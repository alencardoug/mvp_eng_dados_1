"""O *digest* do Debezium Server: o fixado no *chart* contra o vigente no quay.io (RVT-1-01).

O quay.io republica a *tag* `3.7.1.Final` toda noite (~00:50 UTC) e o manifesto anterior deixa de
existir (Registro §48). A fixação por *digest* fica (P10); o que muda é que ela vale um dia, e a
quarta começa conferindo: `vigente` segue; `trocar` diz o *digest* novo, que entra no `values.yaml`
por *commit* e no *cluster* pelo `09_aplicacoes` (1 a alterar). Só lê: nada aqui escreve.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import urllib.parse
import urllib.request

RAIZ = pathlib.Path(__file__).resolve().parents[3]
VALORES = RAIZ / "terraform" / "charts" / "debezium-server" / "values.yaml"
API = "https://quay.io/api/v1/repository/{repositorio}/tag/?"


def fixada(texto: str) -> tuple[str, str, str]:
    """`(repositório, tag, digest)` da linha `imagem:` do `values.yaml`."""
    achado = re.search(r"^imagem: quay\.io/([^:\s]+):([^@\s]+)@(sha256:[0-9a-f]{64})$", texto, re.M)
    if not achado:
        raise ValueError("values.yaml sem `imagem: quay.io/<repo>:<tag>@sha256:<64 hex>`")
    return achado.group(1), achado.group(2), achado.group(3)


def vigente(resposta: dict, tag: str) -> str:
    """O *digest* ativo da *tag* na resposta da API (`onlyActiveTags=true`); exatamente um."""
    ativas = [t for t in resposta.get("tags", []) if t.get("name") == tag and t.get("end_ts") is None]
    if len(ativas) != 1:
        raise ValueError(f"a API devolveu {len(ativas)} versões ativas da tag {tag}; nada se conclui")
    return ativas[0]["manifest_digest"]


def main() -> int:
    repositorio, tag, digest = fixada(VALORES.read_text(encoding="utf-8"))
    url = API.format(repositorio=repositorio) + urllib.parse.urlencode({"specificTag": tag, "onlyActiveTags": "true"})
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            atual = vigente(json.load(r), tag)
    except (OSError, ValueError) as erro:
        print(f"ERRO: o digest vigente de {repositorio}:{tag} não foi lido ({erro}); nada se conclui — repita")
        return 1
    if atual == digest:
        print(f"debezium: {repositorio}:{tag} vigente — {digest[:19]}… (o do values.yaml)")
        return 0
    print(f"debezium: TROCAR — o values.yaml fixa {digest[:19]}…, o quay.io serve {atual}")
    return 3


if __name__ == "__main__":
    sys.exit(main())
