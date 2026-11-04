"""Os trechos que `make catalog` escreve a partir dos modelos estão em dia.

O Dicionário §1 e §2 e o inventário e o diagrama do Modelo de Dados são
derivados (ADR-0009, ADR-0014): a correção se faz no modelo ou na configuração
do gerador, e `make catalog` reescreve o documento. Sem conferência, um
derivado esquecido passava pelo `check` — o total do plano de volume ficou
atrasado da 1.5 à regeneração da v1.1.0 (592e2cc). Não precisa de banco.
"""

from __future__ import annotations

import re
import subprocess

import pytest

from mvp_ed1.models import export

#: Os trechos gerados que têm outro dono: a linhagem do Dicionário §3, escrita
#: e conferida por `lineage.py` (`lineage --check` no `make check`).
_DE_OUTRO_DONO = {(export.DICIONARIO, 1)}


def _rastreados() -> list:
    """Todo Markdown rastreado pelo Git, onde quer que esteja (RV19-2-02)."""
    saida = subprocess.run(["git", "ls-files", "-z", "*.md"], cwd=export.ROOT,
                           capture_output=True, check=True).stdout.decode("utf-8")
    return sorted(export.ROOT / nome for nome in saida.split("\0") if nome)


def _pares(caminho, texto: str) -> int:
    """Quantos trechos o documento tem, lidos marcador a marcador.

    Contar só os pares completos deixava sumir um marcador sem par — um `FIM`
    apagado à mão levava o trecho junto, e a declaração que o perdesse passava
    (RV19-2-01). A sequência tem de alternar início e fim, começando no início.

    **Limite:** a leitura é dos marcadores literais, os mesmos que `_substituir`
    escreve. Um trecho cujos **dois** marcadores foram desfigurados — quebrados
    em linhas, por exemplo — deixa de ser trecho para o gerador e para esta
    conferência, e passa como texto comum; basta um deles inteiro para a sequência
    acusar (RV19-3-01, aceita como limite).
    """
    marcas = re.findall(re.escape(export.INICIO) + "|" + re.escape(export.FIM), texto)
    esperada = [export.INICIO, export.FIM] * (len(marcas) // 2)
    assert marcas == esperada, f"{caminho}: marcadores fora de par ou de ordem: {len(marcas)} marca(s)"
    return len(esperada) // 2


def _marcados() -> set:
    """Todo trecho entre marcadores no repositório, contado nos documentos — não na declaração."""
    return {
        (caminho, n)
        for caminho in _rastreados()
        for n in range(_pares(caminho, caminho.read_text(encoding="utf-8")))
    }


def test_trechos_gerados_estao_em_dia():
    assert export.desatualizados() == [], "rode `make catalog` e commite os documentos"


def test_todo_trecho_marcado_esta_declarado_uma_vez():
    """A conferência acima passa vazia se `TRECHOS` perder uma entrada (RV19-05).

    O inventário vem dos marcadores nos documentos: um trecho marcado que nenhum
    gerador declara, ou declarado duas vezes, é acusado aqui.
    """
    declarados = [(caminho, n) for caminho, n, _ in export.TRECHOS]
    assert len(declarados) == len(set(declarados)), "trecho declarado mais de uma vez"
    assert set(declarados) | _DE_OUTRO_DONO == _marcados()
    assert not set(declarados) & _DE_OUTRO_DONO


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


@pytest.mark.parametrize("marcas, pares", [
    ("", 0),
    ("I x F", 1),
    ("I x F I y F", 2),
])
def test_pares_conta_trechos_completos(marcas, pares):
    texto = marcas.replace("I", export.INICIO).replace("F", export.FIM)
    assert _pares("doc.md", texto) == pares


@pytest.mark.parametrize("marcas", [
    "I x F I y",      # o último fim apagado: o trecho sumia do inventário
    "I x F I",        # um início órfão no fim
    "F x I",          # fora de ordem
    "I x I y F F",    # aninhado
    "I x F F",        # um fim a mais
])
def test_contraprova_marcador_sem_par_e_acusado(marcas):
    texto = marcas.replace("I", export.INICIO).replace("F", export.FIM)
    with pytest.raises(AssertionError, match="fora de par ou de ordem"):
        _pares("doc.md", texto)
