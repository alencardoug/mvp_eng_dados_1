"""Domínio de negócio de cada objeto do dbt, declarado uma vez (Governança §5.1).

── O que é declaração e o que é derivado ───────────────────────────────────────
O domínio de cada tabela da origem é **declarado** nos modelos SQLAlchemy
(`models/base.py::table_meta`, nove domínios). Um modelo de `staging`, de
`trusted`, um snapshot ou uma tabela de `quarantine` que **conduz** uma tabela da
origem — o `stg_retail__orders` e o `orders` conduzem `orders` — pertence ao
domínio dela, e `make catalog` o escreve no `.yml` do modelo (N46 do plano do
`bi-como-codigo`). A tabela conduzida é a do nome do modelo; onde o nome não a
diz, ela está em `CONDUCTS`, que é declaração e se revisa inteira.

Pela linhagem não daria: as pontes do legado leem o JSON das quarenta tabelas, e
todo modelo que empilha herdaria os nove domínios de uma vez.

O que não conduz tabela nenhuma — as dimensões e fatos de `analytics`, as views
de `consumption`, as seeds — tem o domínio escrito à mão, pela pergunta de
negócio. Os objetos gerados por `make legacy-models` declaram o deles no
gerador. Domínio à mão num modelo que conduz uma tabela vale só com
`meta.domain_reason`, como a sensibilidade e a descrição; sem ele, o derivado o
substitui.

O `owner` não está aqui: há um só, declarado por camada no `dbt_project.yml`.
"""

from __future__ import annotations

import pathlib
from collections import defaultdict
from dataclasses import dataclass, field

from mvp_ed1.models import Base

#: As camadas em que o objeto conduz uma tabela da origem.
DERIVED_LAYERS = ("staging", "trusted", "snapshots", "quarantine")

#: Modelo → tabela da origem que ele conduz, onde o nome do modelo não a diz.
CONDUCTS: dict[str, str] = {
    "order_status_events": "order_status_history",
    "product_skus": "product_variants",
    "cart_lifecycle_events": "carts",
    "scd_customer": "customers",
    "scd_product": "products",
    "scd_coupon": "coupons",
    "scd_support_agent": "support_agents",
    "rejected_shipment_deliveries": "delivery_events",
}

#: Modelo → domínio, onde não há tabela conduzida: a infraestrutura do legado fora do
#: gerador, e o que serve a todos os domínios (`transversal`, N51).
DECLARED: dict[str, str] = {
    "legacy_selected_capture": "legado",
    # A origem da dimensão de geografia: estados e regiões servem a clientes,
    # logística e estoque, e nenhuma tabela da origem a conduz (N51).
    "geographies": "transversal",
}


def source_domains() -> dict[str, str]:
    return {t.name: t.info["domain"] for t in Base.metadata.tables.values()}


def conducted_domain(nome: str, dominios: dict[str, str]) -> str | None:
    """O domínio de um modelo que conduz uma tabela da origem; `None` se ele não conduz nenhuma."""
    if nome in DECLARED:
        return DECLARED[nome]
    tabela = CONDUCTS.get(nome, nome.removeprefix("stg_retail__"))
    return dominios.get(tabela)


@dataclass
class Domains:
    patches: dict[pathlib.Path, dict[str, str]] = field(default_factory=lambda: defaultdict(dict))   # .yml à mão → modelo → domínio
    generated: dict[str, str] = field(default_factory=dict)                                        # modelo de _derived.yml → domínio
    changes: list[str] = field(default_factory=list)


def derive_domains(manifest: dict, disco: dict) -> Domains:
    """O domínio a escrever em cada objeto de `DERIVED_LAYERS` que conduz uma tabela da origem."""
    dominios = source_domains()
    saida = Domains()
    for no in manifest["nodes"].values():
        if no["resource_type"] not in ("model", "snapshot") or no["schema"] not in DERIVED_LAYERS:
            continue
        derivado = conducted_domain(no["name"], dominios)
        entrada = disco.get(no["name"])
        if derivado is None or (entrada is not None and entrada.kind == "generator"):
            continue
        meta = entrada.meta if entrada is not None else {}
        if meta.get("domain_reason") and meta.get("domain"):
            continue                                           # exceção declarada e justificada
        if entrada is not None and entrada.kind == "hand":
            if meta.get("domain") != derivado:
                saida.patches[entrada.path][no["name"]] = derivado
                if meta.get("domain"):
                    saida.changes.append(f"{no['name']}: domínio à mão `{meta['domain']}` sem `domain_reason` trocado por `{derivado}`")
        else:
            saida.generated[no["name"]] = derivado
    return saida


def patch_domains(texto: str, entradas: dict[str, str]) -> str:
    """Insere ou atualiza `meta.domain` no nível do modelo, preservando o resto."""
    from mvp_ed1.models.sensitivity import _block_end, _find_entry, _indent
    linhas = texto.split("\n")
    for entrada, dominio in entradas.items():
        inicio = _find_entry(linhas, entrada)
        if inicio is None:
            raise KeyError(f"entrada `{entrada}` não encontrada")
        base = _indent(linhas[inicio])
        fim = _block_end(linhas, inicio, base)
        idx_meta = next((i for i in range(inicio + 1, fim) if linhas[i].strip() == "meta:" and _indent(linhas[i]) == base + 2), None)
        if idx_meta is None:
            linhas[inicio + 1:inicio + 1] = [" " * (base + 2) + "meta:", " " * (base + 4) + f"domain: {dominio}"]
            continue
        fim_meta = _block_end(linhas, idx_meta, base + 2)
        idx_dom = next((i for i in range(idx_meta + 1, fim_meta) if linhas[i].strip().startswith("domain:") and _indent(linhas[i]) == base + 4), None)
        if idx_dom is None:
            linhas.insert(idx_meta + 1, " " * (base + 4) + f"domain: {dominio}")
        else:
            linhas[idx_dom] = " " * (base + 4) + f"domain: {dominio}"
    return "\n".join(linhas)
