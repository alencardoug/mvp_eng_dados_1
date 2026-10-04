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

#: Cerca de bloco de código: três ou mais crases ou tis, com ou sem linguagem.
#: O recuo é medido à parte, contra o do item de lista em que a cerca está.
CERCA = re.compile(r"^(?P<recuo> *)(?P<cerca>`{3,}|~{3,})(?P<resto>.*)$")

#: Item de lista — `-`, `*`, `+`, `1.` ou `1)` seguido de espaço ou do fim da
#: linha. O conteúdo dele começa na coluna depois do marcador e dos espaços.
ITEM_DE_LISTA = re.compile(r"^(?P<marcador> *(?:[-*+]|\d{1,9}[.)]))(?= |$)")

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
    #: as âncoras que os títulos geram, já com o sufixo dos repetidos
    ancoras: set[str]
    #: rótulo de referência → alvo
    definicoes: dict[str, str]
    #: (linha, alvo) de cada link que aponta para o disco
    links: list[tuple[int, str]]
    #: (linha, número) de cada ADR citada
    adrs: list[tuple[int, str]]


def _fora_de_codigo(texto: str):
    """Rende `(numero, linha)` pulando o que está dentro de cerca de código.

    A regra do GFM: o bloco fecha só numa cerca do **mesmo** caractere, de
    comprimento igual ou maior, sem nada depois. Dentro de uma cerca de quatro
    crases, três crases são conteúdo — é assim que se mostra um bloco de código
    num exemplo de Markdown. Até 03/10/2026 qualquer cerca alternava o estado,
    e um `# título` de exemplo virava âncora (RVF12-06). Crase na linha de
    abertura de uma cerca de crases é código em linha, não cerca.

    **O recuo conta, contra a coluna do item de lista** (RVF12-2-06). A cerca
    abre e fecha com até três espaços além da coluna em que o conteúdo do item
    começa — zero fora de lista. Até 03/10/2026 o recuo era livre, e três
    crases com quatro espaços, que são conteúdo, fechavam o bloco cedo: a cerca
    verdadeira o reabria e escondia o texto depois dela. Linha com menos recuo
    que o item encerra o item, e o bloco com ele. **Limites declarados:** tab,
    citação (`>`), item que abre com a própria cerca e bloco indentado sem cerca
    não são lidos; a continuação de parágrafo sem recuo encerra o item, e a
    cerca de um item de quatro colunas depois dela é lida como texto — o erro
    aí é acusar um exemplo, não esconder. O repositório não usa nenhum desses.
    """
    larguras: list[int] = []  # a coluna do conteúdo de cada item de lista aberto
    aberta: tuple[str, int] | None = None  # a cerca e a coluna do item em que ela abriu
    for numero, linha in enumerate(texto.splitlines(), start=1):
        recuo = len(linha) - len(linha.lstrip(" "))
        if aberta is not None:
            cerca_aberta, base = aberta
            if not linha.strip():
                continue
            if recuo >= base:
                cerca = CERCA.match(linha)
                if (
                    cerca
                    and recuo - base <= 3
                    and cerca["cerca"][0] == cerca_aberta[0]
                    and len(cerca["cerca"]) >= len(cerca_aberta)
                    and not cerca["resto"].strip()
                ):
                    aberta = None
                continue
            aberta = None
        if linha.strip():
            while larguras and recuo < larguras[-1]:
                larguras.pop()
        base = larguras[-1] if larguras else 0
        cerca = CERCA.match(linha)
        if (
            cerca
            and recuo - base <= 3
            and not (cerca["cerca"][0] == "`" and "`" in cerca["resto"])
        ):
            aberta = (cerca["cerca"], base)
            continue
        item = ITEM_DE_LISTA.match(linha)
        if item:
            depois = linha[item.end():]
            espacos = len(depois) - len(depois.lstrip(" "))
            larguras.append(item.end() + (espacos if depois.strip() and espacos <= 4 else 1))
        yield numero, linha


def _sem_codigo_em_linha(linha: str) -> str:
    """A linha com cada código em linha trocado por um espaço.

    No GFM o código em linha tem precedência sobre o link — `` `[x](y.md)` ``
    mostra a sintaxe, não aponta para nada. Até 03/10/2026 nenhuma linha o
    respeitava, e a correção do RVF12-04, que passou a ler os títulos, fez de um
    exemplo num título um link quebrado (RVF12-2-05). Link cujo texto é código
    continua link.

    A leitura é da esquerda para a direita, como a do GFM (RVF12-3-02). Fora do
    código, a barra invertida escapa o caractere seguinte: em `\\` + crase, a
    primeira barra escapa a segunda, e a crase abre código. Uma sequência de
    crases fecha só noutra do **mesmo** comprimento, e dentro do código a barra
    é literal. O código vira um espaço, e não nada: apagá-lo juntava `[x]`, o
    código e `(y.md)` num link que não existia.
    """
    partes: list[str] = []
    i = 0
    while i < len(linha):
        if linha[i] == "\\":
            partes.append(linha[i : i + 2])
            i += 2
        elif linha[i] == "`":
            fim = i
            while fim < len(linha) and linha[fim] == "`":
                fim += 1
            fecho = re.compile(rf"(?<!`){'`' * (fim - i)}(?!`)").search(linha, fim)
            if fecho:
                partes.append(" ")
                i = fecho.end()
            else:
                partes.append(linha[i:fim])
                i = fim
        else:
            partes.append(linha[i])
            i += 1
    return "".join(partes)


def ler(caminho: pathlib.Path, relativo: str) -> Documento:
    texto = caminho.read_text(encoding="utf-8")
    #: âncora já emitida → último sufixo usado a partir dela
    vistos: dict[str, int] = {}
    ancoras: set[str] = set()
    definicoes: dict[str, str] = {}
    links: list[tuple[int, str]] = []
    adrs: list[tuple[int, str]] = []

    for numero, linha in _fora_de_codigo(texto):
        titulo = TITULO.match(linha)
        if titulo:
            # O algoritmo do `github-slugger`: toda âncora emitida fica
            # reservada, inclusive as sufixadas. `X`, `X`, `X-1` dão `x`,
            # `x-1` e `x-1-1` — a terceira não pode repetir a segunda. Até
            # 03/10/2026 só a base contava, e `#x-1-1` era acusada (RVF12-05).
            base = slug(titulo.group(2))
            ancora = base
            while ancora in vistos:
                vistos[base] += 1
                ancora = f"{base}-{vistos[base]}"
            vistos[ancora] = 0
            ancoras.add(ancora)
            # O título também é texto: link e citação de ADR nele valem como em
            # qualquer linha. Até 03/10/2026 o `continue` aqui os pulava (RVF12-04).

        definicao = DEFINICAO.match(linha)
        if definicao:
            definicoes[definicao.group("rotulo").lower()] = definicao.group("alvo")
            continue

        sem_codigo = _sem_codigo_em_linha(linha)
        for casado in LINK.finditer(sem_codigo):
            links.append((numero, casado.group("alvo")))
        for casado in USO_REFERENCIA.finditer(sem_codigo):
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
