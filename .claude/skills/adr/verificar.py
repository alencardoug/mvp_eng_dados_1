#!/usr/bin/env python3
"""Verifica a integridade dos artefatos após registrar um ADR.

Confere links relativos, ADRs citados, decisões resolvidas que continuam pendentes e a coerência dos
contadores de pendentes entre README, Pendências e Registro de Decisões. Executar a partir da raiz do
repositório.

**Dois conjuntos de pendentes, e não um.** Nem toda decisão do Owner vira ADR: as de operação — de
D45 a D56 — fecham nas Pendências, sem ADR. Cada conjunto tem o seu dono e os seus contadores:

- as que esperam um ADR estão na tabela da §3 do Registro de Decisões, e a linha *Registro de
  Decisões* do README as conta;
- todas as que esperam o Owner estão em "Esperando você", nas Pendências, e o cabeçalho delas e a
  linha *Pendências do Owner* do README as contam. As da §3 do Registro estão entre elas.

Até 24/09/2026 o verificador só conhecia o primeiro conjunto, e só com o código em negrito
(`| **D36** |`): a linha `| D43 |` virava zero pendentes, o cabeçalho `1 (D43, …)` não casava com a
forma `1 — D36`, e ele acusava contadores certos. E, com a D53 e a D54 abertas só nas Pendências, o
README dizia 1 pendente enquanto elas diziam 3 — e ele não via.

**Nem tudo que espera o Owner é decisão.** "Esperando você" também guarda aprovações — o aceite de
uma etapa —, com título `###` sem `Dnn`. O cabeçalho das Pendências conta cada tipo na sua linha
(*Decisões pendentes*, *Aprovações pendentes*), e a linha *Pendências do Owner* do README conta as
duas. Até 03/10/2026 o verificador só via as decisões, e reprovava o README certo do fechamento da
Etapa 12 — "o aceite da Etapa 12 e a D43" — por contar 2 (RVF12-07).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
# Só o que é do projeto: pacote dbt de terceiro e artefato de build têm links
# próprios, quebrados ou não, e não são responsabilidade deste repositório.
IGNORADOS = {".git", ".venv", ".tools", ".terraform", "dbt_packages", "target", "node_modules"}


def rel(p):
    return p.relative_to(ROOT)


def secao(texto: str, titulo: str) -> str | None:
    """O corpo da seção `## <titulo>`, até a próxima do mesmo nível; `None` se ela não existir."""
    inicio = re.search(rf"^## {re.escape(titulo)}\b[^\n]*\n", texto, re.M)
    if not inicio:
        return None
    fim = re.search(r"^## ", texto[inicio.end():], re.M)
    return texto[inicio.end():inicio.end() + fim.start()] if fim else texto[inicio.end():]


def codigos_dos_titulos(corpo: str) -> set[str]:
    """Os `Dnn` dos títulos `###` de uma seção — cada decisão das Pendências tem o seu."""
    return {c for titulo in re.findall(r"^### (.*)$", corpo, re.M) for c in re.findall(r"\bD\d{2}\b", titulo)}


def aprovacoes_dos_titulos(corpo: str) -> list[str]:
    """Os títulos `###` sem `Dnn` de uma seção — aprovações, como o aceite de uma etapa."""
    return [titulo for titulo in re.findall(r"^### (.*)$", corpo, re.M) if not re.search(r"\bD\d{2}\b", titulo)]


def pendentes_do_registro(registro: str) -> set[str]:
    """Os códigos da tabela da §3 do Registro, com ou sem negrito. A prosa depois dela não conta."""
    corpo = secao(registro, "3. Decisões pendentes") or ""
    return set(re.findall(r"^\|\s*\*{0,2}(D\d{2})\*{0,2}\s*\|", corpo, re.M))


def plural(n: int) -> str:
    # Concordância de número: "1 pendente", não "1 pendentes". O README é lido por
    # gente, e o verificador não deve forçar um erro de português nele.
    return f"{n} pendente" + ("" if n == 1 else "s")


def decisoes(
    registro: str, pendencias: str, readme: str, n_adr: int
) -> tuple[list[str], set[str], set[str], list[str]]:
    """Os problemas de coerência do que espera o Owner, e os conjuntos: do Registro, das Pendências e as aprovações."""
    problemas: list[str] = []

    # "Parte da D36" registra resolução **parcial**: o ADR fechou um pedaço e a
    # decisão continua pendente. Contá-la como resolvida obrigaria a escolher entre
    # apagar a origem parcial da §2 e apagar a pendência real da §3 — as duas
    # perdem informação, e a que se perderia é justamente a que o R14 cobra.
    antes_da_3 = registro.partition("## 3. Decisões pendentes")[0]
    resolvidas = {
        codigo
        for parcial, codigo in re.findall(r"(?:(Parte da) )?\b(D\d{2})\b", antes_da_3)
        if not parcial
    }
    do_registro = pendentes_do_registro(registro)
    for d in sorted(resolvidas & do_registro):
        problemas.append(f"decisão resolvida ainda listada como pendente no Registro: {d}")

    corpo = secao(pendencias, "1. Esperando você")
    if corpo is None:
        problemas.append("pendencias.md sem a seção '## 1. Esperando você' — não há onde contar as pendentes")
        corpo = ""
    esperando = codigos_dos_titulos(corpo)
    aprovacoes = aprovacoes_dos_titulos(corpo)
    fechadas = codigos_dos_titulos(secao(pendencias, "2. Decisões já fechadas") or "")
    for d in sorted(esperando & (fechadas | resolvidas)):
        problemas.append(f"decisão fechada ainda esperando o Owner nas Pendências: {d}")
    for d in sorted(do_registro - esperando):
        problemas.append(f"pendente no Registro que não está em 'Esperando você', nas Pendências: {d}")

    # O cabeçalho pode nomear quais são — "1 — D36", "1 (D43, adiada)" —, e nomear
    # é melhor que contar. O que se confere é o número, não o contexto ao lado dele.
    cabecalho = re.search(r"^\| Decisões pendentes \| (\d+)\b", pendencias, re.M)
    if not cabecalho or int(cabecalho.group(1)) != len(esperando):
        problemas.append(
            f"pendencias.md desatualizado — o cabeçalho deveria dizer {len(esperando)} decisões pendentes"
            f" ({', '.join(sorted(esperando)) or 'nenhuma'})"
        )
    cabecalho = re.search(r"^\| Aprovações pendentes \| (\d+)\b", pendencias, re.M)
    if (int(cabecalho.group(1)) if cabecalho else 0) != len(aprovacoes):
        problemas.append(
            f"pendencias.md desatualizado — o cabeçalho deveria dizer {len(aprovacoes)} aprovações pendentes"
            f" ({'; '.join(aprovacoes) or 'nenhuma'})"
        )

    linha = re.search(r"^\| \[Registro de Decisões\].*$", readme, re.M)
    contagem = linha and re.search(r"(\d+) aceitos, (\d+) pendentes?", linha.group(0))
    if not contagem or (int(contagem.group(1)), int(contagem.group(2))) != (n_adr, len(do_registro)):
        problemas.append(
            f"README desatualizado — a linha Registro de Decisões deveria dizer"
            f" '{n_adr} aceitos, {plural(len(do_registro))}'"
        )

    # A situação das Pendências já foi escrita de quatro jeitos — "Nada pendente",
    # "Nenhuma decisão pendente em 15/09/2026", "**D33** e **D34**, da revisão" e
    # "1 pendente em 24/09/2026: a D43". O número, quando há; senão, nada ou os
    # códigos nomeados. E todo código nomeado ali precisa estar esperando. A
    # conta inclui as aprovações: "2 pendentes: o aceite da Etapa 12 e a D43".
    linha = re.search(r"^\| \[Pendências do Owner\]\([^)]*\) \|[^|]*\|([^|]*)\|", readme, re.M)
    if not linha:
        problemas.append("README sem a linha Pendências do Owner")
    else:
        situacao = linha.group(1)
        numero = re.search(r"(\d+) pendentes?", situacao)
        nomeadas = set(re.findall(r"\bD\d{2}\b", situacao))
        if numero:
            n = int(numero.group(1))
        elif re.search(r"\b(?:Nada|Nenhuma|Nenhum)\b", situacao):
            n = 0
        else:
            n = len(nomeadas)
        total = len(esperando) + len(aprovacoes)
        if n != total:
            quais = sorted(esperando) + aprovacoes
            problemas.append(
                f"README desatualizado — a linha Pendências do Owner conta {n}, e 'Esperando você' tem"
                f" {total} ({'; '.join(quais) or 'nenhuma'})"
            )
        for d in sorted(nomeadas - esperando):
            problemas.append(f"README nomeia como pendente o que não espera o Owner: {d}")

    return problemas, do_registro, esperando, aprovacoes


CERCA = re.compile(r"^(?P<recuo> *)(?P<cerca>`{3,}|~{3,})(?P<resto>.*)$")
ITEM_DE_LISTA = re.compile(r"^(?P<marcador> *(?:[-*+]|\d{1,9}[.)]))(?= |$)")


def sem_codigo(texto: str) -> str:
    """O texto sem os blocos de código cercados — a mesma regra do `docs_check`, copiada.

    Saída de comando colada num dossiê é exemplo, não citação: até 03/10/2026 o
    `ADR-9999` que a contraprova de um revisor imprimia virava "ADR inexistente".
    O recuo da cerca conta contra a coluna do item de lista, até três espaços:
    três crases com quatro espaços são conteúdo, e até 03/10/2026 fechavam o
    bloco cedo e escondiam o link quebrado depois dele (RVF12-2-06). A cópia
    existe porque este script roda com o `python3` do sistema, sem o pacote; o
    `test_docs_check` confere que as duas dão o mesmo texto.
    """
    linhas: list[str] = []
    larguras: list[int] = []  # a coluna do conteúdo de cada item de lista aberto
    aberta: tuple[str, int] | None = None  # a cerca e a coluna do item em que ela abriu
    for linha in texto.splitlines():
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
        if cerca and recuo - base <= 3 and not (cerca["cerca"][0] == "`" and "`" in cerca["resto"]):
            aberta = (cerca["cerca"], base)
            continue
        item = ITEM_DE_LISTA.match(linha)
        if item:
            depois = linha[item.end():]
            espacos = len(depois) - len(depois.lstrip(" "))
            larguras.append(item.end() + (espacos if depois.strip() and espacos <= 4 else 1))
        linhas.append(linha)
    return "\n".join(linhas)


def main() -> int:
    docs = [p for p in sorted(ROOT.rglob("*.md")) if not IGNORADOS & set(p.parts)]
    texts = {p: p.read_text(encoding="utf-8") for p in docs}
    # Tudo o que se confere é lido fora de bloco de código, como no `docs_check`:
    # links, ADRs citados e os títulos e contadores das decisões. Até 03/10/2026
    # só os dois primeiros, e um `### Exemplo` cercado virava aprovação (RVF12-2-04).
    limpos = {p: sem_codigo(t) for p, t in texts.items()}
    problemas: list[str] = []

    # links relativos resolvem
    for path, text in limpos.items():
        for m in re.finditer(r"\]\((?!https?:|#)([^)\s]+)\)", text):
            target = m.group(1).split("#")[0]
            if target and not (path.parent / target).resolve().exists():
                problemas.append(f"link quebrado — {rel(path)}: {target}")

    # ADRs citados existem
    adr_numbers = {f.name[:4] for f in (ROOT / "docs/adr").glob("0*.md")}
    for path, text in limpos.items():
        for n in sorted(set(re.findall(r"ADR-(\d{4})", text))):
            if n not in adr_numbers and n != "NNNN":
                problemas.append(f"ADR inexistente — {rel(path)}: ADR-{n}")

    # decisões pendentes: resolvidas que ficaram, e os contadores dos dois conjuntos
    n_adr = len(adr_numbers) - 1  # 0000-template não conta
    achados, do_registro, esperando, aprovacoes = decisoes(
        limpos[ROOT / "docs/adr/README.md"], limpos[ROOT / "docs/pendencias.md"], limpos[ROOT / "README.md"], n_adr
    )
    problemas += achados

    # a numeração Dnn não é densa: lacunas não indicam decisão perdida
    # (docs/adr/README.md §1), portanto não são verificadas.
    todos = set()
    for text in texts.values():
        todos |= set(re.findall(r"\bD\d{2}\b", text))

    print(
        f"ADRs aceitos: {n_adr}  ·  esperando ADR: {len(do_registro)}  ·  esperando o Owner:"
        f" {len(esperando)} decisão(ões) e {len(aprovacoes)} aprovação(ões)  ·  Dnn citados: {len(todos)}"
    )
    print()

    if problemas:
        print("PROBLEMAS:")
        for p in problemas:
            print(" -", p)
        return 1
    print("Integridade conferida: links, ADRs citados, decisões pendentes e contadores.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
