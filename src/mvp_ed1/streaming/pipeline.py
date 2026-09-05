"""A lógica do caminho quente — a parte que **não** muda entre as fases.

O que este módulo descreve é o grafo: deduplicar, gravar, janelar por tempo de
evento, acumular saldo, avaliar limiar, alertar. Nenhuma linha aqui sabe que o
transporte é Redpanda ou que o destino é PostgreSQL; a origem vem de
`transport.py` e o destino de `sink.py`, e são essas duas pontas que o Dataflow
substitui (Streaming §2).

**O desenho em uma frase:** o pipeline escreve eventos imutáveis, e o saldo é
uma soma deles — nunca um agregado guardado. O ADR-0019 recusou a tabela
agregada por janela porque *"janela processada errado não tem de onde ser
reconstruída"*, e a consequência é que a janela aqui serve ao **alerta**, não ao
armazenamento.

**Por que o ramo do saldo pende da escrita, e não da leitura.** O destino é a
fronteira exatamente-uma-vez: só segue adiante o evento que o `on conflict`
deixou entrar. Pendurar o saldo direto na leitura faria uma duplicata que
chegasse fora da janela de deduplicação ser descartada na tabela e ainda assim
somada duas vezes no alerta. É a mesma fronteira que o `staging` é para o
caminho frio, no lugar equivalente.
"""

from __future__ import annotations

import datetime as dt
import logging
from typing import Any, Iterable

import apache_beam as beam
from apache_beam.coders import BooleanCoder, VarIntCoder
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
from apache_beam.transforms import trigger, userstate, window
from apache_beam.transforms.timeutil import TimeDomain
from apache_beam.utils.timestamp import Duration
from apache_beam.utils.windowed_value import PaneInfoTiming

from mvp_ed1.streaming.config import Fluxo
from mvp_ed1.streaming.sink import GravarEventos
from mvp_ed1.streaming.transport import LerDoTransporte, PublicarAlerta

LOG = logging.getLogger(__name__)

#: Motivos de alerta. `abertura` é a travessia do limiar para baixo;
#: `normalizacao` é a volta. As duas são emitidas: um alerta que nunca se
#: fecha vira ruído, e quem consome o tópico precisa saber que passou.
ABERTURA = "abertura"
NORMALIZACAO = "normalizacao"


class DeduplicarPorChave(beam.DoFn):
    """Descarta retransmissões pela `idempotency_key`, dentro da janela declarada.

    Deduplicação **por tempo de evento**, e não por tempo de processamento. Não é
    preciosismo: o `DeduplicatePerKey` que o Beam oferece declara um temporizador
    de tempo de processamento mesmo quando só se pede o de tempo de evento, e um
    temporizador de tempo real desqualifica os dois únicos executores locais
    capazes de rodar um `DoFn` divisível não-limitado. Sobraria o mais fraco, e o
    pipeline não subiria.

    O que se perde escrevendo à mão é nada: o Streaming §3.2 já descreve
    deduplicação por chave dentro de uma janela fixa, que é exatamente isto.

    Isto é **otimização**, não a garantia. Quem garante é a idempotência do
    destino (ADR-0019): duplicata que chegue depois desta janela é barrada lá.
    """

    VISTO = userstate.ReadModifyWriteStateSpec("visto", BooleanCoder())
    EXPIRACAO = userstate.TimerSpec("expiracao", TimeDomain.WATERMARK)

    def __init__(self, janela_segundos: int):
        self._janela = janela_segundos
        self.repetidos = beam.metrics.Metrics.counter("streaming", "retransmissoes_no_transporte")

    def process(
        self,
        elemento: tuple[str, dict[str, Any]],
        instante=beam.DoFn.TimestampParam,
        visto=beam.DoFn.StateParam(VISTO),
        expiracao=beam.DoFn.TimerParam(EXPIRACAO),
    ) -> Iterable[dict[str, Any]]:
        _, evento = elemento
        if visto.read():
            self.repetidos.inc()
            return
        visto.write(True)
        # A memória da deduplicação expira pelo *watermark*, não pelo relógio:
        # é o mesmo eixo em que a janela fecha, e é o que mantém o resultado
        # estável quando a ordem de chegada não é a ordem dos fatos.
        expiracao.set(instante + Duration(seconds=self._janela))
        yield evento

    @userstate.on_timer(EXPIRACAO)
    def _esquecer(self, visto=beam.DoFn.StateParam(VISTO)):
        visto.clear()


def somar_deltas(valores: Iterable[tuple[int, int]]) -> tuple[int, int]:
    """Soma o delta da janela e conta quantos eventos vieram ao vivo.

    Entrada e saída têm a mesma forma de propósito: o Beam chama um combinador
    tanto sobre os valores originais quanto sobre resultados parciais, e um
    combinador cuja saída não serve de entrada quebra no primeiro agrupamento
    dividido — em silêncio, e só em volume.
    """
    delta = ao_vivo = 0
    for parcial_delta, parcial_ao_vivo in valores:
        delta += parcial_delta
        ao_vivo += parcial_ao_vivo
    return delta, ao_vivo


class _AnotarJanela(beam.DoFn):
    """Carrega janela e classificação do painel para dentro do valor.

    Depois do rejanelamento para o global, `WindowParam` e `PaneInfoParam`
    passam a descrever a janela nova. O que interessa — de qual janela de
    evento veio, e se o painel foi **atrasado** — precisa viajar no valor.
    """

    def process(
        self,
        elemento: tuple[tuple[int, int], tuple[int, int]],
        janela=beam.DoFn.WindowParam,
        painel=beam.DoFn.PaneInfoParam,
    ) -> Iterable[tuple[tuple[int, int], dict[str, Any]]]:
        chave, (delta, ao_vivo) = elemento
        yield chave, {
            "delta": delta,
            "ao_vivo": ao_vivo,
            "janela_inicio": janela.start.to_utc_datetime(),
            "janela_fim": janela.end.to_utc_datetime(),
            "atrasado": painel.timing == PaneInfoTiming.LATE,
            "indice_do_painel": painel.index,
        }


class AcumularSaldoEAlertar(beam.DoFn):
    """Saldo corrente por armazém/SKU e travessia do limiar.

    O estado é global por chave, não por janela: saldo é acumulado, e estado
    por janela zeraria a cada minuto. O rejanelamento para o global logo antes
    daqui existe exatamente para isso.

    **O painel atrasado é a correção.** Com acumulação `DISCARDING`, o painel
    tardio traz **apenas** o que chegou atrasado — somá-lo ao saldo corrente
    recalcula a janela sem contar duas vezes o que já havia. É assim que um
    movimento que ocorreu ontem e chegou hoje corrige o saldo de ontem em vez
    de ser ignorado ou de corromper a janela já fechada.
    """

    SALDO = userstate.ReadModifyWriteStateSpec("saldo", VarIntCoder())

    def __init__(self, limiar: int, destino):
        self._limiar = limiar
        self._destino = destino
        self._semente: dict[tuple[int, int], int] = {}
        self.alertas = beam.metrics.Metrics.counter("streaming", "alertas_emitidos")
        self.correcoes = beam.metrics.Metrics.counter("streaming", "janelas_corrigidas")

    def setup(self):
        """Semeia o saldo a partir dos deltas já duráveis no destino.

        Sem isto o acumulador começaria em zero a cada subida do pipeline, e o
        número que ele chama de "saldo" seria apenas o que este processo viu —
        nada cruzaria um limiar partindo de zero, e o alerta nunca dispararia.

        O corte é **temporal e exato**: entra na semente tudo que foi gravado
        *antes* de esta instância começar. O que ela mesma gravar carrega carimbo
        posterior e chega pelo fluxo, uma vez só. Evento gravado por uma execução
        anterior e nunca contabilizado por ela não existe — o destino grava antes
        de encaminhar, e o que já está gravado volta como duplicata e é barrado.

        É também o que torna o `DirectRunner` local honesto: ele não persiste
        estado entre execuções, e o Dataflow persiste. Semear do destino faz o
        mesmo código dar o mesmo resultado nos dois, que é o ponto do **P4**.
        """
        import sqlalchemy as sa

        from mvp_ed1.streaming.sink import engine

        motor = engine()
        try:
            with motor.connect() as conexao:
                self._inicio = conexao.execute(sa.text("select now()")).scalar_one()
                linhas = conexao.execute(
                    sa.text(
                        f"select warehouse_id, product_variant_id, sum(quantity_delta) "
                        f"from {self._destino.qualificado} "
                        f"where _stream_extracted_at < :inicio group by 1, 2"
                    ),
                    {"inicio": self._inicio},
                ).all()
        finally:
            motor.dispose()
        self._semente = {(w, v): int(s) for w, v, s in linhas}
        LOG.info("saldo semeado a partir de %s pares já duráveis", len(self._semente))

    def process(
        self,
        elemento: tuple[tuple[int, int], dict[str, Any]],
        saldo=beam.DoFn.StateParam(SALDO),
    ) -> Iterable[dict[str, Any]]:
        (armazem, sku), painel = elemento
        gravado = saldo.read()
        anterior = self._semente.get((armazem, sku), 0) if gravado is None else gravado
        atual = anterior + painel["delta"]
        saldo.write(atual)

        if painel["atrasado"]:
            self.correcoes.inc()

        # Painel formado apenas por eventos do *snapshot* inicial constrói o
        # saldo, mas não avisa sobre ele: o snapshot reproduz dois anos e meio
        # de livro, e alertar em cada travessia histórica encheria o tópico de
        # avisos sobre estoque de 2024. É o mesmo motivo pelo qual um sistema
        # real não dispara alarme ao carregar o estado inicial.
        if not painel["ao_vivo"]:
            return

        # Travessia, não nível: alertar a cada evento enquanto abaixo do limiar
        # afogaria o tópico. O que interessa é a borda — e a volta também, para
        # que quem consome saiba que o alerta se fechou.
        if anterior >= self._limiar > atual:
            motivo = ABERTURA
        elif anterior < self._limiar <= atual:
            motivo = NORMALIZACAO
        else:
            return

        self.alertas.inc()
        yield {
            "motivo": motivo,
            "warehouse_id": armazem,
            "product_variant_id": sku,
            "quantity_on_hand": atual,
            "quantity_before": anterior,
            "limiar": self._limiar,
            "delta_da_janela": painel["delta"],
            "janela_inicio": painel["janela_inicio"],
            "janela_fim": painel["janela_fim"],
            # Alerta nascido de painel atrasado é **correção** de janela já
            # fechada, e quem consome precisa distinguir os dois casos.
            "correcao_de_evento_atrasado": painel["atrasado"],
            "emitido_em": dt.datetime.now(dt.timezone.utc),
        }


def construir(p: beam.Pipeline, fluxo: Fluxo) -> dict[str, beam.PCollection]:
    """Monta o grafo e devolve as coleções nomeadas, para teste e diagnóstico."""
    proc = fluxo.processamento

    eventos = p | "LerDoTransporte" >> LerDoTransporte(
        fluxo.transporte, proc.folga_do_watermark_segundos
    )

    # Deduplicação no consumidor, pela `idempotency_key`, dentro da janela
    # declarada (Streaming §3.2). É otimização, não a garantia: o que garante é
    # a idempotência do destino, logo abaixo. Duplicata que escape desta janela
    # é barrada lá.
    unicos = (
        eventos
        # A dica de tipo na chave não é decoração: sem ela o Beam escolhe um
        # codificador genérico e avisa que a chave pode não ser determinística —
        # e chave não determinística em `DoFn` com estado significa estado
        # procurado no lugar errado, em silêncio.
        | "ChavearPorIdempotencia" >> beam.Map(
            lambda e: (e["idempotency_key"], e)
        ).with_output_types(tuple[str, dict[str, Any]])
        | "Deduplicar" >> beam.ParDo(DeduplicarPorChave(proc.janela_segundos))
    )

    # ── Ramo 1: deltas imutáveis (ADR-0019) ─────────────────────────────────
    novos = unicos | "GravarDeltas" >> beam.ParDo(GravarEventos(fluxo.destino, fluxo.transporte))

    # ── Ramo 2: saldo por tempo de evento e alerta (Streaming §3 e §5) ──────
    alertas = (
        novos
        | "JanelaDeEvento" >> beam.WindowInto(
            window.FixedWindows(proc.janela_segundos),
            # `AfterWatermark(late=...)` é o que dá sentido a "evento atrasado
            # recalcula a janela": o painel pontual sai quando o watermark
            # passa, e cada retardatário dispara um painel próprio.
            trigger=trigger.AfterWatermark(late=trigger.AfterCount(1)),
            allowed_lateness=Duration(seconds=proc.atraso_tolerado_segundos),
            # `DISCARDING` e não `ACCUMULATING`: o painel atrasado traz só o
            # que chegou atrasado, e é isso que torna a soma corrente correta
            # sem escrituração de retratação.
            accumulation_mode=trigger.AccumulationMode.DISCARDING,
        )
        | "ChavearPorArmazemESku" >> beam.Map(
            lambda e: (
                (e["warehouse_id"], e["product_variant_id"]),
                (e["quantity_delta"], 0 if e.get("_do_snapshot") else 1),
            )
        )
        | "SomarDeltaDaJanela" >> beam.CombinePerKey(somar_deltas)
        | "AnotarJanela" >> beam.ParDo(_AnotarJanela())
        # Saldo é acumulado: estado por janela zeraria a cada minuto.
        | "VoltarAoGlobal" >> beam.WindowInto(
            window.GlobalWindows(),
            trigger=trigger.Repeatedly(trigger.AfterCount(1)),
            accumulation_mode=trigger.AccumulationMode.DISCARDING,
        )
        | "AcumularSaldo" >> beam.ParDo(AcumularSaldoEAlertar(fluxo.limiar_de_unidades, fluxo.destino))
        | "PublicarAlerta" >> beam.ParDo(PublicarAlerta(fluxo.transporte))
    )

    return {"eventos": eventos, "unicos": unicos, "novos": novos, "alertas": alertas}


#: Paciência do programa cliente com o serviço de job, em segundos.
#:
#: O padrão do Beam é 300, e a documentação da opção afirma que ele "não se
#: aplica ao tempo de execução do pipeline". Aplica: o fluxo de mensagens do
#: job herda o mesmo prazo, e um job de streaming saudável morre com
#: `DEADLINE_EXCEEDED` em exatos cinco minutos — o pipeline continua vivo do
#: lado do runner e o cliente desiste dele. Um dia é o teto operacional de uma
#: sessão de desenvolvimento; quem quiser mais para o alvo `stream-run`.
PACIENCIA_COM_O_SERVICO_DE_JOB = 86400


def opcoes(extras: list[str] | None = None) -> PipelineOptions:
    """Opções do executor local em modo contínuo."""
    op = PipelineOptions(
        [f"--job_server_timeout={PACIENCIA_COM_O_SERVICO_DE_JOB}", *(extras or [])]
    )
    op.view_as(StandardOptions).streaming = True
    return op


def executar(fluxo: Fluxo, extras: list[str] | None = None) -> None:
    """Sobe o pipeline e o mantém consumindo até ser interrompido."""
    LOG.info(
        "pipeline: janela=%ss atraso_tolerado=%ss folga=%ss limiar=%s destino=%s",
        fluxo.processamento.janela_segundos,
        fluxo.processamento.atraso_tolerado_segundos,
        fluxo.processamento.folga_do_watermark_segundos,
        fluxo.limiar_de_unidades,
        fluxo.destino.qualificado,
    )
    with beam.Pipeline(options=opcoes(extras)) as p:
        construir(p, fluxo)
