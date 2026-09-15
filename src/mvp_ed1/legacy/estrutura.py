"""O catálogo físico do schema legado, lido do banco — para provar equivalência, não presumir.

Duas coisas dizem "como o schema `legacy` é": a migração Alembic
(`db/migrations_legacy/`) e a declaração de referência (`schema.ddl()`). Que
digam a mesma coisa não se assume: lê-se o que cada uma deixou no banco e
compara-se. É também assim que um `legacy_db` que já existia — criado pelo
`ddl()` antes de haver migração — é **adotado** pelo ciclo Alembic: só recebe
`stamp` depois de o seu catálogo físico ser igual ao de um banco isolado
migrado do zero (achado P05 da revisão do plano, 14/09/2026).

O que entra na comparação é o que muda comportamento: tabelas, colunas na
ordem, tipo, nulabilidade, identidade e padrão, e as *constraints* com nome e
colunas. O que não entra é o que não é estrutura — dono, tablespace, estatísticas.
"""

from __future__ import annotations

from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.legacy import schema


def catalogo_fisico(engine: Engine, esquema: str = schema.SCHEMA) -> dict[str, Any]:
    """Estrutura do schema como o PostgreSQL a descreve, normalizada para comparação."""
    with engine.connect() as conexao:
        colunas = conexao.execute(
            text(
                """
                select table_name, ordinal_position, column_name, data_type, is_nullable,
                       is_identity, identity_generation, column_default
                from information_schema.columns
                where table_schema = :s
                order by table_name, ordinal_position
                """
            ),
            {"s": esquema},
        ).all()
        restricoes = conexao.execute(
            text(
                """
                select tc.table_name, tc.constraint_name, tc.constraint_type,
                       coalesce(string_agg(kcu.column_name, ',' order by kcu.ordinal_position), '') as colunas
                from information_schema.table_constraints tc
                left join information_schema.key_column_usage kcu
                  on kcu.constraint_schema = tc.constraint_schema
                 and kcu.constraint_name = tc.constraint_name
                 and kcu.table_name = tc.table_name
                where tc.table_schema = :s and tc.constraint_type <> 'CHECK'
                group by tc.table_name, tc.constraint_name, tc.constraint_type
                order by tc.table_name, tc.constraint_name
                """
            ),
            {"s": esquema},
        ).all()
        indices = conexao.execute(
            text(
                "select tablename, indexname, indexdef from pg_indexes "
                "where schemaname = :s order by tablename, indexname"
            ),
            {"s": esquema},
        ).all()

    tabelas: dict[str, dict[str, Any]] = {}
    for nome, posicao, coluna, tipo, nulavel, identidade, geracao, padrao in colunas:
        tabelas.setdefault(nome, {"colunas": [], "restricoes": [], "indices": []})["colunas"].append(
            {
                "posicao": posicao,
                "nome": coluna,
                "tipo": tipo,
                "nulavel": nulavel,
                "identidade": identidade,
                "geracao": geracao,
                "padrao": padrao,
            }
        )
    for nome, restricao, tipo, cols in restricoes:
        tabelas.setdefault(nome, {"colunas": [], "restricoes": [], "indices": []})["restricoes"].append(
            {"nome": restricao, "tipo": tipo, "colunas": cols}
        )
    for nome, indice, definicao in indices:
        # A definição cita o schema e o nome do banco não; normaliza-se só o
        # que varia entre bancos idênticos — nada.
        tabelas.setdefault(nome, {"colunas": [], "restricoes": [], "indices": []})["indices"].append(
            {"nome": indice, "definicao": definicao}
        )
    return {"schema": esquema, "tabelas": tabelas}


def diferencas(a: dict[str, Any], b: dict[str, Any]) -> list[str]:
    """Descrição legível de cada diferença entre dois catálogos físicos; vazia se iguais."""
    saida: list[str] = []
    ta, tb = a["tabelas"], b["tabelas"]
    for nome in sorted(set(ta) ^ set(tb)):
        saida.append(f"tabela {nome} só existe em {'a' if nome in ta else 'b'}")
    for nome in sorted(set(ta) & set(tb)):
        for parte in ("colunas", "restricoes", "indices"):
            if ta[nome][parte] != tb[nome][parte]:
                saida.append(f"{nome}.{parte}: {ta[nome][parte]} != {tb[nome][parte]}")
    return saida
