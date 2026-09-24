"""O `Makefile` sob `make -n`: nada roda de verdade.

O GNU make executa **de verdade**, mesmo sob `-n`, toda linha de receita que
referencia `$(MAKE)` — é assim que ele traça a recursão. Uma linha que só faz
`$(MAKE) alvo` é inofensiva: o submake herda o `-n` e só imprime. Uma linha que
mistura `$(MAKE)` com outro comando leva o outro comando junto. Em 23/09/2026 um
`make -n recovery-restore` executou, pela linha de `airbyte-up`, um
`abctl local install` com o Airbyte de pé — só a armadilha do `PG_VERSION` o
abortou. O RVE-02 tinha achado a mesma armadilha pelo medidor, e a correção
dele mudou o medidor, não a linha.

Dois oráculos: a **regra**, lida do texto — toda linha que referencia `$(MAKE)`
é só a recursão —, e o **efeito**, medido — `make -n` sobre uma cópia do
`Makefile` real, num diretório de rascunho com executáveis simulados que
registram cada chamada, não chama nada.

Com os mesmos executáveis simulados, e sem `-n`, a retomada do Airbyte que a
correção transformou em variável: ela só diz "pronta" quando a API responde, e
esgotar o prazo é erro nos dois chamadores (RVE3-02).
"""

from __future__ import annotations

import os
import pathlib
import re
import shutil
import subprocess

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]

#: `$(if $(filter 1,$(VAR)),…[,true])` — a forma dos interruptores do projeto.
#: **O `make` procura `$(MAKE)` no texto da linha, antes de expandir**: com o
#: interruptor desligado a linha roda do mesmo jeito sob `-n` (medido no GNU
#: Make 4.3 em 23/09/2026 — o ramo falso de um `$(if)` executou). Por isso os
#: dois ramos precisam ser inofensivos: dentro, a recursão pura; fora, no
#: máximo `true`.
CONDICIONAL = re.compile(r"\$\(if \$\(filter [^,]*,\$\([A-Z_]+\)\),(?P<dentro>.*?)(?:,true)?\)")

#: `$(MAKE)` e argumentos — nenhum operador de shell, redirecionamento ou
#: substituição de comando que levaria outro comando junto.
RECURSAO_PURA = re.compile(r"\$\(MAKE\)(?:\s[^;&|<>`]*)?")


def _linhas_de_receita(texto: str) -> list[str]:
    """As linhas de receita como o `make` as entrega ao shell: continuações juntadas."""
    return [linha for linha in texto.replace("\\\n", " ").splitlines() if linha.startswith("\t")]


def test_toda_linha_com_make_recursivo_e_so_a_recursao():
    impuras = []
    for linha in _linhas_de_receita((RAIZ / "Makefile").read_text(encoding="utf-8")):
        if "$(MAKE)" not in linha:
            continue
        corpo = linha.strip().lstrip("@+-").strip()
        if corpo.startswith("#"):
            continue  # comentário de receita é prosa
        condicional = CONDICIONAL.fullmatch(corpo)
        if condicional:
            corpo = condicional["dentro"].strip()
        if not RECURSAO_PURA.fullmatch(corpo) or "$$(" in corpo:
            impuras.append(corpo[:140])

    assert impuras == [], "linha de receita que o `make -n` executaria de verdade:\n" + "\n".join(impuras)


#: Um executável simulado: registra quem foi chamado, com que argumentos, e sai 0.
REGISTRADOR = '#!/usr/bin/env bash\necho "$(basename "$0") $*" >> "$SIM_LOG"\n'

#: Tudo o que as receitas chamam por caminho — ferramentas, ambiente Python e os
#: scripts do projeto. O `docker` e o `curl` vão à frente do `PATH`.
SIMULADOS = (
    ".tools/abctl", ".tools/terraform",
    ".venv/bin/alembic", ".venv/bin/dbt", ".venv/bin/python", ".venv/bin/pytest",
    "docker/preflight.sh", "docker/conteineres.sh", "docker/airflow_cli.sh",
    "docker/medir.sh", "docker/airbyte_jobs.sh",
)


def _make(
    tmp_path: pathlib.Path,
    *argumentos: str,
    docker: str = REGISTRADOR,
    binarios: dict[str, str | None] | None = None,
    ambiente_extra: dict[str, str] | None = None,
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    """`make` sobre o `Makefile` real copiado; devolve a execução e o que foi chamado.

    `binarios` troca ou acrescenta executáveis à frente do `PATH` — o `curl` da
    API, o `sleep` que não dorme —, e `None` tira um dos simulados padrão.
    """
    trabalho = tmp_path / "checkout"
    for relativo in SIMULADOS:
        caminho = trabalho / relativo
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text(REGISTRADOR, encoding="utf-8")
        caminho.chmod(0o755)
    (tmp_path / "bin").mkdir()
    for nome, script in ({"docker": docker, "curl": REGISTRADOR} | (binarios or {})).items():
        if script is None:
            continue
        (tmp_path / "bin" / nome).write_text(script, encoding="utf-8")
        (tmp_path / "bin" / nome).chmod(0o755)
    (trabalho / "Makefile").write_text((RAIZ / "Makefile").read_text(encoding="utf-8"), encoding="utf-8")
    (trabalho / ".env").write_text("", encoding="utf-8")
    (trabalho / "dbt").mkdir()
    registro = tmp_path / "chamadas"
    ambiente = os.environ | {"PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}", "SIM_LOG": str(registro)}

    r = subprocess.run(
        ["make", "--no-print-directory", *argumentos],
        cwd=trabalho, capture_output=True, text=True, env=ambiente | (ambiente_extra or {}), timeout=60,
    )
    return r, (registro.read_text(encoding="utf-8").splitlines() if registro.exists() else [])


@pytest.mark.parametrize(
    "alvo",
    [
        pytest.param(["airbyte-up"], id="airbyte-up"),
        pytest.param(["dbt-build", "RESET=1"], id="dbt-build-RESET"),
        pytest.param(["recovery-restore", "RESTAURAR=1"], id="recovery-restore"),
    ],
)
def test_make_n_nao_executa_nada(tmp_path, alvo):
    """A contraprova do incidente: `airbyte-up` chamava `abctl local install`, e
    `dbt-build RESET=1` rodava o `dbt build --full-refresh` que vinha depois do `&&`.

    `recovery-restore` entra porque é por ele que o incidente aconteceu: ele
    chama os dois, e mais onze submakes.
    """
    r, chamadas = _make(tmp_path, "-n", *alvo)

    assert r.returncode == 0, r.stdout + r.stderr
    assert chamadas == []


#: Um `docker` que responde o que `airbyte-up` pergunta: o cluster está parado
#: (`SIM_PAUSADO=1`) ou não existe.
DOCKER_DO_CLUSTER = """#!/usr/bin/env bash
echo "docker $*" >> "$SIM_LOG"
case "$1" in
  ps) [ "${SIM_PAUSADO:-0}" = 1 ] && echo 3f2a1b ;;
esac
exit 0
"""

#: A API do Airbyte, uma resposta por consulta, na ordem de `SIM_API`; a
#: última se repete. `muda`, `503` e `pronta` são os três estados da retomada
#: real de 23/09/2026: `muda` é a API sem resposta HTTP nenhuma (`http=000`;
#: o dublê sai 7, e o código real não foi registrado), `503` é o ingress de pé
#: com o servidor ainda subindo, e `pronta` é a resposta medida, byte a byte.
#: `falsa` é a API que responde sem estar disponível.
CURL_DA_API = """#!/usr/bin/env bash
echo "curl $*" >> "$SIM_LOG"
IFS=, read -ra respostas <<< "$SIM_API"
n=$(grep -c '^curl ' "$SIM_LOG")
i=$(( n <= ${#respostas[@]} ? n - 1 : ${#respostas[@]} - 1 ))
case "${respostas[$i]}" in
  muda) exit 7 ;;
  503) echo '<html><head><title>503 Service Temporarily Unavailable</title></head></html>' ;;
  falsa) echo '{"available":false}' ;;
  pronta) echo '{"available":true}' ;;
esac
exit 0
"""

#: O prazo é contado em consultas; o `sleep` que não dorme faz as 60 caberem
#: num teste.
SLEEP_INSTANTANEO = "#!/bin/sh\nexit 0\n"

#: Os dois chamadores de `RETOMAR_AIRBYTE`, com o cluster parado.
CHAMADORES = [pytest.param("airbyte-resume", id="airbyte-resume"), pytest.param("airbyte-up", id="airbyte-up")]


def _retomar(tmp_path: pathlib.Path, alvo: str, api: str) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    r, chamadas = _make(
        tmp_path,
        alvo,
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API, "sleep": SLEEP_INSTANTANEO},
        ambiente_extra={"SIM_PAUSADO": "1", "SIM_API": api},
    )
    return r, [c for c in chamadas if c.startswith("curl ")]


@pytest.mark.parametrize("alvo", CHAMADORES)
@pytest.mark.parametrize(
    "api, consultas",
    [
        pytest.param("pronta", 1, id="pronta-na-primeira"),
        pytest.param("muda,muda,503,503,pronta", 5, id="espera-o-silencio-e-o-503-passarem"),
    ],
)
def test_a_retomada_diz_pronta_so_quando_a_api_responde(tmp_path, alvo, api, consultas):
    """RVE3-02: pronto é a API responder `available:true`, e a espera espera por isso.

    O caso de cinco consultas é o desenho da retomada real: primeiro a API sem
    resposta, depois o 503 do ingress. A espera antiga dizia "pronto" antes de
    tudo isso, porque o `grep -q Ready` casava nos sandboxes `NotReady`.
    """
    r, curls = _retomar(tmp_path, alvo, api)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "aguardando a API do Airbyte" in r.stdout and r.stdout.count("pronta.") == 1, r.stdout
    assert len(curls) == consultas, curls
    assert all("http://localhost:8000/api/v1/health" in c for c in curls), curls


@pytest.mark.parametrize("alvo", CHAMADORES)
@pytest.mark.parametrize(
    "api",
    [
        pytest.param("muda", id="sem-resposta"),
        pytest.param("503", id="ingress-sem-servidor"),
        pytest.param("falsa", id="available-false"),
    ],
)
def test_a_retomada_que_esgota_o_prazo_falha(tmp_path, alvo, api):
    """RVE3-02: o prazo esgotado sai com erro, e `airbyte-up` não anuncia a interface.

    Antes, as 30 consultas terminavam num `echo` que saía 0, e quem chamou
    seguia adiante sem o Airbyte.
    """
    r, curls = _retomar(tmp_path, alvo, api)

    assert r.returncode != 0, r.stdout
    assert "tempo esgotado" in r.stdout and "pronta." not in r.stdout, r.stdout
    assert len(curls) == 60, "o prazo é de 60 consultas"
    assert re.search(r"a 60 consultas em \d+ s\.", r.stdout), "a mensagem diz o que foi contado, e em quanto tempo"
    assert "Interface em" not in r.stdout


def test_sem_curl_a_retomada_recusa_antes_de_religar(tmp_path):
    """Sem `curl`, a espera venceria o prazo dizendo que a API não respondeu.

    O `2>/dev/null` da consulta engoliria o "command not found". O `PATH` aqui
    tem só o que a receita usa além do `curl`, e nada é religado.
    """
    restrito = tmp_path / "restrito"
    restrito.mkdir()
    for ferramenta in ("make", "bash", "seq", "grep", "sleep"):
        (restrito / ferramenta).symlink_to(shutil.which(ferramenta))

    r, chamadas = _make(
        tmp_path,
        "airbyte-resume",
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": None},
        ambiente_extra={"SIM_PAUSADO": "1", "PATH": f"{tmp_path / 'bin'}:{restrito}"},
    )

    assert r.returncode != 0, r.stdout
    assert "curl ausente" in r.stdout, r.stdout + r.stderr
    assert "docker start airbyte-abctl-control-plane" not in chamadas


def test_airbyte_up_retoma_o_cluster_pausado_sem_reinstalar(tmp_path):
    """O comportamento que a variável substituiu, conferido sem `-n`."""
    r, chamadas = _make(
        tmp_path,
        "airbyte-up",
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API},
        ambiente_extra={"SIM_PAUSADO": "1", "SIM_API": "pronta"},
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert "cluster pausado — retomando em vez de reinstalar" in r.stdout
    assert "aguardando a API do Airbyte pronta." in r.stdout
    assert "docker start airbyte-abctl-control-plane" in chamadas
    assert not any(c.startswith("abctl") for c in chamadas), chamadas


def test_airbyte_up_instala_quando_nao_ha_cluster(tmp_path):
    r, chamadas = _make(tmp_path, "airbyte-up", docker=DOCKER_DO_CLUSTER)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "abctl local install --values airbyte/values.yaml" in chamadas
    assert "docker start airbyte-abctl-control-plane" not in chamadas
    assert not any(c.startswith("curl") for c in chamadas), "quem instala é o abctl, e ele espera por conta própria"


def test_airbyte_resume_continua_retomando(tmp_path):
    r, chamadas = _make(
        tmp_path,
        "airbyte-resume",
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API},
        ambiente_extra={"SIM_PAUSADO": "1", "SIM_API": "pronta"},
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert "aguardando a API do Airbyte pronta." in r.stdout
    assert chamadas[0] == "docker start airbyte-abctl-control-plane"
