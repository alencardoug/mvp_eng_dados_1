"""O oráculo da memória do legado — T3 da regeneração da v1.1.0.

Somente leitura, contra o livro retido (`ledger`) e, quando dado, o livro de
capturas do diário — a lista que o operador mantém das tentativas do ciclo.
Ele afirma, sobre a época corrente (runbook da regeneração no `bi-como-codigo`,
§3.3, T3; ADR-0050):

1. **toda captura que o livro guarda está intacta** — as da linha de base e as
   de cada tentativa registrada depois: por tabela, contagem, *digest* de todas
   as colunas e gerações das linhas, e as linhas do certificado iguais ao
   último registro. E cada passo de um registro ao seguinte é **uma das
   transições que o eng_dados faz** (`TRANSICOES`), com os valores delas;
   qualquer outra mudança é um campo trocado;
1b. **de novo, por conta própria**: as linhas de cada captura certificada,
   medidas outra vez por `captura.medir_recebido`, dão o `received_rows` e o
   `received_hash` do certificado dela — conferência do conteúdo de negócio,
   que (1) completa com as colunas que ela não lê;
2. **toda linha do bruto e do certificado é de uma tentativa do livro**, e cada
   tentativa tem exatamente as linhas registradas;
3. **as certificadas** são as da linha de base mais as certificadas do livro de
   capturas, cada uma acima da maior da linha de base, e a selecionada é a
   última;
4. **a quarentena**: toda fatia da linha de base contida, com contagem e
   *digest*; toda fatia de todo registro de tratamento contida como ele a
   guarda; o acréscimo da captura selecionada **exatamente** as rejeitadas da
   classificação corrente; e nada mais;
5. `governance._versions` igual à da linha de base; a memória de exclusões
   igual à dela, **mais** as remoções aceitas (N54) e **menos** as reaparições
   aceitas (N56) — as duas da comparação do H2 sobre o estado real
   (`make generation-compare MANIFESTO_ANTES=`). Uma chave da memória que a
   comparação dá como adicionada voltou à origem, e o modelo a tira por
   desenho: "sai quando a chave reaparece" (ADR-0045). Com reaparição aceita, as
   linhas que restam da linha de base se conferem **por chave**, e não por
   conteúdo: a linha de base guarda o *digest* do conjunto, e um conjunto menor
   não se compara com ele. O relatório diz isso numa nota, sem esconder.

O histórico SCD fica fora (runbook §1).
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import Any

from sqlalchemy import Engine, text

from mvp_ed1.recovery import capture_recovery, leitura, ledger, oraculos

#: Campos que nunca mudam, e os que a publicação da fase 2 escreve.
IMUTAVEIS = ("capture_attempt_id", "source_table", "connection_name", "started_at",
             "source_rows_before", "source_hash_before")
PUBLICADOS = ("source_rows_after", "source_hash_after", "received_rows", "received_hash",
              "sync_id_matches", "completed_at")
VEREDITOS = {"complete", "unstable", "incomplete", "inconsistent"}
FINAIS = VEREDITOS | {"abandoned"}


# ── As transições do eng_dados, campo a campo ────────────────────────────────
def _transicao_da_linha(x: Mapping[str, Any], y: Mapping[str, Any]) -> tuple[str, Any] | str:
    """O nome da transição de uma linha do certificado — ou o problema, em texto."""
    mudou = {campo for campo in x if x[campo] != y.get(campo)}
    if not mudou:
        return ("igual", None)
    if x["status"] in FINAIS:
        return f"linha final mudou: {sorted(mudou)}"
    if mudou & set(IMUTAVEIS):
        return f"campo imutável mudou: {sorted(mudou & set(IMUTAVEIS))}"
    if x["status"] != "pending":
        return f"estado de origem desconhecido: {x['status']}"
    if x["job_id"] is None and y["status"] == "pending" and mudou == {"job_id"}:
        return ("registrar_job", y["job_id"])
    if (x["job_id"] is not None and y["status"] in VEREDITOS and mudou <= {"status", "snapshot_id", *PUBLICADOS}
            and x["snapshot_id"] is None and all(x[c] is None and y[c] is not None for c in PUBLICADOS)):
        return ("publicar", y["snapshot_id"])
    if (x["job_id"] is None and y["status"] == "abandoned" and mudou == {"status", "completed_at"}
            and x["completed_at"] is None and y["completed_at"] is not None):
        return ("abandonar", None)
    return f"mudança fora das transições: {sorted(mudou)}"


def transition_problems(tentativa: str, antes: list[Mapping[str, Any]], depois: list[Mapping[str, Any]]) -> list[str]:
    """Os problemas de um passo entre dois registros da mesma tentativa; vazio, o passo é permitido."""
    a = {linha["source_table"]: linha for linha in antes}
    d = {linha["source_table"]: linha for linha in depois}
    if set(a) != set(d):
        return [f"tentativa {tentativa}: as tabelas do certificado mudaram entre registros"]
    problemas: list[str] = []
    tipos: set[tuple[str, Any]] = set()
    for tabela in sorted(a):
        resultado = _transicao_da_linha(a[tabela], d[tabela])
        if isinstance(resultado, str):
            problemas.append(f"tentativa {tentativa}, {tabela}: {resultado}")
        else:
            tipos.add(resultado)
    if problemas:
        return problemas
    tipos.discard(("igual", None))
    if len(tipos) > 1:
        return [f"tentativa {tentativa}: o passo mistura transições nas linhas: {sorted(map(str, tipos))}"]
    if tipos:
        nome, valor = next(iter(tipos))
        if nome == "publicar":
            job = next(iter(d.values()))["job_id"]
            recebeu = any((linha["received_rows"] or 0) > 0 for linha in d.values())
            if valor != (job if recebeu else None):
                problemas.append(f"tentativa {tentativa}: snapshot_id {valor}, e o job {job} "
                                 f"{'recebeu' if recebeu else 'não recebeu'} linhas")
        if len(tipos) == 1 and any(a[t] == d[t] for t in a):
            problemas.append(f"tentativa {tentativa}: a transição não chegou às {len(a)} linhas")
    return problemas


# ── O retrato da memória, somente leitura ────────────────────────────────────
@dataclass
class Memory:
    certificate: dict[str, list[Any]]
    captures: dict[str, dict[str, dict[str, Any]]]
    certified: list[int]
    received: dict[int, dict[str, tuple[int, str]]]
    selected: int | None
    quarantine: dict[str, dict[str, Any]] | None
    quarantine_by_table: dict[str, dict[str, dict[str, Any]]]
    classification: dict[str, Any] | None
    versions: list[str]
    deletions: dict[str, Any] | None
    deletion_rows: list[dict[str, Any]] | None = None


def _existe(conexao, relacao: str) -> bool:
    esquema, tabela = relacao.split(".")
    return tabela in leitura.tabelas_do_schema(conexao, esquema) or bool(conexao.execute(
        text("select 1 from information_schema.views where table_schema = :s and table_name = :t"),
        {"s": esquema, "t": tabela},
    ).first())


def read_memory(engine: Engine) -> Memory:
    from mvp_ed1.legacy import captura

    with ledger._read_only(engine) as conexao:
        certificado = capture_recovery._by_attempt(
            ledger.canonical_rows(leitura._linhas(conexao, f"select * from {ledger.CERTIFICATE}"))
        )
        capturas = ledger.measure_captures(conexao)
        selecionada = (conexao.execute(text("select max(snapshot_id) from staging.legacy_selected_capture")).scalar()
                       if _existe(conexao, "staging.legacy_selected_capture") else None)
        tem_quarentena = _existe(conexao, leitura.TABELA_DA_QUARENTENA)
        por_tabela: dict[str, dict[str, list[dict[str, Any]]]] = {}
        if tem_quarentena:
            for linha in leitura._linhas(conexao, f"select * from {leitura.TABELA_DA_QUARENTENA}"):
                fatia = oraculos.nome_da_fatia(linha, leitura.CHAVE_DA_QUARENTENA)
                por_tabela.setdefault(fatia, {}).setdefault(linha["source_table"], []).append(linha)
    certificadas = captura.certificadas(engine)
    return Memory(
        certificate=certificado,
        captures=capturas,
        certified=certificadas,
        received={j: {t: (r.linhas, r.hash) for t, r in captura.medir_recebido(engine, j).items()} for j in certificadas},
        selected=None if selecionada is None else int(selecionada),
        quarantine=leitura.oraculo_da_quarentena(engine) if tem_quarentena else None,
        quarantine_by_table={f: {t: {"rows": len(ls), "digest": oraculos.digest(ls)} for t, ls in sorted(ts.items())}
                             for f, ts in por_tabela.items()},
        classification=leitura.classificacao_corrente(engine),
        versions=leitura.versoes_do_armazem(engine),
        deletions=leitura.oraculo_das_exclusoes(engine),
        deletion_rows=ledger.deletion_rows(engine),
    )


# ── O oráculo ────────────────────────────────────────────────────────────────
_ORDEM = {"baseline": 0, ledger.ATTEMPT: 1, ledger.TRANSITION: 2}


def _historias(registros: list[Mapping[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    """Por tentativa, os registros em ordem: linha de base, tentativa, transição."""
    base = next(r for r in registros if r.get("kind") == "baseline")
    historias: dict[str, list[dict[str, Any]]] = {}
    for tentativa, linhas in capture_recovery._by_attempt(base["certificate"]["rows"]).items():
        job = capture_recovery._job_of(linhas)
        historias[tentativa] = [{"kind": "baseline", "taken_at": "", "rows": linhas,
                                 "raw": base["captures"].get(str(job)) if job is not None else None}]
    for r in registros:
        if r.get("kind") in (ledger.ATTEMPT, ledger.TRANSITION):
            historias.setdefault(r["capture_attempt_id"], []).append(
                {"kind": r["kind"], "taken_at": r.get("taken_at", ""), "rows": r["certificate"]["rows"],
                 "raw": r.get("raw"), "associated_job": r.get("associated_job")})
    for passos in historias.values():
        passos.sort(key=lambda p: (_ORDEM[p["kind"]], p["taken_at"]))
    return historias


def _vazia(tabelas: Iterable[str]) -> dict[str, dict[str, Any]]:
    return {t: {"rows": 0, "digest": oraculos.digest([]), "generations": []} for t in tabelas}


def _compara_bruto(nome: str, esperado: Mapping[str, Any], atual: Mapping[str, Any] | None,
                   tabelas: list[str]) -> list[str]:
    # Um job sem linha nenhuma some do retrato: vazio, nas tabelas do esperado e nas do bruto.
    agora = atual if atual is not None else _vazia(set(tabelas) | set(esperado))
    problemas = []
    for tabela in sorted(set(esperado) | set(agora)):
        e, a = esperado.get(tabela), agora.get(tabela)
        if e is None or a is None:
            # Uma tabela que o bruto não tinha: vazia dos dois lados conta como igual.
            outro = e if a is None else a
            if outro["rows"]:
                problemas.append(f"{nome}, {tabela}: {'sumiu' if a is None else 'apareceu'} com {outro['rows']} linhas")
            continue
        for campo in ("rows", "digest", "generations"):
            if e[campo] != a[campo]:
                problemas.append(f"{nome}, {tabela}: {campo} {e[campo]!r} → {a[campo]!r}")
    return problemas


def accepted_removals(comparacao: Mapping[str, Any]) -> set[tuple[str, str]]:
    """As chaves do legado que a comparação do H2 dá como removidas — as que o Owner aceitou entrar
    na memória de exclusões (N54 do plano do `bi-como-codigo`)."""
    return {
        (tabela, str(chave))
        for tabela, dados in comparacao["legacy"]["keys"].items()
        for chave in dados.get("changed", {}).get("removed", [])
    }


def accepted_reappearances(comparacao: Mapping[str, Any]) -> set[tuple[str, str]]:
    """As chaves do legado que a comparação do H2 sobre o estado real dá como adicionadas — as que
    voltam à origem. Só as que a memória de exclusões da linha de base guarda saem dela; as outras
    (uma categoria nova da árvore, por exemplo) não a tocam (N56 do plano do `bi-como-codigo`)."""
    return {
        (tabela, str(chave))
        for tabela, dados in comparacao["legacy"]["keys"].items()
        for chave in dados.get("changed", {}).get("added", [])
    }


def _deletion_problems(base: Mapping[str, Any], memoria: Memory, aceitas: set[tuple[str, str]] | None,
                       reaparecidas: set[tuple[str, str]] | None = None,
                       notas: list[str] | None = None) -> list[str]:
    if aceitas is None and reaparecidas is None:
        return ([] if "deletions" not in base or memoria.deletions == base["deletions"]
                else ["a memória de exclusões mudou desde a linha de base"])
    if base.get("deletion_keys") is None or memoria.deletion_rows is None:
        return ["mudanças aceitas dadas, e a linha de base ou o armazém não tem a memória de exclusões por chave"]
    aceitas, reaparecidas = aceitas or set(), reaparecidas or set()
    da_base = {tuple(k) for k in base["deletion_keys"]}
    saem = da_base & reaparecidas
    esperadas = (da_base - saem) | aceitas
    agora = {(str(r["source_table"]), str(r["business_key"])): r for r in memoria.deletion_rows}
    problemas = []
    if set(agora) != esperadas:
        faltam = sorted(esperadas - set(agora))
        sobram = sorted(set(agora) - esperadas)
        problemas.append(f"memória de exclusões: faltam {faltam[:5]} e sobram {sobram[:5]} "
                         f"({len(faltam)} e {len(sobram)})")
    if saem:
        if notas is not None:
            notas.append(f"memória de exclusões: {len(saem)} chave(s) da linha de base saíram por reaparição "
                         f"aceita ({sorted(saem)[:5]}); as {len(da_base - saem)} que restam conferidas por "
                         "chave, não por conteúdo — a linha de base guarda o digest do conjunto")
        return problemas
    antigas = [r for k, r in agora.items() if k in da_base]
    if base.get("deletions") and oraculos.digest(antigas) != base["deletions"]["digest"]:
        problemas.append("memória de exclusões: as linhas da linha de base mudaram")
    return problemas


def check(registros: list[Mapping[str, Any]], memoria: Memory,
          certificadas_do_livro: list[int] | None = None,
          remocoes_aceitas: set[tuple[str, str]] | None = None,
          reaparicoes_aceitas: set[tuple[str, str]] | None = None,
          notas: list[str] | None = None) -> list[str]:
    """Os cinco grupos de afirmações. Vazio, a memória está contida (T3).

    `notas`, quando dada, recebe o que a conferência não pôde afirmar por inteiro e
    declara — hoje, as linhas da memória de exclusões conferidas só por chave.
    """
    problemas: list[str] = []
    base = next((r for r in registros if r.get("kind") == "baseline"), None)
    if base is None:
        return ["a época não tem linha de base"]
    tabelas = sorted({t for c in base["captures"].values() for t in c} | {t for c in memoria.captures.values() for t in c})
    historias = _historias(registros)

    # (1) As capturas da linha de base, e cada tentativa registrada: intactas, e só transições do eng_dados.
    for sync_id, esperado in sorted(base["captures"].items()):
        problemas += _compara_bruto(f"captura {sync_id} da linha de base", esperado,
                                    memoria.captures.get(sync_id), tabelas)
    jobs_registrados: set[str] = set(base["captures"])
    for tentativa, passos in sorted(historias.items()):
        for anterior, seguinte in zip(passos, passos[1:]):
            problemas += transition_problems(tentativa, anterior["rows"], seguinte["rows"])
            # O bruto de um job final não muda: entre dois registros ele é o mesmo, ou
            # linhas apagadas antes da transição passariam medidas de novo no registro dela.
            if anterior.get("raw") is not None and seguinte.get("raw") is not None:
                problemas += _compara_bruto(f"tentativa {tentativa}, entre o registro {anterior['kind']} e o "
                                            f"{seguinte['kind']}", anterior["raw"], seguinte["raw"], [])
        ultimo = passos[-1]
        atual = memoria.certificate.get(tentativa)
        if atual is None:
            problemas.append(f"tentativa {tentativa}: sumiu do certificado")
        elif atual != ultimo["rows"]:
            problemas.append(f"tentativa {tentativa}: o certificado difere do último registro ({ultimo['kind']})")
        job = capture_recovery._job_of(ultimo["rows"])
        job = job if job is not None else next((p["associated_job"] for p in passos if p.get("associated_job")), None)
        if job is None or ultimo["kind"] == "baseline":
            continue
        jobs_registrados.add(str(job))
        if ultimo["raw"] is None:
            problemas.append(f"tentativa {tentativa}: o registro não mediu as linhas do job {job}")
        else:
            problemas += _compara_bruto(f"tentativa {tentativa} (job {job})", ultimo["raw"],
                                        memoria.captures.get(str(job)), tabelas)

    # (1b) Cada certificada, medida de novo pelo `medir_recebido`.
    por_snapshot = {capture_recovery._job_of(ls): ls for ls in memoria.certificate.values()
                    if {linha["status"] for linha in ls} == {"complete"}}
    for job in memoria.certified:
        linhas = {linha["source_table"]: linha for linha in por_snapshot.get(job, [])}
        for tabela, (n, h) in sorted(memoria.received.get(job, {}).items()):
            linha = linhas.get(tabela)
            if linha is None or (linha["received_rows"], linha["received_hash"]) != (n, h):
                problemas.append(f"captura {job}, {tabela}: medida de novo dá {n} linhas e {h}, o certificado "
                                 f"diz {None if linha is None else (linha['received_rows'], linha['received_hash'])}")

    # (2) Toda linha do bruto e do certificado é de uma tentativa do livro.
    for sync_id in sorted(set(memoria.captures) - jobs_registrados):
        problemas.append(f"sync_id {sync_id} do bruto sem captura da linha de base nem tentativa registrada")
    for tentativa in sorted(set(memoria.certificate) - set(historias)):
        problemas.append(f"tentativa {tentativa} do certificado sem registro no livro")

    # (3) As certificadas: as da linha de base mais as do livro de capturas; a selecionada é a última.
    def certificadas(passos_por_tentativa, so_da_base: bool) -> set[int]:
        saida = set()
        for passos in passos_por_tentativa.values():
            escolhido = passos[0] if so_da_base else passos[-1]
            if (escolhido["kind"] == "baseline") is not so_da_base:
                continue
            ls = escolhido["rows"]
            if ls and {linha["status"] for linha in ls} == {"complete"} and ls[0].get("snapshot_id") is not None:
                saida.add(int(ls[0]["snapshot_id"]))
        return saida

    da_base = certificadas(historias, so_da_base=True)
    novas = (sorted(certificadas_do_livro) if certificadas_do_livro is not None
             else sorted(certificadas({t: p for t, p in historias.items() if p[0]["kind"] != "baseline"},
                                      so_da_base=False)))
    acima = [j for j in novas if da_base and j <= max(da_base)]
    if acima:
        problemas.append(f"capturas novas não acima da maior da linha de base ({max(da_base)}): {acima}")
    esperadas = sorted(da_base | set(novas))
    if memoria.certified != esperadas:
        problemas.append(f"certificadas {memoria.certified}, esperadas {esperadas}")
    if esperadas and memoria.selected != esperadas[-1]:
        problemas.append(f"a selecionada é {memoria.selected}, e a última certificada é {esperadas[-1]}")

    # (4) A quarentena.
    base_q = base.get("quarantine") or {}
    atual_q = memoria.quarantine or {}
    problemas += [f"quarentena, linha de base: {p}" for p in oraculos.contido(base_q, atual_q)]
    tratadas: set[str] = set()
    for r in registros:
        if r.get("kind") != ledger.TREATMENT:
            continue
        for fatia, por_tabela in sorted(r["rejected"].items()):
            tratadas.add(fatia)
            if memoria.quarantine_by_table.get(fatia) != por_tabela:
                problemas.append(f"quarentena: a fatia {fatia} do tratamento de {r.get('taken_at')} não está "
                                 "como o registro a guarda")
    corrente = memoria.classification
    if corrente is not None:
        if memoria.selected is not None:
            tratada = sorted({leitura.snapshot_da_fatia(c) for c in corrente["tratadas"]})
            if tratada != [memoria.selected]:
                problemas.append(f"quarentena: a classificação corrente trata {tratada}, e a selecionada é "
                                 f"{memoria.selected}")
            # Toda fatia que a classificação corrente rejeita está na quarentena, com a
            # mesma contagem e o mesmo digest — seja a selecionada de depois da linha
            # de base, seja uma dela. O "nada a mais" é a conferência final, abaixo.
            da_selecionada = {c: f for c, f in atual_q.items() if leitura.snapshot_da_fatia(c) == memoria.selected}
            problemas += [f"quarentena, auditoria da selecionada: {p}"
                          for p in oraculos.contido(corrente["rejeitadas"], da_selecionada)]
        tratadas |= set(corrente["rejeitadas"])
    for fatia in sorted(set(atual_q) - set(base_q) - tratadas):
        problemas.append(f"quarentena: fatia {fatia} que nem a linha de base nem um tratamento explica")

    # (5) Versões e memória de exclusões.
    if "governance_versions" in base and memoria.versions != base["governance_versions"]:
        problemas.append(f"governance._versions mudou: {base['governance_versions']} → {memoria.versions}")
    problemas += _deletion_problems(base, memoria, remocoes_aceitas, reaparicoes_aceitas, notas)
    return problemas


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.recovery.memory_oracle",
                                     description="T3: a memória do legado contra o livro retido, somente leitura.")
    parser.add_argument("--capture-ledger", type=pathlib.Path, default=None,
                        help="o livro de capturas do diário: JSON com 'certified', os jobs certificados do ciclo")
    parser.add_argument("--accepted-removals", type=pathlib.Path, default=None,
                        help="a comparação do H2 (`make generation-compare`): as chaves removidas que o Owner aceitou")
    parser.add_argument("--accepted-reappearances", type=pathlib.Path, default=None,
                        help="a comparação do H2 sobre o estado real (`MANIFESTO_ANTES=`): as chaves que voltam à "
                             "origem e saem da memória de exclusões, que o Owner aceitou (N56)")
    parser.add_argument("--out", type=pathlib.Path, default=None)
    args = parser.parse_args(argv)

    from sqlalchemy import create_engine

    from mvp_ed1.db import WAREHOUSE, database_url
    from mvp_ed1.recovery.sources import _write, provenance

    epoca = ledger.current_epoch(ledger.root())
    do_livro = (json.loads(args.capture_ledger.read_text(encoding="utf-8"))["certified"]
                if args.capture_ledger else None)
    armazem = create_engine(database_url(WAREHOUSE))
    try:
        aceitas = (accepted_removals(json.loads(args.accepted_removals.read_text(encoding="utf-8")))
                   if args.accepted_removals else None)
        reaparecidas = (accepted_reappearances(json.loads(args.accepted_reappearances.read_text(encoding="utf-8")))
                        if args.accepted_reappearances else None)
        notas: list[str] = []
        problemas = check(ledger.records(epoca), read_memory(armazem), do_livro, aceitas, reaparecidas, notas)
    finally:
        armazem.dispose()
    relatorio = {"format": 1, "kind": "memory_oracle", "provenance": provenance(), "epoch": str(epoca),
                 "capture_ledger": None if args.capture_ledger is None else str(args.capture_ledger),
                 "accepted_removals": None if args.accepted_removals is None else str(args.accepted_removals),
                 "accepted_reappearances": (None if args.accepted_reappearances is None
                                            else str(args.accepted_reappearances)),
                 "ok": not problemas, "problems": problemas, "notes": notas}
    for problema in problemas:
        print(f"  PROBLEMA {problema}")
    for nota in notas:
        print(f"  NOTA {nota}")
    if args.capture_ledger is None:
        print("  (sem o livro de capturas do diário: as certificadas novas saem dos registros da época)")
    print(f"T3: {'memória contida' if not problemas else 'FALHOU'} · {_write(relatorio, args.out, 't3')}")
    return 0 if not problemas else 1


if __name__ == "__main__":
    sys.exit(main())
