"""Oráculos do `docs_check`: a conferência de links que era feita a olho.

Um título renomeado quebra âncoras em silêncio — o leitor cai no topo do
arquivo achando que leu o que procurava. Cada regra de *slug* do GitHub que
este projeto depende tem aqui a sua contraprova, porque errar uma delas produz
o pior resultado possível: uma ferramenta que diz "nada quebrado" sobre um mapa
quebrado.
"""

from __future__ import annotations

import pathlib
import subprocess

import pytest

from mvp_ed1 import docs_check


def _git(root: pathlib.Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)


@pytest.fixture
def repositorio(tmp_path: pathlib.Path) -> pathlib.Path:
    _git(tmp_path, "init", "-q")
    _git(tmp_path, "config", "user.email", "teste@exemplo.local")
    _git(tmp_path, "config", "user.name", "teste")
    (tmp_path / "docs" / "adr").mkdir(parents=True)
    (tmp_path / "docs" / "adr" / "0007-uma-decisao.md").write_text("# ADR-0007\n", encoding="utf-8")
    return tmp_path


def _escrever(raiz: pathlib.Path, relativo: str, texto: str) -> None:
    caminho = raiz / relativo
    caminho.parent.mkdir(parents=True, exist_ok=True)
    caminho.write_text(texto, encoding="utf-8")
    _git(raiz, "add", relativo)


# ── A regra de slug, que é de onde vêm os enganos ───────────────────────────


@pytest.mark.parametrize(
    "titulo, esperado",
    [
        ("## 8. Retenção", "8-retenção"),
        ("## 3. Modelo dimensional — 25 tabelas em `analytics`", "3-modelo-dimensional--25-tabelas-em-analytics"),
        ("### D35 — decidida em 07/09/2026", "d35--decidida-em-07092026"),
        ("## O que **não** entra", "o-que-não-entra"),
        ("## Ver o [Termo](abertura.md)", "ver-o-termo"),
        ("## snake_case e kebab-case", "snake_case-e-kebab-case"),
    ],
)
def test_o_slug_e_o_do_github(titulo, esperado):
    """Acentos ficam; pontuação sai; o travessão vira dois hífens.

    O travessão é o caso que mais engana: `— 25 tabelas` não vira
    `-25-tabelas`, vira `--25-tabelas`, porque o espaço de cada lado do
    travessão vira hífen e o travessão some.
    """
    assert docs_check.slug(titulo.lstrip("# ")) == esperado


def test_link_bom_passa(repositorio):
    _escrever(repositorio, "docs/alvo.md", "# Alvo\n\n## Uma seção\n")
    _escrever(repositorio, "README.md", "Ver [o alvo](docs/alvo.md#uma-seção).\n")

    quebrados, contagem = docs_check.verificar(repositorio)

    assert quebrados == []
    assert contagem["links"] == 1 and contagem["ancoras"] == 1


def test_arquivo_inexistente_e_ancora_inexistente_sao_acusados(repositorio):
    _escrever(repositorio, "docs/alvo.md", "# Alvo\n\n## Uma seção\n")
    _escrever(
        repositorio,
        "README.md",
        "[sumiu](docs/sumiu.md)\n\n[errada](docs/alvo.md#outra-secao)\n",
    )

    quebrados, _ = docs_check.verificar(repositorio)
    motivos = {q.alvo: q.motivo for q in quebrados}

    assert motivos["docs/sumiu.md"] == "arquivo não existe"
    assert motivos["docs/alvo.md#outra-secao"] == "título não existe em docs/alvo.md"


def test_ancora_com_acento_e_fragmento_codificado(repositorio):
    """`%C3%A7` é o que o navegador copia da barra de endereços."""
    _escrever(repositorio, "docs/gov.md", "# Governança\n\n## 8. Retenção\n")
    _escrever(
        repositorio,
        "README.md",
        "[cru](docs/gov.md#8-retenção)\n\n[codificado](docs/gov.md#8-reten%C3%A7%C3%A3o)\n",
    )

    quebrados, contagem = docs_check.verificar(repositorio)

    assert quebrados == [], quebrados
    assert contagem["ancoras"] == 2


def test_titulo_repetido_ganha_sufixo(repositorio):
    """Dois `## Contexto` no mesmo arquivo: o segundo é `contexto-1`."""
    _escrever(repositorio, "docs/adr/0007-uma-decisao.md", "# ADR-0007\n\n## Contexto\n\n## Contexto\n")
    _escrever(
        repositorio,
        "README.md",
        "[primeiro](docs/adr/0007-uma-decisao.md#contexto)\n\n"
        "[segundo](docs/adr/0007-uma-decisao.md#contexto-1)\n\n"
        "[terceiro](docs/adr/0007-uma-decisao.md#contexto-2)\n",
    )

    quebrados, _ = docs_check.verificar(repositorio)

    assert [q.alvo for q in quebrados] == ["docs/adr/0007-uma-decisao.md#contexto-2"]


def test_titulo_dentro_de_bloco_de_codigo_nao_conta(repositorio):
    """`# Isto é um comentário de shell`, não um título.

    Contá-lo criaria uma âncora que o GitHub não gera — a ferramenta diria
    "existe" sobre um link que quebra no navegador.
    """
    _escrever(
        repositorio,
        "docs/alvo.md",
        "# Alvo\n\n```bash\n# Um comentário\n```\n",
    )
    _escrever(repositorio, "README.md", "[falso](docs/alvo.md#um-comentário)\n")

    quebrados, _ = docs_check.verificar(repositorio)

    assert len(quebrados) == 1
    assert quebrados[0].motivo == "título não existe em docs/alvo.md"


def test_link_dentro_de_bloco_de_codigo_nao_e_conferido(repositorio):
    """Exemplo em bloco de código é exemplo, não ponteiro."""
    _escrever(
        repositorio,
        "README.md",
        "```markdown\n[exemplo](nao/existe.md)\n```\n",
    )

    quebrados, contagem = docs_check.verificar(repositorio)

    assert quebrados == []
    assert contagem["links"] == 0


def test_link_por_referencia_e_resolvido(repositorio):
    _escrever(repositorio, "docs/alvo.md", "# Alvo\n\n## Uma seção\n")
    _escrever(
        repositorio,
        "README.md",
        "Ver [o alvo][alvo] e [o perdido][perdido].\n\n[alvo]: docs/alvo.md#uma-seção\n",
    )

    quebrados, _ = docs_check.verificar(repositorio)

    assert [(q.alvo, q.motivo) for q in quebrados] == [("[perdido]", "referência sem definição")]


def test_adr_citada_precisa_existir(repositorio):
    _escrever(repositorio, "README.md", "Ver ADR-0007 e também ADR-0099.\n")

    quebrados, contagem = docs_check.verificar(repositorio)

    assert contagem["adrs"] == 2
    assert [(q.alvo, q.motivo) for q in quebrados] == [("ADR-0099", "não existe em docs/adr/")]


def test_link_externo_nao_e_conferido(repositorio):
    _escrever(repositorio, "README.md", "[fora](https://exemplo.invalido/pagina)\n")

    quebrados, contagem = docs_check.verificar(repositorio)

    assert quebrados == []
    assert contagem["links"] == 0


def test_a_documentacao_deste_projeto_passa():
    """A conferência vale para o repositório real, não só para o efêmero."""
    raiz = pathlib.Path(__file__).resolve().parent.parent
    quebrados, contagem = docs_check.verificar(raiz)

    assert quebrados == [], "\n".join(str(q) for q in quebrados)
    assert contagem["links"] > 500, contagem
