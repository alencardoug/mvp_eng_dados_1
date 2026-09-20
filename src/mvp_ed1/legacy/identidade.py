"""A guarda da identidade da captura — pré-condição de **disparar** o *job*.

`snapshot_id` é o `job_id` do Airbyte (ADR-0044). Um Airbyte reinstalado
recomeça o contador em 1, e o pacote de recuperação retém capturas 9–43: a
primeira sincronização depois de uma restauração reusaria uma identidade já
certificada, e a captura 43 passaria a ler duas linhas onde havia uma.

**Por que antes do disparo, e não na certificação (RV12-3-04).** A revisão 4
punha a guarda em `captura.decidir`, que roda na fase 2 — depois de o Airbyte
ter terminado o *append*. Recusar ali não desfaz nada: as linhas do *job*
reutilizado já estão no bruto e o certificado antigo continua elegível. A
guarda em `decidir` **continua existindo** como rede, mas o que ela faz é
**recusar o certificado**; ela não protege retroativamente o bruto.

**Por que em todo ponto de entrada, e não só no fluxo certificado
(RV12-4-03).** A revisão 5 punha a pré-condição junto da fase 1. A sonda da
quarta rodada de revisão mostrou duas entradas que passam ao largo dela:
`python -m mvp_ed1.airbyte sync --connection legacy_para_raw_legacy`, **sem**
`--certificar-legado`, chega ao `POST /jobs` pelo ramo direto do `main`, e a
mesma CLI aceita `reset` para essa conexão. Nesses caminhos `decidir` nem é
chamado. Este módulo é o dono único da pré-condição, e quem dispara a conexão
legada passa por aqui — CLI, DAG e `sincronizar_certificando`.

**O contador é compartilhado.** O `jobId` do Airbyte atende a conexão
principal e os *resets* também, e não avança de um em um para a conexão
legada. Por isso a pergunta não é "qual é o próximo job desta conexão", e sim
"o contador do Airbyte já passou do maior `snapshot_id` certificado" — se
passou, nenhuma identidade nova colide; se não passou, colide e o *job* não
nasce.
"""

from __future__ import annotations

from typing import Any, Callable

from sqlalchemy import Engine

from mvp_ed1.legacy import captura

#: A conexão cuja identidade é a identidade da captura (ADR-0044).
CONEXAO_LEGADA = "legacy_para_raw_legacy"


class IdentidadeReutilizada(Exception):
    """O contador do Airbyte ainda não passou do que o armazém já certificou."""


class ResetDoLegadoRecusado(Exception):
    """`reset` da conexão legada descarta o bruto retido — e ele é memória."""


def maior_job_conhecido(listar: Callable[[], Any]) -> int | None:
    """O maior `jobId` que o Airbyte conhece, de qualquer conexão.

    `None` quando o Airbyte não tem *job* nenhum — instalação recém-criada,
    que é exatamente o caso perigoso.
    """
    dados = (listar() or {}).get("data", [])
    ids = [int(item["jobId"]) for item in dados if item.get("jobId") is not None]
    return max(ids) if ids else None


def conferir(armazem: Engine, listar: Callable[[], Any]) -> tuple[int | None, int | None]:
    """Devolve `(maior job do Airbyte, maior snapshot certificado)`.

    Separada de `exigir` para que a mensagem de recusa e o teste vejam os dois
    números, em vez de um booleano que não explica nada.
    """
    certificadas = captura.certificadas(armazem)
    return maior_job_conhecido(listar), (max(certificadas) if certificadas else None)


def exigir(armazem: Engine, listar: Callable[[], Any]) -> None:
    """Pré-condição de disparar a conexão legada. Levanta, ou devolve `None`.

    Sem captura certificada não há identidade a proteger, e a guarda libera —
    é o estado de um armazém novo, em que a primeira captura pode ser o *job* 1.
    """
    maior_job, maior_snapshot = conferir(armazem, listar)
    if maior_snapshot is None:
        return
    if maior_job is not None and maior_job >= maior_snapshot:
        return
    atual = "nenhum job" if maior_job is None else f"o maior job é {maior_job}"
    raise IdentidadeReutilizada(
        f"identidade reutilizada ou retrocedida: o armazém tem a captura "
        f"{maior_snapshot} certificada e, no Airbyte, {atual}. "
        f"O próximo job nasceria com identidade já usada, e o bruto retido "
        f"passaria a misturar duas capturas sob o mesmo `snapshot_id`.\n"
        f"  Numa instalação nova do Airbyte, avance a sequência de jobs para "
        f"{maior_snapshot + 1} antes de sincronizar (D50, plano da Etapa 12 §6).\n"
        f"  O job NÃO foi disparado."
    )


def recusar_reset(conexao: str) -> None:
    """`reset` da conexão legada é incompatível com a retenção do bruto.

    O `reset` descarta o dado em `raw_legacy` e o cursor. Para a conexão
    principal isso é rotina — a recarga do gerador depende dele. Para a legada,
    o bruto **é** a memória das capturas retidas: as 40 tabelas de cada
    `snapshot_id` certificado, de onde a memória de exclusões renasce
    (ADR-0045). Descartá-lo não tem volta pelo Airbyte.
    """
    if conexao != CONEXAO_LEGADA:
        return
    raise ResetDoLegadoRecusado(
        f"`reset` de {CONEXAO_LEGADA!r} descartaria o bruto retido em `raw_legacy`, "
        "que é memória das capturas certificadas (ADR-0037/0044/0045) e de onde a "
        "memória de exclusões renasce.\n"
        "  Se é mesmo isso que você quer, faça o pacote de recuperação primeiro "
        "(`make recovery-pack`) e execute o reset à mão, registrando a decisão.\n"
        "  O job NÃO foi disparado."
    )
