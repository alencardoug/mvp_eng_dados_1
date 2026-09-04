"""Cliente mínimo da API pública do Airbyte.

Existe por um motivo só: **disparar a sincronização e esperar o resultado**. A
configuração — fonte, destino e o modo de cada tabela — é declarativa e vive no
Terraform (ADR-0004); nada aqui cria nem altera recurso.

As credenciais vêm do ambiente, e o `Makefile` as obtém de
`abctl local credentials` no momento da execução. Elas não são escritas em
arquivo nenhum, versionado ou não (regra inviolável 1 do `CLAUDE.md`).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from typing import Any

BASE = os.environ.get("AIRBYTE_URL", "http://localhost:8000/api/public/v1")

#: Estados terminais de um job de sincronização.
CONCLUIDOS = {"succeeded", "failed", "cancelled", "incomplete"}


class AirbyteIndisponivel(Exception):
    """A API não respondeu, ou respondeu o que não devia."""


def _chamar(caminho: str, token: str | None = None, corpo: dict | None = None) -> Any:
    dados = json.dumps(corpo).encode() if corpo is not None else None
    req = urllib.request.Request(f"{BASE}{caminho}", data=dados, method="POST" if dados else "GET")
    req.add_header("content-type", "application/json")
    if token:
        req.add_header("authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=60) as resposta:
            return json.load(resposta)
    except urllib.error.HTTPError as erro:
        detalhe = erro.read().decode(errors="replace")[:400]
        raise AirbyteIndisponivel(f"{erro.code} em {caminho}: {detalhe}") from erro
    except urllib.error.URLError as erro:
        raise AirbyteIndisponivel(
            f"Airbyte não respondeu em {BASE}. Rode `make airbyte-up`. ({erro.reason})"
        ) from erro


def token() -> str:
    """Token de acesso a partir das credenciais do ambiente."""
    cliente = os.environ.get("AIRBYTE_CLIENT_ID")
    segredo = os.environ.get("AIRBYTE_CLIENT_SECRET")
    if not cliente or not segredo:
        raise AirbyteIndisponivel(
            "AIRBYTE_CLIENT_ID e AIRBYTE_CLIENT_SECRET ausentes. "
            "Use os alvos do Makefile, que os obtêm de `abctl local credentials`."
        )
    resposta = _chamar(
        "/applications/token", corpo={"client_id": cliente, "client_secret": segredo}
    )
    return resposta["access_token"]


def workspace(jwt: str) -> str:
    """`workspaceId` do espaço padrão criado pelo `abctl`."""
    espacos = _chamar("/workspaces", jwt).get("data", [])
    if not espacos:
        raise AirbyteIndisponivel("nenhum workspace no Airbyte")
    return espacos[0]["workspaceId"]


def conexao(nome: str, jwt: str) -> str:
    """`connection_id` pelo nome declarado no Terraform."""
    for item in _chamar("/connections", jwt).get("data", []):
        if item["name"] == nome:
            return item["connectionId"]
    raise AirbyteIndisponivel(
        f"conexão {nome!r} não existe no Airbyte. Rode `make airbyte-config`, "
        "que a cria a partir do Terraform."
    )


def sincronizar(connection_id: str, jwt: str, tipo: str = "sync") -> dict:
    return _chamar("/jobs", jwt, {"connectionId": connection_id, "jobType": tipo})


def acompanhar(job_id: int, jwt: str, intervalo: float = 15.0) -> dict:
    """Espera o job terminar, imprimindo o andamento.

    Sem espera, `make sync-airbyte` devolveria o controle antes de existir uma
    linha em `raw` — e o `dbt build` seguinte rodaria sobre o schema vazio.

    **O token é renovado a cada consulta.** O do Airbyte vale poucos minutos, e
    uma sincronização de porte dura mais que isso: reusar o mesmo token faz a
    espera morrer com `401` no meio, com o job seguindo vivo do outro lado — que
    é o pior desfecho possível, porque parece falha e não é.
    """
    while True:
        try:
            job = _chamar(f"/jobs/{job_id}", jwt)
        except AirbyteIndisponivel as erro:
            if "401" not in str(erro):
                raise
            jwt = token()
            job = _chamar(f"/jobs/{job_id}", jwt)
        estado = job.get("status", "?")
        linhas = job.get("rowsSynced") or 0
        print(f"  job {job_id}: {estado} · {linhas:,} linhas".replace(",", "."), flush=True)
        if estado in CONCLUIDOS:
            return job
        time.sleep(intervalo)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.airbyte")
    parser.add_argument("comando", choices=["sync", "reset", "status", "workspace"])
    parser.add_argument("--connection", default="oltp_para_raw")
    args = parser.parse_args(argv)

    try:
        jwt = token()
        if args.comando == "workspace":
            print(workspace(jwt))
            return 0
        connection_id = conexao(args.connection, jwt)
        if args.comando == "status":
            print(f"{args.connection}: {connection_id}")
            return 0
        # `reset` descarta o estado do cursor e o dado em `raw`, forçando a
        # próxima carga a ser completa. É o que a recarga do gerador exige: a
        # geração é determinística, então `updated_at` não muda entre execuções
        # e o incremental **não enxerga** dado regerado.
        tipo = "reset" if args.comando == "reset" else "sync"
        print(f"{args.comando} de {args.connection} ({connection_id})")
        job = acompanhar(sincronizar(connection_id, jwt, tipo)["jobId"], jwt)
    except AirbyteIndisponivel as erro:
        print(f"ERRO: {erro}", file=sys.stderr)
        return 2

    if job.get("status") != "succeeded":
        print(f"ERRO: sincronização terminou como {job.get('status')}", file=sys.stderr)
        return 1
    print(f"concluída: {job.get('rowsSynced', 0):,} linhas".replace(",", "."))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
