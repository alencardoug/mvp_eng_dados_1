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


def test_sufixo_nao_repete_ancora_ja_emitida(repositorio):
    """RVF12-05: `X`, `X`, `X-1` geram `x`, `x-1` e `x-1-1`, como o `github-slugger`.

    A segunda já ocupou `x-1`; a terceira, cujo *slug* também é `x-1`, ganha
    sufixo. Até 03/10/2026 só a base era contada, e `#x-1-1` era acusada.
    """
    _escrever(
        repositorio,
        "README.md",
        "# X\n\n# X\n\n# X-1\n\n[1](#x) [2](#x-1) [3](#x-1-1) [4](#x-2)\n",
    )

    quebrados, contagem = docs_check.verificar(repositorio)

    assert contagem["ancoras"] == 4
    assert [q.alvo for q in quebrados] == ["#x-2"]


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


@pytest.mark.parametrize(
    "bloco",
    [
        pytest.param("````markdown\n```python\n# Falso\n```\n````\n", id="quatro-crases-com-tres-dentro"),
        pytest.param("~~~markdown\n```\n# Falso\n```\n~~~\n", id="tis-com-crases-dentro"),
        pytest.param("```\n# Falso\n``` texto\n```\n", id="cerca-com-texto-nao-fecha"),
    ],
)
def test_cerca_so_fecha_com_o_mesmo_caractere_e_comprimento(repositorio, bloco):
    """RVF12-06: dentro de quatro crases, três crases são conteúdo.

    Até 03/10/2026 qualquer cerca alternava o estado: o `# Falso` do exemplo
    virava título, e o link para `#falso` passava. O texto depois do bloco é
    lido de novo — o título real dali em diante conta.
    """
    _escrever(repositorio, "README.md", bloco + "\n# Real\n\n[falso](#falso) [real](#real)\n")

    quebrados, _ = docs_check.verificar(repositorio)

    assert [q.alvo for q in quebrados] == ["#falso"]


#: Cercas cujo recuo decide onde o bloco começa e termina (RVF12-2-06). Em todas,
#: `# Falso` está dentro do bloco e o `# Real` acrescentado depois, fora.
BLOCOS_COM_RECUO = [
    pytest.param("```text\n    ```\n# Falso\n```\n", id="quatro-espacos-sao-conteudo"),
    pytest.param("   ```\n     ```\n# Falso\n   ```\n", id="abre-com-tres-conteudo-com-cinco"),
    pytest.param("1. Passo:\n\n   ```bash\n   # Falso\n   ```\n", id="item-de-lista"),
    pytest.param("16. Passo:\n    ```\n    # Falso\n    ```\n", id="item-de-dois-digitos"),
    pytest.param("- Passo:\n\n  ```\n  # Falso\n", id="o-fim-do-item-fecha-o-bloco"),
    pytest.param("    ```\n", id="quatro-espacos-fora-de-lista-nao-abrem"),
]


@pytest.mark.parametrize("bloco", BLOCOS_COM_RECUO)
def test_recuo_da_cerca_conta_contra_o_item_de_lista(repositorio, bloco):
    """RVF12-2-06: a cerca abre e fecha com até três espaços além do item.

    Até 03/10/2026 o recuo era livre: três crases com quatro espaços fechavam
    o bloco cedo, a cerca verdadeira o reabria, e o texto depois sumia.
    """
    _escrever(repositorio, "README.md", bloco + "\n# Real\n\n[falso](#falso) [real](#real)\n")

    quebrados, _ = docs_check.verificar(repositorio)

    assert [q.alvo for q in quebrados] == ["#falso"]


def test_o_verificador_de_adr_copia_a_mesma_regra_de_cercas():
    """`.claude/skills/adr/verificar.py` roda com o `python3` do sistema e copia a regra.

    Cópia diverge na primeira correção que esquece uma das duas — foi assim que
    a liberdade de recuo daqui virou regressão lá (RVF12-2-06). O oráculo é este
    módulo, nos casos de recuo e em cada documento rastreado do repositório.
    """
    import importlib.util

    raiz = pathlib.Path(__file__).resolve().parent.parent
    spec = importlib.util.spec_from_file_location(
        "verificar_adr", raiz / ".claude" / "skills" / "adr" / "verificar.py"
    )
    verificar = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(verificar)

    rastreados = subprocess.run(
        ["git", "ls-files", "-z", "*.md"], cwd=raiz, capture_output=True, text=True, check=True
    ).stdout.split("\0")
    textos = [caso.values[0] for caso in BLOCOS_COM_RECUO]
    textos += [(raiz / r).read_text(encoding="utf-8") for r in rastreados if r]
    for texto in textos:
        esperado = "\n".join(linha for _, linha in docs_check._fora_de_codigo(texto))
        assert verificar.sem_codigo(texto) == esperado


def test_crase_na_linha_nao_abre_cerca(repositorio):
    """``` `x` ``` é código em linha: depois dele, o título continua sendo título."""
    _escrever(repositorio, "README.md", "``` `x` ```\n\n# Real\n\n[real](#real)\n")

    quebrados, _ = docs_check.verificar(repositorio)

    assert quebrados == []


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


def test_link_e_adr_no_titulo_sao_conferidos(repositorio):
    """RVF12-04: o título gera âncora **e** é texto — o que ele cita é conferido.

    Até 03/10/2026 o leitor registrava a âncora e pulava a linha, e um título
    com link para arquivo inexistente ou com ADR inexistente passava.
    """
    _escrever(repositorio, "README.md", "# Ver o [alvo](sumiu.md)\n\n## Segundo o ADR-0099\n")

    quebrados, contagem = docs_check.verificar(repositorio)

    assert [(q.linha, q.alvo, q.motivo) for q in quebrados] == [
        (1, "sumiu.md", "arquivo não existe"),
        (3, "ADR-0099", "não existe em docs/adr/"),
    ]
    assert (contagem["links"], contagem["adrs"]) == (1, 1)


def test_link_dentro_de_codigo_em_linha_nao_e_conferido(repositorio):
    """RVF12-2-05: no GFM o código em linha tem precedência sobre o link.

    O título que mostra a sintaxe entre crases, a mesma sintaxe dentro de duas
    crases, e a referência `[x][y]` no corpo são exemplo. Link cujo texto é
    código continua link, e crase escapada não abre código.

    RVF12-3-02: código entre os colchetes e o parêntese separa os dois — não há
    link —, e em duas barras seguidas de crase a barra escapada é a segunda: a
    crase abre código. Dentro do código a barra é literal e não impede o fecho.
    """
    _escrever(
        repositorio,
        "README.md",
        "# Como escrever `[perdido](sumiu.md)`\n\n"
        "Com crase dentro: `` `[perdido](sumiu.md)` `` e `[x][y]`.\n\n"
        "Link com código no texto: [`sumiu.md`](tambem-sumiu.md).\n\n"
        "Crase escapada: \\`[escapado](escapado.md)\\`.\n\n"
        "Código entre as partes: [perdido]`texto`(sumiu.md).\n\n"
        "Barra escapada: \\\\`[perdido](sumiu.md)`.\n\n"
        "Barra dentro do código: `a\\`[dentro](dentro.md).\n",
    )

    quebrados, contagem = docs_check.verificar(repositorio)

    assert [(q.linha, q.alvo) for q in quebrados] == [
        (5, "tambem-sumiu.md"),
        (7, "escapado.md"),
        (13, "dentro.md"),
    ]
    assert contagem["links"] == 3


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
