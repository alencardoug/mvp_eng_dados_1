"""Coerência dos documentos, por ferramenta — a etapa 1 de `make check`.

O mapa da documentação deste projeto é feito de links: cada assunto tem um dono
documental, e os outros documentos apontam para ele em vez de repetir o
conteúdo (`CLAUDE.md` §5). Isso só funciona enquanto os ponteiros apontam para
algum lugar. Um título renomeado quebra âncoras em silêncio, e o leitor cai no
topo do arquivo achando que leu o que procurava.

Até a Etapa 12 a conferência era **a olho** (§0 do plano). Este módulo a
substitui por ferramenta:

* link relativo → o arquivo existe;
* âncora → existe um título que gera aquele *slug* no arquivo de destino;
* `ADR-00nn` citado no texto → existe `docs/adr/00nn-*.md`.

**Limite declarado: isto verifica caminhos, não prosa.** "O documento está
coerente com o código" é outra pergunta, e quem a responde é a execução linha a
linha da Execução Local, em B5 — a lista de desvios conhecidos já começa com
três. Um link que aponta para o arquivo certo e descreve a coisa errada passa
aqui, e deve passar: fingir o contrário seria pior que não medir.

**A regra de *slug* é a do GitHub**, porque é onde estes documentos são lidos:
minúsculas, pontuação removida, espaços viram hífen, acentos **mantidos**, e
títulos repetidos ganham `-1`, `-2`. Títulos dentro de blocos de código não
contam — são exemplo, não estrutura.
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from urllib.parse import unquote

#: Cerca de bloco de código: ``` ou ~~~, com ou sem linguagem.
CERCA = re.compile(r"^\s*(```|~~~)")

#: Título ATX. Setext (`====` embaixo) não é usado neste repositório.
TITULO = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")

#: Link em linha: `[texto](alvo)`. O alvo para no primeiro espaço ou `)`.
LINK = re.compile(r"\[(?P<texto>[^\]]*)\]\((?P<alvo>[^)\s]+)(?:\s+\"[^\"]*\")?\)")

#: Definição de link por referência: `[rótulo]: alvo`.
DEFINICAO = re.compile(r"^\s{0,3}\[(?P<rotulo>[^\]]+)\]:\s*(?P<alvo>\S+)")

#: Uso de link por referência: `[texto][rótulo]`, ou `[rótulo][]`.
USO_REFERENCIA = re.compile(r"\[(?P<texto>[^\]]*)\]\[(?P<rotulo>[^\]]*)\]")

#: Citação de ADR no corpo do texto.
CITACAO_ADR = re.compile(r"\bADR-(?P<numero>\d{4})\b")

#: Esquemas que não se resolvem no disco.
EXTERNOS = ("http://", "https://", "mailto:", "ftp://", "#")

#: Marcação em linha que o GitHub remove antes de gerar o *slug*. O *slug* sai
#: do texto **renderizado**, então crase, asterisco e til somem sempre.
ENFASE = re.compile(r"[`*~]")

#: O sublinhado é outro caso: `_ênfase_` some porque é marcação, mas o de
#: `snake_case` **fica** — no meio de uma palavra ele não é ênfase nenhuma, e
#: este repositório tem títulos com `snake_case` e nomes de coluna. Remover os
#: dois geraria uma âncora que o GitHub não gera, e a ferramenta diria "existe"
#: sobre um link que quebra no navegador.
SUBLINHADO_DE_ENFASE = re.compile(r"(?<!\w)_|_(?!\w)")
LINK_NO_TITULO = re.compile(r"\[([^\]]*)\]\([^)]*\)")


def slug(titulo: str) -> str:
    """O identificador que o GitHub gera para um título.

    Acentos ficam: `## 8. Retenção` vira `8-retenção`, e é assim que os
    documentos deste projeto se referenciam entre si.
    """
    texto = LINK_NO_TITULO.sub(r"\1", titulo)
    texto = SUBLINHADO_DE_ENFASE.sub("", ENFASE.sub("", texto)).strip().lower()
    # Normaliza a composição para que `ç` escrito como `c` + cedilha e `ç`
    # pré-composto gerem o mesmo slug — os dois existem em arquivos editados
    # por ferramentas diferentes.
    texto = unicodedata.normalize("NFC", texto)
    texto = "".join(c for c in texto if c.isalnum() or c in " -_")
    return texto.replace(" ", "-")


@dataclass(frozen=True)
class Quebrado:
    arquivo: str
    linha: int
    alvo: str
    motivo: str

    def __str__(self) -> str:
        return f"{self.arquivo}:{self.linha}: {self.alvo} — {self.motivo}"


@dataclass
class Documento:
    caminho: pathlib.Path
    relativo: str
    #: slug → quantas vezes o título apareceu (o GitHub sufixa a partir da 2ª)
    ancoras: set[str]
    #: rótulo de referência → alvo
    definicoes: dict[str, str]
    #: (linha, alvo) de cada link que aponta para o disco
    links: list[tuple[int, str]]
    #: (linha, número) de cada ADR citada
    adrs: list[tuple[int, str]]


def _fora_de_codigo(texto: str):
    """Rende `(numero, linha)` pulando o que está dentro de cerca de código."""
    dentro = False
    for numero, linha in enumerate(texto.splitlines(), start=1):
        if CERCA.match(linha):
            dentro = not dentro
            continue
        if not dentro:
            yield numero, linha


def ler(caminho: pathlib.Path, relativo: str) -> Documento:
    texto = caminho.read_text(encoding="utf-8")
    vistos: dict[str, int] = {}
    ancoras: set[str] = set()
    definicoes: dict[str, str] = {}
    links: list[tuple[int, str]] = []
    adrs: list[tuple[int, str]] = []

    for numero, linha in _fora_de_codigo(texto):
        titulo = TITULO.match(linha)
        if titulo:
            base = slug(titulo.group(2))
            repeticao = vistos.get(base, 0)
            ancoras.add(base if repeticao == 0 else f"{base}-{repeticao}")
            vistos[base] = repeticao + 1
            continue

        definicao = DEFINICAO.match(linha)
        if definicao:
            definicoes[definicao.group("rotulo").lower()] = definicao.group("alvo")
            continue

        for casado in LINK.finditer(linha):
            links.append((numero, casado.group("alvo")))
        for casado in USO_REFERENCIA.finditer(linha):
            rotulo = (casado.group("rotulo") or casado.group("texto")).lower()
            links.append((numero, f"[[ref:{rotulo}]]"))
        for casado in CITACAO_ADR.finditer(linha):
            adrs.append((numero, casado.group("numero")))

    return Documento(caminho, relativo, ancoras, definicoes, links, adrs)


def _documentos(raiz: pathlib.Path) -> dict[str, Documento]:
    saida = subprocess.run(
        ["git", "ls-files", "-z", "*.md"], cwd=raiz, capture_output=True, text=True, check=True
    ).stdout
    relativos = [c for c in saida.split("\0") if c]
    return {r: ler(raiz / r, r) for r in relativos if (raiz / r).is_file()}


def verificar(raiz: pathlib.Path) -> tuple[list[Quebrado], dict[str, int]]:
    """Confere todos os `.md` rastreados. Devolve quebrados e o que foi contado."""
    documentos = _documentos(raiz)
    quebrados: list[Quebrado] = []
    contagem = {"documentos": len(documentos), "links": 0, "ancoras": 0, "adrs": 0}

    adrs_existentes = {
        arquivo.name[:4] for arquivo in (raiz / "docs" / "adr").glob("[0-9][0-9][0-9][0-9]-*.md")
    }

    for relativo, documento in documentos.items():
        pasta = documento.caminho.parent
        for numero, alvo in documento.links:
            if alvo.startswith("[[ref:"):
                rotulo = alvo[len("[[ref:") : -2]
                if rotulo not in documento.definicoes:
                    quebrados.append(
                        Quebrado(relativo, numero, f"[{rotulo}]", "referência sem definição")
                    )
                    continue
                alvo = documento.definicoes[rotulo]

            if alvo.startswith(EXTERNOS[:-1]):
                continue

            caminho, _, fragmento = alvo.partition("#")
            fragmento = unquote(fragmento)

            if not caminho:  # âncora no próprio documento
                contagem["ancoras"] += 1
                if fragmento not in documento.ancoras:
                    quebrados.append(
                        Quebrado(relativo, numero, f"#{fragmento}", "título não existe neste arquivo")
                    )
                continue

            contagem["links"] += 1
            destino = (pasta / unquote(caminho)).resolve()
            try:
                chave = str(destino.relative_to(raiz.resolve()))
            except ValueError:
                quebrados.append(Quebrado(relativo, numero, alvo, "aponta para fora do repositório"))
                continue

            if not destino.exists():
                quebrados.append(Quebrado(relativo, numero, alvo, "arquivo não existe"))
                continue

            if fragmento:
                contagem["ancoras"] += 1
                alvo_doc = documentos.get(chave)
                if alvo_doc is None:
                    if destino.suffix.lower() == ".md":
                        quebrados.append(
                            Quebrado(relativo, numero, alvo, "destino não é documento rastreado")
                        )
                elif fragmento not in alvo_doc.ancoras:
                    quebrados.append(
                        Quebrado(relativo, numero, alvo, f"título não existe em {chave}")
                    )

        for numero, numero_adr in documento.adrs:
            contagem["adrs"] += 1
            if numero_adr not in adrs_existentes:
                quebrados.append(
                    Quebrado(relativo, numero, f"ADR-{numero_adr}", "não existe em docs/adr/")
                )

    return quebrados, contagem


def main(argv: list[str] | None = None) -> int:
    raiz = pathlib.Path(argv[0]) if argv else pathlib.Path.cwd()
    quebrados, contagem = verificar(raiz)

    resumo = (
        f"{contagem['documentos']} documentos, {contagem['links']} links de arquivo, "
        f"{contagem['ancoras']} âncoras, {contagem['adrs']} citações de ADR"
    )
    if quebrados:
        for quebrado in quebrados:
            print(quebrado, file=sys.stderr)
        print(f"\ndocs-check: {len(quebrados)} quebrado(s) de {resumo}", file=sys.stderr)
        return 1
    print(f"docs-check: {resumo} — nada quebrado")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
