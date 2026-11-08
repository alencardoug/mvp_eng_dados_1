"""As mutações da origem legada entre as duas capturas da janela, da declaração (§7.2; ADR-0045).

`mutacoes_da_janela.yml` diz o quê; aqui elas se aplicam no legado do ambiente (o Cloud SQL, pelo
`make gcp-legado-mutar`), uma por vez, pelo mesmo `mutacoes` da fase local. O diário vai para o
manifesto do lote desse legado (`MVP_REGISTROS_DIR`).

Cada mutação confirma e grava o diário sozinha; uma falha no meio deixa as anteriores aplicadas
(RV13J-1-04). Por isso o diário é lido como **prefixo** da declaração:

* vazio — aplica todas;
* prefixo próprio, sem erro registrado — **retoma** da primeira que falta, sem repetir as que já
  foram (repetir uma remoção apagaria outras chaves);
* completo — nada a fazer, e diz isso;
* qualquer outra coisa (outra ordem, outra tabela, entrada com erro) — recusa, e é para parar.

Antes de cada mutação, o *hash* da tabela no banco tem de ser o que o diário diz que ela tem — o
`hash_depois` da última mutação nela, ou o do lote carregado (`lote.tabelas`) se nenhuma a tocou.
Diferente, houve mudança fora do diário (uma mutação confirmada cujo diário não foi gravado, por
exemplo), e o esperado da matriz já não seria o efeito do diário: recusa.

    python -m mvp_ed1.gcp.mutacoes_janela
"""

from __future__ import annotations

import json
import pathlib
import sys
from typing import Any

import yaml

DECLARACAO = pathlib.Path(__file__).with_name("mutacoes_da_janela.yml")
OPERACOES = ("remover", "inserir", "alterar")


def declaradas(caminho: pathlib.Path = DECLARACAO) -> list[tuple[str, dict[str, Any]]]:
    """`(operação, argumentos)` na ordem; cada item tem uma operação só."""
    itens = yaml.safe_load(caminho.read_text(encoding="utf-8"))["mutacoes"]
    saida = []
    for item in itens:
        if len(item) != 1 or next(iter(item)) not in OPERACOES:
            raise ValueError(f"mutação mal declarada: {item}")
        operacao, argumentos = next(iter(item.items()))
        saida.append((operacao, dict(argumentos)))
    return saida


class Recusa(RuntimeError):
    """O diário e o banco não permitem seguir; a mensagem diz o quê, e é para parar."""


def _pendentes(diario: list[dict[str, Any]], itens: list[tuple[str, dict[str, Any]]]) -> int:
    """Quantas das declaradas o diário já tem, conferido como prefixo exato delas."""
    if len(diario) > len(itens):
        raise Recusa(f"o diário tem {len(diario)} mutações e a declaração {len(itens)}: não é o diário da janela")
    for i, (entrada, (operacao, argumentos)) in enumerate(zip(diario, itens), start=1):
        if (entrada.get("tipo"), entrada.get("tabela")) != (operacao, argumentos["tabela"]):
            raise Recusa(f"a mutação {i} do diário é {entrada.get('tipo')} em {entrada.get('tabela')}, e a declarada "
                         f"é {operacao} em {argumentos['tabela']}: não é o diário da janela")
        if "erro" in entrada:
            raise Recusa(f"a mutação {i} do diário registrou erro ({entrada['erro']}): o banco não está no estado "
                         "que a declaração supõe")
    return len(diario)


def _hash_esperado(manifesto: dict[str, Any], tabela: str) -> str:
    for entrada in reversed(manifesto.get("mutacoes") or []):
        if entrada.get("tabela") == tabela:
            return entrada["hash_depois"]["hash"]
    return manifesto["lote"]["tabelas"][tabela]["hash"]


def _hash_atual(engine, tabela: str) -> str:
    from mvp_ed1.legacy import conteudo, schema

    with engine.connect() as conexao:
        return conteudo.hash_no_banco(conexao, schema.SCHEMA, tabela)["hash"]


def aplicar(engine, manifesto: pathlib.Path, itens: list[tuple[str, dict[str, Any]]], *,
            hash_atual=_hash_atual) -> list[dict[str, Any]]:
    """Aplica as declaradas que o diário ainda não tem; devolve os registros das aplicadas agora."""
    from mvp_ed1.legacy import mutacoes

    def ler() -> dict[str, Any]:
        return json.loads(manifesto.resolve().read_text(encoding="utf-8"))

    feitas = _pendentes(ler().get("mutacoes") or [], itens)
    if feitas:
        print(f"o diário já tem {feitas} de {len(itens)} mutações da janela"
              + ("; retomando da seguinte" if feitas < len(itens) else ""))
    registros = []
    for operacao, a in itens[feitas:]:
        esperado, atual = _hash_esperado(ler(), a["tabela"]), hash_atual(engine, a["tabela"])
        if atual != esperado:
            raise Recusa(f"{a['tabela']} mudou fora do diário (hash {atual[:12]}, o diário diz {esperado[:12]}): "
                         "uma mutação confirmada sem registro, ou outra escrita; o esperado da matriz não vale")
        try:
            if operacao == "remover":
                registro = mutacoes.remover(engine, a["tabela"], quantidade=a.get("quantidade"),
                                            chaves=a.get("chaves"), manifesto=manifesto)
            elif operacao == "inserir":
                registro = mutacoes.inserir(engine, a["tabela"], {k: str(v) for k, v in a["valores"].items()},
                                            manifesto=manifesto)
            else:
                registro = mutacoes.alterar(engine, a["tabela"], str(a["chave"]), a["coluna"], a.get("valor"),
                                            manifesto=manifesto)
        except ValueError as erro:
            raise Recusa(f"{operacao} em {a['tabela']}: {erro}") from erro
        if "erro" in registro:
            raise Recusa(f"{operacao} em {a['tabela']}: {registro['erro']}")
        registros.append(registro)
        print(f"{operacao} {a['tabela']}: hash {registro['hash_antes']['hash'][:12]} → {registro['hash_depois']['hash'][:12]}")
    if _pendentes(ler().get("mutacoes") or [], itens) != len(itens):
        raise Recusa("o diário não ficou com todas as mutações declaradas")
    return registros


def main(argv: list[str] | None = None) -> int:
    del argv
    from sqlalchemy import create_engine

    from mvp_ed1.db import LEGACY, database_url
    from mvp_ed1.legacy.cli import _manifestos

    manifesto = _manifestos() / "manifesto.json"
    if not manifesto.exists():
        print(f"RECUSADO: {manifesto} não existe — povoe o legado antes (make gcp-origens-povoar)", file=sys.stderr)
        return 1
    engine = create_engine(database_url(LEGACY))
    itens = declaradas()
    try:
        registros = aplicar(engine, manifesto, itens)
    except Recusa as erro:
        print(f"RECUSADO: {erro}", file=sys.stderr)
        return 1
    finally:
        engine.dispose()
    print(f"{len(registros)} mutações aplicadas agora; o diário tem as {len(itens)} da janela, em {manifesto}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
