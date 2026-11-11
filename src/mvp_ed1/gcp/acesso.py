"""O acesso por camada no BigQuery, derivado da mesma declaração do dbt (Etapa 13, G3).

No PostgreSQL, o `on-run-end` do dbt (`aplicar_acesso_por_camada`) concede o que fica acima do
objeto: o `create` no schema a quem o escreve (`meta.writers`) e o `select` nas tabelas das
fontes, que o dbt não materializa (`grants` da fonte). No BigQuery, isso é IAM de *dataset* — e
IAM é Terraform. A declaração continua uma só: este módulo lê o *manifest* e grava
`terraform/acesso.auto.tfvars.json`, que o Terraform carrega sozinho.

    python -m mvp_ed1.gcp.acesso            # regrava o arquivo
    python -m mvp_ed1.gcp.acesso --conferir # sai com 1 se o arquivo não for o que a declaração dá

O que **não** sai daqui:

- o `select` dos objetos que o dbt materializa — o `+grants`, que ele aplica objeto a objeto
  (`bigquery__apply_grants`);
- a concessão por tabela que substitui a da fonte (`raw.inventory_movements_stream`, do
  `streamer`): a tabela nasce com o caminho quente (`streaming/nuvem.py::garantir_tabela`, pelo
  `make gcp-dataflow-tabela`), e o IAM dela vai com ela, no degrau do Dataflow
  (`terraform/dataflow.tf`, que lê `pendentes_por_tabela` deste arquivo).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"
SAIDA = RAIZ / "terraform" / "acesso.auto.tfvars.json"

#: O privilégio do PostgreSQL e o papel do BigQuery que faz a mesma coisa no *dataset*.
#: `create` no schema é escrever tabelas novas e as próprias — `dataEditor`.
ESCRITA = "roles/bigquery.dataEditor"
#: Quem **materializa pelo dbt** também concede o `select` objeto a objeto (`+grants`,
#: `bigquery__apply_grants`), e isso pede `bigquery.tables.setIamPolicy`, que o `dataEditor` não
#: tem — no Composer, o `transformer` personificado parou no `dbt seed` (Registro §55, passo 9).
#: É a paridade com o PostgreSQL, onde quem cria a tabela é o dono dela e concede a leitura:
#: `dataOwner` no *dataset* que escreve, e só nele. Quem só escreve fontes (o `ingestor`, pelo
#: Airbyte e pelo livro) não concede nada por objeto e continua `dataEditor`.
DONO = "roles/bigquery.dataOwner"
LEITURA = "roles/bigquery.dataViewer"
#: Recriar uma *authorized view* (`grant_access_to`, G1.5) pede `bigquery.datasets.update` em
#: cada *dataset* que ela lê; onde quem a materializa já é `DONO`, isso vem junto. Onde não é —
#: o `raw`, aterrissagem do caminho quente que só o `ingestor` escreve —, o papel próprio
#: `mvpAutorizarViews` (`terraform/papeis.tf`: só `datasets.get` e `datasets.update`). No Composer
#: o `create or replace view` da `skus_below_reorder_point` foi negado no `raw` (Registro §55,
#: passo 9). Não é papel predefinido: o Terraform troca o nome pelo id do papel do projeto.
AUTORIZAR = "mvpAutorizarViews"


def derivar(manifest: dict) -> dict:
    escritores: dict[str, set[str]] = {}
    materializam: dict[str, set[str]] = {}
    leitores: dict[str, set[str]] = {}
    pendentes: list[dict] = []

    autorizam: dict[str, set[str]] = {}
    for no in manifest["nodes"].values():
        if no["resource_type"] not in ("model", "snapshot", "seed"):
            continue
        for papel in (no["config"].get("meta") or {}).get("writers", []):
            escritores.setdefault(no["schema"], set()).add(papel)
            materializam.setdefault(no["schema"], set()).add(papel)
            for alvo in no["config"].get("grant_access_to") or []:
                autorizam.setdefault(alvo["dataset"], set()).add(papel)

    for fonte in manifest["sources"].values():
        meta_fonte = fonte.get("source_meta") or {}
        for papel in meta_fonte.get("writers", []):
            escritores.setdefault(fonte["schema"], set()).add(papel)
        for privilegio, papeis in (meta_fonte.get("grants") or {}).items():
            if privilegio != "select":
                raise ValueError(f"privilégio de fonte sem tradução: {privilegio} ({fonte['schema']})")
            leitores.setdefault(fonte["schema"], set()).update(papeis)
        # `meta` da tabela herda o da fonte no manifest; o que difere é a substituição.
        proprio = (fonte.get("meta") or {}).get("grants")
        if proprio is not None and proprio != meta_fonte.get("grants"):
            pendentes.append({"tabela": f"{fonte['schema']}.{fonte['name']}",
                              "grants": {k: sorted(v) for k, v in sorted(proprio.items())}})

    acesso = []
    for schema, papeis in sorted(escritores.items()):
        dbt = materializam.get(schema, set())
        acesso += [{"dataset": schema, "role": DONO if p in dbt else ESCRITA, "papel": p} for p in sorted(papeis)]
    for schema, papeis in sorted(autorizam.items()):
        acesso += [{"dataset": schema, "role": AUTORIZAR, "papel": p}
                   for p in sorted(papeis - materializam.get(schema, set()))]
    for schema, papeis in sorted(leitores.items()):
        # Quem escreve já lê: dataViewer a mais seria a mesma permissão duas vezes.
        acesso += [{"dataset": schema, "role": LEITURA, "papel": p}
                   for p in sorted(papeis - escritores.get(schema, set()))]
    # JSON não tem comentário, e chave sem variável declarada vira aviso do Terraform: o "não
    # editar" está na descrição das duas variáveis (`papeis.tf`) e no teste que confere o arquivo.
    return {
        "acesso_por_dataset": acesso,
        "pendentes_por_tabela": sorted(pendentes, key=lambda x: x["tabela"]),
    }


def main(argv: list[str] | None = None) -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    args.add_argument("--conferir", action="store_true")
    opcoes = args.parse_args(argv)
    derivado = derivar(json.loads(MANIFEST.read_text(encoding="utf-8")))
    novo = json.dumps(derivado, ensure_ascii=False, indent=2) + "\n"
    if opcoes.conferir:
        atual = SAIDA.read_text(encoding="utf-8") if SAIDA.exists() else ""
        if atual != novo:
            print(f"{SAIDA.relative_to(RAIZ)} desatualizado: rode python -m mvp_ed1.gcp.acesso")
            return 1
        print(f"{SAIDA.relative_to(RAIZ)} em dia com a declaração")
        return 0
    SAIDA.write_text(novo, encoding="utf-8")
    print(f"{SAIDA.relative_to(RAIZ)}: {len(derivado['acesso_por_dataset'])} concessões por dataset, "
          f"{len(derivado['pendentes_por_tabela'])} por tabela pendentes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
