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

E as duas decisões de 24/09/2026 sobre subir e retomar: `airbyte-up` com o
cluster de pé confere a API em vez de reinstalar (D53), e todo alvo que liga
Airbyte, Airflow ou *streaming* passa pelo preflight antes — os `*-resume`
religavam sem conferir memória nem conflito (D54).
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
    simulados: dict[str, str] | None = None,
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    """`make` sobre o `Makefile` real copiado; devolve a execução e o que foi chamado.

    `binarios` troca ou acrescenta executáveis à frente do `PATH` — o `curl` da
    API, o `sleep` que não dorme —, e `None` tira um dos simulados padrão.
    `simulados` troca o corpo de um dos scripts do projeto — o preflight que
    recusa, o `conteineres.sh` que resolve um contêiner.
    """
    trabalho = tmp_path / "checkout"
    for relativo in SIMULADOS:
        caminho = trabalho / relativo
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text((simulados or {}).get(relativo, REGISTRADOR), encoding="utf-8")
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


#: Um `docker` que responde o que `airbyte-up` e `airbyte-resume` perguntam, com
#: a semântica do `docker ps` real: sem `-a` só o que está `running`, `-f
#: status=` filtra o estado, e `--format '{{.State}}'` imprime o estado em vez
#: do id. `SIM_CLUSTER` é o estado do nó — `running`, `exited`, outro, ou vazio
#: quando ele não existe, e aí o `docker start` falha como o real —, e
#: `SIM_DOCKER_MUDO=1` é o Docker que não responde (RVE-08).
DOCKER_DO_CLUSTER = """#!/usr/bin/env bash
echo "docker $*" >> "$SIM_LOG"
if [ "$1" = start ] && [ -z "${SIM_CLUSTER:-}" ]; then
  echo "Error response from daemon: No such container: $2" >&2; exit 1
fi
[ "$1" = ps ] || exit 0
[ "${SIM_DOCKER_MUDO:-0}" = 1 ] && { echo "Cannot connect to the Docker daemon" >&2; exit 1; }
[ -n "${SIM_CLUSTER:-}" ] || exit 0
shift; todos=false; estado=""; formato=""
while [ $# -gt 0 ]; do
  case "$1" in
    -a|-aq) todos=true ;;
    -f|--filter) case "$2" in status=*) estado="${2#status=}" ;; esac; shift ;;
    --format) formato="$2"; shift ;;
  esac
  shift
done
$todos || [ "$SIM_CLUSTER" = running ] || exit 0
[ -z "$estado" ] || [ "$estado" = "$SIM_CLUSTER" ] || exit 0
case "$formato" in *State*) echo "$SIM_CLUSTER" ;; *) echo 3f2a1b ;; esac
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

#: Os três caminhos que esperam a API: os dois chamadores da retomada, com o
#: cluster parado, e `airbyte-up` com ele de pé, que só confere (D53).
CHAMADORES = [
    pytest.param("airbyte-resume", "exited", id="airbyte-resume"),
    pytest.param("airbyte-up", "exited", id="airbyte-up-pausado"),
    pytest.param("airbyte-up", "running", id="airbyte-up-de-pe"),
]


def _retomar(
    tmp_path: pathlib.Path, alvo: str, cluster: str, api: str
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    r, chamadas = _make(
        tmp_path,
        alvo,
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API, "sleep": SLEEP_INSTANTANEO},
        ambiente_extra={"SIM_CLUSTER": cluster, "SIM_API": api},
    )
    return r, [c for c in chamadas if c.startswith("curl ")]


@pytest.mark.parametrize("alvo, cluster", CHAMADORES)
@pytest.mark.parametrize(
    "api, consultas",
    [
        pytest.param("pronta", 1, id="pronta-na-primeira"),
        pytest.param("muda,muda,503,503,pronta", 5, id="espera-o-silencio-e-o-503-passarem"),
    ],
)
def test_a_retomada_diz_pronta_so_quando_a_api_responde(tmp_path, alvo, cluster, api, consultas):
    """RVE3-02: pronto é a API responder `available:true`, e a espera espera por isso.

    O caso de cinco consultas é o desenho da retomada real: primeiro a API sem
    resposta, depois o 503 do ingress. A espera antiga dizia "pronto" antes de
    tudo isso, porque o `grep -q Ready` casava nos sandboxes `NotReady`. O
    cluster de pé passa pela mesma espera (D53): recém-religado à mão, ele
    também pode estar no meio desse desenho.
    """
    r, curls = _retomar(tmp_path, alvo, cluster, api)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "aguardando a API do Airbyte" in r.stdout and r.stdout.count("pronta.") == 1, r.stdout
    assert len(curls) == consultas, curls
    assert all("http://localhost:8000/api/v1/health" in c for c in curls), curls


@pytest.mark.parametrize("alvo, cluster", CHAMADORES)
@pytest.mark.parametrize(
    "api",
    [
        pytest.param("muda", id="sem-resposta"),
        pytest.param("503", id="ingress-sem-servidor"),
        pytest.param("falsa", id="available-false"),
    ],
)
def test_a_retomada_que_esgota_o_prazo_falha(tmp_path, alvo, cluster, api):
    """RVE3-02: o prazo esgotado sai com erro, e `airbyte-up` não anuncia a interface.

    Antes, as 30 consultas terminavam num `echo` que saía 0, e quem chamou
    seguia adiante sem o Airbyte.
    """
    r, curls = _retomar(tmp_path, alvo, cluster, api)

    assert r.returncode != 0, r.stdout
    assert "tempo esgotado" in r.stdout and "pronta." not in r.stdout, r.stdout
    assert len(curls) == 60, "o prazo é de 60 consultas"
    assert re.search(r"a 60 consultas em \d+ s\.", r.stdout), "a mensagem diz o que foi contado, e em quanto tempo"
    assert "Interface em" not in r.stdout


@pytest.mark.parametrize("alvo, cluster", CHAMADORES)
def test_sem_curl_a_espera_recusa_antes_de_mexer_em_qualquer_coisa(tmp_path, alvo, cluster):
    """Sem `curl`, a espera venceria o prazo dizendo que a API não respondeu.

    O `2>/dev/null` da consulta engoliria o "command not found". A recusa vem
    antes do preflight, e não só antes de religar: a troca pausaria o outro
    ambiente por uma espera que não tem como acontecer. O `PATH` aqui tem só o
    que as receitas usam além do `curl`.
    """
    restrito = tmp_path / "restrito"
    restrito.mkdir()
    for ferramenta in ("make", "bash", "seq", "grep", "sleep", "basename"):
        (restrito / ferramenta).symlink_to(shutil.which(ferramenta))

    r, chamadas = _make(
        tmp_path,
        alvo,
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": None},
        ambiente_extra={"SIM_CLUSTER": cluster, "PATH": f"{tmp_path / 'bin'}:{restrito}"},
    )

    assert r.returncode != 0, r.stdout
    assert "curl ausente" in r.stdout, r.stdout + r.stderr
    assert not any(c.startswith(("preflight.sh", "docker start", "abctl")) for c in chamadas), chamadas


def test_airbyte_up_retoma_o_cluster_pausado_sem_reinstalar(tmp_path):
    """O comportamento que a variável substituiu, conferido sem `-n`."""
    r, chamadas = _make(
        tmp_path,
        "airbyte-up",
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API},
        ambiente_extra={"SIM_CLUSTER": "exited", "SIM_API": "pronta"},
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert "cluster pausado — retomando em vez de reinstalar" in r.stdout
    assert "aguardando a API do Airbyte pronta." in r.stdout
    assert "docker start airbyte-abctl-control-plane" in chamadas
    assert not any(c.startswith("abctl") for c in chamadas), chamadas


def test_airbyte_up_com_o_cluster_de_pe_confere_a_api_sem_reinstalar(tmp_path):
    """D53: com o cluster de pé, o ramo de instalação chamava `abctl local install`
    — que, assim, abortou no `PG_VERSION` em 05/09 e em 23/09/2026. De pé, ele
    só confere a API, que é o que "de pé" promete a quem vem depois."""
    r, chamadas = _make(
        tmp_path,
        "airbyte-up",
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API},
        ambiente_extra={"SIM_CLUSTER": "running", "SIM_API": "pronta"},
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert "cluster de pé — conferindo a API" in r.stdout
    assert "aguardando a API do Airbyte pronta." in r.stdout
    assert not any(c.startswith(("abctl", "docker start")) for c in chamadas), chamadas


def test_airbyte_up_instala_quando_nao_ha_cluster(tmp_path):
    r, chamadas = _make(tmp_path, "airbyte-up", docker=DOCKER_DO_CLUSTER)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "abctl local install --values airbyte/values.yaml" in chamadas
    assert "docker start airbyte-abctl-control-plane" not in chamadas
    assert not any(c.startswith("curl") for c in chamadas), "quem instala é o abctl, e ele espera por conta própria"


@pytest.mark.parametrize("alvo", ["airbyte-up", "airbyte-resume"])
def test_docker_mudo_nao_decide_as_cegas(tmp_path, alvo):
    """RVE-08 no Makefile: `docker ps` que falha não é "não há cluster" — em
    `airbyte-up`, a consulta vazia levava ao `abctl local install`."""
    r, chamadas = _make(
        tmp_path,
        alvo,
        docker=DOCKER_DO_CLUSTER,
        binarios={"sleep": SLEEP_INSTANTANEO},
        ambiente_extra={"SIM_DOCKER_MUDO": "1"},
    )

    assert r.returncode != 0, r.stdout
    assert "o Docker não respondeu" in r.stdout, r.stdout
    assert not any(c.startswith(("abctl", "preflight.sh", "docker start", "curl")) for c in chamadas), chamadas


def test_airbyte_up_em_estado_que_nao_trata_recusa(tmp_path):
    """Nem de pé, nem pausado, nem ausente — um `docker pause`, por exemplo: o
    `abctl` recusaria o contêiner, e o `docker start` também."""
    r, chamadas = _make(tmp_path, "airbyte-up", docker=DOCKER_DO_CLUSTER, ambiente_extra={"SIM_CLUSTER": "paused"})

    assert r.returncode != 0, r.stdout
    assert "'paused'" in r.stdout, r.stdout
    assert not any(c.startswith(("abctl", "preflight.sh", "docker start")) for c in chamadas), chamadas


# ── D54: todo alvo que liga ambiente pesado passa pelo preflight ─────────────

#: O que liga Airbyte, Airflow ou *streaming* no texto de uma receita. Os
#: bancos (`$(COMPOSE) up`) ficam de fora: não são ambiente pesado do R11, e
#: sobem sempre.
LIGA_AMBIENTE = re.compile(
    r"\$\((?:RETOMAR_AIRBYTE|AGUARDAR_API_AIRBYTE)\)|\$\(ABCTL\) local install|docker start|"
    r"\$\(CONTEINERES\) retomar|\$\(COMPOSE_(?:AIRFLOW|STREAM)\) up"
)

#: A família que cada prefixo de alvo liga — é ela que o preflight precisa conferir.
FAMILIA_DO_ALVO = {"airbyte-": "airbyte", "airflow-": "airflow", "stream-": "streaming"}


def _receitas(texto: str) -> dict[str, list[str]]:
    """Alvo → linhas de receita, com as continuações juntadas e sem os comentários de receita."""
    receitas: dict[str, list[str]] = {}
    alvo = None
    for linha in texto.replace("\\\n", " ").splitlines():
        if linha.startswith("\t"):
            corpo = linha.strip().lstrip("@+-").strip()
            if alvo and not corpo.startswith("#"):
                receitas[alvo].append(corpo)
            continue
        cabecalho = re.match(r"([a-z][a-z0-9_-]*):(?!=)", linha)
        alvo = cabecalho[1] if cabecalho else None
        if alvo:
            receitas.setdefault(alvo, [])
    return receitas


def test_todo_alvo_que_liga_ambiente_pesado_passa_pelo_preflight():
    """D54: `airbyte-resume`, `stream-resume` e `airflow-resume` religavam sem
    conferir memória nem conflito, e o próprio preflight mandava retomar por
    eles — retomar o Airbyte com o *streaming* de pé subia as duas famílias
    juntas. A regra, lida do texto: a receita que liga ambiente pesado chama o
    preflight da própria família antes da primeira linha que liga.
    """
    receitas = _receitas((RAIZ / "Makefile").read_text(encoding="utf-8"))
    ligam = {alvo: linhas for alvo, linhas in receitas.items() if any(LIGA_AMBIENTE.search(l) for l in linhas)}

    sem_guarda = []
    for alvo, linhas in ligam.items():
        familia = next(f for prefixo, f in FAMILIA_DO_ALVO.items() if alvo.startswith(prefixo))
        liga = next(i for i, l in enumerate(linhas) if LIGA_AMBIENTE.search(l))
        guarda = [i for i, l in enumerate(linhas) if l == f"$(call preflight,{familia})"]
        if not guarda or guarda[0] > liga:
            sem_guarda.append(alvo)

    assert sorted(ligam) == [
        "airbyte-resume", "airbyte-up", "airflow-resume", "airflow-up", "stream-resume", "stream-up",
    ], "o conjunto dos que ligam mudou — confira se o padrão ainda o reconhece"
    assert sem_guarda == [], "liga ambiente pesado sem passar pelo preflight antes: " + ", ".join(sem_guarda)


#: `conteineres.sh` que resolve um contêiner em qualquer grupo e registra o resto.
CONTEINERES_COM_UM = (
    '#!/usr/bin/env bash\necho "conteineres.sh $*" >> "$SIM_LOG"\n'
    '[ "$1" = resolver ] && echo mvp_ed1_x\nexit 0\n'
)

#: O preflight que recusa — memória que nem a troca resolve, por exemplo.
PREFLIGHT_QUE_RECUSA = (
    '#!/usr/bin/env bash\necho "preflight.sh $*" >> "$SIM_LOG"\n'
    'echo "RECUSADO — simulado."\nexit 1\n'
)

RETOMADAS = [
    pytest.param("airbyte-resume", "airbyte", id="airbyte-resume"),
    pytest.param("stream-resume", "streaming", id="stream-resume"),
    pytest.param("airflow-resume", "airflow", id="airflow-resume"),
]


def _retomada(
    tmp_path: pathlib.Path, alvo: str, *argumentos: str, simulados: dict[str, str] | None = None
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    """Uma retomada com o que ela precisa existindo: o cluster parado, um contêiner por grupo."""
    return _make(
        tmp_path,
        alvo,
        *argumentos,
        docker=DOCKER_DO_CLUSTER,
        binarios={"curl": CURL_DA_API, "sleep": SLEEP_INSTANTANEO},
        ambiente_extra={"SIM_CLUSTER": "exited", "SIM_API": "pronta"},
        simulados={"docker/conteineres.sh": CONTEINERES_COM_UM} | (simulados or {}),
    )


def _religacoes(chamadas: list[str]) -> list[int]:
    return [i for i, c in enumerate(chamadas) if c.startswith(("docker start", "conteineres.sh retomar"))]


@pytest.mark.parametrize("alvo, familia", RETOMADAS)
def test_a_retomada_passa_pela_troca_antes_de_religar(tmp_path, alvo, familia):
    """D54: a mesma troca dos `*-up` — pausa o conflitante e confere a memória —, antes de religar."""
    r, chamadas = _retomada(tmp_path, alvo)

    assert r.returncode == 0, r.stdout + r.stderr
    troca = chamadas.index(f"preflight.sh {familia} --trocar")
    assert _religacoes(chamadas) and troca < _religacoes(chamadas)[0], chamadas


@pytest.mark.parametrize("alvo, familia", RETOMADAS)
def test_recusa_do_preflight_nao_religa_nada(tmp_path, alvo, familia):
    r, chamadas = _retomada(tmp_path, alvo, simulados={"docker/preflight.sh": PREFLIGHT_QUE_RECUSA})

    assert r.returncode != 0, r.stdout
    assert f"preflight.sh {familia} --trocar" in chamadas
    assert _religacoes(chamadas) == [], chamadas


@pytest.mark.parametrize("alvo, familia", RETOMADAS)
def test_force_na_retomada_e_a_autorizacao_do_owner(tmp_path, alvo, familia):
    """O caminho sem conferência continua existindo — agora é só este, e é do Owner."""
    r, chamadas = _retomada(tmp_path, alvo, "FORCE=1")

    assert r.returncode == 0, r.stdout + r.stderr
    assert f"ignorado por FORCE=1 — subida de {familia} autorizada pelo Owner" in r.stdout
    assert not any(c.startswith("preflight.sh") for c in chamadas), chamadas
    assert _religacoes(chamadas), chamadas


@pytest.mark.parametrize("alvo, familia", RETOMADAS)
def test_retomar_o_que_nao_existe_recusa_antes_da_troca(tmp_path, alvo, familia):
    """Sem nada para religar, a troca pausaria o outro ambiente à toa."""
    r, chamadas = _make(tmp_path, alvo, docker=DOCKER_DO_CLUSTER, binarios={"sleep": SLEEP_INSTANTANEO})

    assert r.returncode != 0, r.stdout
    assert "não existe" in r.stdout or "não tem contêineres" in r.stdout, r.stdout
    assert not any(c.startswith("preflight.sh") for c in chamadas), chamadas
