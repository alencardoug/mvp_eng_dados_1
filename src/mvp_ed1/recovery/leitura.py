"""O que o manifesto afirma, lido dos bancos — e como.

Separado da regra (`oraculos.py`, `rebase.py`) de propósito: aqui mora o SQL,
lá mora o que se prova sem banco. O que este módulo faz é entregar **linhas**
às funções puras, e não calcular nada por si.

**As contagens saem numa transação `repeatable read` por banco**, no mesmo
instante do corte. Sem isso, uma tabela contada antes e outra depois de uma
escrita descreveriam dois estados diferentes como se fossem um.
"""

from __future__ import annotations

import subprocess
from collections.abc import Iterator
from typing import Any

import sqlalchemy as sa
from sqlalchemy import Engine

from mvp_ed1.recovery import oraculos, rebase

#: A chave das fatias da quarentena. `source_system` entra porque a mesma
#: captura pode vir de mais de uma origem (RV12-4-02).
CHAVE_DA_QUARENTENA = (
    "source_system", "snapshot_id", "catalog_version", "treatment_fingerprint",
)

TABELA_DA_QUARENTENA = "quarantine.rejected_legacy_records"

#: A classificação da captura selecionada. A auditoria de uma captura tratada
#: é `select *` das rejeitadas daqui (`rejected_legacy_records.sql`), e por
#: isso é daqui que sai o **esperado** do acréscimo da quarentena no passo 9
#: (RVE2-01). Medido em 23/09/2026 na captura 43: 3.207 rejeitadas aqui e na
#: fatia dela na quarentena, com o mesmo digest.
TABELA_DA_CLASSIFICACAO = "trusted.legacy_classifications"
SCHEMA_DOS_SNAPSHOTS = "snapshots"
SCHEMA_DO_BRUTO = "raw_legacy"

#: A memória de exclusões (ADR-0045) é `table` reconstruída pelo dbt a partir
#: das capturas retidas — e por isso é oráculo do passo 9, não conteúdo do
#: pacote. `observed_in_snapshot_id` é a captura **selecionada** no momento do
#: build: muda de propósito quando a captura nova entra, e fica fora do digest.
TABELA_DAS_EXCLUSOES = "trusted.legacy_removed_records"
COLUNAS_VOLATEIS_DAS_EXCLUSOES = ("observed_in_snapshot_id",)

#: Os dois caminhos do livro de estoque (ADR-0031): a carga completa do
#: Airbyte e os deltas do CDC. As 16 colunas de negócio são as do contrato do
#: evento (`streaming/sink.py`, `COLUNAS_DO_EVENTO`); `metadata` é texto nos
#: dois e se compara como `jsonb`, porque a forma textual de um JSON igual pode
#: diferir entre quem o escreveu.
CAMINHO_LOTE = "raw.inventory_movements"
CAMINHO_FLUXO = "raw.inventory_movements_stream"

#: O livro na origem, pela chave com que `contagens(origem, ["oltp"])` o
#: devolve. É o tamanho que os dois caminhos precisam ter até o corte: sem ele,
#: dois caminhos vazios são "iguais" e o passo 9 aceitava o livro que não voltou.
LIVRO_NA_ORIGEM = "oltp.inventory_movements"

#: Onde o gerador da origem principal registra os parâmetros efetivos da
#: última carga (`make seed-data`). O do legado registra os seus em
#: `data/legacy/manifesto.json` (`lote.parametros`).
REGISTRO_DA_GERACAO = "data/source/geracao.json"
MANIFESTO_DO_LEGADO = "data/legacy/manifesto.json"

#: Lido em fatias: a quarentena tem 63.802 linhas, e trazer tudo de uma vez
#: para a memória seria desnecessário.
FATIA = 5000


def _somente_leitura(engine: Engine):
    conexao = engine.connect().execution_options(isolation_level="REPEATABLE READ")
    conexao.execute(sa.text("set transaction read only"))
    return conexao


def _linhas(conexao, sql: str, parametros: dict | None = None) -> Iterator[dict[str, Any]]:
    # As opções vão na **instrução**, não na conexão: `Connection.execution_options`
    # altera a conexão em definitivo, e um `update` executado depois na mesma
    # transação saía embrulhado em `DECLARE … CURSOR FOR update` — medido em
    # 21/09/2026, no re-base aplicado a um banco isolado.
    resultado = conexao.execute(
        sa.text(sql).execution_options(stream_results=True, yield_per=FATIA), parametros or {}
    )
    for linha in resultado.mappings():
        yield dict(linha)


def tabelas_do_schema(conexao, schema: str) -> list[str]:
    return [
        nome
        for (nome,) in conexao.execute(
            sa.text(
                "select table_name from information_schema.tables "
                "where table_schema = :s and table_type = 'BASE TABLE' order by 1"
            ),
            {"s": schema},
        )
    ]


def contagens(engine: Engine, schemas: list[str]) -> dict[str, int]:
    """Linhas por `schema.tabela`, num instante só."""
    with _somente_leitura(engine) as conexao:
        resultado: dict[str, int] = {}
        for schema in schemas:
            for tabela in tabelas_do_schema(conexao, schema):
                relacao = f"{schema}.{tabela}"
                resultado[relacao] = int(
                    conexao.execute(sa.text(f'select count(*) from {schema}."{tabela}"')).scalar_one()
                )
        return resultado


def tamanhos(engine: Engine, schemas: list[str]) -> dict[str, int]:
    """Bytes por `schema.tabela` (`pg_total_relation_size`), medidos, não inferidos."""
    with _somente_leitura(engine) as conexao:
        resultado: dict[str, int] = {}
        for schema in schemas:
            for tabela in tabelas_do_schema(conexao, schema):
                resultado[f"{schema}.{tabela}"] = int(
                    conexao.execute(
                        sa.text("select pg_total_relation_size(:relacao)"),
                        {"relacao": f'{schema}."{tabela}"'},
                    ).scalar_one()
                )
        return resultado


def oraculo_scd(engine: Engine) -> dict[str, dict[str, Any]]:
    """Por *snapshot*: linhas, `dbt_scd_id` distintos e o digest canônico.

    O digest cobre **todas as colunas** de cada versão — era a ausência disso
    que fazia o oráculo da revisão 4 devolver o mesmo hash para conteúdos
    diferentes (RV12-3-05).
    """
    with _somente_leitura(engine) as conexao:
        resultado: dict[str, dict[str, Any]] = {}
        for tabela in tabelas_do_schema(conexao, SCHEMA_DOS_SNAPSHOTS):
            linhas = list(
                _linhas(conexao, f'select * from {SCHEMA_DOS_SNAPSHOTS}."{tabela}"')
            )
            resultado[tabela] = {
                "linhas": len(linhas),
                "versoes": len({linha.get("dbt_scd_id") for linha in linhas}),
                "digest": oraculos.digest(linhas),
            }
        return resultado


def snapshot_da_fatia(chave: str) -> int | None:
    """O `snapshot_id` de uma fatia da quarentena, lido da chave do manifesto."""
    import json

    valor = json.loads(chave)[CHAVE_DA_QUARENTENA.index("snapshot_id")]
    return None if valor is None else int(valor)


def oraculo_da_quarentena(engine: Engine) -> dict[str, dict[str, Any]]:
    """Por `(origem, captura, versão, impressão)`: contagem **e** digest.

    É oráculo de **continência**: uma captura nova acrescenta uma fatia, e o
    total não volta igual — nem deve.
    """
    with _somente_leitura(engine) as conexao:
        linhas = _linhas(conexao, f"select * from {TABELA_DA_QUARENTENA}")
        return oraculos.por_chave(linhas, CHAVE_DA_QUARENTENA)


def classificacao_corrente(engine: Engine) -> dict[str, Any] | None:
    """O que a classificação corrente afirma: as fatias que ela trata e as que ela rejeita.

    `tratadas` são as chaves `(origem, captura, versão, impressão)` presentes —
    com ou sem rejeição —, e `rejeitadas` o oráculo por chave das linhas
    `rejected`, na mesma forma do da quarentena. Uma captura tratada sem
    rejeição nenhuma é **legítima** e tem acréscimo vazio; é o que distingue
    "não havia o que auditar" de "a auditoria não entrou". `None` quando a
    tabela não existe — armazém que ainda não teve `dbt build`.
    """
    schema, tabela = TABELA_DA_CLASSIFICACAO.split(".")
    with _somente_leitura(engine) as conexao:
        if tabela not in tabelas_do_schema(conexao, schema):
            return None
        tratadas = sorted(
            oraculos.nome_da_fatia(linha, CHAVE_DA_QUARENTENA)
            for linha in _linhas(
                conexao, f"select distinct {', '.join(CHAVE_DA_QUARENTENA)} from {TABELA_DA_CLASSIFICACAO}"
            )
        )
        rejeitadas = oraculos.por_chave(
            _linhas(conexao, f"select * from {TABELA_DA_CLASSIFICACAO} where classification = 'rejected'"),
            CHAVE_DA_QUARENTENA,
        )
    return {"tratadas": tratadas, "rejeitadas": rejeitadas}


def oraculo_das_capturas(engine: Engine) -> dict[str, Any]:
    """O que identifica as capturas retidas — e a geração de cada tabela (D52).

    A geração vai por tabela porque é por tabela que `medir_recebido` conta
    intrusas. `nulas` entra no oráculo porque "nenhuma positiva" não basta: um
    nulo atravessa essa conferência e deixa a linha fora de faixa nenhuma.
    """
    from mvp_ed1.legacy import captura

    with _somente_leitura(engine) as conexao:
        geracoes: dict[str, dict[str, Any]] = {}
        for tabela in tabelas_do_schema(conexao, SCHEMA_DO_BRUTO):
            linha = (
                conexao.execute(
                    sa.text(
                        "select min(_airbyte_generation_id) as minima, "
                        "max(_airbyte_generation_id) as maxima, "
                        "count(distinct _airbyte_generation_id) as classes, "
                        "count(*) filter (where _airbyte_generation_id is null) as nulas "
                        f'from {SCHEMA_DO_BRUTO}."{tabela}"'
                    )
                )
                .mappings()
                .one()
            )
            geracoes[tabela] = dict(linha)

    certificadas = captura.certificadas(engine)
    return {
        "certificadas": certificadas,
        "maior_snapshot": max(certificadas) if certificadas else None,
        "geracoes_por_tabela": geracoes,
    }


def chaves_e_geracoes(conexao, tabela: str, apenas_retidas: bool = False) -> Iterator[tuple[str, int | None]]:
    """`(_airbyte_raw_id, _airbyte_generation_id)` de uma tabela do bruto, em fatias.

    `apenas_retidas` restringe à faixa negativa — o que voltou do pacote e foi
    re-baseado —, para que a assinatura continue comparável depois de a carga
    nova ter escrito nas gerações não negativas.
    """
    filtro = " where _airbyte_generation_id < 0" if apenas_retidas else ""
    for linha in _linhas(
        conexao,
        f'select _airbyte_raw_id as chave, _airbyte_generation_id as geracao '
        f'from {SCHEMA_DO_BRUTO}."{tabela}"{filtro}',
    ):
        yield linha["chave"], (None if linha["geracao"] is None else int(linha["geracao"]))


def oraculo_da_particao(engine: Engine, apenas_retidas: bool = False) -> dict[str, dict[str, Any]]:
    """Por tabela do bruto: a assinatura da partição das linhas por geração.

    É o oráculo do passo 4b guardado no manifesto (RVE-04): invariante ao
    re-base, e restrita às retidas quando a carga nova já entrou.
    """
    with _somente_leitura(engine) as conexao:
        return {
            tabela: rebase.assinatura(chaves_e_geracoes(conexao, tabela, apenas_retidas))
            for tabela in tabelas_do_schema(conexao, SCHEMA_DO_BRUTO)
        }


def oraculo_das_exclusoes(engine: Engine) -> dict[str, Any] | None:
    """A memória de exclusões, sem a coluna que muda com a captura selecionada.

    `None` quando a tabela não existe — armazém que ainda não teve `dbt build`
    —, e o manifesto diz isso em vez de gravar um digest do vazio.
    """
    schema, tabela = TABELA_DAS_EXCLUSOES.split(".")
    with _somente_leitura(engine) as conexao:
        if tabela not in tabelas_do_schema(conexao, schema):
            return None
        linhas = [
            {c: v for c, v in linha.items() if c not in COLUNAS_VOLATEIS_DAS_EXCLUSOES}
            for linha in _linhas(conexao, f"select * from {TABELA_DAS_EXCLUSOES}")
        ]
        return {"linhas": len(linhas), "digest": oraculos.digest(linhas)}


def comparar_caminhos(engine: Engine, corte: int) -> dict[str, Any]:
    """Os dois caminhos do livro até o corte: os quatro zeros e as duas somas.

    O que se compara é o **payload** — chave e as 16 colunas de negócio — e o
    saldo por armazém/SKU, não flags de chegada; é a comparação da Execução
    Local §3.2 que prova o livro restaurado (passo 9).
    """
    colunas = (
        "movement_id", "event_sequence", "idempotency_key", "warehouse_id",
        "product_variant_id", "movement_type", "quantity_delta", "unit_cost",
        "source_type", "source_id", "correlation_id", "causation_id",
        "aggregate_version", "occurred_at", "recorded_at", "schema_version",
    )
    lista = ", ".join(colunas)
    tupla_l = ", ".join(f"l.{c}" for c in colunas)
    tupla_f = ", ".join(f"f.{c}" for c in colunas)
    sql = f"""
        with lote as (
            select {lista}, metadata::jsonb as metadata from {CAMINHO_LOTE}
            where event_sequence <= :corte
        ), fluxo as (
            select {lista}, metadata::jsonb as metadata from {CAMINHO_FLUXO}
            where event_sequence <= :corte
        ), juntos as (
            select l.movement_id as lote_id, f.movement_id as fluxo_id,
                   (({tupla_l}, l.metadata) is distinct from ({tupla_f}, f.metadata)) as diferentes
            from lote l full outer join fluxo f on l.movement_id = f.movement_id
        ), saldos as (
            select coalesce(l.warehouse_id, f.warehouse_id) as warehouse_id,
                   coalesce(l.product_variant_id, f.product_variant_id) as product_variant_id,
                   coalesce(l.saldo, 0) as saldo_lote, coalesce(f.saldo, 0) as saldo_fluxo
            from (select warehouse_id, product_variant_id, sum(quantity_delta) as saldo
                  from lote group by 1, 2) l
            full outer join (select warehouse_id, product_variant_id, sum(quantity_delta) as saldo
                  from fluxo group by 1, 2) f
              on l.warehouse_id = f.warehouse_id and l.product_variant_id = f.product_variant_id
        )
        select
            (select count(*) from juntos where fluxo_id is null) as so_no_lote,
            (select count(*) from juntos where lote_id is null) as so_no_fluxo,
            (select count(*) from juntos where lote_id is not null and fluxo_id is not null and diferentes) as payloads_diferentes,
            (select count(*) from saldos where saldo_lote <> saldo_fluxo) as saldos_diferentes,
            (select coalesce(sum(quantity_delta), 0) from lote) as soma_lote,
            (select coalesce(sum(quantity_delta), 0) from fluxo) as soma_fluxo,
            (select count(*) from lote) as linhas_lote,
            (select count(*) from fluxo) as linhas_fluxo
    """
    with _somente_leitura(engine) as conexao:
        linha = conexao.execute(sa.text(sql), {"corte": corte}).mappings().one()
    return {"corte": corte, **{k: int(v) for k, v in linha.items()}}


def capturas_certificadas_desde(engine: Engine, corte: str) -> list[int]:
    """`snapshot_id` certificados cuja captura começou depois do corte do pacote.

    É a identidade que o Airbyte devolveu de fato — `job_id` gravado por
    `registrar_job` ao nascer o job —, e não um número escrito num plano.
    """
    from mvp_ed1.legacy import captura

    with _somente_leitura(engine) as conexao:
        depois = {
            int(g)
            for (g,) in conexao.execute(
                sa.text(
                    f"select snapshot_id from {captura.TABELA} "
                    "where snapshot_id is not null group by snapshot_id "
                    "having min(started_at) >= cast(:corte as timestamptz)"
                ),
                {"corte": corte},
            )
        }
    return sorted(depois & set(captura.certificadas(engine)))


def geracao_registrada(raiz) -> dict[str, Any]:
    """Os parâmetros efetivos de geração das duas origens — os registrados, e só eles.

    Sem registro, o valor é `None` **com o motivo**: um manifesto que gravasse
    o padrão do YAML afirmaria uma semente que ninguém mediu (RVE-15).
    """
    import json
    import pathlib

    resultado: dict[str, Any] = {}
    origem = pathlib.Path(raiz) / REGISTRO_DA_GERACAO
    if origem.exists():
        resultado["source_db"] = json.loads(origem.read_text(encoding="utf-8"))
    else:
        resultado["source_db"] = None
        resultado["source_db_motivo"] = (
            f"{REGISTRO_DA_GERACAO} não existe — a origem foi carregada antes de o gerador "
            "registrar os parâmetros efetivos, ou por outro caminho; nada foi inferido"
        )
    legado = pathlib.Path(raiz) / MANIFESTO_DO_LEGADO
    if legado.exists():
        lote = json.loads(legado.read_text(encoding="utf-8")).get("lote", {})
        resultado["legacy_db"] = {"parametros": lote.get("parametros"), "hash": lote.get("hash")}
    else:
        resultado["legacy_db"] = None
        resultado["legacy_db_motivo"] = f"{MANIFESTO_DO_LEGADO} não existe; nada foi inferido"
    return resultado


def geracoes_da_tabela(engine: Engine, tabela: str) -> list[int | None]:
    """As gerações distintas de uma tabela do bruto, para montar o re-base."""
    with engine.connect() as conexao:
        return [
            g
            for (g,) in conexao.execute(
                sa.text(
                    f'select distinct _airbyte_generation_id from {SCHEMA_DO_BRUTO}."{tabela}" '
                    "order by 1"
                )
            )
        ]


def versoes_do_armazem(engine: Engine) -> list[str]:
    from mvp_ed1 import governance

    return governance.versoes(engine)


def maior_event_sequence(engine: Engine) -> int:
    from mvp_ed1.models.base import SCHEMA

    with engine.connect() as conexao:
        return int(
            conexao.execute(
                sa.text(f"select coalesce(max(event_sequence), 0) from {SCHEMA}.inventory_movements")
            ).scalar_one()
        )


def alembic_current(raiz, secao: str | None = None) -> str:
    """`alembic current` de uma das fontes — o oráculo de versão delas.

    O armazém não tem Alembic e não terá: o oráculo dele é
    `governance._versions` (ADR-0044).
    """
    comando = [".venv/bin/alembic"]
    if secao:
        comando += ["-n", secao]
    comando.append("current")
    saida = subprocess.run(comando, cwd=raiz, capture_output=True, text=True)
    return saida.stdout.strip() or saida.stderr.strip()
