"""Carga no `source_db` por `COPY`.

O ADR-0009 declarou a fronteira: o *unit of work* do SQLAlchemy é o caminho
normal, e a carga em massa passa por `COPY` na conexão bruta. Um quarto de
milhão de linhas objeto a objeto é ordens de grandeza mais lento e não é o uso
pretendido do ORM.

Duas consequências de escrever `id` explícito, e as duas são tratadas aqui:

* a sequência de identidade fica para trás, porque `COPY` não a consome. Sem
  `setval`, o primeiro `INSERT` que alguém fizer depois colide com a linha 1;
* colunas `GENERATED ALWAYS` — `event_sequence` e `quantity_available` — não
  entram no `COPY`. Quem as preenche é o banco, e tentar escrevê-las é erro.

O banco é o teste. Toda `CHECK`, toda unicidade e toda chave estrangeira do
modelo é verificada aqui, na carga — não por um teste que roda depois e opina
sobre dados que já entraram.
"""

from __future__ import annotations

import time
from typing import Any, Iterable

from psycopg.types.json import Jsonb
from sqlalchemy import Engine, text

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.models import SCHEMA, Base

#: Ordem de dependência referencial, resolvida pelo mapeamento (ADR-0009).
ORDEM = tuple(t.name for t in Base.metadata.sorted_tables)


class DestinoNaoVazio(Exception):
    """Há dados no destino e a carga não foi autorizada a apagá-los."""


def contagens(engine: Engine) -> dict[str, int]:
    with engine.connect() as conexao:
        return {
            nome: conexao.execute(text(f'select count(*) from {SCHEMA}."{nome}"')).scalar_one()
            for nome in ORDEM
        }


def truncar(engine: Engine) -> None:
    """Esvazia as 40 tabelas de uma vez, reiniciando as identidades.

    Em um só comando por causa das chaves estrangeiras: truncar tabela a tabela
    exigiria ordem inversa e ainda assim esbarraria em `RESTRICT`.
    """
    alvos = ", ".join(f'{SCHEMA}."{nome}"' for nome in ORDEM)
    with engine.begin() as conexao:
        conexao.execute(text(f"truncate table {alvos} restart identity cascade"))


def escrever(engine: Engine, dados: Dataset, *, forcar: bool = False) -> dict[str, Any]:
    """Carrega o conjunto gerado. Recusa destino com dados, salvo `forcar`."""
    ocupadas = {nome: n for nome, n in contagens(engine).items() if n}
    if ocupadas and not forcar:
        raise DestinoNaoVazio(
            f"{len(ocupadas)} tabelas já contêm dados ({sum(ocupadas.values()):,} linhas). "
            "Use FORCE=1 para truncar antes de carregar."
        )
    if ocupadas:
        truncar(engine)

    marca = time.perf_counter()
    escritas: dict[str, int] = {}
    bruta = engine.raw_connection()
    try:
        with bruta.cursor() as cursor:
            for nome in ORDEM:
                colunas = Motor.colunas_gravaveis(nome)
                linhas = dados[nome] if nome in dados else []
                escritas[nome] = _copiar(cursor, nome, colunas, linhas)
            for nome in ORDEM:
                _reposicionar_sequencia(cursor, nome)
        bruta.commit()
    except Exception:
        bruta.rollback()
        raise
    finally:
        bruta.close()

    return {
        "linhas": escritas,
        "total": sum(escritas.values()),
        "segundos": time.perf_counter() - marca,
    }


def _copiar(cursor: Any, tabela: str, colunas: tuple[str, ...], linhas: Iterable[dict]) -> int:
    lista = ", ".join(f'"{coluna}"' for coluna in colunas)
    comando = f'copy {SCHEMA}."{tabela}" ({lista}) from stdin'
    escritas = 0
    with cursor.copy(comando) as copia:
        for linha in linhas:
            copia.write_row(tuple(_adaptar(linha[coluna]) for coluna in colunas))
            escritas += 1
    return escritas


def _adaptar(valor: Any) -> Any:
    """`dict` vira `jsonb`; o resto o psycopg já sabe adaptar."""
    return Jsonb(valor) if isinstance(valor, dict) else valor


def _reposicionar_sequencia(cursor: Any, tabela: str) -> None:
    """Alinha a sequência de identidade ao maior `id` carregado.

    `inventory_movements` não entra: a chave dela é `movement_id`, e o
    `event_sequence` é `GENERATED ALWAYS`, atribuído pelo banco durante o
    próprio `COPY`.
    """
    if "id" not in Base.metadata.tables[f"{SCHEMA}.{tabela}"].columns:
        return
    cursor.execute(
        f'''
        select setval(
            pg_get_serial_sequence(%s, 'id'),
            coalesce(max(id), 1),
            count(*) > 0
        )
        from {SCHEMA}."{tabela}"
        ''',
        (f"{SCHEMA}.{tabela}",),
    )
