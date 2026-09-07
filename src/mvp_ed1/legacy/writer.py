"""Criação do schema legado e carga por `COPY`.

Mesma fronteira do ADR-0009 que a origem principal usa: o ORM é o caminho
normal, a carga em massa passa por `COPY` na conexão bruta. A diferença é que
aqui **não há o que validar** — o banco legado não tem `CHECK`, chave
estrangeira nem tipo que recuse valor. Essa é a razão de ele existir, e também a
razão de a carga não provar nada sobre a qualidade do que entrou.

O manifesto **não** vai para o banco. Ele é o oráculo dos testes, e guardá-lo ao
lado do dado tratado convidaria a transformação a consultá-lo — que é
exatamente o que a Origem Legada §3.2 proíbe. Ele é escrito em arquivo, fora do
alcance das credenciais de leitura da transformação.
"""

from __future__ import annotations

import io
import json
import pathlib
import time
from dataclasses import asdict
from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.legacy import schema
from mvp_ed1.legacy.injetor import Resultado


class DestinoNaoVazio(Exception):
    """Há dados no legado e a carga não foi autorizada a apagá-los."""


def criar_schema(engine: Engine) -> None:
    with engine.begin() as conexao:
        for comando in schema.ddl():
            conexao.execute(text(comando))


def contagens(engine: Engine) -> dict[str, int]:
    with engine.connect() as conexao:
        existentes = {
            linha[0]
            for linha in conexao.execute(
                text(
                    "select table_name from information_schema.tables "
                    "where table_schema = :s"
                ),
                {"s": schema.SCHEMA},
            )
        }
        return {
            nome: conexao.execute(
                text(f'select count(*) from {schema.SCHEMA}."{nome}"')
            ).scalar_one()
            for nome in schema.tabelas()
            if nome in existentes
        }


def truncar(engine: Engine) -> None:
    alvos = ", ".join(f'{schema.SCHEMA}."{n}"' for n in schema.tabelas())
    with engine.begin() as conexao:
        conexao.execute(text(f"truncate table {alvos} restart identity"))


def escrever(engine: Engine, resultado: Resultado, *, forcar: bool = False) -> dict[str, Any]:
    """Cria o schema se preciso e carrega o conjunto degradado."""
    criar_schema(engine)
    ocupadas = {n: c for n, c in contagens(engine).items() if c}
    if ocupadas and not forcar:
        raise DestinoNaoVazio(
            f"{len(ocupadas)} tabelas do legado já contêm dados "
            f"({sum(ocupadas.values()):,} linhas). Use FORCE=1 para truncar antes."
        )
    if ocupadas:
        truncar(engine)

    marca = time.perf_counter()
    escritas: dict[str, int] = {}
    conexao_bruta = engine.raw_connection()
    try:
        cursor = conexao_bruta.cursor()
        for tabela in schema.tabelas():
            linhas = resultado.linhas.get(tabela, [])
            if not linhas:
                escritas[tabela] = 0
                continue
            colunas = schema.colunas(tabela)
            buffer = io.StringIO()
            # `COPY ... from stdin` no formato texto **não** é CSV: não há
            # aspas, e quem cita um valor entrega as aspas junto com ele. O
            # escape que este formato entende é o de `_limpo`, e é só ele.
            for linha in linhas:
                buffer.write(
                    "\t".join(
                        "\\N" if linha.get(c) is None else _limpo(linha[c]) for c in colunas
                    )
                    + "\n"
                )
            buffer.seek(0)
            alvo = ", ".join(f'"{c}"' for c in colunas)
            with cursor.copy(
                f'copy {schema.SCHEMA}."{tabela}" ({alvo}) from stdin'
            ) as copia:
                copia.write(buffer.getvalue())
            escritas[tabela] = len(linhas)
        conexao_bruta.commit()
    finally:
        conexao_bruta.close()

    return {
        "tabelas": escritas,
        "linhas": sum(escritas.values()),
        "segundos": round(time.perf_counter() - marca, 2),
    }


def _limpo(valor: str) -> str:
    """`COPY` em texto: tabulação e quebra de linha precisam ser escapadas.

    O valor **não** é normalizado além disso: espaço à volta, caixa trocada e
    delimitador interno são defeitos declarados no catálogo, e limpá-los aqui
    apagaria o que a etapa existe para tratar.
    """
    return valor.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n")


def gravar_manifesto(resultado: Resultado, destino: pathlib.Path) -> pathlib.Path:
    """Escreve o oráculo em JSON, fora do banco e fora do alcance da transformação."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    veredito = resultado.resultado_por_ocorrencia()
    conteudo = {
        "achados": [asdict(a) for a in resultado.achados],
        "ocorrencias": [
            {"tabela": t, "legacy_row_id": i, "resultado_esperado": r}
            for (t, i), r in sorted(veredito.items())
        ],
    }
    destino.write_text(json.dumps(conteudo, ensure_ascii=False, indent=2), encoding="utf-8")
    return destino
