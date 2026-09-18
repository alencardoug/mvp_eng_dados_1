"""O SQL que `aplicar_acesso_por_camada` emite, lido sem banco.

`tests/test_acesso.py` prova a política executando cada papel no armazém; este
prova a **macro** — o que o `on-run-end` manda para o banco a partir do que os
`.yml` declaram — renderizando-a com o mesmo Jinja do dbt e um inventário de
mentira. Um grafo mínimo cobre a regra; o manifest real, quando existe, confere
que a declaração inteira produz `create` só para os escritores da Governança §7.
"""

from __future__ import annotations

import json
import pathlib
from types import SimpleNamespace

import jinja2
import pytest

from mvp_ed1.governance import PAPEIS

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MACRO = RAIZ / "dbt" / "macros" / "aplicar_acesso_por_camada.sql"
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"


class _Retorno(Exception):
    def __init__(self, valor):
        self.valor = valor


def renderizar(nodes: dict, sources: dict, schemas: list[str], tabelas: list[str], papeis=PAPEIS) -> list[str]:
    """Os comandos que a macro emitiria para este grafo e este inventário do banco."""
    inventario = {"pg_namespace": schemas, "information_schema.tables": tabelas, "pg_roles": list(papeis)}

    def run_query(sql: str):
        valores = next(v for chave, v in inventario.items() if chave in sql)
        return SimpleNamespace(columns=[SimpleNamespace(values=lambda: valores)])

    def _return(valor):
        raise _Retorno(valor)

    ambiente = jinja2.Environment(extensions=["jinja2.ext.do"])
    ambiente.globals.update(target=SimpleNamespace(type="postgres"), execute=True, run_query=run_query,
                            graph=SimpleNamespace(nodes=nodes, sources=sources))
    ambiente.globals["return"] = _return
    modulo = ambiente.from_string(MACRO.read_text(encoding="utf-8")).module
    try:
        texto = modulo.aplicar_acesso_por_camada()
    except _Retorno as retorno:
        texto = retorno.valor
    return [c.strip() for c in str(texto).split(";") if c.strip()]


def _modelo(nome: str, schema: str, grants: dict, writers: list[str]) -> dict:
    return {"resource_type": "model", "schema": schema, "config": {"enabled": True, "grants": grants, "meta": {"writers": writers}}}


def _fonte(schema: str, tabela: str, grants: dict, writers: list[str]) -> dict:
    return {"schema": schema, "identifier": tabela, "meta": {"grants": grants, "writers": writers}}


GRAFO_MINIMO = dict(
    nodes={"model.x.view": _modelo("view", "consumption", {"select": ["analyst", "transformer"]}, ["transformer"])},
    sources={
        "source.x.raw.customers": _fonte("raw", "customers", {"select": ["transformer"]}, ["ingestor"]),
        "source.x.raw.stream": _fonte("raw", "inventory_movements_stream", {"select": ["streamer", "transformer"], "insert": ["streamer"]}, ["ingestor"]),
    },
    schemas=["raw", "consumption"],
    tabelas=["raw.customers", "raw.inventory_movements_stream", "consumption.view"],
)


def test_create_so_para_o_escritor_e_revogado_de_quem_entra_sem_escrever() -> None:
    comandos = renderizar(**GRAFO_MINIMO)
    assert "grant create on schema raw to ingestor" in comandos
    assert "grant create on schema consumption to transformer" in comandos
    assert not any(c.startswith("grant create") and "streamer" in c for c in comandos)
    # Quem entra sem escrever perde o `create`, esteja ele lá por mão humana ou por história.
    assert "revoke create on schema consumption from analyst" in comandos
    assert "revoke create on schema raw from streamer" in comandos
    assert "revoke create on schema raw from transformer" in comandos
    assert "grant usage on schema raw to ingestor, streamer, transformer" in comandos
    assert "grant usage on schema consumption to analyst, transformer" in comandos


def test_quem_nao_entra_perde_tudo_e_a_fonte_e_zerada_antes_de_conceder() -> None:
    comandos = renderizar(**GRAFO_MINIMO)
    assert "revoke all privileges on schema consumption from auditor" in comandos
    assert "revoke all privileges on schema raw from analyst" in comandos
    zera = comandos.index("revoke all privileges on raw.inventory_movements_stream from analyst, auditor, ingestor, streamer, transformer")
    assert comandos.index("grant insert on raw.inventory_movements_stream to streamer") > zera
    assert comandos.index("grant select on raw.inventory_movements_stream to streamer, transformer") > zera


def test_so_o_que_existe_entra_e_fora_do_postgres_nada_sai() -> None:
    parcial = dict(GRAFO_MINIMO, schemas=["raw"], tabelas=["raw.customers"])
    comandos = renderizar(**parcial)
    assert not any("consumption" in c or "inventory_movements_stream" in c for c in comandos)
    assert any(c.startswith("grant select on raw.customers") for c in comandos)


def test_a_declaracao_inteira_concede_create_so_aos_escritores_da_governanca() -> None:
    """Com o manifest real: o `create` que o hook emite, por schema, é a coluna *Escreve* da §7."""
    if not MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    from test_acesso import POLITICA
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    tabelas = sorted({f"{n['schema']}.{n.get('alias') or n['name']}" for n in manifest["nodes"].values()
                      if n["resource_type"] in ("model", "seed", "snapshot")}
                     | {f"{s['schema']}.{s['identifier']}" for s in manifest["sources"].values()})
    comandos = renderizar(manifest["nodes"], manifest["sources"], list(POLITICA), tabelas)
    criam = {}
    for c in comandos:
        if c.startswith("grant create on schema "):
            schema, papeis = c.removeprefix("grant create on schema ").split(" to ")
            criam[schema] = sorted(papeis.split(", "))
    assert criam == {schema: sorted(regra["escreve"]) for schema, regra in POLITICA.items()}
    revogam = {(c.split(" ")[4], c.split(" ")[6]) for c in comandos if c.startswith("revoke create on schema ")}
    assert ("consumption", "analyst") in revogam and ("raw", "streamer") in revogam
