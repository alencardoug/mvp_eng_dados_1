"""Produtor de eventos de estoque — o que dá ao caminho quente o que processar.

Especificado na [Geração de Dados §6](../../../docs/geracao_de_dados.md). A carga
histórica cria o livro coerente entre `period_start` e `as_of_date`; este
produtor acrescenta eventos **depois** disso, ao vivo, e é ele quem gera os
casos difíceis de propósito: rajada, ociosidade, evento atrasado e transferência
em par correlacionado.

Três regras que não são detalhe:

1. **Nada de duplicata na origem.** A tabela permanece íntegra; quem repete é o
   transporte, e a repetição é injetada por `mvp_ed1.streaming.cli duplicar`.
   Duplicar na origem testaria a coisa errada — a duplicata real nasce no
   caminho, não no banco.
2. **O relógio nunca produz `occurred_at` no futuro.** Evento atrasado tem
   `occurred_at` no passado e `recorded_at` agora, que é a forma exata do
   `CHECK (recorded_at >= occurred_at)`.
3. **Movimento e saldo na mesma transação** (Modelo de Dados §5.4). Escrever o
   evento sem mover o saldo faria o CDC publicar um fato que a origem não
   sustenta, e a reconciliação do fim da etapa acusaria — corretamente.
"""

from __future__ import annotations

import datetime as dt
import json
import logging
import hashlib
import random
import time
from dataclasses import dataclass, field
from decimal import Decimal
from pathlib import Path
from typing import Any

import sqlalchemy as sa

from mvp_ed1.db import SOURCE, database_url
from mvp_ed1.streaming.config import Produtor as Parametros

LOG = logging.getLogger(__name__)

#: Estado de retomada. Fora do repositório: é estado de execução, não código.
ESTADO = Path(".stream") / "producer_state.json"

#: Tipo de movimento → processo de origem, como o `CHECK` da origem exige.
ORIGEM_DO_TIPO = {
    "purchase_receipt": "purchase",
    "customer_return": "return",
    "supplier_return": "return",
    "sale_dispatch": "sale",
    "transfer_in": "transfer",
    "transfer_out": "transfer",
    "adjustment_in": "adjustment",
    "adjustment_out": "adjustment",
}

#: Tipos que o produtor sorteia, com peso. Venda domina porque é o que domina
#: a operação — e é ela que faz o saldo cair até cruzar o limiar do alerta.
PESOS = {
    "sale_dispatch": 0.55,
    "purchase_receipt": 0.20,
    "adjustment_out": 0.08,
    "adjustment_in": 0.07,
    "customer_return": 0.06,
    "supplier_return": 0.04,
}

ENTRADAS = frozenset({"purchase_receipt", "customer_return", "transfer_in", "adjustment_in"})

MOTIVOS = (
    "Contagem cíclica", "Avaria em manuseio", "Perda por validade",
    "Divergência de conferência", "Devolução ao estoque",
)


@dataclass
class _Agregado:
    """Estado corrente de um par armazém/SKU, mantido em memória."""

    disponivel: int
    reservado: int
    versao: int


@dataclass
class Relatorio:
    emitidos: int = 0
    atrasados: int = 0
    transferencias: int = 0
    por_tipo: dict[str, int] = field(default_factory=dict)
    primeiro: dt.datetime | None = None
    ultimo: dt.datetime | None = None


class ProdutorDeEventos:
    """Emite eventos no livro da origem, respeitando todas as invariantes."""

    def __init__(self, parametros: Parametros, semente: int, teto: int | None = None):
        self._p = parametros
        self._semente = semente
        self._teto = teto if teto is not None else parametros.teto_de_eventos

        # ── Repetível **e** retomável ────────────────────────────────────────
        # A mesma `stream_seed` recria o mesmo cenário — inclusive os mesmos
        # `movement_id`, porque a chave nasce do sorteio. Rodar duas vezes com a
        # mesma semente sobre a mesma origem colidiria na chave primária, que é
        # a repetibilidade funcionando contra si mesma.
        #
        # A Geração §6 pede as duas coisas: repetibilidade **e** cursor que
        # permita retomar. O deslocamento resolve as duas — cada execução recebe
        # uma subsemente derivada de onde a anterior parou, então a sequência
        # continua em vez de recomeçar, e continua determinística.
        self._deslocamento = self._retomar()
        self._rng = random.Random(
            int.from_bytes(
                hashlib.blake2b(
                    f"{semente}:{self._deslocamento}".encode(), digest_size=8
                ).digest(),
                "big",
            )
        )
        self._motor = sa.create_engine(database_url(SOURCE), future=True)
        self._agregados: dict[tuple[int, int], _Agregado] = {}
        self._armazens: list[int] = []
        self._custos: dict[int, Decimal] = {}
        self._sequencia = 0

    def _retomar(self) -> int:
        """Quantos eventos esta semente já emitiu, segundo o cursor persistido."""
        if not ESTADO.exists():
            return 0
        try:
            estado = json.loads(ESTADO.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return 0
        if estado.get("stream_seed") != self._semente:
            return 0
        return int(estado.get("emitidos_acumulados", estado.get("emitidos", 0)))

    # ── Carga do estado da origem ───────────────────────────────────────────
    def _carregar(self) -> None:
        with self._motor.connect() as c:
            self._armazens = [
                r[0] for r in c.execute(
                    sa.text("select id from oltp.warehouses where deleted_at is null order by id")
                )
            ]
            # O custo vem do **último movimento** do SKU, não de uma tabela de
            # preço: é exatamente o que o ADR-0030 define como custo — o do
            # instante em que a mercadoria se moveu. Um SKU que nunca se moveu
            # não tem custo conhecido, e o evento sai com `unit_cost` nulo, que
            # é o que a coluna admite.
            self._custos = {
                r[0]: r[1] for r in c.execute(
                    sa.text(
                        "select distinct on (product_variant_id) product_variant_id, unit_cost "
                        "from oltp.inventory_movements where unit_cost is not null "
                        "order by product_variant_id, event_sequence desc"
                    )
                )
            }
            saldos = c.execute(
                sa.text(
                    "select warehouse_id, product_variant_id, quantity_available, quantity_reserved "
                    "from oltp.inventory_balances"
                )
            ).all()
            versoes = c.execute(
                sa.text(
                    "select warehouse_id, product_variant_id, max(aggregate_version) "
                    "from oltp.inventory_movements group by 1, 2"
                )
            ).all()

        ultima_versao = {(w, v): int(m) for w, v, m in versoes}
        for armazem, variante, disponivel, reservado in saldos:
            self._agregados[(armazem, variante)] = _Agregado(
                disponivel=int(disponivel),
                reservado=int(reservado),
                versao=ultima_versao.get((armazem, variante), 0),
            )
        LOG.info(
            "origem: %s armazéns, %s SKUs, %s pares com saldo",
            len(self._armazens), len(self._custos), len(self._agregados),
        )

    # ── Construção de um evento ─────────────────────────────────────────────
    def _instantes(self) -> tuple[dt.datetime, dt.datetime]:
        """`occurred_at` e `recorded_at`, com atraso deliberado na fração declarada."""
        agora = dt.datetime.now(dt.timezone.utc)
        if self._rng.random() < self._p.fracao_de_eventos_atrasados:
            atraso = self._rng.randint(*self._p.atraso_dos_eventos_segundos)
            return agora - dt.timedelta(seconds=atraso), agora
        return agora, agora

    def _proximo_par(self) -> tuple[int, int, _Agregado]:
        (armazem, variante), estado = self._rng.choice(list(self._agregados.items()))
        return armazem, variante, estado

    def _evento(
        self,
        *,
        tipo: str,
        armazem: int,
        variante: int,
        quantidade: int,
        ocorrido: dt.datetime,
        registrado: dt.datetime,
        codigo: str,
        correlacao: str | None = None,
        metadados: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        import uuid

        estado = self._agregados[(armazem, variante)]
        estado.versao += 1
        origem = ORIGEM_DO_TIPO[tipo]
        delta = quantidade if tipo in ENTRADAS else -quantidade
        estado.disponivel += delta

        self._sequencia += 1
        return {
            "movement_id": str(uuid.UUID(int=self._rng.getrandbits(128), version=4)),
            "idempotency_key": f"{origem}:{codigo}:{armazem}:{variante}:{estado.versao}"[:100],
            "warehouse_id": armazem,
            "product_variant_id": variante,
            "movement_type": tipo,
            "quantity_delta": delta,
            "unit_cost": self._custos.get(variante),
            "source_type": origem,
            "source_id": codigo,
            "correlation_id": correlacao,
            "causation_id": str(uuid.UUID(int=self._rng.getrandbits(128), version=4)),
            "aggregate_version": estado.versao,
            "occurred_at": ocorrido,
            "recorded_at": registrado,
            "schema_version": 1,
            "metadata": json.dumps(metadados, ensure_ascii=False) if metadados else None,
        }

    def _sortear(self) -> list[dict[str, Any]]:
        """Um evento, ou o par de uma transferência."""
        ocorrido, registrado = self._instantes()

        if len(self._armazens) >= 2 and self._rng.random() < self._p.fracao_de_transferencias:
            return self._transferencia(ocorrido, registrado)

        armazem, variante, estado = self._proximo_par()
        tipo = self._rng.choices(list(PESOS), weights=list(PESOS.values()), k=1)[0]

        if tipo not in ENTRADAS:
            # Saída sem lastro violaria `quantity_on_hand >= 0` e a reserva.
            # A operação real não tira o que não tem: vira entrada.
            teto = min(estado.disponivel, 40)
            if teto < 1:
                tipo = "purchase_receipt"
            else:
                quantidade = self._rng.randint(1, teto)
                return [self._evento(
                    tipo=tipo, armazem=armazem, variante=variante, quantidade=quantidade,
                    ocorrido=ocorrido, registrado=registrado,
                    codigo=self._codigo(tipo),
                    metadados=self._metadados(tipo),
                )]

        return [self._evento(
            tipo=tipo, armazem=armazem, variante=variante,
            quantidade=self._rng.randint(1, 60),
            ocorrido=ocorrido, registrado=registrado,
            codigo=self._codigo(tipo), metadados=self._metadados(tipo),
        )]

    def _transferencia(self, ocorrido, registrado) -> list[dict[str, Any]]:
        """Saída e entrada com o mesmo `correlation_id` e a mesma quantidade.

        Transferência que não fecha dos dois lados some do saldo consolidado
        sem deixar rastro. É o caso que o critério "transferência confere dos
        dois lados" existe para pegar, e é por isso que os dois lados nascem
        na mesma transação.
        """
        import uuid

        origem_id, destino_id = self._rng.sample(self._armazens, 2)
        candidatos = [
            (a, v) for (a, v), e in self._agregados.items() if a == origem_id and e.disponivel > 0
        ]
        if not candidatos:
            return self._sortear()
        _, variante = self._rng.choice(candidatos)
        estado = self._agregados[(origem_id, variante)]
        quantidade = self._rng.randint(1, min(estado.disponivel, 25))

        correlacao = str(uuid.UUID(int=self._rng.getrandbits(128), version=4))
        codigo = f"TRF-{correlacao[:8].upper()}"

        self._agregados.setdefault(
            (destino_id, variante), _Agregado(disponivel=0, reservado=0, versao=0)
        )
        return [
            self._evento(
                tipo="transfer_out", armazem=origem_id, variante=variante,
                quantidade=quantidade, ocorrido=ocorrido, registrado=registrado,
                codigo=codigo, correlacao=correlacao,
            ),
            self._evento(
                tipo="transfer_in", armazem=destino_id, variante=variante,
                quantidade=quantidade, ocorrido=ocorrido, registrado=registrado,
                codigo=codigo, correlacao=correlacao,
            ),
        ]

    def _codigo(self, tipo: str) -> str:
        prefixo = {"sale_dispatch": "SHP", "purchase_receipt": "GR", "customer_return": "RET",
                   "supplier_return": "DEV"}.get(tipo, "AJU")
        # O código carrega o deslocamento: sem ele, duas execuções gerariam
        # `SHP-STR-000001` duas vezes e a `idempotency_key` colidiria.
        return f"{prefixo}-STR-{self._deslocamento + self._sequencia + 1:06d}"

    def _metadados(self, tipo: str) -> dict[str, Any] | None:
        if tipo.startswith("adjustment"):
            return {"motivo": self._rng.choice(MOTIVOS), "origem": "produtor_de_streaming"}
        return None

    # ── Escrita ─────────────────────────────────────────────────────────────
    def _gravar(self, eventos: list[dict[str, Any]]) -> None:
        """Movimento e saldo na mesma transação (Modelo de Dados §5.4)."""
        with self._motor.begin() as c:
            for evento in eventos:
                c.execute(
                    sa.text(
                        "insert into oltp.inventory_movements ("
                        "movement_id, idempotency_key, warehouse_id, product_variant_id, "
                        "movement_type, quantity_delta, unit_cost, source_type, source_id, "
                        "correlation_id, causation_id, aggregate_version, occurred_at, "
                        "recorded_at, schema_version, metadata) values ("
                        ":movement_id, :idempotency_key, :warehouse_id, :product_variant_id, "
                        ":movement_type, :quantity_delta, :unit_cost, :source_type, :source_id, "
                        ":correlation_id, :causation_id, :aggregate_version, :occurred_at, "
                        ":recorded_at, :schema_version, cast(:metadata as jsonb))"
                    ),
                    evento,
                )
                self._mover_saldo(c, evento)

    @staticmethod
    def _mover_saldo(conexao, evento: dict[str, Any]) -> None:
        """Atualiza o saldo; insere só se o par ainda não existir.

        `on conflict do update` seria o caminho óbvio e está **errado** aqui: o
        PostgreSQL avalia as `CHECK` sobre a linha **proposta** antes de arbitrar
        o conflito, então uma saída de 8 unidades tentava inserir `-8` como
        saldo e batia em `quantity_on_hand >= 0` — mesmo com o par existindo e o
        caminho de atualização sendo perfeitamente válido.

        O par novo só aparece como destino de transferência, e transferência de
        entrada é sempre positiva: o `insert` nunca nasce negativo.
        """
        parametros = {
            "w": evento["warehouse_id"], "v": evento["product_variant_id"],
            "q": evento["quantity_delta"], "t": evento["occurred_at"],
        }
        atualizadas = conexao.execute(
            sa.text(
                "update oltp.inventory_balances set "
                "quantity_on_hand = quantity_on_hand + :q, "
                "last_movement_at = :t, updated_at = now() "
                "where warehouse_id = :w and product_variant_id = :v"
            ),
            parametros,
        ).rowcount
        if not atualizadas:
            conexao.execute(
                sa.text(
                    "insert into oltp.inventory_balances "
                    "(warehouse_id, product_variant_id, quantity_on_hand, last_movement_at) "
                    "values (:w, :v, :q, :t)"
                ),
                parametros,
            )

    # ── Laço ────────────────────────────────────────────────────────────────
    def executar(self) -> Relatorio:
        self._carregar()
        relatorio = Relatorio()

        while relatorio.emitidos < self._teto:
            rajada = self._rng.randint(*self._p.eventos_por_rajada)
            lote: list[dict[str, Any]] = []
            while len(lote) < rajada and relatorio.emitidos + len(lote) < self._teto:
                lote.extend(self._sortear())

            self._gravar(lote)
            for evento in lote:
                relatorio.emitidos += 1
                relatorio.por_tipo[evento["movement_type"]] = (
                    relatorio.por_tipo.get(evento["movement_type"], 0) + 1
                )
                if evento["occurred_at"] < evento["recorded_at"]:
                    relatorio.atrasados += 1
                if evento["movement_type"] == "transfer_out":
                    relatorio.transferencias += 1
                if relatorio.primeiro is None:
                    relatorio.primeiro = evento["occurred_at"]
                relatorio.ultimo = evento["recorded_at"]

            self._salvar_estado(relatorio)
            time.sleep(self._rng.uniform(*self._p.pausa_entre_rajadas_segundos))

        return relatorio

    def _salvar_estado(self, relatorio: Relatorio) -> None:
        """Cursor e contagem emitida, para retomada (Geração §6)."""
        ESTADO.parent.mkdir(parents=True, exist_ok=True)
        ESTADO.write_text(
            json.dumps(
                {
                    "stream_seed": self._semente,
                    "emitidos": relatorio.emitidos,
                    "emitidos_acumulados": self._deslocamento + relatorio.emitidos,
                    "teto": self._teto,
                    "ultimo_registrado_em": relatorio.ultimo.isoformat() if relatorio.ultimo else None,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
