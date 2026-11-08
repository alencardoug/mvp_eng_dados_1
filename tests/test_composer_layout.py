"""O layout da DAG no Composer e o que a DAG lê do ambiente (Etapa 13, G2.4)."""

from __future__ import annotations

import ast
import pathlib
import re

import pytest

from mvp_ed1 import orquestracao
from mvp_ed1.gcp import composer

RAIZ = pathlib.Path(__file__).resolve().parent.parent
DAG = (RAIZ / "airflow" / "dags" / "fluxo_batch.py").read_text(encoding="utf-8")
DIAGNOSTICO = (RAIZ / "airflow" / "composer" / "diagnostico_composer.py").read_text(encoding="utf-8")
ORQUESTRACAO = (RAIZ / "src" / "mvp_ed1" / "orquestracao.py").read_text(encoding="utf-8")
#: O prefixo de todo comando dbt das DAGs, como o `bash` o recebe.
DBT = orquestracao.DBT


def test_as_dags_nao_fixam_o_caminho_do_projeto():
    for fonte in (DAG, DIAGNOSTICO, ORQUESTRACAO):
        codigo = [no for no in ast.parse(fonte).body if not isinstance(no, ast.Expr)]  # sem a docstring
        assert "/opt/mvp_ed1" not in "".join(ast.unparse(no) for no in codigo)
    assert DBT.startswith('cd "${MVP_PROJECT_DIR:?')
    # As duas DAGs usam o mesmo prefixo, importado do pacote — nenhuma o reescreve.
    for fonte in (DAG, DIAGNOSTICO):
        assert "from mvp_ed1.orquestracao import DBT" in fonte and "mktemp" not in fonte


def test_target_e_logs_do_dbt_num_temporario_que_some():
    assert 'ARTEFATOS="$(mktemp -d)" && trap \'rm -rf "$ARTEFATOS"\' EXIT' in DBT
    assert DBT.endswith('DBT_TARGET_PATH="$ARTEFATOS/target" DBT_LOG_PATH="$ARTEFATOS/logs" dbt')


def test_o_compose_local_da_a_variavel_e_monta_o_dbt_so_para_leitura():
    compose = (RAIZ / "docker" / "docker-compose.airflow.yml").read_text(encoding="utf-8")
    assert "MVP_PROJECT_DIR: /opt/mvp_ed1" in compose
    assert "- ../dbt:/opt/mvp_ed1/dbt:ro" in compose


def test_o_layout_monta_dags_e_data_sem_o_que_e_gerado(tmp_path):
    destino = tmp_path / "gcs"
    montados = composer.montar(destino)
    assert montados == sorted([*composer.LAYOUT, "dags/.airflowignore"])
    assert (destino / "dags/fluxo_batch.py").read_text(encoding="utf-8") == DAG
    assert (destino / "dags/diagnostico_composer.py").read_text(encoding="utf-8") == DIAGNOSTICO
    assert (destino / "dags/mvp_ed1/__init__.py").exists()
    assert (destino / "dags/.airflowignore").read_text(encoding="utf-8") == "mvp_ed1/\n"
    assert (destino / "data/dbt/dbt_project.yml").exists() and (destino / "data/dbt/dbt_packages").is_dir()
    # Os `docs-paths` do dbt leem o glossário por `../docs/…`: ele fica ao lado do projeto.
    assert (destino / "data/docs/glossario_de_negocio").is_dir()
    for gerado in ("target", "target_gcp", "logs"):
        assert not (destino / "data/dbt" / gerado).exists()
    assert not list(destino.rglob("__pycache__"))


def test_o_layout_nao_monta_por_cima(tmp_path):
    with pytest.raises(SystemExit, match="já existe"):
        composer.montar(tmp_path)


def test_os_pacotes_do_composer_sao_os_da_trava():
    pacotes = composer.pacotes()
    assert set(pacotes) == {"dbt-core", "dbt-bigquery", "google-api-core"}
    trava = (RAIZ / "uv.lock").read_text(encoding="utf-8")
    for nome, versao in pacotes.items():
        assert re.search(rf'name = "{nome}"\nversion = "{re.escape(versao[2:])}"', trava), nome
    # A correção do problema conhecido de 30/10/2026 no Composer com Python 3.11.
    principal, menor, patch = map(int, pacotes["google-api-core"][2:].split("."))
    assert (principal, menor, patch) >= (2, 43, 1)
