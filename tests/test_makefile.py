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
religavam sem conferir memória nem conflito (D54). E a rede do projeto passa a
ser externa, criada pelo `Makefile`, para que nenhum `down` a leve (D55).
"""

from __future__ import annotations

import json
import os
import pathlib
import re
import shutil
import subprocess

import pytest
import yaml

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
    env_texto: str = "",
    sem_ambiente: tuple[str, ...] = (),
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    """`make` sobre o `Makefile` real copiado; devolve a execução e o que foi chamado.

    `binarios` troca ou acrescenta executáveis à frente do `PATH` — o `curl` da
    API, o `sleep` que não dorme —, e `None` tira um dos simulados padrão.
    `simulados` troca o corpo de um dos scripts do projeto — o preflight que
    recusa, o `conteineres.sh` que resolve um contêiner — ou põe no rascunho um
    arquivo a mais, como a composição dos bancos. `env_texto` é o `.env`, e
    `sem_ambiente` tira chaves do ambiente — `make test` exporta as do `.env`.
    """
    trabalho = tmp_path / "checkout"
    for relativo in SIMULADOS:
        caminho = trabalho / relativo
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text((simulados or {}).get(relativo, REGISTRADOR), encoding="utf-8")
        caminho.chmod(0o755)
    for relativo, corpo in (simulados or {}).items():
        if relativo not in SIMULADOS:
            (trabalho / relativo).parent.mkdir(parents=True, exist_ok=True)
            (trabalho / relativo).write_text(corpo, encoding="utf-8")
    (tmp_path / "bin").mkdir()
    for nome, script in ({"docker": docker, "curl": REGISTRADOR} | (binarios or {})).items():
        if script is None:
            continue
        (tmp_path / "bin" / nome).write_text(script, encoding="utf-8")
        (tmp_path / "bin" / nome).chmod(0o755)
    (trabalho / "Makefile").write_text((RAIZ / "Makefile").read_text(encoding="utf-8"), encoding="utf-8")
    (trabalho / ".env").write_text(env_texto, encoding="utf-8")
    (trabalho / "dbt").mkdir()
    registro = tmp_path / "chamadas"
    ambiente = {k: v for k, v in os.environ.items() if k not in sem_ambiente}
    ambiente |= {"PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}", "SIM_LOG": str(registro)}

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


# ── D55: a rede do projeto é externa, e nenhum `down` a remove ──────────────

#: As três composições que compartilham o projeto — e a rede dele.
COMPOSICOES = ("docker/docker-compose.yml", "docker/docker-compose.airflow.yml", "docker/docker-compose.streaming.yml")


@pytest.mark.parametrize("composicao", COMPOSICOES)
def test_as_composicoes_declaram_a_rede_do_projeto_como_externa(composicao):
    """D55: gerida pelo Compose, a rede ia embora no `make down` dos bancos, e os
    contêineres pausados do Airflow e do streaming ficavam presos ao ID antigo —
    `docker start` recusava, de 21/09 a 24/09/2026. Externa, nenhum `down` a
    remove. O nome é o que o Compose já dava, e os contêineres de pé ficam nela.
    """
    documento = yaml.safe_load((RAIZ / composicao).read_text(encoding="utf-8"))

    assert documento["networks"]["default"] == {"name": "${COMPOSE_PROJECT_NAME:-mvp_ed1}_default", "external": True}


#: Uma receita que sobe uma composição.
SOBE_COMPOSICAO = re.compile(r"\$\(COMPOSE(?:_AIRFLOW|_STREAM)?\) up\b")


def test_todo_up_do_compose_garante_a_rede_antes():
    """Externa, a rede não nasce do `up`: quem sobe uma composição a garante antes."""
    receitas = _receitas((RAIZ / "Makefile").read_text(encoding="utf-8"))
    sobem = {alvo: linhas for alvo, linhas in receitas.items() if any(SOBE_COMPOSICAO.search(l) for l in linhas)}

    sem_rede = []
    for alvo, linhas in sobem.items():
        sobe = next(i for i, l in enumerate(linhas) if SOBE_COMPOSICAO.search(l))
        if not any(l == "$(GARANTIR_REDE)" for l in linhas[:sobe]):
            sem_rede.append(alvo)

    assert sorted(sobem) == ["airflow-up", "stream-up", "up"], "o conjunto dos que sobem mudou — confira o padrão"
    assert sem_rede == [], "sobe composição sem garantir a rede antes: " + ", ".join(sem_rede)


#: `docker` que responde pela rede: `SIM_REDE=1` diz que ela existe, e
#: `SIM_CRIA=0` faz a criação falhar. O resto só é registrado.
DOCKER_DA_REDE = """#!/usr/bin/env bash
echo "docker $*" >> "$SIM_LOG"
case "$1 $2" in
  "network inspect") [ "${SIM_REDE:-0}" = 1 ] || exit 1 ;;
  "network create") [ "${SIM_CRIA:-1}" = 1 ] || exit 1 ;;
esac
exit 0
"""

#: O `conteineres.sh` real: é ele quem diz o nome do projeto, e daí o da rede.
CONTEINERES_REAL = (RAIZ / "docker" / "conteineres.sh").read_text(encoding="utf-8")


def _subir(tmp_path: pathlib.Path, **ambiente: str) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    return _make(
        tmp_path,
        "up",
        docker=DOCKER_DA_REDE,
        ambiente_extra={"COMPOSE_PROJECT_NAME": "mvp_ed1", **ambiente},
        simulados={"docker/conteineres.sh": CONTEINERES_REAL},
    )


@pytest.mark.parametrize("existe", [pytest.param(False, id="sem-rede"), pytest.param(True, id="com-rede")])
def test_make_up_cria_a_rede_so_quando_falta(tmp_path, existe):
    r, chamadas = _subir(tmp_path, SIM_REDE="1" if existe else "0")

    assert r.returncode == 0, r.stdout + r.stderr
    assert ("docker network create mvp_ed1_default" in chamadas) is (not existe), chamadas
    sobe = next(i for i, c in enumerate(chamadas) if c.startswith("docker compose") and " up " in c)
    assert chamadas.index("docker network inspect mvp_ed1_default") < sobe, chamadas


def test_sem_rede_nada_sobe(tmp_path):
    r, chamadas = _subir(tmp_path, SIM_REDE="0", SIM_CRIA="0")

    assert r.returncode != 0, r.stdout
    assert "a rede mvp_ed1_default não existe e não consegui criá-la" in r.stdout, r.stdout
    assert not any(c.startswith("docker compose") for c in chamadas), chamadas


@pytest.mark.parametrize("composicao", COMPOSICOES)
def test_as_composicoes_declaram_o_mesmo_projeto(composicao):
    """A do Airflow não declarava `name:`. Com o `.env` sem o nome, o Compose chamaria o projeto dela
    pela pasta — `docker` —, e o preflight, que procura os contêineres pelo rótulo do projeto, não
    veria o Airflow. Achado próprio, na aplicação do RVE4-01."""
    documento = yaml.safe_load((RAIZ / composicao).read_text(encoding="utf-8"))

    assert documento["name"] == "${COMPOSE_PROJECT_NAME:-mvp_ed1}"


# ── RVE4-01: o nome da rede é o que o Compose resolve ───────────────────────


def _compose_disponivel() -> bool:
    docker = shutil.which("docker")
    return bool(docker) and subprocess.run([docker, "compose", "version"], capture_output=True).returncode == 0


#: Só o `config` do Compose, que não fala com o daemon: nenhuma rede ou contêiner é tocado.
exige_compose = pytest.mark.skipif(not _compose_disponivel(), reason="exige o `docker compose` instalado")

#: O resto de um `.env` que a composição dos bancos aceita: sem as portas, o `config` não fecha.
PORTAS = "SOURCE_DB_PORT=5432\nLEGACY_DB_PORT=5433\nWAREHOUSE_DB_PORT=5434\n"

#: As formas do nome no `.env` que a leitura por `sed` lia diferente do Compose (E4-3), e as de controle.
FORMAS_DO_NOME = [
    pytest.param("COMPOSE_PROJECT_NAME=clone_etapa12\n", id="simples"),
    pytest.param('COMPOSE_PROJECT_NAME="clone_etapa12"\n', id="aspas"),
    pytest.param("COMPOSE_PROJECT_NAME=clone_etapa12 # clone\n", id="comentario"),
    pytest.param("export COMPOSE_PROJECT_NAME=clone_etapa12\n", id="export"),
    pytest.param("PREFIX=clone\nCOMPOSE_PROJECT_NAME=${PREFIX}_etapa12\n", id="expansao"),
    pytest.param("COMPOSE_PROJECT_NAME=mvp_ed1\nCOMPOSE_PROJECT_NAME=clone_etapa12\n", id="duplicado"),
    pytest.param("", id="sem-nome"),
    # RVE5-01: nomes que o YAML do `config` serializa entre aspas — `name: "123"`, `name: 'yes'` —, e
    # a extração por `sed` levava as aspas para o nome. O JSON do mesmo `config` é canônico.
    pytest.param("COMPOSE_PROJECT_NAME=123\n", id="numero"),
    pytest.param("COMPOSE_PROJECT_NAME=20260924\n", id="data"),
    pytest.param("COMPOSE_PROJECT_NAME=yes\n", id="yes"),
    pytest.param("COMPOSE_PROJECT_NAME=true\n", id="true"),
    pytest.param("COMPOSE_PROJECT_NAME=null\n", id="null"),
]

COMPOSE_BANCOS = (RAIZ / "docker" / "docker-compose.yml").read_text(encoding="utf-8")


def _ambiente_sem_projeto() -> dict[str, str]:
    """O ambiente sem `COMPOSE_PROJECT_NAME`: é o `.env` que precisa dizer o nome."""
    return {k: v for k, v in os.environ.items() if k != "COMPOSE_PROJECT_NAME"}


def _rascunho(tmp_path: pathlib.Path, nome: str) -> pathlib.Path:
    raiz = tmp_path / "rascunho"
    (raiz / "docker").mkdir(parents=True)
    (raiz / "docker" / "conteineres.sh").write_text(CONTEINERES_REAL, encoding="utf-8")
    (raiz / "docker" / "docker-compose.yml").write_text(COMPOSE_BANCOS, encoding="utf-8")
    (raiz / ".env").write_text(PORTAS + nome, encoding="utf-8")
    return raiz


def _config_do_compose(raiz: pathlib.Path, ambiente: dict[str, str]) -> dict:
    """A configuração que o Compose instalado resolve, lida por um leitor de JSON de verdade."""
    r = subprocess.run(
        ["docker", "compose", "--env-file", ".env", "-f", "docker/docker-compose.yml", "config", "--format", "json"],
        cwd=raiz, env=ambiente, capture_output=True, text=True, check=True, timeout=60,
    )
    return json.loads(r.stdout)


def _rede_que_o_compose_exige(raiz: pathlib.Path, ambiente: dict[str, str]) -> str:
    return _config_do_compose(raiz, ambiente)["networks"]["default"]["name"]


def _projeto(raiz: pathlib.Path, ambiente: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "docker/conteineres.sh", "projeto"], cwd=raiz, env=ambiente, capture_output=True, text=True, timeout=60
    )


@exige_compose
@pytest.mark.parametrize("nome", FORMAS_DO_NOME)
def test_a_rede_garantida_e_a_que_o_compose_exige(tmp_path, nome):
    """RVE4-01: `conteineres.sh projeto` lia o `.env` com `sed` — a primeira ocorrência, sem aspas nem
    espaços —, e o Compose o interpreta. Com `export`, comentário na linha, interpolação ou chave
    repetida, a garantia preparava uma rede e o Compose exigia outra. A comparação é com o Compose
    instalado, e não com uma ideia dele."""
    raiz = _rascunho(tmp_path, nome)
    ambiente = _ambiente_sem_projeto()

    r = _projeto(raiz, ambiente)

    assert r.returncode == 0, r.stdout + r.stderr
    assert f"{r.stdout.strip()}_default" == _rede_que_o_compose_exige(raiz, ambiente)


@exige_compose
def test_o_ambiente_vence_o_env(tmp_path):
    """A precedência que o Compose dá ao ambiente, preservada."""
    raiz = _rascunho(tmp_path, "COMPOSE_PROJECT_NAME=do_env\n")
    ambiente = _ambiente_sem_projeto() | {"COMPOSE_PROJECT_NAME": "do_ambiente"}

    r = _projeto(raiz, ambiente)

    assert r.stdout == "do_ambiente\n", r.stdout + r.stderr
    assert _rede_que_o_compose_exige(raiz, ambiente) == "do_ambiente_default"


#: O `docker` da rede, que passa o `config` ao Docker de verdade: o nome sai do Compose instalado, e
#: o resto — rede e subida — só é registrado.
DOCKER_DA_REDE_E_DO_COMPOSE = DOCKER_DA_REDE.replace(
    'echo "docker $*" >> "$SIM_LOG"\n',
    'echo "docker $*" >> "$SIM_LOG"\ncase " $* " in *" config "*) exec "$DOCKER_REAL" "$@" ;; esac\n',
    1,
)


@exige_compose
@pytest.mark.parametrize(
    "nome, rede",
    [
        pytest.param("export COMPOSE_PROJECT_NAME=rve4_clone_probe\n", "rve4_clone_probe_default", id="export-RVE4-01"),
        pytest.param("COMPOSE_PROJECT_NAME=123\n", "123_default", id="numero-RVE5-01"),
    ],
)
def test_make_up_garante_a_rede_que_o_compose_exige(tmp_path, nome, rede):
    """RVE4-01, a sonda do revisor: com `export` no `.env`, a garantia achava `mvp_ed1_default`, e o
    `make up` real parou em "network rve4_clone_probe_default declared as external, but could not
    be found". RVE5-01: com `123`, a correção procurava `"123"_default`, com as aspas do YAML."""
    r, chamadas = _make(
        tmp_path,
        "up",
        docker=DOCKER_DA_REDE_E_DO_COMPOSE,
        ambiente_extra={"SIM_REDE": "0", "DOCKER_REAL": shutil.which("docker") or "docker"},
        simulados={"docker/conteineres.sh": CONTEINERES_REAL, "docker/docker-compose.yml": COMPOSE_BANCOS},
        env_texto=PORTAS + nome,
        sem_ambiente=("COMPOSE_PROJECT_NAME",),
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert f"docker network create {rede}" in chamadas, chamadas
    assert [c for c in chamadas if c.startswith("docker network")] == [
        f"docker network inspect {rede}", f"docker network create {rede}"
    ], chamadas


def test_sem_o_nome_do_projeto_nada_sobe(tmp_path):
    """Se o Compose não diz o nome, a garantia não inventa um: "não sei" não é o padrão. O `docker`
    daqui não responde ao `config`."""
    r, chamadas = _make(
        tmp_path,
        "up",
        docker=DOCKER_DA_REDE,
        simulados={"docker/conteineres.sh": CONTEINERES_REAL},
        sem_ambiente=("COMPOSE_PROJECT_NAME",),
    )

    assert r.returncode != 0, r.stdout
    assert "o Compose não disse o nome do projeto" in r.stdout, r.stdout
    assert not any(c.startswith("docker network create") for c in chamadas), chamadas
    assert not any(c.startswith("docker compose") and " up " in c for c in chamadas), chamadas


#: `docker` que passa o `config` ao Docker de verdade e só registra o resto — é por ele que se lê o
#: filtro de projeto que o `resolver` manda ao `docker ps`.
DOCKER_QUE_REGISTRA = """#!/usr/bin/env bash
case " $* " in *" config "*) exec "$DOCKER_REAL" "$@" ;; esac
printf '%s\\n' "$*" >> "$SIM_LOG"
exit 0
"""


@exige_compose
@pytest.mark.parametrize("nome", FORMAS_DO_NOME)
def test_o_filtro_de_projeto_e_o_nome_que_o_compose_resolve(tmp_path, nome):
    """RVE5-01, o outro consumidor: o `resolver` do preflight procura os contêineres pelo rótulo do
    projeto. Com `name: "123"` no YAML, ele filtrava por `project="123"`, com as aspas."""
    raiz = _rascunho(tmp_path, nome)
    binario = tmp_path / "bin"
    binario.mkdir()
    (binario / "docker").write_text(DOCKER_QUE_REGISTRA, encoding="utf-8")
    (binario / "docker").chmod(0o755)
    registro = tmp_path / "chamadas"
    ambiente = _ambiente_sem_projeto()
    esperado = _config_do_compose(raiz, ambiente)["name"]

    r = subprocess.run(
        ["bash", "docker/conteineres.sh", "resolver", "airflow_scheduler"],
        cwd=raiz, capture_output=True, text=True, timeout=60,
        env=ambiente | {"PATH": f"{binario}:{os.environ['PATH']}", "DOCKER_REAL": shutil.which("docker") or "docker",
                        "SIM_LOG": str(registro)},
    )

    assert r.returncode == 0, r.stdout + r.stderr
    filtros = [p for linha in registro.read_text(encoding="utf-8").splitlines() for p in linha.split()
               if p.startswith("label=com.docker.compose.project=")]
    assert filtros == [f"label=com.docker.compose.project={esperado}"], filtros


# ── RV12-2-04: o check-offline, o primeiro comando do clone de B5 ───────────


def test_check_offline_nao_sobe_nem_consulta_nada(tmp_path):
    """Segredos, documentos e a suíte sem a marca `integracao` — nada de `dbt`, migração ou
    contêiner: é o que roda num clone antes de subir qualquer coisa."""
    r, chamadas = _make(tmp_path, "check-offline")

    assert r.returncode == 0, r.stdout + r.stderr
    assert chamadas[:3] == [
        "python -m mvp_ed1.secrets_review",
        "python -m mvp_ed1.docs_check",
        "pytest -q -rs -m not integracao",
    ], chamadas
    assert "pytest -q --co -m integracao" in chamadas, chamadas
    assert not any(c.split()[0] in {"dbt", "alembic", "docker", "abctl", "terraform"} for c in chamadas), chamadas


def test_check_offline_falha_quando_a_coleta_dos_de_integracao_falha(tmp_path):
    """RVB5-03: a terceira etapa é um encadeamento, e sem `pipefail` o código era o do `uniq` — a
    coleta que saía 2 terminava em "as três etapas passaram", sem o inventário do que ficou de fora."""
    coleta_que_falha = REGISTRADOR + 'case " $* " in *" --co "*) echo "coleta recusada" >&2; exit 2;; esac\n'
    r, chamadas = _make(tmp_path, "check-offline", simulados={".venv/bin/pytest": coleta_que_falha})

    assert r.returncode != 0, r.stdout + r.stderr
    assert "pytest -q --co -m integracao" in chamadas, chamadas
    assert "as três etapas passaram" not in r.stdout, r.stdout


def test_o_pytest_do_check_lista_os_pulados_com_motivo(tmp_path):
    """O `check` chama o `make test`, e o Termo pede a lista de pulados com motivo (plano, §7.6).
    Até 24/09/2026 só o `check-offline` a imprimia: o `-q` sozinho diz quantos, não quais."""
    r, chamadas = _make(tmp_path, "test")

    assert r.returncode == 0, r.stdout + r.stderr
    assert chamadas == ["pytest -q -rs"], chamadas


#: Os quatro que a sonda achou tocando o armazém ou o `dbt` (a do plano em 19/09 e a de 24/09, com a
#: suíte três vezes maior, acharam os mesmos): fora da seleção offline.
PRECISAM_DO_ARMAZEM = [
    "tests/test_consumo.py::test_toda_view_de_consumo_responde",
    "tests/test_consumo.py::test_as_dezesseis_perguntas_estao_publicadas",
    "tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao",
    "tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai",
]


def test_o_que_precisa_do_armazem_fica_fora_do_check_offline():
    r = subprocess.run(
        [str(RAIZ / ".venv" / "bin" / "pytest"), "--co", "-q", "-m", "not integracao", "-p", "no:cacheprovider",
         "tests/test_consumo.py", "tests/test_legacy_classification.py"],
        cwd=RAIZ, capture_output=True, text=True, timeout=120,
    )

    selecionados = set(r.stdout.split())
    assert not [t for t in PRECISAM_DO_ARMAZEM if t in selecionados], r.stdout
    assert any(t.startswith("tests/test_legacy_classification.py::") for t in selecionados), "os outros continuam"


# ── RV12-07: o install traz os pacotes dbt da trava ─────────────────────────


def test_install_traz_os_pacotes_dbt_da_trava(tmp_path):
    """Sem `dbt deps`, o primeiro comando dbt de um clone falhava no `parse` — medido na revisão do
    plano, com `dbt_utils`, `dbt_date` e `dbt_expectations` ausentes. As versões são as da trava
    versionada, lidas pelo próprio `dbt deps`."""
    r, chamadas = _make(tmp_path, "install", binarios={"uv": REGISTRADOR})

    assert r.returncode == 0, r.stdout + r.stderr
    assert chamadas[:2] == ["uv sync", "dbt deps"], chamadas
    assert "cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt deps" in r.stdout, r.stdout


# ── B5, linha 2: o airbyte-config num Airbyte recém-instalado ───────────────


def test_airbyte_config_aplica_um_recurso_por_vez(tmp_path):
    """Num Airbyte recém-instalado, a tabela de segredos nasce na primeira escrita, por `CREATE TABLE
    IF NOT EXISTS`, que o PostgreSQL não serializa: no B5, em 25/09/2026, o Terraform criou quatro
    recursos ao mesmo tempo, duas criações colidiram (`duplicate key … pg_type_typname_nsp_index`) e o
    Airbyte devolveu 500. Um recurso por vez."""
    r, chamadas = _make(tmp_path, "airbyte-config", "AUTO=1")

    assert r.returncode == 0, r.stdout + r.stderr
    aplicacoes = [c for c in chamadas if c.startswith("terraform") and " apply" in c]
    assert aplicacoes and all("-parallelism=1" in c.split() for c in aplicacoes), chamadas
