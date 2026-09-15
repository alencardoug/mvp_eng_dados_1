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
`(capture_attempt_id, source_table)`: reenviar produz o mesmo estado.
"""

from __future__ import annotations

import datetime as dt
import uuid
from dataclasses import dataclass
from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1 import governance
from mvp_ed1.legacy import conteudo, schema

RAW = "raw_legacy"
TABELA = f"{governance.SCHEMA}.legacy_captures"

PENDING, COMPLETE, UNSTABLE, INCOMPLETE, INCONSISTENT, ABANDONED = (
    "pending", "complete", "unstable", "incomplete", "inconsistent", "abandoned",
)


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

def iniciar(legado: Engine, armazem: Engine, conexao_airbyte: str) -> str:
    """Mede a origem e abre a tentativa como `pending`. Devolve o `capture_attempt_id`.

    Antes de abrir a sua, resolve as tentativas pendentes que ficaram para trás:
    com `job_id`, tenta concluí-las a partir do "antes" já gravado; sem `job_id`,
    marca `abandoned`. Nenhuma é reaproveitada em silêncio.
    """
    governance.garantir(armazem)
    for pendente, job_id in _pendentes(armazem):
        if job_id is None:
            _marcar(armazem, pendente, ABANDONED)
        else:
            concluir(legado, armazem, pendente)

    tentativa = uuid.uuid4().hex
    agora = dt.datetime.now(dt.timezone.utc)
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


# ── Fase 2 ───────────────────────────────────────────────────────────────────

def concluir(legado: Engine, armazem: Engine, tentativa: str) -> dict[str, Any]:
    """Fecha a tentativa: mede a origem de novo e o bruto do *job*, decide por tabela.

    Recuperável: usa o "antes" **gravado** na fase 1, nunca remedido. Tentativa
    sem `job_id` não é certificável e vira `abandoned`.
    """
    with armazem.connect() as conexao:
        linhas = conexao.execute(
            text(
                f"select source_table, job_id, source_rows_before, source_hash_before "
                f"from {TABELA} where capture_attempt_id = :a"
            ),
            {"a": tentativa},
        ).all()
    if not linhas:
        raise ValueError(f"tentativa {tentativa} não existe; a fase 1 não aconteceu")
    job_id = linhas[0][1]
    if job_id is None:
        _marcar(armazem, tentativa, ABANDONED)
        return {"capture_attempt_id": tentativa, "job_id": None, "snapshot_id": None,
                "status": ABANDONED, "tabelas": {}}

    antes = {t: Medida(n, h) for t, _, n, h in linhas}
    depois = medir_origem(legado)
    recebido = medir_recebido(armazem, job_id)
    agora = dt.datetime.now(dt.timezone.utc)
    vereditos: dict[str, str] = {}
    geracoes: set[int] = set()
    with armazem.begin() as conexao:
        for tabela in schema.tabelas():
            veredito = decidir(antes[tabela], depois[tabela], recebido[tabela])
            vereditos[tabela] = veredito
            geracoes.update(recebido[tabela].geracoes)
            conexao.execute(
                text(
                    f"""
                    update {TABELA}
                       set source_rows_after = :na, source_hash_after = :ha,
                           received_rows = :nr, received_hash = :hr,
                           sync_id_matches = :m, status = :s, completed_at = :quando,
                           snapshot_id = :g
                     where capture_attempt_id = :a and source_table = :t
                    """
                ),
                {"na": depois[tabela].linhas, "ha": depois[tabela].hash,
                 "nr": recebido[tabela].linhas, "hr": recebido[tabela].hash,
                 "m": recebido[tabela].intrusas == 0 and len(recebido[tabela].geracoes) <= 1,
                 "s": veredito, "quando": agora,
                 "g": None,
                 "a": tentativa, "t": tabela},
            )
    todas = set(vereditos.values())
    status = COMPLETE if todas == {COMPLETE} else _pior(todas)
    # A identidade da captura é o **job** (`schema.CAPTURA_SQL`): a geração do
    # Airbyte é por stream, e a captura F do plano mostrou as quarenta
    # desalinhadas depois de um stream reabilitado. Todas as 40 linhas do
    # certificado carregam o job como `snapshot_id` — é o que permite ao dbt
    # agrupar e exigir 40 `complete`. Job que não escreveu linha nenhuma em
    # tabela nenhuma não é captura.
    snapshot_id = int(job_id) if geracoes else None
    with armazem.begin() as conexao:
        conexao.execute(
            text(f"update {TABELA} set snapshot_id = :g where capture_attempt_id = :a"),
            {"g": snapshot_id, "a": tentativa},
        )
    return {"capture_attempt_id": tentativa, "job_id": int(job_id),
            "snapshot_id": snapshot_id if status == COMPLETE else None,
            "status": status, "tabelas": vereditos}


def _pior(estados: set[str]) -> str:
    for estado in (INCONSISTENT, UNSTABLE, INCOMPLETE):
        if estado in estados:
            return estado
    return COMPLETE


def _pendentes(armazem: Engine) -> list[tuple[str, int | None]]:
    with armazem.connect() as conexao:
        return [
            (a, j)
            for a, j in conexao.execute(
                text(
                    f"select capture_attempt_id, min(job_id) from {TABELA} "
                    f"where status = '{PENDING}' group by capture_attempt_id"
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
                    f"select snapshot_id from {TABELA} where status = '{COMPLETE}' "
                    "group by snapshot_id having count(distinct source_table) = :n order by 1"
                ),
                {"n": len(schema.tabelas())},
            )
        ]
