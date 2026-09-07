"""Geração das pontes que põem o legado na forma da origem principal.

O empilhamento acontece em `trusted` (ADR-0021), e lá os modelos leem colunas
**renomeadas** pelo `staging`. O conjunto apto do legado chega de outro jeito:
um `cleaned_payload` em JSONB, com os nomes e a tipagem frouxa da origem antiga.
A ponte é o que reconcilia as duas formas, para que o empilhamento seja um
`union all` entre duas relações do mesmo formato.

── Por que gerar, e não escrever ─────────────────────────────────────────────
São 36 tabelas, e a ponte de cada uma é o mesmo mapa de renome que o modelo de
`staging` da origem principal já declara. Escrevê-la à mão seria manter esse
mapa em dois lugares: o dia em que uma coluna fosse renomeada no `staging`, a
ponte continuaria produzindo o nome antigo, e o `union all` quebraria — ou, pior,
casaria por posição com a coluna errada.

Aqui o mapa tem um dono só. O gerador **lê** o modelo de `staging` da origem
principal, extrai a projeção do bloco `renomeado`, e reescreve cada referência
de coluna como extração do JSONB com o tipo declarado no modelo SQLAlchemy. O
que se revisa é este arquivo; as 36 pontes são derivado (§5 do `CLAUDE.md`).

── O que o gerador se recusa a adivinhar ─────────────────────────────────────
Identificador que não é coluna da origem nem está declarado em `FORA_DA_ORIGEM`
interrompe a geração com o nome da tabela e do identificador. Emitir SQL
plausível para um caso não previsto seria produzir uma ponte silenciosamente
errada, e a falha entraria no armazém em vez de aparecer aqui.
"""

from __future__ import annotations

import pathlib
import re

from sqlalchemy import JSON, String, Text, Uuid
from sqlalchemy.dialects import postgresql

from mvp_ed1.legacy import schema
from mvp_ed1.models import Base

#: Onde estão os modelos de `staging` da origem principal, de onde sai o mapa.
ORIGEM = pathlib.Path("dbt/models/staging")

#: Onde as pontes moram — junto dos demais derivados do legado.
DESTINO = pathlib.Path("dbt/models/trusted/legacy")

AVISO = """-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
"""

#: Expressões da projeção que **não** nascem de coluna da origem, e o que a
#: ponte põe no lugar de cada uma.
#:
#: `_airbyte_extracted_at` é o carimbo de carga da origem principal; o
#: equivalente no legado é o carimbo da captura. As duas de linhagem do estoque
#: (ADR-0031) são constantes aqui por definição: o legado é capturado em lote e
#: não tem caminho de *streaming* — dizer que chegou pelos dois seria inventar.
FORA_DA_ORIGEM: dict[str, str] = {
    "_airbyte_extracted_at": "snapshot_at",
    "first_ingested_at": "snapshot_at",
    "arrived_by_stream": "false",
    "arrived_by_batch": "true",
    # Ordenação técnica que o banco atribui na origem principal. No legado o
    # equivalente é a identidade da ocorrência física, que é o que o sistema
    # antigo tem de mais próximo de uma ordem local — e a unicidade continua
    # valendo, porque depois do empilhamento ela é por origem (ADR-0039).
    "event_sequence": "legacy_row_id",
}

#: Palavras que a projeção usa e que não são identificador de coluna. A lista é
#: curta de propósito: cada acréscimo é uma construção nova nos modelos de
#: `staging`, e passar por aqui é o que obriga a olhar para ela.
PALAVRAS = frozenset(
    {"cast", "as", "is", "not", "null", "true", "false", "and", "or",
     "integer", "bigint", "numeric", "text", "boolean", "date", "coalesce"}
)

#: Tabelas do legado sem contraparte na origem principal. Não são empilháveis:
#: não há relação com que unir. Ficam declaradas para que a ausência seja
#: legível, e para que o teste de reconciliação saiba que a exceção é conhecida.
SEM_CONTRAPARTE: dict[str, str] = {
    "customer_contacts": "sem modelo de staging na origem principal",
    "customer_preferences": "sem modelo de staging na origem principal",
    "price_lists": "sem modelo de staging na origem principal",
    "product_prices": "sem modelo de staging na origem principal",
}


#: Onde cada tabela do legado é empilhada. O modelo `trusted` da esquerda tem a
#: tabela da direita como **relação condutora**: uma linha apta do legado vira
#: uma linha do modelo, e a contagem de um lado tem de bater com a do outro.
#:
#: A lista existe para ser conferida de uma olhada, e para gerar o teste de
#: reconciliação — que sem ela seria escrito 27 vezes à mão e envelheceria na
#: primeira tabela nova.
CONDUTORAS: dict[str, str] = {
    "campaigns": "campaigns",
    "carriers": "carriers",
    "carts": "carts",
    "coupon_redemptions": "coupon_redemptions",
    "coupons": "coupons",
    "customers": "customers",
    "delivery_events": "delivery_events",
    "inventory_balances": "inventory_balances",
    "inventory_movements": "inventory_movements",
    "order_items": "order_items",
    "order_status_events": "order_status_history",
    "orders": "orders",
    "payment_methods": "payment_methods",
    "payment_transactions": "payment_transactions",
    "payments": "payments",
    "product_skus": "product_variants",
    "purchase_order_items": "purchase_order_items",
    "purchase_orders": "purchase_orders",
    "refunds": "refunds",
    "sales_channels": "sales_channels",
    "shipment_items": "shipment_items",
    "shipments": "shipments",
    "suppliers": "suppliers",
    "support_agents": "support_agents",
    "support_tickets": "support_tickets",
    "ticket_events": "ticket_events",
    "warehouses": "warehouses",
}

#: Tabelas que entram em `trusted` **enriquecendo** um modelo de outro grão, e
#: não conduzindo um seu. Item de carrinho vira contagem e valor do carrinho;
#: endereço vira a cidade do cliente; categoria e marca viram atributo do SKU.
#: Não têm uma linha própria no armazém, e por isso a reconciliação por
#: contagem não as alcança — o que as alcança é o teste da ponte.
ENRIQUECIMENTO: dict[str, str] = {
    "brands": "product_skus",
    "cart_items": "carts",
    "customer_addresses": "customers",
    "customer_segments": "customers",
    "goods_receipt_items": "purchase_order_items",
    "goods_receipts": "purchase_order_items",
    "product_categories": "product_skus",
    "products": "product_skus",
    "stock_reservations": "inventory_balances",
}


def _tipo(tabela: str, coluna: str) -> str:
    """Tipo em que a extração do JSONB é convertida.

    Texto vira `text` sem largura, mesmo quando o modelo declara `varchar(n)`:
    converter para o tipo estreito **truncaria em silêncio** um valor que
    passou pela limpeza, que é exatamente o descarte mudo que a regra 4 proíbe.
    Se um valor do legado for mais largo que a coluna de hoje, o `union all`
    alarga o resultado e a diferença fica visível.

    `uuid` e `jsonb` também viram `text`, e o motivo é outro: o alvo a igualar
    não é o tipo do modelo, é **o que o `staging` da origem principal entrega**.
    O Airbyte grava os dois como `varchar` em `raw` e o `staging` só renomeia;
    uma ponte que convertesse para o tipo do modelo daria um `union all` de
    tipos que o Postgres se recusa a casar.
    """
    c = Base.metadata.tables[f"{Base.metadata.schema}.{tabela}"].columns[coluna]
    if isinstance(c.type, (JSON, String, Text, Uuid)):
        return "text"
    compilado = c.type.compile(dialect=postgresql.dialect()).lower()
    return "timestamptz" if compilado == "timestamp with time zone" else compilado


def _derivada(tabela: str, coluna: str) -> str | None:
    """Expressão da coluna que o banco mantém derivada, quando é o caso.

    `quantity_available` não existe no legado: na origem principal ela é
    `Computed`, e o legado, tipado frouxo, não tem coluna gerada. A ponte
    recalcula a partir da mesma expressão declarada no modelo — copiá-la aqui
    faria a derivada divergir da definição no dia em que ela mudasse.
    """
    tabela_origem = Base.metadata.tables[f"{Base.metadata.schema}.{tabela}"]
    c = tabela_origem.columns.get(coluna)
    if c is None or not getattr(c, "computed", None):
        return None
    return str(c.computed.sqltext)


def _projecao(sql: str) -> list[str]:
    """Itens da projeção do bloco `renomeado`, sem comentários nem vazios."""
    corpo = re.search(r"renomeado as \(\s*select\n(.*?)\n    from ", sql, re.S)
    if corpo is None:
        raise ValueError("o modelo não tem o bloco `renomeado as (select ... from`")
    limpo = re.sub(r"--[^\n]*", "", corpo.group(1))

    itens, atual, profundidade = [], "", 0
    for caractere in limpo:
        if caractere == "(":
            profundidade += 1
        elif caractere == ")":
            profundidade -= 1
        if caractere == "," and profundidade == 0:
            itens.append(atual)
            atual = ""
            continue
        atual += caractere
    itens.append(atual)
    return [" ".join(i.split()) for i in itens if i.strip()]


def _parte(item: str) -> tuple[str, str]:
    """Separa expressão e apelido, ignorando o `as` de dentro de `cast(...)`."""
    profundidade, corte = 0, None
    for posicao, caractere in enumerate(item):
        if caractere == "(":
            profundidade += 1
        elif caractere == ")":
            profundidade -= 1
        elif profundidade == 0 and item[posicao : posicao + 4] == " as ":
            corte = posicao
    if corte is None:
        return item, item.split(".")[-1]
    return item[:corte], item[corte + 4 :].strip()


def _reescreve(tabela: str, expressao: str, colunas: frozenset[str]) -> str:
    """Troca cada referência de coluna pela extração tipada do `cleaned_payload`."""
    sem_alias = re.sub(r"\b[a-z]\.(?=[a-z_])", "", expressao)

    def troca(achado: re.Match[str]) -> str:
        nome = achado.group(0)
        if nome in colunas:
            return f"(cleaned_payload->>'{nome}')::{_tipo(tabela, nome)}"
        if nome in FORA_DA_ORIGEM:
            return FORA_DA_ORIGEM[nome]
        derivada = _derivada(tabela, nome)
        if derivada is not None:
            return "(" + _reescreve(tabela, derivada, colunas) + ")"
        if nome in PALAVRAS:
            return nome
        raise ValueError(
            f"`{tabela}`: `{nome}` não é coluna da origem nem está declarado em"
            " FORA_DA_ORIGEM — declare o que a ponte deve pôr no lugar"
        )

    fora_de_texto = re.split(r"('[^']*')", sem_alias)
    for posicao, pedaco in enumerate(fora_de_texto):
        if not pedaco.startswith("'"):
            fora_de_texto[posicao] = re.sub(r"[a-z_][a-z0-9_]*", troca, pedaco)
    return "".join(fora_de_texto)


def modelo(tabela: str) -> str:
    """SQL de uma ponte."""
    sql = (ORIGEM / f"stg_retail__{tabela}.sql").read_text(encoding="utf-8")
    colunas = frozenset(schema.colunas(tabela))

    linhas = []
    for item in _projecao(sql):
        expressao, apelido = _parte(item)
        traduzida = _reescreve(tabela, expressao.strip(), colunas)
        recuo = " " * max(1, 56 - 4 - len(traduzida))
        linhas.append(f"    {traduzida}{recuo}as {apelido}")

    corpo = ",\n".join(linhas)
    return f"""{AVISO}
-- Registros aptos de `legacy.{tabela}`, na forma que `stg_retail__{tabela}`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{{{ ref('legacy_eligible_records') }}}}
    where source_table = '{tabela}'

)

select
{corpo}
from apto
"""


def empilhaveis() -> tuple[str, ...]:
    """Tabelas do legado que têm contraparte na origem principal."""
    return tuple(t for t in schema.tabelas() if t not in SEM_CONTRAPARTE)


def models_yml() -> str:
    """Declaração das pontes, sem repetir a descrição de coluna do `staging`.

    Cada ponte expõe exatamente as colunas do modelo de `staging` que a gerou, e
    a descrição delas já vive lá. Copiá-la para cá criaria uma segunda cópia que
    envelheceria — o que a documentação do projeto trata como defeito. O que
    esta declaração acrescenta é o que só a ponte sabe: de que tabela do legado
    ela vem, e em que modelo o resultado é empilhado.
    """
    onde = {tabela: modelo_trusted for modelo_trusted, tabela in CONDUTORAS.items()}
    onde.update(ENRIQUECIMENTO)

    entradas = "\n".join(
        f"""  - name: legado__{tabela}
    description: >
      Registros aptos de `legacy.{tabela}` na forma de `stg_retail__{tabela}`,
      empilhados em `{onde[tabela]}`. As colunas são as do modelo de `staging`,
      onde estão descritas.
    meta:
      domain: legado
      owner: data_custodian"""
        for tabela in empilhaveis()
    )
    return f"""# Gerado por `make legacy-models`. Não edite: a lista sai de ponte.py.

version: 2

models:
{entradas}
"""


def gerar(destino: pathlib.Path = DESTINO) -> list[pathlib.Path]:
    """Escreve uma ponte por tabela empilhável e devolve os caminhos."""
    destino.mkdir(parents=True, exist_ok=True)
    escritos = []
    for tabela in empilhaveis():
        caminho = destino / f"legado__{tabela}.sql"
        caminho.write_text(modelo(tabela), encoding="utf-8")
        escritos.append(caminho)
    declaracao = destino / "_pontes__models.yml"
    declaracao.write_text(models_yml(), encoding="utf-8")
    escritos.append(declaracao)
    return escritos


#: Onde os testes gerados moram.
TESTES = pathlib.Path("dbt/tests")


def teste_da_ponte() -> str:
    """Nada apto se perde entre o julgamento e a entrada em `trusted`."""
    ramos = "\n\nunion all\n\n".join(
        f"""select
    '{tabela}'                                  as tabela,
    (select count(*) from {{{{ ref('legacy_eligible_records') }}}}
        where source_table = '{tabela}')        as aptos,
    (select count(*) from {{{{ ref('legado__{tabela}') }}}}) as na_ponte
where (select count(*) from {{{{ ref('legacy_eligible_records') }}}}
        where source_table = '{tabela}')
   <> (select count(*) from {{{{ ref('legado__{tabela}') }}}})"""
        for tabela in empilhaveis()
    )
    return f"""{AVISO}
-- A ponte entrega o conjunto apto inteiro, tabela por tabela.
--
-- É a primeira metade de `empilhados = aceitos + corrigidos` (Origem Legada
-- §6): entre o julgamento e a entrada em `trusted` não se perde nem se ganha
-- registro. A segunda metade — que o modelo `trusted` empilhou o que a ponte
-- entregou — está em `legado_empilhado_reconcilia`.
--
-- Uma linha no resultado é uma tabela em que as duas contagens divergiram.

{ramos}
"""


def teste_do_empilhamento() -> str:
    """A contagem do legado em cada modelo condutor é a do seu conjunto apto."""
    ramos = "\n\nunion all\n\n".join(
        f"""select
    '{modelo_trusted}'                          as modelo,
    '{tabela}'                                  as tabela,
    (select count(*) from {{{{ ref('legado__{tabela}') }}}}) as aptos,
    (select count(*) from {{{{ ref('{modelo_trusted}') }}}}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{{{ ref('legado__{tabela}') }}}})
   <> (select count(*) from {{{{ ref('{modelo_trusted}') }}}}
        where source_system = 'legacy')"""
        for modelo_trusted, tabela in sorted(CONDUTORAS.items())
    )
    return f"""{AVISO}
-- O que cada modelo empilhou é o que a ponte lhe entregou.
--
-- Segunda metade de `empilhados = aceitos + corrigidos` (Origem Legada §6).
-- Divergir aqui não é arredondamento: é junção interna derrubando registro do
-- legado em silêncio — o pai que ficou para trás, a chave que não casou —, que
-- é o descarte mudo que a regra 4 proíbe.
--
-- Só as tabelas **condutoras** aparecem: as de enriquecimento entram noutro
-- grão e não têm linha própria para contar. A divisão está em
-- `src/mvp_ed1/legacy/ponte.py`.
--
-- Uma linha no resultado é um modelo em que as duas contagens divergiram.

{ramos}
"""


def gerar_testes(destino: pathlib.Path = TESTES) -> list[pathlib.Path]:
    """Escreve os dois testes de reconciliação do empilhamento."""
    destino.mkdir(parents=True, exist_ok=True)
    escritos = []
    for nome, conteudo in (
        ("legado_ponte_preserva_o_conjunto_apto", teste_da_ponte()),
        ("legado_empilhado_reconcilia", teste_do_empilhamento()),
    ):
        caminho = destino / f"{nome}.sql"
        caminho.write_text(conteudo, encoding="utf-8")
        escritos.append(caminho)
    return escritos
