"""As policy tags das colunas: a regra, a convergência das fontes e o inventário (Etapa 13, G4; D71, D79)."""

from __future__ import annotations

import json
import pathlib

import pytest
from google.cloud.bigquery import PolicyTagList, SchemaField

from mvp_ed1.gcp import politicas

TAGS = {"confidential": "projects/p/locations/l/taxonomies/1/policyTags/10",
        "personal": "projects/p/locations/l/taxonomies/1/policyTags/20"}

MANIFEST = {
    "sources": {
        "source.x.raw.customers": {"schema": "raw", "identifier": "customers", "name": "customers", "columns": {
            "customer_id": {"meta": {"sensitivity": "internal"}},
            "email": {"meta": {"sensitivity": "personal"}},
        }},
    },
    "nodes": {
        "model.x.dim_customer": {"resource_type": "model", "schema": "analytics", "alias": "dim_customer",
                                 "name": "dim_customer", "config": {"materialized": "table"}, "columns": {
                                     "email": {"meta": {"sensitivity": "personal"}}}},
        "model.x.v": {"resource_type": "model", "schema": "consumption", "alias": "v", "name": "v",
                      "config": {"materialized": "view"}, "columns": {"x": {"meta": {"sensitivity": "personal"}}}},
    },
}


class _Tabela:
    def __init__(self, schema):
        self.schema = schema


class _Cliente:
    def __init__(self, tabelas):
        self.tabelas = tabelas
        self.atualizadas = []

    def get_table(self, nome):
        from google.api_core import exceptions as gexc

        chave = nome.split(".", 1)[1]
        if chave not in self.tabelas:
            raise gexc.NotFound(nome)
        return self.tabelas[chave]

    def update_table(self, tabela, campos):
        self.atualizadas.append((tabela, campos))


def _campo(nome, tag=None):
    return SchemaField(nome, "STRING", policy_tags=PolicyTagList([tag]) if tag else None)


def test_so_confidential_e_personal_levam_tag():
    assert politicas.esperado("personal", TAGS) == [TAGS["personal"]]
    assert politicas.esperado("confidential", TAGS) == [TAGS["confidential"]]
    assert politicas.esperado("internal", TAGS) == [] and politicas.esperado("public", TAGS) == []
    assert politicas.esperado(None, TAGS) == []


def test_views_nao_entram_e_fontes_e_modelos_sim():
    donos = {(t.dataset, t.nome): t.dono for t in politicas.tabelas(MANIFEST)}
    assert donos == {("raw", "customers"): "fonte", ("analytics", "dim_customer"): "dbt"}


def test_convergir_marca_e_desmarca_so_as_fontes():
    cliente = _Cliente({
        "raw.customers": _Tabela([_campo("customer_id", TAGS["personal"]), _campo("email"),
                                  _campo("_airbyte_raw_id")]),
        "analytics.dim_customer": _Tabela([_campo("email")]),
    })
    rel = politicas.percorrer(cliente, "p", MANIFEST, TAGS, corrigir=True, so_fontes=True)
    assert len(cliente.atualizadas) == 1
    schema = {c.name: (list(c.policy_tags.names) if c.policy_tags else []) for c in cliente.atualizadas[0][0].schema}
    # `internal` perde a tag que não devia ter; `personal` ganha a sua; a coluna do carregador fica como está.
    assert schema == {"customer_id": [], "email": [TAGS["personal"]], "_airbyte_raw_id": []}
    assert len(rel.trocadas) == 2 and not rel.sem_classificacao


def test_o_inventario_acusa_sem_escrever_inclusive_nos_modelos():
    cliente = _Cliente({
        "raw.customers": _Tabela([_campo("customer_id"), _campo("email", TAGS["personal"])]),
        "analytics.dim_customer": _Tabela([_campo("email"), _campo("coluna_nova")]),
    })
    rel = politicas.percorrer(cliente, "p", MANIFEST, TAGS, corrigir=False, so_fontes=False)
    assert cliente.atualizadas == []
    assert rel.divergentes == ["analytics.dim_customer.email: — → ['projects/p/locations/l/taxonomies/1/policyTags/20']"]
    assert rel.sem_classificacao == ["analytics.dim_customer.coluna_nova"]


def test_o_convergir_nunca_reescreve_tabela_do_dbt():
    cliente = _Cliente({"raw.customers": _Tabela([_campo("customer_id"), _campo("email", TAGS["personal"])]),
                        "analytics.dim_customer": _Tabela([_campo("email")])})
    rel = politicas.percorrer(cliente, "p", MANIFEST, TAGS, corrigir=True, so_fontes=False)
    assert cliente.atualizadas == [] and rel.divergentes  # acusada, não corrigida: quem marca é o dbt (D71)


def test_mapa_incompleto_recusa():
    with pytest.raises(SystemExit, match="personal"):
        politicas.tags_do_ambiente({"MVP_POLICY_TAGS": json.dumps({"confidential": "x"})})


def test_a_classificacao_real_tem_tabela_e_coluna_a_marcar():
    manifest = json.loads(pathlib.Path("dbt/target/manifest.json").read_text(encoding="utf-8"))
    todas = politicas.tabelas(manifest)
    marcadas = [c for t in todas for c, n in t.niveis.items() if n in politicas.NIVEIS_MARCADOS]
    assert {t.dataset for t in todas if t.dono == "fonte"} == set(politicas.DATASETS_DAS_FONTES)
    assert len(marcadas) > 300


def test_o_workflow_so_roda_na_janela_e_sem_chave():
    texto = pathlib.Path(".github/workflows/policy-tags.yml").read_text(encoding="utf-8")
    assert "if: vars.MVP_GCP_ATIVO == 'true'" in texto
    assert "id-token: write" in texto and "credentials_json" not in texto
    import re
    usos = re.findall(r"uses: (\S+)", texto)
    assert usos and all(re.search(r"@[0-9a-f]{40}$", u) for u in usos), usos


def test_o_repositorio_do_fluxo_no_terraform_e_este():
    tf = pathlib.Path("terraform/politicas.tf").read_text(encoding="utf-8")
    assert 'repositorio_do_fluxo = "alencardoug/mvp_eng_dados_1"' in tf
    assert "assertion.ref == 'refs/heads/main'" in tf


@pytest.mark.parametrize("comando", ["inventario", "convergir"])
@pytest.mark.parametrize("presentes", [{}, {"analytics.dim_customer": _Tabela([_campo("email", TAGS["personal"])])}])
def test_tabela_declarada_ausente_falha_nos_dois_comandos(comando, presentes, monkeypatch, tmp_path, capsys):
    """RV13J-1-06: `0 divergências` sobre tabelas que faltam seria aprovar o vazio."""
    from google.cloud import bigquery

    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps(MANIFEST), encoding="utf-8")
    monkeypatch.setenv("GCP_PROJECT_ID", "p")
    monkeypatch.setenv("MVP_POLICY_TAGS", json.dumps(TAGS))
    monkeypatch.setattr(bigquery, "Client", lambda **_: _Cliente(dict(presentes)))
    assert politicas.main([comando, "--manifest", str(manifest)]) == 1
    assert "AUSENTE — raw.customers" in capsys.readouterr().err


def test_sem_ausente_nem_divergencia_o_inventario_passa(monkeypatch, tmp_path):
    from google.cloud import bigquery

    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps(MANIFEST), encoding="utf-8")
    monkeypatch.setenv("GCP_PROJECT_ID", "p")
    monkeypatch.setenv("MVP_POLICY_TAGS", json.dumps(TAGS))
    tabelas = {"raw.customers": _Tabela([_campo("customer_id"), _campo("email", TAGS["personal"])]),
               "analytics.dim_customer": _Tabela([_campo("email", TAGS["personal"])])}
    monkeypatch.setattr(bigquery, "Client", lambda **_: _Cliente(tabelas))
    assert politicas.main(["inventario", "--manifest", str(manifest)]) == 0
