"""Decodificação do envelope do Debezium para o contrato do evento de estoque.

O que chega do transporte é o envelope do CDC — `before`, `after`, `source`,
`op` —, não o evento. O que o pipeline processa é o evento do
[Modelo de Dados §5](../../../docs/modelo_de_dados.md#5-contrato-do-evento-de-estoque).
Este módulo é a fronteira entre os dois, e é o único lugar do projeto que sabe
como o Debezium serializa.

**Nada é descartado em silêncio.** `inventory_movements` é livro de eventos: só
aceita inserção. Um `UPDATE` ou `DELETE` capturado significa que a origem violou
o contrato, e o pipeline **falha** em cima disso — regra 4 do `CLAUDE.md` e
exigência explícita do [Streaming §2.1](../../../docs/streaming.md).
"""

from __future__ import annotations

import datetime as dt
import json
from decimal import Decimal
from typing import Any

#: `c` é inserção capturada do WAL; `r` é linha lida no snapshot inicial. As
#: duas nascem de um `INSERT`, e são as únicas que o livro admite.
OPERACOES_ACEITAS = frozenset({"c", "r"})

#: `u` altera, `d` apaga, `t` trunca. Nenhuma é evento de negócio aqui.
OPERACOES_PROIBIDAS = {"u": "UPDATE", "d": "DELETE", "t": "TRUNCATE"}

#: Colunas do contrato que chegam como texto e precisam virar `Decimal`.
#: Nunca `float`: `decimal.handling.mode=string` no conector existe para que a
#: conversão seja exata do transporte ao destino (CLAUDE.md §3).
_DECIMAIS = ("unit_cost",)

_INTEIROS = (
    "event_sequence", "warehouse_id", "product_variant_id",
    "quantity_delta", "aggregate_version", "schema_version",
)

_INSTANTES = ("occurred_at", "recorded_at")


class ContratoViolado(RuntimeError):
    """A origem publicou algo que o livro de eventos não admite."""


def _instante(valor: Any, campo: str) -> dt.datetime:
    """Converte o carimbo do Debezium em `datetime` com fuso.

    `timestamptz` chega como ISO-8601 em UTC (`ZonedTimestamp`). O ramo
    numérico existe para o caso de o tipo da coluna mudar na origem: em vez de
    um `TypeError` obscuro no meio do pipeline, a falha diz qual campo era.
    """
    if isinstance(valor, str):
        return dt.datetime.fromisoformat(valor.replace("Z", "+00:00"))
    if isinstance(valor, (int, float)):
        return dt.datetime.fromtimestamp(valor / 1_000_000, tz=dt.timezone.utc)
    raise ContratoViolado(f"{campo}: instante em formato inesperado ({valor!r})")


def decodificar(bruto: bytes | str) -> dict[str, Any]:
    """Envelope do Debezium → evento do contrato, tipado.

    Levanta `ContratoViolado` para qualquer operação que não seja inserção.
    """
    envelope = json.loads(bruto)

    # Envelope achatado pelo `unwrap` da fase GCP (D78): a operação e a posição no
    # WAL vêm como campos `__op` e `__lsn`, e um DELETE reescrito traz `__deleted`.
    # A recusa é a mesma do envelope inteiro — a operação, não o formato, decide.
    if "op" not in envelope and "__op" in envelope:
        return _achatado(envelope)

    # Já sem envelope e sem operação: aceito, desde que traga a chave do evento.
    # Não custa tolerá-lo — o que não se tolera é operação errada.
    if "op" not in envelope and "movement_id" in envelope:
        return _tipar(envelope, operacao="c", lsn=None)

    operacao = envelope.get("op")
    if operacao in OPERACOES_PROIBIDAS:
        chave = (envelope.get("before") or envelope.get("after") or {}).get("movement_id")
        raise ContratoViolado(
            f"{OPERACOES_PROIBIDAS[operacao]} capturado em oltp.inventory_movements "
            f"(movement_id={chave}). O livro de eventos só aceita inserção: correção "
            "é evento compensatório novo. Isto é defeito na origem, não evento de negócio."
        )
    if operacao not in OPERACOES_ACEITAS:
        raise ContratoViolado(f"operação desconhecida no envelope: {operacao!r}")

    linha = envelope.get("after")
    if not linha:
        raise ContratoViolado(f"envelope com op={operacao!r} e `after` vazio")

    return _tipar(linha, operacao=operacao, lsn=(envelope.get("source") or {}).get("lsn"))


def _achatado(envelope: dict[str, Any]) -> dict[str, Any]:
    operacao = envelope["__op"]
    linha = {campo: valor for campo, valor in envelope.items() if not campo.startswith("__")}
    if operacao in OPERACOES_PROIBIDAS or str(envelope.get("__deleted", "false")).lower() == "true":
        nome = OPERACOES_PROIBIDAS.get(operacao, "DELETE")
        raise ContratoViolado(
            f"{nome} capturado em oltp.inventory_movements (movement_id={linha.get('movement_id')}). "
            "O livro de eventos só aceita inserção: correção é evento compensatório novo. "
            "Isto é defeito na origem, não evento de negócio."
        )
    if operacao not in OPERACOES_ACEITAS:
        raise ContratoViolado(f"operação desconhecida no envelope achatado: {operacao!r}")
    lsn = envelope.get("__lsn")
    return _tipar(linha, operacao=operacao, lsn=None if lsn is None else int(lsn))


def _tipar(linha: dict[str, Any], *, operacao: str, lsn: int | None) -> dict[str, Any]:
    evento: dict[str, Any] = dict(linha)

    for campo in _INSTANTES:
        evento[campo] = _instante(linha[campo], campo)
    for campo in _INTEIROS:
        if evento.get(campo) is not None:
            evento[campo] = int(evento[campo])
    for campo in _DECIMAIS:
        if evento.get(campo) is not None:
            evento[campo] = Decimal(str(evento[campo]))

    # `metadata` chega como texto JSON; guardar o texto e não o objeto evita
    # reserializar com outra ordem de chaves na escrita.
    if isinstance(evento.get("metadata"), (dict, list)):
        evento["metadata"] = json.dumps(evento["metadata"], ensure_ascii=False)

    # Procedência do evento, para diagnóstico e para o teste de reprocessamento.
    # `lsn` é a posição no WAL; ausente no snapshot inicial, que não veio do log.
    evento["_operacao"] = operacao
    evento["_lsn"] = lsn
    evento["_do_snapshot"] = operacao == "r"
    return evento
