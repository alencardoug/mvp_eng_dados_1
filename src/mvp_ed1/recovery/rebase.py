"""O re-base das gerações retidas do bruto legado (D52, completado pelo RV12-4-01).

`_airbyte_generation_id` é o **segundo** contador do Airbyte, e ninguém tinha
olhado para ele até a terceira rodada de revisão do plano da Etapa 12.
`captura.medir_recebido` conta como **intrusa** qualquer linha que esteja na
geração do *job* com outro `sync_id`; um Airbyte novo recomeça a geração em 1,
em cima das linhas retidas, e a primeira captura depois de uma restauração
sairia `inconsistent` com o conteúdo correto.

A saída é tirar o dado retido do caminho, não enfraquecer a conferência: as
gerações que voltaram do pacote vão para uma faixa **negativa**, e o contador
do Airbyte novo pode recomeçar onde quiser.

**"Negativo e idempotente" não basta — e o contraexemplo é do segundo ciclo.**
Depois de uma restauração o bruto tem geração `-1` antiga e `1` nova. Um
re-base que apenas negue as positivas e deixe as negativas como estão satisfaz
os dois critérios escritos e **funde as duas em `-1`**: a sonda da quarta
rodada mediu o veredito passando de `complete` a `inconsistent` **sem que o
hash mudasse** — a captura recusada com o conteúdo certo. Separar por *job*
também não serve: daria gerações distintas a linhas que originalmente
**compartilhavam** uma geração, e é nessa coincidência que uma intrusa se
esconde.

**O contrato, por tabela:**

1. **preservação da equivalência de geração** — linhas com a mesma geração
   continuam com a mesma; linhas com gerações diferentes continuam diferentes,
   inclusive perante os negativos já presentes de uma restauração anterior;
2. **faixa livre** — os valores novos são estritamente negativos e não
   encostam em nada que uma carga futura vá escrever;
3. **domínio conferido** — toda linha retida fica com geração estritamente
   negativa **e não nula**; "ausência de positivas" não serve, porque um nulo
   atravessa;
4. **idempotência** — aplicar duas vezes é aplicar uma.

A regra que satisfaz os quatro é a **normalização densa por ordem**: as `n`
gerações distintas da tabela, em ordem crescente, recebem `-n … -1`. Aplicada
a `{1…28}` dá `{-28…-1}`; aplicada de novo é identidade; e num segundo ciclo,
com `{-28…-1}` retidas e `{1, 2}` novas, dá `{-30…-1}` — trinta classes
distintas, nenhuma fundida.

A premissa, declarada: **as cargas novas escrevem em gerações não negativas.**
É o que o Airbyte faz, e é o que mantém as faixas separadas.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Any


class RebaseImpossivel(Exception):
    """A tabela não permite um re-base que preserve o contrato.

    Levantar aqui é a forma de **recuar e devolver a consequência ao Owner**,
    em vez de re-basear do jeito que der: este passo escreve no único dado que
    o pacote traz de volta.
    """


def plano(geracoes: Iterable[int | None]) -> dict[int, int]:
    """As gerações distintas de uma tabela → os valores que elas passam a ter.

    Normalização densa por ordem. Recusa nulo: uma linha sem geração não pode
    ser posta em faixa nenhuma, e fingir que pode é perder a conferência de
    intrusas justamente nela.
    """
    distintas = set()
    for g in geracoes:
        if g is None:
            raise RebaseImpossivel(
                "há linha com `_airbyte_generation_id` nulo: sem geração não há faixa, "
                "e a conferência de intrusas fica cega nessa linha. "
                "O re-base não foi aplicado."
            )
        distintas.add(int(g))
    ordenadas = sorted(distintas)
    n = len(ordenadas)
    return {g: -(n - i) for i, g in enumerate(ordenadas)}


def conforme(mapa: Mapping[int, int]) -> list[str]:
    """As violações do contrato num mapa proposto. Lista vazia é aprovação.

    Existe para que o contrato seja **conferível**, e não só descrito: é com
    ela que o teste reprova a negação ingênua, que é o que o plano admitia
    antes da quarta rodada de revisão.
    """
    problemas: list[str] = []
    if not mapa:
        return problemas

    positivas = sorted(v for v in mapa.values() if v >= 0)
    if positivas:
        problemas.append(f"valores não estritamente negativos: {positivas}")

    if len(set(mapa.values())) != len(mapa):
        fundidas = sorted(
            origem for origem, destino in mapa.items()
            if list(mapa.values()).count(destino) > 1
        )
        problemas.append(
            f"gerações distintas foram fundidas: {fundidas} caem no mesmo valor — "
            "a conferência de intrusas passa a acusar linhas legítimas"
        )

    idem = plano(mapa.values())
    movidas = {origem: idem[destino] for origem, destino in mapa.items() if idem[destino] != destino}
    if movidas:
        problemas.append(f"não é idempotente: uma segunda aplicação moveria {movidas}")

    return problemas


def dominio_valido(geracoes: Iterable[int | None]) -> list[str]:
    """O oráculo do passo, depois de aplicado: o que ainda está fora da faixa.

    Confere **estritamente negativa e não nula**, e não "nenhuma positiva" —
    a diferença é o nulo, que a segunda deixa passar.
    """
    problemas: list[str] = []
    # Materializado uma vez: um iterador seria esgotado pela contagem de nulos
    # e a busca por não negativas leria o vazio (RVE-16).
    geracoes = list(geracoes)
    nulos = sum(1 for g in geracoes if g is None)
    if nulos:
        problemas.append(f"{nulos} linha(s) com geração nula")
    fora = sorted({int(g) for g in geracoes if g is not None and g >= 0})
    if fora:
        problemas.append(f"gerações não negativas ainda no bruto retido: {fora}")
    return problemas


def assinatura(linhas: Iterable[tuple[object, int | None]]) -> dict[str, Any]:
    """A partição de uma tabela, **invariante ao re-base**: classes e digest.

    Cada linha entra como `chave=posição da sua geração na ordem crescente das
    gerações distintas`, e não com o valor da geração. O re-base é uma
    renumeração que preserva a ordem, então a assinatura de antes e a de
    depois são iguais **se e só se** as linhas continuam agrupadas do mesmo
    jeito — é o oráculo do passo 4b que o manifesto guarda (RVE-04), e que
    continua valendo depois da carga nova, restrito às linhas retidas.
    """
    import hashlib

    pares = list(linhas)
    ordem = {g: i for i, g in enumerate(sorted({g for _, g in pares if g is not None}))}
    acumulador = hashlib.md5()  # noqa: S324 — oráculo de comparação, não de segurança
    for chave, geracao in sorted(
        (str(chave), "null" if geracao is None else str(ordem[geracao])) for chave, geracao in pares
    ):
        acumulador.update(f"{chave}={geracao}\n".encode("utf-8"))
    return {
        "linhas": len(pares),
        "classes": len(ordem),
        "nulas": sum(1 for _, g in pares if g is None),
        "digest": acumulador.hexdigest(),
    }


def particao_preservada_por_assinatura(antes: Mapping[str, Any], depois: Mapping[str, Any]) -> list[str]:
    """As violações entre a assinatura de antes e a de depois do re-base."""
    problemas: list[str] = []
    if antes["linhas"] != depois["linhas"]:
        problemas.append(f"a quantidade de linhas mudou: {antes['linhas']} → {depois['linhas']}")
    if antes["classes"] != depois["classes"]:
        problemas.append(f"a quantidade de classes de geração mudou: {antes['classes']} → {depois['classes']}")
    if depois["nulas"]:
        problemas.append(f"{depois['nulas']} linha(s) com geração nula depois do re-base")
    if antes["digest"] != depois["digest"]:
        problemas.append(
            "o agrupamento das linhas mudou: há linhas que estavam juntas e ficaram "
            "separadas, ou o contrário"
        )
    return problemas


def particao(linhas: Iterable[tuple[object, int | None]]) -> dict[int | None, frozenset]:
    """Chave → geração agrupada: as classes de equivalência de uma tabela.

    O oráculo do passo 4b compara a partição **antes** e **depois**: mesma
    quantidade de classes e mesmo agrupamento das linhas. Comparar só a
    quantidade aceitaria uma permutação que trocasse duas linhas de classe.
    """
    grupos: dict[int | None, set] = {}
    for chave, geracao in linhas:
        grupos.setdefault(geracao, set()).add(chave)
    return {g: frozenset(chaves) for g, chaves in grupos.items()}


def particao_preservada(antes: Mapping, depois: Mapping) -> list[str]:
    """As violações entre duas partições. Lista vazia é aprovação."""
    problemas: list[str] = []
    if len(antes) != len(depois):
        problemas.append(
            f"a quantidade de classes de geração mudou: {len(antes)} → {len(depois)}"
        )
    classes_antes = {frozenset(c) for c in antes.values()}
    classes_depois = {frozenset(c) for c in depois.values()}
    if classes_antes != classes_depois:
        problemas.append(
            "o agrupamento das linhas mudou: há linhas que estavam juntas e ficaram "
            "separadas, ou o contrário"
        )
    return problemas
