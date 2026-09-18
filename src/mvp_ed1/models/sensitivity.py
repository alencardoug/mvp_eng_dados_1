"""Classificação de sensibilidade derivada dos modelos, camada a camada, por linhagem.

── O que é declaração e o que é derivado ───────────────────────────────────────
A classificação de cada coluna da origem é **declarada** uma vez, nos modelos
SQLAlchemy (`models/base.py::meta`, obrigatória e validada). Tudo o que o
armazém materializa a partir dela — `raw`, `staging`, `trusted`, `snapshots`,
`analytics`, `consumption`, `quarantine` — é transporte, renome, conversão ou
combinação dessas colunas. Escrever `sensitivity` à mão nas 4 mil colunas do
armazém seria uma segunda declaração da mesma coisa, que divergiria da primeira
(R14); o que se faz aqui é **derivar**.

── A regra ──────────────────────────────────────────────────────────────────────
A linhagem de cada coluna de cada modelo é lida do SQL compilado pelo dbt
(`sqlglot`, coluna a coluna, atravessando CTEs, subconsultas e `union`), até
chegar às folhas: colunas de fontes ou de modelos já classificados.

* coluna com uma folha só (transporte, renome, `cast`) **herda** o nível dela;
* coluna com várias folhas (concatenação, `case`, agregação, junção) recebe o
  nível **mais restritivo** entre elas — `public < internal < confidential <
  personal`. É conservador de propósito: um derivado de dado pessoal é tratado
  como pessoal até que alguém declare o contrário;
* coluna sem folha (literal, `row_number()`, `current_timestamp`, hash de
  chave) é técnica: `internal`;
* colunas que o dbt acrescenta aos snapshots (`dbt_*`) e o Airbyte às fontes
  (`_airbyte_*`) são `internal`.

No `.yml`, `sensitivity` é **derivado** — reescrito a cada geração — a menos
que venha com `meta.sensitivity_reason`: aí a declaração à mão vale, para a
coluna e para quem a lê depois. É a única forma de exceção, e ela é visível no
`.yml` e no diff: toda troca de valor é impressa ao gerar.

── Onde o resultado é escrito ───────────────────────────────────────────────────
* modelo documentado num `.yml` escrito à mão: o `meta.sensitivity` é inserido
  ou atualizado **no lugar**, preservando o resto do arquivo linha a linha;
* modelo sem entrada em `.yml` nenhum: entra em `_sensitivity.yml` no diretório
  dele — arquivo inteiramente gerado, reescrito com **todos** os modelos que lhe
  pertencem a cada geração, e removido quando não sobra nenhum. Para promover um
  modelo a um `.yml` à mão, acrescente a entrada e rode `make catalog` **antes**
  do dbt: o disco, não o manifest, diz onde o modelo está documentado, e é a
  geração que retira a entrada gerada antes de o dbt recusar a duplicidade;
* fonte `raw` (e `raw_legacy`): as colunas entram em `_retail__sources.yml`, sob
  cada tabela — **espelho** da declaração SQLAlchemy, que continua sendo a folha;
  um espelho atrasado não sobrepõe a origem;
* `.yml` gerado por `make legacy-models`: não é tocado — a sensibilidade dele
  nasce no próprio gerador (`legacy/classification.py`), da mesma declaração.

`--check` não escreve: sai com 1 se algum arquivo estaria diferente, e é o que
`make check` roda para garantir que o derivado não ficou para trás. Derivação
incompleta — manifest de `dbt parse`, sem SQL compilado, ou SQL que o parser não
lê — não escreve nem apaga nada, com ou sem `--check`.

As folhas por coluna que esta leitura produz (`Derivation.leaves`) são a mesma
coisa de que `models/lineage.py` parte para fechar a linhagem até a origem: uma
leitura do SQL, dois derivados.

Uso: ``python -m mvp_ed1.models.sensitivity [--check]`` (também em ``make catalog``).
"""

from __future__ import annotations

import csv
import json
import pathlib
import sys
from collections import defaultdict
from dataclasses import dataclass, field

import sqlglot
import yaml
from sqlglot import exp
from sqlglot.optimizer.qualify import qualify
from sqlglot.optimizer.scope import Scope, traverse_scope

from mvp_ed1.legacy import schema as legacy_schema
from mvp_ed1.models import Base
from mvp_ed1.models.base import SENSITIVITY_LEVELS

ROOT = pathlib.Path(__file__).resolve().parents[3]
DBT = ROOT / "dbt"
MANIFEST = DBT / "target" / "manifest.json"

LEVEL_ORDER = ("public", "internal", "confidential", "personal")
TECHNICAL = "internal"
AIRBYTE_COLUMNS = ("_airbyte_raw_id", "_airbyte_extracted_at", "_airbyte_meta", "_airbyte_generation_id")
#: Tabelas de `raw` escritas pelo caminho quente, não pelo Airbyte (ADR-0031):
#: as colunas de negócio são as da tabela transacional homônima, e as `_stream_*`
#: são metadados do transporte.
STREAM_SINKS = {"inventory_movements_stream": "inventory_movements"}
STREAM_COLUMNS = ("_stream_partition", "_stream_offset", "_stream_lsn", "_stream_from_snapshot", "_stream_extracted_at")
SNAPSHOT_COLUMNS = ("dbt_scd_id", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to")
GENERATED_FILE = "_sensitivity.yml"
GENERATED_HEADER = (
    "# Gerado por `make catalog` (mvp_ed1/models/sensitivity.py). Não edite: a\n"
    "# classificação é derivada, por linhagem, da declarada nos modelos SQLAlchemy.\n"
    "# Modelo que ganhar entrada num .yml escrito à mão sai daqui na próxima geração.\n"
)


def strictest(levels: list[str]) -> str:
    return max(levels, key=LEVEL_ORDER.index) if levels else TECHNICAL


# ── Folhas: o que já está classificado antes de qualquer modelo ─────────────────

def source_leaves() -> tuple[dict[str, dict[str, dict[str, str]]], dict[tuple[str, str, str], str]]:
    """Esquema (`schema → tabela → coluna → tipo`) e nível de cada coluna das fontes `raw` e `raw_legacy`."""
    esquema: dict[str, dict[str, dict[str, str]]] = defaultdict(dict)
    niveis: dict[tuple[str, str, str], str] = {}
    for table in Base.metadata.tables.values():
        declarada = {c.name: c.info["sensitivity"] for c in table.columns}
        for camada in ("raw", "raw_legacy"):
            colunas = dict.fromkeys(AIRBYTE_COLUMNS, TECHNICAL)
            if camada == "raw_legacy":
                colunas[legacy_schema.IDENTIDADE] = TECHNICAL
                colunas.update({c: declarada[c] for c in legacy_schema.colunas(table.name)})
            else:
                colunas.update(declarada)
            esquema[camada][table.name] = {c: "text" for c in colunas}
            niveis.update({(camada, table.name, c): n for c, n in colunas.items()})
    for sink, origem in STREAM_SINKS.items():
        colunas = {c.name: c.info["sensitivity"] for c in Base.metadata.tables[f"oltp.{origem}"].columns}
        colunas.update(dict.fromkeys(STREAM_COLUMNS, TECHNICAL))
        esquema["raw"][sink] = {c: "text" for c in colunas}
        niveis.update({("raw", sink, c): n for c, n in colunas.items()})
    return esquema, niveis


# ── A regra do valor, compartilhada ─────────────────────────────────────────────

def value_children(e: exp.Expression) -> list[exp.Expression]:
    """Os filhos de uma expressão que **entram no valor** — não os que decidem o ramo.

    `case when a then b else c end` vale `b` e `c`; `if(a, b, c)`, `b` e `c`.
    É o mesmo critério para a linhagem dos modelos e para as pontes do legado
    (`legacy/ponte.py`), que classificam expressões sem passar pelo dbt.
    """
    if isinstance(e, exp.Case):
        filhos = [ramo.args["true"] for ramo in e.args.get("ifs", [])]
        if e.args.get("default") is not None:
            filhos.append(e.args["default"])
        return filhos
    if isinstance(e, exp.If):
        return [v for k, v in e.args.items() if k in ("true", "false") and v is not None]
    return list(e.iter_expressions())


def value_columns(sql: str) -> list[str]:
    """Nomes das colunas que **entram no valor** de uma expressão SQL avulsa, na ordem em que aparecem."""
    nomes: list[str] = []
    pilha = [sqlglot.parse_one(sql, read="postgres")]
    while pilha:
        e = pilha.pop()
        if isinstance(e, exp.Column):
            nomes.append(e.name)
        else:
            pilha.extend(value_children(e))
    return nomes


def expression_level(sql: str, lookup) -> str:
    """Nível de uma expressão SQL avulsa: o mais restritivo entre as colunas que entram no valor.

    `lookup(nome)` devolve o nível de uma coluna pelo nome, ou `None` para o
    que não é coluna de dado (palavra reservada, metadado de transporte).
    """
    return strictest([nivel for nivel in map(lookup, value_columns(sql)) if nivel])


# ── Derivação ───────────────────────────────────────────────────────────────────

@dataclass
class Derivation:
    """O resultado: nível por coluna de cada nó, as folhas de que cada coluna é feita, e o que não pôde ser derivado."""
    levels: dict[str, dict[str, str]] = field(default_factory=dict)      # node_id → coluna → nível
    leaves: dict[str, dict[str, set["Leaf"]]] = field(default_factory=dict)  # node_id → coluna → folhas imediatas
    problems: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def _topological(nodes: dict[str, dict]) -> list[str]:
    restantes = {k: {d for d in v["depends_on"].get("nodes", []) if d in nodes} for k, v in nodes.items()}
    ordem: list[str] = []
    while restantes:
        prontos = sorted(k for k, deps in restantes.items() if not deps)
        if not prontos:
            raise RuntimeError(f"ciclo entre nós do dbt: {sorted(restantes)[:5]}")
        ordem.extend(prontos)
        for k in prontos:
            del restantes[k]
        for deps in restantes.values():
            deps.difference_update(prontos)
    return ordem


def _seed_columns(node: dict) -> list[str]:
    with (DBT / node["original_file_path"]).open(encoding="utf-8", newline="") as arquivo:
        return next(csv.reader(arquivo))


def derive(manifest: dict) -> Derivation:
    esquema, niveis = source_leaves()
    saida = Derivation()

    # Fontes declaradas com colunas no .yml (governance.legacy_captures) são folhas prontas.
    # As de `raw` e `raw_legacy` não: o `meta.sensitivity` delas é espelho da declaração
    # SQLAlchemy, escrito por `plan()`, e um espelho atrasado não pode sobrepor a origem —
    # a reclassificação de uma coluna tem de chegar ao derivado na mesma geração.
    espelhadas = set(esquema)
    for fonte in manifest["sources"].values():
        if fonte["schema"] in espelhadas:
            continue
        for coluna in fonte.get("columns", {}).values():
            nivel = (coluna.get("meta") or {}).get("sensitivity")
            if nivel:
                esquema[fonte["schema"]].setdefault(fonte["identifier"], {})[coluna["name"]] = "text"
                niveis[(fonte["schema"], fonte["identifier"], coluna["name"])] = nivel

    nos = {k: v for k, v in manifest["nodes"].items() if v["resource_type"] in ("model", "seed", "snapshot")}
    banco = next(iter(nos.values()))["database"]

    for node_id in _topological(nos):
        no = nos[node_id]
        relacao = no.get("alias") or no["name"]
        if no["resource_type"] == "seed":
            declarado = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in no.get("columns", {}).values()}
            colunas = {}
            for nome in _seed_columns(no):
                if not declarado.get(nome):
                    saida.problems.append(f"{node_id}: coluna `{nome}` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado")
                colunas[nome] = declarado.get(nome) or TECHNICAL
            folhas = {nome: set() for nome in colunas}     # seed é origem: não vem de lugar nenhum
        else:
            folhas = _derive_node(no, esquema, niveis, banco, saida.problems, saida.warnings)
            colunas = {nome: strictest([niveis[f] for f in chaves]) for nome, chaves in folhas.items()}
            if no["resource_type"] == "snapshot":
                colunas.update(dict.fromkeys(SNAPSHOT_COLUMNS, TECHNICAL))
                folhas.update({c: set() for c in SNAPSHOT_COLUMNS})
        saida.leaves[node_id] = folhas
        # Exceção declarada e justificada vale — e vale para quem lê o modelo
        # depois: a ponte do legado extrai colunas de um payload JSON pessoal e
        # declara o nível real de cada uma; o que a lê herda esse nível, não o
        # do payload.
        for coluna in no.get("columns", {}).values():
            meta = coluna.get("meta") or {}
            if meta.get("sensitivity") and meta.get("sensitivity_reason") and coluna["name"] in colunas:
                colunas[coluna["name"]] = meta["sensitivity"]
        saida.levels[node_id] = colunas
        esquema[no["schema"]][relacao] = {c: "text" for c in colunas}
        niveis.update({(no["schema"], relacao, c): n for c, n in colunas.items()})
    return saida


def _derive_node(no: dict, esquema, niveis, banco: str, problems: list[str], warnings: list[str]) -> dict[str, set["Leaf"]]:
    """Por coluna de saída do nó, as folhas imediatas — colunas de fonte ou de modelo anterior."""
    sql = no.get("compiled_code") or ""
    if not sql.strip():
        problems.append(f"{no['unique_id']}: sem SQL compilado no manifest; rode `make dbt-build`")
        return {}
    catalogo = {banco: {s: dict(t) for s, t in esquema.items()}}
    try:
        arvore = sqlglot.parse_one(sql, read="postgres")
        qualificada = qualify(arvore, schema=catalogo, dialect="postgres", validate_qualify_columns=False)
    except Exception as erro:  # noqa: BLE001 — o que interessa é o nó e o motivo
        problems.append(f"{no['unique_id']}: não qualificável ({str(erro)[:120]})")
        return {}
    folhas = _leaves_by_output(qualificada, no["unique_id"], (no["schema"], no.get("alias") or no["name"]), niveis, problems, warnings)
    if not folhas:
        problems.append(f"{no['unique_id']}: nenhuma projeção reconhecida no SQL compilado")
    return folhas


Leaf = tuple[str, str, str]


def _leaves_by_output(query: exp.Expression, node_id: str, propria: tuple[str, str], niveis, problems: list[str], warnings: list[str]) -> dict[str, set[Leaf]]:
    """Por coluna de saída da consulta, as colunas de fonte de que ela é feita.

    Um passo só por escopo, de dentro para fora (`traverse_scope` entrega cada
    CTE, subconsulta e ramo de `union` antes de quem o lê): a saída de um
    escopo é lida pelo seguinte pelo nome, e a de um `union` casa os ramos
    pela posição. O que decide o ramo de um `case` não entra — só o que vira
    valor.
    """
    saidas: dict[int, dict[str, set[Leaf]]] = {}

    def resolver(coluna: exp.Column, escopo: Scope) -> set[Leaf]:
        atual: Scope | None = escopo
        while atual is not None:
            fonte = atual.sources.get(coluna.table)
            if isinstance(fonte, exp.Table):
                if not fonte.db or (fonte.db, fonte.name) == propria:   # função de tabela, ou `{{ this }}` do incremental
                    return set()
                chave = (fonte.db, fonte.name, coluna.name)
                if chave not in niveis:
                    problems.append(f"{node_id}: folha desconhecida {fonte.db}.{fonte.name}.{coluna.name}")
                    return set()
                return {chave}
            if isinstance(fonte, Scope):
                conhecidas = saidas.get(id(fonte), saidas.get(id(fonte.expression), {}))
                if coluna.name in conhecidas:
                    return set(conhecidas[coluna.name])
                if "*" in conhecidas:          # função de tabela: toda coluna dela vem dos argumentos
                    return set(conhecidas["*"])
                problems.append(f"{node_id}: coluna `{coluna.name}` não sai de `{coluna.table}`")
                return set()
            if fonte is not None:          # `unnest`, `values`: sem folha
                return set()
            atual = atual.parent
        # `with ordinality c(name, position)` e afins: o sqlglot não registra o
        # apelido como fonte. É técnica (o argumento é um contrato JSON), fica
        # sem folha e avisada — não bloqueia.
        warnings.append(f"{node_id}: origem `{coluna.table}` de `{coluna.name}` não encontrada; tratada como técnica")
        return set()

    def folhas_de(expressao: exp.Expression, escopo: Scope) -> set[Leaf]:
        encontradas: set[Leaf] = set()
        pilha = [expressao]
        while pilha:
            e = pilha.pop()
            if isinstance(e, exp.Column):
                encontradas |= resolver(e, escopo)
            elif isinstance(e, exp.Star):
                if isinstance(e.parent, exp.Select):     # `count(*)` não é projeção: sem folha
                    problems.append(f"{node_id}: `*` não expandido — fonte sem colunas conhecidas")
            elif isinstance(e, exp.Subquery) or (isinstance(e, exp.Query) and e is not expressao):
                interna = saidas.get(id(e.this if isinstance(e, exp.Subquery) else e), saidas.get(id(e), {}))
                for chaves in interna.values():
                    encontradas |= chaves
            else:
                pilha.extend(value_children(e))
        return encontradas

    for escopo in traverse_scope(query):
        consulta = escopo.expression
        while isinstance(consulta, (exp.Lateral, exp.Subquery)):   # `cross join lateral (select …)`
            consulta = consulta.this
        if isinstance(consulta, exp.SetOperation):
            ramos = [saidas.get(id(r), saidas.get(id(r.expression), {})) for r in (escopo.union_scopes or [])]
            nomes = [list(r.keys()) for r in ramos]
            combinado: dict[str, set[Leaf]] = {}
            for posicao, nome in enumerate(nomes[0] if nomes else []):
                combinado[nome] = set()
                for ramo, ramo_nomes in zip(ramos, nomes):
                    if posicao < len(ramo_nomes):
                        combinado[nome] |= ramo[ramo_nomes[posicao]]
            saidas[id(escopo)] = saidas[id(escopo.expression)] = saidas[id(consulta)] = combinado
            if isinstance(consulta.parent, exp.Subquery):
                saidas[id(consulta.parent)] = combinado
            continue
        resultado: dict[str, set[Leaf]] = {}
        if isinstance(consulta, exp.Query):
            for projecao in consulta.selects:
                resultado[projecao.alias_or_name] = folhas_de(projecao, escopo)
        else:                                   # `cross join lateral jsonb_each_text(x) f`
            resultado["*"] = folhas_de(consulta, escopo.parent or escopo)
        saidas[id(escopo)] = saidas[id(escopo.expression)] = saidas[id(consulta)] = resultado
        if isinstance(consulta.parent, exp.Subquery):
            saidas[id(consulta.parent)] = resultado

    return saidas.get(id(query), {})


# ── Onde cada coluna está declarada hoje ────────────────────────────────────────

def _is_generated(path: pathlib.Path) -> bool:
    with path.open(encoding="utf-8") as arquivo:
        cabecalho = "".join(arquivo.readline() for _ in range(3))
    return "gerado" in cabecalho.lower()


@dataclass
class Plan:
    """O que mudaria em cada arquivo, e o que ficou de fora."""
    patches: dict[pathlib.Path, dict[str, dict[str, str]]] = field(default_factory=lambda: defaultdict(dict))   # yml → entrada → coluna → nível
    generated: dict[pathlib.Path, dict[str, dict[str, str]]] = field(default_factory=lambda: defaultdict(dict))  # _sensitivity.yml → modelo → coluna → nível
    changes: list[str] = field(default_factory=list)          # valor que muda, para o diff ser lido
    left_to_generator: list[str] = field(default_factory=list)


def manual_entries() -> dict[str, tuple[pathlib.Path, dict[str, dict]]]:
    """`modelo → (.yml escrito à mão, coluna → meta)` de tudo o que os `.yml` do projeto documentam à mão, **lido do disco**.

    O disco, e não o manifest, decide onde um modelo está documentado: quem
    promove um modelo a um `.yml` à mão acrescenta a entrada e roda
    `make catalog` — o manifest ainda aponta para o gerado, e o dbt se recusaria
    a compilar com as duas entradas. Ler o disco é o que permite retirar a
    entrada gerada **antes** dessa recusa, sem editar o derivado à mão.
    """
    entradas: dict[str, tuple[pathlib.Path, dict[str, dict]]] = {}
    for caminho in sorted(list((DBT / "models").rglob("*.yml")) + list((DBT / "snapshots").rglob("*.yml"))):
        if _is_generated(caminho):
            continue
        documento = yaml.safe_load(caminho.read_text(encoding="utf-8")) or {}
        for entrada in (documento.get("models") or []) + (documento.get("snapshots") or []):
            colunas = {c["name"]: (c.get("meta") or {}) for c in entrada.get("columns") or []}
            entradas[entrada["name"]] = (caminho, colunas)
    return entradas


def plan(manifest: dict, derivation: Derivation) -> Plan:
    resultado = Plan()
    manuais = manual_entries()
    for node_id, colunas in derivation.levels.items():
        no = manifest["nodes"][node_id]
        if no["resource_type"] == "seed":
            continue
        manual = manuais.get(no["name"])
        if manual:
            caminho, declaradas = manual
        else:
            declaradas = {c["name"]: (c.get("meta") or {}) for c in no.get("columns", {}).values()}
        alvo: dict[str, str] = {}
        for coluna, derivado in colunas.items():
            meta = declaradas.get(coluna, {})
            atual = meta.get("sensitivity")
            if atual and meta.get("sensitivity_reason"):
                continue  # exceção declarada e justificada: vale a mão
            if atual != derivado:
                if atual:
                    resultado.changes.append(f"{no['name']}.{coluna}: `{atual}` → `{derivado}`")
                alvo[coluna] = derivado
        if manual:
            if alvo:
                resultado.patches[caminho][no["name"]] = alvo
            continue
        if not (no.get("patch_path") and not no["patch_path"].endswith("/" + GENERATED_FILE)):
            # Arquivo inteiramente gerado: é reescrito por inteiro, então **todo** modelo que
            # lhe pertence entra, mude ou não — um que ficasse de fora por não ter mudado
            # sumiria do arquivo na primeira alteração de outro. Modelo com entrada num .yml
            # à mão já saiu acima e, por isso mesmo, sai daqui.
            diretorio = DBT / pathlib.Path(no["original_file_path"]).parent
            resultado.generated[diretorio / GENERATED_FILE][no["name"]] = colunas
            continue
        if not alvo:
            continue
        # Só resta o .yml gerado por `make legacy-models`: a sensibilidade dele é do gerador.
        caminho = DBT / no["patch_path"].split("://", 1)[1]
        resultado.left_to_generator.append(f"{no['name']}: {len(alvo)} colunas sem sensitivity em {caminho.relative_to(ROOT)} (gerado)")

    # Fontes raw: colunas sob cada tabela de _retail__sources.yml.
    _, niveis = source_leaves()
    for fonte in manifest["sources"].values():
        if fonte["schema"] != "raw":
            continue
        declaradas = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in fonte.get("columns", {}).values()}
        alvo = {c: n for (s, t, c), n in niveis.items() if s == "raw" and t == fonte["identifier"] and declaradas.get(c) != n}
        if alvo:
            resultado.patches[DBT / fonte["original_file_path"]][fonte["identifier"]] = alvo
    return resultado


# ── Escrita: no lugar, linha a linha ────────────────────────────────────────────

def _indent(linha: str) -> int:
    return len(linha) - len(linha.lstrip(" "))


def _block_end(linhas: list[str], inicio: int, indent: int) -> int:
    """Primeira linha depois de `inicio` com indentação ≤ `indent` que não é vazia nem comentário solto."""
    for i in range(inicio + 1, len(linhas)):
        texto = linhas[i]
        if texto.strip() and _indent(texto) <= indent:
            return i
    return len(linhas)


def _find_entry(linhas: list[str], nome: str, indent: int | None = None) -> int | None:
    for i, linha in enumerate(linhas):
        if linha.strip() == f"- name: {nome}" and (indent is None or _indent(linha) == indent):
            return i
    return None


def patch_yaml(texto: str, entradas: dict[str, dict[str, str]]) -> str:
    """Insere ou atualiza `meta.sensitivity` de cada coluna de cada entrada, preservando o resto."""
    linhas = texto.split("\n")
    for entrada, colunas in entradas.items():
        for coluna, nivel in colunas.items():
            inicio = _find_entry(linhas, entrada)
            if inicio is None:
                raise KeyError(f"entrada `{entrada}` não encontrada")
            base = _indent(linhas[inicio])
            fim = _block_end(linhas, inicio, base)
            bloco = linhas[inicio:fim]
            # `columns:` do bloco, criado se não existir
            idx_cols = next((i for i, l in enumerate(bloco) if l.strip() == "columns:" and _indent(l) == base + 2), None)
            if idx_cols is None:
                while bloco and not bloco[-1].strip():
                    bloco.pop()
                bloco.append(" " * (base + 2) + "columns:")
                idx_cols = len(bloco) - 1
            item_indent = base + 4
            idx_col = next((i for i in range(idx_cols + 1, len(bloco)) if bloco[i].strip() == f"- name: {coluna}" and _indent(bloco[i]) == item_indent), None)
            if idx_col is None:
                # fim do bloco de colunas: última linha não vazia
                fim_cols = len(bloco)
                while fim_cols > idx_cols + 1 and not bloco[fim_cols - 1].strip():
                    fim_cols -= 1
                bloco[fim_cols:fim_cols] = [
                    " " * item_indent + f"- name: {coluna}",
                    " " * (item_indent + 2) + "meta:",
                    " " * (item_indent + 4) + f"sensitivity: {nivel}",
                ]
            else:
                fim_col = _block_end(bloco, idx_col, item_indent)
                idx_meta = next((i for i in range(idx_col + 1, fim_col) if bloco[i].strip() == "meta:" and _indent(bloco[i]) == item_indent + 2), None)
                if idx_meta is None:
                    bloco[idx_col + 1:idx_col + 1] = [
                        " " * (item_indent + 2) + "meta:",
                        " " * (item_indent + 4) + f"sensitivity: {nivel}",
                    ]
                else:
                    fim_meta = _block_end(bloco, idx_meta, item_indent + 2)
                    idx_sens = next((i for i in range(idx_meta + 1, fim_meta) if bloco[i].strip().startswith("sensitivity:")), None)
                    if idx_sens is None:
                        bloco.insert(idx_meta + 1, " " * (item_indent + 4) + f"sensitivity: {nivel}")
                    else:
                        bloco[idx_sens] = " " * (item_indent + 4) + f"sensitivity: {nivel}"
            linhas[inicio:fim] = bloco
    return "\n".join(linhas)


def render_generated(modelos: dict[str, dict[str, str]], chave: str = "models") -> str:
    corpo = {"version": 2, chave: [
        {"name": nome, "columns": [{"name": c, "meta": {"sensitivity": n}} for c, n in colunas.items()]}
        for nome, colunas in sorted(modelos.items())
    ]}
    return GENERATED_HEADER + "\n" + yaml.safe_dump(corpo, sort_keys=False, allow_unicode=True, width=120)


def render_files(plano: Plan) -> dict[pathlib.Path, str]:
    """Conteúdo final de cada arquivo que mudaria."""
    saida: dict[pathlib.Path, str] = {}
    for caminho, entradas in plano.patches.items():
        saida[caminho] = patch_yaml(caminho.read_text(encoding="utf-8"), entradas)
    for caminho, modelos in plano.generated.items():
        saida[caminho] = render_generated(modelos, "snapshots" if caminho.parent.name == "snapshots" else "models")
    return saida


def stale_generated(plano: Plan) -> list[pathlib.Path]:
    """`_sensitivity.yml` em disco que nenhum modelo mais habita — todos ganharam entrada à mão."""
    existentes = set((DBT / "models").rglob(GENERATED_FILE)) | set((DBT / "snapshots").rglob(GENERATED_FILE))
    return sorted(existentes - set(plano.generated))


def _verify(caminho: pathlib.Path, conteudo: str, esperado: dict[str, dict[str, str]]) -> None:
    """O arquivo escrito ainda é YAML válido e diz o que se pediu."""
    documento = yaml.safe_load(conteudo)
    entradas = {e["name"]: e for e in documento.get("models", []) + documento.get("snapshots", [])}
    for fonte in documento.get("sources", []):
        entradas.update({t["name"]: t for t in fonte.get("tables", [])})
    for nome, colunas in esperado.items():
        declaradas = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in entradas[nome].get("columns", [])}
        faltam = {c: n for c, n in colunas.items() if declaradas.get(c) != n}
        if faltam:
            raise RuntimeError(f"{caminho.relative_to(ROOT)}: `{nome}` não ficou como esperado: {faltam}")


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    conferir = "--check" in argv
    if not MANIFEST.exists():
        print(f"sem {MANIFEST.relative_to(ROOT)}; rode `make dbt-build` antes", file=sys.stderr)
        return 2
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    derivacao = derive(manifest)
    for aviso in derivacao.warnings:
        print(f"aviso: {aviso}", file=sys.stderr)
    for problema in derivacao.problems:
        print(f"derivação: {problema}", file=sys.stderr)
    if derivacao.problems:
        # Derivação incompleta não escreve nem apaga nada: um manifest de `dbt parse`
        # (sem SQL compilado) deixaria todo modelo com zero colunas, e o arquivo gerado
        # seria reescrito vazio antes de o código de saída dizer que algo falhou.
        print(f"derivação incompleta ({len(derivacao.problems)} problema(s)): nenhum arquivo é tocado; "
              "rode `make dbt-build` (ou `dbt compile`) antes", file=sys.stderr)
        return 1
    plano = plan(manifest, derivacao)
    arquivos = render_files(plano)

    for mudanca in plano.changes:
        print(f"trocado: {mudanca}", file=sys.stderr)
    for pendente in plano.left_to_generator:
        print(f"gerador: {pendente}", file=sys.stderr)

    mudados = {c: t for c, t in arquivos.items() if not c.exists() or c.read_text(encoding="utf-8") != t}
    obsoletos = stale_generated(plano)
    total = sum(len(v) for v in derivacao.levels.values())
    if conferir:
        for caminho in sorted(mudados):
            print(f"desatualizado: {caminho.relative_to(ROOT)}", file=sys.stderr)
        for caminho in obsoletos:
            print(f"obsoleto (sem modelo): {caminho.relative_to(ROOT)}", file=sys.stderr)
        falhou = bool(mudados or obsoletos or plano.left_to_generator)
        print(f"classificação derivada de {total} colunas em {len(derivacao.levels)} nós; "
              f"{len(mudados) + len(obsoletos)} arquivo(s) desatualizado(s)")
        return 1 if falhou else 0

    for caminho, texto in mudados.items():
        esperado = plano.patches.get(caminho) or plano.generated.get(caminho) or {}
        _verify(caminho, texto, esperado)
        caminho.write_text(texto, encoding="utf-8")
        print(f"escrito: {caminho.relative_to(ROOT)}")
    for caminho in obsoletos:
        caminho.unlink()
        print(f"removido: {caminho.relative_to(ROOT)}")
    print(f"classificação derivada de {total} colunas em {len(derivacao.levels)} nós; {len(mudados) + len(obsoletos)} arquivo(s) escrito(s)")
    return 1 if plano.left_to_generator else 0


if __name__ == "__main__":
    raise SystemExit(main())
