"""Mutações na origem legada **depois** da carga — com diário do que o banco devolveu.

Provar a detecção de exclusão física (ADR-0045) exige apagar, inserir e alterar
linhas em `legacy_db` entre duas capturas. Quem faz isso precisa deixar um
esperado **independente** da transformação: não "o que pretendia apagar", mas
o que o `DELETE … RETURNING` devolveu, confirmado depois do `commit`, e o hash
de conteúdo da tabela antes e depois — é isso que o diário `mutacoes` do
manifesto guarda, e é dele que os testes de integração tiram o que esperar de
`legacy_capture_transitions` e `legacy_removed_records`.

A escolha das chaves a remover é do oráculo quando não é explícita: entre as
ocorrências **aptas** da tabela no manifesto, as primeiras N em ordem física.
Remover uma rejeitada não provaria nada — ela já não estava no datamart.
"""

from __future__ import annotations

import datetime as dt
import json
import pathlib
from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.legacy import conteudo, remocao, schema

MANIFESTO = pathlib.Path("data/legacy/manifesto.json")


def _ler(caminho: pathlib.Path) -> tuple[pathlib.Path, dict[str, Any]]:
    alvo = caminho.resolve()
    if not alvo.exists():
        raise FileNotFoundError(f"sem manifesto em {caminho}; rode `make seed-legacy`")
    manifesto = json.loads(alvo.read_text(encoding="utf-8"))
    if "mutacoes" not in manifesto:
        raise ValueError("manifesto em formato anterior a 14/09/2026, sem diário; regere-o")
    return alvo, manifesto


def _gravar(alvo: pathlib.Path, manifesto: dict[str, Any]) -> None:
    alvo.write_text(json.dumps(manifesto, ensure_ascii=False, indent=1), encoding="utf-8")


def efeito_liquido(diario: list[dict[str, Any]]) -> dict[tuple[str, str], bool]:
    """Por `(tabela, chave canônica)`, se a linha **existe** na origem depois da última mutação.

    Deriva do que o banco **confirmou depois do commit**: cada mutação grava
    `presenca_apos_commit` — quantas linhas físicas restam para cada chave
    canônica que ela tocou (a antiga e a nova, quando a PK muda; nenhuma, se o
    banco não devolveu linha). É a multiplicidade do ADR-0045: apagar só `'08'`
    com `'8'` sobrevivente reduz a chave `8`, não a remove (RV10-2-07); alterar
    a PK de `'1'` para `'2'` deixa `1` ausente e `2` presente (RV10-2-06).
    Chave sem identidade não entra.

    Entradas anteriores a 15/09/2026 (noite) não têm o campo: para elas vale o
    que o `RETURNING` devolveu, com a chave canonizada — a leitura que RV10-10
    corrigiu e que estas duas contraprovas mostraram incompleta.
    """
    presente: dict[tuple[str, str], bool] = {}

    def registrar(tabela: str, bruta: str | None, existe: bool, *, sobrescreve: bool = True) -> None:
        chave = remocao.canonizar(bruta, remocao.chave(tabela)[1])
        if chave is None:  # sem identidade não entra na comparação (ADR-0045)
            return
        if sobrescreve:
            presente[(tabela, chave)] = existe
        else:
            presente.setdefault((tabela, chave), existe)

    for mutacao in diario:
        tabela, coluna = mutacao["tabela"], mutacao["chave"]
        if "presenca_apos_commit" in mutacao:
            for chave, restantes in mutacao["presenca_apos_commit"].items():
                presente[(tabela, chave)] = restantes > 0
        elif mutacao["tipo"] == "remover":
            for linha in mutacao["devolvidas"]:
                registrar(tabela, linha[coluna], False)
        elif mutacao["tipo"] == "inserir":
            registrar(tabela, mutacao["devolvida"][coluna], True)
        elif mutacao["tipo"] == "alterar" and mutacao["devolvidas"]:
            registrar(tabela, mutacao["valor_da_chave"], True, sobrescreve=False)
    return presente


def _presenca_canonica(engine: Engine, tabela: str, brutas: list[str | None]) -> dict[str, int]:
    """Depois do commit: quantas linhas físicas restam para cada chave canônica de `brutas`.

    Lê a coluna da PK inteira e canoniza em Python (`remocao.canonizar`, o
    espelho da macro): a igualdade textual da CLI não vê que `'8'` e `'08'`
    são a mesma chave, e é a chave canônica que o intervalo compara.
    """
    coluna, tipo = remocao.chave(tabela)
    alvo = {c for c in (remocao.canonizar(b, tipo) for b in brutas) if c is not None}
    if not alvo:
        return {}
    contagem = {c: 0 for c in alvo}
    with engine.connect() as conexao:
        for (valor,) in conexao.execute(text(f'select "{coluna}" from {schema.SCHEMA}."{tabela}"')):
            canonica = remocao.canonizar(valor, tipo)
            if canonica in contagem:
                contagem[canonica] += 1
    return contagem


def aptas(manifesto: dict[str, Any], tabela: str) -> list[int]:
    """`legacy_row_id` das ocorrências aptas da tabela, em ordem física."""
    return sorted(
        identidade
        for t, identidade, saida, *_ in manifesto["veredito"]
        if t == tabela and saida in ("accepted", "corrected")
    )


def _chave_de(engine: Engine, tabela: str, identidades: list[int]) -> list[str]:
    coluna, _ = remocao.chave(tabela)
    with engine.connect() as conexao:
        return [
            linha[0]
            for linha in conexao.execute(
                text(f'select "{coluna}" from {schema.SCHEMA}."{tabela}" where legacy_row_id = any(:ids) order by legacy_row_id'),
                {"ids": identidades},
            )
        ]


def _hash(engine: Engine, tabela: str) -> dict[str, Any]:
    with engine.connect() as conexao:
        return conteudo.hash_no_banco(conexao, schema.SCHEMA, tabela)


def remover(
    engine: Engine,
    tabela: str,
    *,
    chaves: list[str] | None = None,
    quantidade: int | None = None,
    manifesto: pathlib.Path = MANIFESTO,
) -> dict[str, Any]:
    """Apaga por chave de negócio e grava no diário o que o banco devolveu."""
    alvo, oraculo = _ler(manifesto)
    coluna, _ = remocao.chave(tabela)
    if chaves is None:
        if not quantidade:
            raise ValueError("informe --chaves ou --quantidade")
        chaves = _chave_de(engine, tabela, aptas(oraculo, tabela)[:quantidade])
        if len(chaves) < quantidade:
            raise ValueError(f"{tabela}: só {len(chaves)} ocorrências aptas para remover")
    colunas = ", ".join(f'"{c}"' for c in schema.colunas(tabela))
    antes = _hash(engine, tabela)
    with engine.begin() as conexao:
        devolvidas = [
            dict(linha)
            for linha in conexao.execute(
                text(
                    f'delete from {schema.SCHEMA}."{tabela}" where "{coluna}" = any(:chaves) '
                    f"returning legacy_row_id, {colunas}"
                ),
                {"chaves": chaves},
            ).mappings()
        ]
    with engine.connect() as conexao:
        restantes = conexao.execute(
            text(f'select count(*) from {schema.SCHEMA}."{tabela}" where "{coluna}" = any(:chaves)'),
            {"chaves": chaves},
        ).scalar_one()
    depois = _hash(engine, tabela)
    registro = {
        "tipo": "remover",
        "tabela": tabela,
        "chave": coluna,
        "chaves": chaves,
        "devolvidas": devolvidas,
        "linhas_apagadas": len(devolvidas),
        "restantes_apos_commit": int(restantes),
        "presenca_apos_commit": _presenca_canonica(engine, tabela, [linha[coluna] for linha in devolvidas]),
        "hash_antes": antes,
        "hash_depois": depois,
        "quando": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    if restantes:
        registro["erro"] = "linhas com a chave sobreviveram ao commit"
    oraculo["mutacoes"].append(registro)
    _gravar(alvo, oraculo)
    return registro


def inserir(engine: Engine, tabela: str, valores: dict[str, Any], *, manifesto: pathlib.Path = MANIFESTO) -> dict[str, Any]:
    """Insere uma linha de negócio e grava o que o banco devolveu."""
    alvo, oraculo = _ler(manifesto)
    desconhecidas = set(valores) - set(schema.colunas(tabela))
    if desconhecidas:
        raise ValueError(f"{tabela}: colunas desconhecidas {sorted(desconhecidas)}")
    colunas = list(valores)
    citadas = ", ".join(f'"{c}"' for c in colunas)
    marcadores = ", ".join(f":{c}" for c in colunas)
    todas = ", ".join(f'"{c}"' for c in schema.colunas(tabela))
    antes = _hash(engine, tabela)
    with engine.begin() as conexao:
        devolvida = dict(
            conexao.execute(
                text(
                    f'insert into {schema.SCHEMA}."{tabela}" ({citadas}) values ({marcadores}) '
                    f"returning legacy_row_id, {todas}"
                ),
                valores,
            ).mappings().one()
        )
    depois = _hash(engine, tabela)
    coluna_pk = remocao.chave(tabela)[0]
    registro = {
        "tipo": "inserir", "tabela": tabela, "chave": coluna_pk,
        "devolvida": devolvida, "hash_antes": antes, "hash_depois": depois,
        "presenca_apos_commit": _presenca_canonica(engine, tabela, [devolvida[coluna_pk]]),
        "quando": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    oraculo["mutacoes"].append(registro)
    _gravar(alvo, oraculo)
    return registro


def alterar(
    engine: Engine, tabela: str, chave: str, coluna: str, valor: str | None, *, manifesto: pathlib.Path = MANIFESTO
) -> dict[str, Any]:
    """Altera uma célula de uma linha de negócio e grava antes e depois."""
    alvo, oraculo = _ler(manifesto)
    pk, _ = remocao.chave(tabela)
    if coluna not in schema.colunas(tabela):
        raise ValueError(f"{tabela}: coluna desconhecida {coluna}")
    antes = _hash(engine, tabela)
    with engine.begin() as conexao:
        anteriores = [
            dict(linha)
            for linha in conexao.execute(
                text(f'select legacy_row_id, "{coluna}" as valor from {schema.SCHEMA}."{tabela}" where "{pk}" = :k'),
                {"k": chave},
            ).mappings()
        ]
        devolvidas = [
            dict(linha)
            for linha in conexao.execute(
                text(
                    f'update {schema.SCHEMA}."{tabela}" set "{coluna}" = :v where "{pk}" = :k '
                    f'returning legacy_row_id, "{coluna}" as valor'
                ),
                {"v": valor, "k": chave},
            ).mappings()
        ]
    depois = _hash(engine, tabela)
    # Só o que o banco devolveu toca a presença: a chave pedida, e a nova se a
    # própria PK mudou. Alteração de zero linhas não toca chave nenhuma —
    # gravar `{chave: 0}` fabricaria uma testemunha de ausência para uma chave
    # que o diário nunca viu existir (RV10-3-02).
    tocadas = ([chave] + [linha["valor"] for linha in devolvidas if coluna == pk]) if devolvidas else []
    registro = {
        "tipo": "alterar", "tabela": tabela, "chave": pk, "valor_da_chave": chave, "coluna": coluna,
        "antes": anteriores, "devolvidas": devolvidas, "hash_antes": antes, "hash_depois": depois,
        "presenca_apos_commit": _presenca_canonica(engine, tabela, tocadas),
        "quando": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    oraculo["mutacoes"].append(registro)
    _gravar(alvo, oraculo)
    return registro
