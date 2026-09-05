"""As barreiras das operações destrutivas são verificadas antes de conectar."""

from unittest.mock import MagicMock

import pytest

from mvp_ed1.streaming.config import Destino
from mvp_ed1.streaming.maintenance import drop_replication_slots, main, reset_stream_sink


@pytest.mark.parametrize("command", ["drop-slots", "reset-sink"])
def test_maintenance_requires_explicit_force(command, monkeypatch):
    connect = MagicMock(side_effect=AssertionError("não deveria abrir banco"))
    monkeypatch.setattr("mvp_ed1.streaming.maintenance.sa.create_engine", connect)
    with pytest.raises(SystemExit) as error:
        main([command])
    assert error.value.code == 2
    connect.assert_not_called()


@pytest.mark.parametrize("destination", [
    Destino("raw_legacy", "inventory_movements_stream", 500),
    Destino("raw", "inventory_movements", 500),
])
def test_reset_refuses_any_other_destination(destination):
    engine = MagicMock()
    with pytest.raises(ValueError, match="somente"):
        reset_stream_sink(engine, destination)
    engine.begin.assert_not_called()


@pytest.mark.parametrize("active,own_database", [(True, True), (False, False)])
def test_slot_is_not_dropped_when_active_or_from_another_database(active, own_database):
    engine = MagicMock()
    connection = engine.connect.return_value.execution_options.return_value.__enter__.return_value
    connection.execute.return_value.mappings.return_value.one_or_none.return_value = {
        "active": active, "own_database": own_database,
    }
    with pytest.raises(RuntimeError, match="ativo ou pertencente"):
        drop_replication_slots(engine, ("mvp_inventory_movements",))
    assert connection.execute.call_count == 1  # Só consultou; nunca tentou remover.


def test_slot_failure_never_reports_success(capsys):
    engine = MagicMock()
    engine.connect.side_effect = RuntimeError("conexão indisponível")
    with pytest.raises(RuntimeError, match="indisponível"):
        drop_replication_slots(engine, ("mvp_inventory_movements",))
    assert capsys.readouterr().out == ""


def test_absent_slot_is_not_reported_as_removed():
    engine = MagicMock()
    connection = engine.connect.return_value.execution_options.return_value.__enter__.return_value
    connection.execute.return_value.mappings.return_value.one_or_none.return_value = None
    assert drop_replication_slots(engine, ("mvp_inventory_movements",)) == []
    assert connection.execute.call_count == 1


@pytest.mark.parametrize("remaining", [0, 1])
def test_slot_removal_is_verified_in_catalog(remaining):
    engine = MagicMock()
    connection = engine.connect.return_value.execution_options.return_value.__enter__.return_value
    state = MagicMock()
    state.mappings.return_value.one_or_none.return_value = {"active": False, "own_database": True}
    count = MagicMock()
    count.scalar_one.return_value = remaining
    connection.execute.side_effect = [state, MagicMock(), count]
    if remaining:
        with pytest.raises(RuntimeError, match="continua presente"):
            drop_replication_slots(engine, ("mvp_inventory_movements",))
    else:
        assert drop_replication_slots(engine, ("mvp_inventory_movements",)) == ["mvp_inventory_movements"]
    assert connection.execute.call_count == 3
