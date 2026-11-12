"""As *policy tags* nas colunas do BigQuery: convergência e inventário (Etapa 13, G4; ADR-0025, D71, D79).

A classificação é uma só — `meta.sensitivity` de cada coluna no *manifest* do dbt, a mesma que o
catálogo publica —, e a *tag* de uma coluna é função dela: `confidential` e `personal` levam a
*tag* do nível (D79); os outros níveis, nenhuma. Quem grava a *tag* depende de quem materializa a
tabela (D71):

* as tabelas do dbt são marcadas pelo próprio dbt, a cada *build*
  (`dbt/macros/descricao_no_bigquery.sql`) — substituir uma tabela apaga as *tags* dela;
* as **fontes** — `raw` e `raw_legacy`, que o Airbyte escreve; o destino do caminho quente em
  `raw`; e `governance` — são **convergidas** aqui: o fluxo do ADR-0025 depois de o YAML mudar, e
  a DAG depois de cada sincronização.

O **inventário** confere tudo, fontes e modelos, contra a classificação: é a prova do G4, repetida
depois da carga, de uma sincronização, de um *rebuild* e de uma reclassificação.

    python -m mvp_ed1.gcp.politicas convergir   [--manifest …]   # escreve só em fontes
    python -m mvp_ed1.gcp.politicas inventario  [--manifest …]   # não escreve nada

O mapa nível → *tag* vem de `MVP_POLICY_TAGS` (a saída `policy_tags` do Terraform).
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import sys
from collections.abc import Iterable, Mapping
from dataclasses import dataclass, field
from typing import Any

RAIZ = pathlib.Path(__file__).resolve().parents[3]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"
#: A conta que o fluxo das tags personifica no Composer (`terraform/composer.tf`).
ENV_POLITICAS = "MVP_POLITICAS_IMPERSONATE_SA"

#: Os níveis que viram *tag* com controle ligado (D79).
NIVEIS_MARCADOS = ("confidential", "personal")

#: Os *datasets* das tabelas que o dbt não materializa — e que só este módulo converge.
DATASETS_DAS_FONTES = ("raw", "raw_legacy", "governance")

#: Colunas técnicas que o carregador acrescenta e o *manifest* não declara: `internal`, sem *tag*.
COLUNAS_DO_CARREGADOR = ("_airbyte_raw_id", "_airbyte_extracted_at", "_airbyte_meta", "_airbyte_generation_id")


@dataclass(frozen=True)
class Tabela:
    dataset: str
    nome: str
    #: coluna → nível declarado.
    niveis: Mapping[str, str]
    #: quem a materializa: `fonte` (convergida aqui) ou `dbt`.
    dono: str


@dataclass
class Relatorio:
    tabelas: int = 0
    colunas: int = 0
    marcadas: int = 0
    trocadas: list[str] = field(default_factory=list)
    divergentes: list[str] = field(default_factory=list)
    sem_classificacao: list[str] = field(default_factory=list)
    ausentes: list[str] = field(default_factory=list)

    def como_dict(self) -> dict[str, Any]:
        return {k: v for k, v in self.__dict__.items()}


def tags_do_ambiente(environ: Mapping[str, str] | None = None) -> dict[str, str]:
    env = os.environ if environ is None else environ
    mapa = json.loads(env.get("MVP_POLICY_TAGS") or "{}")
    faltam = [n for n in NIVEIS_MARCADOS if n not in mapa]
    if faltam:
        raise SystemExit(f"MVP_POLICY_TAGS sem {', '.join(faltam)}: rode com a saída `policy_tags` do Terraform")
    return mapa


def esperado(nivel: str | None, tags: Mapping[str, str]) -> list[str]:
    """A *tag* que a coluna deve ter: a do nível, se ele é marcado; senão, nenhuma."""
    return [tags[nivel]] if nivel in NIVEIS_MARCADOS else []


def tabelas(manifest: Mapping[str, Any]) -> list[Tabela]:
    """As tabelas do armazém que levam *tag*: as fontes e os modelos materializados como tabela.

    *Views* ficam de fora: não levam *policy tag*; o controle delas é o das colunas que leem.
    """
    saida: list[Tabela] = []
    for fonte in manifest["sources"].values():
        niveis = {c: (meta.get("meta") or {}).get("sensitivity") for c, meta in fonte["columns"].items()}
        saida.append(Tabela(fonte["schema"], fonte["identifier"] or fonte["name"], niveis, "fonte"))
    for no in manifest["nodes"].values():
        if no["resource_type"] not in ("model", "snapshot", "seed"):
            continue
        if no["resource_type"] == "model" and no["config"].get("materialized") == "view":
            continue
        niveis = {c: (meta.get("meta") or {}).get("sensitivity") for c, meta in no["columns"].items()}
        saida.append(Tabela(no["schema"], no["alias"] or no["name"], niveis, "dbt"))
    return sorted(saida, key=lambda t: (t.dataset, t.nome))


def _conferir_e_corrigir(campos: Iterable, tabela: Tabela, tags: Mapping[str, str], rel: Relatorio,
                         corrigir: bool) -> tuple[list, bool]:
    from google.cloud.bigquery import SchemaField

    novos, mudou = [], False
    for campo in campos:
        rel.colunas += 1
        nivel = tabela.niveis.get(campo.name)
        if nivel is None and campo.name not in COLUNAS_DO_CARREGADOR:
            rel.sem_classificacao.append(f"{tabela.dataset}.{tabela.nome}.{campo.name}")
        atual = list(campo.policy_tags.names) if campo.policy_tags else []
        quer = esperado(nivel, tags) if campo.field_type != "RECORD" else atual
        rel.marcadas += bool(quer)
        if atual == quer:
            novos.append(campo)
            continue
        rotulo = f"{tabela.dataset}.{tabela.nome}.{campo.name}: {atual or '—'} → {quer or '—'}"
        if corrigir and tabela.dono == "fonte":
            api = campo.to_api_repr()
            api["policyTags"] = {"names": quer}
            novos.append(SchemaField.from_api_repr(api))
            rel.trocadas.append(rotulo)
            mudou = True
        else:
            rel.divergentes.append(rotulo)
            novos.append(campo)
    return novos, mudou


def percorrer(cliente, projeto: str, manifest: Mapping[str, Any], tags: Mapping[str, str], *,
              corrigir: bool, so_fontes: bool) -> Relatorio:
    """Confere cada tabela; com `corrigir`, reescreve o *schema* das **fontes** que divergem."""
    from google.api_core import exceptions as gexc

    rel = Relatorio()
    for tabela in tabelas(manifest):
        if so_fontes and tabela.dono != "fonte":
            continue
        if tabela.dono == "fonte" and tabela.dataset not in DATASETS_DAS_FONTES:
            continue
        try:
            atual = cliente.get_table(f"{projeto}.{tabela.dataset}.{tabela.nome}")
        except gexc.NotFound:
            rel.ausentes.append(f"{tabela.dataset}.{tabela.nome}")
            continue
        rel.tabelas += 1
        novos, mudou = _conferir_e_corrigir(atual.schema, tabela, tags, rel, corrigir)
        if mudou:
            atual.schema = novos
            cliente.update_table(atual, ["schema"])
    return rel


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.politicas")
    parser.add_argument("comando", choices=["convergir", "inventario"])
    parser.add_argument("--manifest", type=pathlib.Path, default=MANIFEST)
    parser.add_argument("--saida", type=pathlib.Path, help="grava o relatório em JSON")
    args = parser.parse_args(argv)

    from google.cloud import bigquery

    projeto = os.environ["GCP_PROJECT_ID"]
    tags = tags_do_ambiente()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    # No Composer, a conta do ambiente personifica a `mvp-politicas` (ADR-0025): é ela que tem o
    # `mvpVincularPolicyTags` nos datasets das fontes. Sem a variável, a ADC — o Owner, nesta máquina.
    from mvp_ed1.gcp.credenciais import personificada

    cred = personificada(variavel=ENV_POLITICAS)
    cliente = bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION"), credentials=cred)
    convergir = args.comando == "convergir"
    rel = percorrer(cliente, projeto, manifest, tags, corrigir=convergir, so_fontes=convergir)
    texto = json.dumps(rel.como_dict(), ensure_ascii=False, indent=2)
    print(texto)
    if args.saida:
        args.saida.parent.mkdir(parents=True, exist_ok=True)
        args.saida.write_text(texto + "\n", encoding="utf-8")
    # O inventário falha com qualquer divergência: é prova, não relatório. Tabela declarada que não
    # existe falha nos dois: não se inventaria nem se converge o que não está lá, e "0 divergências"
    # sobre tabelas que faltam seria aprovação do vazio (RV13J-1-06).
    for ausente in rel.ausentes:
        print(f"AUSENTE — {ausente}: declarada no manifest e inexistente no BigQuery", file=sys.stderr)
    if rel.ausentes:
        return 1
    return 1 if (not convergir and (rel.divergentes or rel.sem_classificacao)) else 0


if __name__ == "__main__":
    sys.exit(main())
