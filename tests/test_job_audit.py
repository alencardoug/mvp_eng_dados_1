"""Nenhum POST indevido: os jobs da conexão legada contra o livro (Etapa 13, G2.1)."""

from __future__ import annotations

import pytest

from mvp_ed1.recovery import job_audit, ledger


def _livro(*tentativas: tuple[str, int | None, int | None], antes=(1, 2)):
    registros = [{"kind": "baseline", "airbyte_jobs": [{"id": j} for j in antes]}]
    for tentativa, job, associado in tentativas:
        registro = {"kind": ledger.ATTEMPT, "capture_attempt_id": tentativa, "job_id": job}
        if associado is not None:
            registro["associated_job"] = associado
        registros.append(registro)
    return registros


def _jobs(*ids: int):
    return [{"id": j} for j in ids]


def test_o_ciclo_da_terca_passa():
    # Primeira captura (3), a interrompida que a recuperação registrou com o job dela (4) e a
    # segunda (5): a interrompida tem o registro de tentativa e o de transição, uma tentativa só.
    livro = _livro(("a", 3, None), ("b", 4, None), ("c", 5, None))
    livro.append({"kind": ledger.TRANSITION, "capture_attempt_id": "b", "job_id": 4})
    relatorio = job_audit.audit(livro, _jobs(1, 2, 3, 4, 5))
    assert relatorio == {"jobs_before": 2, "jobs_since_baseline": 3, "attempts_with_job": 3, "problems": []}


def test_job_sem_tentativa_e_post_indevido():
    relatorio = job_audit.audit(_livro(("a", 3, None)), _jobs(1, 2, 3, 6))
    assert relatorio["problems"] == ["job 6 da conexão legada sem tentativa no livro (POST indevido)"]


def test_o_job_associado_pela_reconciliacao_conta():
    assert job_audit.audit(_livro(("a", None, 3)), _jobs(1, 2, 3))["problems"] == []


def test_job_de_duas_tentativas_e_job_que_o_airbyte_nao_lista():
    problemas = job_audit.audit(_livro(("a", 3, None), ("b", 3, None), ("c", 9, None)), _jobs(1, 2, 3))["problems"]
    assert problemas == ["job 3 citado por 2 tentativas: ['a', 'b']", "job 9 no livro e não no Airbyte"]


def test_sem_linha_de_base_unica_recusa():
    with pytest.raises(ledger.LedgerError):
        job_audit.audit([{"kind": ledger.ATTEMPT, "capture_attempt_id": "a", "job_id": 3}], _jobs(3))
