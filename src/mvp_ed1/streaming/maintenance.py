"""Manutenção explícita do estado descartável do streaming em desenvolvimento.

Não altera o contrato append-only: uma regeração começa com o consumidor
parado e um snapshot novo. Slots vêm dos conectores declarados; o destino
permitido é somente a tabela do caminho quente no warehouse.
"""

from __future__ import annotations

import argparse
import re

import sqlalchemy as sa
import yaml

from mvp_ed1.db import SOURCE, WAREHOUSE, database_url
from mvp_ed1.streaming import config


def declared_slots() -> tuple[str, ...]:
    slots = set()
    for path in sorted(config.CONECTORES.glob("*.yml")):
        declaration = yaml.safe_load(path.read_text(encoding="utf-8"))
        slot = declaration["config"]["slot.name"]
        if not isinstance(slot, str) or not re.fullmatch(r"[a-z0-9_]+", slot):
            raise ValueError(f"slot inválido em {path.name}")
        slots.add(slot)
    if not slots:
        raise ValueError("nenhum slot declarado em streaming/connectors/")
    return tuple(sorted(slots))


def drop_replication_slots(engine: sa.Engine, slots: tuple[str, ...]) -> list[str]:
    """Recusa slots ativos ou de outro banco e confirma a remoção pelo catálogo."""
    removed = []
    with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as connection:
        for slot in slots:
            state = connection.execute(sa.text(
                "select active, database = current_database() as own_database "
                "from pg_replication_slots where slot_name = :slot"
            ), {"slot": slot}).mappings().one_or_none()
            if state is None:
                continue
            if state["active"] or not state["own_database"]:
                raise RuntimeError(f"slot {slot!r} ativo ou pertencente a outro banco; nada removido dele")
            connection.execute(sa.text("select pg_drop_replication_slot(:slot)"), {"slot": slot})
            remaining = connection.execute(sa.text(
                "select count(*) from pg_replication_slots where slot_name = :slot"
            ), {"slot": slot}).scalar_one()
            if remaining:
                raise RuntimeError(f"slot {slot!r} continua presente após a remoção")
            removed.append(slot)
    return removed


def reset_stream_sink(engine: sa.Engine, destination: config.Destino) -> int:
    """Trunca apenas o destino autorizado, sem CASCADE e com contagem conferida.

    O chamador deve parar Beam/Prism e o conector antes. Lock e contagem na
    mesma transação impedem que a verificação aceite uma escrita concorrente.
    A restrição explícita evita que uma declaração errada esvazie outra camada.
    """
    if (destination.schema, destination.tabela) != ("raw", "inventory_movements_stream"):
        raise ValueError("reset permitido somente para raw.inventory_movements_stream")
    with engine.begin() as connection:
        connection.execute(sa.text("set local lock_timeout = '5s'"))
        exists = connection.execute(sa.text(
            "select to_regclass('raw.inventory_movements_stream') is not null"
        )).scalar_one()
        if not exists:
            return 0
        connection.execute(sa.text("lock table raw.inventory_movements_stream in access exclusive mode"))
        rows = connection.execute(sa.text("select count(*) from raw.inventory_movements_stream")).scalar_one()
        connection.execute(sa.text("truncate table raw.inventory_movements_stream"))
        if connection.execute(sa.text("select count(*) from raw.inventory_movements_stream")).scalar_one():
            raise RuntimeError("destino do streaming não ficou vazio; transação cancelada")
    return rows


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["drop-slots", "reset-sink"])
    parser.add_argument("--force", action="store_true", help="autoriza descartar o estado indicado")
    args = parser.parse_args(argv)
    if not args.force:
        parser.error("operação destrutiva: use FORCE=1 no Makefile ou --force após parar os consumidores")

    prefix = SOURCE if args.command == "drop-slots" else WAREHOUSE
    engine = sa.create_engine(database_url(prefix))
    try:
        if args.command == "drop-slots":
            slots = declared_slots()
            removed = drop_replication_slots(engine, slots)
            for slot in slots:
                print(f"slot {slot!r}: " + ("removido e ausência conferida" if slot in removed else "já ausente"))
        else:
            rows = reset_stream_sink(engine, config.carregar().destino)
            print(f"raw.inventory_movements_stream: {rows} linhas removidas; destino vazio conferido")
    finally:
        engine.dispose()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
