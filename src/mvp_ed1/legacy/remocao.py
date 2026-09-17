"""Modelos da exclusão física do legado (ADR-0045) — gerados da declaração, como os demais.

Três modelos em `trusted` e dois testes de dados, todos a partir de `Base.metadata`
(a chave primária e o seu tipo, tabela a tabela) e da lista de tabelas de
`schema`. Escrever os quarenta braços à mão daria uma segunda lista que
divergiria da primeira no dia em que uma tabela entrasse ou saísse.

* `legacy_presence_by_capture` — por captura certificada (e pela selecionada),
  tabela e **chave canônica**: quantas linhas físicas, e os payloads brutos.
  É a única leitura das 40 fontes; os dois modelos seguintes leem só dele, o
  que é o que torna os *unit tests* do dbt viáveis (três entradas a simular,
  não quarenta e duas);
* `legacy_capture_transitions` — o **intervalo**: entre a certificada anterior
  mais recente e a selecionada, por chave e com multiplicidade. É o que fecha
  a equação em linhas físicas;
* `legacy_removed_records` — a **memória**: chaves vistas em qualquer
  certificada anterior e ausentes na selecionada, com `last_seen`,
  `removed_in` e o último payload. Persiste por construção; não entra em
  equação nenhuma;
* `legado_presenca_fisica_reconcilia` — o teste: por tabela,
  `linhas(anterior) − Σ max(0, n_ant − n_sel) + Σ max(0, n_sel − n_ant)
  + Δ sem_identidade = linhas(selecionada)`;
* `legado_vinculo_nao_diverge_por_representacao` — a sentinela: a limpeza
  resolve o pai por igualdade **textual** e a comparação entre capturas pela
  chave **canônica** (D43); um filho que só encontra o pai pela segunda seria
  órfão em silêncio, e este teste o acusa em vez disso.
"""

from __future__ import annotations

import pathlib
import re
import uuid

from sqlalchemy import BigInteger, Integer, SmallInteger, Uuid

from mvp_ed1.legacy import schema
from mvp_ed1.legacy.dbt import AVISO, certificadas_sql
from mvp_ed1.models import Base

DESTINO = pathlib.Path("dbt/models/trusted/legacy")
TESTES = pathlib.Path("dbt/tests")

#: Domínio de cada tipo inteiro do PostgreSQL — o mesmo que a macro confere.
DOMINIOS = {
    "bigint": (-(2**63), 2**63 - 1),
    "integer": (-(2**31), 2**31 - 1),
    "smallint": (-(2**15), 2**15 - 1),
}

#: Os mesmos regex da macro, com duas diferenças de dialeto que fazem a mesma
#: coisa: `\Z` no lugar de `$` (em Python `$` aceita um `\n` final; no ARE do
#: PostgreSQL não), e brancos ASCII explícitos no lugar de `\s` (que em Python,
#: como no ARE, casaria U+00A0 e U+2003 — e o cast recusa). RV10-2-05.
#:
#: A gramática do inteiro é a de `pg_strtoint64` do PostgreSQL 16 (RV10-3-01):
#: sinal, e o número em decimal, hexa (`0x`), octal (`0o`) ou binário (`0b`),
#: com `_` entre dígitos ou logo depois do prefixo. Nenhum quantificador se
#: sobrepõe ao vizinho — `0*` antes de `[0-9]+` custava tempo quadrático em
#: zeros seguidos de sufixo inválido (RV10-3-03); os zeros à esquerda saem
#: depois, por `lstrip`, que é linear.
_BRANCOS = r"[ \t\n\x0b\x0c\r]"
_INTEIRO = re.compile(
    _BRANCOS + r"*([+-]?)"
    r"(0[xX]_?[0-9a-fA-F]+(?:_[0-9a-fA-F]+)*|0[oO]_?[0-7]+(?:_[0-7]+)*|0[bB]_?[01]+(?:_[01]+)*|[0-9]+(?:_[0-9]+)*)"
    + _BRANCOS + r"*\Z"
)
_UUID = re.compile(r"(\{([0-9a-f]{4}-?){7}[0-9a-f]{4}\}|([0-9a-f]{4}-?){7}[0-9a-f]{4})\Z", re.IGNORECASE)

#: Base por prefixo, e quantos dígitos significativos cabem em `bigint` — a
#: macro corta no mesmo ponto; acima disso o valor está fora de qualquer dos
#: três domínios sem que seja preciso convertê-lo.
_BASES = {"0x": (16, 16), "0o": (8, 22), "0b": (2, 64)}
_DECIMAL = (10, 19)


def chave(tabela: str) -> tuple[str, str]:
    """`(coluna, tipo)` da chave de negócio: a PK declarada, e o tipo que a canoniza.

    O tipo é o **domínio** do PostgreSQL que a declaração pede — `bigint`,
    `integer`, `smallint`, `uuid` ou `texto` —, e não "inteiro" em geral: a
    macro confere o domínio antes de converter, e `9223372036854775808` não é
    identidade de uma coluna `BigInteger` (RV10-05).
    """
    colunas = list(Base.metadata.tables[f"oltp.{tabela}"].primary_key.columns)
    if len(colunas) != 1:
        raise ValueError(f"{tabela}: chave primária composta não é suportada na comparação entre capturas")
    coluna = colunas[0]
    if isinstance(coluna.type, BigInteger):
        tipo = "bigint"
    elif isinstance(coluna.type, SmallInteger):
        tipo = "smallint"
    elif isinstance(coluna.type, Integer):
        tipo = "integer"
    elif isinstance(coluna.type, Uuid):
        tipo = "uuid"
    else:
        tipo = "texto"
    return coluna.name, tipo


def canonizar(valor: str | None, tipo: str) -> str | None:
    """A mesma canonização da macro `chave_canonica`, em Python — o esperado independente.

    É o que o diário de mutações e os testes usam para dizer que chave
    **deveria** aparecer em `legacy_capture_transitions`: `08` removido é a
    chave `8`. Mesma gramática, mesmo domínio, mesma fronteira (nulo para o que
    não converte); se a macro e esta função divergirem, o teste que compara o
    diário com o intervalo acusa.
    """
    if valor is None:
        return None
    if tipo in DOMINIOS:
        casado = _INTEIRO.match(valor)
        if casado is None:
            return None
        sinal, corpo = casado.groups()
        corpo = corpo.lower().replace("_", "")
        base, limite = _BASES.get(corpo[:2], _DECIMAL)
        digitos = (corpo[2:] if corpo[:2] in _BASES else corpo).lstrip("0")
        if len(digitos) > limite:
            return None
        numero = int(digitos, base) if digitos else 0
        if sinal == "-":
            numero = -numero
        minimo, maximo = DOMINIOS[tipo]
        return str(numero) if minimo <= numero <= maximo else None
    if tipo == "uuid":
        return str(uuid.UUID(hex=valor.strip("{}").replace("-", ""))) if _UUID.match(valor) else None
    if tipo == "texto":
        return valor.strip() or None
    raise ValueError(f"chave_canonica: tipo desconhecido {tipo}")


def presenca_por_captura() -> str:
    ramos = []
    for tabela in schema.tabelas():
        coluna, tipo = chave(tabela)
        payload = ", ".join(f"'{c}', r.\"{c}\"" for c in schema.colunas(tabela))
        ramos.append(
            f"""select
    '{tabela}'::text                                          as source_table,
    {schema.CAPTURA_SQL.replace('_airbyte_meta', 'r._airbyte_meta')}                     as snapshot_id,
    {{{{ chave_canonica('r."{coluna}"', '{tipo}') }}}}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object({payload}) order by r.legacy_row_id) as payloads
from {{{{ source('legacy', '{tabela}') }}}} r
where {schema.CAPTURA_SQL.replace('_airbyte_meta', 'r._airbyte_meta')} in (select snapshot_id from consideradas)
group by 1, 2, 3"""
        )
    uniao = "\n\nunion all\n\n".join(ramos)
    return f"""{AVISO}
-- Presença física por captura, tabela e chave canônica (ADR-0045).
--
-- Só capturas **certificadas** entram (ADR-0044), mais a selecionada — que é
-- certificada por definição, salvo quando `legacy_snapshot_id` reprocessa uma
-- antiga. A chave é a PK declarada no SQLAlchemy, canonizada pelo tipo:
-- `business_key` nulo é linha **sem identidade**, contada à parte.

{{{{ config(materialized='table') }}}}

with {certificadas_sql()},

selecionada as (

    select snapshot_id from {{{{ ref('legacy_selected_capture') }}}}

),

consideradas as (

    select snapshot_id from certificadas
    union
    select snapshot_id from selecionada where snapshot_id is not null

)

{uniao}
"""


def transicoes() -> str:
    return f"""{AVISO}
-- O intervalo entre a certificada anterior mais recente e a selecionada (ADR-0045).
--
-- Por tabela e chave canônica, com **multiplicidade**: `removida` (n > 0 → 0),
-- `adicionada` (0 → n > 0), `reduzida`/`aumentada` (as duas > 0 e diferentes),
-- `mantida`. Linhas sem identidade entram como `sem_identidade`, por lado.
-- Sem anterior certificada não há intervalo: o modelo fica vazio, e o teste de
-- reconciliação não tem o que cobrar.

{{{{ config(materialized='table') }}}}

with {certificadas_sql()},

selecionada as (

    select snapshot_id from {{{{ ref('legacy_selected_capture') }}}}

),

anterior as (

    select max(snapshot_id) as snapshot_id
    from certificadas
    where snapshot_id < (select snapshot_id from selecionada)

),

presenca as (

    select * from {{{{ ref('legacy_presence_by_capture') }}}}

),

lado_anterior as (

    select source_table, business_key, n
    from presenca
    where snapshot_id = (select snapshot_id from anterior)

),

lado_selecionado as (

    select source_table, business_key, n
    from presenca
    where snapshot_id = (select snapshot_id from selecionada)
      and (select snapshot_id from anterior) is not null

),

com_identidade as (

    select
        coalesce(a.source_table, s.source_table)        as source_table,
        coalesce(a.business_key, s.business_key)        as business_key,
        coalesce(a.n, 0)                                as n_anterior,
        coalesce(s.n, 0)                                as n_selecionada
    from (select * from lado_anterior where business_key is not null) a
    full outer join (select * from lado_selecionado where business_key is not null) s
      on s.source_table = a.source_table and s.business_key = a.business_key

),

sem_identidade as (

    select
        coalesce(a.source_table, s.source_table)        as source_table,
        null::text                                      as business_key,
        coalesce(a.n, 0)                                as n_anterior,
        coalesce(s.n, 0)                                as n_selecionada
    from (select * from lado_anterior where business_key is null) a
    full outer join (select * from lado_selecionado where business_key is null) s
      on s.source_table = a.source_table

)

select
    (select snapshot_id from anterior)                  as previous_snapshot_id,
    (select snapshot_id from selecionada)               as selected_snapshot_id,
    source_table,
    business_key,
    n_anterior                                          as rows_before,
    n_selecionada                                       as rows_after,
    case
        when business_key is null                       then 'sem_identidade'
        when n_anterior > 0 and n_selecionada = 0       then 'removida'
        when n_anterior = 0 and n_selecionada > 0       then 'adicionada'
        when n_anterior > n_selecionada                 then 'reduzida'
        when n_anterior < n_selecionada                 then 'aumentada'
        else                                                 'mantida'
    end                                                 as transition
from (select * from com_identidade union all select * from sem_identidade) t
where (select snapshot_id from anterior) is not null
"""


def removidos() -> str:
    return f"""{AVISO}
-- A memória da ausência: o que já sumiu da origem legada e não voltou (ADR-0045).
--
-- Chave presente em **qualquer** captura certificada anterior à selecionada e
-- ausente nela. `last_seen_snapshot_id` é a maior onde esteve;
-- `removed_in_snapshot_id` é a menor certificada **posterior a ela** — depois
-- de um reaparecimento e nova exclusão, as duas avançam juntas. Persiste por
-- construção em toda captura seguinte; sai quando a chave reaparece. Não entra
-- em equação nenhuma: é auditoria. O payload é o **bruto** da última captura em
-- que a chave existiu — não é tratado, e o dicionário diz isso.

{{{{ config(materialized='table') }}}}

with {certificadas_sql()},

selecionada as (

    select snapshot_id from {{{{ ref('legacy_selected_capture') }}}}

),

presenca as (

    select * from {{{{ ref('legacy_presence_by_capture') }}}}
    where business_key is not null

),

historico as (

    select p.*
    from presenca p
    join certificadas c on c.snapshot_id = p.snapshot_id
    where p.snapshot_id < (select snapshot_id from selecionada)

),

presentes_agora as (

    select source_table, business_key
    from presenca
    where snapshot_id = (select snapshot_id from selecionada)

),

ausentes as (

    select h.source_table, h.business_key, max(h.snapshot_id) as last_seen_snapshot_id
    from historico h
    where not exists (
        select 1 from presentes_agora a
        where a.source_table = h.source_table and a.business_key = h.business_key
    )
    group by 1, 2

)

select
    a.source_table,
    a.business_key,
    a.last_seen_snapshot_id,
    (
        select min(c.snapshot_id) from certificadas c
        where c.snapshot_id > a.last_seen_snapshot_id
          and c.snapshot_id <= (select snapshot_id from selecionada)
    )                                                   as removed_in_snapshot_id,
    (select snapshot_id from selecionada)               as observed_in_snapshot_id,
    h.n                                                 as rows_last_seen,
    h.payloads                                          as last_payload
from ausentes a
join historico h
  on h.source_table = a.source_table
 and h.business_key = a.business_key
 and h.snapshot_id = a.last_seen_snapshot_id
"""


def teste_presenca_fisica() -> str:
    contagens = "\n    union all\n".join(
        f"    select '{tabela}' as source_table, {schema.CAPTURA_SQL} as snapshot_id, count(*) as linhas"
        f" from {{{{ source('legacy', '{tabela}') }}}} group by 1, 2"
        for tabela in schema.tabelas()
    )
    return f"""{AVISO}
-- A equação física entre a certificada anterior e a selecionada (ADR-0045):
--
--   linhas(anterior) − Σ max(0, n_ant − n_sel) + Σ max(0, n_sel − n_ant)
--     + (sem_identidade_sel − sem_identidade_ant) = linhas(selecionada)
--
-- por tabela, em **linhas físicas** contadas direto no bruto — não nas
-- transições. É o que garante que o modelo de intervalo descreve o que o bruto
-- tem, e não o contrário. Sem anterior certificada não há linhas a cobrar.

with transicoes as (

    select * from {{{{ ref('legacy_capture_transitions') }}}}

),

bruto as (

{contagens}

),

por_tabela as (

    select
        source_table,
        min(previous_snapshot_id)                                   as previous_snapshot_id,
        min(selected_snapshot_id)                                   as selected_snapshot_id,
        sum(case when business_key is not null then greatest(rows_before - rows_after, 0) else 0 end) as perdidas,
        sum(case when business_key is not null then greatest(rows_after - rows_before, 0) else 0 end) as ganhas,
        sum(case when business_key is null then rows_after - rows_before else 0 end)                  as delta_sem_identidade
    from transicoes
    group by source_table

)

select
    t.source_table,
    coalesce(a.linhas, 0)                                           as linhas_anterior,
    coalesce(s.linhas, 0)                                           as linhas_selecionada,
    t.perdidas, t.ganhas, t.delta_sem_identidade,
    coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade as calculado
from por_tabela t
left join bruto a on a.source_table = t.source_table and a.snapshot_id = t.previous_snapshot_id
left join bruto s on s.source_table = t.source_table and s.snapshot_id = t.selected_snapshot_id
where coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade <> coalesce(s.linhas, 0)
"""


def referencias() -> list[tuple[str, str, str, str, str]]:
    """`(filha, coluna, pai, chave, tipo)` de cada chave estrangeira declarada, na ordem do modelo."""
    saida = []
    for tabela in schema.tabelas():
        for fk in sorted(Base.metadata.tables[f"oltp.{tabela}"].foreign_keys, key=lambda f: f.parent.name):
            pai = fk.column.table.name
            saida.append((tabela, fk.parent.name, pai, fk.column.name, chave(pai)[1]))
    return saida


def teste_vinculo_por_representacao() -> str:
    ramos = "\n    union all\n".join(
        f"""    select '{filha}' as source_table, f.legacy_row_id, '{coluna}' as column_name,
        '{pai}' as parent_table, f.cleaned_payload->>'{coluna}' as parent_value
    from registros f
    where f.source_table = '{filha}' and f.cleaned_payload->>'{coluna}' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = '{pai}' and p.cleaned_payload->>'{chave_pai}' = f.cleaned_payload->>'{coluna}'
      )
      and exists (
          select 1 from registros p
          where p.source_table = '{pai}'
            and {{{{ chave_canonica("p.cleaned_payload->>'{chave_pai}'", '{tipo}') }}}}
              = {{{{ chave_canonica("f.cleaned_payload->>'{coluna}'", '{tipo}') }}}}
      )"""
        for filha, coluna, pai, chave_pai, tipo in referencias()
    )
    return f"""{AVISO}
-- Sentinela da identidade do vínculo (17/09/2026, registrada junto à D43).
--
-- A classificação resolve a referência ao pai por igualdade **textual**
-- (`classification.sql`, CTE `edges`); a comparação entre capturas resolve a
-- mesma chave pela forma **canônica** do tipo (`chave_canonica`, ADR-0045).
-- Enquanto as chaves do bruto forem inteiros e UUIDs limpos as duas coincidem.
-- No dia em que um pai for escrito `0x8` e o filho `8`, o intervalo dirá
-- `mantida` e a limpeza dirá `FK_ORPHAN` — e este teste acusa o filho, em vez
-- de deixar a divergência passar como órfão legítimo. Não muda tratamento
-- nenhum: unificar as noções de identidade é decisão da D43.

with registros as (

    select source_table, legacy_row_id, cleaned_payload
    from {{{{ ref('legacy_records') }}}}

)

{ramos}
"""


def gerar(destino: pathlib.Path = DESTINO, testes: pathlib.Path = TESTES) -> list[pathlib.Path]:
    destino.mkdir(parents=True, exist_ok=True)
    testes.mkdir(parents=True, exist_ok=True)
    saidas = {
        destino / "legacy_presence_by_capture.sql": presenca_por_captura(),
        destino / "legacy_capture_transitions.sql": transicoes(),
        destino / "legacy_removed_records.sql": removidos(),
        testes / "legado_presenca_fisica_reconcilia.sql": teste_presenca_fisica(),
        testes / "legado_vinculo_nao_diverge_por_representacao.sql": teste_vinculo_por_representacao(),
    }
    for caminho, conteudo in saidas.items():
        caminho.write_text(conteudo, encoding="utf-8")
    return list(saidas)
