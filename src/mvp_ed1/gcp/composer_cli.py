"""A leitura das respostas da CLI do Airflow pelo `gcloud composer environments run` (Etapa 13).

As receitas do `Makefile` (`COMPOSER_RODAR`, `gcp-desmonte-parar`) liam essas respostas com um
Python de uma linha que tratava resposta vazia ou inválida como "nada": uma listagem que falhou
virava "nenhuma execução em curso", e um `tasks states-for-dag-run` que falhou deixava um arquivo
vazio que a receita anunciava como os tempos da §7.2 (RV13J-1-07, RV13J-1-12). Aqui a regra é a
oposta: só se aceita o que se prova.

* **`execucoes`** — quantas execuções a listagem tem. `No data found` (o que a CLI do Airflow
  imprime para lista vazia) é zero; resposta vazia ou que não é uma lista JSON é **erro**;
* **`importacao`** — os erros de importação das DAGs; algum erro sai com 1;
* **`estado --run R`** — o estado da execução `R` na listagem, ou nada se ela ainda não aparece;
* **`tarefas --saida F`** — confere a resposta do `tasks states-for-dag-run` (lista não vazia, cada
  tarefa com `task_id` e `state`; com `--terminada`, toda tarefa com `start_date` e `end_date`, de
  onde sai a duração) e só então grava `F`. Inválida, não grava e sai com 1.

    g dags list-runs -- fluxo_batch --state running -o json | python -m mvp_ed1.gcp.composer_cli execucoes
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import sys
from typing import Any

#: O que a CLI do Airflow imprime quando a tabela pedida não tem linha (`AirflowConsole.print_as`).
SEM_DADOS = "No data found"


class RespostaInvalida(ValueError):
    pass


def _corpo(texto: str) -> Any:
    """O JSON que fecha a resposta, depois do preâmbulo de log que o Composer 3 põe no stdout.

    No Composer 3 (Airflow 3) o `gcloud composer environments run` devolve no stdout as linhas de
    log do comando (`[2026-11-11T19:16:44Z] {{…}} WARNING - …`) antes da resposta (Registro §55,
    passo 6). Aceita-se o primeiro trecho, começado numa linha com `[` ou `{`, que vai **até o fim**
    e é JSON inteiro; linha de log começada por `[` não forma JSON até o fim e é pulada. Nada que
    não se prove como JSON vira resposta.
    """
    linhas = texto.splitlines()
    if linhas[-1].strip() == SEM_DADOS:
        return []
    for i, linha in enumerate(linhas):
        if linha.lstrip()[:1] in ("[", "{"):
            try:
                return json.loads("\n".join(linhas[i:]))
            except ValueError:
                continue
    raise RespostaInvalida(f"resposta que não é JSON: {texto[:120]!r}")


def _lista(texto: str) -> list[dict[str, Any]]:
    texto = texto.strip()
    if not texto:
        raise RespostaInvalida("resposta vazia: a consulta falhou ou não respondeu")
    valor = _corpo(texto)
    if not isinstance(valor, list) or not all(isinstance(x, dict) for x in valor):
        raise RespostaInvalida(f"resposta que não é uma lista de objetos: {texto[:120]!r}")
    return valor


def erros_de_importacao(texto: str) -> list[dict[str, Any]]:
    """Os erros de importação das DAGs (`dags list-import-errors`); lista vazia é sem erro."""
    return _lista(texto)


def execucoes(texto: str) -> int:
    return len(_lista(texto))


def estado(texto: str, run_id: str) -> str:
    achadas = [x for x in _lista(texto) if x.get("run_id") == run_id]
    return str(achadas[0].get("state") or "") if achadas else ""


def _instante(valor: Any) -> dt.datetime | None:
    if not valor:
        return None
    return dt.datetime.fromisoformat(str(valor).replace("Z", "+00:00"))


def tarefas(texto: str, *, terminada: bool) -> list[dict[str, Any]]:
    """As tarefas da execução, com a duração; recusa resposta que não as tenha."""
    lista = _lista(texto)
    if not lista:
        raise RespostaInvalida("nenhuma tarefa na resposta")
    saida = []
    for t in lista:
        if not t.get("task_id") or "state" not in t:
            raise RespostaInvalida(f"tarefa sem task_id ou state: {t}")
        inicio, fim = _instante(t.get("start_date")), _instante(t.get("end_date"))
        if terminada and t.get("state") not in ("skipped", "upstream_failed") and (inicio is None or fim is None):
            raise RespostaInvalida(f"tarefa {t['task_id']} ({t.get('state')}) sem start_date ou end_date")
        saida.append({**t, "duracao_s": None if inicio is None or fim is None else (fim - inicio).total_seconds()})
    return saida


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.composer_cli", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="comando", required=True)
    sub.add_parser("execucoes")
    sub.add_parser("importacao")
    s = sub.add_parser("estado")
    s.add_argument("--run", required=True)
    s = sub.add_parser("tarefas")
    s.add_argument("--saida", type=pathlib.Path, required=True)
    s.add_argument("--terminada", action="store_true", help="toda tarefa executada tem início e fim")
    args = ap.parse_args(argv)
    texto = sys.stdin.read()
    try:
        if args.comando == "execucoes":
            print(execucoes(texto))
        elif args.comando == "importacao":
            erros = erros_de_importacao(texto)
            print("importação:", "sem erro" if not erros else erros)
            if erros:
                return 1
        elif args.comando == "estado":
            print(estado(texto, args.run))
        else:
            lista = tarefas(texto, terminada=args.terminada)
            args.saida.parent.mkdir(parents=True, exist_ok=True)
            args.saida.write_text(json.dumps(lista, ensure_ascii=False, indent=2, default=str) + "\n", encoding="utf-8")
            for t in lista:
                duracao = "—" if t["duracao_s"] is None else f"{t['duracao_s']:.0f} s"
                print(f"  {t['task_id']:<40} {t['state']:<10} {duracao}")
    except RespostaInvalida as erro:
        print(f"ERRO: {erro}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
