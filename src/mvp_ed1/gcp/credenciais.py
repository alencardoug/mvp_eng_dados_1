"""A identidade com que os clientes do Google agem: a ADC, ou uma conta de papel personificada (D81).

No Composer o ambiente tem **uma** conta, `mvp-composer`, e a DAG faz trabalho de dois papéis do
ADR-0011 — a captura do legado é do `ingestor`, o dbt é do `transformer`. A conta do ambiente não
recebe as concessões de nenhum dos dois: ela personifica a conta do papel, por token de curta
duração, e quem escreve no BigQuery e no livro é a conta do papel, como em qualquer outro lugar.

- **As tarefas Python** (captura, recuperação, portão do livro) leem `MVP_IMPERSONATE_SA` aqui;
- **o dbt** lê `MVP_DBT_IMPERSONATE_SA` no `profiles.yml` (`impersonate_service_account` do
  dbt-bigquery), uma variável à parte porque as duas correm no mesmo *worker*.

Sem a variável, `None`: o cliente usa a ADC — a do Owner nesta máquina, que é como tudo rodou até
o G2.4. Nenhuma chave existe (ADR-0025): o token sai da ADC pela API de credenciais do IAM, e a
conta de origem precisa de `iam.serviceAccountTokenCreator` na de destino (`terraform/composer.tf`).
"""

from __future__ import annotations

import os
from collections.abc import Mapping

ENV = "MVP_IMPERSONATE_SA"
ESCOPO = "https://www.googleapis.com/auth/cloud-platform"
#: Uma hora, o máximo sem a política de organização que estende; a credencial se renova sozinha
#: ao expirar, então a duração só limita o que vaza se o token vazar.
VIDA_EM_SEGUNDOS = 3600


def personificada(environ: Mapping[str, str] | None = None, variavel: str = ENV):
    """A credencial da conta na `variavel` (por padrão `MVP_IMPERSONATE_SA`), ou `None` para a ADC."""
    conta = ((os.environ if environ is None else environ).get(variavel) or "").strip()
    if not conta:
        return None
    import google.auth
    from google.auth import impersonated_credentials

    origem, _ = google.auth.default(scopes=[ESCOPO])
    return impersonated_credentials.Credentials(
        source_credentials=origem,
        target_principal=conta,
        target_scopes=[ESCOPO],
        lifetime=VIDA_EM_SEGUNDOS,
    )
