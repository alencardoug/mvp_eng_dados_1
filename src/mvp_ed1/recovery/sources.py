"""O que a geração produz e o que as origens contêm — T1 e T2 da regeneração da v1.1.0.

A regeneração da v1.1.0 troca o conteúdo das duas origens com as correções do
gerador (árvore de categorias, faixa de preço, lançamento antes da venda), e o
runbook dela no `bi-como-codigo` (§3.2, H1 e H2; §3.3, T1 e T2) pede duas
medidas que não existiam:

* **T1 — a geração, em memória** (`measure`, `compare`): para as duas origens,
  com os mesmos parâmetros, por tabela, a contagem e o *digest* do conteúdo
  sobre as colunas que a carga escreve; e as chaves canônicas de cada tabela do
  legado. Não toca banco nenhum. Duas medidas tiradas em *commits* diferentes —
  o gerador de antes das correções e o corrigido — se comparam por `compare`,
  que diz as tabelas que mudam e as transições de chave do legado;
* **T2 — o oráculo das origens, só leitura** (`oracle`): o mesmo, lido do
  `source_db` e do `legacy_db`, contra uma medida da T1.

**O H2 compara estados, não lotes** (`compare --before-manifest`). O legado de
antes da regeneração não era o lote puro: o diário de mutações do manifesto
dele registra o que se fez no banco depois da carga — na Etapa 11, a remoção de
`customers` 1, 2 e 3 e a troca de `campaigns.id` 4 por `0x4`. Comparar só os
lotes não vê que a recarga desfaz essas mutações: no D4 de 04/11/2026 as três
chaves reapareceram e saíram da memória de exclusões, e o H2 dizia "nenhuma"
(N56 do plano do `bi-como-codigo`). Com o manifesto do lado de antes, o diário
é aplicado ao lado de antes — às chaves pela `presenca_apos_commit` de cada
mutação, aos *hashes* pela cadeia de `expected_legacy` —, e a comparação é do
estado real de antes com o lote novo.

**Por que contagem não basta** (Capacidade e Recuperação §2.7): um preço válido
diferente mantém todas as contagens. O que se compara é conteúdo.

**Uma representação, dois lados.** Na origem principal o *digest* é
`oraculos.digest` — a codificação canônica tipada do formato 2, com
multiplicidade, nulos, escala de `numeric`, instantes em UTC e `jsonb` com
chaves ordenadas — aplicado às linhas da memória e às lidas do banco. No
legado é a identidade de conteúdo do próprio gravador (`legacy/conteudo`), o
*hash* por tabela e o do lote, e não uma segunda medida. Que as duas leituras
compartilham a representação não é suposto: a **calibração** a prova.

**A calibração** (`oracle --calibration`) roda a T2 na origem de hoje contra a
T1 do gerador de antes das correções. A origem de hoje é o *dump* do corte de
25/09/2026 mais o que o produtor do *streaming* emitiu — e nenhum arquivo
registra a geração dela (`data/source/geracao.json` não existe). Por isso a
calibração exclui só o que o produtor move: `inventory_balances` inteira, e de
`inventory_movements` o que passa do `max_event_sequence` do manifesto
aprovado, que a contagem de movimentos da T1 precisa igualar. As exclusões são
da calibração e só dela; a conferência depois de uma carga cobre tudo.

**As colunas que o banco gera** não entram no *digest* — a carga não as
escreve — e são conferidas à parte, pela declaração do modelo: a identidade
`always` (`event_sequence`) vai de 1 à contagem, sem buraco nem repetição, como
fica depois de `truncate … restart identity`; a coluna calculada
(`quantity_available`) é igual à expressão que a declara.

**O legado de hoje não é o lote puro.** O diário de mutações do manifesto
corrente registra o que se fez no banco depois da carga, com o *hash* da tabela
antes e depois. O esperado no `legacy_db` é o lote da T1 com cada mutação
aplicada em ordem — e uma mutação cujo *hash* de antes não é o esperado até ali
é diário que não encadeia, e falha.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import pathlib
import subprocess
import sys
from collections import Counter
from collections.abc import Iterable, Mapping
from typing import Any

from sqlalchemy import Connection, Engine, create_engine, text

from mvp_ed1.recovery import oraculos

ROOT = pathlib.Path(__file__).resolve().parents[3]
#: Onde ficam as medidas da v1.1.0 (runbook, H1). Fora do Git, como `data/`.
MEASUREMENTS = ROOT / "data" / "medicoes" / "v1_1_0"
LEGACY_MANIFEST = ROOT / "data" / "legacy" / "manifesto.json"
APPROVED_MANIFEST = ROOT / "data" / "recovery" / "aprovado" / "manifesto.json"

#: A forma deste arquivo de medida. Sobe quando um campo muda de sentido.
FORMAT = 1

#: O que decide o conteúdo gerado: o gerador, o legado (catálogo e injetor) e
#: os modelos (colunas, tipos, enumerações). A medida registra a árvore de cada
#: um no *commit*, e se havia alteração não commitada neles.
GENERATING_PATHS = ("src/mvp_ed1/generator", "src/mvp_ed1/legacy", "src/mvp_ed1/models")

#: O livro de estoque: a tabela cuja identidade o banco atribui e que o
#: produtor do *streaming* estende.
LEDGER = "inventory_movements"
LEDGER_SEQUENCE = "event_sequence"
#: O saldo que o produtor move junto com o livro.
BALANCES = "inventory_balances"


class Refused(Exception):
    """As duas medidas não são comparáveis — formato ou parâmetros diferentes."""


# ── Proveniência ─────────────────────────────────────────────────────────────
def _git(*args: str) -> str | None:
    try:
        return subprocess.run(
            ["git", *args], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def provenance() -> dict[str, Any]:
    """O *commit*, a árvore de cada caminho que gera e o que nele não está commitado."""
    dirty = _git("status", "--porcelain", "--", *GENERATING_PATHS)
    return {
        "commit": _git("rev-parse", "HEAD"),
        "trees": {path: _git("rev-parse", f"HEAD:{path}") for path in GENERATING_PATHS},
        "uncommitted": dirty.splitlines() if dirty else [],
        "measured_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
    }


# ── T1: a geração em memória ─────────────────────────────────────────────────
def table_digest(rows: Iterable[Mapping[str, Any]], columns: Iterable[str]) -> dict[str, Any]:
    """Contagem e *digest* de um conjunto de linhas, só nas colunas dadas."""
    columns = tuple(columns)
    projected = [{column: row[column] for column in columns} for row in rows]
    return {"rows": len(projected), "digest": oraculos.digest(projected)}


def oltp_tables(dados: Any) -> dict[str, dict[str, Any]]:
    """As 40 tabelas da origem principal, na ordem de carga, sobre as colunas gravadas."""
    from mvp_ed1.generator.engine import Motor
    from mvp_ed1.generator.writer import ORDEM

    return {
        table: table_digest(dados[table] if table in dados else [], Motor.colunas_gravaveis(table))
        for table in ORDEM
    }


def legacy_keys(rows_by_table: Mapping[str, Iterable[Mapping[str, Any]]]) -> dict[str, dict[str, Any]]:
    """Por tabela do legado, a multiplicidade de cada chave canônica (ADR-0045).

    A chave é a PK declarada no SQLAlchemy, canonizada pelo tipo dela pela mesma
    função que o diário de mutações usa (`remocao.canonizar`, o espelho da
    macro `chave_canonica`). Linha cuja chave não canoniza não tem identidade:
    conta à parte, como no modelo de presença.
    """
    from mvp_ed1.legacy import remocao, schema

    keys: dict[str, dict[str, Any]] = {}
    for table in schema.tabelas():
        column, kind = remocao.chave(table)
        counts: Counter[str] = Counter()
        without_identity = 0
        for row in rows_by_table.get(table, ()):
            value = row.get(column)
            key = remocao.canonizar(None if value is None else str(value), kind)
            if key is None:
                without_identity += 1
            else:
                counts[key] += 1
        keys[table] = {
            "column": column,
            "type": kind,
            "keys": dict(sorted(counts.items())),
            "without_identity": without_identity,
        }
    return keys


def measure(
    *, seed: int | None = None, as_of: dt.date | None = None, scale: str | float | None = None
) -> dict[str, Any]:
    """T1: gera as duas origens em memória e mede cada tabela. Nenhum banco é tocado.

    A origem principal usa os parâmetros de `make seed-data` — os do YAML, salvo
    os dados aqui —; o legado, os do catálogo, como `make seed-legacy`.
    """
    from mvp_ed1.generator import pipeline
    from mvp_ed1.generator.config import carregar
    from mvp_ed1.generator.engine import Motor
    from mvp_ed1.legacy import conteudo
    from mvp_ed1.legacy.cli import _gerar as generate_legacy

    config = carregar()
    motor = Motor(config, seed=seed, as_of_date=as_of, fator=scale)
    dados = pipeline.gerar(motor)
    catalogo, resultado, parametros = generate_legacy()
    batch = conteudo.hash_do_lote(resultado.linhas)
    return {
        "format": FORMAT,
        "kind": "generation",
        "digest_format": oraculos.FORMATO,
        "provenance": provenance(),
        "oltp": {
            "parameters": {
                "seed": motor.seed,
                "as_of": motor.as_of_date.isoformat(),
                "scale": scale if scale is not None else config.fator_padrao,
            },
            "tables": oltp_tables(dados),
        },
        "legacy": {
            "parameters": {**parametros, "versao_catalogo": catalogo.versao},
            "batch_hash": conteudo.hash_global(batch),
            "tables": batch,
            "keys": legacy_keys(resultado.linhas),
        },
    }


# ── T1: duas medidas comparadas ──────────────────────────────────────────────
#: Parâmetros que não identificam a geração: a versão do catálogo é informação,
#: e a mudança dela aparece no relatório sem recusar a comparação.
_INFORMATIVE = frozenset({"versao_catalogo"})


def _generation_parameters(parameters: Mapping[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in parameters.items() if k not in _INFORMATIVE}


def changed_tables(
    before: Mapping[str, Mapping[str, Any]], after: Mapping[str, Mapping[str, Any]]
) -> dict[str, dict[str, Any]]:
    """As tabelas cujo conteúdo muda — a contagem ou o *digest* —, com os dois lados."""
    changes: dict[str, dict[str, Any]] = {}
    for table in sorted(set(before) | set(after)):
        a, b = before.get(table), after.get(table)
        if a != b:
            changes[table] = {"before": a, "after": b}
    return changes


def key_transitions(before: Mapping[str, int], after: Mapping[str, int]) -> dict[str, list[str]]:
    """As transições de chave de uma tabela, com multiplicidade — as classes de `legacy_capture_transitions`."""
    transitions: dict[str, list[str]] = {
        "removed": [], "added": [], "reduced": [], "increased": [], "kept": []
    }
    for key in sorted(set(before) | set(after)):
        n_before, n_after = before.get(key, 0), after.get(key, 0)
        if n_before and not n_after:
            transitions["removed"].append(key)
        elif n_after and not n_before:
            transitions["added"].append(key)
        elif n_after < n_before:
            transitions["reduced"].append(key)
        elif n_after > n_before:
            transitions["increased"].append(key)
        else:
            transitions["kept"].append(key)
    return transitions


def _pk_values(mutacao: Mapping[str, Any], pk: str) -> list[Any]:
    """Os valores da chave primária que uma mutação tocou, como o banco os devolveu."""
    tipo = mutacao["tipo"]
    if tipo == "remover":
        return [*mutacao.get("chaves", []), *(d.get(pk) for d in mutacao.get("devolvidas", []))]
    if tipo == "inserir":
        return [mutacao.get("devolvida", {}).get(pk)]
    if tipo == "alterar":
        if mutacao.get("coluna") != pk:
            return [mutacao.get("valor_da_chave")]
        return [mutacao.get("valor_da_chave"),
                *(a.get("valor") for a in mutacao.get("antes", [])),
                *(d.get("valor") for d in mutacao.get("devolvidas", []))]
    raise Refused(f"mutação de tipo desconhecido no diário: {tipo!r}")


def apply_mutations(
    keys: Mapping[str, Mapping[str, Any]], diary: Iterable[Mapping[str, Any]]
) -> dict[str, dict[str, Any]]:
    """As chaves do legado depois do diário de mutações: o estado do banco, e não o lote puro.

    Cada mutação grava `presenca_apos_commit` — quantas linhas físicas restam,
    depois do *commit*, de cada chave canônica que ela tocou
    (`legacy.mutacoes.efeito_liquido`). Aplicadas em ordem sobre a multiplicidade
    do lote, dão a do banco: zero tira a chave.

    O que o diário não diz, não se inventa. Entrada sem `presenca_apos_commit` é
    diário encerrado (D44), e uma chave primária tocada que não canoniza muda a
    contagem das linhas sem identidade, que a presença não registra: as duas
    recusam, em vez de dar um estado que o banco talvez não tenha.
    """
    from mvp_ed1.legacy import remocao

    result = {table: {**found, "keys": dict(found["keys"])} for table, found in keys.items()}
    for indice, mutacao in enumerate(diary):
        table = mutacao["tabela"]
        if "presenca_apos_commit" not in mutacao:
            raise Refused(f"mutação {indice} ({mutacao['tipo']} em {table}) sem `presenca_apos_commit`: "
                          "diário encerrado (D44), que não se aplica")
        if table not in result:
            raise Refused(f"mutação {indice} em {table}, tabela que a medida não tem")
        column, kind = remocao.chave(table)
        for valor in _pk_values(mutacao, column):
            if remocao.canonizar(None if valor is None else str(valor), kind) is None:
                raise Refused(f"mutação {indice} ({mutacao['tipo']} em {table}) toca a chave {valor!r}, "
                              "que não canoniza: a contagem das linhas sem identidade não sai do diário")
        counts = result[table]["keys"]
        for key, remaining in mutacao["presenca_apos_commit"].items():
            if remaining > 0:
                counts[key] = remaining
            else:
                counts.pop(key, None)
        result[table]["keys"] = dict(sorted(counts.items()))
    return result


def compare(
    before: Mapping[str, Any], after: Mapping[str, Any], *, before_manifest: Mapping[str, Any] | None = None
) -> dict[str, Any]:
    """H1 e H2: o que muda entre duas gerações dos mesmos parâmetros.

    Recusa medidas de formatos ou parâmetros diferentes: com outra semente,
    toda tabela mudaria, e a comparação não diria nada sobre as correções.

    Com `before_manifest` — o manifesto do lote de antes, com o diário de
    mutações aberto —, o lado de antes é o **estado** do banco: o lote com o
    diário aplicado, nas chaves e nos *hashes*. Um manifesto de outro lote, ou
    um diário que não encadeia, recusa.
    """
    for medida in (before, after):
        if medida.get("kind") != "generation":
            raise Refused(f"não é uma medida da geração (T1): kind={medida.get('kind')!r}")
    mutations: dict[str, Any] | None = None
    if before_manifest is not None:
        diary = before_manifest.get("mutacoes", [])
        expected, problems = expected_legacy(before["legacy"], before_manifest)
        if problems:
            raise Refused("o manifesto de antes não descreve o lado de antes: " + "; ".join(problems))
        before = {**before, "legacy": {**before["legacy"], "tables": expected,
                                       "keys": apply_mutations(before["legacy"]["keys"], diary)}}
        mutations = {"batch_hash": before_manifest["lote"]["hash"], "applied": len(diary),
                     "tables": sorted({m["tabela"] for m in diary})}
    if (before["format"], before["digest_format"]) != (after["format"], after["digest_format"]):
        raise Refused(
            f"formatos diferentes: {before['format']}/{before['digest_format']} × "
            f"{after['format']}/{after['digest_format']}"
        )
    for source in ("oltp", "legacy"):
        a = _generation_parameters(before[source]["parameters"])
        b = _generation_parameters(after[source]["parameters"])
        if a != b:
            raise Refused(f"{source}: parâmetros diferentes — {a} × {b}")

    keys: dict[str, Any] = {}
    for table in sorted(set(before["legacy"]["keys"]) | set(after["legacy"]["keys"])):
        a = before["legacy"]["keys"].get(table, {"keys": {}, "without_identity": 0})
        b = after["legacy"]["keys"].get(table, {"keys": {}, "without_identity": 0})
        transitions = key_transitions(a["keys"], b["keys"])
        keys[table] = {
            "counts": {kind: len(found) for kind, found in transitions.items()},
            "changed": {kind: found for kind, found in transitions.items() if kind != "kept" and found},
            "without_identity": {"before": a["without_identity"], "after": b["without_identity"]},
        }
    oltp = changed_tables(before["oltp"]["tables"], after["oltp"]["tables"])
    legacy = changed_tables(before["legacy"]["tables"], after["legacy"]["tables"])
    key_changes = sorted(
        table for table, found in keys.items()
        if found["changed"] or found["without_identity"]["before"] != found["without_identity"]["after"]
    )
    return {
        "format": FORMAT,
        "kind": "comparison",
        "before": before["provenance"],
        "after": after["provenance"],
        "parameters": {source: before[source]["parameters"] for source in ("oltp", "legacy")},
        "catalog_version": {
            "before": before["legacy"]["parameters"].get("versao_catalogo"),
            "after": after["legacy"]["parameters"].get("versao_catalogo"),
        },
        "oltp": {"changed": oltp, "unchanged": sorted(set(after["oltp"]["tables"]) - set(oltp))},
        "legacy": {
            "batch_hash": {"before": before["legacy"]["batch_hash"], "after": after["legacy"]["batch_hash"]},
            "before_mutations": mutations,
            "changed": legacy,
            "unchanged": sorted(set(after["legacy"]["tables"]) - set(legacy)),
            "keys": keys,
            "tables_with_key_changes": key_changes,
        },
    }


# ── T2: o oráculo das origens ────────────────────────────────────────────────
def _read_only(conexao: Connection) -> None:
    """Abre a transação somente leitura e confere que o banco a aceitou."""
    conexao.execute(text("set transaction read only"))
    if conexao.execute(text("show transaction_read_only")).scalar_one() != "on":
        raise RuntimeError("a sessão não ficou somente leitura — nada é lido assim")


def generated_column_checks(conexao: Connection, table: str, where: str = "") -> dict[str, Any]:
    """As colunas que o banco gera, pela declaração do modelo — vazio se a tabela não tem nenhuma."""
    from mvp_ed1.models import SCHEMA, Base

    filtro = f" where {where}" if where else ""
    checks: dict[str, Any] = {}
    for coluna in Base.metadata.tables[f"{SCHEMA}.{table}"].columns:
        nome = coluna.name
        if coluna.identity is not None and coluna.identity.always:
            n, distintos, minimo, maximo = conexao.execute(text(
                f'select count(*), count(distinct "{nome}"), min("{nome}"), max("{nome}") '
                f'from {SCHEMA}."{table}"{filtro}'
            )).one()
            checks[nome] = {
                "rule": "1 a n, sem buraco nem repetição",
                "rows": n, "distinct": distintos, "min": minimo, "max": maximo,
                "ok": n == distintos and (n == 0 or (minimo == 1 and maximo == n)),
            }
        elif coluna.computed is not None:
            expressao = str(coluna.computed.sqltext)
            divergentes = conexao.execute(text(
                f'select count(*) from {SCHEMA}."{table}"'
                f'{filtro or " where true"} and "{nome}" is distinct from ({expressao})'
            )).scalar_one()
            checks[nome] = {"rule": expressao, "differing": divergentes, "ok": divergentes == 0}
    return checks


def read_oltp(engine: Engine, *, ledger_up_to: int | None = None) -> dict[str, Any]:
    """Cada tabela de `oltp`, lida em transação somente leitura, na representação da T1."""
    from mvp_ed1.generator.engine import Motor
    from mvp_ed1.generator.writer import ORDEM
    from mvp_ed1.models import SCHEMA

    tables: dict[str, Any] = {}
    generated: dict[str, Any] = {}
    with engine.connect() as conexao:
        _read_only(conexao)
        for table in ORDEM:
            columns = Motor.colunas_gravaveis(table)
            where = ""
            if table == LEDGER and ledger_up_to is not None:
                where = f'"{LEDGER_SEQUENCE}" <= {int(ledger_up_to)}'
            lista = ", ".join(f'"{c}"' for c in columns)
            consulta = f'select {lista} from {SCHEMA}."{table}"' + (f" where {where}" if where else "")
            tables[table] = table_digest(conexao.execute(text(consulta)).mappings(), columns)
            checks = generated_column_checks(conexao, table, where)
            if checks:
                generated[table] = checks
        conexao.rollback()
    return {"tables": tables, "generated": generated}


def read_legacy(engine: Engine) -> dict[str, dict[str, Any]]:
    """O *hash* de cada tabela de `legacy_db`, pela função do gravador."""
    from mvp_ed1.legacy import conteudo, schema

    with engine.connect() as conexao:
        _read_only(conexao)
        found = {table: conteudo.hash_no_banco(conexao, schema.SCHEMA, table) for table in schema.tabelas()}
        conexao.rollback()
    return found


def expected_legacy(
    batch: Mapping[str, Any], manifest: Mapping[str, Any]
) -> tuple[dict[str, dict[str, Any]], list[str]]:
    """O esperado no `legacy_db`: o lote da T1 com o diário de mutações aplicado, em ordem.

    Devolve o esperado por tabela e os problemas: um manifesto que descreve
    outro lote, ou uma mutação que não encadeia — o *hash* de antes dela não é
    o esperado até ali.
    """
    problems: list[str] = []
    if manifest["lote"]["hash"] != batch["batch_hash"]:
        problems.append(
            f"o manifesto corrente descreve o lote {manifest['lote']['hash']}, e a medida o "
            f"{batch['batch_hash']}"
        )
    expected = {table: dict(found) for table, found in batch["tables"].items()}
    for indice, mutacao in enumerate(manifest.get("mutacoes", [])):
        table = mutacao["tabela"]
        if expected.get(table) != mutacao["hash_antes"]:
            problems.append(
                f"mutação {indice} ({mutacao['tipo']} em {table}) não encadeia: o hash de antes "
                f"é {mutacao['hash_antes']}, e o esperado até ali {expected.get(table)}"
            )
        expected[table] = dict(mutacao["hash_depois"])
    return expected, problems


def compare_tables(
    expected: Mapping[str, Mapping[str, Any]],
    found: Mapping[str, Mapping[str, Any]],
    *,
    excluded: Iterable[str] = (),
) -> dict[str, dict[str, Any]]:
    """Tabela a tabela: o esperado, o encontrado e o veredito. Excluída é relatada, não julgada."""
    excluded = frozenset(excluded)
    result: dict[str, dict[str, Any]] = {}
    for table in sorted(set(expected) | set(found)):
        a, b = expected.get(table), found.get(table)
        status = "excluded" if table in excluded else ("equal" if a == b else "different")
        result[table] = {"status": status, "expected": a, "found": b}
    return result


def oracle(
    medida: Mapping[str, Any],
    *,
    source: Engine,
    legacy: Engine,
    legacy_manifest: Mapping[str, Any],
    calibration_up_to: int | None = None,
) -> dict[str, Any]:
    """T2: as duas origens lidas contra uma medida da T1.

    `calibration_up_to` é o `max_event_sequence` do corte: com ele, o oráculo
    exclui `inventory_balances` e lê do livro só até ali — e exige que a T1 tenha
    gerado exatamente esse número de movimentos.
    """
    if medida.get("kind") != "generation" or medida.get("digest_format") != oraculos.FORMATO:
        raise Refused("a medida não é da T1, ou é de outro formato de digest")
    problems: list[str] = []
    excluded: tuple[str, ...] = ()
    if calibration_up_to is not None:
        excluded = (BALANCES,)
        generated_moves = medida["oltp"]["tables"][LEDGER]["rows"]
        if generated_moves != calibration_up_to:
            problems.append(
                f"a T1 gerou {generated_moves} movimentos, e o corte termina em "
                f"{LEDGER_SEQUENCE} {calibration_up_to}"
            )

    lido = read_oltp(source, ledger_up_to=calibration_up_to)
    oltp = compare_tables(medida["oltp"]["tables"], lido["tables"], excluded=excluded)
    for table, checks in lido["generated"].items():
        for coluna, check in checks.items():
            if not check["ok"] and table not in excluded:
                problems.append(f"{table}.{coluna}: {check}")

    esperado, problemas_do_diario = expected_legacy(medida["legacy"], legacy_manifest)
    problems.extend(problemas_do_diario)
    encontrado = read_legacy(legacy)
    legado = compare_tables(esperado, encontrado)

    different = [f"oltp.{t}" for t, r in oltp.items() if r["status"] == "different"]
    different += [f"legacy.{t}" for t, r in legado.items() if r["status"] == "different"]
    return {
        "format": FORMAT,
        "kind": "oracle",
        "measure": medida["provenance"],
        "read_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "calibration": None if calibration_up_to is None else {
            "ledger_up_to": calibration_up_to, "excluded": list(excluded),
        },
        "oltp": {"tables": oltp, "generated": lido["generated"]},
        "legacy": {
            "manifest_batch": legacy_manifest["lote"]["hash"],
            "mutations": len(legacy_manifest.get("mutacoes", [])),
            "tables": legado,
        },
        "different": different,
        "problems": problems,
        "ok": not different and not problems,
    }


# ── Linha de comando ─────────────────────────────────────────────────────────
def _write(report: Mapping[str, Any], out: pathlib.Path | None, kind: str) -> pathlib.Path:
    if out is None:
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        commit = (_git("rev-parse", "--short", "HEAD") or "semcommit")
        out = MEASUREMENTS / f"{stamp}_{kind}_{commit}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    # `x`: uma medida nunca substitui outra.
    with out.open("x", encoding="utf-8") as arquivo:
        json.dump(report, arquivo, ensure_ascii=False, indent=1, sort_keys=True)
        arquivo.write("\n")
    return out


def _load(caminho: str) -> dict[str, Any]:
    return json.loads(pathlib.Path(caminho).read_text(encoding="utf-8"))


def _summary_measure(report: Mapping[str, Any]) -> None:
    prov = report["provenance"]
    print(f"commit {prov['commit']}" + (" · COM ALTERAÇÕES NÃO COMMITADAS" if prov["uncommitted"] else ""))
    print(f"oltp   {report['oltp']['parameters']} · {len(report['oltp']['tables'])} tabelas · "
          f"{sum(t['rows'] for t in report['oltp']['tables'].values()):,} linhas")
    print(f"legacy {report['legacy']['parameters']} · lote {report['legacy']['batch_hash']}")


def _summary_compare(report: Mapping[str, Any]) -> None:
    for source in ("oltp", "legacy"):
        changed = report[source]["changed"]
        print(f"{source}: {len(changed)} tabelas mudam" + (f" — {', '.join(changed)}" if changed else ""))
    print(f"lote do legado: {report['legacy']['batch_hash']['before']} → {report['legacy']['batch_hash']['after']}")
    mutations = report["legacy"].get("before_mutations")
    if mutations is not None:
        print(f"lado de antes: o lote com o diário de mutações aplicado — {mutations['applied']} mutação(ões)"
              + (f" em {', '.join(mutations['tables'])}" if mutations["tables"] else ""))
    tables = report["legacy"]["tables_with_key_changes"]
    print(f"chaves do legado: {'nenhuma transição' if not tables else 'mudam em ' + ', '.join(tables)}")
    for table in tables:
        print(f"  {table}: {report['legacy']['keys'][table]['counts']}")


def _summary_oracle(report: Mapping[str, Any]) -> None:
    if report["calibration"]:
        print(f"calibração: livro até {report['calibration']['ledger_up_to']}, "
              f"excluídas {', '.join(report['calibration']['excluded'])}")
    for source in ("oltp", "legacy"):
        status = Counter(r["status"] for r in report[source]["tables"].values())
        print(f"{source}: " + ", ".join(f"{n} {s}" for s, n in sorted(status.items())))
    for item in report["different"]:
        print(f"  DIFERENTE {item}")
    for item in report["problems"]:
        print(f"  PROBLEMA {item}")
    print("oráculo: " + ("conteúdo igual ao da medida" if report["ok"] else "FALHOU"))


def _arguments() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m mvp_ed1.recovery.sources",
        description="T1 e T2 da regeneração da v1.1.0: a geração em memória e o oráculo das origens.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    medir = sub.add_parser("measure", help="T1: gera em memória e mede; nenhum banco é tocado")
    medir.add_argument("--seed", type=int, default=None)
    medir.add_argument("--as-of", type=dt.date.fromisoformat, default=None)
    medir.add_argument("--scale", default=None)
    medir.add_argument("--out", type=pathlib.Path, default=None)
    comparar = sub.add_parser("compare", help="T1: o que muda entre duas medidas")
    comparar.add_argument("before")
    comparar.add_argument("after")
    comparar.add_argument("--before-manifest", type=pathlib.Path, default=None,
                          help="o manifesto do lote de antes: o diário de mutações dele entra no lado de antes")
    comparar.add_argument("--out", type=pathlib.Path, default=None)
    oraculo = sub.add_parser("oracle", help="T2: as origens, só leitura, contra uma medida")
    oraculo.add_argument("measure")
    oraculo.add_argument("--calibration", action="store_true",
                         help="exclui o que o produtor move, até o max_event_sequence do manifesto aprovado")
    oraculo.add_argument("--approved-manifest", type=pathlib.Path, default=None)
    oraculo.add_argument("--out", type=pathlib.Path, default=None)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _arguments().parse_args(argv)
    if args.command == "measure":
        report = measure(seed=args.seed, as_of=args.as_of, scale=args.scale)
        _summary_measure(report)
        print(f"medida: {_write(report, args.out, 'geracao')}")
        return 0
    if args.command == "compare":
        try:
            manifest = None if args.before_manifest is None else _load(str(args.before_manifest))
            report = compare(_load(args.before), _load(args.after), before_manifest=manifest)
        except Refused as erro:
            print(f"RECUSADO: {erro}", file=sys.stderr)
            return 2
        _summary_compare(report)
        print(f"comparação: {_write(report, args.out, 'comparacao')}")
        return 0

    from mvp_ed1.db import LEGACY, database_url

    calibration_up_to = None
    if args.calibration:
        approved = args.approved_manifest
        if approved is None:
            raiz = os.environ.get("RECOVERY_DIR")
            approved = pathlib.Path(raiz) / "aprovado" / "manifesto.json" if raiz else APPROVED_MANIFEST
        calibration_up_to = int(_load(str(approved))["max_event_sequence"])
    from mvp_ed1 import registros

    # O manifesto do lote que está **neste** legado: o local, ou o da carga de outras origens.
    outra = registros.raiz()
    legacy_manifest = LEGACY_MANIFEST if outra is None else outra / "legacy" / "manifesto.json"
    source = create_engine(database_url(), future=True)
    legacy = create_engine(database_url(LEGACY), future=True)
    try:
        report = oracle(
            _load(args.measure), source=source, legacy=legacy,
            legacy_manifest=_load(str(legacy_manifest)), calibration_up_to=calibration_up_to,
        )
    except Refused as erro:
        print(f"RECUSADO: {erro}", file=sys.stderr)
        return 2
    finally:
        source.dispose()
        legacy.dispose()
    _summary_oracle(report)
    print(f"oráculo: {_write(report, args.out, 'oraculo')}")
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
