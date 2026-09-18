"""As regras de `models/sensitivity.py`, provadas sem banco e sem manifest.

Quem revisa a classificação derivada revisa **a regra**, não as 4 mil linhas
que ela produz. Estes testes são a regra por extenso: herança, o mais
restritivo, o que decide o ramo do `case` não entra, `union` casa por posição,
`count(*)` é técnico, e a escrita no `.yml` preserva o que já estava lá.
"""

from __future__ import annotations

import json
import textwrap

import sqlglot
import yaml
from sqlglot.optimizer.qualify import qualify

from mvp_ed1.models import sensitivity as s

CATALOGO = {"wh": {"raw": {
    "customers": {"id": "text", "first_name": "text", "last_name": "text", "segment_id": "text", "_airbyte_raw_id": "text"},
    "orders": {"id": "text", "customer_id": "text", "total_amount": "text"},
}}}
NIVEIS = {
    ("raw", "customers", "id"): "internal", ("raw", "customers", "first_name"): "personal",
    ("raw", "customers", "last_name"): "personal", ("raw", "customers", "segment_id"): "public",
    ("raw", "customers", "_airbyte_raw_id"): "internal",
    ("raw", "orders", "id"): "internal", ("raw", "orders", "customer_id"): "internal",
    ("raw", "orders", "total_amount"): "confidential",
}


def _derivar(sql: str) -> dict[str, str]:
    problemas: list[str] = []
    arvore = qualify(sqlglot.parse_one(sql, read="postgres"), schema=CATALOGO, dialect="postgres", validate_qualify_columns=False)
    folhas = s._leaves_by_output(arvore, "teste", ("trusted", "x"), NIVEIS, problemas, [])
    assert problemas == []
    return {nome: s.strictest([NIVEIS[f] for f in chaves]) for nome, chaves in folhas.items()}


def test_heranca_renome_e_o_mais_restritivo() -> None:
    sql = """
        with fonte as (select * from "wh"."raw"."customers")
        select id as customer_id, segment_id, first_name || ' ' || last_name as full_name,
               md5(id::text) as customer_key, current_timestamp as loaded_at, 1 as one
        from fonte
    """
    assert _derivar(sql) == {
        "customer_id": "internal", "segment_id": "public", "full_name": "personal",
        "customer_key": "internal", "loaded_at": "internal", "one": "internal",
    }


def test_o_que_decide_o_ramo_do_case_nao_entra_no_valor() -> None:
    sql = """
        select
            case when c.first_name is null then c.segment_id else c.id end as decidido_por_pessoal,
            case when c.id > 0 then c.first_name end as vale_pessoal,
            coalesce(c.last_name, c.segment_id) as ambos
        from "wh"."raw"."customers" c
    """
    # `first_name` só decide o ramo: o valor é `segment_id` ou `id`, e o mais restritivo deles é `internal`.
    assert _derivar(sql) == {"decidido_por_pessoal": "internal", "vale_pessoal": "personal", "ambos": "personal"}


def test_juncao_agregacao_e_union_por_posicao() -> None:
    sql = """
        with pedidos as (
            select o.customer_id, count(*) as n, sum(o.total_amount) as total
            from "wh"."raw"."orders" o group by o.customer_id
        ),
        tudo as (
            select 'a' as origem, c.id as chave, c.first_name as valor from "wh"."raw"."customers" c
            union all
            select 'b', o.id, o.total_amount::text from "wh"."raw"."orders" o
        )
        select t.origem, t.chave, t.valor, p.n, p.total
        from tudo t left join pedidos p on p.customer_id = t.chave
    """
    assert _derivar(sql) == {"origem": "internal", "chave": "internal", "valor": "personal", "n": "internal", "total": "confidential"}


def test_expressao_avulsa_segue_a_mesma_regra() -> None:
    niveis = {"first_name": "personal", "id": "internal", "segment_id": "public"}
    assert s.expression_level("first_name || ' ' || last_name", niveis.get) == "personal"
    assert s.expression_level("case when first_name is null then segment_id else id end", niveis.get) == "internal"
    assert s.expression_level("cast(_airbyte_extracted_at as timestamptz)", lambda n: None) == "internal"


def test_a_escrita_no_yml_insere_atualiza_e_preserva_o_resto() -> None:
    original = textwrap.dedent("""\
        version: 2

        models:
          # comentário que precisa sobreviver
          - name: dim_customer
            description: '{{ doc("active_customer") }}'
            columns:
              - name: customer_key
                data_tests: [unique, not_null]
              - name: customer_document
                description: >
                  Documento (sintético).
                meta:
                  sensitivity: public
                  data_type: pii
              - name: birth_date

          - name: dim_date
            description: Calendário.
        """)
    escrito = s.patch_yaml(original, {
        "dim_customer": {"customer_key": "internal", "customer_document": "personal", "birth_date": "personal", "first_name": "personal"},
        "dim_date": {"date_key": "internal"},
    })
    assert "# comentário que precisa sobreviver" in escrito
    assert "data_tests: [unique, not_null]" in escrito and "data_type: pii" in escrito
    documento = yaml.safe_load(escrito)
    modelos = {m["name"]: {c["name"]: c.get("meta", {}).get("sensitivity") for c in m["columns"]} for m in documento["models"]}
    assert modelos == {
        "dim_customer": {"customer_key": "internal", "customer_document": "personal", "birth_date": "personal", "first_name": "personal"},
        "dim_date": {"date_key": "internal"},
    }
    assert documento["models"][0]["description"] == '{{ doc("active_customer") }}'
    # Idempotente: escrever o mesmo de novo não muda uma linha.
    assert s.patch_yaml(escrito, {"dim_customer": {"birth_date": "personal"}}) == escrito


def test_arquivo_gerado_de_snapshots_usa_a_chave_certa() -> None:
    texto = s.render_generated({"scd_customer": {"customer_id": "internal", "dbt_scd_id": "internal"}}, "snapshots")
    documento = yaml.safe_load(texto)
    assert list(documento) == ["version", "snapshots"]
    assert documento["snapshots"][0]["columns"][1] == {"name": "dbt_scd_id", "meta": {"sensitivity": "internal"}}


def _no(nome: str, camada: str, colunas: dict[str, str | None], patch: str | None) -> dict:
    return {
        "unique_id": f"model.mvp_ed1.{nome}", "resource_type": "model", "name": nome, "schema": camada,
        "original_file_path": f"models/{camada}/{nome}.sql", "patch_path": patch,
        "columns": {c: {"name": c, "meta": {"sensitivity": n}} for c, n in colunas.items() if n},
    }


def test_arquivo_gerado_leva_todos_os_modelos_que_lhe_pertencem(tmp_path, monkeypatch) -> None:
    """O `_sensitivity.yml` é reescrito por inteiro: mudar uma coluna de um modelo não apaga os outros.

    Quatro situações numa geração só: coluna que muda, modelo que não muda,
    modelo novo sem `.yml`, e modelo que ganhou entrada num `.yml` à mão — os
    três primeiros ficam no gerado; o último sai dele e vira `patch` no manual.
    O promovido é lido do **disco**: o manifest ainda o aponta para o gerado,
    porque o dbt se recusa a compilar com as duas entradas — é a geração que
    retira a entrada gerada antes dessa recusa.
    """
    monkeypatch.setattr(s, "DBT", tmp_path)
    manual = tmp_path / "models" / "trusted" / "_trusted__models.yml"
    manual.parent.mkdir(parents=True)
    manual.write_text("version: 2\nmodels:\n  - name: promovido\n    columns:\n      - name: id\n", encoding="utf-8")
    gerado = "mvp_ed1://models/trusted/_sensitivity.yml"
    manifest = {"sources": {}, "nodes": {
        "model.mvp_ed1.muda":      _no("muda", "trusted", {"id": "internal", "nome": "public"}, gerado),
        "model.mvp_ed1.fica":      _no("fica", "trusted", {"id": "internal"}, gerado),
        "model.mvp_ed1.novo":      _no("novo", "trusted", {}, None),
        "model.mvp_ed1.promovido": _no("promovido", "trusted", {"id": "internal"}, gerado),
    }}
    derivado = s.Derivation(levels={
        "model.mvp_ed1.muda": {"id": "internal", "nome": "personal"},
        "model.mvp_ed1.fica": {"id": "internal"},
        "model.mvp_ed1.novo": {"id": "internal"},
        "model.mvp_ed1.promovido": {"id": "internal"},
    })
    plano = s.plan(manifest, derivado)
    arquivo = tmp_path / "models" / "trusted" / s.GENERATED_FILE
    assert plano.generated == {arquivo: {
        "muda": {"id": "internal", "nome": "personal"}, "fica": {"id": "internal"}, "novo": {"id": "internal"},
    }}
    assert plano.patches == {manual: {"promovido": {"id": "internal"}}}
    assert plano.changes == ["muda.nome: `public` → `personal`"]
    texto = s.render_files(plano)[arquivo]
    assert [m["name"] for m in yaml.safe_load(texto)["models"]] == ["fica", "muda", "novo"]

    # Segunda geração, com os dois arquivos escritos e o manifest ainda o da primeira
    # (`patch_path` do promovido no gerado): o mesmo arquivo, byte a byte — e nenhum obsoleto.
    for caminho, conteudo in s.render_files(plano).items():
        caminho.write_text(conteudo, encoding="utf-8")
    for nome in ("muda", "novo"):
        manifest["nodes"][f"model.mvp_ed1.{nome}"]["columns"] = {
            c: {"name": c, "meta": {"sensitivity": n}} for c, n in derivado.levels[f"model.mvp_ed1.{nome}"].items()}
        manifest["nodes"][f"model.mvp_ed1.{nome}"]["patch_path"] = gerado
    plano2 = s.plan(manifest, derivado)
    assert plano2.changes == [] and plano2.patches == {}
    assert s.render_files(plano2)[arquivo] == texto
    assert s.stale_generated(plano2) == []
    assert yaml.safe_load(manual.read_text(encoding="utf-8"))["models"][0]["columns"] == [{"name": "id", "meta": {"sensitivity": "internal"}}]

    # Todos promovidos ao `.yml` à mão: o gerado fica sem modelo e é apontado como obsoleto.
    manual.write_text("version: 2\nmodels:\n" + "".join(f"  - name: {n}\n" for n in ("muda", "fica", "novo", "promovido")), encoding="utf-8")
    plano3 = s.plan(manifest, derivado)
    assert plano3.generated == {} and set(plano3.patches) == {manual}
    assert s.stale_generated(plano3) == [arquivo]


def test_derivacao_incompleta_nao_escreve_nem_apaga_nada(tmp_path, monkeypatch, capsys) -> None:
    """Manifest de `dbt parse` (sem SQL compilado) ou SQL que o parser não lê: `main()` recusa antes de tocar em arquivo.

    Sem isso o gerado seria reescrito com zero colunas e o código de saída 1
    chegaria depois do estrago — foi o achado RV11-2-01.
    """
    dbt = tmp_path / "dbt"
    (dbt / "models" / "trusted").mkdir(parents=True)
    (dbt / "target").mkdir()
    monkeypatch.setattr(s, "ROOT", tmp_path)
    monkeypatch.setattr(s, "DBT", dbt)
    monkeypatch.setattr(s, "MANIFEST", dbt / "target" / "manifest.json")
    gerado = dbt / "models" / "trusted" / s.GENERATED_FILE
    original = s.render_generated({"a": {"first_name": "personal"}, "b": {"id": "internal"}})
    gerado.write_text(original, encoding="utf-8")

    def no(nome: str, sql: str | None) -> dict:
        return {"unique_id": f"model.mvp_ed1.{nome}", "resource_type": "model", "name": nome, "schema": "trusted", "database": "wh",
                "original_file_path": f"models/trusted/{nome}.sql", "patch_path": f"mvp_ed1://models/trusted/{s.GENERATED_FILE}",
                "depends_on": {"nodes": []}, "columns": {}, "compiled_code": sql}

    bom = 'select first_name from "wh"."raw"."customers"'
    for caso, nodes in {
        "compilação parcial": {"model.mvp_ed1.a": no("a", bom), "model.mvp_ed1.b": no("b", None)},
        "erro de parser num modelo": {"model.mvp_ed1.a": no("a", bom), "model.mvp_ed1.b": no("b", "select from where (")},
    }.items():
        s.MANIFEST.write_text(json.dumps({"sources": {}, "nodes": nodes}), encoding="utf-8")
        for argv in ([], ["--check"]):
            assert s.main(argv) == 1, caso
            assert gerado.read_text(encoding="utf-8") == original, f"{caso}: arquivo tocado com {argv}"
            assert "nenhum arquivo é tocado" in capsys.readouterr().err


def test_o_espelho_de_raw_nao_sobrepoe_a_declaracao_sqlalchemy() -> None:
    """Reclassificar `customers.first_name` na declaração chega ao derivado na mesma geração.

    O `meta.sensitivity` das fontes `raw` e `raw_legacy` é espelho escrito por
    `plan()`; um espelho atrasado (`public`) não pode ser folha no lugar da
    declaração (`personal`). Fonte sem declaração SQLAlchemy — `governance` —
    continua sendo lida do `.yml`.
    """
    manifest = {
        "sources": {
            "source.mvp_ed1.retail.customers": {
                "schema": "raw", "identifier": "customers", "original_file_path": "models/staging/_retail__sources.yml",
                "columns": {"first_name": {"name": "first_name", "meta": {"sensitivity": "public"}}},
            },
            "source.mvp_ed1.governance.legacy_captures": {
                "schema": "governance", "identifier": "legacy_captures", "original_file_path": "models/staging/legacy/_legacy__sources.yml",
                "columns": {"capture_id": {"name": "capture_id", "meta": {"sensitivity": "confidential"}}},
            },
        },
        "nodes": {
            "model.mvp_ed1.x": {
                "unique_id": "model.mvp_ed1.x", "resource_type": "model", "name": "x", "schema": "trusted", "database": "wh",
                "original_file_path": "models/trusted/x.sql", "depends_on": {"nodes": []}, "columns": {},
                "compiled_code": 'select c.first_name, g.capture_id from "wh"."raw"."customers" c '
                                 'cross join "wh"."governance"."legacy_captures" g',
            },
        },
    }
    derivado = s.derive(manifest)
    assert derivado.problems == []
    assert derivado.levels["model.mvp_ed1.x"] == {"first_name": "personal", "capture_id": "confidential"}
    plano = s.plan(manifest, derivado)
    assert plano.patches[s.DBT / "models/staging/_retail__sources.yml"]["customers"]["first_name"] == "personal"
