"""As mutações da origem legada entre as duas capturas da janela, da declaração (§7.2; ADR-0045).

`mutacoes_da_janela.yml` diz o quê; aqui elas se aplicam no legado do ambiente (o Cloud SQL, pelo
`make gcp-legado-mutar`), uma por vez, pelo mesmo `mutacoes` da fase local. O diário vai para o
manifesto do lote desse legado (`MVP_REGISTROS_DIR`). Recusa com o diário já preenchido: aplicar
duas vezes removeria outras chaves e o esperado deixaria de ser o declarado.

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


def aplicar(engine, manifesto: pathlib.Path, itens: list[tuple[str, dict[str, Any]]]) -> list[dict[str, Any]]:
    from mvp_ed1.legacy import mutacoes

    diario = json.loads(manifesto.resolve().read_text(encoding="utf-8")).get("mutacoes") or []
    if diario:
        raise RuntimeError(f"o diário de {manifesto} já tem {len(diario)} mutações: as da janela já foram aplicadas")
    registros = []
    for operacao, a in itens:
        if operacao == "remover":
            registro = mutacoes.remover(engine, a["tabela"], quantidade=a.get("quantidade"), chaves=a.get("chaves"),
                                        manifesto=manifesto)
        elif operacao == "inserir":
            registro = mutacoes.inserir(engine, a["tabela"], {k: str(v) for k, v in a["valores"].items()},
                                        manifesto=manifesto)
        else:
            registro = mutacoes.alterar(engine, a["tabela"], str(a["chave"]), a["coluna"], a.get("valor"),
                                        manifesto=manifesto)
        if "erro" in registro:
            raise RuntimeError(f"{operacao} em {a['tabela']}: {registro['erro']}")
        registros.append(registro)
        print(f"{operacao} {a['tabela']}: hash {registro['hash_antes']['hash'][:12]} → {registro['hash_depois']['hash'][:12]}")
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
    try:
        registros = aplicar(engine, manifesto, declaradas())
    except RuntimeError as erro:
        print(f"RECUSADO: {erro}", file=sys.stderr)
        return 1
    finally:
        engine.dispose()
    print(f"{len(registros)} mutações aplicadas; diário em {manifesto}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
