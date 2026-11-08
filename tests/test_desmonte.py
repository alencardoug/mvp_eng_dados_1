"""O desmonte da janela: os planos por passo, a guarda do plano e o inventário (PLANO_etapa_13 §6.5)."""

from __future__ import annotations

import pathlib
import re
import shlex
import subprocess
import types

import pytest

from mvp_ed1.gcp import desmonte

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MAKEFILE = (RAIZ / "Makefile").read_text(encoding="utf-8")
VARIAVEIS = (RAIZ / "terraform" / "variables.tf").read_text(encoding="utf-8")


def _estado(passo: int) -> dict[str, str]:
    return dict(v.split("=", 1) for v in desmonte.variaveis(passo))


def test_a_janela_liga_todo_interruptor_do_terraform():
    interruptores = set(re.findall(r'^variable "(enable_\w+)"', VARIAVEIS, re.M))
    assert set(desmonte.JANELA) == interruptores
    assert all(desmonte.JANELA.values())


def test_todo_plano_desliga_so_variavel_que_existe():
    declaradas = set(re.findall(r'^variable "(\w+)"', VARIAVEIS, re.M))
    for plano in desmonte.PLANOS.values():
        assert set(plano.desliga) <= declaradas, plano.nome


def test_cada_passo_desmonta_o_anterior_e_mais_um():
    passos = sorted(desmonte.PLANOS)
    for anterior, seguinte in zip(passos, passos[1:]):
        antes, depois = _estado(anterior), _estado(seguinte)
        # Nada desligado volta a ligar.
        assert all(depois[k] == v for k, v in antes.items() if v in ("false", "0"))
    assert _estado(2)["enable_composer"] == "false" and _estado(2)["enable_dataflow"] == "false"
    assert _estado(2)["enable_gke_apps"] == "true" and _estado(2)["enable_cloud_sql"] == "true"
    # A retenção do livro sai no plano que leva o Cloud SQL, antes do que leva os buckets.
    assert "ledger_retention_seconds" not in _estado(5)
    assert _estado(7)["ledger_retention_seconds"] == "0" and _estado(7)["enable_cheap"] == "true"
    assert _estado(8)["enable_cheap"] == "false"
    assert all(v in ("false", "0") for v in _estado(10).values())


def test_a_ordem_dos_planos_e_a_da_secao_6_5():
    nomes = [desmonte.PLANOS[p].nome for p in sorted(desmonte.PLANOS)]
    assert nomes == sorted(nomes)
    assert [p for p, plano in desmonte.PLANOS.items() if plano.destruir] == [max(desmonte.PLANOS)]


def test_as_atribuicoes_sao_shell_valido():
    saida = subprocess.run(
        ["bash", "-c", f'eval {shlex.quote(desmonte.atribuicoes(10))}; printf "%s|%s|%s|%s" "$nome" "$modo" "$destruir" "$vars"'],
        capture_output=True, text=True, check=True).stdout
    nome, modo, destruir, variaveis = saida.split("|")
    assert (nome, modo, destruir) == ("25_desmonte_raiz", "desmonte", "-destroy")
    assert variaveis.split() == desmonte.variaveis(10)
    with pytest.raises(ValueError):
        desmonte.atribuicoes(1)


def _plano(*mudancas: tuple[str, list[str]]) -> dict:
    return {"resource_changes": [{"address": a, "change": {"actions": acoes}} for a, acoes in mudancas]}


def test_construcao_que_destroi_e_recusada_salvo_o_numero_lido():
    plano = _plano(("google_sql_database_instance.origens[0]", ["delete"]),
                   ("google_container_cluster.this[0]", ["create"]),
                   ("google_storage_bucket.this[\"livro\"]", ["delete", "create"]))
    aceito, mensagem = desmonte.conferir_plano(plano, "construcao")
    assert not aceito and "DESTROI=2" in mensagem and "origens[0]" in mensagem
    assert not desmonte.conferir_plano(plano, "construcao", destroi=1)[0]
    assert desmonte.conferir_plano(plano, "construcao", destroi=2)[0]
    assert desmonte.conferir_plano(_plano(("a.b", ["create"]), ("c.d", ["update"]), ("e.f", ["no-op"])),
                                   "construcao")[0]


def test_desmonte_que_cria_e_recusado():
    assert desmonte.conferir_plano(_plano(("a.b", ["delete"]), ("c.d", ["update"])), "desmonte")[0]
    aceito, mensagem = desmonte.conferir_plano(_plano(("a.b", ["delete"]), ("c.d", ["create"])), "desmonte")
    assert not aceito and "c.d" in mensagem
    # Substituição cria: no desmonte, também é recusada.
    assert not desmonte.conferir_plano(_plano(("a.b", ["create", "delete"])), "desmonte")[0]


def test_o_gcp_plan_passa_pela_guarda_e_o_recusado_nao_se_aplica():
    receita = MAKEFILE.split("\ngcp-plan:", 1)[1].split("\n\n", 1)[0]
    assert "mvp_ed1.gcp.desmonte conferir-plano" in receita
    assert '.tfplan" "$(GCP_PLANOS)/$$nome.tfplan.recusado"' in receita
    aplicar = MAKEFILE.split("\ngcp-apply:", 1)[1].split("\n\n", 1)[0]
    assert 'test -f "$(GCP_PLANOS)/$$nome.tfplan"' in aplicar


def _registro(tipo: str, nome: str) -> dict:
    return {"assetType": tipo, "name": nome}


def test_o_inventario_aceita_o_padrao_e_aponta_o_resto():
    recursos = [
        _registro("cloudresourcemanager.googleapis.com/Project", "//cloudresourcemanager.googleapis.com/projects/p"),
        _registro("compute.googleapis.com/Network", "//compute.googleapis.com/projects/p/global/networks/default"),
        _registro("compute.googleapis.com/Subnetwork",
                  "//compute.googleapis.com/projects/p/regions/us-east1/subnetworks/default"),
        _registro("compute.googleapis.com/Firewall", "//compute.googleapis.com/projects/p/global/firewalls/default-allow-ssh"),
        _registro("iam.googleapis.com/ServiceAccount",
                  "//iam.googleapis.com/projects/p/serviceAccounts/326395764172-compute@developer.gserviceaccount.com"),
        _registro("dataplex.googleapis.com/EntryGroup",
                  "//dataplex.googleapis.com/projects/p/locations/global/entryGroups/@bigquery"),
        # Resíduos: a rede do projeto, uma conta de papel, um disco, a linhagem.
        _registro("compute.googleapis.com/Network", "//compute.googleapis.com/projects/p/global/networks/mvp-ed1"),
        _registro("compute.googleapis.com/Subnetwork",
                  "//compute.googleapis.com/projects/p/regions/us-central1/subnetworks/mvp-ed1-us-central1"),
        _registro("iam.googleapis.com/ServiceAccount",
                  "//iam.googleapis.com/projects/p/serviceAccounts/mvp-streamer@p.iam.gserviceaccount.com"),
        _registro("compute.googleapis.com/Disk", "//compute.googleapis.com/projects/p/zones/us-central1-a/disks/pvc-1"),
        _registro("datalineage.googleapis.com/Process", "//datalineage.googleapis.com/projects/1/locations/us-central1/processes/x"),
        _registro("compute.googleapis.com/Firewall", "//compute.googleapis.com/projects/p/global/firewalls/gke-mvp-ed1-all"),
    ]
    relatorio = desmonte.inventariar(recursos)
    assert relatorio["total"] == len(recursos)
    assert sum(relatorio["aceitos"].values()) == 6
    assert {r["nome"].rsplit("/", 1)[1] for r in relatorio["residuos"]} == {
        "mvp-ed1", "mvp-ed1-us-central1", "mvp-streamer@p.iam.gserviceaccount.com", "pvc-1", "x", "gke-mvp-ed1-all"}


def test_toda_regra_do_esperado_tem_motivo():
    for regra in desmonte._esperados():
        assert regra["tipo"].count("/") == 1 and regra.get("motivo"), regra


def test_a_linhagem_e_apagada_ate_a_lista_vir_vazia(monkeypatch):
    from mvp_ed1.gcp import linhagem

    processos = {f"projects/1/locations/us-central1/processes/p{i}" for i in range(3)}
    pedidos = []

    class Sessao:
        def get(self, url, params=None, headers=None):
            assert headers == {"x-goog-user-project": "proj"}
            return types.SimpleNamespace(raise_for_status=lambda: None,
                                         json=lambda: {"processes": [{"name": n} for n in sorted(processos)]})

        def delete(self, url, headers=None, params=None):
            nome = url.split("/v1/", 1)[1]
            pedidos.append(nome)
            processos.discard(nome)
            return types.SimpleNamespace(raise_for_status=lambda: None)

    monkeypatch.setattr(linhagem, "_sessao", lambda: Sessao())
    assert desmonte.apagar_linhagem("proj", "us-central1", espera=0) == 3
    assert processos == set() and len(pedidos) == 3


def _receitas_gcp() -> dict[str, list[str]]:
    secao = MAKEFILE.split("# ── Fase GCP (Etapa 13)", 1)[1]
    receitas: dict[str, list[str]] = {}
    alvo = None
    for linha in secao.replace("\\\n", " ").splitlines():
        if linha.startswith("\t") and alvo:
            corpo = linha.strip().lstrip("@").strip()
            if not corpo.startswith("#"):
                receitas[alvo].append(corpo)
            continue
        cabecalho = re.match(r"(gcp-[a-z0-9-]+):(?!=)", linha)
        alvo = cabecalho[1] if cabecalho else None
        if alvo:
            receitas[alvo] = []
    return receitas


def test_todo_alvo_gcp_que_chama_o_gcloud_fixa_o_projeto_dele():
    receitas = _receitas_gcp()
    assert "set -a; . ./.env" not in MAKEFILE.split("# ── Fase GCP (Etapa 13)", 1)[1].replace("GCP_ENV = set -a; . ./.env", "")
    sem = [alvo for alvo, linhas in receitas.items()
           if any("gcloud " in linha or "$(GKE_KUBECTL)" in linha for linha in linhas)
           and not any(linha.startswith("$(GCP_ENV);") for linha in linhas)]
    assert sem == []
    assert 'export CLOUDSDK_CORE_PROJECT="$$GCP_PROJECT_ID"' in MAKEFILE


def test_os_alvos_da_secao_6_5_existem_e_sao_phony():
    plano = (RAIZ / "PLANO_etapa_13.md").read_text(encoding="utf-8")
    secao = plano.split("### 6.5", 1)[1].split("\n## ", 1)[0]
    citados = set(re.findall(r"`make (gcp-[a-z0-9-]+)", secao))
    alvos = set(_receitas_gcp())
    phony = MAKEFILE.split(".PHONY:", 1)[1].split("\n\n", 1)[0]
    assert citados and citados <= alvos
    assert {a for a in alvos if a.startswith(("gcp-desmonte-", "gcp-desligar-", "gcp-apagar-"))} <= set(phony.split())
    passos = set(map(int, re.findall(r"PASSO=(\d+)", secao)))
    assert passos == set(desmonte.PLANOS)


def test_o_terraform_nao_deixa_peering_nem_backup():
    rede = (RAIZ / "terraform" / "rede.tf").read_text(encoding="utf-8")
    assert 'deletion_policy = "REMOVE_PEERING"' in rede
    sql = (RAIZ / "terraform" / "cloud_sql.tf").read_text(encoding="utf-8")
    assert "retain_backups_on_delete = false" in sql


def test_o_que_e_irreversivel_pede_o_id_do_projeto():
    receitas = _receitas_gcp()
    for alvo in ("gcp-desligar-faturamento", "gcp-apagar-projeto"):
        assert receitas[alvo][0].startswith("$(GCP_ENV);")
        assert 'test "$(CONFIRMA)" = "$$GCP_PROJECT_ID"' in receitas[alvo][0]
