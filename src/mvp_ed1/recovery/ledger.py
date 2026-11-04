"""O livro retido da memória do legado — T4 da regeneração da v1.1.0, com as épocas do H8.

A regeneração da v1.1.0 troca as origens e mantém a memória do armazém: as
capturas retidas em `raw_legacy`, o certificado de cada uma em
`governance.legacy_captures`, a quarentena e a memória de exclusões. O que
prova que a memória ficou contida é comparar o estado depois com **registros
tirados antes**, e o pacote de recuperação não os tem: o manifesto guarda
partição e contagens, não o conteúdo do bruto nem as linhas do certificado
(runbook da regeneração no `bi-como-codigo`, §3.3, T4; RR-06).

**O livro é um diretório de arquivos, fora do banco e fora do Git.** A raiz vem
de `LEGACY_LEDGER_DIR`, no `.env`; o Airflow monta o mesmo diretório, e a CLI e
a DAG escrevem no mesmo lugar. Ausente, vazia ou sem escrita, quem precisa do
livro falha — o registro nunca é pulado.

**Épocas (H8, decisão N33 do Owner).** Cada época é um subdiretório aberto por
uma **linha de base** — o retrato da memória naquele instante —, e a época
corrente é a mais nova com linha de base válida. Toda captura, recuperação ou
registro do operador vai para a corrente; as anteriores ficam como estão,
nunca editadas. Uma restauração substitui a memória por desenho, e por isso
abre época nova: o livro do estado que ela substituiu pararia a captura dela.

**Publicação sem substituição.** Um registro é escrito num temporário dentro da
própria época, sincronizado, e só então ganha o nome final por `link`, que
falha se o nome já existe; o temporário sai, e o diretório é sincronizado. Um
registro publicado é inteiro ou não existe, e nunca é trocado por outro.

**O que se mede, sempre em sessão somente leitura:**

* de uma captura, por tabela do bruto e pelo `sync_id` do *job*: contagem,
  *digest* de **todas** as colunas (`oraculos.digest`, `_airbyte_raw_id` e
  `_airbyte_meta` incluídos) e as gerações das linhas — zero linhas registradas
  como zero;
* do certificado, toda linha da tentativa, por inteiro, na codificação canônica
  do `oraculos` — o que a T3 compara depois com a mesma codificação.

A linha de base acrescenta todas as capturas do bruto, certificadas ou não, as
linhas do certificado inteiro, a partição por geração, as fatias da
quarentena, a memória de exclusões, `governance._versions` e os *jobs* da
conexão legada no Airbyte — o histórico de onde a reconciliação parte.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import pathlib
import re
import uuid
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import Any

import sqlalchemy as sa
from sqlalchemy import Engine

from mvp_ed1.recovery import leitura, oraculos

#: A variável do `.env` que nomeia a raiz do livro (H6).
ENV = "LEGACY_LEDGER_DIR"
#: A forma dos registros. Sobe quando um campo muda de sentido.
FORMAT = 1
BASELINE = "baseline.json"
EPOCH = re.compile(r"^epoch_(\d{4})_\d{8}T\d{6}Z$")
#: As linhas do certificado, na ordem em que se registram.
CERTIFICATE = "governance.legacy_captures"
RAW = leitura.SCHEMA_DO_BRUTO


class LedgerError(Exception):
    """O livro não pode ser usado: sem raiz, sem época corrente, ou um registro que já existe."""


@dataclass(frozen=True)
class Published:
    path: pathlib.Path
    sha256: str


# ── A raiz e as épocas ───────────────────────────────────────────────────────
def root(environ: Mapping[str, str] | None = None) -> pathlib.Path:
    """A raiz do livro, de `LEGACY_LEDGER_DIR`. Ausente, vazia ou sem diretório, falha."""
    valor = (os.environ if environ is None else environ).get(ENV, "").strip()
    if not valor:
        raise LedgerError(f"{ENV} ausente ou vazia: sem livro, nenhuma captura é registrada")
    caminho = pathlib.Path(valor)
    if not caminho.is_dir():
        raise LedgerError(f"{ENV}={valor} não é um diretório")
    return caminho


def epochs(raiz: pathlib.Path) -> list[pathlib.Path]:
    """Os subdiretórios de época, pelo número, os mais antigos primeiro."""
    return sorted(
        (p for p in raiz.iterdir() if p.is_dir() and EPOCH.match(p.name)),
        key=lambda p: int(EPOCH.match(p.name).group(1)),  # type: ignore[union-attr]
    )


def _valid_baseline(epoca: pathlib.Path) -> bool:
    try:
        conteudo = json.loads((epoca / BASELINE).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return isinstance(conteudo, dict) and conteudo.get("kind") == "baseline" and conteudo.get("format") == FORMAT


def current_epoch(raiz: pathlib.Path) -> pathlib.Path:
    """A época mais nova com linha de base válida. Sem nenhuma, falha (H8)."""
    for epoca in reversed(epochs(raiz)):
        if _valid_baseline(epoca):
            return epoca
    raise LedgerError(f"{raiz}: nenhuma época com linha de base válida — abra uma (T4 da A8)")


def open_epoch(raiz: pathlib.Path, baseline: Mapping[str, Any], *, agora: dt.datetime | None = None) -> Published:
    """Abre a época seguinte com a sua linha de base. Uma época que não chegou a ter a sua é pulada."""
    if baseline.get("kind") != "baseline" or baseline.get("format") != FORMAT:
        raise LedgerError("só uma linha de base abre época")
    existentes = epochs(raiz)
    numero = 1 + (int(EPOCH.match(existentes[-1].name).group(1)) if existentes else 0)  # type: ignore[union-attr]
    carimbo = (agora or dt.datetime.now(dt.timezone.utc)).strftime("%Y%m%dT%H%M%SZ")
    epoca = raiz / f"epoch_{numero:04d}_{carimbo}"
    epoca.mkdir()
    _sync_dir(raiz)
    return publish(epoca, BASELINE, baseline)


# ── Publicação ───────────────────────────────────────────────────────────────
def _sync_dir(caminho: pathlib.Path) -> None:
    descritor = os.open(caminho, os.O_RDONLY)
    try:
        os.fsync(descritor)
    finally:
        os.close(descritor)


def encode(conteudo: Mapping[str, Any]) -> bytes:
    return (json.dumps(conteudo, ensure_ascii=False, indent=1, sort_keys=True) + "\n").encode("utf-8")


def publish(epoca: pathlib.Path, nome: str, conteudo: Mapping[str, Any]) -> Published:
    """Temporário, `fsync`, `link` para o nome final — que falha se ele existe —, `fsync` do diretório."""
    if "/" in nome or nome.startswith("."):
        raise LedgerError(f"nome de registro inválido: {nome!r}")
    dados = encode(conteudo)
    temporario = epoca / f".{nome}.{uuid.uuid4().hex}.tmp"
    final = epoca / nome
    try:
        with open(temporario, "xb") as arquivo:
            arquivo.write(dados)
            arquivo.flush()
            os.fsync(arquivo.fileno())
        try:
            os.link(temporario, final)
        except FileExistsError:
            raise LedgerError(f"{final} já existe: um registro nunca é substituído") from None
    finally:
        temporario.unlink(missing_ok=True)
    _sync_dir(epoca)
    return Published(final, hashlib.sha256(dados).hexdigest())


def probe_writable(epoca: pathlib.Path) -> None:
    """Prova a escrita com um temporário que sai em seguida (H7, passo 0). Falha com `OSError`."""
    teste = epoca / f".probe.{uuid.uuid4().hex}.tmp"
    try:
        with open(teste, "xb") as arquivo:
            arquivo.write(b"probe\n")
            arquivo.flush()
            os.fsync(arquivo.fileno())
    finally:
        teste.unlink(missing_ok=True)


def records(epoca: pathlib.Path) -> list[dict[str, Any]]:
    """Os registros publicados da época, lidos pelo conteúdo — o nome não diz nada (T4)."""
    return [
        json.loads(p.read_text(encoding="utf-8"))
        for p in sorted(epoca.iterdir())
        if p.is_file() and p.suffix == ".json" and not p.name.startswith(".")
    ]


# ── Medidas, somente leitura ─────────────────────────────────────────────────
def canonical_rows(linhas: Iterable[Mapping[str, Any]]) -> list[Any]:
    """Linhas na codificação canônica do `oraculos`, ordenadas: o registro "por inteiro"."""
    return [json.loads(c) for c in sorted(oraculos.linha_canonica(linha) for linha in linhas)]


def _raw_tables(conexao) -> list[str]:
    return leitura.tabelas_do_schema(conexao, RAW)


def _measure(linhas: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "rows": len(linhas),
        "digest": oraculos.digest(linhas),
        "generations": sorted({linha["_airbyte_generation_id"] for linha in linhas}, key=lambda g: (g is None, g)),
    }


def measure_capture(conexao, job_id: int) -> dict[str, dict[str, Any]]:
    """Por tabela do bruto, o que carrega o `sync_id` do *job*: contagem, *digest* e gerações."""
    return {
        tabela: _measure(list(leitura._linhas(
            conexao, f"select * from {RAW}.\"{tabela}\" where _airbyte_meta->>'sync_id' = :j", {"j": str(job_id)}
        )))
        for tabela in _raw_tables(conexao)
    }


def measure_captures(conexao) -> dict[str, dict[str, dict[str, Any]]]:
    """Todas as capturas do bruto, certificadas ou não, por `sync_id`: uma leitura por tabela."""
    por_captura: dict[str, dict[str, list[dict[str, Any]]]] = {}
    tabelas = _raw_tables(conexao)
    for tabela in tabelas:
        for linha in leitura._linhas(conexao, f'select * from {RAW}."{tabela}"'):
            sync_id = (linha["_airbyte_meta"] or {}).get("sync_id")
            chave = "null" if sync_id is None else str(sync_id)
            por_captura.setdefault(chave, {}).setdefault(tabela, []).append(linha)
    return {
        sync_id: {tabela: _measure(linhas.get(tabela, [])) for tabela in tabelas}
        for sync_id, linhas in sorted(por_captura.items())
    }


def certificate_rows(conexao, attempt_id: str | None = None) -> dict[str, Any]:
    """As linhas do certificado — de uma tentativa, ou todas —, por inteiro, com o *digest*."""
    filtro, parametros = ("where capture_attempt_id = :a", {"a": attempt_id}) if attempt_id else ("", {})
    linhas = list(leitura._linhas(conexao, f"select * from {CERTIFICATE} {filtro}", parametros))
    return {"rows": canonical_rows(linhas), "count": len(linhas), "digest": oraculos.digest(linhas)}


def _read_only(engine: Engine):
    return leitura._somente_leitura(engine)


def attempt_record(engine: Engine, attempt_id: str, *, caller: Mapping[str, Any],
                   agora: dt.datetime | None = None) -> dict[str, Any]:
    """O registro de uma tentativa (T4): certificado inteiro e, com *job*, as linhas dele.

    Seja qual for o certificado — `pending` incluído. Lido num só instante
    (`REPEATABLE READ`), para que certificado e bruto sejam do mesmo estado.
    """
    with _read_only(engine) as conexao:
        certificado = certificate_rows(conexao, attempt_id)
        if not certificado["count"]:
            raise LedgerError(f"tentativa {attempt_id} não existe em {CERTIFICATE}")
        jobs = {linha.get("job_id") for linha in leitura._linhas(
            conexao, f"select distinct job_id from {CERTIFICATE} where capture_attempt_id = :a", {"a": attempt_id}
        )}
        if len(jobs) != 1:
            raise LedgerError(f"tentativa {attempt_id} com mais de um job no certificado: {sorted(jobs, key=str)}")
        job_id = next(iter(jobs))
        bruto = measure_capture(conexao, int(job_id)) if job_id is not None else None
    return {
        "format": FORMAT,
        "kind": "attempt",
        "taken_at": (agora or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "capture_attempt_id": attempt_id,
        "job_id": None if job_id is None else int(job_id),
        "caller": dict(caller),
        "certificate": certificado,
        "raw": bruto,
    }


def baseline_record(engine: Engine, airbyte_jobs: Iterable[Mapping[str, Any]], *,
                    agora: dt.datetime | None = None) -> dict[str, Any]:
    """A linha de base (T4 na A8, e a de toda época que se abre): a memória inteira, num retrato.

    Capturas e certificado saem do mesmo instante; partição, quarentena,
    exclusões e versões, das leituras do empacotador — com a janela parada,
    nada se move entre elas.
    """
    with _read_only(engine) as conexao:
        capturas = measure_captures(conexao)
        certificado = certificate_rows(conexao)
    return {
        "format": FORMAT,
        "kind": "baseline",
        "taken_at": (agora or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "captures": capturas,
        "certificate": certificado,
        "partition": leitura.oraculo_da_particao(engine),
        "quarantine": leitura.oraculo_da_quarentena(engine),
        "deletions": leitura.oraculo_das_exclusoes(engine),
        "governance_versions": leitura.versoes_do_armazem(engine),
        "airbyte_jobs": sorted(
            ({"id": int(j["id"]), "type": j.get("type"), "status": j.get("status"), "started_at": j.get("started_at")}
             for j in airbyte_jobs),
            key=lambda j: j["id"],
        ),
    }


def legacy_jobs(listing: Iterable[Mapping[str, Any]], connection_id: str) -> list[dict[str, Any]]:
    """Os *jobs* da conexão legada numa listagem do Airbyte (`airbyte.jobs`): id, tipo, estado, início."""
    return [
        {"id": int(j["jobId"]), "type": j.get("jobType"), "status": j.get("status"), "started_at": j.get("startTime")}
        for j in listing
        if j.get("connectionId") == connection_id
    ]


# ── Nomes dos registros que o código toma (H6, H7) ───────────────────────────
def _safe(texto: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.+-]", "_", texto)


def gate_record_name(attempt_id: str, *, run_id: str | None = None) -> str:
    """O nome do registro de um portão: pela execução da DAG, ou pela CLI, e pela tentativa."""
    origem = f"dag_{_safe(run_id)}" if run_id else "cli"
    return f"{origem}_{_safe(attempt_id)}_attempt.json"
