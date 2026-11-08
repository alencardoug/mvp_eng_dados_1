"""O caminho quente no Dataflow: opções, pacote do worker, peças sem o ambiente (Etapa 13; D82, D83)."""

from __future__ import annotations

import ast
import pathlib
import re
import sys
import tomllib
import types

import pytest

from mvp_ed1.streaming import dataflow, nuvem

RAIZ = pathlib.Path(__file__).resolve().parent.parent
SRC = RAIZ / "src"
TERRAFORM = {
    "projeto": "p", "regiao": "us-central1", "bucket": "p-beam",
    "conta": "mvp-streamer@p.iam.gserviceaccount.com",
    "subrede": "https://www.googleapis.com/compute/v1/projects/p/regions/us-central1/subnetworks/mvp-ed1-us-central1",
}
#: O que a imagem `apache/beam_python3.11_sdk:2.76.0` traz e o caminho quente importa no nível de
#: módulo (`base_image_requirements.txt` da 2.76.0: SQLAlchemy 2.0.51, PyYAML 6.0.3).
NA_IMAGEM = {"apache_beam", "sqlalchemy", "yaml"}


def test_as_opcoes_sao_as_da_capacidade_e_da_d82():
    args = dataflow.argumentos(TERRAFORM, "/tmp/w.whl")
    for esperado in ("--runner=DataflowRunner", "--service_account_email=mvp-streamer@p.iam.gserviceaccount.com",
                     f"--subnetwork={TERRAFORM['subrede']}", "--no_use_public_ips", "--enable_streaming_engine",
                     "--worker_machine_type=n1-standard-2", "--num_workers=1", "--max_num_workers=1",
                     "--autoscaling_algorithm=NONE", "--extra_package=/tmp/w.whl",
                     "--staging_location=gs://p-beam/staging", "--temp_location=gs://p-beam/temp",
                     f"--job_name={dataflow.JOB}"):
        assert esperado in args
    assert "--dry_run=True" not in args
    assert dataflow.argumentos(TERRAFORM, "/tmp/w.whl", validar=True)[-1] == "--dry_run=True"


def test_os_rotulos_do_job_sao_os_do_provider():
    versoes = (RAIZ / "terraform" / "versions.tf").read_text(encoding="utf-8")
    bloco = re.search(r"default_labels = \{(.*?)\}", versoes, re.S).group(1)
    do_provider = dict(re.findall(r'(\S+)\s*=\s*"([^"]+)"', bloco))
    assert dataflow.ROTULOS == do_provider


def test_o_nome_do_job_e_o_mesmo_no_makefile():
    makefile = (RAIZ / "Makefile").read_text(encoding="utf-8")
    assert f"DATAFLOW_JOB := {dataflow.JOB}\n" in makefile


def test_o_pacote_do_worker_nao_declara_dependencia():
    declaracao = tomllib.loads((RAIZ / "streaming" / "dataflow" / "pyproject.toml").read_text(encoding="utf-8"))
    assert declaracao["project"]["dependencies"] == []
    incluido = declaracao["tool"]["hatch"]["build"]["targets"]["wheel"]["force-include"]
    assert incluido == {"../../src/mvp_ed1": "mvp_ed1"}
    assert (RAIZ / "streaming" / "dataflow" / "../../src/mvp_ed1").resolve() == (SRC / "mvp_ed1").resolve()


def _arquivo(modulo: str) -> pathlib.Path:
    caminho = SRC / (modulo.replace(".", "/") + ".py")
    return caminho if caminho.exists() else SRC / modulo.replace(".", "/") / "__init__.py"


def test_o_caminho_quente_so_importa_o_que_a_imagem_do_beam_traz():
    # Só o nível de módulo: o que é importado dentro de função só roda se a função for chamada, e
    # os ramos locais (Kafka, psycopg) não rodam no worker.
    vistos, terceiros, fila = set(), set(), ["mvp_ed1.streaming.pipeline", "mvp_ed1.streaming.nuvem"]
    while fila:
        modulo = fila.pop()
        if modulo in vistos:
            continue
        vistos.add(modulo)
        for no in ast.parse(_arquivo(modulo).read_text(encoding="utf-8")).body:
            nomes = [a.name for a in no.names] if isinstance(no, ast.Import) else (
                [no.module] if isinstance(no, ast.ImportFrom) and no.level == 0 and no.module else [])
            for nome in nomes:
                if nome.startswith("mvp_ed1"):
                    fila.append(nome if _arquivo(nome).exists() else nome.rsplit(".", 1)[0])
                elif nome.split(".")[0] not in sys.stdlib_module_names:
                    terceiros.add(nome.split(".")[0])
    assert terceiros <= NA_IMAGEM, terceiros - NA_IMAGEM


PROJETO = nuvem.Projeto("p-lancador", "us-central1")


@pytest.fixture
def sem_ambiente(monkeypatch):
    """O worker: nenhuma variável do lançador."""
    for nome in ("GCP_PROJECT_ID", "GCP_BQ_LOCATION"):
        monkeypatch.delenv(nome, raising=False)


def test_a_gravacao_e_a_semente_usam_o_projeto_de_quem_construiu(sem_ambiente, monkeypatch):
    pedidos = []

    class Armazem:
        def dispose(self):
            pass

    monkeypatch.setattr(nuvem, "armazem", lambda projeto=None: pedidos.append(projeto) or Armazem())
    monkeypatch.setattr(nuvem, "garantir_tabela", lambda bq, destino: None)
    monkeypatch.setattr(nuvem, "semente", lambda bq, destino, inicio: [])
    nuvem.GravarEventos(object(), PROJETO).setup()
    nuvem.Semear(object(), PROJETO)(None)
    assert pedidos == [PROJETO, PROJETO]


def test_o_alerta_publica_no_projeto_de_quem_construiu(sem_ambiente, monkeypatch):
    class Editor:
        def topic_path(self, projeto, topico):
            return f"projects/{projeto}/topics/{topico}"

    falso = types.SimpleNamespace(PublisherClient=Editor)
    monkeypatch.setitem(sys.modules, "google.cloud.pubsub_v1", falso)
    import google.cloud

    monkeypatch.setattr(google.cloud, "pubsub_v1", falso, raising=False)
    peca = nuvem.PublicarAlerta(types.SimpleNamespace(topico_de_alertas="alertas"), PROJETO)
    peca.setup()
    assert peca._topico == "projects/p-lancador/topics/alertas"


class _Cliente:
    def __init__(self, existe: bool):
        self.existe, self.perguntado, self.ddl = existe, [], []

    def get_table(self, nome):
        from google.api_core.exceptions import NotFound

        self.perguntado.append(nome)
        if not self.existe:
            raise NotFound(nome)

    def query(self, sql, location=None):
        self.ddl.append(sql)
        return types.SimpleNamespace(result=lambda: None)


@pytest.mark.parametrize("existe", [True, False])
def test_o_worker_so_cria_o_destino_se_ele_nao_existe(existe):
    from mvp_ed1.legacy.armazem import BigQuery

    cliente = _Cliente(existe)
    bq = BigQuery(cliente, "p", coordenador=None, local="us-central1", renomear={"raw": "raw_teste"})
    destino = types.SimpleNamespace(qualificado="raw.inventory_movements_stream")
    nuvem.garantir_tabela(bq, destino)
    # O nome perguntado é o do DDL, com o `renomear` do armazém.
    assert cliente.perguntado == ["p.raw_teste.inventory_movements_stream"]
    assert len(cliente.ddl) == (0 if existe else 1)


def test_o_terraform_traduz_todo_privilegio_declarado_por_tabela():
    import json

    tf = (RAIZ / "terraform" / "dataflow.tf").read_text(encoding="utf-8")
    traduzidos = set(re.findall(r"^\s+(\w+)\s+= \"roles/bigquery\.", tf, re.M))
    declarado = json.loads((RAIZ / "terraform" / "acesso.auto.tfvars.json").read_text(encoding="utf-8"))
    privilegios = {p for t in declarado["pendentes_por_tabela"] for p in t["grants"]}
    assert privilegios and privilegios <= traduzidos
    assert 'role    = "roles/dataflow.worker"' in tf and 'google_service_account.role["streamer"].member' in tf
