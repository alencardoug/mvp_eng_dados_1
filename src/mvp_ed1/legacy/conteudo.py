"""Identidade de conteúdo de uma tabela do legado — a mesma função para os três lados.

O manifesto descreve um lote; `legacy_db` recebe o lote; `raw_legacy` recebe uma
captura dele. Dizer que os três são **o mesmo** conjunto exige uma medida que os
três possam calcular sobre o que têm, e que não dependa de contagem nem de
identidade renumerável (`legacy_row_id` recomeça em 1 a cada geração — contagem
e conjunto de identidades iguais não provam conteúdo igual; achado P18 da
revisão do plano, 14/09/2026).

A medida é um `md5` sobre a **serialização canônica** de todas as linhas da
tabela, em ordem de `legacy_row_id`: para cada linha, um vetor JSON com a
identidade física e as colunas de negócio na ordem declarada em `schema`. Duas
normalizações, e só duas, ambas declaradas:

* **string vazia é nulo.** O destino do Airbyte entrega `''` como `NULL`
  (medido em 05/09 e reproduzido em 14/09: seis células vazias na origem chegam
  nulas ao bruto, e com esta normalização origem e bruto coincidem em 40/40
  tabelas). Sem ela a comparação origem × captura falharia por um efeito de
  transporte que não é perda de dado;
* **`legacy_row_id` é inteiro**, o resto é texto — o legado é todo `text`, então
  não há tipo a canonizar além desse.

Quem consome: o `writer` (hash do que foi gerado e do que o `COPY` deixou no
banco), o registro de captura do R09 (origem antes e depois do *job*, bruto por
geração) e os testes de integração, que recusam comparar vereditos com uma
captura cujo conteúdo não seja o do manifesto.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Iterable, Mapping
from typing import Any

from sqlalchemy import Connection, text

from mvp_ed1.legacy import schema


def _celula(valor: Any) -> str | None:
    if valor is None:
        return None
    texto = str(valor)
    return None if texto == "" else texto


def linha_canonica(tabela: str, linha: Mapping[str, Any]) -> str:
    """A serialização de **uma** linha: `[legacy_row_id, col_1, …, col_n]`."""
    vetor: list[Any] = [int(linha[schema.IDENTIDADE])]
    vetor.extend(_celula(linha.get(coluna)) for coluna in schema.colunas(tabela))
    return json.dumps(vetor, ensure_ascii=False, separators=(",", ":"))


def hash_de_tabela(tabela: str, linhas: Iterable[Mapping[str, Any]]) -> dict[str, Any]:
    """`{"linhas": n, "hash": md5}` do conteúdo de uma tabela, na ordem física."""
    ordenadas = sorted(linhas, key=lambda linha: int(linha[schema.IDENTIDADE]))
    resumo = hashlib.md5()
    for indice, linha in enumerate(ordenadas):
        if indice:
            resumo.update(b"\n")
        resumo.update(linha_canonica(tabela, linha).encode("utf-8"))
    return {"linhas": len(ordenadas), "hash": resumo.hexdigest()}


def hash_do_lote(linhas_por_tabela: Mapping[str, Iterable[Mapping[str, Any]]]) -> dict[str, dict[str, Any]]:
    """Uma entrada por tabela declarada — inclusive as vazias, com `linhas: 0`."""
    return {
        tabela: hash_de_tabela(tabela, linhas_por_tabela.get(tabela, ()))
        for tabela in schema.tabelas()
    }


def hash_global(por_tabela: Mapping[str, Mapping[str, Any]]) -> str:
    """Um identificador só para o lote: `md5` dos hashes por tabela, em ordem declarada."""
    resumo = hashlib.md5()
    for tabela in schema.tabelas():
        resumo.update(f"{tabela}:{por_tabela[tabela]['hash']}\n".encode("utf-8"))
    return resumo.hexdigest()


def hash_no_banco(
    conexao: Connection,
    esquema: str,
    tabela: str,
    filtro: str = "",
    parametros: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """O mesmo hash, lido de um banco — `legacy.<t>` ou `raw_legacy.<t>` com filtro de geração.

    As linhas são lidas e serializadas **em Python**, pela mesma função do
    manifesto: uma implementação, três lados. Calcular o `md5` em SQL exigiria
    provar que a serialização JSON do PostgreSQL e a do Python coincidem
    caractere a caractere, e essa prova não vale o que custa.
    """
    colunas = ", ".join(f'"{c}"' for c in (schema.IDENTIDADE, *schema.colunas(tabela)))
    consulta = f'select {colunas} from {esquema}."{tabela}"'
    if filtro:
        consulta += f" where {filtro}"
    linhas = conexao.execute(text(consulta), dict(parametros or {})).mappings().all()
    return hash_de_tabela(tabela, linhas)


def tabelas_divergentes(
    conexao: Connection,
    esquema: str,
    esperado: Mapping[str, Mapping[str, Any]],
    filtro: str = "",
    parametros: Mapping[str, Any] | None = None,
) -> list[str]:
    """As tabelas cujo conteúdo no banco **não** é o do manifesto (`lote.tabelas`).

    É a recusa de comparar: veredito só se confronta com a classificação de
    uma captura que **é** o lote do manifesto, tabela a tabela, por hash. A
    lista vazia autoriza a comparação; qualquer nome nela a recusa — nunca é
    ignorada (plano da Etapa 10, §2 item 5; contraprova (c)).
    """
    return [
        tabela
        for tabela in schema.tabelas()
        if hash_no_banco(conexao, esquema, tabela, filtro, parametros) != dict(esperado[tabela])
    ]
