"""Relatório de tamanho — observação, não limite.

O orçamento de 4 GB foi aposentado (ADR-0014): tamanho deixou de ser restrição
e passou a ser medição. Ela continua por dois motivos declarados em Capacidade
e Recuperação §2 — o princípio **P5**, que separa planejado de medido, e a
calibração do fator `cloud` na Etapa 13, que precisa de números reais.
"""

from __future__ import annotations

from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.models import SCHEMA

_POR_TABELA = text(
    """
    select
        c.relname                                   as tabela,
        coalesce(s.n_live_tup, 0)                   as linhas,
        pg_total_relation_size(c.oid)               as total_bytes,
        pg_indexes_size(c.oid)                      as indices_bytes,
        pg_total_relation_size(c.oid)
            - pg_indexes_size(c.oid)                as dados_bytes
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    left join pg_stat_user_tables s on s.relid = c.oid
    where n.nspname = :schema and c.relkind = 'r'
    order by pg_total_relation_size(c.oid) desc
    """
)


def por_tabela(engine: Engine, schema: str = SCHEMA) -> list[dict[str, Any]]:
    """Tamanho e contagem por tabela.

    `analyze` antes da leitura: `n_live_tup` é estimativa do coletor de
    estatísticas, e logo depois de uma carga por `COPY` ela ainda está zerada —
    o relatório mostraria um banco cheio com zero linhas.
    """
    with engine.begin() as conexao:
        conexao.execute(text("analyze"))
        linhas = conexao.execute(_POR_TABELA, {"schema": schema}).mappings().all()
    return [dict(linha) for linha in linhas]


def tamanho_do_banco(engine: Engine) -> int:
    with engine.connect() as conexao:
        return conexao.execute(text("select pg_database_size(current_database())")).scalar_one()


def formatar(bytes_: float) -> str:
    for unidade in ("B", "kB", "MB", "GB"):
        if abs(bytes_) < 1000 or unidade == "GB":
            return f"{bytes_:.1f} {unidade}"
        bytes_ /= 1024
    return f"{bytes_:.1f} GB"
