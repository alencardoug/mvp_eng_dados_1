"""M7 a M9 refeitas sobre a geração em memória — H3 da regeneração da v1.1.0.

O plano do `bi-como-codigo` (§2) mediu três incoerências do dado sintético no
armazém de hoje, e a etapa 1.5 do mesmo plano tem por critério refazê-las
sobre o conjunto gerado em memória, já com as correções do gerador (runbook da
regeneração, H3). A etapa 1.6 as refaz no armazém, pelas sondas da D5 (H5).

* **M7 — a árvore de categorias**: cada folha que tem produto, com a raiz e a
  intermediária a que o gerador a pendurou, e quantas divergem da árvore que o
  `geracao.yml` declara (N37);
* **M8 — o preço por folha**: dos itens de pedido, contagem, média, mínimo e
  máximo de `unit_price` por folha, e quantos saem da faixa declarada (N38);
* **M9 — a venda antes do lançamento**: itens de pedido cujo produto tem
  `launched_at` posterior ao `placed_at` do pedido (N39, invariante 14).

Só a origem principal — o varejo, que é o que M8 e M9 mediram no armazém. O
legado sai do mesmo motor com outra semente e passa pelo injetor de falhas, que
move datas e preços de propósito: explicar cada violação dele pela falha que a
produziu é a sonda da D5 (H5), que lê o manifesto.

**A mesma medida dos dois lados.** O módulo lê só o que existe também no
gerador de antes das correções: sem árvore nem faixa declaradas, ele mede e
deixa a divergência em branco. Rodado sobre o gerador de antes, precisa dar os
números que M7 a M9 tiraram do armazém — é o que prova que a leitura em
memória é a mesma do armazém, antes de valer como medida do gerador corrigido.
"""

from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import statistics
from collections import Counter
from collections.abc import Mapping
from decimal import Decimal
from typing import Any

from mvp_ed1.recovery.sources import _write, provenance

#: A forma deste arquivo de medida. Sobe quando um campo muda de sentido.
FORMAT = 1


def _path_to_root(category_id: int, by_id: Mapping[int, Mapping[str, Any]]) -> list[str]:
    """Da raiz até a categoria, pelos `parent_id`."""
    path: list[str] = []
    current: Mapping[str, Any] | None = by_id[category_id]
    while current is not None:
        path.append(current["name"])
        current = by_id[current["parent_id"]] if current["parent_id"] is not None else None
    return path[::-1]


def _money(value: Decimal | float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.01")))


def realism(dados: Any, config: Any) -> dict[str, Any]:
    """M7, M8 e M9 sobre um conjunto gerado. Nenhum banco é tocado."""
    categories = {row["id"]: row for row in dados["product_categories"]}
    product = {row["id"]: row for row in dados["products"]}
    leaf_of_product = {pid: categories[row["category_id"]]["name"] for pid, row in product.items()}
    product_of_variant = {row["id"]: row["product_id"] for row in dados["product_variants"]}
    placed = {row["id"]: row["placed_at"] for row in dados["orders"]}

    # O que o YAML declara — ausente no gerador de antes das correções.
    arvore = config.tabelas["product_categories"].processo.get("arvore")
    declared: dict[str, list[str]] = {}
    if arvore:
        for root, middles in arvore.items():
            for middle, leaves in middles.items():
                for leaf in leaves:
                    declared[leaf] = [root, middle, leaf]
    ranges = config.tabelas["product_variants"].processo.get("faixa_de_preco_por_folha")

    # ── M7 ──
    paths = {}
    for pid, row in product.items():
        leaf = leaf_of_product[pid]
        paths.setdefault(leaf, _path_to_root(row["category_id"], categories))
    m7 = {
        "categories": len(categories),
        "leaves_with_products": len(paths),
        "paths": {leaf: " › ".join(path) for leaf, path in sorted(paths.items())},
        "roots": dict(sorted(Counter(path[0] for path in paths.values()).items())),
        "declared_tree": bool(declared),
        "differing_from_declared": (
            sorted(leaf for leaf, path in paths.items() if path != declared.get(leaf)) if declared else None
        ),
    }

    # ── M8 ──
    prices: dict[str, list[Decimal]] = {}
    for item in dados["order_items"]:
        prices.setdefault(leaf_of_product[product_of_variant[item["product_variant_id"]]], []).append(
            item["unit_price"]
        )
    per_leaf = {}
    for leaf, values in prices.items():
        faixa = ranges.get(leaf) if ranges else None
        outside = None
        if faixa is not None:
            low, high = Decimal(str(faixa[0])), Decimal(str(faixa[1]))
            outside = sum(not low <= v <= high for v in values)
        per_leaf[leaf] = {
            "root": paths[leaf][0],
            "items": len(values),
            "avg": _money(sum(values) / len(values)),
            "median": _money(statistics.median(values)),
            "min": _money(min(values)),
            "max": _money(max(values)),
            "declared_range": [_money(faixa[0]), _money(faixa[1])] if faixa is not None else None,
            "outside_declared": outside,
        }
    ordered = dict(sorted(per_leaf.items(), key=lambda kv: Decimal(kv[1]["avg"])))
    lowest, highest = next(iter(ordered)), next(reversed(ordered))
    all_prices = [v for values in prices.values() for v in values]
    m8 = {
        "items": len(all_prices),
        "per_leaf": ordered,
        "avg_lowest": {"leaf": lowest, "avg": ordered[lowest]["avg"]},
        "avg_highest": {"leaf": highest, "avg": ordered[highest]["avg"]},
        "overall_min": _money(min(all_prices)),
        "overall_max": _money(max(all_prices)),
        "outside_declared": sum(v["outside_declared"] for v in per_leaf.values()) if ranges else None,
    }

    # ── M9 ──
    launched = {pid: row["launched_at"] for pid, row in product.items()}
    before = 0
    unknown = 0
    for item in dados["order_items"]:
        at = launched[product_of_variant[item["product_variant_id"]]]
        if at is None:
            unknown += 1
        elif at > placed[item["order_id"]]:
            before += 1
    m9 = {
        "items": len(dados["order_items"]),
        "sold_before_launch": before,
        "launch_unknown": unknown,
        "products": len(product),
        "products_launch_unknown": sum(v is None for v in launched.values()),
    }
    return {"m7": m7, "m8": m8, "m9": m9}


def measure(
    *, seed: int | None = None, as_of: dt.date | None = None, scale: str | float | None = None
) -> dict[str, Any]:
    """Gera a origem principal em memória, com os parâmetros de `make seed-data`, e mede M7 a M9."""
    from mvp_ed1.generator import pipeline
    from mvp_ed1.generator.config import carregar
    from mvp_ed1.generator.engine import Motor

    config = carregar()
    motor = Motor(config, seed=seed, as_of_date=as_of, fator=scale)
    dados = pipeline.gerar(motor)
    return {
        "format": FORMAT,
        "kind": "realism",
        "provenance": provenance(),
        "parameters": {
            "seed": motor.seed,
            "as_of": motor.as_of_date.isoformat(),
            "scale": scale if scale is not None else config.fator_padrao,
        },
        **realism(dados, config),
    }


def _summary(report: Mapping[str, Any]) -> None:
    prov = report["provenance"]
    print(f"commit {prov['commit']}" + (" · COM ALTERAÇÕES NÃO COMMITADAS" if prov["uncommitted"] else ""))
    print(f"parâmetros {report['parameters']}")
    m7, m8, m9 = report["m7"], report["m8"], report["m9"]
    differing = m7["differing_from_declared"]
    print(f"M7  {m7['leaves_with_products']} folhas com produto, raízes {m7['roots']}; "
          f"fora da árvore declarada: {'sem árvore declarada' if differing is None else len(differing)}")
    for leaf, path in m7["paths"].items():
        print(f"      {path}")
    print(f"M8  {m8['items']:,} itens; média de R$ {m8['avg_lowest']['avg']} ({m8['avg_lowest']['leaf']}) "
          f"a R$ {m8['avg_highest']['avg']} ({m8['avg_highest']['leaf']}); de R$ {m8['overall_min']} "
          f"a R$ {m8['overall_max']}; fora da faixa declarada: "
          f"{'sem faixa declarada' if m8['outside_declared'] is None else m8['outside_declared']}")
    for leaf, row in m8["per_leaf"].items():
        faixa = row["declared_range"]
        print(f"      {leaf:<20} {row['items']:>5} itens  média {row['avg']:>9}  "
              f"[{row['min']}, {row['max']}]" + (f"  declarada [{faixa[0]}, {faixa[1]}]" if faixa else ""))
    print(f"M9  {m9['sold_before_launch']:,} de {m9['items']:,} itens vendidos antes do lançamento; "
          f"{m9['launch_unknown']:,} com lançamento desconhecido")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m mvp_ed1.recovery.realism",
        description="H3 da regeneração da v1.1.0: M7 a M9 sobre a geração em memória.",
    )
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--as-of", type=dt.date.fromisoformat, default=None)
    parser.add_argument("--scale", default=None)
    parser.add_argument("--out", type=pathlib.Path, default=None)
    args = parser.parse_args(argv)
    report = measure(seed=args.seed, as_of=args.as_of, scale=args.scale)
    _summary(report)
    print(f"medida: {_write(report, args.out, 'realismo')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
