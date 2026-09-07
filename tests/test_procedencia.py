"""Junção por chave natural carrega a origem junto.

── Por que este arquivo existe ───────────────────────────────────────────────
Porque a mesma falha apareceu **seis vezes** nesta etapa, em lugares
diferentes, e nenhuma delas foi encontrada por teste: `trusted.customers`
juntando pedidos só por `customer_id`, duas invariantes cruzando remessa e
pedido, e quatro views de consumo fundindo cliente, categoria, armazém e
pedido. Todas descobertas por leitura — a última por revisão externa.

Desde o ADR-0021 a identidade de uma entidade é o par (`source_system`, id).
Casar só pelo id junta linhas de sistemas diferentes, e o resultado **não
quebra**: ele soma. Vira receita a mais, coorte a menos, custo multiplicado —
número plausível, que é o pior defeito que um armazém pode ter.

Consertar as seis não impede a sétima. Isto impede.

── O que este teste não faz ──────────────────────────────────────────────────
Não entende SQL. Ele lê o texto dos modelos e cobra que toda condição de
junção que cite uma chave natural cite também a origem. É uma heurística
sintática, e por isso pode ser enganada por SQL escrito de outro jeito — mas
casa com o estilo do projeto, e a alternativa era não ter trava nenhuma.
"""

from __future__ import annotations

import pathlib
import re

MODELOS = pathlib.Path("dbt/models")

#: Chaves naturais de dimensões **conformadas**, que legitimamente não têm
#: procedência (ADR-0039). `dim_date` nasce de série gerada, `dim_geography` de
#: conformação — São Paulo é a mesma cidade nos dois sistemas — e
#: `dim_support_category` de uma *seed*. Cobrar origem delas criaria duplicata
#: onde o projeto quer uma linha só.
SEM_PROCEDENCIA = frozenset({"support_category_natural_key"})


def condicoes_de_juncao(sql: str) -> list[tuple[int, str]]:
    """Cada condição de junção do arquivo, com a linha em que ela começa.

    Uma condição vai da linha do `on` até onde as continuações `and`/`or`
    pararem — que é como as junções deste projeto são escritas.
    """
    linhas = sql.splitlines()
    condicoes = []
    for numero, linha in enumerate(linhas, start=1):
        if not re.search(r"\bon\b", linha) or linha.lstrip().startswith("--"):
            continue
        bloco = [linha]
        for seguinte in linhas[numero:]:
            despido = seguinte.strip()
            if despido.startswith("--"):
                continue
            if re.match(r"^(and|or)\b", despido):
                bloco.append(seguinte)
                continue
            break
        condicoes.append((numero, "\n".join(bloco)))
    return condicoes


def test_juncao_por_chave_natural_carrega_a_origem() -> None:
    """Toda condição que cita chave natural cita `source_system`."""
    faltando: list[str] = []
    for arquivo in sorted(MODELOS.rglob("*.sql")):
        sql = arquivo.read_text(encoding="utf-8")
        for numero, condicao in condicoes_de_juncao(sql):
            chaves = {
                chave
                for chave in re.findall(r"\b(\w*_natural_key)\b", condicao)
                if chave not in SEM_PROCEDENCIA
            }
            if chaves and "source_system" not in condicao:
                caminho = arquivo.relative_to(MODELOS.parent.parent)
                faltando.append(f"{caminho}:{numero} — {', '.join(sorted(chaves))}")

    assert not faltando, (
        "junções por chave natural sem `source_system` — cada uma funde "
        "entidades de origens diferentes sem falhar:\n  " + "\n  ".join(faltando)
    )


def test_subconsulta_escalar_nao_procura_entidade_por_nome() -> None:
    """Procurar dimensão pelo **nome** deixou de ser possível com duas origens.

    Foi assim que a P11 quebrou: uma subconsulta escalar buscava o armazém por
    `warehouse_name`, o nome deixou de ser único, e a view — criada sem erro —
    falhava na primeira leitura com `CardinalityViolation`.

    Nome não é identidade. Com uma origem só era frágil; com duas é defeito.
    """
    suspeitas: list[str] = []
    for arquivo in sorted(MODELOS.rglob("*.sql")):
        sql = arquivo.read_text(encoding="utf-8")
        for achado in re.finditer(r"=\s*\(\s*select\s+\w*_natural_key", sql, re.I):
            # Uma janela depois do `select`, e não até o primeiro `)`: o
            # fechamento de `{{ ref(...) }}` vem antes do `where` e truncava a
            # busca — foi por isso que a primeira versão deste teste passou
            # sobre o defeito que ela existe para achar.
            janela = sql[achado.start() : achado.start() + 400]
            if re.search(r"\bwhere\b.*?_name\s*=", janela, re.S | re.I):
                linha = sql[: achado.start()].count("\n") + 1
                suspeitas.append(f"{arquivo.relative_to(MODELOS.parent.parent)}:{linha}")

    assert not suspeitas, (
        "subconsultas que procuram identidade pelo nome: " + ", ".join(suspeitas)
    )
