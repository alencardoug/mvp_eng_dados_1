"""O layout da DAG no Composer (Etapa 13, G2.4; RV13-1-06).

O *bucket* do ambiente tem duas pastas que o Composer sincroniza nos *workers*: `dags/`, que entra
no `sys.path` e é varrida pelo processador de DAGs, e `data/`, que só é montada
(`/home/airflow/gcs/data`). O que vai em cada uma está declarado aqui, uma vez, e é o mesmo que a
prova local monta e que a janela copia para o *bucket*:

* `dags/` — a DAG e o pacote `mvp_ed1` que ela importa, e um `.airflowignore` que tira o pacote da
  varredura: módulo do pacote não é arquivo de DAG, e importá-lo como tal só gastaria o *parse*;
* `data/` — o projeto dbt com os pacotes já instalados (a DAG não roda `dbt deps`) e o glossário,
  ao lado dele, porque os `docs-paths` o leem por `../docs/glossario_de_negocio`.

Nada do que o dbt ou a DAG geram vai junto: nem `target/`, nem `logs/` — a DAG os põe num
temporário por tarefa (ver `fluxo_batch.py`).

    python -m mvp_ed1.gcp.composer montar DESTINO     # monta dags/ e data/ em DESTINO
    python -m mvp_ed1.gcp.composer pacotes            # os pacotes PyPI do ambiente, um por linha
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]

#: Pasta no *bucket* → origem no repositório.
LAYOUT: dict[str, str] = {
    "dags/fluxo_batch.py": "airflow/dags/fluxo_batch.py",
    "dags/mvp_ed1": "src/mvp_ed1",
    "data/dbt": "dbt",
    "data/docs/glossario_de_negocio": "docs/glossario_de_negocio",
}

#: O que é gerado e nunca sobe: o *target* e os *logs* do dbt (os dois alvos), *bytecode*.
FORA = ("target", "target_gcp", "logs", "__pycache__", "*.pyc", ".user.yml")

AIRFLOWIGNORE = "mvp_ed1/\n"

#: A lista de pacotes PyPI do ambiente — o que a imagem não traz na versão travada.
PACOTES = RAIZ / "airflow" / "requirements-composer.txt"


def pacotes(caminho: Path = PACOTES) -> dict[str, str]:
    """`nome → especificação`, no formato do `pypi_packages` do Terraform (`"==1.12.3"`)."""
    saida = {}
    for linha in caminho.read_text(encoding="utf-8").splitlines():
        linha = linha.split("#", 1)[0].strip()
        if not linha:
            continue
        nome, versao = linha.split("==", 1)
        saida[nome.strip()] = f"=={versao.strip()}"
    return saida


def montar(destino: Path, raiz: Path = RAIZ) -> list[str]:
    """Monta `dags/` e `data/` em `destino` (que não pode existir) e devolve os caminhos montados."""
    if destino.exists():
        raise SystemExit(f"{destino} já existe: o layout se monta numa pasta nova")
    for alvo, origem in LAYOUT.items():
        de, para = raiz / origem, destino / alvo
        if not de.exists():
            raise SystemExit(f"{origem} não existe")
        para.parent.mkdir(parents=True, exist_ok=True)
        if de.is_dir():
            shutil.copytree(de, para, ignore=shutil.ignore_patterns(*FORA))
        else:
            shutil.copy2(de, para)
    if not (destino / "data/dbt/dbt_packages").is_dir():
        raise SystemExit("dbt/dbt_packages ausente: rode `make install` antes de montar")
    (destino / "dags/.airflowignore").write_text(AIRFLOWIGNORE, encoding="utf-8")
    return sorted([*LAYOUT, "dags/.airflowignore"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.composer")
    sub = parser.add_subparsers(dest="acao", required=True)
    sub.add_parser("montar").add_argument("destino", type=Path)
    sub.add_parser("pacotes")
    args = parser.parse_args(argv)
    if args.acao == "montar":
        for caminho in montar(args.destino):
            print(caminho)
    else:
        for nome, versao in pacotes().items():
            sys.stdout.write(f"{nome}{versao}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
