"""As respostas da CLI do Airflow e as receitas que as leem: só se aceita o que se prova (RV13J-1-07, -08, -12, -13)."""

from __future__ import annotations

import json
import pathlib

import pytest

from mvp_ed1.gcp import composer_cli

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MAKEFILE = (RAIZ / "Makefile").read_text(encoding="utf-8")


def _receita(alvo: str) -> str:
    return MAKEFILE.split(f"\n{alvo}:", 1)[1].split("\n\n", 1)[0]


def _variavel(nome: str) -> str:
    return MAKEFILE.split(f"\n{nome} = ", 1)[1].split("\n\n", 1)[0]


@pytest.mark.parametrize("texto", ["", "   \n", "Traceback (most recent call last)", '{"run_id": "a"}', "[1, 2]"])
def test_resposta_vazia_ou_invalida_nao_e_zero_execucoes(texto):
    with pytest.raises(composer_cli.RespostaInvalida):
        composer_cli.execucoes(texto)


def test_sem_dados_e_zero_e_a_lista_conta():
    assert composer_cli.execucoes("No data found\n") == 0
    assert composer_cli.execucoes(json.dumps([{"run_id": "a"}, {"run_id": "b"}])) == 2


def test_o_estado_e_o_da_execucao_pedida():
    lista = json.dumps([{"run_id": "a", "state": "running"}, {"run_id": "b", "state": "success"}])
    assert composer_cli.estado(lista, "b") == "success"
    assert composer_cli.estado(lista, "c") == ""


TAREFAS = [{"task_id": "sync", "state": "success", "start_date": "2026-11-11T10:00:00+00:00",
            "end_date": "2026-11-11T10:04:30+00:00"},
           {"task_id": "dbt_build", "state": "success", "start_date": "2026-11-11T10:05:00Z",
            "end_date": "2026-11-11T10:25:00Z"}]


def test_as_tarefas_terminadas_levam_a_duracao(tmp_path):
    lista = composer_cli.tarefas(json.dumps(TAREFAS), terminada=True)
    assert [t["duracao_s"] for t in lista] == [270.0, 1200.0]


@pytest.mark.parametrize("texto", ["", "[]", json.dumps([{"task_id": "sync", "state": "success",
                                                         "start_date": "2026-11-11T10:00:00Z", "end_date": None}])])
def test_tarefas_sem_tempo_final_nao_viram_evidencia(texto, tmp_path, monkeypatch, capsys):
    import io

    saida = tmp_path / "run.json"
    monkeypatch.setattr("sys.stdin", io.StringIO(texto))
    assert composer_cli.main(["tarefas", "--saida", str(saida), "--terminada"]) == 1
    assert not saida.exists()


def test_as_receitas_usam_o_leitor_estrito():
    rodar = _variavel("COMPOSER_RODAR")
    tarefas = _variavel("COMPOSER_TAREFAS")
    assert "composer_cli estado" in rodar and "$(call COMPOSER_TAREFAS," in rodar
    assert "set -o pipefail" in tarefas and "composer_cli tarefas" in tarefas and "|| tarefas=" in tarefas
    assert 'test -n "$$tarefas" ||' in rodar, "sucesso da DAG sem os tempos não é sucesso do alvo"
    parar = _receita("gcp-desmonte-parar")
    assert "composer_cli execucoes" in parar and "python -c" not in parar
    assert 'resposta=$$(g dags list-runs' in parar and "|| { echo \"ERRO: a listagem" in parar


def test_listagem_que_falha_no_dataflow_nao_e_nenhum_job():
    parar = _receita("gcp-dataflow-parar")
    assert 'test -z "$$(ativos)"' not in parar and "for id in $$(ativos)" not in parar
    assert "vazio() { ids=$$(ativos) || {" in parar


def test_cada_oraculo_tem_o_seu_veredito():
    oraculos = _receita("gcp-oraculos")
    assert "&& \\" not in oraculos and oraculos.count("rc=1; }") == 4 and "exit $$rc" in oraculos


def test_o_port_forward_e_o_proxy_sao_o_proprio_processo_e_o_token_nao_vai_na_linha():
    kubectl = _variavel("GKE_KUBECTL")
    airbyte = _variavel("GKE_AIRBYTE")
    assert "--token" not in kubectl and "kubeconfig" in kubectl and "umask 077" in kubectl
    assert "k -n airbyte port-forward" not in airbyte and "$$KUBECTL -n airbyte port-forward" in airbyte
    assert "$(call GCP_PORTA_LIVRE,$(GCP_AIRBYTE_PORTA))" in airbyte
    assert "$(call GCP_PORTA_LIVRE,$(GCP_SQL_PORTA))" in _variavel("GCP_ORIGENS")
    assert "wait $$pids" in MAKEFILE.split("\nGCP_LIMPEZA = ", 1)[1].split("\n", 1)[0]
