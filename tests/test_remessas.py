"""D31: caixas não vazias, com conservação das quantidades por item vendido."""

import datetime as dt
from collections import Counter
from decimal import Decimal

import pytest

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.domains.logistica import remessas
from mvp_ed1.generator.engine import Motor


@pytest.mark.parametrize("quantities", [(1,), (1, 1), (1, 1, 1), (1, 1, 1, 1), (2,), (3,), (1, 3, 2)])
@pytest.mark.parametrize("split_requested", [False, True])
def test_shipments_preserve_items_without_empty_boxes(config, monkeypatch, quantities, split_requested):
    # Probabilidade 0/1 força a decisão no construtor real, sem depender da seed.
    monkeypatch.setitem(
        config.tabelas["shipments"].processo, "remessa_dividida", int(split_requested)
    )
    engine = Motor(config)
    data = Dataset()
    data.guardar("carriers", [{"id": 1, "service_level": "standard"}])
    data.guardar("warehouses", [{"id": 1, "city": "São Paulo"}])
    data.guardar("orders", [{
        "id": 1,
        "status": "delivered",
        "placed_at": engine.inicio,
        "shipping_amount": Decimal("20.00"),
        "__momentos": {
            "picking": engine.inicio + dt.timedelta(days=1),
            "shipped": engine.inicio + dt.timedelta(days=2),
            "delivered": engine.inicio + dt.timedelta(days=3),
        },
    }])
    data.guardar("order_items", [
        {"id": index, "order_id": 1, "product_variant_id": index, "quantity": quantity}
        for index, quantity in enumerate(quantities, start=1)
    ])

    remessas(engine, data)

    expected_boxes = 2 if split_requested and sum(quantities) >= 2 else 1
    assert len(data["shipments"]) == expected_boxes
    assert {row["shipment_id"] for row in data["shipment_items"]} == {
        row["id"] for row in data["shipments"]
    }
    shipped = Counter()
    for row in data["shipment_items"]:
        assert row["quantity"] > 0
        shipped[row["order_item_id"]] += row["quantity"]
    assert dict(shipped) == dict(enumerate(quantities, start=1))

    # A partição por item tem ordem estável; o item avulso nunca é duplicado.
    if expected_boxes == 2 and all(quantity == 1 for quantity in quantities):
        assert [row["order_item_id"] for row in data["shipment_items"] if row["shipment_id"] == 1] == list(
            range(1, len(quantities) // 2 + 1)
        )


@pytest.mark.parametrize("dataset_fixture", ["dados", "dados_reduzidos"])
def test_split_delivered_orders_are_covered(request, dataset_fixture):
    """O teste dbt do ciclo do pedido dividido não pode passar por vacuidade."""
    data = request.getfixturevalue(dataset_fixture)
    delivered = Counter(
        row["order_id"] for row in data["shipments"] if row["status"] in ("delivered", "returned")
    )
    assert any(count > 1 for count in delivered.values())
