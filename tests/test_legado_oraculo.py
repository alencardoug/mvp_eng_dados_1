"""O esperado por ocorrência, sem banco: semântica, consistência e discriminação.

Três perguntas, e cada uma tem um teste porque cada uma já falhou de um jeito
diferente nesta base:

* **a semântica está certa?** — os quatro casos que a documentação não decidia
  e o Owner fechou em 14/09/2026, um a um, sobre lotes mínimos construídos à
  mão. É especificação por exemplo, e é o que torna o oráculo revisável sem
  ler o código;
* **o oráculo concorda com o injetor sobre o lote inteiro?** — tudo o que o
  injetor declarou como contexto reaparece no recômputo. Foi assim que apareceu
  a excedente de duplicata que herdava o defeito e não herdava o achado;
* **a comparação discrimina?** — dois algoritmos do mesmo autor concordando
  não provam nada; mutar o esperado ou o obtido tem de fazer a comparação
  acusar. Sem isso, um comparador que devolvesse lista vazia sempre passaria.
"""

from __future__ import annotations

import collections
import copy
import datetime as dt

import pytest

from mvp_ed1.legacy import conteudo, injetor, oraculo, schema
from mvp_ed1.legacy.catalogo import carregar



@pytest.fixture(scope="module")
def catalogo():
    return carregar()


@pytest.fixture(scope="module")
def lote():
    from mvp_ed1.legacy import cli

    catalogo, resultado, parametros = cli._gerar()
    return catalogo, resultado, parametros


# ── Lotes mínimos ────────────────────────────────────────────────────────────

def _linha(tabela: str, identidade: int, **valores) -> dict:
    """Uma linha íntegra da tabela, com o mínimo que a obrigatoriedade exige."""
    agora = "2026-01-01T00:00:00-03:00"
    base = {schema.IDENTIDADE: identidade}
    for coluna in schema.colunas(tabela):
        if coluna in ("created_at", "updated_at"):
            base[coluna] = agora
        elif coluna in ("is_active",):
            base[coluna] = "true"
        elif coluna == "depth":
            base[coluna] = "1"
        elif coluna == "status":
            base[coluna] = "active"
        elif coluna in ("deleted_at", "parent_id", "brand_id", "description", "launched_at", "country"):
            base[coluna] = None
        else:
            base[coluna] = f"{coluna}-{identidade}"
    base.update(valores)
    return base


def _resultado(**tabelas) -> injetor.Resultado:
    return injetor.Resultado(linhas={t: list(linhas) for t, linhas in tabelas.items()}, achados=[])


def _veredito(vereditos, tabela, identidade):
    return vereditos[(tabela, identidade)]


def test_excedente_exato_nao_e_pai_e_a_canonica_apta_segura_o_filho(catalogo) -> None:
    categoria = _linha("product_categories", 1, id="10", code="c10", name="Casa")
    excedente = {**categoria, schema.IDENTIDADE: 2}
    produto = _linha("products", 1, id="100", product_code="p100", category_id="10", name="Mesa")
    v = oraculo.esperar(catalogo, _resultado(product_categories=[categoria, excedente], products=[produto]))

    assert _veredito(v, "product_categories", 1).classification == oraculo.ACCEPTED
    assert (_veredito(v, "product_categories", 2).classification, _veredito(v, "product_categories", 2).rejection_origin) == (
        oraculo.REJECTED, oraculo.DUPLICATE_EXCESS)
    assert _veredito(v, "product_categories", 2).achados == [oraculo.AchadoEsperado("DUP_EXACT", None, (1,))]
    assert _veredito(v, "products", 1).classification == oraculo.ACCEPTED, "o pai de negócio existe e está apto"


def test_duplicata_parcial_rejeita_as_duas_versoes_e_o_filho_cascateia(catalogo) -> None:
    a = _linha("product_categories", 1, id="10", code="c10", name="Casa")
    b = _linha("product_categories", 2, id="10", code="c10", name="Casa (rev)")
    produto = _linha("products", 1, id="100", product_code="p100", category_id="10", name="Mesa")
    v = oraculo.esperar(catalogo, _resultado(product_categories=[a, b], products=[produto]))

    for identidade in (1, 2):
        veredito = _veredito(v, "product_categories", identidade)
        assert (veredito.classification, veredito.rejection_origin) == (oraculo.REJECTED, oraculo.OWN_INVALID)
        assert {a.codigo for a in veredito.achados} == {"DUP_PARTIAL"}
        # `id` e `code` conflitam — uma unicidade por chave declarada.
        assert sorted(a.vinculo for a in veredito.achados) == [("code",), ("id",)]
    filho = _veredito(v, "products", 1)
    assert (filho.classification, filho.rejection_origin) == (oraculo.REJECTED, oraculo.PARENT_REJECTED)
    assert sorted(a.vinculo for a in filho.achados) == [("product_categories", 1), ("product_categories", 2)]


def test_pai_com_chave_nula_torna_o_filho_orfao_e_nao_cascata(catalogo) -> None:
    categoria = _linha("product_categories", 1, id=None, code="c10", name="Casa")
    produto = _linha("products", 1, id="100", product_code="p100", category_id="10", name="Mesa")
    v = oraculo.esperar(catalogo, _resultado(product_categories=[categoria], products=[produto]))

    pai = _veredito(v, "product_categories", 1)
    assert (pai.classification, pai.rejection_origin) == (oraculo.REJECTED, oraculo.OWN_INVALID)
    assert pai.achados == [oraculo.AchadoEsperado("NULL_REQUIRED", "id")]
    filho = _veredito(v, "products", 1)
    assert (filho.classification, filho.rejection_origin) == (oraculo.REJECTED, oraculo.OWN_INVALID)
    assert filho.achados == [oraculo.AchadoEsperado("FK_ORPHAN", "category_id", ("product_categories", "id"))]


def test_ciclo_com_raiz_rejeitada_cai_inteiro_e_a_raiz_conserva_a_causa(catalogo) -> None:
    raiz = _linha("product_categories", 1, id="1", code="c1", name=None, parent_id="2")
    filho = _linha("product_categories", 2, id="2", code="c2", name="Dois", parent_id="1")
    neto = _linha("product_categories", 3, id="3", code="c3", name="Três", parent_id="2")
    v = oraculo.esperar(catalogo, _resultado(product_categories=[raiz, filho, neto]))

    assert (_veredito(v, "product_categories", 1).classification, _veredito(v, "product_categories", 1).rejection_origin) == (
        oraculo.REJECTED, oraculo.OWN_INVALID)
    assert [a.codigo for a in _veredito(v, "product_categories", 1).achados] == ["NULL_REQUIRED"], (
        "a raiz não ganha PARENT_REJECTED do próprio ciclo: conserva a causa própria")
    for identidade, pai in ((2, 1), (3, 2)):
        veredito = _veredito(v, "product_categories", identidade)
        assert (veredito.classification, veredito.rejection_origin) == (oraculo.REJECTED, oraculo.PARENT_REJECTED)
        assert veredito.achados == [oraculo.AchadoEsperado("PARENT_REJECTED", "parent_id", ("product_categories", pai))]


def test_defeito_proprio_vence_excedente_na_origem_da_rejeicao(catalogo) -> None:
    marca = _linha("brands", 1, id="1", code="b1", name=None)
    excedente = {**marca, schema.IDENTIDADE: 2}
    v = oraculo.esperar(catalogo, _resultado(brands=[marca, excedente]))
    assert _veredito(v, "brands", 2).rejection_origin == oraculo.OWN_INVALID
    assert {a.codigo for a in _veredito(v, "brands", 2).achados} == {"NULL_REQUIRED", "DUP_EXACT"}


def test_recuperacao_segue_o_contrato_do_catalogo(catalogo) -> None:
    """`nulo` não volta ao original; `original` volta — e o payload limpo reflete isso."""
    marca = _linha("brands", 1, id="1", code="b1", name="  Acme  ", country="N/A")
    resultado = _resultado(brands=[marca])
    resultado.achados.extend([
        injetor.Achado("brands", 1, "name", "TEXT_WHITESPACE_CASE", "Acme", "  Acme  ", injetor.CORRIGIDO, "Acme"),
        injetor.Achado("brands", 1, "country", "NULL_DISGUISED", "BR", "N/A", injetor.CORRIGIDO, None),
    ])
    v = oraculo.esperar(catalogo, resultado)
    veredito = _veredito(v, "brands", 1)
    assert veredito.classification == oraculo.CORRECTED
    assert veredito.valores_esperados == {"name": "Acme", "country": None}


def test_a_precedencia_do_catalogo_vale_sobre_a_entrada_bruta(catalogo) -> None:
    """RV10-06: `TEXT_TRUNCATED` precede `TEXT_WHITESPACE_CASE` no catálogo, e mede-se a entrada.

    Uma injeção de espaços leva `warehouses.name` de 21 caracteres à largura
    antiga de 24: para o contrato é truncamento — rejeição, texto preservado,
    sem valor recuperado — ainda que o injetor tenha declarado uma correção.
    O oráculo media o texto já recuperado (21) e pulava a coluna por já ter
    achado; dizia `corrected`, e o SQL, que aplica o catálogo, dizia
    `rejected`.
    """
    largura = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)[("warehouses", "name")]
    original = "ABCDEFGHIJKLMNOPQRSTU"
    injetado = "  " + original + " " * (largura - len(original) - 2)
    assert len(injetado) == largura and len(original) < largura
    ordem = list(catalogo.falhas)
    assert ordem.index("TEXT_TRUNCATED") < ordem.index("TEXT_WHITESPACE_CASE")

    deposito = _linha("warehouses", 1, id="1", code="w1", name=injetado, country="BR")
    resultado = _resultado(warehouses=[deposito])
    resultado.achados.append(
        injetor.Achado("warehouses", 1, "name", "TEXT_WHITESPACE_CASE", original, injetado, injetor.CORRIGIDO, original)
    )
    veredito = _veredito(oraculo.esperar(catalogo, resultado), "warehouses", 1)
    assert (veredito.classification, veredito.rejection_origin) == (oraculo.REJECTED, oraculo.OWN_INVALID)
    assert veredito.achados == [oraculo.AchadoEsperado("TEXT_TRUNCATED", "name")]
    assert veredito.valores_esperados == {}, "a rejeição preserva o texto; nada é recuperado"

    # Com um caractere a menos a heurística não dispara e a correção declarada vale.
    deposito["name"] = injetado[:-1]
    resultado.achados[0] = injetor.Achado("warehouses", 1, "name", "TEXT_WHITESPACE_CASE", original, injetado[:-1], injetor.CORRIGIDO, original)
    veredito = _veredito(oraculo.esperar(catalogo, resultado), "warehouses", 1)
    assert veredito.classification == oraculo.CORRECTED
    assert veredito.achados == [oraculo.AchadoEsperado("TEXT_WHITESPACE_CASE", "name")]
    assert veredito.valores_esperados == {"name": original}


def test_total_do_pedido_e_recomputado_a_partir_dos_itens(catalogo) -> None:
    pedido = _linha("orders", 1, id="1", order_number="o1", customer_id="1", sales_channel_id="1", cart_id=None,
                    placed_at="2026-01-01T00:00:00-03:00", currency="BRL", subtotal_amount="30.00",
                    discount_amount="0", shipping_amount="5.00", tax_amount="0", total_amount="35.00")
    item = _linha("order_items", 1, id="1", order_id="1", product_variant_id="1", quantity="3", unit_price="10.00")
    cliente = _linha("customers", 1, id="1", segment_id=None)
    canal = _linha("sales_channels", 1, id="1")
    variante = _linha("product_variants", 1, id="1", product_id="1")
    produto = _linha("products", 1, id="1", product_code="p1", category_id="1", name="Mesa")
    categoria = _linha("product_categories", 1, id="1", code="c1", name="Casa")
    base = dict(orders=[pedido], order_items=[item], customers=[cliente], sales_channels=[canal],
                product_variants=[variante], products=[produto], product_categories=[categoria])

    v = oraculo.esperar(catalogo, _resultado(**base))
    assert _veredito(v, "orders", 1).classification == oraculo.ACCEPTED, _veredito(v, "orders", 1).achados

    # Quantidade fora de faixa no item, numericamente válida: o total declarado
    # deixa de reconciliar com o que a origem registrou (D33).
    com_defeito = copy.deepcopy(base)
    com_defeito["order_items"][0]["quantity"] = "99999"
    v = oraculo.esperar(catalogo, _resultado(**com_defeito))
    assert oraculo.AchadoEsperado("TOTAL_MISMATCH", "total_amount") in _veredito(v, "orders", 1).achados


# ── O lote inteiro ───────────────────────────────────────────────────────────

def test_o_oraculo_cobre_toda_ocorrencia_e_concorda_com_o_injetor(lote, record_property) -> None:
    catalogo, resultado, _ = lote
    vereditos = oraculo.esperar(catalogo, resultado)
    assert len(vereditos) == sum(len(v) for v in resultado.linhas.values())
    assert oraculo.conferir_com_o_injetor(resultado, vereditos) == []
    contagem = collections.Counter((v.classification, v.rejection_origin) for v in vereditos.values())
    for (saida, origem), quantidade in sorted(contagem.items(), key=str):
        record_property(f"expected_{saida}_{origem or 'none'}", quantidade)
    assert contagem[(oraculo.REJECTED, oraculo.PARENT_REJECTED)] > 0, "o lote precisa exercitar a cascata"


def test_o_manifesto_identifica_o_lote_por_conteudo(lote) -> None:
    """Mesmo conjunto de identidades e achados, conteúdo diferente → hash diferente."""
    from mvp_ed1.legacy import writer

    catalogo, resultado, parametros = lote
    manifesto = writer.manifesto(catalogo, resultado, parametros)
    assert set(manifesto) == {"lote", "achados", "veredito", "mutacoes"}
    assert set(manifesto["lote"]["tabelas"]) == set(schema.tabelas())
    assert manifesto["lote"]["parametros"]["versao_catalogo"] == catalogo.versao

    alterado = copy.deepcopy(resultado)
    linha = next(l for l in alterado.linhas["brands"] if l.get("name"))
    linha["name"] = linha["name"] + " "  # não é achado: nenhuma regra muda, só o conteúdo
    de_novo = writer.manifesto(catalogo, alterado, parametros)
    assert de_novo["lote"]["tabelas"]["brands"]["linhas"] == manifesto["lote"]["tabelas"]["brands"]["linhas"]
    assert de_novo["lote"]["hash"] != manifesto["lote"]["hash"]
    assert de_novo["lote"]["tabelas"]["customers"] == manifesto["lote"]["tabelas"]["customers"]


def test_string_vazia_e_nulo_na_identidade_de_conteudo() -> None:
    a = conteudo.hash_de_tabela("brands", [{schema.IDENTIDADE: 1, "name": "", "code": "x"}])
    b = conteudo.hash_de_tabela("brands", [{schema.IDENTIDADE: 1, "name": None, "code": "x"}])
    c = conteudo.hash_de_tabela("brands", [{schema.IDENTIDADE: 1, "name": " ", "code": "x"}])
    assert a == b != c


# ── A comparação discrimina ──────────────────────────────────────────────────

def test_a_comparacao_acusa_mutacao_no_esperado_e_no_obtido(lote) -> None:
    catalogo, resultado, _ = lote
    esperado = oraculo.esperar(catalogo, resultado)
    obtido = copy.deepcopy(esperado)
    assert oraculo.comparar(esperado, obtido) == []

    chave = next(k for k, v in esperado.items() if v.rejection_origin == oraculo.PARENT_REJECTED)
    mutado = copy.deepcopy(esperado)
    mutado[chave].classification, mutado[chave].rejection_origin, mutado[chave].achados = oraculo.ACCEPTED, None, []
    campos = {d.campo for d in oraculo.comparar(mutado, obtido) if d.chave == chave}
    assert campos == {"classification", "rejection_origin", "achados"}

    duplicado = copy.deepcopy(esperado)
    duplicado[chave].achados.append(duplicado[chave].achados[0])
    [d] = [d for d in oraculo.comparar(esperado, duplicado) if d.chave == chave]
    assert d.campo == "achados" and d.esperado == [] and len(d.obtido) == 1, "multiplicidade indevida não se esconde"

    faltando = copy.deepcopy(esperado)
    del faltando[chave]
    assert any(d.campo == "ocorrencia" for d in oraculo.comparar(faltando, obtido))


def test_achado_obtido_le_o_vinculo_como_a_classificacao_o_grava() -> None:
    assert oraculo.achado_obtido("PARENT_REJECTED", "parent_id", {"parent_table": "t", "parent_row_id": 7}) == \
        oraculo.AchadoEsperado("PARENT_REJECTED", "parent_id", ("t", 7))
    assert oraculo.achado_obtido("DUP_PARTIAL", None, {"key_columns": ["id"]}) == \
        oraculo.AchadoEsperado("DUP_PARTIAL", None, ("id",))
    assert oraculo.achado_obtido("DUP_EXACT", None, {"canonical_row_id": 3}) == \
        oraculo.AchadoEsperado("DUP_EXACT", None, (3,))
    assert oraculo.achado_obtido("MONEY_LOCALE", "amount", {}) == oraculo.AchadoEsperado("MONEY_LOCALE", "amount")
