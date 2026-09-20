"""Oráculos do `docker/preflight.sh` e do `docker/conteineres.sh`.

O script decide se um ambiente pesado pode subir e, quando pode, **pausa** o
conflitante antes. Errar aqui não produz um número errado: produz os dois
ambientes de pé ao mesmo tempo, que é o R11 — a máquina travando com o OOM
killer disparando. Foi o achado R27: `docker stop` falhando e o script
anunciando "pausado" e liberando o alvo assim mesmo.

A Etapa 12 (B0) acrescentou três defeitos vivos, medidos nesta máquina: o
Airflow nunca era encontrado, porque a composição dele não declara
`container_name` e o preflight procurava por prefixo de nome; a consulta que
decidiria se ele está ocupado é inválida no Airflow 3.2.2, que exige `dag_id`;
e `make airflow-pause` imprimia "Airflow pausado." sobre uma lista vazia.

Nada aqui toca em Docker, em contêiner ou na memória da máquina. O script roda
dentro de um *namespace* de montagem próprio, com `/proc/meminfo` substituído
por um arquivo do teste e com `docker`, `pgrep` e o CLI do Airflow falsos à
frente do `PATH`. O `docker` falso mantém a lista de contêineres num arquivo de
estado **com os rótulos do Compose**, de modo que parar e religar sejam
observáveis — é o que permite afirmar o estado resultante em vez de acreditar
no código de saída.
"""

from __future__ import annotations

import os
import pathlib
import subprocess

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
PREFLIGHT = RAIZ / "docker" / "preflight.sh"
CONTEINERES_SH = RAIZ / "docker" / "conteineres.sh"

PROJETO = "mvp_ed1"

#: Contêineres por ambiente, na forma que o Compose **de fato** produz: o
#: Airflow sem `container_name` (nome gerado `<projeto>-<serviço>-<n>`), o
#: streaming e os bancos com `container_name` parametrizado. O que o preflight
#: usa como critério é o rótulo `com.docker.compose.service`, não o nome.
CONTEINERES: dict[str, list[tuple[str, str]]] = {
    # (serviço, molde do nome) — `{p}` é o nome do projeto
    "Airflow": [
        ("airflow_scheduler", "{p}-airflow_scheduler-1"),
        ("airflow_apiserver", "{p}-airflow_apiserver-1"),
        ("airflow_dag_processor", "{p}-airflow_dag_processor-1"),
        ("airflow_db", "{p}-airflow_db-1"),
    ],
    "streaming": [
        ("redpanda", "{p}_redpanda"),
        ("kafka_connect", "{p}_kafka_connect"),
    ],
    "bancos": [
        ("source_db", "{p}_source_db"),
        ("legacy_db", "{p}_legacy_db"),
        ("warehouse_db", "{p}_warehouse_db"),
    ],
}

#: O nó do cluster do Airbyte nasce do `abctl`, não do Compose: não tem rótulo
#: de serviço, e continua sendo reconhecido pelo nome que a ferramenta declara.
AIRBYTE = "airbyte-abctl-control-plane"


def nomes(ambiente: str, projeto: str = PROJETO) -> list[str]:
    return [molde.format(p=projeto) for _, molde in CONTEINERES[ambiente]]


def _linhas_de_estado(ambientes: list[str], projeto: str = PROJETO) -> str:
    linhas = []
    for amb in ambientes:
        if amb == "Airbyte":
            # sem rótulos do Compose: projeto e serviço vazios
            linhas.append(f"{AIRBYTE}|||up")
            continue
        for servico, molde in CONTEINERES[amb]:
            linhas.append(f"{molde.format(p=projeto)}|{projeto}|{servico}|up")
    return "".join(f"{l}\n" for l in linhas)


DOCKER_FALSO = r"""#!/usr/bin/env bash
# `docker` SIMULADO. Nenhum contêiner real é consultado ou tocado.
# Estado: uma linha por contêiner, `nome|projeto|serviço|up|exited`.
echo "docker $*" >> "$SIM_LOG"
cmd="$1"; shift

_marcar() {  # $1 = nome, $2 = novo estado
  awk -F'|' -v OFS='|' -v n="$1" -v e="$2" \
    '{ if ($1 == n) $4 = e; print }' "$SIM_ESTADO" > "$SIM_ESTADO.tmp"
  mv "$SIM_ESTADO.tmp" "$SIM_ESTADO"
}

case "$cmd" in
  ps)
    todos=false; proj=""; svc=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -a|-aq) todos=true ;;
        --filter)
          case "$2" in
            label=com.docker.compose.project=*) proj="${2##*project=}" ;;
            label=com.docker.compose.service=*) svc="${2##*service=}" ;;
          esac
          shift ;;
        --format) shift ;;
      esac
      shift
    done
    while IFS='|' read -r nome p s estado; do
      [ -z "$nome" ] && continue
      $todos || [ "$estado" = up ] || continue
      [ -n "$proj" ] && [ "$p" != "$proj" ] && continue
      [ -n "$svc" ] && [ "$s" != "$svc" ] && continue
      echo "$nome"
    done < "$SIM_ESTADO"
    ;;
  exec)
    [ "${SIM_EXEC_OK:-1}" = 1 ] || exit 1
    [ -n "${SIM_EXEC_SLEEP:-}" ] && sleep "$SIM_EXEC_SLEEP"
    shift  # nome do contêiner
    case "$*" in
      *"crictl pods"*)
        printf '%s\n' "$SIM_PODS" ;;
      *"dags list-runs"*)
        dag="$4"; estado=""
        while [ $# -gt 0 ]; do [ "$1" = "--state" ] && estado="$2"; shift; done
        var="SIM_RUNS_${dag}_${estado}"
        printf '%s\n' "${SIM_RUIDO:-}"
        printf '%s\n' "${!var:-[]}" ;;
      *"dags list"*)
        printf '%s\n' "${SIM_RUIDO:-}"
        printf '%s\n' "${SIM_DAGS:-[]}" ;;
      *) ;;
    esac
    ;;
  stop)
    [ "${SIM_STOP_OK:-1}" = 1 ] || exit 1
    for n in "$@"; do
      case " ${SIM_STOP_IGNORAR:-} " in *" $n "*) continue ;; esac
      _marcar "$n" exited
    done
    # Parar devolve memória: o script espera ela subir antes de decidir de novo.
    printf 'MemTotal:       12582912 kB\nMemAvailable:   %d kB\n' \
      "$((SIM_MEM_APOS * 1024))" > "$SIM_MEMINFO"
    ;;
  start)
    for n in "$@"; do _marcar "$n" up; done
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

#: Ruído de inicialização que o Airflow escreve no **stdout** — não no stderr.
RUIDO_ALEMBIC = (
    "2026-09-20T05:54:15.145529Z [info     ] setup plugin alembic.autogenerate.schemas "
    "[alembic.runtime.plugins] loc=plugins.py:37\n"
    "2026-09-20T05:54:15.146101Z [info     ] setup plugin alembic.autogenerate.tables "
    "[alembic.runtime.plugins] loc=plugins.py:37"
)


def dags_json(*dag_ids: str, pausada: bool = False) -> str:
    """A enumeração como o Airflow 3.2.2 a devolve — com repetidos."""
    itens = [
        '{"dag_id": "%s", "is_paused": "%s"}' % (d, "True" if pausada else "False")
        for d in dag_ids
        for _ in range(6)  # a versão instalada repete a mesma DAG seis vezes
    ]
    return "[" + ", ".join(itens) + "]"


def runs_json(dag_id: str, run_id: str) -> str:
    return '[{"dag_id": "%s", "run_id": "%s", "state": "running"}]' % (dag_id, run_id)


def _tem_unshare() -> bool:
    try:
        return subprocess.run(["unshare", "-rm", "true"], capture_output=True).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


exige_unshare = pytest.mark.skipif(
    not _tem_unshare(),
    reason="exige 'unshare -rm' para trocar /proc/meminfo sem privilégio real",
)


def _bin_falso(tmp_path: pathlib.Path) -> pathlib.Path:
    binario = tmp_path / "bin"
    binario.mkdir(parents=True)
    for nome, corpo in (("docker", DOCKER_FALSO), ("pgrep", PGREP_FALSO)):
        alvo = binario / nome
        alvo.write_text(corpo, encoding="utf-8")
        alvo.chmod(0o755)
    return binario


class Resultado:
    def __init__(self, saida: str, log: list[str], estado: list[str]) -> None:
        self.saida = saida
        self.log = log
        self.estado = estado
        # O script anuncia o veredito pelo código de saída; `exit_code:` é
        # ecoado pelo invólucro porque `unshare` não o propaga por si.
        self.codigo = int(saida.rsplit("exit_code:", 1)[1].strip())

    @property
    def de_pe(self) -> list[str]:
        return [l.split("|")[0] for l in self.estado if l.endswith("|up")]

    def parou(self) -> bool:
        return any(l.startswith("docker stop") for l in self.log)

    def religou(self) -> bool:
        return any(l.startswith("docker start") for l in self.log)


def executa(
    tmp_path: pathlib.Path,
    alvo: str,
    no_ar: list[str],
    *,
    projeto: str = PROJETO,
    estado_extra: str = "",
    mem_mib: int = 12000,
    mem_apos_mib: int | None = None,
    stop_ok: bool = True,
    pods: str = "POD ID              NAME",
    exec_ok: bool = True,
    exec_sleep: str = "",
    dags: str | None = None,
    ruido: str = "",
    runs: dict[str, str] | None = None,
    prazo_consulta: str = "20",
    prazo_total: str = "90",
) -> Resultado:
    binario = _bin_falso(tmp_path)

    estado = tmp_path / "de_pe"
    estado.write_text(_linhas_de_estado(no_ar, projeto) + estado_extra, encoding="utf-8")
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
        "SIM_EXEC_SLEEP": exec_sleep,
        "SIM_STOP_OK": "1" if stop_ok else "0",
        "SIM_MEM_APOS": str(mem_apos_mib if mem_apos_mib is not None else mem_mib + 400),
        "SIM_SCRIPT": str(PREFLIGHT),
        "SIM_ALVO": alvo,
        "SIM_DAGS": dags if dags is not None else "[]",
        "SIM_RUIDO": ruido,
        "COMPOSE_PROJECT_NAME": projeto,
        "PREFLIGHT_PRAZO_CONSULTA": prazo_consulta,
        "PREFLIGHT_PRAZO_TOTAL": prazo_total,
    }
    for chave, valor in (runs or {}).items():
        ambiente[f"SIM_RUNS_{chave}"] = valor

    saida = subprocess.run(
        ["unshare", "-rm", str(dentro)],
        capture_output=True,
        text=True,
        env=ambiente,
        timeout=180,
    )
    return Resultado(
        saida.stdout + saida.stderr,
        log.read_text(encoding="utf-8").splitlines(),
        estado.read_text(encoding="utf-8").split(),
    )


# ── O achado original: pausa que não acontece não libera o alvo ──────────────


@exige_unshare
def test_pausa_que_falha_nao_libera_o_alvo(tmp_path):
    """R27: `docker stop` falhando não pode virar '[preflight] OK'.

    É o achado inteiro: com memória de sobra, o script anunciava a pausa,
    esvaziava o conflito e saía 0 — com o outro ambiente ainda de pé.
    """
    r = executa(tmp_path, "streaming", ["Airbyte"], stop_ok=False)

    assert r.codigo == 1, r.saida
    assert "falhei em pausar Airbyte" in r.saida
    assert "[preflight] OK" not in r.saida
    assert AIRBYTE in r.de_pe


@exige_unshare
def test_pausa_confirmada_libera_o_alvo(tmp_path):
    r = executa(tmp_path, "streaming", ["Airbyte"])

    assert r.codigo == 0, r.saida
    assert "[preflight] OK" in r.saida
    assert r.parou()
    assert r.de_pe == []


@exige_unshare
def test_nada_e_pausado_com_trabalho_em_andamento(tmp_path):
    r = executa(tmp_path, "streaming", ["Airbyte"], pods="orchestrator-repl-abc123")

    assert r.codigo == 1, r.saida
    assert "sincronização em andamento" in r.saida
    assert not r.parou(), "recuou sem tocar em nada é o contrato"
    assert AIRBYTE in r.de_pe


@exige_unshare
def test_verificacao_que_nao_responde_conta_como_bloqueio(tmp_path):
    """Comando mudo não é 'não há trabalho'. Perder uma sincronização é silencioso."""
    r = executa(tmp_path, "streaming", ["Airbyte"], exec_ok=False)

    assert r.codigo == 1, r.saida
    assert "indeterminado" in r.saida
    assert not r.parou()


@exige_unshare
def test_recusa_por_memoria_restaura_o_que_pausou(tmp_path):
    """Pausar e desistir deixaria a máquina pior do que estava."""
    r = executa(tmp_path, "airbyte", ["streaming"], mem_mib=6000, mem_apos_mib=6400)

    assert r.codigo == 1, r.saida
    assert "restaurando o que foi pausado" in r.saida
    assert r.parou() and r.religou()
    assert sorted(r.de_pe) == sorted(nomes("streaming"))


def test_sem_trocar_o_preflight_nao_tem_efeito(tmp_path):
    """`make preflight ALVO=…` responde a mesma pergunta sem tocar em nada."""
    binario = _bin_falso(tmp_path)
    estado = tmp_path / "de_pe"
    estado.write_text(_linhas_de_estado(["Airbyte"]), encoding="utf-8")
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
            "COMPOSE_PROJECT_NAME": PROJETO,
        },
        timeout=60,
    )

    assert saida.returncode == 1, saida.stdout
    assert "RECUSADO" in saida.stdout
    assert log.read_text(encoding="utf-8").count("docker stop") == 0
    assert AIRBYTE in estado.read_text(encoding="utf-8")


# ── B0, defeito 1: o Airflow existe para o preflight ─────────────────────────


@exige_unshare
def test_airflow_e_encontrado_pelos_nomes_gerados_pelo_compose(tmp_path):
    """O defeito vivo: `^airflow_` nunca casa com `mvp_ed1-airflow_scheduler-1`.

    Antes de B0, `AIRFLOW_NO_AR` era sempre falso — `make stream-up` subia o
    streaming com o Airflow inteiro de pé, que é o R11 acontecendo.
    """
    r = executa(tmp_path, "streaming", ["Airflow"])

    assert "Airflow" in r.saida, r.saida
    assert r.codigo == 0, r.saida
    assert r.parou()
    assert r.de_pe == []


@exige_unshare
def test_projeto_com_outro_nome_resolve_os_proprios_conteineres(tmp_path):
    """No clone de B5 o `COMPOSE_PROJECT_NAME` é outro — e os contêineres também.

    O preflight do clone não pode pausar (nem contar) o Airflow do *checkout*
    antigo: são dois projetos, e o rótulo os separa.
    """
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        projeto="clone_etapa12",
        estado_extra=_linhas_de_estado(["Airflow"], "mvp_ed1"),
    )

    assert r.codigo == 0, r.saida
    assert sorted(r.de_pe) == sorted(nomes("Airflow", "mvp_ed1")), (
        "o Airflow do projeto antigo não podia ser tocado"
    )
    for nome in nomes("Airflow", "clone_etapa12"):
        assert nome not in r.de_pe


# ── B0, defeito 2: a consulta de trabalho ────────────────────────────────────


@exige_unshare
def test_airflow_ocioso_libera_a_troca(tmp_path):
    """A contraprova que faltava.

    Corrigido só o nome, o preflight passaria a **recusar toda troca**: a
    consulta antiga sai com código 2 no Airflow 3.2.2, e "indeterminado" é
    bloqueio. Airflow de pé e ocioso tem de liberar.
    """
    r = executa(tmp_path, "streaming", ["Airflow"], dags=dags_json("fluxo_batch"))

    assert r.codigo == 0, r.saida
    assert "[preflight] OK" in r.saida
    assert "indeterminado" not in r.saida
    assert r.de_pe == []


@exige_unshare
def test_dag_em_execucao_recusa_e_nomeia_o_run(tmp_path):
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch"),
        runs={"fluxo_batch_running": runs_json("fluxo_batch", "manual__2026-09-20T06:00:00")},
    )

    assert r.codigo == 1, r.saida
    assert "DAG fluxo_batch com execução running" in r.saida
    assert "manual__2026-09-20T06:00:00" in r.saida
    assert not r.parou()
    assert sorted(r.de_pe) == sorted(nomes("Airflow"))


@exige_unshare
def test_execucao_enfileirada_tambem_recusa(tmp_path):
    """RV12-4-04: a CLI filtra o estado exato, e `queued` pode começar entre a
    consulta e o `docker stop` — que é exatamente a corrida a evitar."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch"),
        runs={"fluxo_batch_queued": runs_json("fluxo_batch", "manual__enfileirada")},
    )

    assert r.codigo == 1, r.saida
    assert "com execução queued" in r.saida
    assert not r.parou()


@exige_unshare
def test_dag_pausada_com_execucao_em_andamento_recusa(tmp_path):
    """Pausa não é ociosidade: `is_paused=true` não descarta a DAG da consulta."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch", pausada=True),
        runs={"fluxo_batch_running": runs_json("fluxo_batch", "manual__em_dag_pausada")},
    )

    assert r.codigo == 1, r.saida
    assert "com execução running" in r.saida
    assert not r.parou()


@exige_unshare
def test_ruido_do_alembic_no_stdout_e_descartado(tmp_path):
    """O ruído sai no stdout — `2>/dev/null` não limpa nada. O JSON é o que resta."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch"),
        ruido=RUIDO_ALEMBIC,
    )

    assert r.codigo == 0, r.saida
    assert "indeterminado" not in r.saida
    assert r.de_pe == []


@exige_unshare
def test_enumeracao_ilegivel_e_indeterminado(tmp_path):
    """Saída que não é JSON — o `Usage:` de um `dag_id` ausente, por exemplo."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags="Usage: airflow dags list-runs [-h] ...",
    )

    assert r.codigo == 1, r.saida
    assert "indeterminado" in r.saida
    assert not r.parou()


@exige_unshare
def test_dag_nova_entra_na_consulta_sem_lista_fixa(tmp_path):
    """A segunda DAG do projeto não pode depender de alguém editar o preflight."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch", "fluxo_recem_registrado"),
        runs={"fluxo_recem_registrado_running": runs_json("fluxo_recem_registrado", "manual__nova")},
    )

    assert r.codigo == 1, r.saida
    assert "DAG fluxo_recem_registrado" in r.saida
    assert not r.parou()


@exige_unshare
def test_consulta_pendurada_expira_e_bloqueia(tmp_path):
    """RV12-4-04: sem prazo, uma consulta pendurada pendura quem chamou."""
    r = executa(
        tmp_path,
        "streaming",
        ["Airflow"],
        dags=dags_json("fluxo_batch"),
        exec_sleep="10",
        prazo_consulta="1",
    )

    assert r.codigo == 1, r.saida
    assert "indeterminado" in r.saida
    assert "prazo" in r.saida
    assert not r.parou()
    assert sorted(r.de_pe) == sorted(nomes("Airflow"))


# ── B0, defeito 3: o alvo de pausa que anunciava o que não fez ───────────────


def _conteineres(
    tmp_path: pathlib.Path, acao: str, *args: str, estado: str, projeto: str = PROJETO
) -> subprocess.CompletedProcess[str]:
    binario = _bin_falso(tmp_path)
    arquivo = tmp_path / "de_pe"
    arquivo.write_text(estado, encoding="utf-8")
    log = tmp_path / "log"
    log.write_text("", encoding="utf-8")
    processo = subprocess.run(
        [str(CONTEINERES_SH), acao, *args],
        capture_output=True,
        text=True,
        env=os.environ
        | {
            "PATH": f"{binario}:{os.environ['PATH']}",
            "SIM_ESTADO": str(arquivo),
            "SIM_LOG": str(log),
            "SIM_MEM_APOS": "12000",
            "SIM_MEMINFO": str(tmp_path / "nao_usado"),
            "COMPOSE_PROJECT_NAME": projeto,
        },
        timeout=60,
    )
    processo.estado_final = arquivo.read_text(encoding="utf-8")  # type: ignore[attr-defined]
    return processo


#: Os consumidores citam o **grupo**, nunca a lista: é o que impede que uma
#: lista repetida no Makefile divirja da do script no primeiro serviço novo.
GRUPO_AIRFLOW = ["@airflow"]


def test_pausa_sem_conteiner_resolvido_nao_diz_pausado(tmp_path):
    """O defeito medido em 19/09: `grep` não casa (rc 1), mas o código do
    *pipeline* é o do `xargs -r`, que sem entrada sai 0 — e a mensagem de
    sucesso saía com o Airflow inteiro de pé."""
    r = _conteineres(tmp_path, "pausar", "Airflow", *GRUPO_AIRFLOW, estado="")

    assert "pausado" not in r.stdout, r.stdout
    assert "já não estava de pé" in r.stdout
    assert r.returncode == 3


def test_pausa_confirmada_diz_quantos_parou(tmp_path):
    r = _conteineres(
        tmp_path,
        "pausar",
        "Airflow",
        *GRUPO_AIRFLOW,
        estado=_linhas_de_estado(["Airflow"]),
    )

    assert r.returncode == 0, r.stdout
    assert "Airflow pausado — 4 contêineres parados." in r.stdout
    assert "|up" not in r.estado_final  # type: ignore[attr-defined]


def test_pausa_parcial_e_denunciada_com_o_que_sobrou(tmp_path):
    """Metade parada é pior que nada: quem chamou precisa saber o que sobrou.

    O `docker stop` pode parar três dos quatro e sair 0 — e o código de saída
    não distingue esse caso do sucesso. O oráculo é o estado resultante.
    """
    teimoso = "mvp_ed1-airflow_scheduler-1"
    binario = _bin_falso(tmp_path)
    arquivo = tmp_path / "de_pe"
    arquivo.write_text(_linhas_de_estado(["Airflow"]), encoding="utf-8")
    log = tmp_path / "log"
    log.write_text("", encoding="utf-8")

    r = subprocess.run(
        [str(CONTEINERES_SH), "pausar", "Airflow", *GRUPO_AIRFLOW],
        capture_output=True,
        text=True,
        env=os.environ
        | {
            "PATH": f"{binario}:{os.environ['PATH']}",
            "SIM_ESTADO": str(arquivo),
            "SIM_LOG": str(log),
            "SIM_STOP_IGNORAR": teimoso,
            "SIM_MEM_APOS": "12000",
            "SIM_MEMINFO": str(tmp_path / "nao_usado"),
            "COMPOSE_PROJECT_NAME": PROJETO,
        },
        timeout=60,
    )

    assert r.returncode == 1, r.stdout
    assert "NÃO foi pausado — 1 de 4 continuam de pé" in r.stdout
    assert teimoso in r.stdout
    assert "Airflow pausado" not in r.stdout


def test_retomada_confere_o_estado_resultante(tmp_path):
    parados = _linhas_de_estado(["Airflow"]).replace("|up", "|exited")
    r = _conteineres(tmp_path, "retomar", "Airflow", *GRUPO_AIRFLOW, estado=parados)

    assert r.returncode == 0, r.stdout
    assert "Airflow retomado — 4 contêineres de pé." in r.stdout
    assert "|exited" not in r.estado_final  # type: ignore[attr-defined]


def test_resolucao_separa_projetos(tmp_path):
    r = _conteineres(
        tmp_path,
        "resolver",
        "airflow_scheduler",
        estado=_linhas_de_estado(["Airflow"], "mvp_ed1")
        + _linhas_de_estado(["Airflow"], "clone_etapa12"),
        projeto="clone_etapa12",
    )

    assert r.stdout.split() == ["clone_etapa12-airflow_scheduler-1"], r.stdout
