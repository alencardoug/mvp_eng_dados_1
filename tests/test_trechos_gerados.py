"""Os trechos que `make catalog` escreve a partir dos modelos estão em dia.

O Dicionário §1 e §2 e o inventário e o diagrama do Modelo de Dados são
derivados (ADR-0009, ADR-0014): a correção se faz no modelo ou na configuração
do gerador, e `make catalog` reescreve o documento. Sem conferência, um
derivado esquecido passava pelo `check` — o total do plano de volume ficou
atrasado da 1.5 à regeneração da v1.1.0 (592e2cc). Não precisa de banco.
"""

from __future__ import annotations

from mvp_ed1.models import export


def test_trechos_gerados_estao_em_dia():
    assert export.desatualizados() == [], "rode `make catalog` e commite os documentos"


def test_contraprova_trecho_divergente_e_acusado(tmp_path, monkeypatch):
    documento = tmp_path / "doc.md"
    documento.write_text(f"antes\n{export.INICIO}\nvelho\n{export.FIM}\ndepois\n", encoding="utf-8")
    monkeypatch.setattr(export, "ROOT", tmp_path)
    monkeypatch.setattr(export, "TRECHOS", ((documento, 0, lambda: "novo"),))
    assert export.desatualizados() == ["doc.md (trecho 1)"]
    monkeypatch.setattr(export, "TRECHOS", ((documento, 0, lambda: "velho"),))
    assert export.desatualizados() == []


def test_contraprova_trecho_ausente_e_acusado(tmp_path, monkeypatch):
    documento = tmp_path / "doc.md"
    documento.write_text("sem marcadores\n", encoding="utf-8")
    monkeypatch.setattr(export, "ROOT", tmp_path)
    monkeypatch.setattr(export, "TRECHOS", ((documento, 0, lambda: "novo"),))
    assert export.desatualizados() == ["doc.md (trecho 1)"]
