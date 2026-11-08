"""Nenhum POST indevido: os *jobs* da conexão legada contra os registros do livro (Etapa 13, G2.1).

Todo *job* da conexão legada nasce de uma tentativa, pelo portão da CLI ou da DAG, e toda tentativa
termina registrada no livro, com o *job* dela (`job_id`) ou o que a reconciliação associou
(`associated_job`). A linha de base da época guarda os *jobs* que já existiam (`airbyte_jobs`).
Então, numa época:

* um *job* da conexão que não está na linha de base e que nenhum registro cita é um **POST
  indevido**: nasceu fora do portão (a interface, um agendamento, um reenvio);
* um *job* citado por registros de **duas** tentativas é a mesma captura contada duas vezes;
* um *job* citado no livro que o Airbyte não lista é registro de *job* que não existe.

Somente leitura: a listagem do Airbyte e os registros da época corrente.

    python -m mvp_ed1.recovery.job_audit
"""

from __future__ import annotations

import sys
from collections.abc import Iterable, Mapping
from typing import Any

from mvp_ed1.recovery import ledger


def audit(registros: Iterable[Mapping[str, Any]], jobs_da_conexao: Iterable[Mapping[str, Any]]) -> dict[str, Any]:
    """O cruzamento; `problems` vazio é "nenhum POST indevido"."""
    registros = list(registros)
    linhas_de_base = [r for r in registros if r.get("kind") == "baseline"]
    if len(linhas_de_base) != 1:
        raise ledger.LedgerError(f"a época tem {len(linhas_de_base)} linhas de base; esperava uma")
    anteriores = {int(j["id"]) for j in linhas_de_base[0].get("airbyte_jobs", [])}
    no_airbyte = {int(j["id"]) for j in jobs_da_conexao}
    por_job: dict[int, set[str]] = {}
    for registro in registros:
        if registro.get("kind") not in (ledger.ATTEMPT, ledger.TRANSITION):
            continue
        job = registro.get("job_id") if registro.get("job_id") is not None else registro.get("associated_job")
        if job is not None:
            por_job.setdefault(int(job), set()).add(str(registro["capture_attempt_id"]))
    novos = no_airbyte - anteriores
    problemas = [f"job {j} da conexão legada sem tentativa no livro (POST indevido)" for j in sorted(novos - set(por_job))]
    problemas += [f"job {j} citado por {len(t)} tentativas: {sorted(t)}" for j, t in sorted(por_job.items()) if len(t) > 1]
    problemas += [f"job {j} no livro e não no Airbyte" for j in sorted(set(por_job) - no_airbyte)]
    return {
        "jobs_before": len(anteriores),
        "jobs_since_baseline": len(novos),
        "attempts_with_job": len({t for ts in por_job.values() for t in ts}),
        "problems": problemas,
    }


def main(argv: list[str] | None = None) -> int:
    del argv
    from mvp_ed1 import airbyte
    from mvp_ed1.legacy.identidade import CONEXAO_LEGADA

    epoca = ledger.current_epoch(ledger.root())
    jwt = airbyte.token()
    listagem = (airbyte.jobs(jwt, ledger.JOBS_LISTED) or {}).get("data", [])
    if len(listagem) >= ledger.JOBS_LISTED:
        print(f"RECUSADO: a listagem do Airbyte veio cheia ({len(listagem)}); o histórico pode estar incompleto",
              file=sys.stderr)
        return 2
    relatorio = audit(ledger.records(epoca), ledger.legacy_jobs(listagem, airbyte.conexao(CONEXAO_LEGADA, jwt)))
    print(f"época {epoca}: {relatorio['jobs_since_baseline']} jobs da conexão legada desde a linha de base, "
          f"{relatorio['attempts_with_job']} tentativas com job no livro ({relatorio['jobs_before']} antes dela)")
    for problema in relatorio["problems"]:
        print(f"  PROBLEMA {problema}")
    print("nenhum POST indevido" if not relatorio["problems"] else "FALHOU")
    return 0 if not relatorio["problems"] else 1


if __name__ == "__main__":
    sys.exit(main())
