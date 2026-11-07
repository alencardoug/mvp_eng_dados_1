"""A prova da negação por *policy tag* (Etapa 13, G4; D79).

Duas contas com o **mesmo** acesso de *dataset* a `consumption` — o `mvp-analyst` e o
`mvp-prova-sem-leitura` —, e só a primeira com o Fine-Grained Reader das *tags*. Cada uma,
personificada pela ADC do Owner, roda:

1. `count(*)` na view — não lê coluna marcada: as duas leem, e é isso que mostra que a diferença
   seguinte não é de acesso ao *dataset*;
2. a soma de `net_revenue_amount` (`confidential`) na mesma view — o `analyst` lê; a outra é
   **negada**, porque a view, autorizada ou não, carrega o controle das colunas que lê.

Depois, os registros de auditoria das duas tentativas, pela API do Cloud Logging.

    python -m mvp_ed1.gcp.prova_tags --saida data/medicoes/etapa_13/g4/prova_tags.json
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import time
from typing import Any

VIEW = "consumption.monthly_revenue_by_channel_and_category"
COLUNA_MARCADA = "net_revenue_amount"
CONTAS = ("analyst", "prova-sem-leitura")


def _cliente(projeto: str, conta: str):
    import google.auth
    from google.auth import impersonated_credentials
    from google.cloud import bigquery

    origem, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    cred = impersonated_credentials.Credentials(
        source_credentials=origem, target_principal=f"mvp-{conta}@{projeto}.iam.gserviceaccount.com",
        target_scopes=["https://www.googleapis.com/auth/cloud-platform"], lifetime=600)
    return bigquery.Client(project=projeto, credentials=cred, location=os.environ.get("GCP_BQ_LOCATION"))


def _tentar(cliente, sql: str) -> dict[str, Any]:
    from google.api_core import exceptions as gexc

    try:
        valor = next(iter(cliente.query(sql).result()))[0]
        return {"resultado": "PERMITIDO", "valor": str(valor)}
    except gexc.Forbidden as erro:
        return {"resultado": "NEGADO", "mensagem": str(erro)[:300]}


def _auditoria(projeto: str, desde: dt.datetime) -> list[dict[str, Any]]:
    """As entradas do BigQuery das duas contas desde o início da prova (registros de acesso a dados)."""
    import google.auth
    import google.auth.transport.requests as transporte

    cred, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    sessao = transporte.AuthorizedSession(cred)
    contas = " OR ".join(f'protoPayload.authenticationInfo.principalEmail="mvp-{c}@{projeto}.iam.gserviceaccount.com"'
                         for c in CONTAS)
    filtro = (f'protoPayload.serviceName="bigquery.googleapis.com" AND ({contas}) '
              f'AND timestamp>="{desde.isoformat().replace("+00:00", "Z")}"')
    resposta = sessao.post("https://logging.googleapis.com/v2/entries:list", json={
        "resourceNames": [f"projects/{projeto}"], "filter": filtro, "orderBy": "timestamp asc", "pageSize": 100,
    }, headers={"x-goog-user-project": projeto})
    resposta.raise_for_status()
    saida = []
    for e in resposta.json().get("entries", []):
        carga = e.get("protoPayload", {})
        saida.append({
            "quando": e.get("timestamp"),
            "conta": carga.get("authenticationInfo", {}).get("principalEmail"),
            "metodo": carga.get("methodName"),
            "status": carga.get("status", {}).get("code", 0),
            "mensagem": (carga.get("status", {}).get("message") or "")[:200],
        })
    return saida


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.prova_tags")
    parser.add_argument("--saida", help="grava o relatório em JSON")
    parser.add_argument("--espera-auditoria", type=int, default=90,
                        help="segundos para os registros de auditoria aparecerem")
    args = parser.parse_args(argv)

    projeto = os.environ["GCP_PROJECT_ID"]
    inicio = dt.datetime.now(dt.timezone.utc)
    alvo = f"`{projeto}.{VIEW}`"
    relatorio: dict[str, Any] = {"view": VIEW, "coluna_marcada": COLUNA_MARCADA, "contas": {}}
    for conta in CONTAS:
        cliente = _cliente(projeto, conta)
        relatorio["contas"][conta] = {
            "contagem": _tentar(cliente, f"select count(*) from {alvo}"),
            "coluna_marcada": _tentar(cliente, f"select sum({COLUNA_MARCADA}) from {alvo}"),
        }
    time.sleep(args.espera_auditoria)
    relatorio["auditoria"] = _auditoria(projeto, inicio)

    esperado = {
        "analyst": ("PERMITIDO", "PERMITIDO"),
        "prova-sem-leitura": ("PERMITIDO", "NEGADO"),
    }
    relatorio["falhas"] = [
        f"{conta}: esperado {esperado[conta]}"
        for conta, r in relatorio["contas"].items()
        if (r["contagem"]["resultado"], r["coluna_marcada"]["resultado"]) != esperado[conta]
    ]
    if not relatorio["auditoria"]:
        relatorio["falhas"].append("nenhum registro de auditoria das duas contas")
    texto = json.dumps(relatorio, ensure_ascii=False, indent=2)
    print(texto)
    if args.saida:
        os.makedirs(os.path.dirname(args.saida), exist_ok=True)
        with open(args.saida, "w", encoding="utf-8") as saida:
            saida.write(texto + "\n")
    return 1 if relatorio["falhas"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
