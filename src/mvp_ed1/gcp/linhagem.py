"""A linhagem no GCP: a paridade da captura nativa e as travessias de fora do BigQuery (Etapa 13, G5; D80).

**Por coluna, a nativa.** O BigQuery registra sozinho, na Data Lineage API, a linhagem por coluna
dos *jobs* que o dbt roda — `CREATE TABLE … AS SELECT`, `CREATE VIEW`, `MERGE`
([about-data-lineage](https://docs.cloud.google.com/dataplex/docs/about-data-lineage)). Evento
OpenLineage customizado **não** leva linhagem por coluna (mesma página). Então o que se publica
por coluna não é escrito aqui: **mede-se** (`paridade`) se a nativa contém as arestas que
`models/lineage.py` deriva do SQL compilado — a mesma leitura do Dicionário §3. A nativa é mais
larga: ela registra também a dependência de *join* e de filtro, que o módulo não conta como
origem do valor. O que se cobra é a inclusão: toda aresta de valor do módulo presente na nativa.

**Por tabela, as travessias.** O que acontece fora do BigQuery — a extração pelo Airbyte, o
caminho quente pelo Debezium Server e pelo Pub/Sub, o certificado de captura — o BigQuery não vê.
`travessias` as publica pelos recursos nativos da Data Lineage API (processo, execução, evento), uma
por tabela, das mesmas declarações que escrevem o Dicionário §3.1 (`airbyte/streams.yml`,
`streaming/fluxo.yml`). O OpenLineage não serve aqui: o *endpoint* dele recusa o espaço de nomes do
Cloud SQL. O processo é reaproveitado pelo nome e a aresta é o par origem → destino: publicar de novo
não duplica aresta.

    python -m mvp_ed1.gcp.linhagem paridade   [--saida …]
    python -m mvp_ed1.gcp.linhagem travessias [--saida …]

A captura nativa aparece em até 24 h e fica 30 dias.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import json
import os
import pathlib
import sys
import uuid
from collections import Counter
from typing import Any

import yaml

RAIZ = pathlib.Path(__file__).resolve().parents[3]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"
STREAMS = RAIZ / "airbyte" / "streams.yml"
FLUXO = RAIZ / "streaming" / "fluxo.yml"

#: A instância do Cloud SQL das duas origens (`terraform/cloud_sql.tf`).
INSTANCIA = "mvp-ed1-origens"

#: O espaço de nomes dos *jobs* das travessias no OpenLineage — o processo de cada uma é `mvp-ed1:<job>`.
NAMESPACE_DOS_JOBS = "mvp-ed1"

#: Um `runId` fixo por travessia, derivado do nome dela: republicar é a mesma execução.
_RAIZ_DOS_RUNS = uuid.UUID("6d8f0f0e-5c1b-4c4e-9a53-0e6d1a5f0b13")


def _sessao():
    import google.auth
    import google.auth.transport.requests as transporte

    cred, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    return transporte.AuthorizedSession(cred)


def _base(projeto: str, local: str) -> str:
    return f"https://datalineage.googleapis.com/v1/projects/{projeto}/locations/{local}"


# ── Paridade por coluna ──────────────────────────────────────────────────────

def arestas_do_modulo(manifest: dict) -> dict[tuple[str, str, str], set[tuple[str, str, str]]]:
    """`(dataset, relação, coluna) → folhas imediatas`, só as derivadas do SQL (`declared=False`).

    As pontes do legado declaram `meta.lineage` porque o SQL extrai de um *payload* JSON; a nativa
    vê o *payload*, não a declaração — compará-las mediria a declaração, não a captura.
    """
    from mvp_ed1.models import lineage

    modulo = lineage.build(manifest, declared=False)
    return {(schema, relacao, coluna): set(folhas)
            for (schema, relacao), colunas in modulo.leaves.items()
            for coluna, folhas in colunas.items() if folhas}


#: Alvos por consulta: a API aceita até 20 colunas da mesma tabela (`targets.entities`); uma
#: consulta por coluna estoura a cota por minuto.
ALVOS_POR_CONSULTA = 20


def _post_com_espera(sessao, url: str, corpo: dict, projeto: str) -> dict:
    """POST que espera e tenta de novo no 429 (cota por minuto), com espera crescente."""
    import time

    espera = 5.0
    for _ in range(8):
        resposta = sessao.post(url, json=corpo, headers={"x-goog-user-project": projeto})
        if resposta.status_code != 429:
            resposta.raise_for_status()
            return resposta.json()
        time.sleep(espera)
        espera = min(espera * 2, 60.0)
    resposta.raise_for_status()
    return {}


def arestas_nativas(sessao, projeto: str, local: str, dataset: str, relacao: str,
                    colunas: list[str]) -> dict[str, dict[tuple[str, str, str], list[str]]]:
    """As origens de cada coluna de uma relação na captura nativa: `coluna → {origem → tipos}`."""
    fqn_alvo = f"bigquery:{projeto}.{dataset}.{relacao}"
    saida: dict[str, dict[tuple[str, str, str], list[str]]] = {c: {} for c in colunas}
    for inicio in range(0, len(colunas), ALVOS_POR_CONSULTA):
        corpo: dict[str, Any] = {"targets": {"entities": [{"fullyQualifiedName": fqn_alvo, "field": [c]}
                                                          for c in colunas[inicio:inicio + ALVOS_POR_CONSULTA]]},
                                 "pageSize": 1000}
        while True:
            dados = _post_com_espera(sessao, f"{_base(projeto, local)}:searchLinks", corpo, projeto)
            for link in dados.get("links", []):
                fqn = link["source"]["fullyQualifiedName"]
                alvo = ".".join(link["target"].get("field") or [])
                if not fqn.startswith(f"bigquery:{projeto}.") or not link["source"].get("field") or alvo not in saida:
                    continue
                ds, tabela = fqn.removeprefix(f"bigquery:{projeto}.").split(".", 1)
                tipos = [d.get("dependencyType", "?") for d in link.get("dependencyInfo", [])] or ["?"]
                saida[alvo][(ds, tabela, ".".join(link["source"]["field"]))] = tipos
            if not dados.get("nextPageToken"):
                break
            corpo["pageToken"] = dados["nextPageToken"]
    return saida


def paridade(manifest: dict, projeto: str, local: str, *, paralelo: int = 2) -> dict[str, Any]:
    modulo = arestas_do_modulo(manifest)
    sessao = _sessao()
    por_relacao: dict[tuple[str, str], list[str]] = {}
    for dataset, relacao, coluna in modulo:
        por_relacao.setdefault((dataset, relacao), []).append(coluna)
    with concurrent.futures.ThreadPoolExecutor(max_workers=paralelo) as executor:
        respostas = dict(zip(por_relacao, executor.map(
            lambda chave: arestas_nativas(sessao, projeto, local, chave[0], chave[1], por_relacao[chave]), por_relacao)))
    nativas = {(d, r, c): respostas[(d, r)][c] for (d, r), colunas in por_relacao.items() for c in colunas}
    total = presentes = 0
    ausentes: list[str] = []
    sem_nativa: list[str] = []
    tipos_presentes: Counter = Counter()
    extras: Counter = Counter()
    for alvo, folhas in sorted(modulo.items()):
        nativa = nativas[alvo]
        if not nativa:
            sem_nativa.append(".".join(alvo))
        for folha in folhas:
            total += 1
            if folha in nativa:
                presentes += 1
                tipos_presentes.update(nativa[folha])
            else:
                ausentes.append(f"{'.'.join(alvo)} ← {'.'.join(folha)}")
        for origem, tipos in nativa.items():
            if origem not in folhas:
                extras.update(tipos)
    return {
        "colunas_comparadas": len(modulo),
        "arestas_do_modulo": total,
        "presentes_na_nativa": presentes,
        "ausentes_da_nativa": len(ausentes),
        "tipos_das_presentes": dict(tipos_presentes),
        "extras_da_nativa_por_tipo": dict(extras),
        "colunas_sem_nenhuma_aresta_nativa": len(sem_nativa),
        "amostra_ausentes": ausentes[:40],
        "amostra_sem_nativa": sem_nativa[:40],
    }


# ── Travessias por tabela ────────────────────────────────────────────────────

def travessias(projeto: str, local: str, bancos: dict[str, str]) -> list[dict[str, Any]]:
    """Uma por tabela: `{job, entradas, saídas}`, com os FQN da Data Lineage API.

    `bancos` é `{"retail": <banco da origem>, "legacy": <banco do legado>}` — os nomes do `.env`, que
    o Cloud SQL repete (`cloud_sql_origens`).
    """
    streams = yaml.safe_load(STREAMS.read_text(encoding="utf-8"))["origens"]
    fluxo = yaml.safe_load(FLUXO.read_text(encoding="utf-8"))

    def cloud_sql(origem: str, tabela: str) -> str:
        return f"cloudsql_postgresql:{projeto}.{local}.{INSTANCIA}.{bancos[origem]}.{streams[origem]['schema']}.{tabela}"

    def bigquery(dataset: str, tabela: str) -> str:
        return f"bigquery:{projeto}.{dataset}.{tabela}"

    saida = []
    for origem in ("retail", "legacy"):
        spec = streams[origem]
        nomes = spec["tabelas"] if isinstance(spec["tabelas"], list) else list(spec["tabelas"])
        for tabela in sorted(nomes):
            saida.append({"job": f"airbyte.{spec['schema']}_para_{spec['destino']}.{tabela}",
                          "entradas": [cloud_sql(origem, tabela)], "saidas": [bigquery(spec["destino"], tabela)]})
        if origem == "legacy":
            saida.append({"job": "captura.certificado",
                          "entradas": [cloud_sql("legacy", t) for t in sorted(nomes)],
                          "saidas": [bigquery("governance", "legacy_captures")]})
    topico = f"pubsub:topic:{projeto}.{fluxo['transporte']['topico_de_eventos']}"
    destino = fluxo["destino"]
    saida.append({"job": "debezium-server.inventory_movements",
                  "entradas": [cloud_sql("retail", "inventory_movements")], "saidas": [topico]})
    saida.append({"job": "beam.caminho_quente",
                  "entradas": [topico], "saidas": [bigquery(destino["schema"], destino["tabela"])]})
    return saida


def _openlineage(fqn: str) -> dict[str, str]:
    """FQN → `namespace` e `name` do OpenLineage: o mapeamento concatena os dois."""
    namespace, nome = fqn.split(":", 1)
    if namespace == "pubsub":
        tipo, resto = nome.split(":", 1)
        projeto, topico = resto.split(".", 1)
        return {"namespace": "pubsub", "name": f"{tipo}:{projeto}:{topico}"}
    return {"namespace": namespace, "name": nome}


def evento(travessia: dict[str, Any], quando: dt.datetime) -> dict[str, Any]:
    return {
        "eventType": "COMPLETE",
        "eventTime": quando.isoformat().replace("+00:00", "Z"),
        "producer": "https://github.com/alencardoug/mvp_eng_dados_1",
        "schemaURL": "https://openlineage.io/spec/2-0-2/OpenLineage.json#/definitions/RunEvent",
        "run": {"runId": str(uuid.uuid5(_RAIZ_DOS_RUNS, travessia["job"]))},
        "job": {"namespace": NAMESPACE_DOS_JOBS, "name": travessia["job"]},
        "inputs": [_openlineage(f) for f in travessia["entradas"]],
        "outputs": [_openlineage(f) for f in travessia["saidas"]],
    }


def publicar(projeto: str, local: str, lista: list[dict[str, Any]]) -> dict[str, Any]:
    """Pelos recursos nativos da API — processo, execução, evento —, e não pelo OpenLineage.

    O `processOpenLineageRunEvent` recusa o espaço de nomes do Cloud SQL ("Unrecognized input",
    medido em 07/11/2026); o FQN `cloudsql_postgresql:` é aceito pelo evento nativo. O processo é
    reaproveitado pelo nome de exibição, e uma aresta é o par origem → destino: publicar de novo
    acrescenta uma execução, não uma aresta.
    """
    sessao = _sessao()
    base = _base(projeto, local)
    cabecalho = {"x-goog-user-project": projeto}
    existentes: dict[str, str] = {}
    corpo: dict[str, Any] = {"pageSize": 100}
    while True:
        dados = sessao.get(f"{base}/processes", params=corpo, headers=cabecalho).json()
        existentes.update({p_["displayName"]: p_["name"] for p_ in dados.get("processes", [])})
        if not dados.get("nextPageToken"):
            break
        corpo["pageToken"] = dados["nextPageToken"]
    agora = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    respostas = []
    for travessia in lista:
        nome = f"{NAMESPACE_DOS_JOBS}:{travessia['job']}"
        try:
            processo = existentes.get(nome)
            if processo is None:
                r = sessao.post(f"{base}/processes", json={"displayName": nome, "attributes": {"projeto": "mvp-ed1"}},
                                headers=cabecalho)
                r.raise_for_status()
                processo = r.json()["name"]
            r = sessao.post(f"https://datalineage.googleapis.com/v1/{processo}/runs", headers=cabecalho, json={
                "displayName": travessia["job"], "state": "COMPLETED", "startTime": agora, "endTime": agora})
            r.raise_for_status()
            execucao = r.json()["name"]
            links = [{"source": {"fullyQualifiedName": e}, "target": {"fullyQualifiedName": s_}}
                     for e in travessia["entradas"] for s_ in travessia["saidas"]]
            r = sessao.post(f"https://datalineage.googleapis.com/v1/{execucao}/lineageEvents", headers=cabecalho,
                            json={"links": links, "startTime": agora, "endTime": agora})
            respostas.append({"job": travessia["job"], "status": r.status_code, "corpo": r.json() if r.content else {}})
        except Exception as erro:  # noqa: BLE001 — uma travessia que falha vira linha do relatório
            respostas.append({"job": travessia["job"], "status": getattr(getattr(erro, "response", None), "status_code", 0),
                              "corpo": str(erro)[:300]})
    return {"publicadas": sum(1 for r in respostas if r["status"] == 200), "total": len(respostas),
            "falhas": [r for r in respostas if r["status"] != 200]}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.linhagem")
    parser.add_argument("comando", choices=["paridade", "travessias"])
    parser.add_argument("--manifest", type=pathlib.Path, default=MANIFEST)
    parser.add_argument("--saida", type=pathlib.Path)
    args = parser.parse_args(argv)

    projeto, local = os.environ["GCP_PROJECT_ID"], os.environ["GCP_BQ_LOCATION"]
    if args.comando == "paridade":
        relatorio = paridade(json.loads(args.manifest.read_text(encoding="utf-8")), projeto, local)
        falhou = relatorio["ausentes_da_nativa"] > 0
    else:
        bancos = {"retail": os.environ["SOURCE_DB_NAME"], "legacy": os.environ["LEGACY_DB_NAME"]}
        relatorio = publicar(projeto, local, travessias(projeto, local, bancos))
        falhou = bool(relatorio["falhas"])
    texto = json.dumps(relatorio, ensure_ascii=False, indent=2)
    print(texto)
    if args.saida:
        args.saida.parent.mkdir(parents=True, exist_ok=True)
        args.saida.write_text(texto + "\n", encoding="utf-8")
    return 1 if falhou else 0


if __name__ == "__main__":
    sys.exit(main())
