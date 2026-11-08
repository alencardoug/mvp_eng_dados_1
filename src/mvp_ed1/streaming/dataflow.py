"""O caminho quente no Dataflow: criar o destino, validar o *job* e lançá-lo (Etapa 13, G2.3/G6).

O grafo é o de `pipeline.construir(..., nuvem=True)`, o mesmo provado no executor local (§19 do
registro). O que muda é o executor e o que vai junto com ele:

* **o pacote**: o `mvp_ed1` como *wheel* sem dependência declarada (`streaming/dataflow/`), porque
  o *worker* instala o pacote resolvendo as dependências, e as do projeto não são as do caminho
  quente; o que ele importa já está na imagem do Beam;
* **a identidade**: os *workers* rodam como `mvp-streamer` (D82), sem IP público, na sub-rede do
  projeto — os valores vêm da saída `dataflow` do Terraform, não de uma segunda declaração;
* **o tamanho**: 1 *worker* `n1-standard-2` com Streaming Engine, sem autoescala (Capacidade §2.14).

O destino é criado **antes**, pela ADC do Owner: o `streamer` tem IAM só da tabela, e criar no
*dataset* não pode (`terraform/dataflow.tf`).

    python -m mvp_ed1.streaming.dataflow tabela
    python -m mvp_ed1.streaming.dataflow validar --terraform SAIDA.json --pacote W.whl --saida JOB.json
    python -m mvp_ed1.streaming.dataflow lancar  --terraform SAIDA.json --pacote W.whl

`validar` monta o *job* inteiro — o grafo traduzido e cada peça serializada como o Dataflow a
recebe — com o `--dry_run` do Beam, que para antes de enviar ou de copiar qualquer coisa para o
*bucket*: custo zero.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

#: Um nome só: o Dataflow recusa um segundo *job* ativo com o mesmo nome, e é isso que impede dois
#: caminhos quentes gravando juntos. O `gcp-dataflow-parar` o procura por este nome.
JOB = "mvp-ed1-caminho-quente"
#: Capacidade §2.14: 2 vCPU e 7,5 GB, ~US$ 0,165/h com o Streaming Engine.
MAQUINA = "n1-standard-2"
#: As do `default_labels` do provider, para o *job* entrar no mesmo filtro de custo e de resíduo.
ROTULOS = {"projeto": "mvp-ed1", "etapa": "13", "desmontar-ate": "2026-11-12"}


def argumentos(terraform: dict[str, Any], pacote: str, *, validar: bool = False) -> list[str]:
    """As opções do Dataflow a partir da saída `dataflow` do Terraform."""
    bucket = terraform["bucket"]
    args = [
        "--runner=DataflowRunner",
        f"--project={terraform['projeto']}",
        f"--region={terraform['regiao']}",
        f"--job_name={JOB}",
        f"--staging_location=gs://{bucket}/staging",
        f"--temp_location=gs://{bucket}/temp",
        f"--service_account_email={terraform['conta']}",
        f"--subnetwork={terraform['subrede']}",
        "--no_use_public_ips",
        "--enable_streaming_engine",
        f"--worker_machine_type={MAQUINA}",
        "--num_workers=1",
        "--max_num_workers=1",
        "--autoscaling_algorithm=NONE",
        f"--extra_package={pacote}",
        *(f"--labels={chave}={valor}" for chave, valor in ROTULOS.items()),
    ]
    if validar:
        args.append("--dry_run=True")
    return args


def tabela() -> str:
    """Cria o destino com a ADC de quem roda (o Owner), se ainda não existe; devolve o nome."""
    from mvp_ed1.streaming import config as cfg
    from mvp_ed1.streaming import nuvem

    fluxo = cfg.carregar()
    bq = nuvem.armazem()
    try:
        nuvem.garantir_tabela(bq, fluxo.destino)
        return bq.tabela(fluxo.destino.qualificado)
    finally:
        bq.dispose()


def executar(terraform: dict[str, Any], pacote: str, *, validar: bool):
    """Monta o grafo da nuvem com o executor do Dataflow e o envia (ou só o monta, em `validar`)."""
    import apache_beam as beam

    from mvp_ed1.streaming import config as cfg
    from mvp_ed1.streaming.pipeline import construir, opcoes

    fluxo = cfg.carregar()
    p = beam.Pipeline(options=opcoes(argumentos(terraform, pacote, validar=validar)))
    construir(p, fluxo, nuvem=True)
    # Sem `with`: num *job* de *streaming* ele esperaria o fim, que não vem. O `run` volta assim que
    # o Dataflow aceita o *job*; quem o acompanha é a consola, e quem o encerra é o `gcp-dataflow-parar`.
    return p.run()


def montado(job, terraform: dict[str, Any]) -> dict[str, Any]:
    """O *job* do `--dry_run` com o ambiente dos *workers*, e o que nele difere do pedido.

    O `--dry_run` para antes de o Beam montar o ambiente (`create_job_description`, que primeiro
    envia o pacote e o grafo ao *bucket*). O ambiente se monta aqui pelo mesmo `apiclient.Environment`,
    sem enviar nada — fica de fora só a lista de pacotes, e o *wheel* se confere à parte.
    """
    from apache_beam.runners.dataflow.internal import apiclient

    ambiente = apiclient.Environment(
        packages=[],
        options=job.options,
        # Privado do Beam, mas é o que o `DataflowApplicationClient` passa; só serve à conferência.
        environment_version=apiclient._FNAPI_ENVIRONMENT_MAJOR_VERSION,
        proto_pipeline_staged_url=f"gs://{terraform['bucket']}/staging/pipeline.pb",
        proto_pipeline=job.proto_pipeline,
    ).proto
    job.proto.environment = ambiente
    descrito = json.loads(job.json())
    pool = (descrito.get("environment", {}).get("workerPools") or [{}])[0]
    imagens = [c.get("containerImage") for c in pool.get("sdkHarnessContainerImages", [])]
    esperado = {
        "serviceAccountEmail": terraform["conta"],
        "machineType": MAQUINA,
        "numWorkers": 1,
        "subnetwork": terraform["subrede"],
        "ipConfiguration": "WORKER_IP_PRIVATE",
    }
    obtido = {
        "serviceAccountEmail": descrito.get("environment", {}).get("serviceAccountEmail"),
        "machineType": pool.get("machineType"),
        "numWorkers": pool.get("numWorkers"),
        "subnetwork": pool.get("subnetwork"),
        "ipConfiguration": pool.get("ipConfiguration"),
    }
    return {
        "job": {"name": descrito.get("name"), "type": descrito.get("type"), "labels": descrito.get("labels")},
        "transformacoes": len(job.proto_pipeline.components.transforms),
        "imagem": imagens[0] if imagens else None,
        "ambiente": obtido,
        "experimentos": descrito.get("environment", {}).get("experiments"),
        "divergencias": {k: {"esperado": v, "obtido": obtido[k]} for k, v in esperado.items() if obtido[k] != v},
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.streaming.dataflow", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="comando", required=True)
    sub.add_parser("tabela", help="cria o destino com a ADC do Owner, se não existe")
    for nome in ("validar", "lancar"):
        s = sub.add_parser(nome)
        s.add_argument("--terraform", type=Path, required=True, help="a saída `terraform output -json dataflow`")
        s.add_argument("--pacote", required=True, help="o wheel de streaming/dataflow")
        if nome == "validar":
            s.add_argument("--saida", type=Path, required=True, help="onde gravar o job montado (JSON)")
    args = ap.parse_args(argv)

    if args.comando == "tabela":
        print(f"destino pronto: {tabela()}")
        return 0
    terraform = json.loads(args.terraform.read_text(encoding="utf-8"))
    if not terraform:
        print("ERRO: a saída `dataflow` do Terraform está vazia (degrau barato não aplicado).", file=sys.stderr)
        return 1
    resultado = executar(terraform, args.pacote, validar=args.comando == "validar")
    if args.comando == "validar":
        relatorio = montado(resultado.job, terraform)
        args.saida.write_text(json.dumps(relatorio, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"job montado sem enviar: {relatorio['job']['name']} · {relatorio['transformacoes']} "
              f"transformações · imagem {relatorio['imagem']} · {args.saida}")
        return 1 if relatorio["divergencias"] else 0
    print(f"job enviado: {resultado.job_id()} ({JOB}); acompanhe na consola do Dataflow")
    return 0


if __name__ == "__main__":
    sys.exit(main())
