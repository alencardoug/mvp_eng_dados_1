"""Onde as cargas das origens deixam os registros delas, quando não é o `data/` local.

O `seed` do gerador grava `source/geracao.json`, e o do legado grava `legacy/manifesto-<hash>.json`
com o *link* `manifesto.json` — e uma recarga **encerra o diário de mutações** aberto do mesmo
lote. Os dois descrevem os bancos locais, e o pacote de recuperação os leva. Carregar outras
origens (o Cloud SQL da Etapa 13) da raiz do projeto os sobrescreveria. Com `MVP_REGISTROS_DIR`, os
registros da carga vão para essa raiz. Sem ela, nada muda.
"""

from __future__ import annotations

import os
import pathlib
from collections.abc import Mapping

ENV = "MVP_REGISTROS_DIR"


def raiz(environ: Mapping[str, str] | None = None) -> pathlib.Path | None:
    """A raiz dos registros declarada no ambiente, ou `None` para o lugar de sempre."""
    valor = ((os.environ if environ is None else environ).get(ENV) or "").strip()
    return pathlib.Path(valor) if valor else None
