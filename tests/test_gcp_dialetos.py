"""A tradução para o BigQuery e os oráculos da Etapa 13 (PLANO_etapa_13 G1)."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from mvp_ed1.gcp.compilacao import comparar
from mvp_ed1.gcp.oraculo import _campos_json
from mvp_ed1.legacy.bigquery import _argumento_sql, dois_dialetos, para_bigquery
from mvp_ed1.legacy.catalogo import carregar
from mvp_ed1.legacy.classification import classification_sql_bigquery


def test_cte_de_values_mantem_os_nomes_das_colunas():
    sql = para_bigquery("with d (tabela) as (values ('a'), ('b')) select d.tabela from d")
    assert "'a' AS tabela" in sql and "_c0" not in sql


def test_select_sem_from_com_where_ganha_uma_linha():
    sql = para_bigquery("select 1 as x where not exists (select 1 from t)")
    assert "sem_from" in sql


def test_literal_jsonb_vira_parse_json():
    assert "PARSE_JSON('{\"a\": 1}')" in para_bigquery("select '{\"a\": 1}'::jsonb as c")


def test_argumento_sql_de_macro_de_canonizacao_e_traduzido():
    assert _argumento_sql("""{{ chave_canonica('r."id"', 'bigint') }}""") == \
        "{{ chave_canonica('r.`id`', 'bigint') }}"
    traduzido = _argumento_sql("""{{ chave_canonica("p.cleaned_payload->>'order_id'", 'bigint') }}""")
    assert "->>" not in traduzido and "order_id" in traduzido
    # Outra macro passa intacta.
    assert _argumento_sql("{{ ref('x') }}") == "{{ ref('x') }}"


def test_corpo_bigquery_a_mao_substitui_a_traducao_e_preserva_o_postgres():
    conteudo = "-- cabeçalho\nselect 1 as x\n"
    saida = dois_dialetos(conteudo, "select 2 as x\n")
    assert saida == ("-- cabeçalho\n{% if target.type == 'bigquery' %}\nselect 2 as x\n"
                     "{% else %}select 1 as x{% endif %}\n")


def test_classificacao_bigquery_sem_marcador_e_com_literais_do_googlesql():
    sql = classification_sql_bigquery(carregar(), fingerprint="abc")
    assert "__" not in sql.replace("__RECORDS__", "")  # nenhum marcador sobra
    assert '"abc" as treatment_fingerprint' in sql
    assert "''" not in sql.split("rules as")[1].split("records as")[0]  # aspa do BigQuery, não do PG


def test_oraculo_compara_campos_escolhidos_do_json():
    valor = '[{"code": "A", "column": "x", "cleaned_value": "2026-09-02T00:00:00Z"}]'
    assert _campos_json(valor, ["code", "column"]) == (("A", "x"),)


def test_oraculo_de_compilacao_separa_igual_equivalente_e_diferente(tmp_path: Path):
    antes, depois = tmp_path / "a", tmp_path / "d"
    for raiz in (antes, depois):
        raiz.mkdir()
    (antes / "igual.sql").write_text("select 1")
    (depois / "igual.sql").write_text("select 1")
    (antes / "eq.sql").write_text("select x::int from t -- comentário")
    (depois / "eq.sql").write_text("select cast(x as int)\nfrom t")
    (antes / "dif.sql").write_text("select 1")
    (depois / "dif.sql").write_text("select 2")
    r = comparar(antes, depois)
    assert r["igual"] == ["igual.sql"] and r["equivalente"] == ["eq.sql"] and r["diferente"] == ["dif.sql"]


# ── A canonização no BigQuery contra a mesma fronteira do PostgreSQL ─────────
#
# `test_legado_remocao` prova que a `default__chave_canonica` devolve o que o `cast` do
# PostgreSQL devolve, forma a forma, e que `remocao.canonizar` (Python) concorda com os
# dois. Aqui a `bigquery__chave_canonica` roda no BigQuery sobre as mesmas formas e é
# comparada com o Python — logo, com o `cast` do PostgreSQL. Só com `GCP_TESTES=1`: o
# projeto é destruído no fim da Etapa 13, e o `make check` não pode depender dele.


def _macro_bigquery():
    import jinja2

    class _Excecoes:
        def raise_compiler_error(self, mensagem):  # noqa: D401 — a interface do dbt
            raise RuntimeError(mensagem)

    fonte = Path("dbt/macros/chave_canonica.sql").read_text(encoding="utf-8")
    modulo = jinja2.Environment().from_string(fonte, globals={"exceptions": _Excecoes()}).module
    return modulo.bigquery__chave_canonica


@pytest.mark.skipif(os.environ.get("GCP_TESTES") != "1", reason="só com GCP_TESTES=1 (BigQuery real)")
@pytest.mark.parametrize("tipo", ["bigint", "integer", "smallint", "uuid"])
def test_chave_canonica_no_bigquery_devolve_o_que_o_postgresql_devolve(tipo):
    from google.cloud import bigquery

    from mvp_ed1.legacy import remocao
    from tests.test_legado_remocao import FORMAS

    formas = FORMAS[tipo]
    cliente = bigquery.Client(project=os.environ["GCP_PROJECT_ID"])
    sql = f"select i, {_macro_bigquery()('v', tipo)} as chave from unnest(@formas) as v with offset i"
    linhas = cliente.query(sql, job_config=bigquery.QueryJobConfig(query_parameters=[
        bigquery.ArrayQueryParameter("formas", "STRING", formas)])).result()
    no_bigquery = {r["i"]: r["chave"] for r in linhas}
    divergencias = [(f[:40], no_bigquery.get(i), remocao.canonizar(f, tipo))
                    for i, f in enumerate(formas) if no_bigquery.get(i) != remocao.canonizar(f, tipo)]
    assert not divergencias, divergencias


# ── A medição da D43 (`mvp_ed1.gcp.identidades`) ─────────────────────────────


def test_identidades_conta_recusa_dos_dois_lados_como_o_mesmo_resultado():
    from mvp_ed1.gcp.identidades import comparar

    lista = [("bigint", "8"), ("bigint", "08"), ("bigint", "0x8"), ("bigint", "9" * 99)]
    pg = [{"identidade": "8", "chave": "8"}, {"identidade": "8", "chave": "8"},
          {"identidade": "0x8", "chave": "8"}, {"identidade": "ERRO: a", "chave": None}]
    bq = [{"identidade": "8", "chave": "8"}, {"identidade": "8", "chave": "8"},
          {"identidade": "0x8", "chave": "8"}, {"identidade": "ERRO: b", "chave": None}]
    r = comparar(lista, pg, bq)
    assert r["paridade"]["identidade"]["divergentes"] == 0
    assert r["paridade"]["identidade"]["recusadas_nos_dois"] == 1
    bigint = r["entre_nocoes"]["bigint"]
    # '8'×'0x8' e '08'×'0x8': a chave junta, a identidade separa; o par com recusa fica fora.
    assert len(bigint["chave_sim_identidade_nao"]) == 2 and bigint["identidade_sim_chave_nao"] == []
    assert bigint["pares"] == 3 and bigint["texto_nao_chave_sim"] == 3


def test_identidades_acusa_quando_so_um_armazem_recusa():
    from mvp_ed1.gcp.identidades import comparar

    r = comparar([("bigint", " 8 ")], [{"identidade": "ERRO: x", "chave": "8"}],
                 [{"identidade": " 8 ", "chave": "8"}])
    assert r["paridade"]["identidade"]["divergentes"] == 1 and r["paridade"]["chave"]["divergentes"] == 0
