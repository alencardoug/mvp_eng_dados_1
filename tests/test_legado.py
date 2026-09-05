"""A origem legada é declarativa, determinística e cobre o catálogo inteiro.

São testes do **gerador**, não do tratamento: o que se verifica aqui é que o
defeito é produzido conforme declarado, e que o manifesto descreve o que foi
feito. Se estes falharem, nenhum teste de limpeza adiante significa coisa
alguma — estaria medindo um oráculo errado.
"""

from __future__ import annotations

import collections
import re

import pytest
import yaml

from mvp_ed1.generator import pipeline
from mvp_ed1.generator.config import carregar as carregar_config
from mvp_ed1.generator.engine import Motor
from mvp_ed1.legacy import injetor, schema
from mvp_ed1.legacy.catalogo import CAMINHO, CatalogoInvalido, carregar


@pytest.fixture(scope="module")
def catalogo():
    return carregar()


@pytest.fixture(scope="module")
def promessas() -> frozenset[str]:
    return frozenset(yaml.safe_load(CAMINHO.read_text(encoding="utf-8"))["promessas"])


def _gerar(catalogo, promessas):
    motor = Motor(carregar_config(), seed=catalogo.semente, as_of_date=None, fator=catalogo.fator)
    dataset = pipeline.gerar(motor)
    dados = {tabela: dataset[tabela] for tabela in dataset}
    return injetor.injetar(catalogo, dados, promessas=promessas, as_of=motor.as_of_date)


@pytest.fixture(scope="module")
def resultado(catalogo, promessas):
    return _gerar(catalogo, promessas)


def test_catalogo_carrega_e_valida(catalogo) -> None:
    """A declaração é revisada integralmente (`CLAUDE.md` §5); carregá-la a valida."""
    assert catalogo.falhas, "catálogo vazio"
    for falha in catalogo.falhas.values():
        assert bool(falha.conversao) != bool(falha.rejeicao), (
            f"{falha.codigo}: converte **ou** rejeita, nunca ambos nem nenhum"
        )


def test_catalogo_recusa_falha_sem_tratamento(tmp_path) -> None:
    """Um catálogo incoerente falha na carga, não na hora de tratar o registro."""
    quebrado = tmp_path / "catalogo.yml"
    quebrado.write_text(
        "versao: 1\n"
        "geracao: {semente: 1, fator: 0.05}\n"
        "delimitador: ';'\n"
        "nulos_disfarcados: ['-']\n"
        "promessas: []\n"
        "falhas:\n"
        "  SEM_TRATAMENTO:\n"
        "    grupo: teste\n"
        "    arquetipo: texto\n"
        "    deteccao: qualquer coisa\n"
        "    injecao: {frequencia: 1, formas: [espaco_a_volta]}\n",
        encoding="utf-8",
    )
    with pytest.raises(CatalogoInvalido, match="conversão"):
        carregar(quebrado)


def test_todo_arquetipo_injetavel_alcanca_alguma_coluna(catalogo, promessas) -> None:
    """Arquétipo que não alcança coluna é regra morta — falha declarada sem alvo."""
    estruturais = {"registro", "chave_natural", "total_do_pedido", "registro_filho"}
    arquetipos = {
        schema.arquetipo(t, c, promessas) for t in schema.tabelas() for c in schema.colunas(t)
    }
    for falha in catalogo.injetaveis:
        if falha.arquetipo in estruturais:
            continue
        assert any(schema.alcanca(falha.arquetipo, a) for a in arquetipos), (
            f"{falha.codigo}: arquétipo {falha.arquetipo!r} não alcança coluna nenhuma"
        )


def test_toda_forma_declarada_tem_implementacao(catalogo) -> None:
    """Forma no YAML sem função é falha na injeção, não defeito silencioso."""
    de_linha = {"absorve_os_seguintes", "linha_repetida", "mesma_chave_outro_atributo",
                "total_alterado"}
    declaradas = {forma for falha in catalogo.injetaveis for forma in falha.formas}
    implementadas = {nome[1:] for nome in injetor.FORMAS}
    assert declaradas - implementadas == de_linha


def test_piso_de_cobertura_todos_os_codigos_presentes(catalogo, resultado) -> None:
    """ADR-0014: **todo** tipo representado em qualquer escala.

    Um tipo sem registro gerado é um tratamento sem teste — e o fator do legado
    é pequeno de propósito, o que torna este piso a única garantia de que a
    escala reduzida não silencia uma falha.
    """
    presentes = {a.codigo for a in resultado.achados}
    ausentes = [f.codigo for f in catalogo.injetaveis if f.codigo not in presentes]
    assert not ausentes, f"sem cobertura no fator declarado: {ausentes}"


def test_geracao_e_deterministica(catalogo, promessas, resultado) -> None:
    """Mesma semente, mesmo resultado: é o que torna o manifesto um oráculo."""
    segunda = _gerar(catalogo, promessas)
    assert [
        (a.tabela, a.legacy_row_id, a.codigo, a.valor_legado) for a in resultado.achados
    ] == [(a.tabela, a.legacy_row_id, a.codigo, a.valor_legado) for a in segunda.achados]


def test_precedencia_rejeicao_vence_conversao(resultado) -> None:
    """Origem Legada §3.1.1: todos os achados registrados, ocorrência contada uma vez."""
    veredito = resultado.resultado_por_ocorrencia()
    por_ocorrencia: dict[tuple[str, int], list[str]] = collections.defaultdict(list)
    for a in resultado.achados:
        por_ocorrencia[(a.tabela, a.legacy_row_id)].append(a.resultado_esperado)

    assert set(veredito) == set(por_ocorrencia), "ocorrência com achado e sem veredito"
    for chave, esperados in por_ocorrencia.items():
        if injetor.REJEITADO in esperados:
            assert veredito[chave] == injetor.REJEITADO, f"{chave}: rejeição precisa vencer"


def test_identidade_fisica_e_unica_por_tabela(resultado) -> None:
    """Duas linhas idênticas precisam ser distinguíveis (ADR-0038)."""
    for tabela, linhas in resultado.linhas.items():
        ids = [linha[schema.IDENTIDADE] for linha in linhas]
        assert len(ids) == len(set(ids)), f"{tabela}: identidade física repetida"


def test_duplicata_exata_produz_linha_a_mais_e_so_a_excedente_e_rejeitada(resultado) -> None:
    """A canônica segue empilhável; cada excedente é uma rejeição própria."""
    excedentes = [a for a in resultado.achados if a.codigo == "DUP_EXACT"]
    assert excedentes, "sem duplicata exata gerada"
    for a in excedentes:
        assert a.resultado_esperado == injetor.REJEITADO
        canonica, copia = int(a.valor_original), int(a.valor_legado)
        assert canonica < copia, "a canônica é a de menor identificador físico"


def test_schema_legado_nao_tem_constraint_que_recuse_defeito() -> None:
    """Coluna tipada rejeitaria o exemplo antes de a limpeza existir.

    A busca é por **palavra**, e não por substring: `references` aparece dentro
    de `customer_preferences`, e a primeira versão deste teste reprovou o
    schema por causa do nome de uma tabela.
    """
    corpo = "\n".join(schema.ddl()).lower()
    for proibido in ("check", r"not\s+null", "references", "unique", r"foreign\s+key"):
        assert not re.search(rf"\b{proibido}\b", corpo), (
            f"o legado não pode declarar {proibido!r}: tornaria uma falha do catálogo impossível"
        )
    assert corpo.count(" text") >= 400, "as colunas do legado são texto"
