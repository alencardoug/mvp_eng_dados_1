"""As regras da herança de descrição, provadas sem banco e sem manifest.

Quem revisa a descrição derivada revisa **a regra** (`models/transport.py`,
`models/descriptions.py`), não os milhares de linhas que ela escreve. Estes
testes são a regra por extenso: só a coluna pura, o apelido e o `cast` de volta
ao tipo declarado transportam; soma de mesmo nome não herda; união herda com o
mesmo texto em todo ramo que transporta, e ramo constante não vota — salvo quando o
tipo dele, ou o de outro ramo, faz a união converter o valor; convenção
pede nome **e** forma; texto à mão vale com motivo; a ponte só herda pela
declaração; e a escrita no `.yml` preserva o resto.
"""

from __future__ import annotations

import textwrap

import pytest
import sqlglot
import yaml
from sqlglot.optimizer.qualify import qualify

from mvp_ed1.models import Base
from mvp_ed1.models import descriptions as d
from mvp_ed1.models import sensitivity as s
from mvp_ed1.models import transport as tr

CATALOGO = {"wh": {
    "raw": {"orders": {"id": "text", "customer_id": "text", "total_amount": "text", "deleted_at": "text", "quantity": "text"}},
    "staging": {"a": {"x": "text"}, "b": {"x": "text"}},
}}
TIPOS = {("raw", "orders", "quantity"): "INT"}
ORDERS = Base.metadata.tables["oltp.orders"].columns
TEXTO_TOTAL = ORDERS["total_amount"].info["description"].strip()


def _transporte(sql: str) -> dict[str, tr.Transport]:
    arvore = qualify(sqlglot.parse_one(sql, read="postgres"), schema=CATALOGO, dialect="postgres", validate_qualify_columns=False)
    return tr.carries_by_output(arvore, ("trusted", "teste"), TIPOS.get)


def _folhas(t: tr.Transport) -> set:
    assert isinstance(t, tr.Carry), t
    return set(t.leaves)


# ── O que transporta ────────────────────────────────────────────────────────────

def test_transporta_so_a_coluna_o_apelido_e_o_cast_ao_tipo_declarado() -> None:
    saida = _transporte("""
        with f as (select * from "wh"."raw"."orders")
        select id as order_id, total_amount, cast(quantity as integer) as q_declarado,
               cast(quantity as bigint) as q_outro_tipo, cast(total_amount as numeric(12, 2)) as t_sem_tipo_declarado
        from f
    """)
    assert _folhas(saida["order_id"]) == {("raw", "orders", "id")}
    assert _folhas(saida["total_amount"]) == {("raw", "orders", "total_amount")}
    assert _folhas(saida["q_declarado"]) == {("raw", "orders", "quantity")}
    assert saida["q_outro_tipo"] == tr.Computed("cast")            # tipo diferente do declarado pode estreitar
    assert saida["t_sem_tipo_declarado"] == tr.Computed("cast")    # tipo de origem desconhecido: calcula


def test_soma_de_mesmo_nome_e_o_que_transforma_o_valor_calculam() -> None:
    """A receita somada da P01 tem a mesma folha da coluna somada (M21) — e não herda."""
    agregado = _transporte("""
        select customer_id, sum(total_amount) as total_amount, count(*) as order_count
        from "wh"."raw"."orders" group by customer_id
    """)
    assert _folhas(agregado["customer_id"]) == {("raw", "orders", "customer_id")}   # a chave do grupo é o valor
    assert agregado["total_amount"] == tr.Computed("sum")
    assert agregado["order_count"] == tr.Computed("count")
    linha = _transporte("""
        select round(total_amount, 2) as a, total_amount * 100 as b, coalesce(total_amount, 0) as c,
               case when id > 0 then total_amount end as k, total_amount || '' as t
        from "wh"."raw"."orders"
    """)
    assert {nome: t.kind for nome, t in linha.items()} == {"a": "round", "b": "mul", "c": "coalesce", "k": "case", "t": "dpipe"}


def test_uniao_herda_com_ramo_constante_e_calcula_com_ramo_que_calcula() -> None:
    def coluna(sql: str) -> tr.Transport:
        return next(iter(_transporte(sql).values()))
    assert _folhas(coluna('select x from "wh"."staging"."a" union all select x from "wh"."staging"."b"')) == {
        ("staging", "a", "x"), ("staging", "b", "x")}
    # O membro desconhecido: um literal de preenchimento não vota (N45).
    assert _folhas(coluna("""select x from "wh"."staging"."a" union all select 'Sem canal' as x""")) == {("staging", "a", "x")}
    assert _folhas(coluna("""select x from "wh"."staging"."a" union all select cast(null as text) as x""")) == {("staging", "a", "x")}
    # Só constantes: calcula, e a forma diz quais.
    assert coluna("select 'retail' as s union all select 'legacy' as s") == tr.Computed("constant", "constant:legacy|retail")
    # Um ramo que calcula faz a união calcular.
    assert coluna('select x from "wh"."staging"."a" union all select upper(x) as x from "wh"."staging"."b"') == tr.Computed("union")


def test_is_not_null_e_a_forma_da_exclusao_logica_nas_duas_grafias() -> None:
    saida = _transporte("""
        select deleted_at is not null as d1, not (deleted_at is null) as d2, quantity > 0 as d3
        from "wh"."raw"."orders"
    """)
    assert saida["d1"] == tr.Computed("is_not_null", "not_null:deleted_at")
    assert saida["d2"] == tr.Computed("is_not_null", "not_null:deleted_at")
    assert saida["d3"] == tr.Computed("gt")


# ── O texto que cada coluna recebe ──────────────────────────────────────────────

def _textos(nos: dict[str, tuple[str, list[str]]], transportes: dict[str, dict[str, tr.Transport]], disco: dict[str, d.Entry],
            folhas: dict[str, dict[str, set]] | None = None) -> d.Texts:
    """Um manifest mínimo — modelo, schema e dependências —, a derivação dada, e o disco dado."""
    manifest = {"sources": {}, "nodes": {
        f"model.p.{nome}": {"resource_type": "model", "name": nome, "schema": schema, "depends_on": {"nodes": [f"model.p.{x}" for x in deps]}}
        for nome, (schema, deps) in nos.items()
    }}
    derivacao = s.Derivation(
        levels={f"model.p.{n}": dict.fromkeys(transportes[n], "internal") for n in nos},
        carries={f"model.p.{n}": transportes[n] for n in nos},
        leaves={f"model.p.{n}": c for n, c in (folhas or {}).items()},
    )
    return d.derive_texts(manifest, derivacao, disco=disco, fontes={})


def _entrada(caminho, tipo: str, **colunas: dict) -> d.Entry:
    return d.Entry(caminho, tipo, {nome: {"name": nome, **c} for nome, c in colunas.items()})


def _carry(*folhas: tuple[str, str, str]) -> tr.Carry:
    return tr.Carry(frozenset(folhas))


def test_herda_salto_a_salto_e_para_no_que_calcula(tmp_path) -> None:
    yml = tmp_path / "_m.yml"
    textos = _textos(
        {"stg": ("staging", []), "t": ("trusted", ["stg"])},
        {"stg": {"a": _carry(("raw", "orders", "total_amount"))},
         "t": {"a": _carry(("staging", "stg", "a")), "soma": tr.Computed("sum")}},
        {"stg": _entrada(yml, "hand", a={}), "t": _entrada(tmp_path / s.GENERATED_FILE, "derived")},
    )
    assert textos.texts[("staging", "stg", "a")] == TEXTO_TOTAL
    assert textos.texts[("trusted", "t", "a")] == TEXTO_TOTAL
    assert textos.undescribed[("trusted", "t", "soma")] == "sum"
    assert textos.patches[yml] == {"stg": {"a": TEXTO_TOTAL}}        # o .yml à mão recebe no lugar
    assert textos.generated["t"] == {"a": TEXTO_TOTAL}               # o modelo sem .yml, no gerado


def test_uniao_so_herda_quando_todo_ramo_chega_ao_mesmo_texto(tmp_path) -> None:
    textos = _textos(
        {"u": ("trusted", [])},
        {"u": {"igual": _carry(("raw", "orders", "total_amount"), ("raw_legacy", "orders", "total_amount")),
               "diferente": _carry(("raw", "orders", "total_amount"), ("raw", "orders", "id"))}},
        {"u": _entrada(tmp_path / s.GENERATED_FILE, "derived")},
    )
    assert textos.texts[("trusted", "u", "igual")] == TEXTO_TOTAL    # o legado declara o mesmo texto
    assert textos.undescribed[("trusted", "u", "diferente")] == "union_differs"


def test_texto_herdado_que_ficou_no_yml_a_mao_nao_vira_raiz_quando_a_coluna_passa_a_calcular(tmp_path) -> None:
    """RVL3-01: `quantity` transportava, o herdado foi escrito no `.yml` à mão; o SQL passou a multiplicar."""
    yml = tmp_path / "_m.yml"
    nos, folhas = {"stg": ("staging", [])}, {"stg": {"a": {("raw", "orders", "total_amount")}}}
    calcula = {"stg": {"a": tr.Computed("mul")}}
    velho = _textos(nos, calcula, {"stg": _entrada(yml, "hand", a={"description": TEXTO_TOTAL})}, folhas)
    assert velho.problems == ["stg.a: não transporta mais (mul) e guarda o texto de quem lê — "
                              "escreva o texto do que ela calcula, ou declare `description_reason`"]
    raiz = _textos(nos, calcula, {"stg": _entrada(yml, "hand", a={"description": "O total vezes cem."})}, folhas)
    assert raiz.problems == [] and raiz.origin[("staging", "stg", "a")] == "written"
    motivo = _textos(nos, calcula, {"stg": _entrada(yml, "hand", a={
        "description": TEXTO_TOTAL, "meta": {"description_reason": "o mesmo conceito"}})}, folhas)
    assert motivo.problems == []


def test_uniao_nao_transporta_quando_a_resolucao_de_tipo_pode_mudar_o_valor() -> None:
    """RVL3-02: o PostgreSQL resolve um tipo para a coluna da união e converte cada ramo para ele."""
    catalogo = {"wh": {"staging": {"a": {"id": "text", "q": "text", "r": "text"}}}}
    tipos = {("staging", "a", "id"): "BIGINT", ("staging", "a", "q"): "INTEGER", ("staging", "a", "r"): "REAL"}

    def coluna(sql: str) -> tr.Transport:
        arvore = qualify(sqlglot.parse_one(sql, read="postgres"), schema=catalogo, dialect="postgres",
                         validate_qualify_columns=False)
        return next(iter(tr.carries_by_output(arvore, ("trusted", "t"), tipos.get).values()))
    base = 'select id from "wh"."staging"."a" union all '
    assert coluna(base + "select 0::real as id") == tr.Computed("union_coercion")      # 16777217 → 16777216
    assert coluna(base + "select cast(null as text) as id") == tr.Computed("union_coercion")
    assert coluna(base + 'select r from "wh"."staging"."a"') == tr.Computed("union_coercion")
    assert isinstance(coluna(base + "select -1 as id"), tr.Carry)                       # sem tipo: resolve pelo ramo
    assert isinstance(coluna(base + "select cast(null as bigint) as id"), tr.Carry)
    assert isinstance(coluna(base + "select cast(-1 as integer) as id"), tr.Carry)      # inteiro alarga sem perda
    assert isinstance(coluna(base + 'select q from "wh"."staging"."a"'), tr.Carry)


def test_convencao_pede_nome_e_forma(tmp_path) -> None:
    textos = _textos(
        {"m": ("staging", []), "outro": ("staging", [])},
        {"m": {"is_deleted": tr.Computed("is_not_null", "not_null:deleted_at"),
               "source_system": tr.Computed("constant", "constant:legacy|retail")},
         "outro": {"is_deleted": tr.Computed("gt"),                                       # mesmo nome, outra forma
                   "source_system": tr.Computed("constant", "constant:web")},             # constante fora do domínio
         },
        {"m": _entrada(tmp_path / s.GENERATED_FILE, "derived"), "outro": _entrada(tmp_path / s.GENERATED_FILE, "derived")},
    )
    assert textos.texts[("staging", "m", "is_deleted")] == '{{ doc("is_deleted") }}'
    assert textos.texts[("staging", "m", "source_system")] == '{{ doc("source_system") }}'
    assert ("staging", "outro", "is_deleted") not in textos.texts
    assert ("staging", "outro", "source_system") not in textos.texts
    so_acrescimo = _textos({"e": ("staging", [])}, {"e": {"is_deleted": tr.Computed("constant", "constant:false")}},
                           {"e": _entrada(tmp_path / s.GENERATED_FILE, "derived")})
    assert so_acrescimo.texts[("staging", "e", "is_deleted")] == '{{ doc("is_deleted_append_only") }}'


def test_texto_a_mao_sem_motivo_e_trocado_e_com_motivo_vale_e_se_propaga(tmp_path) -> None:
    yml = tmp_path / "_m.yml"
    nos = {"f": ("analytics", []), "v": ("consumption", ["f"])}
    transportes = {"f": {"a": _carry(("raw", "orders", "total_amount"))}, "v": {"a": _carry(("analytics", "f", "a"))}}
    sem_motivo = _textos(nos, transportes, {"f": _entrada(yml, "hand", a={"description": "Aditiva — o total."}),
                                            "v": _entrada(yml, "hand", a={})})
    assert sem_motivo.texts[("analytics", "f", "a")] == TEXTO_TOTAL
    assert sem_motivo.changes == ["f.a: texto sem `description_reason`, diferente do herdado, reescrito"]
    com_motivo = _textos(nos, transportes, {
        "f": _entrada(yml, "hand", a={"description": "Aditiva — o total.", "meta": {"description_reason": "diz a aditividade"}}),
        "v": _entrada(yml, "hand", a={})})
    assert com_motivo.texts[("analytics", "f", "a")] == "Aditiva — o total."
    assert com_motivo.texts[("consumption", "v", "a")] == "Aditiva — o total."   # quem transporta herda a exceção
    assert com_motivo.changes == []


def test_ponte_so_herda_pela_declaracao_e_com_o_texto_do_par(tmp_path) -> None:
    pontes = tmp_path / d.BRIDGES_FILE
    nos = {"stg_retail__orders": ("staging", []), "legado__orders": ("trusted", []), "orders": ("trusted", ["stg_retail__orders", "legado__orders"])}
    transportes = {"stg_retail__orders": {"a": _carry(("raw", "orders", "total_amount"))},
                   "legado__orders": {"a": tr.Computed("cast")},                         # extração do JSON
                   "orders": {"a": _carry(("staging", "stg_retail__orders", "a"), ("trusted", "legado__orders", "a"))}}

    def com(**coluna) -> d.Texts:
        return _textos(nos, transportes, {"stg_retail__orders": _entrada(tmp_path / s.GENERATED_FILE, "derived"),
                                          "legado__orders": _entrada(pontes, "generator", a=coluna),
                                          "orders": _entrada(tmp_path / s.GENERATED_FILE, "derived")})
    declarada = com(description=TEXTO_TOTAL, meta={"description_from": "stg_retail__orders.a"})
    assert declarada.problems == [] and declarada.texts[("trusted", "orders", "a")] == TEXTO_TOTAL
    sem_declaracao = com(description=TEXTO_TOTAL)
    assert ("trusted", "orders", "a") not in sem_declaracao.texts
    assert sem_declaracao.problems == ["legado__orders.a: texto na ponte sem `description_from`; rode `make legacy-models`"]
    atrasada = com(description="texto antigo", meta={"description_from": "stg_retail__orders.a"})
    assert atrasada.problems == ["legado__orders.a: a ponte não traz o texto de `stg_retail__orders.a`; rode `make legacy-models`"]


# ── A escrita ───────────────────────────────────────────────────────────────────

def test_a_escrita_da_descricao_insere_substitui_e_preserva_o_resto(tmp_path) -> None:
    original = textwrap.dedent("""\
        version: 2

        models:
          - name: dim_x
            description: O modelo.  # comentário que fica
            columns:
              - name: sem_texto
                meta:
                  sensitivity: internal
              - name: uma_linha
                meta:
                  sensitivity: public
                description: 'Antigo.'
                data_tests: [not_null]
              - name: varias_linhas
                description: >
                  Texto dobrado
                  em duas linhas.
                meta:
                  sensitivity: public
    """)
    pedido = {"dim_x": {"sem_texto": 'Novo: com "aspas".', "uma_linha": '{{ doc("source_system") }}', "varias_linhas": "Curto."}}
    escrito = d.patch_descriptions(original, pedido)
    documento = yaml.safe_load(escrito)
    colunas = {c["name"]: c for c in documento["models"][0]["columns"]}
    assert colunas["sem_texto"]["description"] == 'Novo: com "aspas".'
    assert colunas["uma_linha"]["description"] == '{{ doc("source_system") }}' and colunas["uma_linha"]["data_tests"] == ["not_null"]
    assert colunas["varias_linhas"] == {"name": "varias_linhas", "description": "Curto.", "meta": {"sensitivity": "public"}}
    assert "# comentário que fica" in escrito
    assert d.patch_descriptions(escrito, pedido) == escrito                       # idempotente
    alvo = s.DBT / "models" / "x.yml"                                             # o caminho só entra na mensagem
    d.verify(alvo, escrito, pedido)
    with pytest.raises(RuntimeError, match="sem o texto esperado"):
        d.verify(alvo, original, pedido)


def test_arquivo_gerado_leva_a_descricao_antes_da_sensibilidade() -> None:
    texto = s.render_generated({"t": {"a": "internal", "b": "public"}}, "models", {"t": {"a": "Texto."}})
    colunas = yaml.safe_load(texto)["models"][0]["columns"]
    assert colunas == [{"name": "a", "description": "Texto.", "meta": {"sensitivity": "internal"}},
                       {"name": "b", "meta": {"sensitivity": "public"}}]


def test_a_derivacao_guardada_e_refeita_quando_uma_entrada_muda(tmp_path, monkeypatch) -> None:
    """RV2-10: a mesma derivação serve à classificação, à linhagem e aos testes; muda a entrada, deriva de novo."""
    chamadas = []
    monkeypatch.setattr(s, "CACHE", tmp_path / "derivacao.pickle")
    monkeypatch.setattr(s, "derive", lambda manifest: chamadas.append(manifest) or s.Derivation(levels={"n": {"c": "internal"}}))
    manifest = tmp_path / "manifest.json"
    manifest.write_text('{"nodes": {}, "v": 1}')
    assert s.load(manifest)[1].levels == {"n": {"c": "internal"}} and len(chamadas) == 1
    assert s.load(manifest)[1].levels == {"n": {"c": "internal"}} and len(chamadas) == 1   # guardada
    manifest.write_text('{"nodes": {}, "v": 2}')
    s.load(manifest)
    assert len(chamadas) == 2                                                              # o manifest mudou
    monkeypatch.setattr(s, "derive", lambda manifest: chamadas.append(manifest) or s.Derivation(problems=["incompleta"]))
    manifest.write_text('{"nodes": {}, "v": 3}')
    s.load(manifest), s.load(manifest)
    assert len(chamadas) == 4                                                              # com problema, não se guarda


# ── O domínio (N46) ─────────────────────────────────────────────────────────────

def test_dominio_vem_da_tabela_conduzida_pelo_nome_ou_pela_lista() -> None:
    from mvp_ed1.models import domains as dm
    dominios = dm.source_domains()
    assert dm.conducted_domain("stg_retail__orders", dominios) == dominios["orders"] == "vendas"
    assert dm.conducted_domain("orders", dominios) == "vendas"
    assert dm.conducted_domain("scd_customer", dominios) == dominios["customers"]              # pela lista CONDUCTS
    assert dm.conducted_domain("legacy_selected_capture", dominios) == "legado"                # declarado
    assert dm.conducted_domain("dim_date", dominios) is None                                   # não conduz tabela: à mão


def test_dominio_a_mao_vale_com_motivo_e_o_gerador_nao_e_tocado(tmp_path) -> None:
    from mvp_ed1.models import domains as dm
    yml = tmp_path / "_m.yml"

    def manifest(*nomes: str) -> dict:
        return {"nodes": {f"model.p.{n}": {"resource_type": "model", "name": n, "schema": "staging"} for n in nomes}}
    disco = {
        "stg_retail__orders": d.Entry(yml, "hand", {}, {}),
        "stg_retail__carts": d.Entry(yml, "hand", {}, {"domain": "marketing"}),
        "stg_retail__coupons": d.Entry(yml, "hand", {}, {"domain": "vendas", "domain_reason": "o cupom é de vendas aqui"}),
        "stg_retail__brands": d.Entry(tmp_path / "_legacy__models.yml", "generator", {}, {"domain": "legado"}),
        "stg_retail__warehouses": d.Entry(tmp_path / s.GENERATED_FILE, "derived", {}, {}),
    }
    saida = dm.derive_domains(manifest(*disco), disco)
    assert saida.patches[yml] == {"stg_retail__orders": "vendas", "stg_retail__carts": "vendas"}
    assert saida.changes == ["stg_retail__carts: domínio à mão `marketing` sem `domain_reason` trocado por `vendas`"]
    assert saida.generated == {"stg_retail__warehouses": "estoque"}


def test_a_escrita_do_dominio_insere_atualiza_e_preserva() -> None:
    from mvp_ed1.models import domains as dm
    original = textwrap.dedent("""\
        models:
          - name: a
            description: Sem meta.
            columns:
              - name: x
                meta:
                  sensitivity: internal
          - name: b
            meta:
              retention: rebuildable
            columns: []
          - name: c
            meta:
              domain: errado
    """)
    escrito = dm.patch_domains(original, {"a": "vendas", "b": "clientes", "c": "estoque"})
    modelos = {m["name"]: m for m in yaml.safe_load(escrito)["models"]}
    assert modelos["a"]["meta"] == {"domain": "vendas"} and modelos["a"]["columns"][0]["meta"] == {"sensitivity": "internal"}
    assert modelos["b"]["meta"] == {"domain": "clientes", "retention": "rebuildable"}
    assert modelos["c"]["meta"] == {"domain": "estoque"}
    assert dm.patch_domains(escrito, {"a": "vendas", "b": "clientes", "c": "estoque"}) == escrito
    gerado = yaml.safe_load(s.render_generated({"t": {"a": "internal"}}, "models", None, {"t": "vendas"}))
    assert gerado["models"][0]["meta"] == {"domain": "vendas"}
