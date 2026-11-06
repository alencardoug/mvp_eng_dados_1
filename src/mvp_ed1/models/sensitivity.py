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
* modelo sem entrada em `.yml` nenhum: entra em `_derived.yml` no diretório
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
coisa de que `models/lineage.py` parte para fechar a linhagem até a origem; e o
que cada coluna faz com o valor (`Derivation.carries`, `models/transport.py`) é o
de que `models/descriptions.py` parte para herdar a descrição. Uma leitura do SQL,
três derivados — e guardada (`load`), porque o `make check` a pede três vezes. A
descrição é escrita pelo mesmo `main`, nos mesmos arquivos.

Uso: ``python -m mvp_ed1.models.sensitivity [--check]`` (também em ``make catalog``):
escreve, ou confere, a classificação e a descrição.
"""

from __future__ import annotations

import csv
import hashlib
import json
import pathlib
import pickle
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field

import sqlglot
import yaml
from sqlglot import exp
from sqlglot.optimizer.qualify import qualify
from sqlglot.optimizer.scope import Scope, traverse_scope

from mvp_ed1.legacy import schema as legacy_schema
from mvp_ed1.models import Base, transport
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
#: O tipo físico que o dbt-postgres dá a elas (medido no armazém em 05/11/2026): sem fuso.
SNAPSHOT_TYPES = {"dbt_scd_id": "TEXT", "dbt_updated_at": "TIMESTAMP", "dbt_valid_from": "TIMESTAMP", "dbt_valid_to": "TIMESTAMP"}
GENERATED_FILE = "_derived.yml"
GENERATED_HEADER = (
    "# Gerado por `make catalog` (mvp_ed1/models/sensitivity.py). Não edite: a\n"
    "# classificação e a descrição são derivadas, por linhagem, das declaradas nos\n"
    "# modelos SQLAlchemy (models/descriptions.py para a descrição). Modelo que\n"
    "# ganhar entrada num .yml escrito à mão sai daqui na próxima geração.\n"
)
#: Os nomes que o arquivo gerado já teve: até a v1.1.0 ele só levava a sensibilidade.
#: Um arquivo com o nome antigo é obsoleto, e a geração o remove.
GENERATED_FILES = (GENERATED_FILE, "_sensitivity.yml")
#: A derivação guardada entre processos (`load`): o `make check` a pede três
#: vezes — classificação, linhagem e os testes —, e cada uma custa ~21 s.
CACHE = DBT / "target" / "mvp_ed1_derivation.pickle"


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


def _sql_type(sa_type) -> str:
    """O tipo SQLAlchemy na grafia que o `sqlglot` dá ao alvo de um `cast` no PostgreSQL."""
    from sqlalchemy.dialects import postgresql
    return exp.DataType.build(sa_type.compile(dialect=postgresql.dialect()), dialect="postgres").sql("postgres")


def source_types() -> dict[tuple[str, str, str], str]:
    """Tipo declarado na origem de cada coluna de `raw`, do caminho quente e de `raw_legacy`.

    Em `raw`, o declarado nos modelos SQLAlchemy — o Airbyte grava mais largo, e o
    `staging` devolve a coluna ao tipo declarado. Em `raw_legacy`, texto: é o que
    a tabela do legado é, por desenho.
    """
    tipos: dict[tuple[str, str, str], str] = {}
    for table in Base.metadata.tables.values():
        tipos.update({("raw", table.name, c.name): _sql_type(c.type) for c in table.columns})
        tipos.update({("raw_legacy", table.name, c): "TEXT" for c in legacy_schema.colunas(table.name)})
    for sink, origem in STREAM_SINKS.items():
        tipos.update({("raw", sink, c.name): _sql_type(c.type) for c in Base.metadata.tables[f"oltp.{origem}"].columns})
    return tipos


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
    """O resultado: nível por coluna de cada nó, as folhas de que cada coluna é feita, e o que não pôde ser derivado.

    `carries` diz, por coluna, se ela transporta o valor de outra ou o calcula
    (`models/transport.py`) — a mesma leitura do SQL, para a herança de descrição;
    `origin_types`, o tipo declarado na origem de cada coluna que só transporta.
    """
    levels: dict[str, dict[str, str]] = field(default_factory=dict)      # node_id → coluna → nível
    leaves: dict[str, dict[str, set["Leaf"]]] = field(default_factory=dict)  # node_id → coluna → folhas imediatas
    carries: dict[str, dict[str, transport.Transport]] = field(default_factory=dict)  # node_id → coluna → transporte
    origin_types: dict[tuple[str, str, str], str] = field(default_factory=dict)       # (schema, relação, coluna) → tipo
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
    saida.origin_types = source_types()

    for node_id in _topological(nos):
        no = nos[node_id]
        relacao = no.get("alias") or no["name"]
        transportes: dict[str, transport.Transport] = {}
        if no["resource_type"] == "seed":
            declarado = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in no.get("columns", {}).values()}
            colunas = {}
            for nome in _seed_columns(no):
                if not declarado.get(nome):
                    saida.problems.append(f"{node_id}: coluna `{nome}` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado")
                colunas[nome] = declarado.get(nome) or TECHNICAL
            folhas = {nome: set() for nome in colunas}     # seed é origem: não vem de lugar nenhum
            transportes = {nome: transport.Computed("seed") for nome in colunas}
        else:
            folhas, arvore = _derive_node(no, esquema, niveis, banco, saida.problems, saida.warnings)
            colunas = {nome: strictest([niveis[f] for f in chaves]) for nome, chaves in folhas.items()}
            if arvore is not None:
                transportes = transport.carries_by_output(arvore, (no["schema"], relacao), saida.origin_types.get)
            if no["resource_type"] == "snapshot":
                colunas.update(dict.fromkeys(SNAPSHOT_COLUMNS, TECHNICAL))
                folhas.update({c: set() for c in SNAPSHOT_COLUMNS})
                transportes.update({c: transport.Computed("snapshot_meta") for c in SNAPSHOT_COLUMNS})
        saida.leaves[node_id] = folhas
        saida.carries[node_id] = {c: transportes.get(c, transport.Computed("unresolved")) for c in folhas}
        for coluna, t in saida.carries[node_id].items():
            tipos = ({saida.origin_types.get(f) for f in t.leaves} if isinstance(t, transport.Carry)
                     else {SNAPSHOT_TYPES.get(coluna)} if t.kind == "snapshot_meta" else {transport.materialized_type(t)})
            if len(tipos) == 1 and None not in tipos:
                saida.origin_types[(no["schema"], relacao, coluna)] = tipos.pop()
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


def _inputs_digest(manifest: bytes) -> str:
    """Tudo o que a derivação lê: o manifest, a declaração e o código que a faz, as seeds, o `sqlglot`."""
    h = hashlib.sha256(manifest)
    # Os modelos SQLAlchemy, este módulo e o `transport`; não os que leem a derivação depois.
    leitores = {"descriptions.py", "lineage.py", "export.py"}
    pacote = pathlib.Path(__file__).resolve().parents[1]           # o código que roda, onde quer que o ROOT aponte
    codigo = sorted(c for c in (pacote / "models").glob("*.py") if c.name not in leitores)
    codigo.append(pacote / "legacy" / "schema.py")
    for caminho in codigo:
        h.update(caminho.name.encode() + b"\0" + caminho.read_bytes())
    for caminho in sorted((DBT / "seeds").rglob("*.csv")):
        # O cabeçalho como o CSV o lê — um registro, que pode ter quebra de linha
        # entre aspas —, e não a primeira linha física (RVL3-09).
        with caminho.open(newline="", encoding="utf-8") as arquivo:
            cabecalho = next(csv.reader(arquivo), [])
        h.update(caminho.name.encode() + b"\0" + json.dumps(cabecalho).encode())   # lista sem ambiguidade (RVL3-2-09)
    h.update(f"{sqlglot.__version__}|{sys.version}".encode())
    return h.hexdigest()


_BLOCO_SNAPSHOT = re.compile(r"\{%-?\s*snapshot\s+\w+\s*-?%\}(.*?)\{%-?\s*endsnapshot\s*-?%\}", re.S)


_COMENTARIO_JINJA = re.compile(r"\{#.*?#\}", re.S)


def _sem_comentario(texto: str) -> str:
    """O texto sem os comentários Jinja: uma definição antiga guardada em `{# … #}` não é a ativa (RVL3-3-05)."""
    return _COMENTARIO_JINJA.sub("", texto)


def _declaracoes_no_disco() -> tuple[dict[str, dict[str, dict]], dict[tuple[str, str], dict[str, dict]]]:
    """O que os `.yml` do disco declaram como entrada da derivação: nó → coluna → meta, e fonte → coluna → meta."""
    nos: dict[str, dict[str, dict]] = {}
    fontes: dict[tuple[str, str], dict[str, dict]] = {}
    for pasta in ("models", "snapshots", "seeds"):
        for caminho in sorted((DBT / pasta).rglob("*.yml")):
            documento = read_yaml(caminho)
            for chave in ("models", "snapshots", "seeds"):
                for entrada in documento.get(chave) or []:
                    if caminho.name in GENERATED_FILES and entrada["name"] in nos:
                        continue                                  # a entrada à mão vence a gerada (promoção)
                    nos[entrada["name"]] = {c["name"]: (c.get("meta") or {}) for c in entrada.get("columns") or []}
            for fonte in documento.get("sources") or []:
                for tabela in fonte.get("tables") or []:
                    fontes[(fonte["name"], tabela["name"])] = {c["name"]: (c.get("meta") or {}) for c in tabela.get("columns") or []}
    return nos, fontes


def _declaracao_atrasada(manifest: dict) -> list[str]:
    """As declarações de `.yml` que a derivação lê do manifest e que mudaram no disco depois do build (RVL3-3-04).

    São três, e só elas: o nível com `sensitivity_reason` de uma coluna de modelo
    (a ponte do legado), o nível de cada coluna de seed, e o de cada coluna das
    fontes que não são espelho (`governance`). O resto do `.yml` a derivação lê do
    disco, ou escreve."""
    nos_disco, fontes_disco = _declaracoes_no_disco()
    atrasadas = []
    for no in manifest["nodes"].values():
        if no["resource_type"] not in ("model", "seed", "snapshot"):
            continue
        manifesto = {c["name"]: (c.get("meta") or {}) for c in no.get("columns", {}).values()}
        # Entrada que sumiu do disco conta como declaração vazia: a do manifest
        # continuaria valendo calada (RVL3-4-04).
        disco = nos_disco.get(no["name"], {})
        if no["resource_type"] == "seed":
            par = lambda m: m.get("sensitivity")
            nomes = set(manifesto) | set(disco)
        else:
            par = lambda m: (m.get("sensitivity"), m.get("sensitivity_reason"))
            nomes = {c for c, m in {**manifesto, **disco}.items()
                     if (manifesto.get(c) or {}).get("sensitivity_reason") or (disco.get(c) or {}).get("sensitivity_reason")}
        if any(par(manifesto.get(c) or {}) != par(disco.get(c) or {}) for c in nomes):
            atrasadas.append(f"declaração de {no['name']}")
    for fonte in manifest.get("sources", {}).values():
        if fonte["schema"] in ("raw", "raw_legacy"):
            continue
        disco = fontes_disco.get((fonte["source_name"], fonte["name"]), {})
        manifesto = {c["name"]: (c.get("meta") or {}) for c in fonte.get("columns", {}).values()}
        if {c: m.get("sensitivity") for c, m in manifesto.items()} != {c: m.get("sensitivity") for c, m in disco.items()}:
            atrasadas.append(f"declaração da fonte {fonte['source_name']}.{fonte['name']}")
    return atrasadas


class _SemChaveRepetida(getattr(yaml, "CSafeLoader", yaml.SafeLoader)):
    """O carregador que recusa chave repetida: o `safe_load` ficaria com a última, calado (RVL3-4-01, RVL3-5-02)."""


def _mapa_sem_repeticao(carregador, no, deep=False):
    vistas = set()
    for chave_no, _ in no.value:
        chave = carregador.construct_object(chave_no, deep=deep)
        if chave in vistas:
            raise ValueError(f"chave `{chave}` repetida (linha {chave_no.start_mark.line + 1})")
        vistas.add(chave)
    return yaml.constructor.SafeConstructor.construct_mapping(carregador, no, deep=deep)


_SemChaveRepetida.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _mapa_sem_repeticao)


_NOME_SIMPLES = re.compile(r"[a-z_][a-z0-9_]*")


def source_identity(fonte: dict, tabela: dict) -> tuple[str, str]:
    """A tabela que a declaração de fonte nomeia: (schema efetivo, nome da tabela).

    Só é a tabela física porque a convenção abaixo (`_conferir_fonte`) o garante: sem
    `identifier`, sem `quoting`, nome em minúsculas e uma fonte por schema — o nome
    lógico com que o catálogo escreve é o nome físico com que ele lê (RVL3-9-01/02)."""
    return (fonte.get("schema") or fonte.get("name"), tabela.get("name"))


def _conferir_fonte(caminho: pathlib.Path, fonte: dict) -> None:
    """Uma tabela de fonte tem um nome só, que é o físico — o resto é recusa (RVL3-9-01/02).

    O dbt permite apelidar a tabela física (`identifier`), mudar a caixa e as aspas
    (`quoting`) e declarar duas fontes no mesmo schema. Cada uma dessas formas cria um
    segundo nome para a mesma tabela, e o catálogo escreveria por um e leria por outro:
    a cada rodada de revisão apareceu uma variante. O projeto não usa nenhuma; em vez
    de resolver todas, recusa todas — falha fechada, com a regra escrita."""
    nome = fonte.get("name") or ""
    esquema = fonte.get("schema") or nome
    if "quoting" in fonte:
        raise ValueError(f"{caminho}: fonte `{nome}` com `quoting` — declare o nome físico em minúsculas, sem aspas")
    if "overrides" in fonte:
        # A identidade efetiva vem do pacote sobreposto, que o leitor não lê (RVL3-10-03).
        raise ValueError(f"{caminho}: fonte `{nome}` com `overrides` — fonte de pacote não é catalogada")
    for valor, o_que in ((nome, "nome de fonte"), (esquema, "schema de fonte")):
        if not _NOME_SIMPLES.fullmatch(valor):
            raise ValueError(f"{caminho}: {o_que} `{valor}` fora de `[a-z_][a-z0-9_]*`")
    for tabela in fonte.get("tables") or []:
        t = tabela.get("name") or ""
        if not _NOME_SIMPLES.fullmatch(t):
            raise ValueError(f"{caminho}: tabela de fonte `{nome}.{t}` fora de `[a-z_][a-z0-9_]*`")
        if "quoting" in tabela or ("identifier" in tabela and tabela["identifier"] != t):
            raise ValueError(f"{caminho}: tabela de fonte `{nome}.{t}` com `identifier`/`quoting` — "
                             "um nome só, o físico")


def foreign_sources(manifest: dict) -> list[str]:
    """Fontes que o manifest efetivo traz de outro pacote: o leitor só lê os `.yml` do projeto raiz, e a
    identidade delas — `identifier`, schema, sobreposição — não passa pela convenção acima (RVL3-10-03)."""
    raiz = manifest.get("metadata", {}).get("project_name", "mvp_ed1")
    return sorted(k for k, f in manifest.get("sources", {}).items() if f.get("package_name", raiz) != raiz)


def read_yaml(caminho: pathlib.Path, conteudo: str | None = None) -> dict:
    """Um `.yml` do projeto, lido **sem perder ocorrência** (RVL3-5-02): chave repetida num
    mapa e coluna repetida numa entrada são erro, não a última que vence — uma marca de
    herdado encoberta por uma segunda ocorrência sem ela faria o texto velho virar raiz."""
    texto = caminho.read_text(encoding="utf-8") if conteudo is None else conteudo
    try:
        documento = yaml.load(texto, Loader=_SemChaveRepetida) or {}
    except (ValueError, yaml.YAMLError) as erro:
        raise ValueError(f"{caminho}: {erro}") from None
    for entrada in (e for k in ("models", "snapshots", "seeds") for e in documento.get(k) or []):
        if "meta" in entrada and "meta" in (entrada.get("config") or {}):
            # O dbt recusa o par no nível da entrada; o leitor juntaria os dois, e um
            # escritor que o criasse passaria calado até o próximo parse (RVL3-11-02).
            raise ValueError(f"{caminho}: `{entrada.get('name')}` tem `meta` e `config.meta` — o dbt aceita um só")
    entradas = [e for k in ("models", "snapshots", "seeds") for e in documento.get(k) or []]
    entradas += [t for f in documento.get("sources") or [] for t in f.get("tables") or []]
    for fonte in documento.get("sources") or []:
        _conferir_fonte(caminho, fonte)
    por_esquema: dict[str, str] = {}
    for fonte in documento.get("sources") or []:
        esquema = fonte.get("schema") or fonte.get("name")
        if por_esquema.setdefault(esquema, fonte.get("name")) != fonte.get("name"):
            raise ValueError(f"{caminho}: schema `{esquema}` declarado por duas fontes, "
                             f"`{por_esquema[esquema]}` e `{fonte.get('name')}` — uma fonte por schema")
    tabelas = [source_identity(f, t) for f in documento.get("sources") or [] for t in f.get("tables") or []]
    if repetidas := sorted({x for x in tabelas if tabelas.count(x) > 1}):
        raise ValueError(f"{caminho}: tabela(s) de fonte {repetidas} declarada(s) mais de uma vez")   # RVL3-6-02
    for entrada in entradas:
        nomes = [c.get("name") for c in entrada.get("columns") or []]
        if repetidas := sorted({n for n in nomes if nomes.count(n) > 1}):
            raise ValueError(f"{caminho}: `{entrada.get('name')}` lista a(s) coluna(s) {repetidas} mais de uma vez")
        for coluna in entrada.get("columns") or []:
            _unificar_meta(caminho, entrada.get("name"), coluna)
    return documento


def _unificar_meta(caminho: pathlib.Path, entrada: str, coluna: dict) -> None:
    """`config.meta` da coluna entra em `meta`, como o dbt as junta (RVL3-6-01).

    Quem lê os metadados da coluna lê `meta`; uma marca de herdado movida para
    `config.meta` — sintaxe que o dbt aceita — sumiria da leitura e o texto velho
    viraria raiz. A mesma chave nas duas grafias, com valores diferentes, é recusa."""
    config = coluna.get("config") or {}
    de_config = config.get("meta") or {}
    if not de_config:
        return
    meta = coluna.get("meta") or {}
    if conflito := sorted(k for k in set(meta) & set(de_config) if meta[k] != de_config[k]):
        raise ValueError(f"{caminho}: `{entrada}.{coluna.get('name')}` tem {conflito} em `meta` e em `config.meta`, diferentes")
    coluna["meta"] = {**meta, **de_config}


def _linhas(texto: str) -> str:
    """Quebras normalizadas (o manifest guarda o `\\r\\n` que o disco lido em modo texto perde) e bordas aparadas."""
    return texto.replace("\r\n", "\n").replace("\r", "\n").strip()


def stale_nodes(manifest: dict) -> list[str]:
    """Os modelos, snapshots e macros cujo texto no disco não é o que o manifest compilou (RVL3-07).

    A derivação lê o SQL **compilado** do manifest; a chave do cache e o 14fdf30
    não veem um `.sql` alterado depois do último `dbt build`. O `raw_code` do
    manifest é o texto do arquivo — inteiro no modelo, o miolo do bloco no
    snapshot, comparado ao miolo do bloco do disco, não por trecho (RVL3-2-05) — e
    o `macro_sql` de cada macro do projeto tem de estar no arquivo dela.

    Do `.yml`, conferem-se as declarações que a derivação lê do manifest
    (`_declaracao_atrasada`, RVL3-3-04); o comentário Jinja não conta como
    definição de macro (RVL3-3-05).

    **Limite declarado** (RVL3-2-07): macro nova ou apagada, o `dbt_project.yml`
    e nó que o manifest não tem não se conferem aqui; a compilação recente
    continua sendo a premissa, e o `make check` a cumpre com o build antes."""
    atrasados = []
    for no in manifest["nodes"].values():
        if no["resource_type"] not in ("model", "snapshot") or not no.get("original_file_path"):
            continue
        caminho = DBT / no["original_file_path"]
        disco = _linhas(caminho.read_bytes().decode("utf-8")) if caminho.exists() else None
        codigo = _linhas(no.get("raw_code") or "")
        if disco is not None and no["resource_type"] == "snapshot":
            bloco = _BLOCO_SNAPSHOT.search(disco)
            disco = _linhas(bloco.group(1)) if bloco else None
        if disco is None or codigo != disco:
            atrasados.append(no["name"])
    for macro in manifest.get("macros", {}).values():
        if macro.get("package_name") != manifest.get("metadata", {}).get("project_name", "mvp_ed1"):
            continue
        caminho = DBT / macro.get("original_file_path", "")
        ativo = _linhas(_sem_comentario(caminho.read_bytes().decode("utf-8"))) if caminho.is_file() else None
        if ativo is None or _linhas(_sem_comentario(macro.get("macro_sql") or "")) not in ativo:
            atrasados.append(f"macro {macro['name']}")
    return sorted(atrasados + _declaracao_atrasada(manifest))


def load(manifest_path: pathlib.Path | None = None) -> tuple[dict, Derivation]:
    """O manifest e a sua derivação — guardada em `CACHE`, refeita quando qualquer entrada muda (RV2-10).

    A chave é o conteúdo de tudo o que `derive` lê, não a data dos arquivos: um
    `dbt build` que reescreve o manifest igual reaproveita; uma linha mudada num
    modelo SQLAlchemy, no código da derivação ou no SQL compilado, não. Derivação
    com problema não é guardada. Guardam-se os campos, e não a instância: rodado
    como `python -m`, este módulo é `__main__`, e a classe gravada não se abriria
    em outro processo.
    """
    dados = (MANIFEST if manifest_path is None else manifest_path).read_bytes()   # resolvido na chamada, não na definição
    manifest = json.loads(dados)
    chave = _inputs_digest(dados)
    try:
        with CACHE.open("rb") as arquivo:
            guardada = pickle.load(arquivo)
        if guardada.get("key") == chave:
            return manifest, Derivation(**guardada["fields"])
    except Exception:  # noqa: BLE001 — cache ausente, de outra versão ou corrompido: deriva de novo
        pass
    derivacao = derive(manifest)
    if not derivacao.problems:
        provisorio = CACHE.with_name(CACHE.name + ".tmp")
        with provisorio.open("wb") as arquivo:
            pickle.dump({"key": chave, "fields": vars(derivacao)}, arquivo)
        provisorio.replace(CACHE)
    return manifest, derivacao


def _derive_node(no: dict, esquema, niveis, banco: str, problems: list[str], warnings: list[str]) -> tuple[dict[str, set["Leaf"]], exp.Expression | None]:
    """Por coluna de saída do nó, as folhas imediatas — colunas de fonte ou de modelo anterior —, e a árvore qualificada."""
    sql = no.get("compiled_code") or ""
    if not sql.strip():
        problems.append(f"{no['unique_id']}: sem SQL compilado no manifest; rode `make dbt-build`")
        return {}, None
    catalogo = {banco: {s: dict(t) for s, t in esquema.items()}}
    try:
        arvore = sqlglot.parse_one(sql, read="postgres")
        qualificada = qualify(arvore, schema=catalogo, dialect="postgres", validate_qualify_columns=False)
    except Exception as erro:  # noqa: BLE001 — o que interessa é o nó e o motivo
        problems.append(f"{no['unique_id']}: não qualificável ({str(erro)[:120]})")
        return {}, None
    folhas = _leaves_by_output(qualificada, no["unique_id"], (no["schema"], no.get("alias") or no["name"]), niveis, problems, warnings)
    if not folhas:
        problems.append(f"{no['unique_id']}: nenhuma projeção reconhecida no SQL compilado")
    return folhas, qualificada


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
    patches: dict[pathlib.Path, dict[Address, dict[str, str]]] = field(default_factory=lambda: defaultdict(dict))   # yml → endereço → coluna → nível
    generated: dict[pathlib.Path, dict[str, dict[str, str]]] = field(default_factory=lambda: defaultdict(dict))  # _derived.yml → modelo → coluna → nível
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
        documento = read_yaml(caminho)
        for entrada in (documento.get("models") or []) + (documento.get("snapshots") or []):
            colunas = {c["name"]: (c.get("meta") or {}) for c in entrada.get("columns") or []}
            entradas[entrada["name"]] = (caminho, colunas)
    return entradas


def generator_entries() -> dict[str, pathlib.Path]:
    """`modelo → .yml` dos arquivos gerados por `make legacy-models`, **lidos do disco**.

    É o disco, como em `manual_entries`, que diz onde um modelo está documentado:
    um manifest compilado antes de um `.yml` à mão ser removido ainda aponta o
    modelo para ele, e decidir por esse `patch_path` deixaria o modelo fora do
    arquivo gerado sem aviso nenhum.
    """
    entradas: dict[str, pathlib.Path] = {}
    for caminho in sorted(list((DBT / "models").rglob("*.yml")) + list((DBT / "snapshots").rglob("*.yml"))):
        if caminho.name in GENERATED_FILES or not _is_generated(caminho):
            continue
        documento = read_yaml(caminho)
        for entrada in (documento.get("models") or []) + (documento.get("snapshots") or []):
            entradas[entrada["name"]] = caminho
    return entradas


def plan(manifest: dict, derivation: Derivation) -> Plan:
    resultado = Plan()
    manuais = manual_entries()
    do_gerador = generator_entries()
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
        if no["name"] not in do_gerador:
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
        caminho = do_gerador[no["name"]]
        resultado.left_to_generator.append(f"{no['name']}: {len(alvo)} colunas sem sensitivity em {caminho.relative_to(ROOT)} (gerado)")

    # Fontes raw: colunas sob cada tabela de _retail__sources.yml.
    _, niveis = source_leaves()
    for fonte in manifest["sources"].values():
        if fonte["schema"] != "raw":
            continue
        declaradas = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in fonte.get("columns", {}).values()}
        alvo = {c: n for (s, t, c), n in niveis.items() if s == "raw" and t == fonte["identifier"] and declaradas.get(c) != n}
        if alvo:
            resultado.patches[DBT / fonte["original_file_path"]][(fonte["source_name"], fonte["name"])] = alvo
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


# O endereço de uma entrada num `.yml`: o nome, para modelo, snapshot e seed — que vivem no
# bloco de topo e têm nome único no projeto —, e o par (fonte, tabela) para a tabela de fonte.
# Duas fontes podem ter tabelas homônimas em schemas diferentes no mesmo arquivo
# (`raw.order_items`, `raw_legacy.order_items`); o nome sozinho escreveria na primeira (RVL3-10-01).
Address = str | tuple[str, str]
_TOPO = ("models", "snapshots", "seeds")


def address_label(endereco: Address) -> str:
    return ".".join(endereco) if isinstance(endereco, tuple) else endereco


def _ativa(linha: str) -> bool:
    texto = linha.strip()
    return bool(texto) and not texto.startswith("#")


def _fim_da_chave(linhas: list[str], inicio: int) -> int:
    """Fim do valor de `chave:` em `inicio` — a lista pode vir na mesma coluna da chave (`yaml.safe_dump`)."""
    base = _indent(linhas[inicio])
    for i in range(inicio + 1, len(linhas)):
        if _ativa(linhas[i]) and (_indent(linhas[i]) < base or (_indent(linhas[i]) == base and not linhas[i].strip().startswith("- "))):
            return i
    return len(linhas)


def _fim_do_item(linhas: list[str], inicio: int) -> int:
    base = _indent(linhas[inicio])
    return next((i for i in range(inicio + 1, len(linhas)) if _ativa(linhas[i]) and _indent(linhas[i]) <= base), len(linhas))


def _chaves(linhas: list[str], inicio: int, fim: int, indent: int, chave: str) -> list[int]:
    return [i for i in range(inicio, fim) if _indent(linhas[i]) == indent and linhas[i].split("#", 1)[0].strip() == f"{chave}:"]


_ITEM_COM_NOME = re.compile(r"-\s+name\s*:")
_nomes_lidos: dict[str, object] = {}


def _nome_do_item(linha: str) -> object:
    """O nome de um item `- name: <nome>`, **como o YAML o lê** — com comentário, aspas ou espaço a
    mais (RVL3-11-01); `None` se a linha não é um item que só abre com o nome."""
    texto = linha.strip()
    if not _ITEM_COM_NOME.match(texto):
        return None
    if texto not in _nomes_lidos:
        try:
            valor = yaml.safe_load(texto[1:])
        except yaml.YAMLError:
            valor = None
        _nomes_lidos[texto] = valor["name"] if isinstance(valor, dict) and list(valor) == ["name"] else None
    return _nomes_lidos[texto]


def _recuo_dos_itens(linhas: list[str], chave: int) -> int | None:
    """A coluna dos itens da lista que é o valor da chave na linha `chave`; `None` se o valor não é lista."""
    fim = _fim_da_chave(linhas, chave)
    primeiro = next((i for i in range(chave + 1, fim) if _ativa(linhas[i])), None)
    if primeiro is None or not linhas[primeiro].strip().startswith("- "):
        return None
    return _indent(linhas[primeiro])


def _itens(linhas: list[str], chave: int, nome: str) -> list[int]:
    """Os itens `- name: <nome>` da lista que é o valor da chave na linha `chave`."""
    coluna = _recuo_dos_itens(linhas, chave)
    if coluna is None:
        return []
    fim = _fim_da_chave(linhas, chave)
    itens = [i for i in range(chave + 1, fim) if _indent(linhas[i]) == coluna and linhas[i].strip().startswith("- ")]
    return [i for i in itens if _nome_do_item(linhas[i]) == nome]


def _coluna(bloco: list[str], idx_cols: int, coluna: str, rotulo: str) -> tuple[int | None, int, int]:
    """O item da coluna sob `columns:` — pela estrutura, com qualquer recuo da lista —, a coluna dos itens
    e onde um item novo entra (o fim da lista, antes de linhas vazias ou comentários soltos).

    Comparar a linha com `- name: <coluna>` não reconhecia `- name: quantity # …`, e o
    escritor acrescentava uma segunda `quantity` (RVL3-11-01); a coluna repetida é recusa."""
    achados = _itens(bloco, idx_cols, coluna)
    if len(achados) > 1:
        raise ValueError(f"`{rotulo}` lista a coluna `{coluna}` {len(achados)} vezes")
    recuo = _recuo_dos_itens(bloco, idx_cols)
    recuo = _indent(bloco[idx_cols]) + 2 if recuo is None else recuo
    fim = _fim_da_chave(bloco, idx_cols)
    while fim > idx_cols + 1 and not _ativa(bloco[fim - 1]):
        fim -= 1
    return (achados[0] if achados else None), recuo, fim


def _chave_columns(bloco: list[str], base: int) -> int | None:
    return next(iter(_chaves(bloco, 0, len(bloco), base + 2, "columns")), None)


def _locate(linhas: list[str], endereco: Address) -> int | None:
    """A linha `- name:` da entrada no seu lugar da estrutura; endereço repetido é recusa, não a primeira."""
    if isinstance(endereco, tuple):
        fonte, tabela = endereco
        achados = [t for s in _chaves(linhas, 0, len(linhas), 0, "sources") for f in _itens(linhas, s, fonte)
                   for k in _chaves(linhas, f + 1, _fim_do_item(linhas, f), _indent(linhas[f]) + 2, "tables")
                   for t in _itens(linhas, k, tabela)]
    else:
        achados = [e for chave in _TOPO for c in _chaves(linhas, 0, len(linhas), 0, chave) for e in _itens(linhas, c, endereco)]
    if len(achados) > 1:
        raise ValueError(f"entrada `{address_label(endereco)}` aparece {len(achados)} vezes no arquivo")
    return achados[0] if achados else None


def entries_by_address(documento: dict) -> dict[Address, dict]:
    """O YAML carregado, por endereço: o par (fonte, tabela) não colide com a homônima de outra fonte."""
    entradas: dict[Address, dict] = {e["name"]: e for k in _TOPO for e in documento.get(k) or []}
    for fonte in documento.get("sources") or []:
        entradas.update({(fonte["name"], t["name"]): t for t in fonte.get("tables") or []})
    return entradas


def _valor_yaml(valor) -> str:
    return "true" if valor is True else "false" if valor is False else str(valor)


def patch_meta(texto: str, entradas: dict[Address, dict[str, dict[str, object]]]) -> str:
    """Insere ou atualiza chaves de `meta` de cada coluna de cada entrada, preservando o resto."""
    linhas = texto.split("\n")
    for entrada, colunas in entradas.items():
        for coluna, chaves in colunas.items():
            for chave, valor in chaves.items():
                linha_valor = f"{chave}: {_valor_yaml(valor)}"
                inicio = _locate(linhas, entrada)
                if inicio is None:
                    raise KeyError(f"entrada `{address_label(entrada)}` não encontrada")
                base = _indent(linhas[inicio])
                fim = _block_end(linhas, inicio, base)
                bloco = linhas[inicio:fim]
                # `columns:` do bloco, criado se não existir
                idx_cols = _chave_columns(bloco, base)
                if idx_cols is None:
                    while bloco and not bloco[-1].strip():
                        bloco.pop()
                    bloco.append(" " * (base + 2) + "columns:")
                    idx_cols = len(bloco) - 1
                idx_col, item_indent, fim_cols = _coluna(bloco, idx_cols, coluna, address_label(entrada))
                if idx_col is None:
                    bloco[fim_cols:fim_cols] = [
                        " " * item_indent + f"- name: {coluna}",
                        " " * (item_indent + 2) + "meta:",
                        " " * (item_indent + 4) + linha_valor,
                    ]
                else:
                    fim_col = _block_end(bloco, idx_col, item_indent)
                    em_linha = next((i for i in range(idx_col + 1, fim_col) if _indent(bloco[i]) == item_indent + 2
                                     and bloco[i].strip().startswith("meta:")
                                     and bloco[i].split("#", 1)[0].strip() != "meta:"), None)
                    if em_linha is not None:
                        # `meta: {…}` não é editável linha a linha: um segundo `meta:` em bloco
                        # duplicaria a chave, e o carregador ficaria com um só (RVL3-4-01).
                        raise ValueError(f"{address_label(entrada)}.{coluna}: `meta` escrito em linha; escreva-o em bloco para o gerador editar")
                    idx_meta = next((i for i in range(idx_col + 1, fim_col)
                                     if bloco[i].split("#", 1)[0].strip() == "meta:" and _indent(bloco[i]) == item_indent + 2), None)
                    if idx_meta is None:
                        bloco[idx_col + 1:idx_col + 1] = [
                            " " * (item_indent + 2) + "meta:",
                            " " * (item_indent + 4) + linha_valor,
                        ]
                    else:
                        fim_meta = _block_end(bloco, idx_meta, item_indent + 2)
                        idx_chave = next((i for i in range(idx_meta + 1, fim_meta) if bloco[i].strip().startswith(f"{chave}:")), None)
                        if idx_chave is None:
                            bloco.insert(idx_meta + 1, " " * (item_indent + 4) + linha_valor)
                        else:
                            bloco[idx_chave] = " " * (item_indent + 4) + linha_valor
                linhas[inicio:fim] = bloco
    return "\n".join(linhas)


def verify_meta(caminho: pathlib.Path, conteudo: str, esperado: dict[Address, dict[str, dict[str, object]]]) -> None:
    """O arquivo escrito, **como o YAML o carrega** e sem chave repetida, tem cada chave de `meta` pedida (RVL3-4-01)."""
    try:
        documento = read_yaml(caminho, conteudo)
    except ValueError as erro:
        raise RuntimeError(str(erro)) from None
    entradas = entries_by_address(documento)
    for nome, colunas in esperado.items():
        metas = {c["name"]: (c.get("meta") or {}) for c in (entradas.get(nome) or {}).get("columns", [])}
        for coluna, chaves in colunas.items():
            faltam = {k: v for k, v in chaves.items() if metas.get(coluna, {}).get(k) != v}
            if faltam:
                raise RuntimeError(f"{caminho.relative_to(ROOT)}: `{address_label(nome)}.{coluna}` não ficou com {faltam}")


def patch_yaml(texto: str, entradas: dict[Address, dict[str, str]]) -> str:
    """Insere ou atualiza `meta.sensitivity` de cada coluna de cada entrada, preservando o resto."""
    return patch_meta(texto, {e: {c: {"sensitivity": n} for c, n in cols.items()} for e, cols in entradas.items()})


def render_generated(modelos: dict[str, dict[str, str]], chave: str = "models", textos: dict[str, dict[str, str]] | None = None,
                     dominios: dict[str, str] | None = None) -> str:
    """O arquivo gerado inteiro: cada modelo com o domínio, quando ele conduz uma tabela da origem, e o nível
    e a descrição derivados de cada coluna."""
    textos, dominios = textos or {}, dominios or {}

    def coluna(modelo: str, c: str, n: str) -> dict:
        texto = textos.get(modelo, {}).get(c)
        # Todo texto daqui foi escrito pela derivação: leva a marca, que acompanha a
        # coluna se ela for promovida a um `.yml` à mão (RVL3-3-01).
        meta = {"sensitivity": n, **({"description_inherited": True} if texto else {})}
        return {"name": c, **({"description": texto} if texto else {}), "meta": meta}

    corpo = {"version": 2, chave: [
        {"name": nome, **({"meta": {"domain": dominios[nome]}} if nome in dominios else {}),
         "columns": [coluna(nome, c, n) for c, n in colunas.items()]}
        for nome, colunas in sorted(modelos.items())
    ]}
    return GENERATED_HEADER + "\n" + yaml.safe_dump(corpo, sort_keys=False, allow_unicode=True, width=120)


def render_files(plano: Plan, textos=None, dominios=None) -> dict[pathlib.Path, str]:
    """Conteúdo final de cada arquivo que mudaria: a sensibilidade primeiro, a descrição (`descriptions.Texts`)
    e o domínio (`domains.Domains`) por cima."""
    from mvp_ed1.models import descriptions, domains
    saida: dict[pathlib.Path, str] = {}
    a_descrever = textos.patches if textos is not None else {}
    a_marcar = textos.marks if textos is not None else {}
    a_classificar = dominios.patches if dominios is not None else {}
    for caminho in sorted(set(plano.patches) | set(a_descrever) | set(a_marcar) | set(a_classificar)):
        texto = caminho.read_text(encoding="utf-8")
        if caminho in plano.patches:
            texto = patch_yaml(texto, plano.patches[caminho])
        if caminho in a_descrever:
            texto = descriptions.patch_descriptions(texto, a_descrever[caminho])
        if caminho in a_marcar:
            texto = patch_meta(texto, a_marcar[caminho])
        if caminho in a_classificar:
            texto = domains.patch_domains(texto, a_classificar[caminho])
        saida[caminho] = texto
    for caminho, modelos in plano.generated.items():
        saida[caminho] = render_generated(modelos, "snapshots" if caminho.parent.name == "snapshots" else "models",
                                          textos.generated if textos is not None else None,
                                          dominios.generated if dominios is not None else None)
    return saida


def stale_generated(plano: Plan) -> list[pathlib.Path]:
    """Arquivo gerado em disco que nenhum modelo mais habita — todos ganharam entrada à mão —, ou com o nome antigo."""
    existentes = {c for nome in GENERATED_FILES for raiz in (DBT / "models", DBT / "snapshots") for c in raiz.rglob(nome)}
    return sorted(existentes - set(plano.generated))


def _verify(caminho: pathlib.Path, conteudo: str, esperado: dict[Address, dict[str, str]]) -> None:
    """O arquivo escrito, lido sem perder ocorrência (`read_yaml`), diz o que se pediu, no endereço pedido."""
    entradas = entries_by_address(read_yaml(caminho, conteudo))
    for nome, colunas in esperado.items():
        declaradas = {c["name"]: (c.get("meta") or {}).get("sensitivity") for c in (entradas.get(nome) or {}).get("columns", [])}
        faltam = {c: n for c, n in colunas.items() if declaradas.get(c) != n}
        if faltam:
            raise RuntimeError(f"{caminho.relative_to(ROOT)}: `{address_label(nome)}` não ficou como esperado: {faltam}")


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    conferir = "--check" in argv
    if not MANIFEST.exists():
        print(f"sem {MANIFEST.relative_to(ROOT)}; rode `make dbt-build` antes", file=sys.stderr)
        return 2
    from mvp_ed1.models import descriptions, domains
    manifest, derivacao = load()
    if atrasados := stale_nodes(manifest):
        print(f"manifest atrasado: {len(atrasados)} modelo(s) mudaram no disco depois do último build "
              f"({', '.join(atrasados[:5])}{'…' if len(atrasados) > 5 else ''}); rode `make dbt-build` antes — "
              "nenhum arquivo é tocado", file=sys.stderr)
        return 1
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
    try:
        if estrangeiras := foreign_sources(manifest):
            raise ValueError(f"fonte de outro pacote no manifest ({', '.join(estrangeiras[:3])}) — "
                             "o catálogo só lê as fontes do projeto raiz (Governança §5.1)")
        plano = plan(manifest, derivacao)
        disco = descriptions.disk_entries()
        textos = descriptions.derive_texts(manifest, derivacao, disco=disco)
        dominios = domains.derive_domains(manifest, disco)
        arquivos = render_files(plano, textos, dominios)
        # Todo conteúdo final, lido estrito antes de qualquer escrita: uma ocorrência que o
        # escritor duplicou não pode sair com 0 para ser recusada só na rodada seguinte (RVL3-11-01).
        for caminho, texto in arquivos.items():
            read_yaml(caminho, texto)
        # A marca conferida no YAML carregado, nos dois modos: um escritor que não a
        # grava não pode passar no `--check` só porque os bytes não mudaram (RVL3-4-01).
        for caminho, marcas in textos.marks.items():
            verify_meta(caminho, arquivos.get(caminho, caminho.read_text(encoding="utf-8")), marcas)
        # Todo destino pedido, conferido no endereço, mude o arquivo ou não: um patch que
        # caísse noutra entrada já certa não muda byte nenhum, e o `--check` passaria (RVL3-10-01).
        for caminho, texto in arquivos.items():
            _verify(caminho, texto, plano.patches.get(caminho) or plano.generated.get(caminho) or {})
            if caminho in textos.patches:
                descriptions.verify(caminho, texto, textos.patches[caminho])
            elif caminho in plano.generated:
                descriptions.verify(caminho, texto, {m: textos.generated[m] for m in plano.generated[caminho] if m in textos.generated})
            # O domínio pedido, no valor que o dbt lê — também quando a escrita não muda byte (RVL3-11-02).
            if caminho in dominios.patches:
                domains.verify(caminho, texto, dominios.patches[caminho])
            elif caminho in plano.generated:
                domains.verify(caminho, texto, {m: dominios.generated[m] for m in plano.generated[caminho] if m in dominios.generated})
    except (ValueError, RuntimeError, KeyError) as erro:
        print(f"recusado: {erro.args[0] if erro.args else erro} — nenhum arquivo é tocado", file=sys.stderr)
        return 1

    for mudanca in plano.changes + textos.changes + dominios.changes:
        print(f"trocado: {mudanca}", file=sys.stderr)
    for pendente in plano.left_to_generator + textos.problems:
        print(f"gerador: {pendente}", file=sys.stderr)
    pendencias = plano.left_to_generator + textos.problems

    mudados = {c: t for c, t in arquivos.items() if not c.exists() or c.read_text(encoding="utf-8") != t}
    obsoletos = stale_generated(plano)
    total = sum(len(v) for v in derivacao.levels.values())
    if conferir:
        for caminho in sorted(mudados):
            print(f"desatualizado: {caminho.relative_to(ROOT)}", file=sys.stderr)
        for caminho in obsoletos:
            print(f"obsoleto (sem modelo): {caminho.relative_to(ROOT)}", file=sys.stderr)
        falhou = bool(mudados or obsoletos or pendencias)
        print(f"classificação e descrição derivadas de {total} colunas em {len(derivacao.levels)} nós; "
              f"{len(mudados) + len(obsoletos)} arquivo(s) desatualizado(s)")
        return 1 if falhou else 0

    for caminho, texto in mudados.items():
        caminho.write_text(texto, encoding="utf-8")
        print(f"escrito: {caminho.relative_to(ROOT)}")
    for caminho in obsoletos:
        caminho.unlink()
        print(f"removido: {caminho.relative_to(ROOT)}")
    print(f"classificação e descrição derivadas de {total} colunas em {len(derivacao.levels)} nós; {len(mudados) + len(obsoletos)} arquivo(s) escrito(s)")
    return 1 if pendencias else 0


if __name__ == "__main__":
    raise SystemExit(main())
