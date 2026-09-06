"""Contrato das três saídas, com exemplos independentes do injetor e sem escrita."""

from __future__ import annotations

import json
import os

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.legacy.catalogo import carregar
from mvp_ed1.legacy.classification import classification_sql, table_contract


@pytest.fixture(scope="module")
def classifier_engine():
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("carregue o .env para os testes SQL do legado")
    engine = create_engine(database_url(WAREHOUSE))
    yield engine
    engine.dispose()


def record(table, row_id, payload, *, snapshot=1, findings=None, original=None,
           required=("id",), references=(), keys=(("id",),)):
    return {
        "source_system": "legacy", "snapshot_id": snapshot,
        "snapshot_at": "2026-09-06T00:00:00+00:00", "source_table": table,
        "legacy_row_id": row_id, "original_payload": payload if original is None else original,
        "cleaned_payload": payload, "value_findings": findings or {},
        "record_contract": {"required": list(required), "references": list(references),
                            "unique_keys": [{"columns": list(k), "conditions": []} for k in keys]},
    }


def reference(column, table):
    return {"column": column, "table": table, "key": "id"}


def classify(engine, records):
    relation = """jsonb_to_recordset(cast(:records as jsonb)) as input(
        source_system text, snapshot_id bigint, snapshot_at timestamptz,
        source_table text, legacy_row_id bigint, original_payload jsonb,
        cleaned_payload jsonb, value_findings jsonb, record_contract jsonb)"""
    query = classification_sql(carregar(), relation)
    with engine.connect() as connection:
        connection.execute(text("set local statement_timeout = '30s'"))
        return [dict(r) for r in connection.execute(text(query), {"records": json.dumps(records)}).mappings()]


def codes(row):
    return {f["code"] for f in row["findings"]}


@pytest.mark.integracao
def test_null_required_preserves_conversion_and_exclusive_outcomes(classifier_engine):
    rows = [
        record("parents", 1, {"id": "1", "code": None}, required=("id", "code"),
               findings={"code": "NULL_DISGUISED"}, original={"id": "1", "code": "N/A"}),
        record("parents", 2, {"id": "2", "optional": None}, findings={"optional": "NULL_DISGUISED"}),
        record("parents", 3, {"id": "3", "code": None}, required=("id", "code")),
        record("parents", 4, {"id": "4", "optional": None}),
    ]
    actual = {r["legacy_row_id"]: r for r in classify(classifier_engine, rows)}
    assert len(actual) == len(rows)
    assert [actual[i]["classification"] for i in range(1, 5)] == ["rejected", "corrected", "rejected", "accepted"]
    assert codes(actual[1]) == {"NULL_DISGUISED", "NULL_REQUIRED"}
    assert actual[1]["original_payload"]["code"] == "N/A"
    assert actual[1]["cleaned_payload"]["code"] is None
    assert codes(actual[2]) == {"NULL_DISGUISED"}
    assert codes(actual[3]) == {"NULL_REQUIRED"}


@pytest.mark.integracao
def test_exact_duplicate_uses_physical_canonical_without_rejecting_child(classifier_engine):
    payload = {"id": "100", "code": "A"}
    rows = [record("parents", 9, payload), record("parents", 2, payload),
            record("children", 1, {"id": "1", "parent_id": "100"}, references=[reference("parent_id", "parents")]),
            record("parents", 9, payload, snapshot=2)]
    actual = {(r["snapshot_id"], r["source_table"], r["legacy_row_id"]): r for r in classify(classifier_engine, rows)}
    assert actual[1, "parents", 2]["classification"] == "accepted"
    duplicate = actual[1, "parents", 9]
    assert codes(duplicate) == {"DUP_EXACT"}
    assert duplicate["rejection_origin"] == "duplicate_excess"
    assert duplicate["findings"][0]["context"]["canonical_row_id"] == 2
    assert actual[1, "children", 1]["classification"] == "accepted"
    assert actual[2, "parents", 9]["classification"] == "accepted"


@pytest.mark.integracao
def test_partial_duplicate_rejects_both_versions_and_cascades(classifier_engine):
    rows = [record("parents", 1, {"id": "1", "code": "A"}),
            record("parents", 2, {"id": "1", "code": "B"}),
            record("children", 1, {"id": "1", "parent_id": "1"}, references=[reference("parent_id", "parents")])]
    actual = classify(classifier_engine, rows)
    assert all(r["classification"] == "rejected" for r in actual)
    assert all("DUP_PARTIAL" in codes(r) for r in actual if r["source_table"] == "parents")
    child = next(r for r in actual if r["source_table"] == "children")
    assert codes(child) == {"PARENT_REJECTED"}
    assert {f["context"]["parent_row_id"] for f in child["findings"]} == {1, 2}


@pytest.mark.integracao
def test_orphan_differs_from_rejected_parent_and_cascade_is_transitive(classifier_engine):
    rows = [record("parents", 1, {"id": "1", "code": None}, required=("id", "code")),
            record("children", 2, {"id": "2", "parent_id": "1"}, references=[reference("parent_id", "parents")]),
            record("children", 3, {"id": "3", "parent_id": "99"}, references=[reference("parent_id", "parents")]),
            record("grandchildren", 4, {"id": "4", "child_id": "2"}, references=[reference("child_id", "children")])]
    actual = {r["legacy_row_id"]: r for r in classify(classifier_engine, rows)}
    assert codes(actual[2]) == {"PARENT_REJECTED"}
    assert codes(actual[3]) == {"FK_ORPHAN"}
    assert codes(actual[4]) == {"PARENT_REJECTED"}
    assert actual[4]["findings"][0]["context"] == {"parent_table": "children", "parent_row_id": 2}


@pytest.mark.integracao
def test_self_reference_cycle_terminates_with_rejected_root(classifier_engine):
    refs = [reference("parent_id", "categories")]
    rows = [record("categories", 1, {"id": "1", "parent_id": "2", "name": None}, required=("id", "name"), references=refs),
            record("categories", 2, {"id": "2", "parent_id": "1"}, references=refs)]
    actual = classify(classifier_engine, rows)
    assert len(actual) == 2 and all(r["classification"] == "rejected" for r in actual)


@pytest.mark.integracao
@pytest.mark.parametrize("total,expected", [("10.00", "accepted"), ("11.00", "rejected")])
def test_total_includes_adjustments_and_cascades_to_items(classifier_engine, total, expected):
    rows = [record("orders", 1, {"id": "1", "subtotal_amount": "9", "discount_amount": "2",
                               "shipping_amount": "1", "tax_amount": "2", "total_amount": total}),
            record("order_items", 1, {"id": "1", "order_id": "1", "quantity": "3", "unit_price": "3"},
                   references=[reference("order_id", "orders")])]
    actual = {r["source_table"]: r for r in classify(classifier_engine, rows)}
    assert actual["orders"]["classification"] == expected
    assert actual["order_items"]["classification"] == expected
    if expected == "rejected":
        assert codes(actual["orders"]) == {"TOTAL_MISMATCH"}
        assert codes(actual["order_items"]) == {"PARENT_REJECTED"}


@pytest.mark.integracao
def test_pai_rejeitado_nao_torna_o_total_do_pedido_inconsistente(classifier_engine):
    """A cascata alcança o item, e **para** aí — não contamina o total.

    Este teste afirmava o contrário, e o contrário era uma circularidade: a
    soma dos itens descontava os já rejeitados, deixava de bater com o
    subtotal, o pedido virava `TOTAL_MISMATCH`, e isso criava mais rejeições
    que tiravam mais itens da soma. Media-se 114 pedidos não reconciliados de
    177; contra todos os itens capturados, 175 reconciliam.

    O critério é o do negócio: o total declarado reconcilia com o que a origem
    **registrou**. Um item cujo produto foi rejeitado é um achado do item — não
    torna inconsistente o total que o pedido sempre teve.
    """
    rows = [record("products", 1, {"id": "1", "code": None}, required=("id", "code")),
            record("orders", 1, {"id": "1", "subtotal_amount": "9", "discount_amount": "0",
                                "shipping_amount": "0", "tax_amount": "0", "total_amount": "9"}),
            record("order_items", 1, {"id": "1", "order_id": "1", "product_id": "1", "quantity": "3", "unit_price": "3"},
                   references=[reference("order_id", "orders"), reference("product_id", "products")])]
    actual = {r["source_table"]: r for r in classify(classifier_engine, rows)}

    assert actual["order_items"]["classification"] == "rejected", "a cascata precisa alcançar o item"
    assert "TOTAL_MISMATCH" not in codes(actual["orders"]), (
        "o total do pedido reconcilia com o que a origem registrou, e não com o que sobrou"
    )
    assert actual["orders"]["classification"] == "accepted"


def test_required_fields_and_partial_unique_predicates_come_from_models():
    assert "shipment_code" in table_contract("shipments")["required"]
    assert "color" not in table_contract("product_variants")["required"]
    keys = table_contract("customer_addresses")["unique_keys"]
    partial = next(k for k in keys if k["columns"] == ["customer_id", "address_type"])
    assert partial["conditions"] == [{"column": "is_primary", "kind": "is_true"},
                                     {"column": "deleted_at", "kind": "is_null"}]


@pytest.mark.integracao
@pytest.mark.parametrize("conflict", [False, True])
def test_partial_unique_index_does_not_reject_secondary_or_deleted_addresses(classifier_engine, conflict):
    rows = [record("addresses", i, {"id": str(i), "customer_id": "10", "address_type": "shipping",
                                   "is_primary": "false" if i == 2 else "true",
                                   "deleted_at": "2026-01-01" if i == 3 else None})
            for i in range(1, 5 if conflict else 4)]
    for row in rows:
        row["record_contract"]["unique_keys"] = table_contract("customer_addresses")["unique_keys"]
    actual = {r["legacy_row_id"]: r for r in classify(classifier_engine, rows)}
    assert actual[2]["classification"] == actual[3]["classification"] == "accepted"
    assert actual[1]["classification"] == ("rejected" if conflict else "accepted")
    if conflict:
        assert codes(actual[1]) == codes(actual[4]) == {"DUP_PARTIAL"}
