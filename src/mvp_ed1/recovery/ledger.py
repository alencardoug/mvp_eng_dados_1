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

**Na fase GCP (Etapa 13, G2.1)** a raiz é `gs://<bucket>/<prefixo>`, e o "nunca substituído" é a
escrita condicionada do Cloud Storage em vez do `link` — o meio e o porquê de cada diferença estão
em `livro_gcs`. As funções abaixo despacham pelo tipo da raiz; o contrato é o mesmo.

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

import contextlib
import datetime as dt
import hashlib
import json
import os
import pathlib
import re
import uuid
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
from typing import Any

import sqlalchemy as sa
from sqlalchemy import Engine

from mvp_ed1.legacy import armazem as dialeto
from mvp_ed1.recovery import leitura, livro_gcs, oraculos
from mvp_ed1.recovery.livro_gcs import Lugar

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
    path: pathlib.Path | Lugar
    sha256: str


# ── A raiz e as épocas ───────────────────────────────────────────────────────
def root(environ: Mapping[str, str] | None = None) -> pathlib.Path | Lugar:
    """A raiz do livro, de `LEGACY_LEDGER_DIR`. Ausente, vazia, sem diretório ou sem *bucket*, falha."""
    valor = (os.environ if environ is None else environ).get(ENV, "").strip()
    if not valor:
        raise LedgerError(f"{ENV} ausente ou vazia: sem livro, nenhuma captura é registrada")
    if valor.startswith(livro_gcs.PREFIXO):
        try:
            lugar = Lugar.de(valor)
        except livro_gcs.LivroGcsError as erro:
            raise LedgerError(f"{ENV}={valor}: {erro}") from None
        motivo = livro_gcs.motivo_raiz(lugar)
        if motivo is not None:
            raise LedgerError(f"{ENV}={valor}: o bucket não existe ou não é legível — {motivo}")
        return lugar
    caminho = pathlib.Path(valor)
    if not caminho.is_dir():
        raise LedgerError(f"{ENV}={valor} não é um diretório")
    return caminho


def epochs(raiz: pathlib.Path | Lugar) -> list[pathlib.Path | Lugar]:
    """Os subdiretórios de época, pelo número, os mais antigos primeiro."""
    candidatos = livro_gcs.subprefixos(raiz) if isinstance(raiz, Lugar) else (p for p in raiz.iterdir() if p.is_dir())
    return sorted(
        (p for p in candidatos if EPOCH.match(p.name)),
        key=lambda p: int(EPOCH.match(p.name).group(1)),  # type: ignore[union-attr]
    )


def _valid_baseline(epoca: pathlib.Path | Lugar) -> bool:
    try:
        if isinstance(epoca, Lugar):
            dados = livro_gcs.ler(epoca / BASELINE)
            if dados is None:
                return False
            conteudo = json.loads(dados.decode("utf-8"))
        else:
            conteudo = json.loads((epoca / BASELINE).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return isinstance(conteudo, dict) and conteudo.get("kind") == "baseline" and conteudo.get("format") == FORMAT


def current_epoch(raiz: pathlib.Path | Lugar) -> pathlib.Path | Lugar:
    """A época mais nova com linha de base válida. Sem nenhuma, falha (H8)."""
    for epoca in reversed(epochs(raiz)):
        if _valid_baseline(epoca):
            return epoca
    raise LedgerError(f"{raiz}: nenhuma época com linha de base válida — abra uma (T4 da A8)")


def open_epoch(raiz: pathlib.Path | Lugar, baseline: Mapping[str, Any], *, agora: dt.datetime | None = None) -> Published:
    """Abre a época seguinte com a sua linha de base. Uma época que não chegou a ter a sua é pulada."""
    if baseline.get("kind") != "baseline" or baseline.get("format") != FORMAT:
        raise LedgerError("só uma linha de base abre época")
    existentes = epochs(raiz)
    numero = 1 + (int(EPOCH.match(existentes[-1].name).group(1)) if existentes else 0)  # type: ignore[union-attr]
    carimbo = (agora or dt.datetime.now(dt.timezone.utc)).strftime("%Y%m%dT%H%M%SZ")
    epoca = raiz / f"epoch_{numero:04d}_{carimbo}"
    if not isinstance(epoca, Lugar):
        # No Cloud Storage o prefixo nasce com o primeiro objeto, a própria linha de base.
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


def publish(epoca: pathlib.Path | Lugar, nome: str, conteudo: Mapping[str, Any]) -> Published:
    """Temporário, `fsync`, `link` para o nome final — que falha se ele existe —, `fsync` do diretório."""
    if "/" in nome or nome.startswith("."):
        raise LedgerError(f"nome de registro inválido: {nome!r}")
    if not nome.endswith(".json"):
        # `records` só lê `.json`: publicar com outro nome devolvia sucesso e deixava o
        # registro fora da leitura do H7 e do T3 (RVL1-07).
        raise LedgerError(f"nome de registro sem .json, que a leitura do livro ignoraria: {nome!r}")
    dados = encode(conteudo)
    if isinstance(epoca, Lugar):
        final = epoca / nome
        try:
            livro_gcs.criar(final, dados)
        except FileExistsError:
            raise LedgerError(f"{final} já existe: um registro nunca é substituído") from None
        return Published(final, hashlib.sha256(dados).hexdigest())
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


def probe_writable(epoca: pathlib.Path | Lugar) -> None:
    """Prova a escrita com um temporário que sai em seguida (H7, passo 0). Falha com `OSError`.

    No Cloud Storage, pela permissão, sem objeto de prova: ver `livro_gcs`."""
    if isinstance(epoca, Lugar):
        if not livro_gcs.pode_criar(epoca):
            raise PermissionError(f"{epoca}: a credencial corrente não cria objetos no bucket")
        return
    teste = epoca / f".probe.{uuid.uuid4().hex}.tmp"
    try:
        with open(teste, "xb") as arquivo:
            arquivo.write(b"probe\n")
            arquivo.flush()
            os.fsync(arquivo.fileno())
    finally:
        teste.unlink(missing_ok=True)


def records(epoca: pathlib.Path | Lugar) -> list[dict[str, Any]]:
    """Os registros publicados da época, lidos pelo conteúdo — o nome não diz nada (T4)."""
    if isinstance(epoca, Lugar):
        return [json.loads(dados.decode("utf-8")) for nome, dados in livro_gcs.objetos(epoca)
                if nome.endswith(".json") and not nome.startswith(".")]
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
            conexao, f"select * from {dialeto.bruto(conexao, RAW, tabela)} where {dialeto.sync_id(conexao)} = :j",
            {"j": str(job_id)}
        )))
        for tabela in _raw_tables(conexao)
    }


def measure_captures(conexao) -> dict[str, dict[str, dict[str, Any]]]:
    """Todas as capturas do bruto, certificadas ou não, por `sync_id`: uma leitura por tabela."""
    por_captura: dict[str, dict[str, list[dict[str, Any]]]] = {}
    tabelas = _raw_tables(conexao)
    for tabela in tabelas:
        for linha in leitura._linhas(conexao, f"select * from {dialeto.bruto(conexao, RAW, tabela)}"):
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
    linhas = list(leitura._linhas(conexao, f"select * from {dialeto.nome(conexao, CERTIFICATE)} {filtro}", parametros))
    return {"rows": canonical_rows(linhas), "count": len(linhas), "digest": oraculos.digest(linhas)}


def _read_only(engine: Engine):
    return leitura._somente_leitura(engine)


#: Os três registros que se tomam de uma tentativa: o da tentativa (o primeiro,
#: pelo portão ou pela recuperação), o da transição (quando a recuperação a
#: finaliza ou abandona) e — este por linha do operador — o de tratamento.
ATTEMPT, TRANSITION, TREATMENT = "attempt", "transition", "treatment"


def attempt_record(engine: Engine, attempt_id: str, *, caller: Mapping[str, Any], kind: str = ATTEMPT,
                   associated_job: int | None = None, reconciliation: Mapping[str, Any] | None = None,
                   agora: dt.datetime | None = None) -> dict[str, Any]:
    """O registro de uma tentativa (T4): certificado inteiro e, com *job*, as linhas dele.

    Seja qual for o certificado — `pending` incluído. Lido num só instante
    (`REPEATABLE READ`), para que certificado e bruto sejam do mesmo estado.
    Uma tentativa sem *job* no certificado a que a reconciliação do §4 associou
    um (`associated_job`) tem as linhas desse *job* medidas, e a associação vai
    no registro — o certificado nunca a recebe.
    """
    if kind not in (ATTEMPT, TRANSITION):
        raise LedgerError(f"tipo de registro de tentativa desconhecido: {kind}")
    with _read_only(engine) as conexao:
        certificado = certificate_rows(conexao, attempt_id)
        if not certificado["count"]:
            raise LedgerError(f"tentativa {attempt_id} não existe em {CERTIFICATE}")
        jobs = {linha.get("job_id") for linha in leitura._linhas(
            conexao, f"select distinct job_id from {dialeto.nome(conexao, CERTIFICATE)} where capture_attempt_id = :a",
            {"a": attempt_id}
        )}
        if len(jobs) != 1:
            raise LedgerError(f"tentativa {attempt_id} com mais de um job no certificado: {sorted(jobs, key=str)}")
        job_id = next(iter(jobs))
        if associated_job is not None and job_id is not None:
            raise LedgerError(f"tentativa {attempt_id} já tem o job {job_id}: não se associa outro")
        medido = job_id if job_id is not None else associated_job
        bruto = measure_capture(conexao, int(medido)) if medido is not None else None
    registro = {
        "format": FORMAT,
        "kind": kind,
        "taken_at": (agora or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "capture_attempt_id": attempt_id,
        "job_id": None if job_id is None else int(job_id),
        "caller": dict(caller),
        "certificate": certificado,
        "raw": bruto,
    }
    if associated_job is not None or reconciliation is not None:
        registro["associated_job"] = associated_job
        registro["reconciliation"] = dict(reconciliation or {})
    return registro


def treatment_record(engine: Engine, *, caller: Mapping[str, Any],
                     agora: dt.datetime | None = None) -> dict[str, Any]:
    """O registro de tratamento (T4): o tratamento corrente e o que ele rejeita, por fatia e tabela.

    Tirado depois de toda linha que construiu a quarentena, seja qual for o
    desfecho dela. A identidade é a das fatias da quarentena — origem, captura,
    versão do catálogo, impressão digital —, e as rejeitadas vão por tabela,
    com contagem e *digest* de todas as colunas: é o esperado que a T3 cobra
    deste tratamento quando um posterior o substitui.
    """
    esquema, tabela = leitura.TABELA_DA_CLASSIFICACAO.split(".")
    chave = leitura.CHAVE_DA_QUARENTENA
    with _read_only(engine) as conexao:
        if tabela not in leitura.tabelas_do_schema(conexao, esquema):
            raise LedgerError(f"{leitura.TABELA_DA_CLASSIFICACAO} não existe: não há tratamento a registrar")
        tratamentos = sorted(
            oraculos.nome_da_fatia(linha, chave)
            for linha in leitura._linhas(conexao, f"select distinct {', '.join(chave)} from {dialeto.nome(conexao, leitura.TABELA_DA_CLASSIFICACAO)}")
        )
        por_fatia: dict[str, dict[str, list[dict[str, Any]]]] = {}
        for linha in leitura._linhas(
            conexao, f"select * from {dialeto.nome(conexao, leitura.TABELA_DA_CLASSIFICACAO)} where classification = 'rejected'"
        ):
            por_fatia.setdefault(oraculos.nome_da_fatia(linha, chave), {}).setdefault(
                linha["source_table"], []).append(linha)
    return {
        "format": FORMAT,
        "kind": TREATMENT,
        "taken_at": (agora or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "caller": dict(caller),
        "treatments": tratamentos,
        "rejected": {
            fatia: {t: {"rows": len(linhas), "digest": oraculos.digest(linhas)} for t, linhas in sorted(tabelas.items())}
            for fatia, tabelas in sorted(por_fatia.items())
        },
    }


def deletion_rows(engine: Engine) -> list[dict[str, Any]] | None:
    """As linhas da memória de exclusões sem a coluna volátil — `None` sem a tabela, como no oráculo dela."""
    esquema, tabela = leitura.TABELA_DAS_EXCLUSOES.split(".")
    with _read_only(engine) as conexao:
        if tabela not in leitura.tabelas_do_schema(conexao, esquema):
            return None
        return [{c: v for c, v in linha.items() if c not in leitura.COLUNAS_VOLATEIS_DAS_EXCLUSOES}
                for linha in leitura._linhas(conexao, f"select * from {dialeto.nome(conexao, leitura.TABELA_DAS_EXCLUSOES)}")]


def deletion_keys(engine: Engine) -> list[list[str]] | None:
    linhas = deletion_rows(engine)
    return None if linhas is None else sorted([str(r["source_table"]), str(r["business_key"])] for r in linhas)


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
        esquema, tabela = leitura.TABELA_DA_QUARENTENA.split(".")
        tem_quarentena = tabela in leitura.tabelas_do_schema(conexao, esquema)
    return {
        "format": FORMAT,
        "kind": "baseline",
        "taken_at": (agora or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "captures": capturas,
        "certificate": certificado,
        "partition": leitura.oraculo_da_particao(engine),
        # Armazém sem `dbt build` não tem quarentena: `None`, como as exclusões.
        "quarantine": leitura.oraculo_da_quarentena(engine) if tem_quarentena else None,
        "deletions": leitura.oraculo_das_exclusoes(engine),
        # As chaves da memória de exclusões, para o T3 aceitar exatamente as que o Owner aceitou (H2).
        "deletion_keys": deletion_keys(engine),
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


# ── Os portões (H6) ──────────────────────────────────────────────────────────
class GateRefused(LedgerError):
    """O portão não registra: tentativa repetida, ou uma tentativa que ainda não tem o que registrar."""


def writable_epoch(environ: Mapping[str, str] | None = None) -> pathlib.Path | Lugar:
    """A época corrente, provada gravável — o que os dois chamadores conferem antes de abrir tentativa.

    Sem ela, uma captura terminaria sem registro possível e pararia a barreira
    seguinte (H7, passo 0).
    """
    epoca = current_epoch(root(environ))
    probe_writable(epoca)
    return epoca


def gate(
    engine: Engine,
    attempt_id: str | None,
    *,
    caller: Mapping[str, Any],
    run_id: str | None = None,
    try_number: int = 1,
    job_state: Callable[[int], str] | None = None,
    environ: Mapping[str, str] | None = None,
    lock_held: bool = False,
) -> tuple[Published, dict[str, Any]]:
    """O registro da tentativa do próprio chamador, na época corrente, segurando o lock dela (H6).

    Registra o certificado **como estiver** — `pending` incluído, mas só com o
    *job* já final, como a T4 pede. Uma tentativa sem *job*, ou com o *job* em
    curso, não é registrável agora: fica para a fase de recuperação do próximo
    chamador (H7). Fora da primeira tentativa da tarefa, recusa sem escrever —
    repetir o portão sozinho tomaria um retrato novo em nome da captura antiga
    (N31). `lock_held` diz que o chamador já segura o lock da tentativa — a
    CLI o segura a invocação inteira (H7) —: tomá-lo de novo, noutra sessão,
    esperaria por si mesmo. Devolve o publicado e o registro.
    """
    from mvp_ed1.airbyte import CONCLUIDOS
    from mvp_ed1.legacy import captura

    if try_number != 1:
        raise GateRefused(
            f"tentativa {try_number} do portão: repeti-lo sozinho é proibido (N31) — "
            "siga o §5 do runbook e rode a DAG inteira de novo"
        )
    if not attempt_id:
        raise GateRefused("nenhuma tentativa de captura aberta nesta execução: nada a registrar")
    epoca = writable_epoch(environ)
    bloqueio = contextlib.nullcontext() if lock_held else captura.bloqueio_da_tentativa(engine, attempt_id)
    with bloqueio:
        chamador = {**caller, "run_id": run_id, "try_number": try_number}
        registro = attempt_record(engine, attempt_id, caller=chamador)
        if {linha["status"] for linha in registro["certificate"]["rows"]} == {captura.PENDING}:
            job = registro["job_id"]
            if job is None:
                raise GateRefused(f"tentativa {attempt_id} pendente sem job: fica para a recuperação (H7)")
            estado = job_state(job) if job_state is not None else None
            if estado not in CONCLUIDOS:
                raise GateRefused(
                    f"tentativa {attempt_id} pendente com o job {job} "
                    f"{'sem observador' if estado is None else estado}: fica para a recuperação (H7)"
                )
            # O retrato vale só tomado depois de o job estar final: o da primeira leitura
            # podia ser de um job que terminou entre ela e a consulta (RVL1-08).
            registro = attempt_record(engine, attempt_id, caller=chamador)
            if registro["job_id"] != job:
                raise GateRefused(f"tentativa {attempt_id}: o job mudou de {job} para {registro['job_id']} "
                                  "entre as duas leituras do portão")
        publicado = publish(epoca, gate_record_name(attempt_id, run_id=run_id), registro)
    return publicado, registro


def certificate_status(registro: Mapping[str, Any]) -> str:
    """O estado da tentativa no registro: o único, ou `mixed`."""
    estados = {linha["status"] for linha in registro["certificate"]["rows"]}
    return estados.pop() if len(estados) == 1 else "mixed"


# ── Linha de comando: a linha de base do operador ────────────────────────────
#: Quantos *jobs* a listagem pede. Uma listagem cheia pode ter deixado *jobs*
#: de fora, e a reconciliação partiria de um histórico incompleto: recusa.
JOBS_LISTED = 1000


def operator_record(engine: Engine, attempt_id: str, nome: str, *,
                    environ: Mapping[str, str] | None = None) -> Published:
    """O registro de tentativa que o operador toma à mão (T4) — recusado com o lock tomado.

    Lock tomado é chamador vivo (H7): registrar agora tomaria o retrato de uma
    tentativa ainda em curso. O nome é o da linha do runbook — `D2_a1_memoria.json`.
    """
    from mvp_ed1.legacy import captura

    from mvp_ed1.recovery import capture_recovery

    epoca = writable_epoch(environ)
    with captura.bloqueio_da_tentativa(engine, attempt_id, esperar=False):
        # O nome do arquivo não identifica a tentativa: um segundo nome publicava um segundo
        # primeiro registro dela (RVL1-06). A identidade é o conteúdo, lido sob o lock.
        guardado = capture_recovery.held(records(epoca)).kinds.get(attempt_id)
        if guardado is not None:
            raise LedgerError(f"a época já guarda a tentativa {attempt_id} ({guardado}): um registro manual "
                              "não a reabre")
        registro = attempt_record(engine, attempt_id, caller={"kind": "operator"})
        return publish(epoca, nome, registro)


def main(argv: list[str] | None = None) -> int:
    """`baseline` abre a época seguinte com a linha de base (T4, A8; H8); `attempt` registra uma tentativa à mão."""
    import argparse
    import sys

    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.recovery.ledger")
    parser.add_argument("command", choices=["baseline", "attempt", "treatment"])
    parser.add_argument("--attempt", help="attempt: o capture_attempt_id")
    parser.add_argument("--name", help="attempt e treatment: o nome do registro, pela linha do runbook "
                                       "(D2_a1_memoria.json, D3_a1_tratamento.json)")
    args = parser.parse_args(argv)

    from sqlalchemy import create_engine

    from mvp_ed1 import airbyte
    from mvp_ed1.db import LEGACY, database_url

    # O armazém que o `.env` declara (`LEGACY_WAREHOUSE`): no GCP, a época inicial lê o BigQuery.
    legado = create_engine(database_url(LEGACY))

    if args.command == "treatment":
        if not args.name:
            parser.error("treatment pede --name")
        armazem = dialeto.do_ambiente(legado)
        try:
            publicado = publish(writable_epoch(), args.name, treatment_record(armazem, caller={"kind": "operator"}))
        finally:
            armazem.dispose()
        print(f"registro de tratamento: {publicado.path} · sha256 {publicado.sha256}")
        return 0
    if args.command == "attempt":
        if not args.attempt or not args.name:
            parser.error("attempt pede --attempt e --name")
        armazem = dialeto.do_ambiente(legado)
        try:
            publicado = operator_record(armazem, args.attempt, args.name)
        finally:
            armazem.dispose()
        print(f"registro: {publicado.path} · sha256 {publicado.sha256}")
        return 0
    from mvp_ed1.legacy.identidade import CONEXAO_LEGADA

    raiz = root()
    jwt = airbyte.token()
    listagem = (airbyte.jobs(jwt, JOBS_LISTED) or {}).get("data", [])
    if len(listagem) >= JOBS_LISTED:
        print(f"RECUSADO: a listagem do Airbyte veio cheia ({len(listagem)}); o histórico pode estar incompleto",
              file=sys.stderr)
        return 2
    jobs = legacy_jobs(listagem, airbyte.conexao(CONEXAO_LEGADA, jwt))
    armazem = dialeto.do_ambiente(legado)
    try:
        linha_de_base = baseline_record(armazem, jobs)
    finally:
        armazem.dispose()
    publicado = open_epoch(raiz, linha_de_base)
    print(f"época aberta: {publicado.path.parent}")
    print(f"linha de base: {publicado.path} · sha256 {publicado.sha256}")
    print(f"  {len(linha_de_base['captures'])} capturas no bruto, {linha_de_base['certificate']['count']} linhas "
          f"de certificado, {len(jobs)} jobs da conexão legada")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
