"""Oráculos do `docker/preflight.sh`: a troca automática de ambientes pesados.

O script decide se um ambiente pesado pode subir e, quando pode, **pausa** o
conflitante antes. Errar aqui não produz um número errado: produz os dois
ambientes de pé ao mesmo tempo, que é o R11 — a máquina travando com o OOM
killer disparando. Foi o achado R27: `docker stop` falhando e o script
anunciando "pausado" e liberando o alvo assim mesmo.

Nada aqui toca em Docker, em contêiner ou na memória da máquina. O script roda
dentro de um *namespace* de montagem próprio, com `/proc/meminfo` substituído
por um arquivo do teste e com `docker` e `pgrep` falsos à frente do `PATH`. O
`docker` falso mantém a lista de contêineres "de pé" num arquivo de estado, de
modo que parar e religar sejam observáveis — é o que permite afirmar o estado
resultante em vez de acreditar no código de saída.
"""

from __future__ import annotations

import os
import pathlib
import subprocess

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
PREFLIGHT = RAIZ / "docker" / "preflight.sh"

#: Nomes que o `_no_ar` do script procura, por ambiente.
CONTEINERES = {
    "Airbyte": ["airbyte-abctl-control-plane"],
    "streaming": ["mvp_ed1_redpanda", "mvp_ed1_kafka_connect"],
    "Airflow": ["airflow_scheduler", "airflow_apiserver"],
}

DOCKER_FALSO = r"""#!/usr/bin/env bash
# `docker` SIMULADO. Nenhum contêiner real é consultado ou tocado.
echo "docker $*" >> "$SIM_LOG"
case "$1" in
  ps)
    cat "$SIM_ESTADO"
    ;;
  exec)
    [ "${SIM_EXEC_OK:-1}" = 1 ] || exit 1
    printf '%s\n' "$SIM_PODS"
    ;;
  stop)
    [ "${SIM_STOP_OK:-1}" = 1 ] || exit 1
    shift
    for n in "$@"; do grep -vxF "$n" "$SIM_ESTADO" > "$SIM_ESTADO.tmp"; mv "$SIM_ESTADO.tmp" "$SIM_ESTADO"; done
    # Parar devolve memória: o script espera ela subir antes de decidir de novo.
    printf 'MemTotal:       12582912 kB\nMemAvailable:   %d kB\n' "$((SIM_MEM_APOS * 1024))" > "$SIM_MEMINFO"
    ;;
  start)
    shift
    for n in "$@"; do echo "$n" >> "$SIM_ESTADO"; done
    ;;
esac
exit 0
"""

PGREP_FALSO = "#!/usr/bin/env bash\nexit 1\n"  # nunca há pipeline Beam no host

DENTRO = r"""#!/usr/bin/env bash
mount --bind "$SIM_MEMINFO" /proc/meminfo || exit 99
export PATH="$SIM_BIN:$PATH"
"$SIM_SCRIPT" "$SIM_ALVO" --trocar
echo "exit_code: $?"
"""


def _tem_unshare() -> bool:
    try:
        return subprocess.run(["unshare", "-rm", "true"], capture_output=True).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


pytestmark = pytest.mark.skipif(
    not _tem_unshare(),
    reason="exige 'unshare -rm' para trocar /proc/meminfo sem privilégio real",
)


class Resultado:
    def __init__(self, saida: str, log: list[str], de_pe: list[str]) -> None:
        self.saida = saida
        self.log = log
        self.de_pe = de_pe
        # O script anuncia o veredito pelo código de saída; `exit_code:` é
        # ecoado pelo invólucro porque `unshare` não o propaga por si.
        self.codigo = int(saida.rsplit("exit_code:", 1)[1].strip())

    def parou(self) -> bool:
        return any(l.startswith("docker stop") for l in self.log)

    def religou(self) -> bool:
        return any(l.startswith("docker start") for l in self.log)


def executa(
    tmp_path: pathlib.Path,
    alvo: str,
    no_ar: list[str],
    *,
    mem_mib: int = 12000,
    mem_apos_mib: int | None = None,
    stop_ok: bool = True,
    pods: str = "POD ID              NAME",
    exec_ok: bool = True,
) -> Resultado:
    binario = tmp_path / "bin"
    binario.mkdir()
    for nome, corpo in (("docker", DOCKER_FALSO), ("pgrep", PGREP_FALSO)):
        alvo_bin = binario / nome
        alvo_bin.write_text(corpo, encoding="utf-8")
        alvo_bin.chmod(0o755)

    estado = tmp_path / "de_pe"
    estado.write_text(
        "".join(f"{c}\n" for amb in no_ar for c in CONTEINERES[amb]), encoding="utf-8"
    )
    meminfo = tmp_path / "meminfo"
    meminfo.write_text(f"MemTotal:       12582912 kB\nMemAvailable:   {mem_mib * 1024} kB\n")
    log = tmp_path / "log"
    log.write_text("", encoding="utf-8")
    dentro = tmp_path / "dentro.sh"
    dentro.write_text(DENTRO, encoding="utf-8")
    dentro.chmod(0o755)

    ambiente = os.environ | {
        "SIM_BIN": str(binario),
        "SIM_ESTADO": str(estado),
        "SIM_MEMINFO": str(meminfo),
        "SIM_LOG": str(log),
        "SIM_PODS": pods,
        "SIM_EXEC_OK": "1" if exec_ok else "0",
        "SIM_STOP_OK": "1" if stop_ok else "0",
        "SIM_MEM_APOS": str(mem_apos_mib if mem_apos_mib is not None else mem_mib + 400),
        "SIM_SCRIPT": str(PREFLIGHT),
        "SIM_ALVO": alvo,
    }
    saida = subprocess.run(
        ["unshare", "-rm", str(dentro)],
        capture_output=True,
        text=True,
        env=ambiente,
        timeout=120,
    )
    return Resultado(
        saida.stdout + saida.stderr,
        log.read_text(encoding="utf-8").splitlines(),
        estado.read_text(encoding="utf-8").split(),
    )


def test_pausa_que_falha_nao_libera_o_alvo(tmp_path):
    """R27: `docker stop` falhando não pode virar '[preflight] OK'.

    É o achado inteiro: com memória de sobra, o script anunciava a pausa,
    esvaziava o conflito e saía 0 — com o outro ambiente ainda de pé.
    """
    r = executa(tmp_path, "streaming", ["Airbyte"], stop_ok=False)

    assert r.codigo == 1, r.saida
    assert "falhei em pausar Airbyte" in r.saida
    assert "[preflight] OK" not in r.saida
    # O estado é o oráculo: o Airbyte continua de pé, e é por isso que recusar
    # era a única resposta possível.
    assert "airbyte-abctl-control-plane" in r.de_pe


def test_pausa_confirmada_libera_o_alvo(tmp_path):
    r = executa(tmp_path, "streaming", ["Airbyte"])

    assert r.codigo == 0, r.saida
    assert "[preflight] OK" in r.saida
    assert r.parou()
    assert r.de_pe == []


def test_nada_e_pausado_com_trabalho_em_andamento(tmp_path):
    r = executa(tmp_path, "streaming", ["Airbyte"], pods="orchestrator-repl-abc123")

    assert r.codigo == 1, r.saida
    assert "sincronização em andamento" in r.saida
    assert not r.parou(), "recuou sem tocar em nada é o contrato"
    assert "airbyte-abctl-control-plane" in r.de_pe


def test_verificacao_que_nao_responde_conta_como_bloqueio(tmp_path):
    """Comando mudo não é 'não há trabalho'. Perder uma sincronização é silencioso."""
    r = executa(tmp_path, "streaming", ["Airbyte"], exec_ok=False)

    assert r.codigo == 1, r.saida
    assert "indeterminado" in r.saida
    assert not r.parou()


def test_recusa_por_memoria_restaura_o_que_pausou(tmp_path):
    """Pausar e desistir deixaria a máquina pior do que estava."""
    r = executa(
        tmp_path, "airbyte", ["streaming"], mem_mib=6000, mem_apos_mib=6400
    )

    assert r.codigo == 1, r.saida
    assert "restaurando o que foi pausado" in r.saida
    assert r.parou() and r.religou()
    assert sorted(r.de_pe) == sorted(CONTEINERES["streaming"])


def test_sem_trocar_o_preflight_nao_tem_efeito(tmp_path):
    """`make preflight ALVO=…` responde a mesma pergunta sem tocar em nada."""
    binario = tmp_path / "bin"
    binario.mkdir()
    for nome, corpo in (("docker", DOCKER_FALSO), ("pgrep", PGREP_FALSO)):
        f = binario / nome
        f.write_text(corpo, encoding="utf-8")
        f.chmod(0o755)
    estado = tmp_path / "de_pe"
    estado.write_text("airbyte-abctl-control-plane\n", encoding="utf-8")
    log = tmp_path / "log"
    log.write_text("", encoding="utf-8")

    saida = subprocess.run(
        [str(PREFLIGHT), "streaming"],
        capture_output=True,
        text=True,
        env=os.environ
        | {
            "PATH": f"{binario}:{os.environ['PATH']}",
            "SIM_ESTADO": str(estado),
            "SIM_LOG": str(log),
            "SIM_PODS": "",
            "SIM_MEM_APOS": "12000",
            "SIM_MEMINFO": str(tmp_path / "nao_usado"),
        },
        timeout=60,
    )

    assert saida.returncode == 1, saida.stdout
    assert "RECUSADO" in saida.stdout
    assert log.read_text(encoding="utf-8").count("docker stop") == 0
    assert estado.read_text(encoding="utf-8").split() == ["airbyte-abctl-control-plane"]
