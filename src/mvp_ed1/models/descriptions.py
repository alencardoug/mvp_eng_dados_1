"""Descrição de coluna herdada por transporte, declarada uma vez (Governança §5.1).

── O que é declaração e o que é derivado ───────────────────────────────────────
A descrição de cada coluna da origem é **declarada** uma vez, nos modelos
SQLAlchemy (`models/base.py::meta`, obrigatória). Uma coluna do armazém que só
**transporta** esse valor — referência pura, apelido, `cast` de volta ao tipo
declarado (`models/transport.py`) — significa o mesmo que a coluna de onde
veio, e herda o texto dela, salto a salto, até o consumo. O que **calcula** —
agregação, aritmética, função, `case`, comparação, gerado — significa outra
coisa, e só tem descrição se alguém a escrever no `.yml` do modelo.

Linhagem não basta para decidir isso: soma, arredondamento e cópia têm a mesma
folha (RV2-08). Por isso a herança lê a forma da expressão a cada salto, não o
conjunto de folhas.

── As regras (decisões N40–N45 do plano do `bi-como-codigo`) ─────────────────
* **União** (`empilhado`, membro desconhecido): herda quando todo ramo que
  transporta chega ao **mesmo texto**; ramo constante não vota; ramo que calcula,
  ou textos diferentes, pedem texto escrito.
* **Ponte do legado** (`legado__*`): a linhagem dela pula a limpeza, então ela
  só herda pela declaração explícita que `legacy/ponte.py` gera —
  `meta.description_from`, a coluna do `stg_retail__*` que ela reproduz. O texto
  na ponte é escrito pelo gerador; aqui só se confere que ele é o do par.
* **Convenções do projeto**, com texto único num bloco `{% docs %}`
  (`dbt/models/_convencoes.md`), aplicado onde a coluna nasce **com a forma da
  convenção** — nome e expressão: `source_system` como constante de um sistema
  declarado, `is_deleted` como `deleted_at IS NOT NULL`, e as colunas que as
  ferramentas acrescentam (`_airbyte_*`, `_stream_*`, `dbt_*`, a identidade do
  legado) onde a ferramenta as acrescenta. Coluna de mesmo nome e outra forma não
  recebe nada.
* **Texto à mão** numa coluna que herda vale só com `meta.description_reason`;
  sem ele, o herdado o substitui na próxima geração, e a troca é impressa.
* **Proveniência na própria coluna** (RVL3-01, RVL3-2-01, RVL3-3-01). Todo texto
  que a derivação escreve leva `meta.description_inherited: true`, no `.yml` à mão
  e no gerado. A marca anda com a coluna — renomeada, movida de modelo, promovida do
  gerado a um `.yml` à mão — e só sai por quem revisa o texto. Coluna marcada que
  deixou de transportar é problema: o texto é de quem ela lia, e escreve-se o do
  cálculo, tirando a marca. Marca com `description_reason` é contradição, e também
  é problema. Sem marca, texto à mão é raiz escrita; a igualdade com o texto da
  folha imediata continua como segunda rede.

── Onde o resultado é escrito ───────────────────────────────────────────────────
Os mesmos lugares da sensibilidade, pelo mesmo escritor (`sensitivity.main`):
no `.yml` escrito à mão, no lugar; no `_derived.yml` gerado; e em
`_retail__sources.yml`, como espelho da declaração. Os `.yml` de
`make legacy-models` escrevem o próprio texto e não são tocados.
"""

from __future__ import annotations

import json
import pathlib
import re
from collections import defaultdict
from dataclasses import dataclass, field

import yaml

from mvp_ed1.legacy import schema as legacy_schema
from mvp_ed1.models import Base, sensitivity
from mvp_ed1.models.transport import Carry, Computed, Transport

DBT = sensitivity.DBT
Leaf = tuple[str, str, str]

#: A marca de proveniência: o texto desta coluna foi escrito pela derivação, não por quem revisa.
MARK = "description_inherited"

#: O arquivo das pontes do legado (`legacy/ponte.py::gerar`): texto nele só vale com a declaração do par.
BRIDGES_FILE = "_pontes__models.yml"

#: O domínio de `source_system` (macro `empilhado`): as duas origens, e o membro desconhecido das dimensões.
SOURCE_SYSTEMS = frozenset({"retail", "legacy", "unknown"})


def doc_ref(bloco: str) -> str:
    return '{{ doc("' + bloco + '") }}'


def _constantes(t: Transport) -> set[str]:
    return set((t.shape or "").removeprefix("constant:").split("|")) if isinstance(t, Computed) and t.kind == "constant" else set()


#: As convenções que nascem num modelo: por nome, cada forma que ela tem onde nasce e o bloco do seu texto (N44).
#: `is_deleted` tem duas — a exclusão lógica lida de `deleted_at`, e o `false` fixo das tabelas
#: só de acréscimo, que não têm `deleted_at` e guardam a coluna para ter a forma das outras.
CONVENTIONS = {
    "source_system": [(lambda t: bool(_constantes(t)) and _constantes(t) <= SOURCE_SYSTEMS, "source_system")],
    "is_deleted": [(lambda t: isinstance(t, Computed) and t.shape == "not_null:deleted_at", "is_deleted"),
                   (lambda t: _constantes(t) == {"false"}, "is_deleted_append_only")],
}


def convention(coluna: str, t: Transport) -> str | None:
    """O bloco da convenção que esta coluna, com esta forma, segue; `None` se nenhuma."""
    return next((bloco for forma, bloco in CONVENTIONS.get(coluna, []) if forma(t)), None)


def tool_columns() -> dict[tuple[str, str], str]:
    """`(camada, coluna) → bloco` das colunas que uma ferramenta acrescenta à fonte; o snapshot à parte."""
    saida = {(camada, c): c for camada in ("raw", "raw_legacy") for c in sensitivity.AIRBYTE_COLUMNS}
    saida[("raw_legacy", legacy_schema.IDENTIDADE)] = legacy_schema.IDENTIDADE
    saida.update({("stream", c): c for c in sensitivity.STREAM_COLUMNS})
    return saida


def source_texts() -> dict[Leaf, str]:
    """O texto de cada coluna de `raw`, do caminho quente e de `raw_legacy`: a declaração SQLAlchemy e as das ferramentas."""
    ferramentas = tool_columns()
    textos: dict[Leaf, str] = {}
    for table in Base.metadata.tables.values():
        declarada = {c.name: c.info["description"].strip() for c in table.columns}
        for camada in ("raw", "raw_legacy"):
            nomes = legacy_schema.colunas(table.name) if camada == "raw_legacy" else list(declarada)
            textos.update({(camada, table.name, c): declarada[c] for c in nomes})
            textos.update({(camada, table.name, c): doc_ref(b) for (k, c), b in ferramentas.items() if k == camada})
    for sink, origem in sensitivity.STREAM_SINKS.items():
        textos.update({("raw", sink, c.name): c.info["description"].strip() for c in Base.metadata.tables[f"oltp.{origem}"].columns})
        textos.update({("raw", sink, c): doc_ref(b) for (k, c), b in ferramentas.items() if k == "stream"})
    return textos


# ── O que está escrito no disco ─────────────────────────────────────────────────

@dataclass
class Entry:
    """Uma entrada de `.yml` como está no disco: de que tipo é o arquivo, e o que cada coluna diz."""
    path: pathlib.Path
    kind: str                                   # "hand" | "derived" (gerado por make catalog) | "generator" (make legacy-models)
    columns: dict[str, dict]
    meta: dict = field(default_factory=dict)    # o `meta` do modelo, para o domínio (`models/domains.py`)


def _text(coluna: dict) -> str:
    return (coluna.get("description") or "").strip()


def _documents() -> list[tuple[pathlib.Path, dict]]:
    """Cada `.yml` do projeto dbt, lido uma vez."""
    raiz = sensitivity.DBT                     # na chamada: os testes apontam o projeto para outro diretório
    caminhos = sorted(list((raiz / "models").rglob("*.yml")) + list((raiz / "snapshots").rglob("*.yml")) + list((raiz / "seeds").rglob("*.yml")))
    documentos = [(c, sensitivity.read_yaml(c)) for c in caminhos]
    # Uma entrada em dois arquivos: o dbt recusaria, e aqui a segunda encobriria a primeira
    # (RVL3-5-02). A exceção é a promoção documentada — o modelo ganha entrada num `.yml`
    # à mão e ainda está no `_derived.yml`, que a geração vai limpar: aí vale a à mão, e a
    # gerada sai da leitura (RVL3-6-03). Fonte repetida também é recusa (RVL3-6-02).
    vistas: dict[str, pathlib.Path] = {}
    fontes: dict[tuple[str, str], pathlib.Path] = {}
    esquemas: dict[str, tuple[str, pathlib.Path]] = {}       # uma fonte por schema, também entre arquivos
    for caminho, documento in documentos:
        for chave in ("models", "snapshots", "seeds"):
            for e in documento.get(chave) or []:
                anterior = vistas.get(e["name"])
                if anterior is not None and _kind(anterior) != "derived" and _kind(caminho) != "derived":
                    raise ValueError(f"`{e['name']}` documentado em {anterior} e em {caminho}")
                if anterior is None or _kind(anterior) == "derived":
                    vistas[e["name"]] = caminho
        for f in documento.get("sources") or []:
            esquema = f.get("schema") or f.get("name")
            dono, onde = esquemas.setdefault(esquema, (f.get("name"), caminho))
            if dono != f.get("name"):
                raise ValueError(f"schema `{esquema}` declarado pela fonte `{dono}` em {onde} e por `{f.get('name')}` "
                                 f"em {caminho} — uma fonte por schema (RVL3-9-01/02)")
            for tabela in f.get("tables") or []:
                # A identidade é a que `disk_sources` usa para reduzir; com a convenção de
                # `sensitivity._conferir_fonte`, ela é a tabela física (RVL3-7-01, RVL3-8-01, RVL3-9-01/02).
                chave_fonte = sensitivity.source_identity(f, tabela)
                if chave_fonte in fontes:
                    raise ValueError(f"tabela de fonte `{chave_fonte[0]}.{chave_fonte[1]}` em {fontes[chave_fonte]} e em {caminho}")
                fontes[chave_fonte] = caminho
    # A entrada gerada que perdeu para a à mão não é lida.
    return [(c, {**d, **{k: [e for e in d.get(k) or [] if vistas.get(e["name"]) == c]
                        for k in ("models", "snapshots", "seeds") if d.get(k)}}) for c, d in documentos]


def _kind(caminho: pathlib.Path) -> str:
    return "derived" if caminho.name in sensitivity.GENERATED_FILES else "generator" if sensitivity._is_generated(caminho) else "hand"


def disk_sources(documentos: list[tuple[pathlib.Path, dict]] | None = None) -> dict[tuple[str, str], Entry]:
    """`(schema, tabela) → Entry` de cada tabela de fonte declarada nos `.yml` — o texto cru, antes do `doc()` renderizado."""
    saida: dict[tuple[str, str], Entry] = {}
    for caminho, documento in (_documents() if documentos is None else documentos):
        for fonte in documento.get("sources") or []:
            for t in fonte.get("tables") or []:
                saida[sensitivity.source_identity(fonte, t)] = Entry(caminho, _kind(caminho), {c["name"]: c for c in t.get("columns") or []})
    return saida


def disk_entries(documentos: list[tuple[pathlib.Path, dict]] | None = None) -> dict[str, Entry]:
    """`modelo, snapshot ou seed → Entry`, lido de todos os `.yml` do projeto dbt."""
    entradas: dict[str, Entry] = {}
    for caminho, documento in (_documents() if documentos is None else documentos):
        tipo = _kind(caminho)
        for chave in ("models", "snapshots", "seeds"):
            for e in documento.get(chave) or []:
                meta = {**(e.get("meta") or {}), **((e.get("config") or {}).get("meta") or {})}
                entradas[e["name"]] = Entry(caminho, tipo, {c["name"]: c for c in e.get("columns") or []}, meta)
    return entradas


# ── A herança ───────────────────────────────────────────────────────────────────

@dataclass
class Texts:
    """O resultado: o texto final de cada coluna, de onde ele veio, e o que escrever."""
    marks: dict[pathlib.Path, dict[str, dict[str, dict]]] = field(default_factory=lambda: defaultdict(dict))  # .yml à mão → entrada → coluna → {MARK: True}
    texts: dict[Leaf, str] = field(default_factory=dict)
    origin: dict[Leaf, str] = field(default_factory=dict)        # declared | inherited | bridge | convention | written | generator
    undescribed: dict[Leaf, str] = field(default_factory=dict)   # coluna → por que não herdou
    patches: dict[pathlib.Path, dict[str, dict[str, str]]] = field(default_factory=lambda: defaultdict(dict))  # .yml → entrada → coluna → texto
    generated: dict[str, dict[str, str]] = field(default_factory=lambda: defaultdict(dict))                   # modelo de _derived.yml → coluna → texto
    changes: list[str] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)


def _normal(texto: str | None) -> str | None:
    """O texto para comparar: espaços colapsados e `doc('x')` com as aspas de `doc("x")`."""
    if texto is None:
        return None
    # Toda grafia da mesma referência renderiza o mesmo bloco (RVL3-3-02).
    texto = re.sub(r"""\{\{-?\s*doc\s*\(\s*['"]([^'"]+)['"]\s*\)\s*-?\}\}""", r'{{ doc("\1") }}', texto)
    return " ".join(texto.split())


def _why_not(t: Transport, textos: list[str | None]) -> str:
    if isinstance(t, Computed):
        return t.kind
    return "union_differs" if all(textos) else "upstream_blank"


def derive_texts(manifest: dict, derivation: sensitivity.Derivation,
                 disco: dict[str, Entry] | None = None, fontes: dict[tuple[str, str], Entry] | None = None) -> Texts:
    documentos = _documents() if disco is None or fontes is None else None
    disco = disk_entries(documentos) if disco is None else disco
    fontes = disk_sources(documentos) if fontes is None else fontes
    saida = Texts()
    saida.texts.update(source_texts())
    saida.origin.update(dict.fromkeys(saida.texts, "declared"))

    # O espelho de `raw` em _retail__sources.yml; a conferência do que o gerador escreveu para
    # `raw_legacy`; e o que as demais fontes (`governance`) declaram, como declaração.
    for (schema, tabela), entrada in fontes.items():
        for nome, c in entrada.columns.items():
            esperado = saida.texts.get((schema, tabela, nome))
            if schema == "raw" and esperado and _text(c) != esperado:
                saida.patches[entrada.path].setdefault(tabela, {})[nome] = esperado
            elif schema == "raw_legacy" and esperado and _text(c) != esperado:
                saida.problems.append(f"raw_legacy.{tabela}.{nome}: o texto do gerador não é o da declaração; rode `make legacy-models`")
            elif schema not in ("raw", "raw_legacy") and _text(c):
                saida.texts[(schema, tabela, nome)] = _text(c)
                saida.origin[(schema, tabela, nome)] = "declared"

    nos = {k: v for k, v in manifest["nodes"].items() if v["resource_type"] in ("model", "seed", "snapshot")}
    por_nome = {no["name"]: k for k, no in nos.items()}
    # A ponte não lê o par no SQL — lê o JSON do legado —, mas o texto dela é o dele:
    # a declaração entra na ordem como dependência, para o par ser lido antes.
    ordem = {k: {**no, "depends_on": {"nodes": list(no["depends_on"].get("nodes", [])) + [
        por_nome[par.partition(".")[0]] for c in (disco[no["name"]].columns.values() if no["name"] in disco else [])
        if (par := (c.get("meta") or {}).get("description_from")) and par.partition(".")[0] in por_nome]}}
        for k, no in nos.items()}
    for node_id in sensitivity._topological(ordem):
        if node_id not in derivation.levels:
            continue
        no = nos[node_id]
        relacao = no.get("alias") or no["name"]
        entrada = disco.get(no["name"])
        for coluna in derivation.levels[node_id]:
            chave = (no["schema"], relacao, coluna)
            no_disco = entrada.columns.get(coluna, {}) if entrada else {}
            escrito = _text(no_disco)
            motivo = (no_disco.get("meta") or {}).get("description_reason")
            marca = bool((no_disco.get("meta") or {}).get(MARK))
            t = derivation.carries.get(node_id, {}).get(coluna, Computed("unresolved"))
            herdado, como, candidatos = None, None, []

            if no["resource_type"] == "seed":
                pass                                           # seed é declaração: só o que está no _seeds.yml
            elif (par := (no_disco.get("meta") or {}).get("description_from")):
                modelo, _, coluna_par = par.partition(".")
                alvo = nos.get(por_nome.get(modelo, ""))
                herdado = saida.texts.get((alvo["schema"], alvo.get("alias") or alvo["name"], coluna_par)) if alvo else None
                como = "bridge"
                if alvo is None:
                    saida.problems.append(f"{no['name']}.{coluna}: `description_from: {par}` não é coluna de modelo nenhum")
            elif isinstance(t, Carry):
                candidatos = [saida.texts.get(f) for f in sorted(t.leaves)]
                if all(candidatos) and len(set(candidatos)) == 1:
                    herdado, como = candidatos[0], "inherited"
            elif no["resource_type"] == "snapshot" and coluna in sensitivity.SNAPSHOT_COLUMNS:
                herdado, como = doc_ref(coluna), "convention"
            elif (bloco := convention(coluna, t)):
                herdado, como = doc_ref(bloco), "convention"

            if entrada and entrada.kind == "generator":
                final, origem = escrito or None, "generator"
                if como == "bridge" and herdado and escrito != herdado:
                    saida.problems.append(f"{no['name']}.{coluna}: a ponte não traz o texto de `{par}`; rode `make legacy-models`")
                elif entrada.path.name == BRIDGES_FILE and escrito and como != "bridge":
                    # A ponte só significa o que o par significa por declaração (N41):
                    # texto sem `description_from` não vale, nem para quem a empilha.
                    saida.problems.append(f"{no['name']}.{coluna}: texto na ponte sem `description_from`; rode `make legacy-models`")
                    final = None
            elif motivo and escrito:
                final, origem = escrito, "written"
                if marca:
                    saida.problems.append(f"{no['name']}.{coluna}: `{MARK}` e `description_reason` juntos — "
                                          "o texto é revisto ou herdado; tire a marca")
            elif herdado:
                final, origem = herdado, como
                if entrada and entrada.kind == "hand":
                    if not marca:
                        saida.marks[entrada.path].setdefault(no["name"], {})[coluna] = {MARK: True}
                    if escrito != herdado:
                        saida.patches[entrada.path].setdefault(no["name"], {})[coluna] = herdado
                        if escrito:
                            # Herdado que ficou para trás, ou texto à mão sem motivo — o `.yml`
                            # não distingue os dois, e a regra é a mesma: vale o herdado.
                            saida.changes.append(f"{no['name']}.{coluna}: texto sem `description_reason`, diferente do herdado, reescrito")
                else:
                    saida.generated[no["name"]][coluna] = herdado
            elif escrito and entrada and entrada.kind == "hand":
                final, origem = escrito, "written"
                # O `.yml` à mão guarda também o herdado que a derivação escreveu nele.
                # Quando a coluna deixa de transportar, esse texto ficaria como raiz
                # escrita, calado — e é o texto de quem ela lia, não do que ela calcula
                # agora (RVL3-01). Igual ao texto de uma folha, sem motivo: problema.
                folhas = derivation.leaves.get(node_id, {}).get(coluna, set())
                if marca or any(_normal(saida.texts.get(f)) == _normal(escrito) for f in folhas):
                    saida.problems.append(
                        f"{no['name']}.{coluna}: não transporta mais ({_why_not(t, candidatos)}) e guarda o texto "
                        "de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`")
            else:
                final, origem = None, None

            if final:
                saida.texts[chave], saida.origin[chave] = final, origem
            elif no["resource_type"] != "seed":
                saida.undescribed[chave] = _why_not(t, candidatos) if como != "bridge" else "bridge_pair_blank"
            else:
                saida.undescribed[chave] = "seed"
    return saida


# ── Escrita: no lugar, linha a linha ────────────────────────────────────────────

def _scalar(texto: str) -> str:
    """O texto como escalar YAML de uma linha — aspas duplas, escapes do JSON, que o YAML lê igual."""
    return json.dumps(texto, ensure_ascii=False)


def patch_descriptions(texto: str, entradas: dict[str, dict[str, str]]) -> str:
    """Insere ou substitui a `description` de cada coluna de cada entrada, preservando o resto."""
    _indent, _block_end, _find_entry = sensitivity._indent, sensitivity._block_end, sensitivity._find_entry
    linhas = texto.split("\n")
    for entrada, colunas in entradas.items():
        for coluna, valor in colunas.items():
            inicio = _find_entry(linhas, entrada)
            if inicio is None:
                raise KeyError(f"entrada `{entrada}` não encontrada")
            base = _indent(linhas[inicio])
            fim = _block_end(linhas, inicio, base)
            bloco = linhas[inicio:fim]
            idx_cols = next((i for i, l in enumerate(bloco) if l.strip() == "columns:" and _indent(l) == base + 2), None)
            if idx_cols is None:
                raise KeyError(f"`{entrada}` sem `columns:` — a sensibilidade é escrita antes da descrição")
            item = base + 4
            idx_col = next((i for i in range(idx_cols + 1, len(bloco)) if bloco[i].strip() == f"- name: {coluna}" and _indent(bloco[i]) == item), None)
            nova = " " * (item + 2) + f"description: {_scalar(valor)}"
            if idx_col is None:
                fim_cols = len(bloco)
                while fim_cols > idx_cols + 1 and not bloco[fim_cols - 1].strip():
                    fim_cols -= 1
                bloco[fim_cols:fim_cols] = [" " * item + f"- name: {coluna}", nova]
            else:
                fim_col = _block_end(bloco, idx_col, item)
                idx_desc = next((i for i in range(idx_col + 1, fim_col) if bloco[i].strip().startswith("description:") and _indent(bloco[i]) == item + 2), None)
                if idx_desc is None:
                    bloco.insert(idx_col + 1, nova)
                else:
                    fim_desc = _block_end(bloco, idx_desc, item + 2)       # escalar de várias linhas (`>`, `|`)
                    bloco[idx_desc:fim_desc] = [nova]
            linhas[inicio:fim] = bloco
    return "\n".join(linhas)


def verify(caminho: pathlib.Path, conteudo: str, esperado: dict[str, dict[str, str]]) -> None:
    """O arquivo escrito ainda é YAML válido e traz o texto que se pediu, coluna a coluna."""
    documento = yaml.safe_load(conteudo)
    entradas = {e["name"]: e for k in ("models", "snapshots", "seeds") for e in documento.get(k) or []}
    for fonte in documento.get("sources", []):
        entradas.update({t["name"]: t for t in fonte.get("tables", [])})
    for nome, colunas in esperado.items():
        escritas = {c["name"]: _text(c) for c in entradas[nome].get("columns", [])}
        faltam = sorted(c for c, t in colunas.items() if escritas.get(c) != t.strip())
        if faltam:
            raise RuntimeError(f"{caminho.relative_to(sensitivity.ROOT)}: `{nome}` sem o texto esperado em {faltam}")
