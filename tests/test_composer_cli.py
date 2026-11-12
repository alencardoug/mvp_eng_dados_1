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
    assert "&& \\" not in oraculos and oraculos.count("rc=1; }") == 3 and "exit $$rc" in oraculos


def test_a_classificacao_por_captura_nao_e_comparada_entre_ambientes():
    """D85: a classificação casa por `snapshot_id`, que é o job de cada Airbyte."""
    oraculos = _receita("gcp-oraculos")
    assert "legacy_classifications" not in oraculos and "não é comparável entre ambientes (D85)" in oraculos


def test_o_port_forward_e_o_proxy_sao_o_proprio_processo_e_o_token_nao_vai_na_linha():
    kubectl = _variavel("GKE_KUBECTL")
    airbyte = _variavel("GKE_AIRBYTE")
    assert "--token" not in kubectl and "kubeconfig" in kubectl and "umask 077" in kubectl
    assert "k -n airbyte port-forward" not in airbyte and "$$KUBECTL -n airbyte port-forward" in airbyte
    assert "$(call GCP_PORTA_LIVRE,$(GCP_AIRBYTE_PORTA))" in airbyte
    assert "$(call GCP_PORTA_LIVRE,$(GCP_SQL_PORTA))" in _variavel("GCP_ORIGENS")
    assert "wait $$pids" in MAKEFILE.split("\nGCP_LIMPEZA = ", 1)[1].split("\n", 1)[0]


def test_o_reinicio_do_debezium_e_conferido_pelo_log_e_nao_so_pelo_rollout():
    """RV13J-2-01, RV13J-3-01: o MERGE suprime um snapshot refeito, e só o log do pod novo o mostra."""
    receita = _receita("gcp-debezium-reiniciar")
    assert receita.index("rollout status") < receita.index("--sort-by=.metadata.creationTimestamp") \
        < receita.index("mvp_ed1.gcp.debezium_log")
    assert "test $$rc = 3 || break" in receita and "grep" not in receita
    # RV13J-4-01: a listagem que falha com saída parcial não escolhe pod nenhum.
    assert "-o name | tail" not in receita and "-o name) \\\n\t\t|| { echo \"ERRO: a listagem dos pods" in receita
    assert '0) echo "gcp-debezium-reiniciar' in receita and "exit 2 ;;" in receita


RETOMOU = """INFO Found previous offset PostgresOffsetContext [lsn=1]
INFO A previous offset indicating a completed snapshot has been found.
INFO Starting streaming
"""


@pytest.mark.parametrize("texto, esperado", [
    (RETOMOU, 0),
    ("", 3),
    ("INFO Found previous offset PostgresOffsetContext\n", 3),            # ainda não decidiu
    ("INFO No previous offset found\nINFO Starting streaming\n", 2),     # contém "previous offset", não é retomada
    ("INFO A previous offset indicating a completed snapshot has been found.\n", 3),
    (RETOMOU + "INFO Snapshot step 1 - Preparing\n", 1),
    ("INFO No previous offsets found\nINFO Snapshot step 1 - Preparing\nINFO Snapshot completed\nINFO Starting streaming\n", 1),
    ("INFO Starting streaming\nINFO A previous offset indicating a completed snapshot has been found.\n", 2),
])
def test_o_veredito_do_log_so_aprova_retomada_dita_antes_do_streaming(texto, esperado):
    from mvp_ed1.gcp import debezium_log

    assert debezium_log.veredito(texto)[0] == esperado


def _parar_com_gcloud_falso(tmp_path, assinaturas: list[str]):
    """Roda a receita de verdade, com `gcloud` e Terraform falsos e nenhum *job* ativo."""
    import os
    import subprocess

    receita = MAKEFILE.split("\ngcp-dataflow-parar:", 1)[1].split("\n\n", 1)[0].split("\n", 1)[1]
    falsos = tmp_path / "bin"
    falsos.mkdir()
    (tmp_path / "lista").write_text("\n".join(assinaturas), encoding="utf-8")
    (tmp_path / "apagadas").write_text("", encoding="utf-8")
    (falsos / "gcloud").write_text(
        "#!/bin/sh\n"
        f'L="{tmp_path}/lista"; A="{tmp_path}/apagadas"\n'
        'case "$1 $2 $3" in\n'
        '  "dataflow jobs list") exit 0;;\n'
        '  "pubsub subscriptions list") cat "$L"; exit 0;;\n'
        '  "pubsub subscriptions delete") echo "$4" >> "$A"; grep -vxF "$4" "$L" > "$L.n"; mv "$L.n" "$L"; exit 0;;\n'
        "esac\nexit 9\n", encoding="utf-8")
    tf = falsos / "terraform"
    tf.write_text('#!/bin/sh\necho \'{"regiao": "us-central1"}\'\n', encoding="utf-8")
    for f in (falsos / "gcloud", tf):
        f.chmod(0o755)
    (tmp_path / ".venv" / "bin").mkdir(parents=True)
    python = tmp_path / ".venv" / "bin" / "python"
    python.write_text(f'#!/bin/sh\nexec "{RAIZ / ".venv" / "bin" / "python"}" "$@"\n', encoding="utf-8")
    python.chmod(0o755)
    (tmp_path / "Makefile").write_text(
        f"GCP_ENV = GCP_PROJECT_ID=p\nGCP_TF := {tf}\nDATAFLOW_JOB := j\n\nparar:\n{receita}\n", encoding="utf-8")
    ambiente = {**os.environ, "PATH": f"{falsos}:{os.environ['PATH']}"}
    r = subprocess.run(["make", "--no-print-directory", "parar"], cwd=tmp_path, capture_output=True, text=True, env=ambiente)
    return r, (tmp_path / "apagadas").read_text(encoding="utf-8").split()


def test_a_assinatura_de_watermark_que_sobra_e_apagada_e_provada(tmp_path):
    """RVT-1-04: cancelado, o Dataflow pode deixar a `…beam__df_internal…`; a receita a apaga e prova."""
    sobra = "projects/p/subscriptions/mvp.oltp.inventory_movements.beam__df_internal71aae1e0"
    r, apagadas = _parar_com_gcloud_falso(tmp_path, [sobra])
    assert r.returncode == 0, r.stdout + r.stderr
    assert apagadas == [sobra] and "a assinatura de watermark que sobrou foi apagada" in r.stdout


def test_so_a_assinatura_com_o_prefixo_exato_e_apagada(tmp_path):
    """O filtro do `gcloud` casa por trecho; o nome que só contém o prefixo não é apagado."""
    intrusa = "projects/p/subscriptions/outra.mvp.oltp.inventory_movements.beam__df_internalx"
    r, apagadas = _parar_com_gcloud_falso(tmp_path, [intrusa])
    assert r.returncode != 0 and apagadas == []
    assert "não é a assinatura de watermark; não apago" in r.stdout


def test_sem_sobra_nada_e_apagado(tmp_path):
    r, apagadas = _parar_com_gcloud_falso(tmp_path, [])
    assert r.returncode == 0 and apagadas == [] and "nenhuma assinatura de watermark sobrando" in r.stdout


def test_job_do_airbyte_sem_estado_final_conta_como_em_curso():
    """RVT-1-04: antes de o degrau das aplicações sair, nenhum *job* do Airbyte no ar."""
    from mvp_ed1 import airbyte

    listagem = {"data": [
        {"jobId": 1, "status": "succeeded"}, {"jobId": 2, "status": "failed"},
        {"jobId": 3, "status": "cancelled"}, {"jobId": 4, "status": "incomplete"},
        {"jobId": 5, "status": "running"}, {"jobId": 6, "status": "pending"}, {"jobId": 7},
    ]}
    assert [j["jobId"] for j in airbyte.em_curso(listagem)] == [5, 6, 7]
    assert airbyte.em_curso({"data": []}) == [] and airbyte.em_curso(None) == []


def test_o_digest_do_debezium_e_lido_do_values_e_comparado_com_a_tag_ativa():
    """RVT-1-01: a quarta começa conferindo o digest; duas versões ativas ou nenhuma não concluem nada."""
    from mvp_ed1.gcp import imagem_debezium as im

    repo, tag, digest = im.fixada(im.VALORES.read_text(encoding="utf-8"))
    assert (repo, tag) == ("debezium/server", "3.7.1.Final") and digest.startswith("sha256:")
    with pytest.raises(ValueError):
        im.fixada("imagem: quay.io/debezium/server:3.7.1.Final\n")
    a, b = "sha256:" + "a" * 64, "sha256:" + "b" * 64
    assert im.vigente({"tags": [{"name": tag, "manifest_digest": a, "end_ts": None},
                                {"name": tag, "manifest_digest": b, "end_ts": 1}]}, tag) == a
    for ruim in ({"tags": []}, {"tags": [{"name": tag, "manifest_digest": a, "end_ts": None}] * 2}):
        with pytest.raises(ValueError):
            im.vigente(ruim, tag)


def test_a_exportacao_acusa_a_enumeracao_dos_datasets_que_falha():
    """RVT-2-03: sem a lista das camadas, o manifesto diz FALHOU e o alvo não sai com sucesso."""
    receita = MAKEFILE.split("\ngcp-evidencias:", 1)[1].split("\n\n", 1)[0]
    assert "for ds in $$lista airbyte_internal; do" in receita
    assert receita.index('test -n "$$lista"') < receita.index("for ds in $$lista")
    assert 'echo "FALHOU enumeracao_datasets' in receita and "grep -q '^FALHOU'" in receita


#: O stdout do `gcloud composer environments run` no Composer 3 (Airflow 3), lido em 11/11/2026
#: (Registro §55, passo 6): linhas de log antes da resposta, uma delas começada por `[`.
PREAMBULO = (
    "2026-11-11 19:16:39 [debug    ] Getting connection using `google.auth.default()` since no explicit"
    " credentials are provided.\n"
    "[2026-11-11T19:16:44.162937Z] {{/opt/python3.11/lib/python3.11/site-packages/airflow/cli/commands/"
    "dag_command.py:50}} WARNING - Could not import graphviz. Rendering graph to the graphical format will"
    " not be possible.\n"
    "You might need to install the graphviz package and necessary system packages.\n"
    "Run `pip install graphviz` to attempt to install it. category=UserWarning\n"
)


def test_o_preambulo_de_log_do_composer_3_nao_impede_a_leitura():
    assert composer_cli.erros_de_importacao(PREAMBULO + "[]\n") == []
    assert composer_cli.execucoes(PREAMBULO + json.dumps([{"run_id": "a"}], indent=2)) == 1
    assert composer_cli.execucoes(PREAMBULO + "No data found\n") == 0
    lista = PREAMBULO + json.dumps([{"run_id": "b", "state": "running"}])
    assert composer_cli.estado(lista, "b") == "running"


@pytest.mark.parametrize("texto", [PREAMBULO, PREAMBULO + "Traceback (most recent call last)\n",
                                   PREAMBULO + "[1, 2]\n"])
def test_so_preambulo_ou_resposta_invalida_depois_dele_e_erro(texto):
    with pytest.raises(composer_cli.RespostaInvalida):
        composer_cli.execucoes(texto)


def test_erro_de_importacao_sai_com_1_e_o_smoke_usa_o_leitor(monkeypatch, capsys):
    import io

    erros = [{"filepath": "/home/airflow/gcs/dags/fluxo_batch.py", "error": "ImportError: x"}]
    monkeypatch.setattr("sys.stdin", io.StringIO(PREAMBULO + json.dumps(erros)))
    assert composer_cli.main(["importacao"]) == 1
    monkeypatch.setattr("sys.stdin", io.StringIO(PREAMBULO + "[]"))
    assert composer_cli.main(["importacao"]) == 0
    assert "sem erro" in capsys.readouterr().out
    monkeypatch.setattr("sys.stdin", io.StringIO(""))
    assert composer_cli.main(["importacao"]) == 1
    assert "composer_cli importacao" in _receita("gcp-composer-smoke")


def test_a_exportacao_le_o_cloud_logging_e_nao_aceita_zero():
    """No Composer 3 os logs não ficam no bucket: em 11/11 o `rsync` copiou 0 arquivos (Registro §55)."""
    receita = _receita("gcp-composer-exportar")
    assert "gcloud logging read" in receita and "storage rsync" not in receita
    assert 'resource.labels.environment_name=\\"$$nome\\"' in receita
    assert 'labels.workflow=\\"$$dag\\"' in receita
    assert 'test "$$total" -gt 0' in receita
    assert "\nCOMPOSER_DAGS := fluxo_batch diagnostico_composer\n" in MAKEFILE
