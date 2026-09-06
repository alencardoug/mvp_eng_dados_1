"""Geração dos modelos dbt de limpeza, a partir do catálogo.

O ADR-0022 diz que do catálogo saem três coisas: o injetor, as regras de
limpeza e os testes. As duas primeiras já existem em Python; esta é a terceira
ponta — as regras viram **modelos dbt gerados**, um por tabela do legado.

Por que gerar em vez de escrever à mão: são 40 tabelas e 416 colunas, e cada
coluna se sujeita às falhas do seu arquétipo. Escrever isso uma vez por tabela
seria repetição que envelhece na primeira coluna nova; escrever um modelo
genérico em SQL não é possível, porque a lógica é **por coluna** e o SQL não
tem como aplicá-la dinamicamente sem SQL dinâmico.

O que se revisa é este arquivo e o catálogo. Os 40 modelos são derivado, e a
§5 do `CLAUDE.md` os põe em amostragem — corrigi-los à mão seria perder o
conserto na próxima geração.
"""

from __future__ import annotations

import pathlib

from mvp_ed1.generator import enums
from mvp_ed1.legacy import schema
from mvp_ed1.legacy.catalogo import Catalogo
from mvp_ed1.legacy.regras import Regra, regra_enum, regra_faixa, regra_truncado, regras

#: Onde os modelos gerados moram. Diretório próprio: são derivados, e misturá-los
#: com os escritos à mão faria a fronteira da revisão desaparecer.
DESTINO = pathlib.Path("dbt/models/staging/legacy")

#: Falhas que não são de valor: precisam de contexto que uma coluna não tem —
#: outras linhas, outras tabelas, ou o resultado do tratamento do pai.
DE_CONTEXTO = frozenset(
    {"FK_ORPHAN", "DUP_EXACT", "DUP_PARTIAL", "TOTAL_MISMATCH", "PARENT_REJECTED"}
)

AVISO = """-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
"""


def _aplicaveis(
    catalogo: Catalogo, tabela: str, coluna: str, promessas: frozenset[str], limites
) -> list[Regra]:
    """Regras que alcançam a coluna, na ordem de precedência do catálogo.

    A ordem **é** a de declaração, e não é acaso: `NUM_TEXT_EQUIV` precisa vir
    antes de `NUM_AMBIGUOUS`, porque `244,0` casa com os dois e só o primeiro
    sabe o que fazer com ele. Reordenar o catálogo muda o tratamento.
    """
    arquetipo = schema.arquetipo(tabela, coluna, promessas)
    valor = regras(catalogo.nulos_disfarcados, catalogo.delimitador)
    saida: list[Regra] = []
    for falha in catalogo.injetaveis:
        if falha.codigo in DE_CONTEXTO or not schema.alcanca(falha.arquetipo, arquetipo):
            continue
        if falha.codigo == "TEXT_TRUNCATED":
            largura = limites.get((tabela, coluna))
            if largura:
                saida.append(regra_truncado(largura))
            continue
        if falha.codigo == "ENUM_UNKNOWN":
            dominio = enums.enumeracoes().get(tabela, {}).get(coluna)
            if dominio:
                saida.append(regra_enum(dominio))
            continue
        if falha.codigo == "NUM_OUT_OF_RANGE":
            saida.append(regra_faixa(f"{tabela}.{coluna}" in catalogo.quantidades_com_sinal))
            continue
        if falha.codigo in valor:
            saida.append(valor[falha.codigo])
    return saida


def _referencia(coluna: str) -> str:
    """A coluna, citada — o Python 3.11 não aceita barra invertida dentro de f-string."""
    return 'c."' + coluna + '"'


def _achado(coluna: str, aplicaveis: list[Regra]) -> str:
    """`case` que devolve o **primeiro** código que casa, ou nulo."""
    alvo = _referencia(coluna)
    ramos = "\n".join(
        "            when " + r.deteccao.format(v=alvo) + f" then '{r.codigo}'"
        for r in aplicaveis
    )
    return f"        case\n{ramos}\n        end"


def _limpo(coluna: str, aplicaveis: list[Regra]) -> str:
    """Valor tratado: converte quando há regra, mantém o original quando não há.

    A rejeição interrompe o `case` preservando o original. Pular esses ramos
    faria uma regra de conversão posterior tratar o mesmo valor: por exemplo,
    `DATE_FORMAT_KNOWN` tentaria converter `31/02/2024`, apesar do achado
    `DATE_IMPOSSIBLE`, e derrubaria a consulta antes da quarentena.
    """
    alvo = _referencia(coluna)
    ramos = [
        "            when " + r.deteccao.format(v=alvo) + " then "
        + (r.conversao.format(v=alvo) if r.conversao is not None else alvo)
        for r in aplicaveis
    ]
    if not ramos:
        return "        " + alvo
    return "        case\n" + "\n".join(ramos) + "\n            else " + alvo + "\n        end"


def modelo(catalogo: Catalogo, tabela: str, promessas: frozenset[str], limites) -> str:
    """SQL de um modelo de limpeza."""
    colunas = [c for c in schema.colunas(tabela)]
    por_coluna = {c: _aplicaveis(catalogo, tabela, c, promessas, limites) for c in colunas}

    limpos = ",\n".join(_limpo(c, por_coluna[c]) + ' as "' + c + '"' for c in colunas)
    achados = ",\n".join(
        f"            '{c}', {_achado(c, por_coluna[c]).strip()}"
        for c in colunas
        if por_coluna[c]
    )
    original = ", ".join(f"'{column}', c.\"{column}\"" for column in colunas)

    return f"""{AVISO}
-- Limpeza de `legacy.{tabela}` — camada `staging` (ADR-0016).
--
-- Uma linha por ocorrência física da **captura mais recente**. Reter capturas
-- antigas (ADR-0037) não significa somá-las: o tratamento olha a última, e as
-- anteriores existem para comparação e reprocessamento.
--
-- Duas saídas por coluna: o valor tratado e o **achado**, que é o código da
-- primeira falha que casa. O valor original permanece acessível em
-- `raw_legacy`, que é imutável.

with captura as (

    select *
    from {{{{ source('legacy', '{tabela}') }}}}
    where _airbyte_generation_id = coalesce(
        {{{{ legacy_snapshot_id() }}}}, (
        select max(_airbyte_generation_id) from {{{{ source('legacy', '{tabela}') }}}}
    ))

)

select
    c.legacy_row_id,
    c._airbyte_generation_id                    as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    '{schema.SCHEMA}'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
{limpos},

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
{achados}
        )
    )                                           as achados,
    jsonb_build_object({original})              as original_payload
from captura c
"""


def gerar(catalogo: Catalogo, promessas: frozenset[str], destino: pathlib.Path = DESTINO) -> list[pathlib.Path]:
    """Escreve um modelo por tabela e devolve os caminhos."""
    destino.mkdir(parents=True, exist_ok=True)
    limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
    escritos = []
    for tabela in schema.tabelas():
        caminho = destino / f"stg_legacy__{tabela}.sql"
        caminho.write_text(modelo(catalogo, tabela, promessas, limites), encoding="utf-8")
        escritos.append(caminho)
    return escritos


def sources_yml() -> str:
    """Declaração das 40 fontes do legado, gerada da mesma lista dos modelos.

    Escrever à mão daria uma segunda lista de tabelas, que divergiria da
    primeira no dia em que uma entrasse ou saísse.
    """
    linhas = "\n".join(f"      - name: {t}" for t in schema.tabelas())
    return f"""# Gerado por `make legacy-models`. Não edite: a lista sai dos modelos.

version: 2

sources:
  - name: legacy
    description: >
      Capturas retidas da origem legada, escritas pelo Airbyte em modo
      `full_refresh_append` (ADR-0037). **Imutável**: cada carga acrescenta uma
      captura, nenhuma sobrescreve a anterior, e é comparando duas que a
      exclusão física da origem antiga é detectada.

      Os valores chegam como texto, com os defeitos preservados. Tipar aqui
      recusaria justamente as linhas que a etapa existe para tratar.
    database: "{{{{ env_var('WAREHOUSE_DB_NAME') }}}}"
    schema: raw_legacy
    loader: airbyte

    # Sem `freshness`: a origem legada é capturada sob demanda, e não há
    # promessa de atualidade a cobrar dela — ela é um sistema que ninguém mexe.
    tables:
{linhas}
"""
