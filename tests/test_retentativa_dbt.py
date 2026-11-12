"""A re-tentativa do dbt só para infraestrutura transitória (Registro §55, passo 9; decisão de 11/11).

A cola é exercitada no `bash` de verdade: um `dbt` falso grava o `run_results.json` de cada cenário
no diretório de artefatos da tarefa, e o teste confere quantas vezes ele foi chamado e com o quê.
"""

from __future__ import annotations

import json
import pathlib
import subprocess

import pytest

from mvp_ed1 import orquestracao

RAIZ = pathlib.Path(__file__).resolve().parent.parent
DAG = (RAIZ / "airflow" / "dags" / "fluxo_batch.py").read_text(encoding="utf-8")

#: A mensagem real da 503 de 11/11 (dbt_staging, not_null_stg_legacy__coupons_snapshot_id).
DE_11_11 = ("Unable to generate access token … ('Unable to acquire impersonated credentials', "
            '\'{"error": {"code": 503, "message": "Authentication backend unavailable.", "status": "UNAVAILABLE"}}\')')

CENARIOS = {
    "transitorio": ([{"status": "success"}, {"status": "error", "message": DE_11_11}], True),
    "teste_vermelho": ([{"status": "fail", "message": "Got 3 results, configured to fail if != 0"}], False),
    "vermelho_e_transitorio": ([{"status": "fail", "message": "Got 3 results"},
                                {"status": "error", "message": DE_11_11}], False),
    "permissao": ([{"status": "error", "message": "Access Denied: Permission bigquery.datasets.update denied"}], False),
    "sql": ([{"status": "error", "message": "Syntax error: Unexpected keyword"}], False),
    "nada_falhou": ([{"status": "success"}, {"status": "pass"}], False),
}


@pytest.mark.parametrize("nome", CENARIOS)
def test_o_classificador_e_o_criterio_no_processo_concordam(nome, tmp_path):
    resultados, esperado = CENARIOS[nome]
    assert orquestracao.falha_transitoria({"results": resultados}) is esperado
    arquivo = tmp_path / "run_results.json"
    arquivo.write_text(json.dumps({"results": resultados}))
    rc = subprocess.run(["python3", "-c", orquestracao.CLASSIFICADOR, str(arquivo)]).returncode
    assert (rc == 0) is esperado


def test_sem_run_results_nao_re_tenta(tmp_path):
    rc = subprocess.run(["python3", "-c", orquestracao.CLASSIFICADOR, str(tmp_path / "nao_existe.json")]).returncode
    assert rc == 1


def _rodar(tmp_path, nome):
    """O comando da camada (`DBT` + build + a re-tentativa) num `bash`, com um `dbt` falso."""
    resultados, _ = CENARIOS[nome]
    (tmp_path / "projeto" / "dbt").mkdir(parents=True)
    binarios = tmp_path / "bin"
    binarios.mkdir()
    chamadas = tmp_path / "chamadas.txt"
    cenario = tmp_path / "cenario.json"
    cenario.write_text(json.dumps({"results": resultados}))
    falso = binarios / "dbt"
    falso.write_text(
        "#!/bin/bash\n"
        f'echo "$*" >> "{chamadas}"\n'
        'mkdir -p "$DBT_TARGET_PATH"\n'
        'if [ "$1" = retry ]; then echo \'{"results": [{"status": "success"}]}\' > "$DBT_TARGET_PATH/run_results.json"; exit 0; fi\n'
        f'cp "{cenario}" "$DBT_TARGET_PATH/run_results.json"\n'
        'grep -q \'"status": "\\(error\\|fail\\)"\' "$DBT_TARGET_PATH/run_results.json" && exit 1 || exit 0\n'
    )
    falso.chmod(0o755)
    comando = f"{orquestracao.DBT} build --select staging" + orquestracao.RETENTAR_SE_TRANSITORIO
    ambiente = {"PATH": f"{binarios}:/usr/bin:/bin", "MVP_PROJECT_DIR": str(tmp_path / "projeto")}
    rc = subprocess.run(["bash", "-c", comando], env=ambiente, capture_output=True, text=True).returncode
    return rc, chamadas.read_text().splitlines()


def test_a_503_de_11_11_re_tenta_uma_vez_e_passa(tmp_path):
    rc, chamadas = _rodar(tmp_path, "transitorio")
    assert rc == 0 and chamadas == ["build --select staging", "retry"]


@pytest.mark.parametrize("nome", ["teste_vermelho", "vermelho_e_transitorio", "permissao", "sql"])
def test_o_resto_falha_sem_re_tentar(tmp_path, nome):
    rc, chamadas = _rodar(tmp_path, nome)
    assert rc != 0 and chamadas == ["build --select staging"]


def test_a_dag_acrescenta_a_re_tentativa_a_toda_camada_e_mantem_retries_0():
    assert '.strip() + RETENTAR_SE_TRANSITORIO' in DAG
    assert '"retries": 0' in DAG
