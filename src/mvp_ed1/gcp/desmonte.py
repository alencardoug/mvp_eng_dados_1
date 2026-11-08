"""O desmonte da janela, executável (PLANO_etapa_13 §6.5, RV13-1-02; Etapa 13, G7).

Três peças, cada uma de uma declaração só:

* **os planos do desmonte** (`PLANOS`): cada um desliga um degrau a mais sobre a janela inteira
  ligada (`JANELA`). O `VARS` sai daqui — `make gcp-plan PASSO=n` —, e não da memória de quem
  digita: um interruptor esquecido no `VARS` destrói um degrau fora de hora;
* **a guarda do plano** (`conferir_plano`): todo `make gcp-plan` passa por ela. Na construção,
  plano que destrói é recusado, salvo o Owner dizer quantos (`DESTROI=n`); no desmonte, plano que
  cria;
* **o inventário de resíduos** (`inventariar`): o que o Cloud Asset Inventory ainda lista, contra
  `residuos_esperados.yml` — o que o projeto cria por padrão, medido (Registro §30).

E uma ação: `apagar_linhagem`, os processos da Data Lineage API — os das travessias (G5) e os que o
BigQuery registra sozinho. Eles não têm `destroy`: ninguém os declarou no Terraform.

    python -m mvp_ed1.gcp.desmonte plano --passo 2
    terraform show -json P.tfplan | python -m mvp_ed1.gcp.desmonte conferir-plano --modo construcao
    python -m mvp_ed1.gcp.desmonte inventario --entrada ASSETS.json --saida RELATORIO.json
    python -m mvp_ed1.gcp.desmonte linhagem
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shlex
import sys
import time
from dataclasses import dataclass, field
from typing import Any

import yaml

ESPERADOS = pathlib.Path(__file__).with_name("residuos_esperados.yml")

#: Os degraus da janela, todos ligados (`terraform/variables.tf`): o ponto de partida do desmonte.
JANELA: dict[str, Any] = {
    "enable_cheap": True,
    "enable_cloud_sql": True,
    "enable_gke": True,
    "enable_gke_apps": True,
    "enable_dataflow": True,
    "enable_composer": True,
}


@dataclass(frozen=True)
class Plano:
    nome: str
    desliga: dict[str, Any] = field(default_factory=dict)
    #: O último: `terraform plan -destroy`, que leva o que nenhum interruptor governa (o orçamento).
    destruir: bool = False


#: Pelo passo da §6.5. Os passos sem plano são alvos do `make` (`gcp-desmonte-*`).
PLANOS: dict[int, Plano] = {
    # Passo 2: o Composer; e o IAM do Dataflow, cujo *job* o passo 1 já drenou.
    2: Plano("20_desmonte_composer", {"enable_composer": False, "enable_dataflow": False}),
    # Passos 3–4: os *releases* do Helm — o Debezium Server e o Airbyte — com o *cluster* de pé.
    3: Plano("21_desmonte_aplicacoes", {"enable_gke_apps": False}),
    5: Plano("22_desmonte_gke", {"enable_gke": False}),
    # Passos 6–7: a retenção do livro sai no mesmo `apply` que leva o Cloud SQL; os *buckets* saem
    # no passo 8, com o resto do degrau barato (o interruptor deles é o `enable_cheap`).
    7: Plano("23_desmonte_cloud_sql", {"enable_cloud_sql": False, "ledger_retention_seconds": 0}),
    8: Plano("24_desmonte_barato", {"enable_cheap": False}),
    10: Plano("25_desmonte_raiz", destruir=True),
}


def _hcl(valor: Any) -> str:
    return str(valor).lower() if isinstance(valor, bool) else str(valor)


def variaveis(passo: int) -> list[str]:
    """O `VARS` do plano do passo: a janela ligada, menos tudo que os planos até ele desligam."""
    if passo not in PLANOS:
        raise ValueError(f"o passo {passo} não tem plano; os que têm: {sorted(PLANOS)}")
    estado = dict(JANELA)
    for n in sorted(PLANOS):
        if n <= passo:
            estado.update(PLANOS[n].desliga)
    return [f"{chave}={_hcl(valor)}" for chave, valor in estado.items()]


def atribuicoes(passo: int) -> str:
    """O que o `make gcp-plan PASSO=n` avalia no shell: nome, `VARS`, modo e o `-destroy`."""
    plano = PLANOS.get(passo)
    if plano is None:
        raise ValueError(f"o passo {passo} não tem plano; os que têm: {sorted(PLANOS)}")
    return "; ".join([
        f"nome={shlex.quote(plano.nome)}",
        f"vars={shlex.quote(' '.join(variaveis(passo)))}",
        "modo=desmonte",
        f"destruir={'-destroy' if plano.destruir else ''}",
    ])


# ── A guarda do plano ────────────────────────────────────────────────────────

def acoes(plano: dict[str, Any]) -> dict[str, list[str]]:
    """Endereços por ação do `terraform show -json`; uma substituição conta como as duas."""
    por_acao: dict[str, list[str]] = {"create": [], "update": [], "delete": []}
    for mudanca in plano.get("resource_changes", []):
        for acao in mudanca["change"]["actions"]:
            if acao in por_acao:
                por_acao[acao].append(mudanca["address"])
    return por_acao


def conferir_plano(plano: dict[str, Any], modo: str, destroi: int | None = None) -> tuple[bool, str]:
    """Na construção não se destrói, salvo `destroi` igual ao que o plano destrói; no desmonte não se cria."""
    por_acao = acoes(plano)
    contagem = f"{len(por_acao['create'])} a criar, {len(por_acao['update'])} a alterar, {len(por_acao['delete'])} a destruir"
    if modo == "desmonte":
        if por_acao["create"]:
            return False, f"plano de desmonte que CRIA ({contagem}): " + ", ".join(por_acao["create"][:20])
        return True, f"desmonte: {contagem}"
    if modo != "construcao":
        raise ValueError(f"modo desconhecido: {modo}")
    if por_acao["delete"] and destroi != len(por_acao["delete"]):
        return False, (
            f"plano de construção que DESTRÓI ({contagem}): " + ", ".join(por_acao["delete"][:20])
            + ". Um interruptor faltou no VARS? Se a destruição é a intenção, leia o plano e repita "
            f"com DESTROI={len(por_acao['delete'])}; o desmonte é `make gcp-plan PASSO=n`."
        )
    return True, f"construção: {contagem}"


# ── O inventário de resíduos ─────────────────────────────────────────────────

def _esperados(caminho: pathlib.Path = ESPERADOS) -> list[dict[str, Any]]:
    regras = yaml.safe_load(caminho.read_text(encoding="utf-8"))["padrao"]
    for regra in regras:
        regra["_nome"] = re.compile(regra.get("nome", ".*"))
    return regras


def inventariar(recursos: list[dict[str, Any]], regras: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    """Cada recurso listado ou casa com uma regra do esperado, ou é resíduo."""
    regras = _esperados() if regras is None else regras
    aceitos: dict[str, int] = {}
    residuos = []
    for recurso in recursos:
        regra = next((r for r in regras
                      if r["tipo"] == recurso["assetType"] and r["_nome"].search(recurso["name"])), None)
        if regra is None:
            residuos.append({"tipo": recurso["assetType"], "nome": recurso["name"], "estado": recurso.get("state")})
        else:
            chave = f"{regra['tipo']} {regra.get('nome', '')}".strip()
            aceitos[chave] = aceitos.get(chave, 0) + 1
    return {"total": len(recursos), "aceitos": aceitos, "residuos": residuos}


# ── A linhagem ───────────────────────────────────────────────────────────────

def apagar_linhagem(projeto: str, local: str, *, tentativas: int = 20, espera: float = 15.0) -> int:
    """Apaga todo processo da Data Lineage API no local; as execuções e os eventos vão com ele.

    O `DELETE` devolve uma operação longa: em vez de esperar cada uma, a lista é refeita até vir
    vazia. Devolve quantos pedidos de exclusão foram feitos.
    """
    from mvp_ed1.gcp.linhagem import _base, _sessao

    sessao = _sessao()
    base = _base(projeto, local)
    cabecalho = {"x-goog-user-project": projeto}

    def listar() -> list[str]:
        nomes, corpo = [], {"pageSize": 100}
        while True:
            r = sessao.get(f"{base}/processes", params=corpo, headers=cabecalho)
            r.raise_for_status()
            dados = r.json()
            nomes += [p["name"] for p in dados.get("processes", [])]
            if not dados.get("nextPageToken"):
                return nomes
            corpo["pageToken"] = dados["nextPageToken"]

    pedidos = 0
    for _ in range(tentativas):
        restantes = listar()
        if not restantes:
            return pedidos
        for nome in restantes:
            r = sessao.delete(f"https://datalineage.googleapis.com/v1/{nome}", headers=cabecalho,
                              params={"allowMissing": "true"})
            r.raise_for_status()
            pedidos += 1
        time.sleep(espera)
    raise RuntimeError(f"a linhagem não esvaziou em {tentativas} rodadas: {len(listar())} processos restam")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.desmonte", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="comando", required=True)
    s = sub.add_parser("plano", help="as atribuições de shell do plano de um passo")
    s.add_argument("--passo", type=int, required=True)
    s = sub.add_parser("conferir-plano", help="lê `terraform show -json` da entrada padrão")
    s.add_argument("--modo", choices=["construcao", "desmonte"], required=True)
    s.add_argument("--destroi", type=int, help="na construção: quantas destruições o Owner leu e aceita")
    s = sub.add_parser("inventario", help="o `gcloud asset search-all-resources` contra o esperado")
    s.add_argument("--entrada", type=pathlib.Path, required=True)
    s.add_argument("--saida", type=pathlib.Path, required=True)
    sub.add_parser("linhagem", help="apaga os processos da Data Lineage API do projeto")
    args = ap.parse_args(argv)

    if args.comando == "plano":
        try:
            print(atribuicoes(args.passo))
        except ValueError as erro:
            print(f"ERRO: {erro}", file=sys.stderr)
            return 1
        return 0
    if args.comando == "conferir-plano":
        aceito, mensagem = conferir_plano(json.load(sys.stdin), args.modo, args.destroi)
        print(("conferir-plano: " if aceito else "ERRO: ") + mensagem, file=sys.stdout if aceito else sys.stderr)
        return 0 if aceito else 1
    if args.comando == "inventario":
        relatorio = inventariar(json.loads(args.entrada.read_text(encoding="utf-8") or "[]"))
        args.saida.write_text(json.dumps(relatorio, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"inventário: {relatorio['total']} recursos, {len(relatorio['residuos'])} resíduos · {args.saida}")
        for residuo in relatorio["residuos"][:40]:
            print(f"  RESÍDUO {residuo['tipo']} {residuo['nome']}")
        return 1 if relatorio["residuos"] else 0
    pedidos = apagar_linhagem(os.environ["GCP_PROJECT_ID"], os.environ["GCP_BQ_LOCATION"])
    print(f"linhagem: {pedidos} processos apagados; a lista do local está vazia")
    return 0


if __name__ == "__main__":
    sys.exit(main())
