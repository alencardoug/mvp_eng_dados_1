"""A fase de recuperação das capturas do legado — H7 da regeneração da v1.1.0.

`captura.iniciar` finalizava as tentativas pendentes de antes da nova, e a
transição acontecia sem registro, com o registro só depois do *job* novo
(RR-28). Agora nada finaliza uma tentativa a não ser esta fase, que os dois
chamadores — `make sync-legacy` e a tarefa `retomar_capturas_do_legado` da DAG
— rodam antes de abrir a sua, contra a época corrente do livro retido
(`ledger`; decisões N30, N32 e N34 do Owner no plano do `bi-como-codigo`):

0. **a época corrente**, com linha de base válida e escrita provada;
1. **as pendentes, lidas uma vez**, como conjunto fixo. Cada uma cujo *job* é
   final, ou que não tem *job*, passou da carência e cujo lock a fase toma sem
   esperar — e segura até a transição dela estar registrada —, ganha o seu
   registro de tentativa, se a época ainda não tem um. A sem *job* passa antes
   pela reconciliação do runbook §4 com a listagem do Airbyte. Uma pendente
   ainda ativa — *job* em curso, sem *job* dentro da carência, ou lock tomado,
   seja qual for a idade — é motivo de parada: espere e rode de novo;
2. **`retomar` restrito às registradas em (1)** — uma que mudou de estado no
   meio-tempo fica de fora —, e o registro de transição de cada uma que ele
   mudou, na hora;
3. **a barreira**, lida depois de (2) (`barreira`): o inventário inteiro desde a
   linha de base.

Qualquer diferença para — e nunca vira transição (N34). Uma falha em qualquer
passo levanta antes de `iniciar`: nenhuma tentativa aberta, nenhum *job*
disparado. A barreira roda de novo **dentro** do lock de abertura de `iniciar`
(`barreira_de_abertura`), e é essa a decisão de abrir (RR-37); a desta fase é
só uma parada antecipada.

**Um chamador vivo por vez** (N35). O que esta fase afirma vale enquanto um só
chamador de captura está vivo; dois juntos são limitação declarada, e os locks
são defesa além disso.
"""

from __future__ import annotations

import contextlib
import datetime as dt
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy import Connection, Engine, text

from mvp_ed1.recovery import leitura, ledger

#: O tempo-limite de cada leitura da barreira: uma leitura parada levanta,
#: desfaz a transação e solta o lock de abertura — uma parada, nunca uma
#: abertura (RR-41). A listagem do Airbyte já tem o do cliente (60 s).
STATEMENT_TIMEOUT_MS = 120_000


class RecoveryStopped(ledger.LedgerError):
    """A recuperação parou: o que achou vai em `problems`, e nada foi aberto."""

    def __init__(self, problems: list[str]) -> None:
        super().__init__("a recuperação parou:\n  " + "\n  ".join(problems))
        self.problems = problems


# ── O que a época guarda ─────────────────────────────────────────────────────
def _instant(valor: Any) -> dt.datetime:
    if isinstance(valor, dt.datetime):
        return valor if valor.tzinfo else valor.replace(tzinfo=dt.timezone.utc)
    if isinstance(valor, (int, float)):
        return dt.datetime.fromtimestamp(valor, dt.timezone.utc)
    instante = dt.datetime.fromisoformat(str(valor).replace("Z", "+00:00"))
    return instante if instante.tzinfo else instante.replace(tzinfo=dt.timezone.utc)


def _by_attempt(linhas: Iterable[Mapping[str, Any]]) -> dict[str, list[Any]]:
    """Linhas canônicas do certificado agrupadas por tentativa, na ordem canônica."""
    saida: dict[str, list[Any]] = {}
    for linha in linhas:
        saida.setdefault(linha["capture_attempt_id"], []).append(linha)
    return saida


def _job_of(linhas: list[Any]) -> int | None:
    jobs = {linha.get("job_id") for linha in linhas}
    return next(iter(jobs)) if len(jobs) == 1 else None


@dataclass
class Held:
    """O que a época corrente guarda: o último registro de cada tentativa e a linha de base."""

    rows: dict[str, list[Any]] = field(default_factory=dict)
    kinds: dict[str, str] = field(default_factory=dict)
    associated: dict[str, int] = field(default_factory=dict)
    baseline_captures: set[str] = field(default_factory=set)
    baseline_taken_at: dt.datetime | None = None

    def claims(self) -> dict[int, list[str]]:
        """*Job* → tentativas que o reivindicam: pelo certificado registrado ou pela associação."""
        saida: dict[int, list[str]] = {}
        for tentativa, linhas in self.rows.items():
            job = _job_of(linhas)
            if job is not None:
                saida.setdefault(int(job), []).append(tentativa)
        for tentativa, job in self.associated.items():
            saida.setdefault(int(job), []).append(tentativa)
        return saida


def held(registros: Iterable[Mapping[str, Any]]) -> Held:
    """O último registro de cada tentativa: transição sobre tentativa, tentativa sobre linha de base."""
    estado = Held()
    ordem = {"baseline": 0, ledger.ATTEMPT: 1, ledger.TRANSITION: 2}
    escolhidos: dict[str, tuple[int, str]] = {}
    linhas_de_base = [r for r in registros if r.get("kind") == "baseline"]
    if len(linhas_de_base) != 1:
        raise ledger.LedgerError(f"a época tem {len(linhas_de_base)} linhas de base, e precisa de uma")
    base = linhas_de_base[0]
    estado.baseline_taken_at = _instant(base["taken_at"]) if base.get("taken_at") else None
    estado.baseline_captures = set(base.get("captures", {}))
    for tentativa, linhas in _by_attempt(base.get("certificate", {}).get("rows", [])).items():
        estado.rows[tentativa] = linhas
        estado.kinds[tentativa] = "baseline"
        escolhidos[tentativa] = (0, "")
    for registro in registros:
        tipo = registro.get("kind")
        if tipo not in (ledger.ATTEMPT, ledger.TRANSITION):
            continue
        tentativa = registro["capture_attempt_id"]
        chave = (ordem[tipo], registro.get("taken_at", ""))
        if registro.get("associated_job") is not None:
            estado.associated[tentativa] = int(registro["associated_job"])
        if chave >= escolhidos.get(tentativa, (-1, "")):
            escolhidos[tentativa] = chave
            estado.rows[tentativa] = list(registro["certificate"]["rows"])
            estado.kinds[tentativa] = tipo
    return estado


# ── O que o banco e o Airbyte mostram agora ──────────────────────────────────
@dataclass(frozen=True)
class Listing:
    """Os *jobs* da conexão legada numa listagem, e até onde ela vai para trás."""

    jobs: list[dict[str, Any]]
    #: `None` quando a listagem trouxe tudo o que o Airbyte tem; senão, o
    #: início do *job* mais antigo listado, de qualquer conexão.
    oldest: dt.datetime | None

    def reaches(self, instante: dt.datetime) -> bool:
        return self.oldest is None or self.oldest <= instante


def airbyte_listing(jwt: str, connection_id: str) -> Listing:
    """A listagem do Airbyte, sob o tempo-limite do cliente; uma que não se lê levanta."""
    from mvp_ed1 import airbyte

    todos = (airbyte.jobs(jwt, ledger.JOBS_LISTED) or {}).get("data", [])
    mais_antigo = min((_instant(j["startTime"]) for j in todos if j.get("startTime")), default=None)
    return Listing(
        jobs=ledger.legacy_jobs(todos, connection_id),
        oldest=mais_antigo if len(todos) >= ledger.JOBS_LISTED else None,
    )


@dataclass(frozen=True)
class Warehouse:
    """O certificado inteiro, por tentativa, e os `sync_id` do bruto — lidos numa transação."""

    certificate: dict[str, list[Any]]
    started: dict[str, dt.datetime]
    sync_ids: set[str]


def read_warehouse(conexao: Connection) -> Warehouse:
    """Sob o tempo-limite de leitura (RR-41); `conexao` precisa estar numa transação."""
    conexao.execute(text(f"set local statement_timeout = {int(STATEMENT_TIMEOUT_MS)}"))
    linhas = list(leitura._linhas(conexao, f"select * from {ledger.CERTIFICATE}"))
    inicio: dict[str, dt.datetime] = {}
    for linha in linhas:
        atual = inicio.get(linha["capture_attempt_id"])
        inicio[linha["capture_attempt_id"]] = linha["started_at"] if atual is None else min(atual, linha["started_at"])
    sync_ids: set[str] = set()
    for tabela in leitura.tabelas_do_schema(conexao, ledger.RAW):
        sync_ids |= {
            v for (v,) in conexao.execute(text(
                f"select distinct coalesce(_airbyte_meta->>'sync_id', 'null') from {ledger.RAW}.\"{tabela}\""
            ))
        }
    return Warehouse(_by_attempt(ledger.canonical_rows(linhas)), inicio, sync_ids)


# ── (3) A barreira ───────────────────────────────────────────────────────────
def barrier(estado: Held, armazem: Warehouse, listagem: Listing) -> list[str]:
    """Tudo o que impede abrir uma tentativa. Vazio, a barreira passa (H7, passo 3; N32)."""
    problemas: list[str] = []
    for tentativa, linhas in sorted(armazem.certificate.items()):
        if tentativa not in estado.rows:
            problemas.append(f"tentativa {tentativa} sem registro na época")
        elif linhas != estado.rows[tentativa]:
            problemas.append(
                f"tentativa {tentativa}: o certificado difere do último registro ({estado.kinds[tentativa]})"
            )
        if any(linha.get("status") == "pending" for linha in linhas):
            problemas.append(f"tentativa {tentativa} ainda pending")
    for tentativa in sorted(set(estado.rows) - set(armazem.certificate)):
        problemas.append(f"tentativa {tentativa}, registrada na época, sumiu do certificado")
    reivindicados = estado.claims()
    explicados = estado.baseline_captures | {str(job) for job in reivindicados}
    for sync_id in sorted(armazem.sync_ids - explicados):
        problemas.append(f"sync_id {sync_id} do bruto sem tentativa registrada nem captura da linha de base")
    if estado.baseline_taken_at is None or not listagem.reaches(estado.baseline_taken_at):
        problemas.append("a listagem do Airbyte não chega à linha de base: o inventário de jobs está incompleto")
    else:
        for job in listagem.jobs:
            if not job.get("started_at") or _instant(job["started_at"]) <= estado.baseline_taken_at:
                continue
            donos = reivindicados.get(int(job["id"]), [])
            if len(donos) != 1:
                problemas.append(
                    f"job {job['id']} da conexão legada, de depois da linha de base, reivindicado por "
                    f"{len(donos)} tentativas" + (f" ({', '.join(sorted(donos))})" if donos else "")
                )
    return problemas


def opening_barrier(listar: Callable[[], Listing], environ: Mapping[str, str] | None = None) -> Callable[[Connection], list[str]]:
    """A barreira que `iniciar` roda dentro do lock de abertura, contra a época corrente (RR-37)."""

    def rodar(conexao: Connection) -> list[str]:
        epoca = ledger.writable_epoch(environ)
        return barrier(held(ledger.records(epoca)), read_warehouse(conexao), listar())

    return rodar


# ── (1) A reconciliação de uma tentativa sem job (runbook §4) ────────────────
@dataclass(frozen=True)
class Reconciled:
    job: int | None = None
    job_status: str | None = None
    stop: str | None = None
    window: tuple[str, str] | None = None


def reconcile(tentativa: str, armazem: Warehouse, estado: Held, listagem: Listing,
              agora: dt.datetime) -> Reconciled:
    """O *job* de uma tentativa sem *job*, se houver exatamente um na janela dela e de ninguém mais."""
    inicio = armazem.started[tentativa]
    seguintes = sorted(t for t in armazem.started.values() if t > inicio)
    fim = seguintes[0] if seguintes else agora
    janela = (inicio.isoformat(), fim.isoformat())
    if not listagem.reaches(inicio):
        return Reconciled(stop=f"tentativa {tentativa}: a listagem do Airbyte não chega ao início da janela",
                          window=janela)
    de_outras: set[int] = set()
    for outra, linhas in armazem.certificate.items():
        if outra != tentativa and _job_of(linhas) is not None:
            de_outras.add(int(_job_of(linhas)))
    de_outras |= {job for outra, job in estado.associated.items() if outra != tentativa}
    candidatos = [
        j for j in listagem.jobs
        if j.get("started_at") and inicio <= _instant(j["started_at"]) < fim and int(j["id"]) not in de_outras
    ]
    if len(candidatos) > 1:
        return Reconciled(stop=f"tentativa {tentativa}: {len(candidatos)} jobs na janela "
                               f"({', '.join(str(j['id']) for j in candidatos)})", window=janela)
    if candidatos:
        return Reconciled(job=int(candidatos[0]["id"]), job_status=candidatos[0].get("status"), window=janela)
    jobs_conhecidos = {str(j) for j in de_outras}
    sem_dono = armazem.sync_ids - estado.baseline_captures - jobs_conhecidos
    if sem_dono:
        return Reconciled(stop=f"tentativa {tentativa}: sem job na janela, e sync_id sem tentativa no bruto "
                               f"({', '.join(sorted(sem_dono))})", window=janela)
    return Reconciled(window=janela)


# ── A fase inteira ───────────────────────────────────────────────────────────
def _record_name(tentativa: str, tipo: str) -> str:
    return f"recovery_{ledger._safe(tentativa)}_{tipo}.json"


def recover(
    legado: Engine,
    armazem: Engine,
    *,
    job_state: Callable[[int], str] | None,
    listar: Callable[[], Listing],
    caller: Mapping[str, Any],
    environ: Mapping[str, str] | None = None,
    agora: dt.datetime | None = None,
) -> dict[str, Any]:
    """Os passos 0 a 3. Devolve o que fez; para com `RecoveryStopped` — e nada se abre."""
    from mvp_ed1.airbyte import CONCLUIDOS
    from mvp_ed1.legacy import captura

    agora = agora or dt.datetime.now(dt.timezone.utc)
    epoca = ledger.writable_epoch(environ)                                         # (0)
    estado = held(ledger.records(epoca))
    paradas: list[str] = []
    registradas: list[str] = []
    publicados: list[str] = []
    listagem: Listing | None = None
    with contextlib.ExitStack() as locks:
        with armazem.begin() as conexao:
            visto = read_warehouse(conexao)
        for tentativa, job, inicio in captura._pendentes(armazem):                 # (1)
            try:
                locks.enter_context(captura.bloqueio_da_tentativa(armazem, tentativa, esperar=False))
            except captura.TentativaOcupada:
                paradas.append(f"tentativa {tentativa} ativa: o lock está com um chamador vivo — espere e rode de novo")
                continue
            associado = None
            reconciliacao = None
            if job is not None:
                estado_do_job = job_state(int(job)) if job_state is not None else None
                if estado_do_job not in CONCLUIDOS:
                    paradas.append(f"tentativa {tentativa} ativa: job {job} "
                                   f"{'sem observador' if estado_do_job is None else estado_do_job}")
                    continue
            elif agora - inicio < captura.CARENCIA_SEM_JOB:
                paradas.append(f"tentativa {tentativa} ativa: sem job, dentro da carência")
                continue
            elif tentativa not in estado.rows:
                if listagem is None:
                    try:
                        listagem = listar()
                    except Exception as erro:  # noqa: BLE001 — sem listagem, a reconciliação não se faz
                        raise RecoveryStopped([f"a listagem do Airbyte não se leu: {erro}"]) from erro
                achado = reconcile(tentativa, visto, estado, listagem, agora)
                if achado.stop:
                    paradas.append(achado.stop)
                    continue
                if achado.job is not None and achado.job_status not in CONCLUIDOS:
                    paradas.append(f"tentativa {tentativa} ativa: o job {achado.job} da janela dela está "
                                   f"{achado.job_status}")
                    continue
                associado = achado.job
                reconciliacao = {"window": list(achado.window or ()), "associated_job": associado}
            if tentativa not in estado.rows:
                registro = ledger.attempt_record(
                    armazem, tentativa, caller={**caller, "phase": "recovery"},
                    associated_job=associado, reconciliation=reconciliacao,
                )
                publicados.append(str(ledger.publish(epoca, _record_name(tentativa, ledger.ATTEMPT), registro).path))
            registradas.append(tentativa)

        ledger.probe_writable(epoca)                                               # (2)
        transicoes: dict[str, str] = {}
        for tentativa in registradas:
            feito = captura.retomar(legado, armazem, estado_do_job=job_state, agora=agora, apenas={tentativa})
            resultado = feito.get(tentativa)
            if resultado in ("concluida", "abandonada"):
                registro = ledger.attempt_record(armazem, tentativa, caller={**caller, "phase": "recovery"},
                                                 kind=ledger.TRANSITION)
                publicados.append(str(ledger.publish(epoca, _record_name(tentativa, ledger.TRANSITION),
                                                     registro).path))
                transicoes[tentativa] = resultado
    if paradas:
        raise RecoveryStopped(paradas)

    estado = held(ledger.records(epoca))                                           # (3)
    with armazem.begin() as conexao:
        visto = read_warehouse(conexao)
    try:
        listagem = listar()
    except Exception as erro:  # noqa: BLE001 — a barreira precisa da listagem
        raise RecoveryStopped([f"a listagem do Airbyte não se leu: {erro}"]) from erro
    problemas = barrier(estado, visto, listagem)
    if problemas:
        raise RecoveryStopped(problemas)
    return {"epoch": str(epoca), "recorded": registradas, "transitions": transicoes, "published": publicados}
