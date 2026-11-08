"""O armazém do certificado e do bruto no BigQuery, e o coordenador dos locks (Etapa 13, G2.1).

Na fase local, armazém e coordenador são o mesmo PostgreSQL, e quem chama passa
um `Engine` — nada muda. Na fase GCP são dois: o certificado e o bruto moram no
BigQuery, e os *locks* — que o BigQuery não tem — no Cloud SQL das origens, que é
PostgreSQL. `BigQuery` carrega os dois, e as funções da captura, da recuperação e
do livro perguntam a ele onde cada garantia mora
([contrato do G2.1](../../../PLANO_etapa_13.md)).

O que este módulo garante sobre cada instrução que muda o certificado (DML):

* **o resultado é o do *job*, não o da resposta.** Cada DML nasce com um
  `job_id` sorteado aqui; se a resposta se perde — erro de transporte, tempo
  esgotado —, o *job* é procurado pelo id e esperado até terminar, e o número de
  linhas afetadas é lido dele. A instrução **não é reenviada**: um reenvio de
  uma instrução já aplicada gravaria zero linhas e pareceria recusa.
* **erro do *job* é "não gravou".** Conflito de DML concorrente no BigQuery é
  erro do *job* inteiro (nenhuma linha muda); `ErroDoJob` sobe, e quem chama
  relê o certificado para saber o que vale.
"""

from __future__ import annotations

import datetime as dt
import re
import time
import uuid
from collections.abc import Iterator, Mapping, Sequence
from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy import Engine

#: Quanto se espera por um *job* cuja resposta se perdeu, antes de desistir.
ESPERA_DO_JOB = dt.timedelta(minutes=10)

def _perdas() -> tuple[type[BaseException], ...]:
    """Erros em que a requisição pode ter chegado e o *job* existir: transporte, tempo, 5xx.

    `OSError` cobre `ConnectionError`, `TimeoutError` e os erros do `requests`.
    """
    import concurrent.futures

    from google.api_core import exceptions as gexc

    return (OSError, concurrent.futures.TimeoutError, gexc.ServerError, gexc.RetryError)


class ErroDoJob(Exception):
    """O *job* terminou com erro: nada do que ele faria foi gravado."""


class JobPerdido(Exception):
    """A resposta se perdeu e o *job* não foi achado nem terminou dentro da espera."""


@dataclass(frozen=True)
class Struct:
    """Uma linha de um parâmetro `ARRAY<STRUCT<…>>`: os campos e o tipo de cada um."""

    campos: Mapping[str, tuple[str, Any]]


@dataclass
class BigQuery:
    """O armazém no BigQuery (`cliente`, `projeto`) e o coordenador dos *locks* (`coordenador`)."""

    cliente: Any
    projeto: str
    coordenador: Engine
    #: A região dos *datasets* e dos *jobs* (`GCP_BQ_LOCATION`). Sem ela, procurar um *job* pelo
    #: id fora da multirregião US responde "não encontrado" — e a resposta perdida nunca se acharia.
    local: str | None = None
    #: *Dataset* trocado por outro — `{"governance": "captura_teste_…"}` nos testes; vazio em produção.
    renomear: Mapping[str, str] = field(default_factory=dict)
    #: Com instante, toda tabela é lida como estava nele (`for system_time as of`): o
    #: `REPEATABLE READ` do PostgreSQL, para leituras que precisam ser de um estado só.
    instante: dt.datetime | None = None
    #: O relógio e a pausa da espera pelo *job* perdido — trocáveis nos testes.
    relogio: Any = field(default=time.monotonic, repr=False)
    pausa: Any = field(default=time.sleep, repr=False)

    dialeto = "bigquery"

    # ── nomes e expressões ──────────────────────────────────────────────────
    def tabela(self, qualificada: str) -> str:
        """`governance.legacy_captures` → `` `projeto.governance.legacy_captures` ``."""
        esquema, tabela = qualificada.split(".")
        return self.do_bruto(esquema, tabela)

    def do_bruto(self, esquema: str, tabela: str) -> str:
        nome = f"`{self.projeto}.{self.renomear.get(esquema, esquema)}.{tabela}`"
        if self.instante is None:
            return nome
        return f"{nome} for system_time as of timestamp '{self.instante.isoformat()}'"

    def no_instante(self) -> "BigQuery":
        """Uma cópia que lê tudo no instante de agora — o do servidor, não o do relógio local."""
        from dataclasses import replace

        if self.instante is not None:
            return self
        agora = next(iter(self._consultar("select current_timestamp()", None, "instante").result()))[0]
        return replace(self, instante=agora)

    @staticmethod
    def sync_id() -> str:
        """O `sync_id` do *job* do Airbyte, como texto — o `_airbyte_meta->>'sync_id'` do PostgreSQL."""
        return "json_value(_airbyte_meta, '$.sync_id')"

    @staticmethod
    def coluna(nome: str) -> str:
        return f"`{nome}`"

    # ── leitura ─────────────────────────────────────────────────────────────
    def linhas(self, sql: str, parametros: Mapping[str, Any] | None = None, *,
               tempo_limite: float | None = None) -> list[dict[str, Any]]:
        """As linhas como dicionários. `tempo_limite` (segundos) é o da leitura, como o `statement_timeout`."""
        job = self._consultar(sql, parametros, "leitura", tempo_limite=tempo_limite)
        return [dict(linha.items()) for linha in job.result()]

    def escalar(self, sql: str, parametros: Mapping[str, Any] | None = None) -> Any:
        linhas = self.linhas(sql, parametros)
        return next(iter(linhas[0].values())) if linhas else None

    def tabelas_do_schema(self, esquema: str) -> list[str]:
        return sorted(t.table_id for t in self.cliente.list_tables(f"{self.projeto}.{esquema}")
                      if t.table_type == "TABLE")

    # ── escrita ─────────────────────────────────────────────────────────────
    def dml(self, sql: str, parametros: Mapping[str, Any] | None = None, *, rotulo: str) -> int:
        """Roda uma instrução DML e devolve as linhas afetadas **pelo *job***.

        Resposta perdida: procura o *job* pelo id e espera ele terminar; não reenvia.
        """
        job_id = f"mvp_{rotulo}_{uuid.uuid4().hex}"
        try:
            job = self._consultar(sql, parametros, rotulo, job_id=job_id)
            job.result()
        except _perdas():
            job = self._esperar(job_id)
        except Exception as erro:  # noqa: BLE001 — o erro do job é decidido abaixo, não aqui
            if getattr(erro, "code", None) in (409,):  # Conflict: o job com este id já existe
                job = self._esperar(job_id)
            elif _e_erro_do_job(erro):
                raise ErroDoJob(f"{rotulo}: {erro}") from erro
            else:
                raise
        if getattr(job, "error_result", None):
            raise ErroDoJob(f"{rotulo}: {job.error_result}")
        return int(job.num_dml_affected_rows or 0)

    def dispose(self) -> None:
        """Fecha o cliente; o coordenador é de quem o passou, e quem o criou o descarta."""
        self.cliente.close()

    def _esperar(self, job_id: str):
        from google.api_core import exceptions as gexc

        limite = self.relogio() + ESPERA_DO_JOB.total_seconds()
        while True:
            try:
                job = self.cliente.get_job(job_id, location=self.local)
            except (gexc.NotFound, *_perdas()):
                job = None
            if job is not None and job.state == "DONE":
                return job
            if self.relogio() >= limite:
                raise JobPerdido(f"job {job_id}: resposta perdida e o job não terminou em {ESPERA_DO_JOB}")
            self.pausa(2)

    def _consultar(self, sql: str, parametros: Mapping[str, Any] | None, rotulo: str, *,
                   job_id: str | None = None, tempo_limite: float | None = None):
        from google.cloud import bigquery

        if self.instante is not None and rotulo not in ("leitura", "instante"):
            raise RuntimeError("um armazém lido num instante não escreve: a escrita usa o armazém sem instante")
        configuracao = bigquery.QueryJobConfig(
            job_timeout_ms=None if tempo_limite is None else int(tempo_limite * 1000),
            query_parameters=[_parametro(nome, valor) for nome, valor in (parametros or {}).items()],
            labels={"mvp_operacao": re.sub(r"[^a-z0-9_-]", "_", rotulo.lower())[:63]},
        )
        if job_id is None:
            return self.cliente.query(_arrobas(sql), job_config=configuracao, location=self.local)
        # Com id fixo, o cliente não reenvia sozinho (`job_retry=None`): reenviar é o que a DML não pode.
        return self.cliente.query(_arrobas(sql), job_config=configuracao, job_id=job_id, job_retry=None,
                                  location=self.local)


def _e_erro_do_job(erro: BaseException) -> bool:
    """Erro que o BigQuery devolveu sobre a instrução (4xx/5xx com motivo), e não de transporte."""
    from google.api_core import exceptions as gexc

    return isinstance(erro, gexc.GoogleAPICallError)


#: `:nome` (o estilo do `sqlalchemy.text`) → `@nome`; `::` do PostgreSQL não casa.
_PARAMETRO = re.compile(r"(?<![:\w]):([A-Za-z_]\w*)")


def _arrobas(sql: str) -> str:
    return _PARAMETRO.sub(r"@\1", sql)


_TIPOS = ((bool, "BOOL"), (int, "INT64"), (str, "STRING"), (dt.datetime, "TIMESTAMP"))


def _tipo(valor: Any) -> str:
    for classe, tipo in _TIPOS:
        if isinstance(valor, classe):
            return tipo
    raise TypeError(f"parâmetro sem tipo do BigQuery: {valor!r} ({type(valor).__name__})")


def _parametro(nome: str, valor: Any):
    """O parâmetro tipado. `None` precisa vir como `(tipo, None)`; listas, de um tipo só."""
    from google.cloud import bigquery

    if isinstance(valor, tuple) and len(valor) == 2 and isinstance(valor[0], str):
        return bigquery.ScalarQueryParameter(nome, valor[0], valor[1])
    if isinstance(valor, Sequence) and not isinstance(valor, str):
        itens = list(valor)
        if itens and isinstance(itens[0], Struct):
            return bigquery.ArrayQueryParameter(nome, "STRUCT", [
                bigquery.StructQueryParameter(None, *(
                    bigquery.ScalarQueryParameter(campo, tipo, v) for campo, (tipo, v) in item.campos.items()
                )) for item in itens
            ])
        tipo = _tipo(itens[0]) if itens else "STRING"
        return bigquery.ArrayQueryParameter(nome, tipo, itens)
    return bigquery.ScalarQueryParameter(nome, _tipo(valor), valor)


# ── qual armazém ─────────────────────────────────────────────────────────────

#: A chave do `.env` que escolhe o armazém do legado: vazia ou `postgres`, o local; `bigquery`, o do GCP.
CHAVE = "LEGACY_WAREHOUSE"


def do_ambiente(legado: Engine, environ: Mapping[str, str] | None = None) -> Engine | BigQuery:
    """O armazém que o ambiente declara. No BigQuery, o coordenador é o próprio banco legado.

    É o Cloud SQL das origens, que é PostgreSQL: os *locks* da captura moram nele, e
    nenhum banco a mais entra só para isso (contrato do G2.1).
    """
    import os

    env = os.environ if environ is None else environ
    escolha = (env.get(CHAVE) or "postgres").strip().lower()
    if escolha == "postgres":
        from sqlalchemy import create_engine

        from mvp_ed1.db import WAREHOUSE, database_url

        return create_engine(database_url(WAREHOUSE))
    if escolha != "bigquery":
        raise RuntimeError(f"{CHAVE}={escolha!r}: use postgres ou bigquery")
    ausentes = [c for c in ("GCP_PROJECT_ID", "GCP_BQ_LOCATION") if not env.get(c)]
    if ausentes:
        raise RuntimeError(f"{CHAVE}=bigquery sem {', '.join(ausentes)} no ambiente")
    from google.cloud import bigquery

    from mvp_ed1.gcp.credenciais import personificada

    projeto = env["GCP_PROJECT_ID"]
    # No Composer, a conta do `ingestor` personificada pela do ambiente (D81); aqui, a ADC.
    cliente = bigquery.Client(project=projeto, location=env["GCP_BQ_LOCATION"],
                              credentials=personificada(env))
    return BigQuery(cliente, projeto, coordenador=legado, local=env["GCP_BQ_LOCATION"])


# ── nomes, nos dois armazéns ─────────────────────────────────────────────────
# Quem lê com uma `Connection` do PostgreSQL ou com um `BigQuery` pergunta aqui
# como se escreve o nome — e só isso muda na consulta.

def nome(alvo: Any, qualificada: str) -> str:
    """`schema.tabela` no armazém de `alvo` (uma `Connection`, um `Engine` ou um `BigQuery`)."""
    return alvo.tabela(qualificada) if isinstance(alvo, BigQuery) else qualificada


def bruto(alvo: Any, esquema: str, tabela: str) -> str:
    """`esquema."tabela"` — o nome entre aspas, como o Airbyte o cria —, ou o do BigQuery."""
    return alvo.do_bruto(esquema, tabela) if isinstance(alvo, BigQuery) else f'{esquema}."{tabela}"'


def sync_id(alvo: Any) -> str:
    """O `sync_id` do `_airbyte_meta`, como texto, no dialeto de `alvo`."""
    return BigQuery.sync_id() if isinstance(alvo, BigQuery) else "_airbyte_meta->>'sync_id'"


# ── o coordenador ────────────────────────────────────────────────────────────

def coordenador(armazem: Engine | BigQuery) -> Engine:
    """Onde moram os *locks*: o próprio armazém local, ou o Cloud SQL ao lado do BigQuery."""
    return armazem.coordenador if isinstance(armazem, BigQuery) else armazem


@contextmanager
def lock_de_sessao(engine: Engine, ns: int, chave_sql: str, parametros: Mapping[str, Any]) -> Iterator[None]:
    """`pg_advisory_lock` de sessão numa conexão só dele, descartada no fim (nunca volta ao *pool*)."""
    from sqlalchemy import text

    conexao = engine.connect()
    try:
        conexao.execute(text(f"select pg_advisory_lock(:ns, {chave_sql})"), {"ns": ns, **parametros})
        conexao.commit()
        yield
    finally:
        conexao.invalidate()
        conexao.close()
