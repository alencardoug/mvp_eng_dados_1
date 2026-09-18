"""Linhagem por coluna, do consumo até as fontes, derivada do SQL compilado.

── O que é ─────────────────────────────────────────────────────────────────────
A linhagem entre modelos o dbt já dá (`ref`, `source`, `dbt docs`). O que ele
não dá é **por coluna**: de quais colunas de fonte cada coluna de cada modelo é
feita. Este módulo lê as folhas imediatas que `models/sensitivity.py` calcula
ao classificar — mesma leitura do SQL compilado, mesma regra do valor — e as
fecha transitivamente até as fontes (`raw`, `raw_legacy`, `governance`) ou até
uma coluna **gerada** (calendário, `row_number()`, literal, chave técnica), que
é origem terminal por definição.

── Declaração que vale mais que o SQL ──────────────────────────────────────────
`meta.lineage` numa coluna substitui as folhas que o SQL dá. Hoje só as pontes
do legado (`legacy/ponte.py`, geradas) declaram: a ponte extrai de um payload
JSON que o `union` das 40 tabelas formou, e o SQL não vê nem a chave nem a
tabela — a ponte vê, porque a expressão é a do `staging` da origem principal.
Lista vazia é declaração de constante. Toda folha declarada precisa existir; a
que não existe é problema, não aviso.

── Onde é publicado ────────────────────────────────────────────────────────────
`make catalog` escreve na §3 do Dicionário de Dados: as travessias que o dbt não
enxerga (lidas de `airbyte/streams.yml`, `streaming/fluxo.yml` e do certificado
de captura), os totais por camada e, coluna a coluna, a origem de cada coluna
das views de `consumption` — o contrato de consumo. `--check` só compara, e é o
que `make check` roda. A linhagem das outras camadas não é versionada: milhares
de linhas que ninguém revisa mudariam a cada modelo (R14); `tests/test_linhagem.py`
prova que ela fecha, e `--all` a imprime.

Uso: ``python -m mvp_ed1.models.lineage [--check | --all]`` (também em ``make catalog``).
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field

import yaml

from mvp_ed1.models import export, sensitivity

ROOT = sensitivity.ROOT
MANIFEST = sensitivity.MANIFEST
DICIONARIO = export.DICIONARIO
STREAMS = ROOT / "airbyte" / "streams.yml"
FLUXO = ROOT / "streaming" / "fluxo.yml"
DAG = ROOT / "airflow" / "dags" / "fluxo_batch.py"

SOURCE_SCHEMAS = ("raw", "raw_legacy", "governance")
LAYERS = ("staging", "trusted", "analytics", "consumption", "quarantine", "snapshots")
CONTRACT_SCHEMA = "consumption"

Rel = tuple[str, str]
Leaf = sensitivity.Leaf


@dataclass
class Lineage:
    """Folhas imediatas por coluna de cada relação, já com as declarações aplicadas."""
    leaves: dict[Rel, dict[str, set[Leaf]]] = field(default_factory=dict)
    seeds: set[Rel] = field(default_factory=set)      # origem declarada no Git, não gerada
    problems: list[str] = field(default_factory=list)
    _origins: dict[Leaf, frozenset[Leaf]] = field(default_factory=dict, repr=False)

    def kind(self, origin: Leaf) -> str:
        """`fonte`, `seed` ou `gerada` — o que uma origem terminal é."""
        if origin[0] in SOURCE_SCHEMAS:
            return "fonte"
        return "seed" if (origin[0], origin[1]) in self.seeds else "gerada"

    def origins(self, schema: str, relation: str, column: str) -> frozenset[Leaf]:
        """Origens terminais de uma coluna: colunas de fonte e colunas geradas, fechadas transitivamente."""
        chave = (schema, relation, column)
        if schema in SOURCE_SCHEMAS:
            return frozenset({chave})
        if chave in self._origins:
            return self._origins[chave]
        self._origins[chave] = frozenset()          # guarda contra ciclo: um `{{ this }}` que escapou
        folhas = self.leaves.get((schema, relation), {}).get(column, set())
        resultado = frozenset({chave}) if not folhas else frozenset().union(*(self.origins(*f) for f in folhas))
        self._origins[chave] = resultado
        return resultado


def _parse_leaf(texto: str) -> Leaf | None:
    partes = texto.split(".")
    return (partes[0], partes[1], partes[2]) if len(partes) == 3 and all(partes) else None


def build(manifest: dict, derivacao: sensitivity.Derivation | None = None, declared: bool = True) -> Lineage:
    """A linhagem do manifest. `derivacao` reaproveita uma leitura já feita; `declared=False` ignora
    todo `meta.lineage` — é a contraprova de que a declaração é o que fecha o legado."""
    derivacao = sensitivity.derive(manifest) if derivacao is None else derivacao
    saida = Lineage(problems=list(derivacao.problems))

    esquema, _ = sensitivity.source_leaves()
    conhecidas: set[Leaf] = {(s, t, c) for s, tabelas in esquema.items() for t, cols in tabelas.items() for c in cols}
    for fonte in manifest["sources"].values():
        conhecidas.update((fonte["schema"], fonte["identifier"], c) for c in fonte.get("columns", {}))
    for node_id, colunas in derivacao.leaves.items():
        no = manifest["nodes"][node_id]
        conhecidas.update((no["schema"], no.get("alias") or no["name"], c) for c in colunas)

    for node_id, colunas in derivacao.leaves.items():
        no = manifest["nodes"][node_id]
        relacao = (no["schema"], no.get("alias") or no["name"])
        folhas = {c: set(f) for c, f in colunas.items()}
        if no["resource_type"] == "seed":
            saida.seeds.add(relacao)
        for coluna in no.get("columns", {}).values():
            declarada = (coluna.get("meta") or {}).get("lineage")
            if not declared or declarada is None or coluna["name"] not in folhas:
                continue
            aceitas: set[Leaf] = set()
            for texto in declarada:
                folha = _parse_leaf(str(texto))
                if folha is None or folha not in conhecidas:
                    saida.problems.append(f"{node_id}: `meta.lineage` de `{coluna['name']}` aponta para `{texto}`, que não existe")
                    continue
                aceitas.add(folha)
            folhas[coluna["name"]] = aceitas
        saida.leaves[relacao] = folhas
    return saida


# ── Totais ──────────────────────────────────────────────────────────────────────

def summary(linhagem: Lineage) -> dict[str, Counter]:
    """Por camada: colunas, quantas chegam a uma fonte, quantas só a uma seed e quantas são só geradas."""
    totais: dict[str, Counter] = defaultdict(Counter)
    for (schema, relacao), colunas in linhagem.leaves.items():
        for coluna in colunas:
            tipos = {linhagem.kind(o) for o in linhagem.origins(schema, relacao, coluna)}
            totais[schema]["colunas"] += 1
            totais[schema]["de_fonte" if "fonte" in tipos else "de_seed" if "seed" in tipos else "geradas"] += 1
    return totais


# ── Travessias que o dbt não enxerga ────────────────────────────────────────────

def _dag_schedule() -> str:
    """A agenda da DAG do lote, lida do código dela — sem importar o Airflow."""
    texto = DAG.read_text(encoding="utf-8")
    achado = re.search(r"^\s*schedule\s*=\s*(.+?),?\s*$", texto, re.M)
    valor = achado.group(1).strip() if achado else "?"
    return "sem agenda: disparo manual" if valor == "None" else f"agenda `{valor}`"


def crossings() -> list[tuple[str, str, str, str, str]]:
    """Linhas `(origem, destino, mecanismo, frequência, observação)`, lidas das declarações de cada caminho."""
    streams = yaml.safe_load(STREAMS.read_text(encoding="utf-8"))["origens"]
    fluxo = yaml.safe_load(FLUXO.read_text(encoding="utf-8"))
    retail, legacy = streams["retail"], streams["legacy"]
    modos = Counter(spec["modo"] for spec in retail["tabelas"].values())
    por_modo = ", ".join(f"`{modo}` em {n}" for modo, n in sorted(modos.items(), key=lambda par: -par[1]))
    destino = fluxo["destino"]
    return [
        (
            f"`{retail['schema']}` — {len(retail['tabelas'])} tabelas",
            f"`{retail['destino']}`",
            f"Airbyte, modo por tabela ({por_modo}) — [`airbyte/streams.yml`](../airbyte/streams.yml), ADR-0015",
            f"a cada execução da DAG `fluxo_batch` ({_dag_schedule()})",
            "réplica descartável; as colunas chegam com o nome da origem, mais `_airbyte_*`",
        ),
        (
            f"`{retail['schema']}.{sensitivity.STREAM_SINKS[destino['tabela']]}`",
            f"`{destino['schema']}.{destino['tabela']}`",
            f"Debezium (WAL) → Redpanda `{fluxo['transporte']['topico_de_eventos']}` → Beam — [`streaming/fluxo.yml`](../streaming/fluxo.yml), ADR-0031",
            "contínua enquanto o *streaming* está de pé",
            "um delta imutável por movimento, mais `_stream_*`; o Airbyte carrega a mesma tabela em lote como reconciliação",
        ),
        (
            f"`{legacy['schema']}` — {len(legacy['tabelas'])} tabelas",
            f"`{legacy['destino']}`",
            f"Airbyte, `{legacy['modo']}` para todas — ADR-0037",
            "por captura (`make sync-legacy` ou a tarefa da DAG)",
            "captura retida por acréscimo, nunca sobrescrita; valores como texto, defeitos preservados",
        ),
        (
            f"`{legacy['schema']}` — {len(legacy['tabelas'])} tabelas",
            "`governance.legacy_captures`",
            "`mvp_ed1.legacy.captura`: contagem e hash da origem antes e depois do *job*, bruto recebido — ADR-0044",
            "por captura, em duas fases em torno do *job*",
            "certificado por *stream*; só captura `complete` nas 40 tabelas é elegível",
        ),
    ]


# ── Publicação ──────────────────────────────────────────────────────────────────

def _grouped(linhagem: Lineage, origens: frozenset[Leaf]) -> str:
    """`raw.orders.{a, b} · raw_legacy.orders.{a, b}`; fonte primeiro, seed e gerada levam a marca."""
    por_tabela: dict[tuple[str, str], list[str]] = defaultdict(list)
    for schema, tabela, coluna in sorted(origens):
        por_tabela[(schema, tabela)].append(coluna)
    partes = []
    for (schema, tabela), colunas in sorted(por_tabela.items(), key=lambda par: (par[0][0] not in SOURCE_SCHEMAS, par[0])):
        tipo = linhagem.kind((schema, tabela, colunas[0]))
        marca = "" if tipo == "fonte" else f" ({tipo})"
        nomes = colunas[0] if len(colunas) == 1 else "{" + ", ".join(colunas) + "}"
        partes.append(f"`{schema}.{tabela}.{nomes}`{marca}")
    return " · ".join(partes)


def render(linhagem: Lineage, manifest: dict) -> str:
    totais = summary(linhagem)
    linhas = [
        "As travessias abaixo são lidas das declarações de cada caminho; os totais e a origem de cada",
        "coluna, do SQL compilado pelo dbt (`models/lineage.py`). Nada aqui é digitado.",
        "",
        "### 3.1 Travessias fora do dbt",
        "",
        "| Origem | Destino | Mecanismo | Frequência | Observação |",
        "|---|---|---|---|---|",
    ]
    linhas.extend(f"| {a} | {b} | {c} | {d} | {e} |" for a, b, c, d, e in crossings())
    linhas += [
        "",
        "### 3.2 Linhagem por coluna — totais",
        "",
        "Toda coluna de todo modelo fecha numa origem: uma coluna de **fonte** (`raw`, `raw_legacy`,",
        "`governance`), uma coluna de **seed** (declarada no Git) ou uma coluna **gerada** (calendário,",
        "numeração, literal, chave técnica, contagem de linhas), que não vem do valor de coluna nenhuma.",
        "Uma coluna conta como *de fonte*",
        "quando ao menos uma das suas origens é fonte; *só de seed* quando nenhuma é fonte e alguma é seed.",
        "",
        "| Camada | Colunas | De fonte | Só de seed | Só geradas |",
        "|---|---:|---:|---:|---:|",
    ]
    for camada in LAYERS:
        c = totais.get(camada, Counter())
        linhas.append(f"| `{camada}` | {c['colunas']} | {c['de_fonte']} | {c['de_seed']} | {c['geradas']} |")
    total = sum((totais[c] for c in LAYERS), Counter())
    linhas.append(f"| **total** | **{total['colunas']}** | **{total['de_fonte']}** | **{total['de_seed']}** | **{total['geradas']}** |")
    linhas += [
        "",
        f"### 3.3 Origem de cada coluna de `{CONTRACT_SCHEMA}`",
        "",
        "O contrato de consumo, view a view. `raw.*` é a réplica do `oltp` pelo Airbyte e",
        "`raw_legacy.*` a captura do legado — as duas travessias da §3.1; uma coluna com as duas é",
        "o empilhamento do ADR-0021. Origem *(seed)* é tabela declarada no Git; *(gerada)* é coluna",
        "que não vem do valor de coluna nenhuma — o calendário, uma contagem de linhas na fato. As",
        "demais camadas têm a mesma linhagem calculada, não publicada:",
        "`python -m mvp_ed1.models.lineage --all` a imprime.",
    ]
    views = sorted(
        (no for no in manifest["nodes"].values() if no["resource_type"] == "model" and no["schema"] == CONTRACT_SCHEMA),
        key=lambda no: no["name"],
    )
    for no in views:
        relacao = (no["schema"], no.get("alias") or no["name"])
        linhas += ["", f"#### `{relacao[1]}`", "", "| Coluna | Origem |", "|---|---|"]
        for coluna in linhagem.leaves.get(relacao, {}):
            linhas.append(f"| `{coluna}` | {_grouped(linhagem, linhagem.origins(relacao[0], relacao[1], coluna))} |")
    return "\n".join(linhas)


def _section(texto: str, ocorrencia: int = 1) -> str:
    """O n-ésimo trecho gerado do arquivo, como está escrito."""
    inicio = -1
    for _ in range(ocorrencia + 1):
        inicio = texto.index(export.INICIO, inicio + 1)
    fim = texto.index(export.FIM, inicio)
    return texto[inicio + len(export.INICIO) + 1 : fim - 1]


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if not MANIFEST.exists():
        print(f"sem {MANIFEST.relative_to(ROOT)}; rode `make dbt-build` antes", file=sys.stderr)
        return 2
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    linhagem = build(manifest)
    for problema in linhagem.problems:
        print(f"linhagem: {problema}", file=sys.stderr)

    if "--all" in argv:
        for (schema, relacao), colunas in sorted(linhagem.leaves.items()):
            for coluna in colunas:
                print(f"{schema}.{relacao}.{coluna}\t{_grouped(linhagem, linhagem.origins(schema, relacao, coluna))}")
        return 1 if linhagem.problems else 0

    esperado = render(linhagem, manifest)
    atual = _section(DICIONARIO.read_text(encoding="utf-8"))
    total = sum(c["colunas"] for c in summary(linhagem).values())
    if "--check" in argv:
        if atual != esperado:
            print(f"desatualizado: {DICIONARIO.relative_to(ROOT)} §3 — rode `make catalog`", file=sys.stderr)
        print(f"linhagem de {total} colunas em {len(linhagem.leaves)} relações; "
              f"§3 do dicionário {'em dia' if atual == esperado else 'desatualizada'}")
        return 1 if (atual != esperado or linhagem.problems) else 0
    if atual != esperado:
        export._substituir(DICIONARIO, esperado, ocorrencia=1)
    print(f"linhagem de {total} colunas em {len(linhagem.leaves)} relações; "
          f"§3 do dicionário {'reescrita' if atual != esperado else 'já em dia'}")
    return 1 if linhagem.problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
