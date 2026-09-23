"""Os oráculos do manifesto — o que prova que a restauração devolveu o mesmo.

Um pacote de recuperação que confere **contagens** não prova continência: uma
linha trocada por outra do mesmo grupo mantém o número. Foi a insuficiência que
a revisão do plano da Etapa 12 achou duas vezes — primeiro no oráculo SCD
(RV12-3-05), depois no da quarentena (RV12-4-02) —, e a resposta é a mesma nas
duas: **comparar as linhas completas, com multiplicidade**.

**Serialização canônica, e por que cada regra existe:**

* **todas as colunas**, não um subconjunto. O oráculo SCD da revisão 4 era
  `md5(string_agg(dbt_scd_id ‖ dbt_valid_from ‖ dbt_valid_to))` — sem atributo
  nenhum. Ele devolvia o **mesmo** hash para o original, para um atributo
  histórico alterado e para o início de uma versão vigente alterado;
* **nulo escrito como marcador explícito**, nunca concatenação nua. Em SQL
  `x ‖ NULL` é nulo, e o `string_agg` o descarta: com 1.574 das 1.575 linhas de
  `scd_customer` vigentes, o hash inteiro se resumia à única versão fechada;
* **ordem estável**, porque `select` sem `order by` não promete ordem e dois
  hashes de um mesmo conteúdo divergiriam;
* **multiplicidade preservada**: linhas iguais contam duas vezes. Sem isso,
  duplicar uma linha não mudaria o hash.

O digest é calculado **em Python, sobre as linhas lidas**, e não em SQL. É uma
escolha, e o custo está declarado: a quarentena tem 63.802 linhas, que se lê em
fatias. O que se ganha é que o oráculo fica exercitável sem banco — e um
oráculo que ninguém consegue testar é o que produziu as duas insuficiências
acima.

**A codificação é tipada e não ambígua (RVE-07).** A primeira versão escrevia
`coluna=str(valor)` com um marcador de nulo e separadores de controle, e a
revisão da entrega mediu o que isso confunde: o nulo com o texto `\\N`, um
separador dentro de um texto com a fronteira entre campos, e — no sentido
contrário — dois instantes iguais em fusos diferentes, `Decimal('1.00')` com
`Decimal('1.0')`, e `bytes` com `memoryview` (cujo `str` é o endereço de
memória, diferente a cada leitura). O que vale agora, por regra:

* **cada linha é um documento JSON** com as colunas em ordem, e cada valor vai
  **com o seu tipo**: nulo é `null` de JSON, texto é string de JSON (todo
  caractere de controle escapado — nenhum separador do nosso vale dentro de um
  valor), inteiro e booleano são os do JSON. Uma string `"\\N"` e um nulo não
  se parecem mais;
* **os tipos que o JSON não tem vão com etiqueta e forma canônica**: instante
  com fuso → UTC em ISO; `numeric` → sem zeros à direita (a escala do
  PostgreSQL é apresentação, não valor); binário → hexadecimal do conteúdo;
  `jsonb` → JSON com chaves ordenadas; data, hora, intervalo e UUID → ISO ou
  texto, cada um sob a sua etiqueta, para que `"1"` e `1` e `Decimal('1')`
  nunca colidam;
* **o formato é versionado** (`FORMATO`): o manifesto grava a versão com que
  foi escrito, e uma conferência com outra versão recusa em vez de comparar
  hashes que nasceram de codificações diferentes.
"""

from __future__ import annotations

import datetime as dt
import decimal
import hashlib
import json
import uuid
from collections.abc import Iterable, Mapping, Sequence
from typing import Any

#: A versão da codificação canônica. Sobe quando a forma de qualquer valor
#: muda — e o manifesto que a gravou deixa de ser comparável com a nova.
FORMATO = 2

#: Separa as linhas canônicas dentro do digest. Nunca aparece dentro de uma
#: linha: o JSON escapa todo caractere de controle.
ENTRE_LINHAS = "\n"


def _numero(v: decimal.Decimal) -> str:
    if not v.is_finite():
        return str(v)
    if v == 0:
        return "0"
    return format(v.normalize(), "f")


def _codificar(v: Any) -> Any:
    """Um valor de coluna → algo que o JSON escreve sem ambiguidade de tipo."""
    if v is None or isinstance(v, (bool, int, str)):
        return v
    if isinstance(v, decimal.Decimal):
        return ["numeric", _numero(v)]
    if isinstance(v, float):
        return ["float", repr(v)]
    if isinstance(v, dt.datetime):
        if v.tzinfo is not None:
            return ["timestamptz", v.astimezone(dt.timezone.utc).isoformat()]
        return ["timestamp", v.isoformat()]
    if isinstance(v, dt.date):
        return ["date", v.isoformat()]
    if isinstance(v, dt.time):
        return ["time", v.isoformat()]
    if isinstance(v, dt.timedelta):
        return ["interval", [v.days, v.seconds, v.microseconds]]
    if isinstance(v, (bytes, bytearray, memoryview)):
        return ["bytea", bytes(v).hex()]
    if isinstance(v, uuid.UUID):
        return ["uuid", str(v)]
    if isinstance(v, (dict, list)):
        # `to_jsonb` de duas linhas iguais pode devolver as chaves em ordens
        # diferentes; ordenar aqui é o que torna o hash comparável.
        return ["json", json.dumps(v, sort_keys=True, ensure_ascii=True, default=str)]
    return [type(v).__name__, str(v)]


def linha_canonica(linha: Mapping[str, Any]) -> str:
    """Uma linha, com **todas** as colunas, tipada e em ordem estável."""
    return json.dumps(
        {coluna: _codificar(linha[coluna]) for coluna in sorted(linha)},
        sort_keys=True, ensure_ascii=True, separators=(",", ":"),
    )


def digest(linhas: Iterable[Mapping[str, Any]]) -> str:
    """O resumo canônico de um conjunto de linhas, com multiplicidade.

    A ordenação é das **linhas canônicas**, não de uma chave escolhida: assim
    o resultado não depende da ordem em que o banco devolveu, e duas linhas
    idênticas entram duas vezes.
    """
    canonicas = sorted(linha_canonica(linha) for linha in linhas)
    acumulador = hashlib.md5()  # noqa: S324 — oráculo de comparação, não de segurança
    for canonica in canonicas:
        acumulador.update(canonica.encode("utf-8"))
        acumulador.update(ENTRE_LINHAS.encode("utf-8"))
    return acumulador.hexdigest()


def nome_da_fatia(linha: Mapping[str, Any], chave: Sequence[str]) -> str:
    """A chave de uma fatia como texto — a mesma no manifesto e em toda leitura."""
    return json.dumps([_codificar(linha[c]) for c in chave], ensure_ascii=True, separators=(",", ":"))


def por_chave(
    linhas: Iterable[Mapping[str, Any]], chave: Sequence[str]
) -> dict[str, dict[str, Any]]:
    """Agrupa por chave e resume cada fatia: contagem **e** conteúdo.

    É a forma dos dois oráculos de continência do manifesto. A chave vira
    texto para que o manifesto seja JSON legível e comparável entre execuções.
    """
    grupos: dict[str, list[Mapping[str, Any]]] = {}
    for linha in linhas:
        grupos.setdefault(nome_da_fatia(linha, chave), []).append(linha)
    return {
        nome: {"linhas": len(fatia), "digest": digest(fatia)}
        for nome, fatia in sorted(grupos.items())
    }


def contido(manifesto: Mapping[str, Any], atual: Mapping[str, Any]) -> list[str]:
    """As violações de continência entre o manifesto e o estado de agora.

    **Continência, não igualdade**: depois de uma restauração a sincronização
    seguinte traz uma captura nova, que acrescenta uma fatia. Cada fatia do
    manifesto precisa reaparecer com a **mesma contagem e o mesmo digest** —
    nenhuma some, nenhuma mude de conteúdo, nenhuma seja trocada por outra do
    mesmo grupo. O acréscimo é conferido à parte, por quem sabe qual captura
    nasceu.
    """
    problemas: list[str] = []
    for chave, esperado in manifesto.items():
        encontrado = atual.get(chave)
        if encontrado is None:
            problemas.append(f"fatia sumiu: {chave!r} ({esperado['linhas']} linhas)")
            continue
        if encontrado["linhas"] != esperado["linhas"]:
            problemas.append(
                f"contagem mudou em {chave!r}: {esperado['linhas']} → {encontrado['linhas']}"
            )
        if encontrado["digest"] != esperado["digest"]:
            problemas.append(
                f"conteúdo mudou em {chave!r}: mesma chave, linhas diferentes "
                f"(contagem {encontrado['linhas']})"
            )
    return problemas


def acrescimo(manifesto: Mapping[str, Any], atual: Mapping[str, Any]) -> dict[str, Any]:
    """As fatias que existem agora e não existiam no manifesto.

    O que a restauração acrescenta é legítimo e precisa ser **nomeado**, não
    tolerado por uma comparação frouxa de totais.
    """
    return {chave: atual[chave] for chave in sorted(set(atual) - set(manifesto))}
