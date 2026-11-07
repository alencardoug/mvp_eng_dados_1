"""A classificação de sensibilidade nos dois alvos (Etapa 13, PLANO_etapa_13 G2.2).

O catálogo deriva a sensibilidade de cada coluna pela linhagem lida do SQL **compilado**
(`models/sensitivity.py`). No alvo `gcp` o SQL compilado é outro — o corpo BigQuery dos
modelos do legado, as metades `bigquery__` das macros —, e é dele que as *policy tags* do G4
vão sair. A prova é derivar dos dois *manifests* e comparar a classificação de **todas** as
colunas de todos os nós: diferença zero, ou cada diferença explicada.

    python -m mvp_ed1.gcp.catalogo [<manifest local> <manifest do BigQuery>]

Sai com código 1 se alguma coluna muda de nível, falta num lado, ou se a derivação do
BigQuery tem problema.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from mvp_ed1.models import sensitivity

LOCAL = sensitivity.DBT / "target" / "manifest.json"
NUVEM = sensitivity.DBT / "target_gcp" / "manifest.json"


def niveis(derivacao: sensitivity.Derivation) -> dict[tuple[str, str], str]:
    return {(no, coluna): nivel for no, colunas in derivacao.levels.items() for coluna, nivel in colunas.items()}


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    local_path, nuvem_path = (Path(args[0]), Path(args[1])) if len(args) == 2 else (LOCAL, NUVEM)
    _, local = sensitivity.load(local_path)
    nuvem = sensitivity.derive(json.loads(nuvem_path.read_text(encoding="utf-8")))
    a, b = niveis(local), niveis(nuvem)
    iguais = sum(1 for k in set(a) & set(b) if a[k] == b[k])
    mudam = sorted(k for k in set(a) & set(b) if a[k] != b[k])
    so_local, so_nuvem = sorted(set(a) - set(b)), sorted(set(b) - set(a))
    print(f"colunas: {len(a)} no local, {len(b)} no BigQuery; {iguais} com o mesmo nível")
    print(f"  mudam de nível: {len(mudam)}; só no local: {len(so_local)}; só no BigQuery: {len(so_nuvem)}")
    for k in mudam[:20]:
        print(f"    {k[0]}.{k[1]}: local {a[k]}, BigQuery {b[k]}")
    for k in so_local[:20]:
        print(f"    só no local: {k[0]}.{k[1]}")
    for k in so_nuvem[:20]:
        print(f"    só no BigQuery: {k[0]}.{k[1]}")
    print(f"  problemas da derivação no BigQuery: {len(nuvem.problems)}; avisos: {len(nuvem.warnings)}")
    for p in nuvem.problems[:20]:
        print(f"    {p}")
    return 1 if mudam or so_local or so_nuvem or nuvem.problems else 0


if __name__ == "__main__":
    sys.exit(main())
