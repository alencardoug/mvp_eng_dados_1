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

from mvp_ed1.recovery import oraculos

#: A chave das fatias da quarentena. `source_system` entra porque a mesma
#: captura pode vir de mais de uma origem (RV12-4-02).
CHAVE_DA_QUARENTENA = (
    "source_system", "snapshot_id", "catalog_version", "treatment_fingerprint",
)

TABELA_DA_QUARENTENA = "quarantine.rejected_legacy_records"
SCHEMA_DOS_SNAPSHOTS = "snapshots"
SCHEMA_DO_BRUTO = "raw_legacy"

#: Lido em fatias: a quarentena tem 63.802 linhas, e trazer tudo de uma vez
#: para a memória seria desnecessário.
FATIA = 5000


def _somente_leitura(engine: Engine):
    conexao = engine.connect().execution_options(isolation_level="REPEATABLE READ")
    conexao.execute(sa.text("set transaction read only"))
    return conexao


def _linhas(conexao, sql: str, parametros: dict | None = None) -> Iterator[dict[str, Any]]:
    resultado = conexao.execution_options(stream_results=True, yield_per=FATIA).execute(
        sa.text(sql), parametros or {}
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


def oraculo_da_quarentena(engine: Engine) -> dict[str, dict[str, Any]]:
    """Por `(origem, captura, versão, impressão)`: contagem **e** digest.

    É oráculo de **continência**: uma captura nova acrescenta uma fatia, e o
    total não volta igual — nem deve.
    """
    with _somente_leitura(engine) as conexao:
        linhas = _linhas(conexao, f"select * from {TABELA_DA_QUARENTENA}")
        return oraculos.por_chave(linhas, CHAVE_DA_QUARENTENA)


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
