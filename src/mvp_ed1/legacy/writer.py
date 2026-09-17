"""Carga do legado por `COPY`, num schema que a migração Alembic criou.

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

import datetime as dt
import io
import json
import pathlib
import time
from dataclasses import asdict
from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.legacy import conteudo, oraculo, schema
from mvp_ed1.legacy.catalogo import Catalogo
from mvp_ed1.legacy.injetor import Resultado


class DestinoNaoVazio(Exception):
    """Há dados no legado e a carga não foi autorizada a apagá-los."""


class SchemaNaoMigrado(Exception):
    """O schema legado não está na cabeça das migrações; a carga não cria DDL."""


def exigir_migracao(engine: Engine) -> str:
    """O schema legado nasce da migração Alembic, nunca daqui.

    Até 14/09/2026 esta função **criava** as tabelas por `schema.ddl()`, e o
    schema ficava fora do ciclo de evolução e reversão (achado R12). Agora ela só
    confere: a revisão aplicada no banco tem de ser a cabeça de
    `db/migrations_legacy/`. Se não for, a mensagem diz o alvo do Makefile, e a
    carga não acontece — DDL por caminho paralelo é exatamente o que se quer
    impossibilitar.
    """
    from alembic.config import Config
    from alembic.runtime.migration import MigrationContext
    from alembic.script import ScriptDirectory

    cabeca = ScriptDirectory.from_config(Config("alembic.ini", ini_section="legacy")).get_current_head()
    with engine.connect() as conexao:
        aplicada = MigrationContext.configure(conexao).get_current_revision()
    if aplicada != cabeca:
        raise SchemaNaoMigrado(
            f"legacy_db está na revisão {aplicada or 'nenhuma'} e a cabeça é {cabeca}; "
            "rode `make migrate-legacy` antes de carregar"
        )
    return cabeca


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


def exigir_destino(engine: Engine, *, forcar: bool = False) -> dict[str, int]:
    """O destino está migrado e vazio — ou a carga foi autorizada a esvaziá-lo.

    Separado de `escrever` para que a CLI possa conferir o destino **antes** de
    gravar o manifesto, e gravar o manifesto **antes** de carregar: o esperado
    durável nasce primeiro, e uma carga recusada não deixa manifesto órfão
    (RV10-07). Devolve as contagens das tabelas ocupadas.
    """
    exigir_migracao(engine)
    ocupadas = {n: c for n, c in contagens(engine).items() if c}
    if ocupadas and not forcar:
        raise DestinoNaoVazio(
            f"{len(ocupadas)} tabelas do legado já contêm dados "
            f"({sum(ocupadas.values()):,} linhas). Use FORCE=1 para truncar antes."
        )
    return ocupadas


def escrever(engine: Engine, resultado: Resultado, *, forcar: bool = False) -> dict[str, Any]:
    """Carrega o conjunto degradado num schema já migrado."""
    if exigir_destino(engine, forcar=forcar):
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

    # O que ficou no banco é o que foi gerado? A pergunta é respondida pelo
    # mesmo hash de conteúdo que o manifesto grava: é o primeiro elo da cadeia
    # manifesto ↔ origem ↔ captura, e um `COPY` que escapou errado uma célula
    # apareceria aqui, não numa divergência de veredito três camadas adiante.
    esperado = conteudo.hash_do_lote(resultado.linhas)
    with engine.connect() as conexao:
        divergentes = [
            tabela
            for tabela in schema.tabelas()
            if conteudo.hash_no_banco(conexao, schema.SCHEMA, tabela) != esperado[tabela]
        ]
    if divergentes:
        raise RuntimeError(
            "o conteúdo carregado difere do gerado em "
            + ", ".join(divergentes)
            + "; o manifesto gravado antes da carga não descreve o que está no banco"
        )

    return {
        "tabelas": escritas,
        "linhas": sum(escritas.values()),
        "segundos": round(time.perf_counter() - marca, 2),
        "hash_conferido": True,
    }


def _limpo(valor: str) -> str:
    """`COPY` em texto: tabulação e quebra de linha precisam ser escapadas.

    O valor **não** é normalizado além disso: espaço à volta, caixa trocada e
    delimitador interno são defeitos declarados no catálogo, e limpá-los aqui
    apagaria o que a etapa existe para tratar.
    """
    return valor.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n")


def manifesto(catalogo: Catalogo, resultado: Resultado, parametros: dict[str, Any]) -> dict[str, Any]:
    """O oráculo do lote, em memória: identidade de conteúdo, achados, vereditos, diário.

    * `lote` identifica **o conteúdo** — hash por tabela e global — e os
      parâmetros efetivos da geração. Contagem e conjunto de `legacy_row_id`
      não bastam: recomeçam em 1 a cada geração e se repetem com conteúdo
      diferente. É pelo hash que uma captura é reconhecida como este lote;
    * `achados` é o que o injetor fez, célula a célula, com o valor esperado
      depois da limpeza pelo contrato `recuperacao`;
    * `veredito` é o esperado por ocorrência — todas as 12 mil, não só as
      atingidas —, recomputado por `oraculo` sobre as linhas finais;
    * `mutacoes` é o diário das alterações feitas **depois** da carga
      (remoção, inserção, alteração), vazio ao nascer; quem muda a origem
      escreve aqui o que o banco devolveu;
    * `mutacoes_encerradas` guarda os diários das cargas anteriores do mesmo
      lote, fechados quando a origem foi recarregada (D44): descrevem capturas
      que o bruto retém, e por isso não se apagam — mas não descrevem mais a
      origem.
    """
    vereditos = oraculo.esperar(catalogo, resultado)
    divergencias = oraculo.conferir_com_o_injetor(resultado, vereditos)
    if divergencias:
        raise RuntimeError("oráculo inconsistente com o injetor: " + "; ".join(divergencias[:5]))
    por_tabela = conteudo.hash_do_lote(resultado.linhas)
    return {
        "lote": {
            "hash": conteudo.hash_global(por_tabela),
            "parametros": {**parametros, "versao_catalogo": catalogo.versao},
            "tabelas": por_tabela,
        },
        "achados": [asdict(a) for a in resultado.achados],
        "veredito": oraculo.serializar(vereditos),
        "mutacoes": [],
        "mutacoes_encerradas": [],
    }


def gravar_manifesto(
    catalogo: Catalogo, resultado: Resultado, parametros: dict[str, Any], diretorio: pathlib.Path,
    *, carga: bool,
) -> pathlib.Path:
    """Escreve `manifesto-<hash>.json` e aponta `manifesto.json` para ele.

    Nenhum manifesto é apagado: regerar a origem produz outro arquivo, e o
    anterior continua descrevendo a captura que já está retida em `raw_legacy`.
    O nome corrente é um *link* simbólico, para que quem só quer "o último" não
    precise saber o hash.

    O diário de mutações do mesmo lote é história que aconteceu no banco e não
    se recalcula. O que decide o destino dele é `carga`: só o manifesto
    recomputado (`carga=False`) o mantém aberto; uma **carga** do lote
    (`carga=True`) o encerra — depois de truncar e recarregar, as linhas que o
    diário diz removidas estão de volta, e um diário que não descreve a origem
    é falso positivo à espera do teste do ciclo real (D44).
    """
    diretorio.mkdir(parents=True, exist_ok=True)
    oraculo_do_lote = manifesto(catalogo, resultado, parametros)
    destino = diretorio / f"manifesto-{oraculo_do_lote['lote']['hash']}.json"
    if destino.exists():
        anterior = json.loads(destino.read_text(encoding="utf-8"))
        abertas, encerradas = anterior.get("mutacoes", []), anterior.get("mutacoes_encerradas", [])
        if carga and abertas:
            encerradas = [*encerradas, {
                "encerrado_em": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
                "motivo": "recarga do lote",
                "mutacoes": abertas,
            }]
            abertas = []
        oraculo_do_lote["mutacoes"], oraculo_do_lote["mutacoes_encerradas"] = abertas, encerradas
    destino.write_text(json.dumps(oraculo_do_lote, ensure_ascii=False, indent=1), encoding="utf-8")
    corrente = diretorio / "manifesto.json"
    if corrente.is_symlink() or corrente.exists():
        corrente.unlink()
    corrente.symlink_to(destino.name)
    return destino
