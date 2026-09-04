#!/usr/bin/env python3
"""Verifica a integridade dos artefatos após registrar um ADR.

Confere links relativos, ADRs citados, decisões resolvidas que continuam na tabela de
pendentes e a coerência dos contadores entre README, pendencias e adr/README.
Executar a partir da raiz do repositório.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
# Só o que é do projeto: pacote dbt de terceiro e artefato de build têm links
# próprios, quebrados ou não, e não são responsabilidade deste repositório.
IGNORADOS = {".git", ".venv", ".tools", ".terraform", "dbt_packages", "target", "node_modules"}
docs = [
    p for p in sorted(ROOT.rglob("*.md"))
    if not IGNORADOS & set(p.parts)
]
texts = {p: p.read_text(encoding="utf-8") for p in docs}
problems = []


def rel(p):
    return p.relative_to(ROOT)


# links relativos resolvem
for path, text in texts.items():
    for m in re.finditer(r"\]\((?!https?:|#)([^)\s]+)\)", text):
        target = m.group(1).split("#")[0]
        if target and not (path.parent / target).resolve().exists():
            problems.append(f"link quebrado — {rel(path)}: {target}")

# ADRs citados existem
adr_numbers = {f.name[:4] for f in (ROOT / "docs/adr").glob("0*.md")}
for path, text in texts.items():
    for n in sorted(set(re.findall(r"ADR-(\d{4})", text))):
        if n not in adr_numbers and n != "NNNN":
            problems.append(f"ADR inexistente — {rel(path)}: ADR-{n}")

# decisões já resolvidas não podem seguir na tabela de pendentes
index = texts[ROOT / "docs/adr/README.md"]
registradas, pendentes = index.split("## 3. Decisões pendentes")
resolvidas = set(re.findall(r"\bD\d{2}\b", registradas))
for d in sorted(resolvidas & set(re.findall(r"\bD\d{2}\b", pendentes))):
    problems.append(f"decisão resolvida ainda listada como pendente: {d}")

# contadores coerentes
n_adr = len(adr_numbers) - 1  # 0000-template não conta
n_pend = len(set(re.findall(r"\*\*(D\d{2})\*\*", pendentes)))
readme = texts[ROOT / "README.md"]
# Concordância de número: "1 pendente", não "1 pendentes". O README é lido por
# gente, e o verificador não deve forçar um erro de português nele.
esperado = f"{n_adr} aceitos, {n_pend} pendente" + ("" if n_pend == 1 else "s")
if esperado not in readme:
    problems.append(f"README desatualizado — esperado {esperado!r}")
header = texts[ROOT / "docs/pendencias.md"]
if f"| Decisões pendentes | {n_pend} |" not in header:
    problems.append(f"pendencias.md desatualizado — esperado {n_pend} decisões pendentes")

# a numeração Dnn não é densa: lacunas não indicam decisão perdida
# (docs/adr/README.md §1), portanto não são verificadas.
todos = set()
for text in texts.values():
    todos |= set(re.findall(r"\bD\d{2}\b", text))

print(f"ADRs aceitos: {n_adr}  ·  decisões pendentes: {n_pend}  ·  Dnn citados: {len(todos)}")
print()

if problems:
    print("PROBLEMAS:")
    for p in problems:
        print(" -", p)
    sys.exit(1)
print("Integridade conferida: links, ADRs citados, tabela de pendentes e contadores.")
