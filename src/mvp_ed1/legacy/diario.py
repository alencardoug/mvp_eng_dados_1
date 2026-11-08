"""O diário de mutações contra o intervalo e a memória: a matriz das duas capturas (ADR-0045).

As mutações na origem legada (`mutacoes.remover`, `inserir`, `alterar`) gravam no diário do
manifesto o que o banco confirmou depois do *commit*. O efeito líquido do diário
(`mutacoes.efeito_liquido`) é o esperado **independente** do SQL dos modelos: chave presente tem de
estar no intervalo (`trusted.legacy_capture_transitions`) com `rows_after > 0` e fora da memória
(`trusted.legacy_removed_records`); chave ausente, na memória, e no intervalo só como `removida`.

Até a Etapa 13 isto era um *helper* dos testes de integração, só no PostgreSQL. A §7.2 do plano o
pede na nuvem, e ele vira código: os testes o usam daqui, e o `make gcp-legado-matriz` o roda no
BigQuery. Somente leitura.

    python -m mvp_ed1.legacy.diario
"""

from __future__ import annotations

import json
import sys
from collections.abc import Callable
from typing import Any

from mvp_ed1.legacy import armazem as dialeto
from mvp_ed1.legacy import mutacoes, schema
from mvp_ed1.recovery import leitura

TRANSICOES = "trusted.legacy_capture_transitions"
MEMORIA = "trusted.legacy_removed_records"
SELECIONADA = "staging.legacy_selected_capture"
CERTIFICADO = "governance.legacy_captures"


def _todas(conexao, sql: str, parametros: dict | None = None) -> list[dict[str, Any]]:
    return list(leitura._linhas(conexao, sql, parametros))


def intervalo_e_memoria(conexao) -> tuple[dict, dict]:
    """Por `(tabela, chave)`: `(transição, rows_after)` do intervalo, e `(last_seen, removed_in)` da memória."""
    intervalo = {
        (r["source_table"], r["business_key"]): (r["transition"], r["rows_after"])
        for r in _todas(conexao, "select source_table, business_key, transition, rows_after "
                                 f"from {dialeto.nome(conexao, TRANSICOES)} where business_key is not null")
    }
    memoria = {
        (r["source_table"], r["business_key"]): (r["last_seen_snapshot_id"], r["removed_in_snapshot_id"])
        for r in _todas(conexao, "select source_table, business_key, last_seen_snapshot_id, removed_in_snapshot_id "
                                 f"from {dialeto.nome(conexao, MEMORIA)}")
    }
    return intervalo, memoria


def anterior_certificada(conexao, selecionada: int) -> int | None:
    """A certificada mais recente antes da selecionada — a mesma regra do `anterior` de `remocao.transicoes()`.

    Sai dos certificados, não da tabela auditada: intervalo vazio não prova que
    não há anterior — com anterior certificada, vazio é perda (RV10-5-01).
    """
    linhas = _todas(conexao, (
        "select max(snapshot_id) as anterior from ("
        f"  select snapshot_id from {dialeto.nome(conexao, CERTIFICADO)}"
        "  where status = 'complete' and snapshot_id < :selecionada"
        "  group by snapshot_id having count(distinct source_table) = :tabelas"
        ") certificadas"
    ), {"selecionada": int(selecionada), "tabelas": len(schema.tabelas())})
    valor = linhas[0]["anterior"] if linhas else None
    return None if valor is None else int(valor)


def faltas(efeito: dict[tuple[str, str], bool], intervalo: dict, memoria: dict) -> list[tuple]:
    """O que o efeito líquido do diário exige e os modelos não mostram.

    Chave presente: fora da memória, e **no intervalo** com `rows_after > 0` —
    em qualquer transição de multiplicidade (`mantida`, `adicionada`,
    `reduzida`, `aumentada`), porque apagar um alias com outro sobrevivente
    **é** redução (RV10-3-04). O intervalo publica também as `mantida`: chave
    presente na selecionada sempre tem linha nele, e a falta dessa linha é
    perda — não tolerância (RV10-4-01). Chave ausente: na memória, e no
    intervalo só como `removida`; fora do intervalo (`None`) é chave removida
    antes das duas últimas certificadas, e a memória sozinha responde.
    """
    achadas = []
    for (tabela, chave), presente in efeito.items():
        transicao, depois = intervalo.get((tabela, chave), (None, None))
        if presente:
            if (tabela, chave) in memoria:
                achadas.append(("presente mas na memória", tabela, chave))
            if transicao is None:
                achadas.append(("presente mas fora do intervalo", tabela, chave))
            elif not depois > 0:
                achadas.append(("presente mas removida no intervalo", tabela, chave, transicao))
        else:
            if (tabela, chave) not in memoria:
                achadas.append(("ausente e fora da memória", tabela, chave))
            if transicao is not None and transicao != "removida":
                achadas.append(("ausente mas presente no intervalo", tabela, chave, transicao))
    return achadas


def veredito(conexao, diario: list[dict], registrar: Callable[[str, Any], None] = lambda nome, valor: None) -> tuple:
    """`("passa",)`, `("salto", motivo)` ou `("falha", faltas | motivo)`.

    O salto é um valor, e não um `skip`: um salto que escapasse das contraprovas pularia a prova
    inteira em silêncio (RV10-5-01). O único legítimo é a selecionada sem anterior certificada.
    """
    linhas = _todas(conexao, f"select snapshot_id from {dialeto.nome(conexao, SELECIONADA)}")
    if len(linhas) != 1:
        return ("falha", f"{SELECIONADA} com {len(linhas)} linhas; esperava uma")
    selecionada = int(linhas[0]["snapshot_id"])
    anterior = anterior_certificada(conexao, selecionada)
    intervalo, memoria = intervalo_e_memoria(conexao)
    limites = sorted({(int(r["previous_snapshot_id"]), int(r["selected_snapshot_id"])) for r in _todas(
        conexao, f"select distinct previous_snapshot_id, selected_snapshot_id from {dialeto.nome(conexao, TRANSICOES)}")})
    if anterior is None:
        return ("salto", f"sem intervalo: a captura {selecionada} não tem anterior certificada")
    if limites not in ([], [(anterior, selecionada)]):
        return ("falha", f"o intervalo materializado não é o certificado: {limites}")
    registrar("interval", f"{anterior}->{selecionada}")
    efeito = mutacoes.efeito_liquido(diario)
    registrar("diary_entries", len(diario))
    registrar("net_absent_keys", sum(not p for p in efeito.values()))
    achadas = faltas(efeito, intervalo, memoria)
    return ("falha", achadas) if achadas else ("passa",)


def main(argv: list[str] | None = None) -> int:
    del argv
    from sqlalchemy import create_engine

    from mvp_ed1.db import LEGACY, database_url
    from mvp_ed1.legacy.cli import _manifestos

    caminho = _manifestos() / "manifesto.json"
    if not caminho.exists():
        print(f"RECUSADO: {caminho} não existe — a carga do legado deste armazém não aconteceu", file=sys.stderr)
        return 2
    diario = json.loads(caminho.resolve().read_text(encoding="utf-8")).get("mutacoes") or []
    if not diario:
        print(f"RECUSADO: o diário de {caminho} está vazio — nenhuma mutação entre as capturas", file=sys.stderr)
        return 2
    legado = create_engine(database_url(LEGACY))
    armazem = dialeto.do_ambiente(legado)
    try:
        with leitura._somente_leitura(armazem) as conexao:
            registros: dict[str, Any] = {}
            resultado = veredito(conexao, diario, lambda nome, valor: registros.__setitem__(nome, valor))
    finally:
        armazem.dispose()
        legado.dispose()
    print(f"diário: {len(diario)} mutações em {caminho}; " + ", ".join(f"{k} {v}" for k, v in registros.items()))
    if resultado[0] == "passa":
        print("matriz das duas capturas: o intervalo e a memória mostram o efeito líquido do diário")
        return 0
    if resultado[0] == "salto":
        print(f"RECUSADO: {resultado[1]}", file=sys.stderr)
        return 2
    detalhe = resultado[1] if isinstance(resultado[1], str) else "\n  ".join(map(str, resultado[1][:40]))
    print(f"FALHOU:\n  {detalhe}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
