"""Esperar o livro quente alcançar um corte — o fim que o *pipeline* não tem.

O `stream-run` é processo de primeiro plano sem fim natural: ele fica lendo o
tópico para sempre. Medir "quanto demorou o caminho quente" exige um fim
declarado, e o fim é um **corte**: o maior `event_sequence` que a origem tinha
no instante escolhido. Esperar é esperar que toda chave da origem até esse
corte tenha aterrissado no livro.

**O corte é lido depois do produtor, nunca antes** (RV12-2-06). No cenário de
*snapshot* não há produtor e o corte inicial não muda; no cenário de eventos
novos, ler antes de produzir fecharia a espera no *snapshot* e não provaria
nada sobre os eventos que o produtor acabou de emitir.

**O oráculo é de chaves, não de contagem.** Contar os dois lados aceita o caso
em que uma chave falta e outra sobra — a mesma insuficiência que a revisão da
Etapa 12 achou no oráculo da quarentena. Aqui a diferença de conjuntos é
barata: o corte limita o volume, e as chaves são `uuid`.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field

import sqlalchemy as sa

from mvp_ed1 import db
from mvp_ed1.models.base import SCHEMA as SCHEMA_ORIGEM
from mvp_ed1.streaming import config as cfg

#: Tabela do livro na origem — o lado que o CDC lê.
TABELA_ORIGEM = "inventory_movements"


def _motor(prefixo: str) -> sa.Engine:
    return sa.create_engine(db.database_url(prefixo), future=True)


def corte_da_origem() -> int:
    """`max(event_sequence)` da origem agora. Livro vazio devolve 0."""
    with _motor(db.SOURCE).connect() as con:
        valor = con.execute(
            sa.text(f"select coalesce(max(event_sequence), 0) from {SCHEMA_ORIGEM}.{TABELA_ORIGEM}")
        ).scalar_one()
    return int(valor)


def _chaves(motor: sa.Engine, relacao: str, ate_seq: int) -> set[str]:
    with motor.connect() as con:
        linhas = con.execute(
            sa.text(
                f"select movement_id::text from {relacao} where event_sequence <= :ate"
            ),
            {"ate": ate_seq},
        ).scalars()
        return {str(linha) for linha in linhas}


@dataclass
class Faltantes:
    """O que o livro ainda não tem, e o que ele tem a mais."""

    origem: int
    livro: int
    faltam: int
    intrusas: int = 0
    exemplos: list[str] = field(default_factory=list)

    @property
    def alcancado(self) -> bool:
        return self.faltam == 0


def pendentes(ate_seq: int, *, destino: str | None = None) -> Faltantes:
    """Chaves da origem até o corte que ainda não estão no livro.

    `intrusas` conta o contrário — chave no livro que a origem não tem sob o
    mesmo corte. Não impede a espera de terminar, porque o critério do corte é
    de **continência**; entra no registro porque um livro restaurado de outro
    ciclo é exatamente onde isso apareceria.
    """
    relacao_destino = destino or cfg.carregar().destino.relacao
    de_origem = _chaves(_motor(db.SOURCE), f"{SCHEMA_ORIGEM}.{TABELA_ORIGEM}", ate_seq)
    do_livro = _chaves(_motor(db.WAREHOUSE), relacao_destino, ate_seq)
    faltam = de_origem - do_livro
    return Faltantes(
        origem=len(de_origem),
        livro=len(do_livro),
        faltam=len(faltam),
        intrusas=len(do_livro - de_origem),
        exemplos=sorted(faltam)[:3],
    )


@dataclass
class Resultado:
    alcancado: bool
    motivo: str
    segundos: float
    ultimo: Faltantes


def aguardar(
    ate_seq: int,
    *,
    prazo_s: float = 900.0,
    intervalo_s: float = 2.0,
    vivo=None,
    reportar=None,
    relogio=time.monotonic,
    dormir=time.sleep,
) -> Resultado:
    """Espera o livro conter a origem até `ate_seq`.

    Três desfechos, e cada um tem nome: `alcancado`, `prazo` e `morreu` — este
    último quando `vivo()` deixa de ser verdadeiro, que é o *pipeline* caindo
    sob a espera. Terminar o produtor **não** encerra a espera: o último evento
    pode estar em trânsito, e foi a contraprova pedida na segunda rodada de
    revisão do plano.
    """
    comeco = relogio()
    ultimo = pendentes(ate_seq)
    while True:
        if reportar is not None:
            reportar(ultimo)
        if ultimo.alcancado:
            return Resultado(True, "alcancado", relogio() - comeco, ultimo)
        if vivo is not None and not vivo():
            return Resultado(False, "morreu", relogio() - comeco, ultimo)
        if relogio() - comeco >= prazo_s:
            return Resultado(False, "prazo", relogio() - comeco, ultimo)
        dormir(intervalo_s)
        ultimo = pendentes(ate_seq)
