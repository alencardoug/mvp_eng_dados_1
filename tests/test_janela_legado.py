"""As duas capturas da janela: as mutações declaradas e a matriz do diário no BigQuery (§7.2; ADR-0045)."""

from __future__ import annotations

import json
import pathlib

import pytest

from mvp_ed1.gcp import mutacoes_janela
from mvp_ed1.legacy import armazem as dialeto
from mvp_ed1.legacy import diario, mutacoes, schema

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MAKEFILE = (RAIZ / "Makefile").read_text(encoding="utf-8")


def test_a_declaracao_cobre_remocao_insercao_e_alteracao_em_tabelas_do_legado():
    itens = mutacoes_janela.declaradas()
    assert {op for op, _ in itens} == set(mutacoes_janela.OPERACOES)
    for operacao, argumentos in itens:
        assert argumentos["tabela"] in schema.tabelas()
        if operacao == "remover":
            assert argumentos.get("quantidade"), "a escolha é do oráculo, entre as aptas"
        if operacao == "inserir":
            assert set(argumentos["valores"]) <= set(schema.colunas(argumentos["tabela"]))


LOTE = {"tabelas": {"brands": {"linhas": 1, "hash": "h-brands-0"}, "customers": {"linhas": 75, "hash": "h-cust-0"}}}


def _manifesto(tmp_path, diario_atual):
    caminho = tmp_path / "manifesto.json"
    caminho.write_text(json.dumps({"lote": LOTE, "mutacoes": diario_atual}), encoding="utf-8")
    return caminho


class Banco:
    """O legado simulado: o hash de cada tabela muda a cada mutação, como no banco."""

    def __init__(self):
        self.hashes = {t: v["hash"] for t, v in LOTE["tabelas"].items()}
        self.falhar_em: int | None = None
        self.aplicadas: list[str] = []

    def mutacao(self, nome):
        def aplicar(_engine, tabela, *args, manifesto, **kwargs):
            if self.falhar_em is not None and len(self.aplicadas) + 1 == self.falhar_em:
                raise ValueError("falha simulada")
            antes = self.hashes[tabela]
            self.hashes[tabela] = f"{antes}+{nome}"
            self.aplicadas.append(f"{nome} {tabela}")
            registro = {"tipo": nome, "tabela": tabela, "presenca_apos_commit": {},
                        "hash_antes": {"hash": antes}, "hash_depois": {"hash": self.hashes[tabela]}}
            conteudo = json.loads(manifesto.read_text(encoding="utf-8"))
            conteudo["mutacoes"].append(registro)
            manifesto.write_text(json.dumps(conteudo), encoding="utf-8")
            return registro
        return aplicar


@pytest.fixture
def banco(monkeypatch):
    b = Banco()
    for nome in mutacoes_janela.OPERACOES:
        monkeypatch.setattr(mutacoes, nome, b.mutacao(nome))
    return b


def _aplicar(banco, manifesto):
    return mutacoes_janela.aplicar(None, manifesto, mutacoes_janela.declaradas(),
                                   hash_atual=lambda _e, tabela: banco.hashes[tabela])


def test_cada_mutacao_vai_para_o_manifesto_dado(tmp_path, banco):
    manifesto = _manifesto(tmp_path, [])
    assert len(_aplicar(banco, manifesto)) == len(mutacoes_janela.declaradas())
    assert banco.aplicadas == [f"{op} {a['tabela']}" for op, a in mutacoes_janela.declaradas()]
    assert len(json.loads(manifesto.read_text())["mutacoes"]) == len(mutacoes_janela.declaradas())


def test_com_o_diario_completo_nada_se_aplica(tmp_path, banco):
    manifesto = _manifesto(tmp_path, [])
    _aplicar(banco, manifesto)
    banco.aplicadas.clear()
    assert _aplicar(banco, manifesto) == [] and banco.aplicadas == []


@pytest.mark.parametrize("falha", [1, 2, 3, 4])
def test_falha_no_meio_retoma_sem_repetir_as_feitas(tmp_path, banco, falha):
    """RV13J-1-04: a segunda execução aplica só as que faltam, e o diário fica com todas uma vez."""
    manifesto = _manifesto(tmp_path, [])
    banco.falhar_em = falha
    with pytest.raises(mutacoes_janela.Recusa, match="falha simulada"):
        _aplicar(banco, manifesto)
    feitas = list(banco.aplicadas)
    banco.falhar_em = None
    _aplicar(banco, manifesto)
    declaradas = [f"{op} {a['tabela']}" for op, a in mutacoes_janela.declaradas()]
    assert banco.aplicadas == declaradas and feitas == declaradas[:falha - 1]
    assert [(m["tipo"], m["tabela"]) for m in json.loads(manifesto.read_text())["mutacoes"]] == [
        (op, a["tabela"]) for op, a in mutacoes_janela.declaradas()]


def test_mudanca_fora_do_diario_recusa(tmp_path, banco):
    """A mutação confirmada cujo diário não foi gravado: o hash do banco não é o do diário."""
    manifesto = _manifesto(tmp_path, [])
    banco.hashes["brands"] = "mexido"
    with pytest.raises(mutacoes_janela.Recusa, match="mudou fora do diário"):
        _aplicar(banco, manifesto)
    assert banco.aplicadas == []


@pytest.mark.parametrize("diario_atual, motivo", [
    ([{"tipo": "inserir", "tabela": "brands"}], "não é o diário da janela"),
    ([{"tipo": "remover", "tabela": "brands", "erro": "sobreviveram"}], "registrou erro"),
    ([{"tipo": "remover", "tabela": "brands"}] * 5, "não é o diário da janela"),
])
def test_diario_que_nao_e_prefixo_da_declaracao_recusa(tmp_path, banco, diario_atual, motivo):
    with pytest.raises(mutacoes_janela.Recusa, match=motivo):
        _aplicar(banco, _manifesto(tmp_path, diario_atual))
    assert banco.aplicadas == []


def test_as_quantidades_cabem_nas_aptas_da_geracao_declarada():
    """A geração da janela é a declarada (a do legado local): remover mais do que as aptas falharia."""
    caminho = RAIZ / "data" / "legacy" / "manifesto.json"
    if not caminho.exists():
        pytest.skip("sem o manifesto do lote local (make seed-legacy)")
    oraculo = json.loads(caminho.read_text(encoding="utf-8"))
    for operacao, argumentos in mutacoes_janela.declaradas():
        if operacao == "remover":
            assert argumentos["quantidade"] <= len(mutacoes.aptas(oraculo, argumentos["tabela"])), argumentos


def test_a_matriz_le_o_bigquery_pelo_dialeto():
    bq = dialeto.BigQuery(cliente=None, projeto="p", coordenador=None)
    pedidos = []

    def linhas(sql, parametros=None, **_):
        pedidos.append(sql)
        if "legacy_selected_capture" in sql:
            return [{"snapshot_id": 12}]
        if "max(snapshot_id)" in sql:
            return [{"anterior": 10}]
        if "distinct previous_snapshot_id" in sql:
            return [{"previous_snapshot_id": 10, "selected_snapshot_id": 12}]
        if "legacy_capture_transitions" in sql:
            return [{"source_table": "brands", "business_key": "2", "transition": "removida", "rows_after": 0},
                    {"source_table": "brands", "business_key": "9", "transition": "adicionada", "rows_after": 1}]
        return [{"source_table": "brands", "business_key": "2", "last_seen_snapshot_id": 10,
                 "removed_in_snapshot_id": 12}]

    bq.linhas = linhas
    diario_atual = [{"tipo": "remover", "tabela": "brands", "presenca_apos_commit": {"2": 0}},
                    {"tipo": "inserir", "tabela": "brands", "presenca_apos_commit": {"9": 1}}]
    assert diario.veredito(bq, diario_atual) == ("passa",)
    assert all("`p." in sql for sql in pedidos), "todo nome qualificado pelo projeto"


def test_os_alvos_da_quarta():
    def receita(alvo):
        return MAKEFILE.split(f"\n{alvo}:", 1)[1].split("\n\n", 1)[0]

    assert "$(call COMPOSER_RODAR,fluxo_batch," in receita("gcp-composer-fluxo")
    assert "$(call COMPOSER_RODAR,diagnostico_composer," in receita("gcp-composer-smoke")
    assert "$(GCP_LIMPEZA); $(GCP_ORIGENS); .venv/bin/python -m mvp_ed1.gcp.mutacoes_janela" in receita("gcp-legado-mutar")
    matriz = receita("gcp-legado-matriz")
    assert 'LEGACY_WAREHOUSE=bigquery MVP_REGISTROS_DIR="$(GCP_REGISTROS)"' in matriz
    rodar = MAKEFILE.split("\nCOMPOSER_RODAR = ", 1)[1].split("\n\n", 1)[0]
    assert "tasks states-for-dag-run" in rodar and "$(COMPOSER_EVIDENCIA)" in rodar
