"""Certificação de uma captura do legado, em duas fases (ADR-0044).

Uma captura só é **elegível** — para ser lida pelos modelos ou para servir de
"anterior" à detecção de exclusão física — quando tem certificado `complete`
nas 40 tabelas em `governance.legacy_captures`. O certificado responde, por
tabela e por conteúdo, três perguntas que máximo de geração e `rowsSynced` não
respondiam (a geração 15 retida tem 39 tabelas, *job* `succeeded` e total
exato): a origem ficou parada durante o *job*? o que chegou é o que a origem
tinha, linha a linha e com multiplicidade? e as linhas são **deste** *job*?

* **Fase 1** (`iniciar`), antes de disparar o *job*: contagem e hash de conteúdo
  de cada tabela na origem, gravados como `pending`. É a medição que não pode
  ser refeita depois — a origem de hoje não é a origem de antes.
* **Fase 2** (`concluir`), depois de o *job* terminar: origem de novo, bruto da
  geração que carrega o `sync_id` do *job*, e o veredito por tabela.

`decidir()` é a regra pura — sem banco —, e é o que os testes de unidade
exercitam com origens e brutos fictícios: alteração sem mudança de contagem,
duplicata compensando perda, linhas de outro *job* na geração.

Quem chama: a DAG (`iniciar` → sincronizar → `concluir`) e `make sync-legacy`,
pela mesma função. As duas fases são *upserts* pela chave
`(capture_attempt_id, source_table)`: reenviar produz o mesmo estado — e uma
tentativa já fechada **não é remedida**: o reenvio devolve o que está gravado.

A fase 2 publica veredito e identidade (`snapshot_id`) das 40 tabelas numa
única transação. Até 15/09/2026 eram duas, e uma interrupção entre elas deixava
40 linhas `complete` sem identidade — que a recuperação não via e que faziam
`certificadas` falhar (achado RV10-01).
"""

from __future__ import annotations

import datetime as dt
import uuid
from dataclasses import dataclass
from typing import Any, Callable

from sqlalchemy import Engine, text

from mvp_ed1 import governance
from mvp_ed1.airbyte import CONCLUIDOS as JOB_TERMINADO
from mvp_ed1.legacy import conteudo, schema

RAW = "raw_legacy"
TABELA = f"{governance.SCHEMA}.legacy_captures"

PENDING, COMPLETE, UNSTABLE, INCOMPLETE, INCONSISTENT, ABANDONED = (
    "pending", "complete", "unstable", "incomplete", "inconsistent", "abandoned",
)

#: Quanto tempo uma tentativa pode ficar `pending` sem `job_id` antes de a
#: retomada considerá-la abandonada. A janela real entre a fase 1 e o registro
#: do *job* é de segundos (CLI) a poucos minutos (duas tarefas da DAG); uma
#: tentativa mais nova que isto pode ser de outro chamador ainda a caminho, e a
#: retomada não a toca (RV10-03). Decidido pelo Owner em 15/09/2026.
CARENCIA_SEM_JOB = dt.timedelta(hours=1)

#: Como a retomada pergunta se um *job* terminou: recebe o `job_id`, devolve o
#: estado (`succeeded`, `running`, …). Sem observador, nenhuma tentativa com
#: *job* é concluída na retomada — fechar um bruto ainda parcial como
#: `incomplete` seria pior do que deixá-lo pendente.
EstadoDoJob = Callable[[int], str]


@dataclass(frozen=True)
class Medida:
    linhas: int
    hash: str


@dataclass(frozen=True)
class Recebido:
    """O que o bruto tem com o `sync_id` do *job*, e o que a geração dele tem de estranho.

    A identidade da captura é o `sync_id` (`schema.CAPTURA_SQL`); a geração é
    **por stream** e serve só de conferência dentro da tabela: um *job* escreve
    uma geração por tabela, e essa geração não pode ter linhas de outro *job*.
    """

    linhas: int
    hash: str
    #: Gerações, **nesta tabela**, das linhas com o `sync_id` do job.
    geracoes: tuple[int, ...]
    #: Linhas na(s) mesma(s) geração(ões) desta tabela com outro `sync_id`.
    intrusas: int


def decidir(antes: Medida, depois: Medida, recebido: Recebido) -> str:
    """O veredito de **uma** tabela — regra pura, na ordem de gravidade.

    `inconsistent` antes de tudo: linhas de dois *jobs* na mesma geração da
    tabela, ou um *job* espalhado por duas gerações da mesma tabela, tornam
    qualquer contagem sem sentido.
    Depois `unstable`: a origem mudou durante a carga, e o que chegou não tem
    contra o que ser conferido. Só então conteúdo e multiplicidade — e é aqui
    que perda compensada por duplicata e alteração sem mudança de contagem
    caem, porque o hash é sobre todas as linhas em ordem física.
    """
    if recebido.intrusas or len(recebido.geracoes) > 1:
        return INCONSISTENT
    if antes != depois:
        return UNSTABLE
    if recebido.linhas != depois.linhas or recebido.hash != depois.hash:
        return INCOMPLETE
    return COMPLETE


def medir_origem(legado: Engine) -> dict[str, Medida]:
    with legado.connect() as conexao:
        return {
            tabela: Medida(**conteudo.hash_no_banco(conexao, schema.SCHEMA, tabela))
            for tabela in schema.tabelas()
        }


def medir_recebido(armazem: Engine, job_id: int) -> dict[str, Recebido]:
    """Por tabela, o que carrega o `sync_id` do *job* — e o que há de intruso na geração dele."""
    saida: dict[str, Recebido] = {}
    with armazem.connect() as conexao:
        for tabela in schema.tabelas():
            medida = conteudo.hash_no_banco(
                conexao, RAW, tabela, "_airbyte_meta->>'sync_id' = :j", {"j": str(job_id)}
            )
            geracoes = tuple(
                int(g)
                for (g,) in conexao.execute(
                    text(
                        f'select distinct _airbyte_generation_id from {RAW}."{tabela}" '
                        "where _airbyte_meta->>'sync_id' = :j order by 1"
                    ),
                    {"j": str(job_id)},
                )
            )
            intrusas = 0
            if geracoes:
                intrusas = conexao.execute(
                    text(
                        f'select count(*) from {RAW}."{tabela}" '
                        "where _airbyte_generation_id = any(:gs) "
                        "and coalesce(_airbyte_meta->>'sync_id', '') <> :j"
                    ),
                    {"gs": list(geracoes), "j": str(job_id)},
                ).scalar_one()
            saida[tabela] = Recebido(medida["linhas"], medida["hash"], geracoes, int(intrusas))
    return saida


# ── Fase 1 ───────────────────────────────────────────────────────────────────

def iniciar(
    legado: Engine,
    armazem: Engine,
    conexao_airbyte: str,
    *,
    estado_do_job: EstadoDoJob | None = None,
    agora: dt.datetime | None = None,
) -> str:
    """Mede a origem e abre a tentativa como `pending`. Devolve o `capture_attempt_id`.

    Antes de abrir a sua, resolve as tentativas pendentes que ficaram para trás
    (`retomar`). Nenhuma é reaproveitada em silêncio, e nenhuma ainda ativa é
    fechada.
    """
    governance.garantir(armazem)
    agora = agora or dt.datetime.now(dt.timezone.utc)
    retomar(legado, armazem, estado_do_job=estado_do_job, agora=agora)

    tentativa = uuid.uuid4().hex
    origem = medir_origem(legado)
    with armazem.begin() as conexao:
        for tabela, medida in origem.items():
            conexao.execute(
                text(
                    f"""
                    insert into {TABELA}
                        (capture_attempt_id, source_table, connection_name, source_rows_before,
                         source_hash_before, status, started_at)
                    values (:a, :t, :c, :n, :h, :s, :quando)
                    on conflict (capture_attempt_id, source_table) do update
                        set source_rows_before = excluded.source_rows_before,
                            source_hash_before = excluded.source_hash_before,
                            status = excluded.status
                    """
                ),
                {"a": tentativa, "t": tabela, "c": conexao_airbyte, "n": medida.linhas,
                 "h": medida.hash, "s": PENDING, "quando": agora},
            )
    return tentativa


def registrar_job(armazem: Engine, tentativa: str, job_id: int) -> None:
    """Grava o `job_id` assim que o *job* nasce — antes de esperar por ele."""
    with armazem.begin() as conexao:
        conexao.execute(
            text(f"update {TABELA} set job_id = :j where capture_attempt_id = :a"),
            {"j": int(job_id), "a": tentativa},
        )


def retomar(
    legado: Engine,
    armazem: Engine,
    *,
    estado_do_job: EstadoDoJob | None = None,
    agora: dt.datetime | None = None,
) -> dict[str, str]:
    """Resolve as tentativas `pending` que ficaram para trás, sem fechar nenhuma ainda ativa.

    Por tentativa, devolve o que foi feito: `concluida` (o *job* terminou e a
    fase 2 rodou com o "antes" gravado), `abandonada` (sem *job* depois da
    carência), `ativa` (*job* ainda em curso, ou sem *job* dentro da carência)
    ou `sem_observador` (tem *job*, e ninguém para dizer se ele terminou).

    Antes de 15/09/2026 toda pendente com *job* era concluída na hora, e uma
    retomada durante a sincronização fechava o bruto parcial como `incomplete`
    e retirava a tentativa da recuperação (RV10-03).
    """
    agora = agora or dt.datetime.now(dt.timezone.utc)
    feito: dict[str, str] = {}
    for pendente, job_id, inicio in _pendentes(armazem):
        if job_id is None:
            if agora - inicio >= CARENCIA_SEM_JOB:
                _marcar(armazem, pendente, ABANDONED)
                feito[pendente] = "abandonada"
            else:
                feito[pendente] = "ativa"
        elif estado_do_job is None:
            feito[pendente] = "sem_observador"
        elif estado_do_job(int(job_id)) in JOB_TERMINADO:
            concluir(legado, armazem, pendente)
            feito[pendente] = "concluida"
        else:
            feito[pendente] = "ativa"
    return feito


# ── Fase 2 ───────────────────────────────────────────────────────────────────

def concluir(legado: Engine, armazem: Engine, tentativa: str) -> dict[str, Any]:
    """Fecha a tentativa: mede a origem de novo e o bruto do *job*, decide por tabela.

    Recuperável: usa o "antes" **gravado** na fase 1, nunca remedido. Tentativa
    sem `job_id` não é certificável e vira `abandoned`. Tentativa já fechada
    devolve o certificado **gravado**, sem remedir nada — remedir a origem
    depois de uma alteração legítima transformaria um `complete` histórico em
    `unstable` e mudaria a memória que a detecção de exclusão física usa
    (RV10-02).
    """
    with armazem.connect() as conexao:
        linhas = conexao.execute(
            text(
                f"select source_table, job_id, source_rows_before, source_hash_before, status, snapshot_id "
                f"from {TABELA} where capture_attempt_id = :a"
            ),
            {"a": tentativa},
        ).all()
    if not linhas:
        raise ValueError(f"tentativa {tentativa} não existe; a fase 1 não aconteceu")
    if all(status != PENDING for *_, status, _g in linhas):
        return _certificado(tentativa, linhas[0][1], {t: s for t, _, _, _, s, _ in linhas}, linhas[0][5])
    job_id = linhas[0][1]
    if job_id is None:
        _marcar(armazem, tentativa, ABANDONED)
        return _certificado(tentativa, None, {}, None)

    antes = {t: Medida(n, h) for t, _, n, h, _, _ in linhas}
    depois = medir_origem(legado)
    recebido = medir_recebido(armazem, job_id)
    vereditos = {t: decidir(antes[t], depois[t], recebido[t]) for t in schema.tabelas()}
    # A identidade da captura é o **job** (`schema.CAPTURA_SQL`): a geração do
    # Airbyte é por stream, e a captura F do plano mostrou as quarenta
    # desalinhadas depois de um stream reabilitado. Todas as 40 linhas do
    # certificado carregam o job como `snapshot_id` — é o que permite ao dbt
    # agrupar e exigir 40 `complete`. Job que não escreveu linha nenhuma em
    # tabela nenhuma não é captura.
    snapshot_id = int(job_id) if any(r.geracoes for r in recebido.values()) else None
    _publicar(armazem, tentativa, depois, recebido, vereditos, snapshot_id)
    return _certificado(tentativa, job_id, vereditos, snapshot_id)


def _publicar(
    armazem: Engine,
    tentativa: str,
    depois: dict[str, Medida],
    recebido: dict[str, Recebido],
    vereditos: dict[str, str],
    snapshot_id: int | None,
) -> None:
    """As 40 linhas, veredito e identidade, numa transação só — ou nada."""
    agora = dt.datetime.now(dt.timezone.utc)
    with armazem.begin() as conexao:
        for tabela, veredito in vereditos.items():
            conexao.execute(
                text(
                    f"""
                    update {TABELA}
                       set source_rows_after = :na, source_hash_after = :ha,
                           received_rows = :nr, received_hash = :hr,
                           sync_id_matches = :m, status = :s, completed_at = :quando,
                           snapshot_id = :g
                     where capture_attempt_id = :a and source_table = :t and status = '{PENDING}'
                    """
                ),
                {"na": depois[tabela].linhas, "ha": depois[tabela].hash,
                 "nr": recebido[tabela].linhas, "hr": recebido[tabela].hash,
                 "m": recebido[tabela].intrusas == 0 and len(recebido[tabela].geracoes) <= 1,
                 "s": veredito, "quando": agora, "g": snapshot_id,
                 "a": tentativa, "t": tabela},
            )


def _certificado(tentativa: str, job_id: int | None, vereditos: dict[str, str], snapshot_id: int | None) -> dict[str, Any]:
    estados = set(vereditos.values())
    status = ABANDONED if not vereditos or estados == {ABANDONED} else _pior(estados)
    return {"capture_attempt_id": tentativa, "job_id": None if job_id is None else int(job_id),
            "snapshot_id": snapshot_id if status == COMPLETE else None,
            "status": status, "tabelas": vereditos}


def _pior(estados: set[str]) -> str:
    for estado in (INCONSISTENT, UNSTABLE, INCOMPLETE):
        if estado in estados:
            return estado
    return COMPLETE


def _pendentes(armazem: Engine) -> list[tuple[str, int | None, dt.datetime]]:
    with armazem.connect() as conexao:
        return [
            (a, j, inicio)
            for a, j, inicio in conexao.execute(
                text(
                    f"select capture_attempt_id, min(job_id), min(started_at) from {TABELA} "
                    f"where status = '{PENDING}' group by capture_attempt_id order by 3"
                )
            )
        ]


def _marcar(armazem: Engine, tentativa: str, status: str) -> None:
    with armazem.begin() as conexao:
        conexao.execute(
            text(f"update {TABELA} set status = :s, completed_at = now() where capture_attempt_id = :a"),
            {"s": status, "a": tentativa},
        )


def certificadas(armazem: Engine) -> list[int]:
    """`snapshot_id` das capturas com certificado `complete` nas 40 tabelas, em ordem."""
    with armazem.connect() as conexao:
        return [
            int(g)
            for (g,) in conexao.execute(
                text(
                    f"select snapshot_id from {TABELA} "
                    f"where status = '{COMPLETE}' and snapshot_id is not null "
                    "group by snapshot_id having count(distinct source_table) = :n order by 1"
                ),
                {"n": len(schema.tabelas())},
            )
        ]
