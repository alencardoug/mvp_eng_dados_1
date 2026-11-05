"""As vigências SCD não dependem do fuso da sessão: gravadas e lidas em UTC explícito.

O `dbt snapshot` do dbt-postgres grava `now()::timestamp without time zone` — a hora
local da sessão — em `dbt_valid_from`, `dbt_valid_to` e `dbt_updated_at`. As dimensões
SCD leem essas colunas como instante UTC, para comparar com o `timestamptz` das fatos.
Os dois lados só concordam se o escritor gravar UTC: é a macro `snapshot_get_time` do
projeto que o garante, no caminho que grava, e não um teste depois dele (revisão do
lote 3 da v1.1.0, RVL3-5-01).
"""

from __future__ import annotations

import json
import pathlib

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
DBT = RAIZ / "dbt"
DIMENSOES_SCD = ("dim_customer", "dim_coupon", "dim_product", "dim_support_agent")


def test_o_escritor_do_snapshot_grava_utc_explicito() -> None:
    macro = (DBT / "macros" / "snapshot_get_time.sql").read_text(encoding="utf-8")
    # As duas portas: a chamada direta e a que o `adapter.dispatch` procura (checagem de tipo).
    assert "macro snapshot_get_time()" in macro and "macro postgres__snapshot_get_time()" in macro
    assert macro.count("(now() at time zone 'UTC')") == 2


@pytest.mark.parametrize("dimensao", DIMENSOES_SCD)
def test_a_dimensao_le_as_vigencias_como_instante_utc(dimensao: str) -> None:
    sql = (DBT / "models" / "analytics" / f"{dimensao}.sql").read_text(encoding="utf-8")
    assert "v.dbt_valid_from at time zone 'UTC'" in sql
    assert "v.dbt_valid_to at time zone 'UTC'" in sql


def test_o_dbt_carrega_a_macro_do_projeto() -> None:
    """No manifest, a macro do projeto existe com o corpo em UTC — a do projeto raiz vence a global.

    Que é ela que o snapshot roda se conferiu no log de um `dbt snapshot` da revisão: 60
    ocorrências de `(now() at time zone 'UTC')` e nenhuma de `now()::timestamp`."""
    manifest = DBT / "target" / "manifest.json"
    if not manifest.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    macros = json.loads(manifest.read_text(encoding="utf-8"))["macros"]
    for nome in ("snapshot_get_time", "postgres__snapshot_get_time"):
        assert "(now() at time zone 'UTC')" in macros[f"macro.mvp_ed1.{nome}"]["macro_sql"]
