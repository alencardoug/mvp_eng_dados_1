"""O oráculo da memória do legado — T3 da regeneração da v1.1.0.

As transições permitidas, puras, campo a campo; e o oráculo inteiro em bancos
efêmeros, com um ciclo limpo que passa e cada caso negativo que o runbook lista
(§3.3, T3) falhando. Medido também sobre o armazém de trabalho em 04/11/2026,
só por leitura, contra uma linha de base tirada na hora: zero problemas, e o
(1b) conferindo as 14 capturas certificadas.
"""

from __future__ import annotations

import copy
import json
import uuid

import pytest
from sqlalchemy import text

from mvp_ed1.legacy import captura
from mvp_ed1.recovery import ledger
from mvp_ed1.recovery import memory_oracle as mo

from test_captura_legado import _simular_job, administradores, efemeros  # noqa: F401
from test_recuperacao_da_captura import _abrir, _capturar, _recuperar, mundo  # noqa: F401


# ── As transições, puras ─────────────────────────────────────────────────────
def _linha(tabela: str, **campos) -> dict:
    base = {"capture_attempt_id": "a", "source_table": tabela, "connection_name": "c", "job_id": None,
            "snapshot_id": None, "source_rows_before": 2, "source_hash_before": "h", "source_rows_after": None,
            "source_hash_after": None, "received_rows": None, "received_hash": None, "sync_id_matches": None,
            "status": "pending", "started_at": ["timestamptz", "t0"], "completed_at": None}
    return {**base, **campos}


PUBLICADO = {"source_rows_after": 2, "source_hash_after": "h", "received_hash": "h", "sync_id_matches": True,
             "completed_at": ["timestamptz", "t1"]}


def _publicar(job=9, snapshot=9, recebidas=2, status="complete"):
    return [_linha(t, job_id=job, status=status, snapshot_id=snapshot, received_rows=recebidas, **PUBLICADO)
            for t in ("brands", "orders")]


def test_publicar_e_permitido_com_o_snapshot_do_job() -> None:
    antes = [_linha(t, job_id=9) for t in ("brands", "orders")]
    assert mo.transition_problems("a", antes, _publicar()) == []
    assert mo.transition_problems("a", antes, _publicar(snapshot=None, recebidas=0, status="incomplete")) == []


@pytest.mark.parametrize("snapshot,recebidas", [(8, 2), (None, 2), (9, 0)])
def test_snapshot_que_nao_e_o_do_job_que_recebeu_e_recusado(snapshot, recebidas) -> None:
    antes = [_linha(t, job_id=9) for t in ("brands", "orders")]
    assert mo.transition_problems("a", antes, _publicar(snapshot=snapshot, recebidas=recebidas))


def test_abandonar_e_registrar_job_sao_permitidos() -> None:
    antes = [_linha(t) for t in ("brands", "orders")]
    abandonada = [_linha(t, status="abandoned", completed_at=["timestamptz", "t1"]) for t in ("brands", "orders")]
    assert mo.transition_problems("a", antes, abandonada) == []
    assert mo.transition_problems("a", antes, [_linha(t, job_id=9) for t in ("brands", "orders")]) == []


@pytest.mark.parametrize("campo,valor", [("source_hash_before", "outro"), ("connection_name", "x"),
                                         ("started_at", ["timestamptz", "t9"])])
def test_campo_imutavel_mudado_na_publicacao_e_recusado(campo, valor) -> None:
    antes = [_linha(t, job_id=9) for t in ("brands", "orders")]
    depois = _publicar()
    depois[0][campo] = valor
    assert any("imutável" in p for p in mo.transition_problems("a", antes, depois))


def test_linha_final_que_muda_e_recusada() -> None:
    final = _publicar()
    depois = copy.deepcopy(final)
    depois[1]["completed_at"] = ["timestamptz", "t2"]
    assert any("linha final mudou" in p for p in mo.transition_problems("a", final, depois))


def test_a_transicao_precisa_chegar_a_todas_as_linhas_e_ser_uma_so() -> None:
    antes = [_linha(t, job_id=9) for t in ("brands", "orders")]
    meio = [_publicar()[0], antes[1]]
    assert any("não chegou" in p for p in mo.transition_problems("a", antes, meio))
    misturada = [_linha("brands", job_id=9), _linha("orders", status="abandoned", completed_at=["timestamptz", "t"])]
    assert mo.transition_problems("a", [_linha(t) for t in ("brands", "orders")], misturada)


# ── O oráculo inteiro, em bancos efêmeros ────────────────────────────────────
@pytest.fixture
def memoria(mundo, tmp_path_factory, monkeypatch):
    """O mundo da recuperação com quarentena, classificação e captura selecionada, e uma época nova."""
    armazem = mundo["armazem"]
    with armazem.begin() as conexao:
        for esquema in ("staging", "trusted", "quarantine"):
            conexao.execute(text(f"create schema if not exists {esquema}"))
        colunas = ("source_system text, snapshot_id bigint, catalog_version int, treatment_fingerprint text, "
                   "source_table text, legacy_row_id bigint")
        # Como no armazém: a quarentena é `select *` das rejeitadas da classificação.
        conexao.execute(text(f"create table quarantine.rejected_legacy_records ({colunas}, classification text)"))
        conexao.execute(text(f"create table trusted.legacy_classifications ({colunas}, classification text)"))
        conexao.execute(text("create table staging.legacy_selected_capture (snapshot_id bigint)"))
    raiz = tmp_path_factory.mktemp("livro_t3")
    monkeypatch.setenv(ledger.ENV, str(raiz))
    mundo["raiz"] = raiz
    ledger.open_epoch(raiz, ledger.baseline_record(armazem, []))
    return mundo


def _tratar(memoria, job: int, linhas: int, *, versao=9, impressao="f1") -> None:
    """O que `dbt build` faz por captura: classifica, põe as rejeitadas na quarentena, seleciona."""
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("delete from trusted.legacy_classifications"))
        # A classificação tem todas as linhas da captura, aceitas também.
        conexao.execute(text("insert into trusted.legacy_classifications values "
                             "('legacy', :s, :v, :f, 'warehouses', 1, 'accepted')"),
                        {"s": job, "v": versao, "f": impressao})
        for rid in range(linhas):
            valores = {"s": job, "v": versao, "f": impressao, "r": rid}
            conexao.execute(text("insert into trusted.legacy_classifications values "
                                 "('legacy', :s, :v, :f, 'brands', :r, 'rejected')"), valores)
            conexao.execute(text("insert into quarantine.rejected_legacy_records values "
                                 "('legacy', :s, :v, :f, 'brands', :r, 'rejected')"), valores)
        conexao.execute(text("delete from staging.legacy_selected_capture"))
        conexao.execute(text("insert into staging.legacy_selected_capture values (:s)"), {"s": job})


def _registrar_tratamento(memoria, nome: str) -> None:
    ledger.publish(ledger.current_epoch(memoria["raiz"]), nome,
                   ledger.treatment_record(memoria["armazem"], caller={"kind": "test"}))


def _t3(memoria, certificadas=None) -> list[str]:
    return mo.check(ledger.records(ledger.current_epoch(memoria["raiz"])), mo.read_memory(memoria["armazem"]),
                    certificadas)


def _ciclo(memoria) -> str:
    """Uma captura certificada pelo portão, tratada e registrada: o estado limpo da D4."""
    tentativa = _capturar(memoria, 901, 1)
    _tratar(memoria, 901, 1)
    _registrar_tratamento(memoria, "D3_a1_tratamento.json")
    return tentativa


@pytest.mark.integracao
def test_o_ciclo_limpo_passa(memoria) -> None:
    _ciclo(memoria)
    assert _t3(memoria, [901]) == []


@pytest.mark.integracao
def test_a_pendente_finalizada_pela_recuperacao_passa(memoria) -> None:
    _capturar(memoria, 901, 1, registrar=False)
    _recuperar(memoria)
    _tratar(memoria, 901, 0)
    assert _t3(memoria, [901]) == []


@pytest.mark.integracao
def test_linhas_de_uma_tentativa_falha_apagadas(memoria) -> None:
    tentativa = _capturar(memoria, 901, 1, registrar=False)
    with memoria["armazem"].begin() as conexao:  # o bruto do job some de uma tabela: incompleta
        conexao.execute(text("delete from raw_legacy.warehouses where _airbyte_meta->>'sync_id' = '901'"))
    captura.concluir(memoria["legado"], memoria["armazem"], tentativa)
    ledger.gate(memoria["armazem"], tentativa, caller={})
    assert _t3(memoria, []) == []
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("delete from raw_legacy.brands where _airbyte_meta->>'sync_id' = '901'"))
    problemas = _t3(memoria, [])
    assert any("brands: rows 2 → 0" in p for p in problemas), problemas


@pytest.mark.integracao
def test_linhas_de_uma_pendente_apagadas_antes_da_recuperacao_que_a_finaliza(memoria) -> None:
    tentativa = _capturar(memoria, 901, 1, registrar=False)
    ledger.publish(ledger.current_epoch(memoria["raiz"]), f"dag_x_{tentativa}_attempt.json",
                   ledger.attempt_record(memoria["armazem"], tentativa, caller={}))
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("delete from raw_legacy.brands where _airbyte_meta->>'sync_id' = '901'"))
    _recuperar(memoria)  # finaliza: o registro de transição mede o bruto já sem as linhas
    assert any("entre o registro attempt e o transition" in p for p in _t3(memoria, []))


@pytest.mark.integracao
def test_source_hash_before_mudado_na_finalizacao(memoria) -> None:
    tentativa = _capturar(memoria, 901, 1, registrar=False)
    ledger.publish(ledger.current_epoch(memoria["raiz"]), f"dag_x_{tentativa}_attempt.json",
                   ledger.attempt_record(memoria["armazem"], tentativa, caller={}))
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text(f"update {ledger.CERTIFICATE} set source_hash_before = 'outro'"))
    # A recuperação pararia na barreira; o certificado é finalizado à mão, com a troca.
    captura.concluir(memoria["legado"], memoria["armazem"], tentativa)
    ledger.publish(ledger.current_epoch(memoria["raiz"]), f"recovery_{tentativa}_transition.json",
                   ledger.attempt_record(memoria["armazem"], tentativa, caller={}, kind=ledger.TRANSITION))
    assert any("imutável" in p and "source_hash_before" in p for p in _t3(memoria))


@pytest.mark.integracao
def test_completed_at_mudado_depois_do_registro_da_transicao(memoria) -> None:
    _capturar(memoria, 901, 1, registrar=False)
    _recuperar(memoria)
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text(f"update {ledger.CERTIFICATE} set completed_at = completed_at + interval '1 second'"))
    assert any("difere do último registro (transition)" in p for p in _t3(memoria))


@pytest.mark.integracao
def test_snapshot_id_que_nao_e_o_do_job(memoria) -> None:
    tentativa = _capturar(memoria, 901, 1, registrar=False)
    ledger.publish(ledger.current_epoch(memoria["raiz"]), f"dag_x_{tentativa}_attempt.json",
                   ledger.attempt_record(memoria["armazem"], tentativa, caller={}))
    captura.concluir(memoria["legado"], memoria["armazem"], tentativa)
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text(f"update {ledger.CERTIFICATE} set snapshot_id = 77"))
    ledger.publish(ledger.current_epoch(memoria["raiz"]), f"recovery_{tentativa}_transition.json",
                   ledger.attempt_record(memoria["armazem"], tentativa, caller={}, kind=ledger.TRANSITION))
    assert any("snapshot_id 77" in p for p in _t3(memoria))


@pytest.mark.integracao
def test_raw_id_trocado_com_tudo_o_que_medir_recebido_le_igual(memoria) -> None:
    _ciclo(memoria)
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("update raw_legacy.brands set _airbyte_raw_id = :r where legacy_row_id = 1 "
                             "and _airbyte_meta->>'sync_id' = '901'"), {"r": uuid.uuid4().hex})
    problemas = _t3(memoria, [901])
    assert any("brands: digest" in p for p in problemas)
    assert not any("medida de novo" in p for p in problemas)  # (1b) não vê; (1) vê


@pytest.mark.integracao
def test_payload_ou_certificado_de_j_mudado(memoria) -> None:
    _ciclo(memoria)
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("update raw_legacy.brands set name = 'Outra' where legacy_row_id = 1 "
                             "and _airbyte_meta->>'sync_id' = '901'"))
    problemas = _t3(memoria, [901])
    assert any("brands: digest" in p for p in problemas) and any("medida de novo" in p for p in problemas)


@pytest.mark.integracao
def test_campo_do_certificado_de_j_mudado(memoria) -> None:
    _ciclo(memoria)
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text(f"update {ledger.CERTIFICATE} set sync_id_matches = false where source_table = 'brands'"))
    assert any("difere do último registro" in p for p in _t3(memoria, [901]))


@pytest.mark.integracao
def test_fatia_de_auditoria_anterior_que_some(memoria) -> None:
    _ciclo(memoria)
    _tratar(memoria, 901, 2, versao=10, impressao="f2")  # um tratamento posterior da mesma captura
    with memoria["armazem"].begin() as conexao:
        conexao.execute(text("delete from quarantine.rejected_legacy_records where catalog_version = 9"))
    assert any("tratamento de" in p for p in _t3(memoria, [901]))


@pytest.mark.integracao
def test_tratamento_posterior_sem_registro_e_fatia_sem_explicacao(memoria) -> None:
    _ciclo(memoria)
    with memoria["armazem"].begin() as conexao:  # uma fatia que nenhum tratamento registrado explica
        conexao.execute(text("insert into quarantine.rejected_legacy_records values "
                             "('legacy', 901, 8, 'f0', 'brands', 5, 'rejected')"))
    assert any("nem a linha de base nem um tratamento explica" in p for p in _t3(memoria, [901]))


@pytest.mark.integracao
def test_captura_que_o_livro_de_capturas_nao_nomeia(memoria) -> None:
    _ciclo(memoria)
    assert any("certificadas [901], esperadas []" in p for p in _t3(memoria, []))
    assert any("esperadas [901, 902]" in p for p in _t3(memoria, [901, 902]))


@pytest.mark.integracao
def test_sync_id_sem_tentativa_no_bruto(memoria) -> None:
    _ciclo(memoria)
    _simular_job(memoria["armazem"], memoria["legado"], job_id=960, geracao=9, tabelas=["brands"])
    assert any("sync_id 960" in p for p in _t3(memoria, [901]))


@pytest.mark.integracao
def test_a_saida_da_linha_de_comando(memoria, tmp_path, monkeypatch) -> None:
    _ciclo(memoria)
    monkeypatch.setenv("WAREHOUSE_DB_NAME", memoria["armazem"].url.database)
    livro = tmp_path / "capturas.json"
    livro.write_text(json.dumps({"certified": [901]}))
    assert mo.main(["--capture-ledger", str(livro), "--out", str(tmp_path / "t3.json")]) == 0
    assert json.loads((tmp_path / "t3.json").read_text())["ok"] is True
    livro.write_text(json.dumps({"certified": []}))
    assert mo.main(["--capture-ledger", str(livro), "--out", str(tmp_path / "t3b.json")]) == 1


# ── A memória de exclusões, com as remoções aceitas do H2 (N54) ──────────────
def _remocao(tabela: str, chave: str, payload: str = "p") -> dict:
    return {"source_table": tabela, "business_key": chave, "last_seen_snapshot_id": 55,
            "removed_in_snapshot_id": 60, "rows_last_seen": 1, "last_payload": [{"x": payload}]}


def _com_exclusoes(linhas_base, linhas_agora):
    from mvp_ed1.recovery import oraculos

    base = {"deletions": {"linhas": len(linhas_base), "digest": oraculos.digest(linhas_base)},
            "deletion_keys": sorted([r["source_table"], r["business_key"]] for r in linhas_base)}
    memoria = mo.Memory(certificate={}, captures={}, certified=[], received={}, selected=None, quarantine=None,
                        quarantine_by_table={}, classification=None, versions=[],
                        deletions={"linhas": len(linhas_agora), "digest": oraculos.digest(linhas_agora)},
                        deletion_rows=linhas_agora)
    return base, memoria


ANTIGA = _remocao("customers", "1")
ACEITAS = {("inventory_balances", "145"), ("inventory_balances", "146")}


def test_sem_aceitas_a_memoria_de_exclusoes_e_igual() -> None:
    assert mo._deletion_problems(*_com_exclusoes([ANTIGA], [ANTIGA]), None) == []
    assert mo._deletion_problems(*_com_exclusoes([ANTIGA], [ANTIGA, _remocao("inventory_balances", "145")]), None)


def test_com_aceitas_e_a_linha_de_base_mais_exatamente_elas() -> None:
    novas = [_remocao("inventory_balances", "145"), _remocao("inventory_balances", "146")]
    assert mo._deletion_problems(*_com_exclusoes([ANTIGA], [ANTIGA, *novas]), ACEITAS) == []
    sobra = _remocao("inventory_movements", "x")
    assert any("sobram [('inventory_movements', 'x')]" in p
               for p in mo._deletion_problems(*_com_exclusoes([ANTIGA], [ANTIGA, *novas, sobra]), ACEITAS))
    assert any("faltam [('inventory_balances', '146')]" in p
               for p in mo._deletion_problems(*_com_exclusoes([ANTIGA], [ANTIGA, novas[0]]), ACEITAS))
    mudada = _remocao("customers", "1", payload="outro")
    assert any("as linhas da linha de base mudaram" in p
               for p in mo._deletion_problems(*_com_exclusoes([ANTIGA], [mudada, *novas]), ACEITAS))


def test_as_remocoes_aceitas_saem_da_comparacao_do_h2() -> None:
    comparacao = {"legacy": {"keys": {
        "inventory_balances": {"changed": {"removed": ["145", "146"]}},
        "product_categories": {"changed": {"added": ["25"]}},
        "brands": {"changed": {}},
    }}}
    assert mo.accepted_removals(comparacao) == ACEITAS


# ── E com as reaparições aceitas do H2 sobre o estado real (N56) ─────────────
OUTRA = _remocao("customers", "99001")
NOVAS = [_remocao("inventory_balances", "145"), _remocao("inventory_balances", "146")]
REAPARECIDAS = {("customers", "1"), ("product_categories", "25")}


def test_a_reaparicao_aceita_tira_a_chave_e_o_resto_se_confere_por_chave() -> None:
    notas: list[str] = []
    base, memoria = _com_exclusoes([ANTIGA, OUTRA], [OUTRA, *NOVAS])
    assert mo._deletion_problems(base, memoria, ACEITAS, REAPARECIDAS, notas) == []
    assert len(notas) == 1
    assert "1 chave(s) da linha de base saíram por reaparição aceita ([('customers', '1')])" in notas[0]
    assert "por conteúdo contra a memória recalculada do bruto" in notas[0]
    assert any("faltam [('customers', '1')]" in p for p in mo._deletion_problems(base, memoria, ACEITAS))


def test_a_reaparicao_aceita_que_nao_aconteceu_e_sobra() -> None:
    base, memoria = _com_exclusoes([ANTIGA, OUTRA], [ANTIGA, OUTRA, *NOVAS])
    assert any("sobram [('customers', '1')]" in p
               for p in mo._deletion_problems(base, memoria, ACEITAS, REAPARECIDAS, []))


def test_reaparicao_fora_da_memoria_nao_dispensa_a_conferencia_do_conteudo() -> None:
    notas: list[str] = []
    mudada = _remocao("customers", "1", payload="outro")
    problemas = mo._deletion_problems(*_com_exclusoes([ANTIGA], [mudada, *NOVAS]), ACEITAS,
                                      {("product_categories", "25")}, notas)
    assert any("as linhas da linha de base mudaram" in p for p in problemas)
    assert notas == []


def test_reaparicoes_aceitas_sem_remocoes_aceitas() -> None:
    assert mo._deletion_problems(*_com_exclusoes([ANTIGA, OUTRA], [OUTRA]), None, {("customers", "1")}, []) == []


def test_as_reaparicoes_aceitas_saem_da_comparacao_sobre_o_estado_real() -> None:
    comparacao = {"legacy": {"keys": {
        "customers": {"changed": {"added": ["1", "2", "3"]}},
        "inventory_balances": {"changed": {"removed": ["145", "146"]}},
        "brands": {"changed": {}},
    }}}
    assert mo.accepted_reappearances(comparacao) == {("customers", "1"), ("customers", "2"), ("customers", "3")}


# ── O conteúdo da memória de exclusões, contra a recalculada do bruto (RVL1-01/02) ──
def _so_exclusoes(linhas, esperadas):
    return mo.Memory(certificate={}, captures={}, certified=[], received={}, selected=None, quarantine=None,
                     quarantine_by_table={}, classification=None, versions=[], deletions=None,
                     deletion_rows=linhas, expected_deletion_rows=esperadas)


def test_o_conteudo_igual_ao_recalculado_passa_e_o_payload_e_multiconjunto() -> None:
    linha = {**_remocao("customers", "99001"), "last_payload": [{"x": "a"}, {"x": "b"}]}
    invertida = {**linha, "last_payload": [{"x": "b"}, {"x": "a"}]}
    assert mo.deletion_content_problems(_so_exclusoes([linha], [invertida])) == []
    assert mo.deletion_content_problems(_so_exclusoes(None, None)) == [], "sem a tabela, como no resto do T3"


def test_sem_o_recalculado_o_conteudo_nao_se_prova() -> None:
    problemas = mo.deletion_content_problems(_so_exclusoes([ANTIGA], None))
    assert problemas and "não se prova" in problemas[0]


@pytest.mark.parametrize("campo, valor", [
    ("last_payload", [{"x": "ADULTERADO"}]),          # RVL1-01: a linha que resta depois da reaparição
    ("last_payload", [{"x": "p"}, {"x": "p"}]),       # multiplicidade do payload
    ("rows_last_seen", 999),
    ("removed_in_snapshot_id", -999),                 # RVL1-02: uma remoção aceita
    ("last_seen_snapshot_id", 54),
])
def test_conteudo_adulterado_com_a_chave_intacta_e_acusado(campo, valor) -> None:
    adulterada = {**ANTIGA, campo: valor}
    problemas = mo.deletion_content_problems(_so_exclusoes([adulterada], [ANTIGA]))
    assert problemas == [f"memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: "
                         f"[(('customers', '1'), ['{campo}'])]"]


def test_chave_a_mais_ou_a_menos_que_o_recalculado_e_acusada() -> None:
    outra = _remocao("inventory_balances", "145")
    assert "sobram [('inventory_balances', '145')]" in mo.deletion_content_problems(_so_exclusoes([ANTIGA, outra], [ANTIGA]))[0]
    assert "faltam [('inventory_balances', '145')]" in mo.deletion_content_problems(_so_exclusoes([ANTIGA], [ANTIGA, outra]))[0]
