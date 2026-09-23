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
"""

from __future__ import annotations

import os
import pathlib
import re
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
#: scripts do projeto. O `docker` vai à frente do `PATH`.
SIMULADOS = (
    ".tools/abctl", ".tools/terraform",
    ".venv/bin/alembic", ".venv/bin/dbt", ".venv/bin/python", ".venv/bin/pytest",
    "docker/preflight.sh", "docker/conteineres.sh", "docker/airflow_cli.sh",
    "docker/medir.sh", "docker/airbyte_jobs.sh",
)


def _make(
    tmp_path: pathlib.Path, *argumentos: str, docker: str = REGISTRADOR, ambiente_extra: dict[str, str] | None = None
) -> tuple[subprocess.CompletedProcess[str], list[str]]:
    """`make` sobre o `Makefile` real copiado; devolve a execução e o que foi chamado."""
    trabalho = tmp_path / "checkout"
    for relativo in SIMULADOS:
        caminho = trabalho / relativo
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text(REGISTRADOR, encoding="utf-8")
        caminho.chmod(0o755)
    (tmp_path / "bin").mkdir()
    (tmp_path / "bin" / "docker").write_text(docker, encoding="utf-8")
    (tmp_path / "bin" / "docker").chmod(0o755)
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
#: (`SIM_PAUSADO=1`) ou não existe, e o nó tem pod pronto.
DOCKER_DO_CLUSTER = """#!/usr/bin/env bash
echo "docker $*" >> "$SIM_LOG"
case "$1" in
  ps) [ "${SIM_PAUSADO:-0}" = 1 ] && echo 3f2a1b ;;
  exec) echo "POD ID  CREATED  STATE  NAME  Ready" ;;
esac
exit 0
"""


def test_airbyte_up_retoma_o_cluster_pausado_sem_reinstalar(tmp_path):
    """O comportamento que a variável substituiu, conferido sem `-n`."""
    r, chamadas = _make(tmp_path, "airbyte-up", docker=DOCKER_DO_CLUSTER, ambiente_extra={"SIM_PAUSADO": "1"})

    assert r.returncode == 0, r.stdout + r.stderr
    assert "cluster pausado — retomando em vez de reinstalar" in r.stdout
    assert "aguardando o cluster pronto." in r.stdout
    assert "docker start airbyte-abctl-control-plane" in chamadas
    assert not any(c.startswith("abctl") for c in chamadas), chamadas


def test_airbyte_up_instala_quando_nao_ha_cluster(tmp_path):
    r, chamadas = _make(tmp_path, "airbyte-up", docker=DOCKER_DO_CLUSTER)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "abctl local install --values airbyte/values.yaml" in chamadas
    assert "docker start airbyte-abctl-control-plane" not in chamadas


def test_airbyte_resume_continua_retomando(tmp_path):
    r, chamadas = _make(tmp_path, "airbyte-resume", docker=DOCKER_DO_CLUSTER, ambiente_extra={"SIM_PAUSADO": "1"})

    assert r.returncode == 0, r.stdout + r.stderr
    assert "aguardando o cluster pronto." in r.stdout
    assert chamadas[0] == "docker start airbyte-abctl-control-plane"
