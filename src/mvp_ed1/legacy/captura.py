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
pela mesma função, ambos depois da fase de recuperação (H7 da v1.1.0). A fase 1
**insere** — um id repetido falha, nunca se sobrescreve —; a fase 2 só escreve
em linha `pending`: reenviá-la produz o mesmo estado, e uma tentativa já
fechada **não é remedida** — o reenvio devolve o que está gravado.

A fase 2 publica veredito e identidade (`snapshot_id`) das 40 tabelas numa
única transação. Até 15/09/2026 eram duas, e uma interrupção entre elas deixava
40 linhas `complete` sem identidade — que a recuperação não via e que faziam
`certificadas` falhar (achado RV10-01).

**Os dois armazéns (Etapa 13, G2.1).** `armazem` é um `Engine` do PostgreSQL —
armazém e coordenador dos *locks* no mesmo banco, a fase local — ou um
`armazem.BigQuery`, que leva o certificado e o bruto para o BigQuery e os
*locks* para o Cloud SQL das origens. Cada garantia, e onde ela mora em cada
um, está no contrato do G2.1 (`PLANO_etapa_13.md`); o que muda aqui é só o
meio, nunca a regra.
"""

from __future__ import annotations

import datetime as dt
import uuid
from collections.abc import Collection, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Callable

from sqlalchemy import Connection, Engine, text

from mvp_ed1 import governance
from mvp_ed1.airbyte import CONCLUIDOS as JOB_TERMINADO
from mvp_ed1.legacy import conteudo, schema
from mvp_ed1.legacy.armazem import BigQuery, ErroDoJob, Struct, coordenador, lock_de_sessao

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

#: O espaço dos *advisory locks* do protocolo de captura, e o do lock de cada
#: tentativa nele (runbook da regeneração da v1.1.0, H7, RR-39).
LOCK_DA_TENTATIVA = 7101


def _t(armazem: Engine | BigQuery) -> str:
    """O nome do certificado no armazém dado."""
    return armazem.tabela(TABELA) if isinstance(armazem, BigQuery) else TABELA


def _ler(armazem: Engine | BigQuery, sql: str, parametros: dict[str, Any] | None = None) -> list[tuple]:
    """Linhas como tuplas, na ordem do `select` — nos dois armazéns."""
    if isinstance(armazem, BigQuery):
        return [tuple(linha.values()) for linha in armazem.linhas(sql, parametros)]
    with armazem.connect() as conexao:
        return [tuple(linha) for linha in conexao.execute(text(sql), parametros or {})]


def _escrever(armazem: Engine | BigQuery, sql: str, parametros: dict[str, Any], *, rotulo: str) -> int:
    """Uma instrução que muda o certificado; devolve as linhas afetadas (no BigQuery, as do *job*)."""
    if isinstance(armazem, BigQuery):
        return armazem.dml(sql, parametros, rotulo=rotulo)
    with armazem.begin() as conexao:
        return conexao.execute(text(sql), parametros).rowcount


class TentativaOcupada(Exception):
    """O lock da tentativa está com outro processo vivo — um chamador ativo."""


@contextmanager
def bloqueio_da_tentativa(armazem: Engine, tentativa: str, *, esperar: bool = True) -> Iterator[None]:
    """O lock de sessão da tentativa, numa conexão só dele, que morre com o processo.

    Quem o segura é um chamador vivo: a fase de recuperação não abandona uma
    tentativa cujo lock está tomado, por mais velha que seja (H7). `esperar`
    falso recusa na hora em vez de esperar. A conexão é descartada no fim, e
    não devolvida ao *pool*: um lock de sessão esquecido nela seguiria vivo.
    No GCP o lock mora no coordenador (o Cloud SQL), não no BigQuery.
    """
    conexao = coordenador(armazem).connect()
    try:
        chave = {"ns": LOCK_DA_TENTATIVA, "a": tentativa}
        if esperar:
            conexao.execute(text("select pg_advisory_lock(:ns, hashtext(:a))"), chave)
        elif not conexao.execute(text("select pg_try_advisory_lock(:ns, hashtext(:a))"), chave).scalar_one():
            raise TentativaOcupada(f"tentativa {tentativa}: o lock está com outro processo")
        conexao.commit()
        yield
    finally:
        conexao.invalidate()
        conexao.close()


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


def medir_recebido(armazem: Engine | BigQuery, job_id: int) -> dict[str, Recebido]:
    """Por tabela, o que carrega o `sync_id` do *job* — e o que há de intruso na geração dele."""
    if isinstance(armazem, BigQuery):
        return _medir_recebido_bigquery(armazem, job_id)
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


def _medir_recebido_bigquery(armazem: BigQuery, job_id: int) -> dict[str, Recebido]:
    """As mesmas três leituras de `medir_recebido`, no BigQuery; o *hash* continua em Python."""
    saida: dict[str, Recebido] = {}
    filtro = f"{armazem.sync_id()} = :j"
    for tabela in schema.tabelas():
        bruto = armazem.do_bruto(RAW, tabela)
        medida = conteudo.hash_no_bigquery(armazem, RAW, tabela, filtro, {"j": str(job_id)})
        geracoes = tuple(int(linha["g"]) for linha in armazem.linhas(
            f"select distinct _airbyte_generation_id as g from {bruto} where {filtro} order by 1",
            {"j": str(job_id)},
        ))
        intrusas = 0
        if geracoes:
            intrusas = armazem.escalar(
                f"select count(*) from {bruto} where _airbyte_generation_id in unnest(:gs) "
                f"and coalesce({armazem.sync_id()}, '') <> :j",
                {"gs": list(geracoes), "j": str(job_id)},
            )
        saida[tabela] = Recebido(medida["linhas"], medida["hash"], geracoes, int(intrusas))
    return saida


# ── Fase 1 ───────────────────────────────────────────────────────────────────

#: O lock de abertura (RR-37): uma chave só, a mesma para os dois chamadores,
#: tomada na transação do *insert* — a decisão de abrir é a própria barreira.
#: Espaço próprio: no da tentativa, o `hashtext` de algum id poderia dar a mesma chave.
LOCK_DE_ABERTURA = (7102, 0)

#: A barreira que `iniciar` roda dentro do lock de abertura: recebe a conexão
#: da transação do *insert* (no BigQuery, o próprio armazém) e devolve o que
#: impede a abertura — vazio, abre.
Barreira = Callable[[Connection | BigQuery], list[str]]


class AberturaRecusada(Exception):
    """A barreira achou o que impede abrir a tentativa: nada foi aberto, nenhum *job* disparado."""

    def __init__(self, problemas: list[str]) -> None:
        super().__init__("abertura recusada pela barreira:\n  " + "\n  ".join(problemas))
        self.problemas = problemas


def iniciar(
    legado: Engine,
    armazem: Engine,
    conexao_airbyte: str,
    *,
    barreira: Barreira,
    tentativa: str | None = None,
    agora: dt.datetime | None = None,
) -> str:
    """Mede a origem e abre a tentativa como `pending`. Devolve o `capture_attempt_id`.

    **Não finaliza tentativa nenhuma** (H7 da regeneração da v1.1.0, N30): até
    04/11/2026 `iniciar` chamava `retomar`, e a transição de uma tentativa
    anterior acontecia sem registro, antes de a nova existir. Quem resolve as
    pendentes agora é a fase de recuperação (`recovery.capture_recovery`), que
    os dois chamadores rodam antes, registrando cada transição.

    **A abertura é a barreira** (RR-37): a transação do *insert* toma o lock de
    abertura — esperando, não falhando —, roda `barreira` dentro dele e só
    insere se ela não achar nada. Como a linha nova se confirma junto com o
    lock, todo chamador seguinte encontra esta tentativa `pending`, e depois
    final sem registro até o portão dela publicar: nenhuma segunda abertura
    cabe entre a primeira e o registro dela.

    `tentativa` é o id que o chamador já sorteou para tomar o lock da tentativa
    antes de o *insert* confirmar (H7); sem ele, sorteia-se aqui. O *insert*
    não é *upsert*: um id que já existe é um campo imutável trocado, e falha.

    No BigQuery (`_iniciar_bigquery`) a transação não envolve o *job*: o lock
    de abertura vira **de sessão**, no coordenador, e só sai depois de o *job*
    que grava as 40 linhas ter terminado — a mesma garantia, por outro meio.
    """
    if isinstance(armazem, BigQuery):
        return _iniciar_bigquery(legado, armazem, conexao_airbyte, barreira=barreira,
                                 tentativa=tentativa, agora=agora)
    governance.garantir(armazem)
    agora = agora or dt.datetime.now(dt.timezone.utc)
    tentativa = tentativa or uuid.uuid4().hex
    origem = medir_origem(legado)
    with armazem.begin() as conexao:
        conexao.execute(text("select pg_advisory_xact_lock(:ns, :k)"),
                        {"ns": LOCK_DE_ABERTURA[0], "k": LOCK_DE_ABERTURA[1]})
        problemas = barreira(conexao)
        if problemas:
            raise AberturaRecusada(problemas)
        for tabela, medida in origem.items():
            conexao.execute(
                text(
                    f"""
                    insert into {TABELA}
                        (capture_attempt_id, source_table, connection_name, source_rows_before,
                         source_hash_before, status, started_at)
                    values (:a, :t, :c, :n, :h, :s, :quando)
                    """
                ),
                {"a": tentativa, "t": tabela, "c": conexao_airbyte, "n": medida.linhas,
                 "h": medida.hash, "s": PENDING, "quando": agora},
            )
    return tentativa


class IdRepetido(Exception):
    """A tentativa já existe no certificado: um id repetido falha, nunca se sobrescreve."""


def _iniciar_bigquery(
    legado: Engine,
    armazem: BigQuery,
    conexao_airbyte: str,
    *,
    barreira: Barreira,
    tentativa: str | None,
    agora: dt.datetime | None,
) -> str:
    """`iniciar` no BigQuery: lock de abertura de sessão no Cloud SQL, barreira, um `MERGE` só.

    O `MERGE` insere as 40 linhas **só se** a tentativa não existir — tudo ou
    nada, numa instrução: um id repetido grava zero, e falha como o *insert*
    do PostgreSQL. O DDL não roda aqui: no GCP é `governance.garantir_bigquery`,
    na preparação do ambiente (época inicial), e não um *job* a mais por captura.
    """
    agora = agora or dt.datetime.now(dt.timezone.utc)
    tentativa = tentativa or uuid.uuid4().hex
    origem = medir_origem(legado)
    linhas = [
        Struct({"t": ("STRING", tabela), "n": ("INT64", medida.linhas), "h": ("STRING", medida.hash)})
        for tabela, medida in origem.items()
    ]
    with lock_de_sessao(coordenador(armazem), LOCK_DE_ABERTURA[0], ":k", {"k": LOCK_DE_ABERTURA[1]}):
        problemas = barreira(armazem)
        if problemas:
            raise AberturaRecusada(problemas)
        gravadas = armazem.dml(
            f"""
            merge {_t(armazem)} c
            using (
                select n.* from unnest(:linhas) n
                where not exists (select 1 from {_t(armazem)} where capture_attempt_id = :a)
            ) n
            on false
            when not matched then insert
                (capture_attempt_id, source_table, connection_name, source_rows_before,
                 source_hash_before, status, started_at)
            values (:a, n.t, :c, n.n, n.h, '{PENDING}', :quando)
            """,
            {"linhas": linhas, "a": tentativa, "c": conexao_airbyte, "quando": agora},
            rotulo="abertura",
        )
        # O lock sai só aqui, com o job terminado: a próxima abertura já vê as 40 linhas.
        if gravadas != len(origem):
            raise IdRepetido(f"tentativa {tentativa}: {gravadas} de {len(origem)} linhas gravadas — "
                             "o id já existe no certificado")
    return tentativa


def conferir_antes_do_disparo(armazem: Engine | BigQuery, tentativa: str) -> None:
    """Antes do `POST` que cria o *job*, segurando o lock da tentativa: ela ainda é `pending` sem *job*.

    Um chamador atrasado além da carência encontra a tentativa abandonada pela
    recuperação e não cria *job* nenhum (RR-39). Levanta `TentativaIndisponivel`.
    """
    ((linhas,),) = _ler(armazem, f"select count(*) from {_t(armazem)} where capture_attempt_id = :a "
                                 f"and status = '{PENDING}' and job_id is null", {"a": tentativa})
    if linhas != len(schema.tabelas()):
        raise TentativaIndisponivel(
            f"tentativa {tentativa} não está mais pendente sem job ({linhas} de {len(schema.tabelas())} "
            "linhas): a recuperação a resolveu — nenhum job é criado; abra outra fase 1"
        )


class TentativaIndisponivel(Exception):
    """A tentativa já está fechada, ou já pertence a outro *job*: precisa de fase 1 própria."""


def registrar_job(armazem: Engine | BigQuery, tentativa: str, job_id: int) -> None:
    """Grava o `job_id` assim que o *job* nasce — antes de esperar por ele.

    Idempotente para o **mesmo** *job*; recusa outro *job* numa tentativa já
    associada ou já fechada. Sem a guarda, reexecutar a sincronização com a
    mesma tentativa misturava duas capturas — `complete` para o *job* novo com
    o `snapshot_id` do antigo (RV10-2-03). Uma sincronização nova exige a sua
    própria fase 1.

    No BigQuery, um conflito de DML concorrente é erro do *job* — ele não
    gravou nada —, e o que vale é relido: as linhas que já têm este *job*.
    """
    parametros = {"j": int(job_id), "a": tentativa}
    try:
        gravadas = _escrever(
            armazem,
            f"update {_t(armazem)} set job_id = :j where capture_attempt_id = :a "
            f"and ((job_id is null and status = '{PENDING}') or job_id = :j)",
            parametros, rotulo="registro_do_job",
        )
    except ErroDoJob:
        ((gravadas,),) = _ler(armazem, f"select count(*) from {_t(armazem)} "
                                       "where capture_attempt_id = :a and job_id = :j", parametros)
    if gravadas != len(schema.tabelas()):
        raise TentativaIndisponivel(
            f"tentativa {tentativa} não aceita o job {job_id}: já fechada ou associada a outro job "
            f"({gravadas} de {len(schema.tabelas())} linhas pendentes sem outro job); abra outra fase 1"
        )


def retomar(
    legado: Engine,
    armazem: Engine | BigQuery,
    *,
    estado_do_job: EstadoDoJob | None = None,
    agora: dt.datetime | None = None,
    apenas: Collection[str] | None = None,
) -> dict[str, str]:
    """Resolve as tentativas `pending` que ficaram para trás, sem fechar nenhuma ainda ativa.

    Por tentativa, devolve o que foi feito: `concluida` (o *job* terminou e a
    fase 2 rodou com o "antes" gravado), `abandonada` (sem *job* depois da
    carência), `ativa` (*job* ainda em curso, ou sem *job* dentro da carência)
    ou `sem_observador` (tem *job*, e ninguém para dizer se ele terminou).
    `apenas` restringe às tentativas dadas — o que a fase de recuperação usa.

    Antes de 15/09/2026 toda pendente com *job* era concluída na hora, e uma
    retomada durante a sincronização fechava o bruto parcial como `incomplete`
    e retirava a tentativa da recuperação (RV10-03).
    """
    agora = agora or dt.datetime.now(dt.timezone.utc)
    feito: dict[str, str] = {}
    for pendente, job_id, inicio in _pendentes(armazem):
        # A fase de recuperação passa só as tentativas que acabou de registrar
        # (H7, passo 2): uma que mudou de estado no meio-tempo fica de fora.
        if apenas is not None and pendente not in apenas:
            continue
        if job_id is None:
            # A lista acima pode estar velha: outro chamador pode ter registrado
            # o job ou concluído entre a leitura e esta escrita. O abandono só
            # vale se, **no instante da escrita**, as 40 linhas ainda estiverem
            # pendentes, sem job e fora da carência (RV10-2-01).
            if agora - inicio >= CARENCIA_SEM_JOB and _abandonar(armazem, pendente, agora - CARENCIA_SEM_JOB):
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

def concluir(legado: Engine, armazem: Engine | BigQuery, tentativa: str) -> dict[str, Any]:
    """Fecha a tentativa: mede a origem de novo e o bruto do *job*, decide por tabela.

    Recuperável: usa o "antes" **gravado** na fase 1, nunca remedido. Tentativa
    sem `job_id` não é certificável e vira `abandoned`. Tentativa já fechada
    devolve o certificado **gravado**, sem remedir nada — remedir a origem
    depois de uma alteração legítima transformaria um `complete` histórico em
    `unstable` e mudaria a memória que a detecção de exclusão física usa
    (RV10-02).
    """
    linhas = _ler(
        armazem,
        f"select source_table, job_id, source_rows_before, source_hash_before, status, snapshot_id "
        f"from {_t(armazem)} where capture_attempt_id = :a",
        {"a": tentativa},
    )
    if not linhas:
        raise ValueError(f"tentativa {tentativa} não existe; a fase 1 não aconteceu")
    if all(status != PENDING for *_, status, _g in linhas):
        return _certificado(tentativa, linhas[0][1], {t: s for t, _, _, _, s, _ in linhas}, linhas[0][5])
    job_id = linhas[0][1]
    if job_id is None:
        # Sem carência: quem chama `concluir` numa tentativa sem job está na
        # fase 2 do próprio fluxo, e sabe que o job não nasceu.
        _abandonar(armazem, tentativa, dt.datetime.max.replace(tzinfo=dt.timezone.utc))
        return _gravado(armazem, tentativa)

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
    # O que se devolve é o que **ficou gravado**, não o que este chamador
    # calculou: se outro chamador publicou primeiro, a guarda `pending` fez
    # esta publicação escrever zero linhas, e o certificado dele é o que a
    # elegibilidade vai ler (RV10-2-02).
    return _gravado(armazem, tentativa)


def _publicar(
    armazem: Engine | BigQuery,
    tentativa: str,
    depois: dict[str, Medida],
    recebido: dict[str, Recebido],
    vereditos: dict[str, str],
    snapshot_id: int | None,
) -> None:
    """As 40 linhas, veredito e identidade, numa transação só — ou nada.

    No BigQuery é **uma** instrução — `update … from unnest(...)` —, atômica
    por si; a guarda `pending` vai no `where`, como aqui. Erro do *job* não
    gravou nada: `_gravado`, depois, diz o que vale.
    """
    agora = dt.datetime.now(dt.timezone.utc)
    if isinstance(armazem, BigQuery):
        _publicar_bigquery(armazem, tentativa, depois, recebido, vereditos, snapshot_id, agora)
        return
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


def _publicar_bigquery(
    armazem: BigQuery,
    tentativa: str,
    depois: dict[str, Medida],
    recebido: dict[str, Recebido],
    vereditos: dict[str, str],
    snapshot_id: int | None,
    agora: dt.datetime,
) -> None:
    valores = [
        Struct({
            "t": ("STRING", tabela),
            "na": ("INT64", depois[tabela].linhas), "ha": ("STRING", depois[tabela].hash),
            "nr": ("INT64", recebido[tabela].linhas), "hr": ("STRING", recebido[tabela].hash),
            "m": ("BOOL", recebido[tabela].intrusas == 0 and len(recebido[tabela].geracoes) <= 1),
            "s": ("STRING", veredito),
        })
        for tabela, veredito in vereditos.items()
    ]
    try:
        armazem.dml(
            f"""
            update {_t(armazem)} c
               set source_rows_after = v.na, source_hash_after = v.ha,
                   received_rows = v.nr, received_hash = v.hr,
                   sync_id_matches = v.m, status = v.s, completed_at = :quando,
                   snapshot_id = :g
              from unnest(:v) v
             where c.capture_attempt_id = :a and c.source_table = v.t and c.status = '{PENDING}'
            """,
            {"v": valores, "quando": agora, "g": ("INT64", snapshot_id), "a": tentativa},
            rotulo="publicacao",
        )
    except ErroDoJob:
        # O job não gravou nada. Se foi outro chamador publicando ao mesmo tempo, a tentativa
        # já não está pendente, e o certificado dele é o que vale; senão, o erro é deste.
        if _ainda_pendente(armazem, tentativa):
            raise


def _ainda_pendente(armazem: Engine | BigQuery, tentativa: str) -> bool:
    ((n,),) = _ler(armazem, f"select count(*) from {_t(armazem)} where capture_attempt_id = :a "
                            f"and status = '{PENDING}'", {"a": tentativa})
    return bool(n)


def _gravado(armazem: Engine | BigQuery, tentativa: str) -> dict[str, Any]:
    """O certificado como está no banco — a única fonte que a elegibilidade lê."""
    linhas = _ler(armazem, f"select source_table, job_id, status, snapshot_id from {_t(armazem)} "
                           "where capture_attempt_id = :a", {"a": tentativa})
    return _certificado(tentativa, linhas[0][1], {t: s for t, _, s, _ in linhas}, linhas[0][3])


def _certificado(tentativa: str, job_id: int | None, vereditos: dict[str, str], snapshot_id: int | None) -> dict[str, Any]:
    estados = set(vereditos.values())
    status = ABANDONED if not vereditos or estados == {ABANDONED} else _pior(estados)
    return {"capture_attempt_id": tentativa, "job_id": None if job_id is None else int(job_id),
            "snapshot_id": snapshot_id if status == COMPLETE else None,
            "status": status, "tabelas": vereditos}


def _pior(estados: set[str]) -> str:
    for estado in (INCONSISTENT, UNSTABLE, INCOMPLETE, PENDING):
        if estado in estados:
            return estado
    return COMPLETE


def _pendentes(armazem: Engine | BigQuery) -> list[tuple[str, int | None, dt.datetime]]:
    return [
        (a, j, inicio)
        for a, j, inicio in _ler(
            armazem,
            f"select capture_attempt_id, min(job_id), min(started_at) from {_t(armazem)} "
            f"where status = '{PENDING}' group by capture_attempt_id order by 3",
        )
    ]


def _abandonar(armazem: Engine | BigQuery, tentativa: str, iniciada_ate: dt.datetime) -> bool:
    """`abandoned` nas 40 linhas — só se todas ainda estiverem pendentes, sem job e antigas o bastante.

    A condição é revalidada **no `UPDATE`**, não na lista lida antes: é o que
    impede o abandono de sobrescrever uma tentativa que ganhou job ou foi
    concluída no meio-tempo. Devolve se abandonou.
    """
    agora = "current_timestamp()" if isinstance(armazem, BigQuery) else "now()"
    try:
        gravadas = _escrever(
            armazem,
            f"update {_t(armazem)} set status = '{ABANDONED}', completed_at = {agora} "
            f"where capture_attempt_id = :a and status = '{PENDING}' and job_id is null "
            f"and started_at <= :limite",
            {"a": tentativa, "limite": iniciada_ate}, rotulo="abandono",
        )
    except ErroDoJob:
        # Não gravou nada: só é "não abandonou" se alguém mudou a tentativa no meio-tempo.
        if _ainda_pendente(armazem, tentativa):
            raise
        return False
    return gravadas == len(schema.tabelas())


def certificadas(armazem: Engine | BigQuery) -> list[int]:
    """`snapshot_id` das capturas com certificado `complete` nas 40 tabelas, em ordem."""
    return [
        int(g)
        for (g,) in _ler(
            armazem,
            f"select snapshot_id from {_t(armazem)} "
            f"where status = '{COMPLETE}' and snapshot_id is not null "
            "group by snapshot_id having count(distinct source_table) = :n order by 1",
            {"n": len(schema.tabelas())},
        )
    ]
