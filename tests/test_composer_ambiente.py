"""O ambiente do Composer: Terraform, segredos e identidade (Etapa 13, G2.4 e G3; D81)."""

from __future__ import annotations

import pathlib
import re
import sys
import types

import pytest

from mvp_ed1 import airbyte, orquestracao
from mvp_ed1.gcp import composer, credenciais

RAIZ = pathlib.Path(__file__).resolve().parent.parent
TF = (RAIZ / "terraform" / "composer.tf").read_text(encoding="utf-8")
SQL_TF = (RAIZ / "terraform" / "cloud_sql.tf").read_text(encoding="utf-8")


def _bloco(nome: str) -> str:
    """O corpo de `nome = { … }` no composer.tf, até a chave que o fecha."""
    inicio = TF.index(f"{nome} = {{")
    profundidade = 0
    for i, c in enumerate(TF[inicio:], start=inicio):
        profundidade += {"{": 1, "}": -1}.get(c, 0)
        if c == "}" and profundidade == 0:
            return TF[inicio:i]
    raise AssertionError(nome)


def test_os_pacotes_do_terraform_sao_os_da_prova_local():
    # O `for` do HCL lê só as linhas `nome==versão`; emulado aqui com a mesma expressão, ele tem de
    # dar o que o `pacotes()` da prova local dá — senão o ambiente instala outra coisa.
    padrao = re.search(r'can\(regex\("(.+?)", trimspace\(linha\)\)\)', TF).group(1).replace("\\\\", "\\")
    linhas = composer.PACOTES.read_text(encoding="utf-8").splitlines()
    pelo_hcl = {l.strip().split("==")[0].lower(): "==" + l.strip().split("==")[1]
                for l in linhas if re.fullmatch(padrao, l.strip())}
    assert pelo_hcl == composer.pacotes()
    assert "airflow/requirements-composer.txt" in TF


def test_a_imagem_do_ambiente_e_a_da_prova_local():
    imagem = re.search(r'composer_imagem = "([^"]+)"', TF).group(1)
    makefile = (RAIZ / "Makefile").read_text(encoding="utf-8")
    assert re.search(rf"^COMPOSER_IMAGEM := .*:{re.escape(imagem)}@sha256:", makefile, re.M)


def test_cada_segredo_da_dag_tem_um_segredo_no_secret_manager():
    prefixo = re.search(r'composer_prefixo = "([^"]+)"', TF).group(1)
    assert f"variables_prefix = local.composer_prefixo" in TF and 'sep              = "-"' in TF
    do_airbyte = set(re.findall(r'"(airbyte-[a-z-]+)"', _bloco("composer_segredos_airbyte")))
    # O do legado é o que o cloud_sql.tf já cria: `<prefixo>-<origem>-db-password`.
    assert '"mvp-ed1-${origem}-db-password"' in SQL_TF and prefixo == "mvp-ed1"
    assert set(orquestracao.SEGREDOS.values()) == do_airbyte | {"legacy-db-password"}


def test_nenhum_segredo_nas_variaveis_de_ambiente_do_composer():
    nomes = re.findall(r"^\s+([A-Z][A-Z0-9_]+)\s+=", _bloco("env_variables"), re.M)
    assert nomes, "o bloco não foi lido"
    assert not set(nomes) & set(orquestracao.SEGREDOS)
    assert not [n for n in nomes if re.search(r"PASSWORD|SECRET|TOKEN|CLIENT", n)]
    # E os nomes que o Composer reserva (descrição do `env_variables` no provider).
    reservados = {"AIRFLOW_HOME", "C_FORCE_ROOT", "CONTAINER_NAME", "DAGS_FOLDER", "GCP_PROJECT", "GCS_BUCKET",
                  "GKE_CLUSTER_NAME", "SQL_DATABASE", "SQL_INSTANCE", "SQL_PASSWORD", "SQL_PROJECT", "SQL_REGION",
                  "SQL_USER"}
    assert not set(nomes) & reservados


def test_a_conta_do_ambiente_so_personifica_os_dois_papeis():
    assert 'toset(["ingestor", "transformer"])' in TF
    assert re.findall(r'role\s+= "(roles/[^"]+)"', TF) == [
        "roles/composer.worker", "roles/iam.serviceAccountTokenCreator", "roles/storage.objectAdmin",
        "roles/secretmanager.secretAccessor"]
    assert 'MVP_IMPERSONATE_SA     = google_service_account.role["ingestor"].email' in TF
    assert 'MVP_DBT_IMPERSONATE_SA = google_service_account.role["transformer"].email' in TF
    perfil = (RAIZ / "dbt" / "profiles.yml").read_text(encoding="utf-8")
    assert "impersonate_service_account: \"{{ env_var('MVP_DBT_IMPERSONATE_SA', '') }}\"" in perfil


@pytest.fixture
def variaveis(monkeypatch):
    """Um `airflow.sdk` falso: as *Variables* que o *backend* entregaria, e quem foi perguntado."""
    guardadas: dict[str, str] = {}
    perguntadas: list[str] = []

    class Variable:
        @staticmethod
        def get(nome, default=None):
            perguntadas.append(nome)
            return guardadas.get(nome, default)

    monkeypatch.setitem(sys.modules, "airflow", types.ModuleType("airflow"))
    monkeypatch.setitem(sys.modules, "airflow.sdk", types.SimpleNamespace(Variable=Variable))
    for env in orquestracao.SEGREDOS:
        monkeypatch.delenv(env, raising=False)
    return guardadas, perguntadas


def test_a_ponte_preenche_so_o_que_falta(variaveis, monkeypatch):
    guardadas, perguntadas = variaveis
    guardadas.update({"legacy-db-password": "s1", "airbyte-client-id": "c1", "airbyte-url": "http://10.10.0.9:8001/api/public/v1"})
    monkeypatch.setenv("AIRBYTE_CLIENT_ID", "do-env")
    orquestracao.segredos()
    import os

    assert os.environ["LEGACY_DB_PASSWORD"] == "s1"
    assert os.environ["AIRBYTE_CLIENT_ID"] == "do-env"  # o ambiente vence: nem foi perguntado
    assert "airbyte-client-id" not in perguntadas
    assert "AIRBYTE_CLIENT_SECRET" not in os.environ  # não existe em lugar nenhum: segue faltando
    # O endereço do Airbyte é lido na hora da chamada, então vale mesmo com o módulo já importado.
    assert airbyte._base() == "http://10.10.0.9:8001/api/public/v1"


def test_a_ponte_nao_consulta_nada_com_o_ambiente_completo(variaveis, monkeypatch):
    _, perguntadas = variaveis
    for env in orquestracao.SEGREDOS:
        monkeypatch.setenv(env, "x")
    orquestracao.segredos()
    assert perguntadas == []


def test_sem_a_variavel_a_credencial_e_a_adc():
    assert credenciais.personificada({}) is None
    assert credenciais.personificada({credenciais.ENV: "  "}) is None


def test_com_a_variavel_a_credencial_e_da_conta_do_papel(monkeypatch):
    import google.auth
    from google.auth import impersonated_credentials
    from google.auth.credentials import AnonymousCredentials

    monkeypatch.setattr(google.auth, "default", lambda scopes: (AnonymousCredentials(), "projeto"))
    cred = credenciais.personificada({credenciais.ENV: "mvp-ingestor@p.iam.gserviceaccount.com"})
    assert isinstance(cred, impersonated_credentials.Credentials)
    assert cred._target_principal == "mvp-ingestor@p.iam.gserviceaccount.com"
    assert isinstance(cred._source_credentials, AnonymousCredentials)
    assert cred._lifetime == credenciais.VIDA_EM_SEGUNDOS


def test_todo_bucket_sai_sem_soft_delete():
    """`force_destroy` esvazia o bucket, mas o *soft delete* padrão guarda o apagado por 7 dias, cobrando (RVPC-1-02)."""
    for arquivo in sorted((RAIZ / "terraform").glob("*.tf")):
        texto = arquivo.read_text(encoding="utf-8")
        blocos = re.split(r'\nresource "', texto)[1:]
        for bloco in blocos:
            if bloco.startswith('google_storage_bucket" '):
                nome = bloco.split('"')[2]
                assert re.search(r"soft_delete_policy \{\s*retention_duration_seconds = 0\s*\}", bloco), \
                    f"{arquivo.name}: google_storage_bucket.{nome} sem soft_delete_policy de 0 s"


# Os limites do Composer 3 para Airflow 3, da tabela oficial
# (https://docs.cloud.google.com/composer/docs/composer-3/scale-environments#resource-limits).
# `cpu`: faixa e regra de valores ("0,5": múltiplos de 0,5; "0,5, 1 ou par": 0,5, 1 ou múltiplo de
# 2). `memoria`: faixa (o mínimo de 2 GB é o do Airflow 3), em passos de 0,25 GB e de 1 a 8 GB por
# vCPU. `armazenamento`: de 0 a 100 GB em passos de 1 GB (o *triggerer* não tem). `count`: faixa
# de inteiros (o *web server* não tem quantidade).
LIMITES_AIRFLOW_3 = {
    "scheduler": {"cpu": (0.5, 2, "0,5"), "memoria": (2, 8), "armazenamento": True, "count": (1, 3)},
    "triggerer": {"cpu": (0.5, 1, "0,5"), "memoria": (2, 8), "armazenamento": False, "count": (0, 10)},
    "dag_processor": {"cpu": (0.5, 32, "0,5, 1 ou par"), "memoria": (2, 256), "armazenamento": True, "count": (1, 3)},
    "web_server": {"cpu": (1, 4, "0,5, 1 ou par"), "memoria": (2, 32), "armazenamento": True, "count": None},
    "worker": {"cpu": (0.5, 32, "0,5, 1 ou par"), "memoria": (2, 256), "armazenamento": True, "count": (1, 100)},
}


def _componentes(texto: str = TF) -> dict[str, dict[str, float]]:
    """Os blocos do `workloads_config`; valor que não é número falha aqui, em vez de sumir."""
    carga = texto[texto.index("workloads_config {"):texto.index("node_config {")]
    return {
        nome: {chave: float(valor) for chave, valor in re.findall(r"(\w+)\s*=\s*(\S+)", corpo)}
        for nome, corpo in re.findall(r"(\w+) \{([^{}]*)\}", carga)
    }


def _multiplo(valor: float, passo: float) -> bool:
    return abs(valor / passo - round(valor / passo)) < 1e-9


def _violacoes(nome: str, valores: dict[str, float]) -> list[str]:
    limites, erros = LIMITES_AIRFLOW_3[nome], []
    cpu, memoria = valores.get("cpu", 0), valores.get("memory_gb", 0)
    minimo, maximo, regra = limites["cpu"]
    if not minimo <= cpu <= maximo:
        erros.append(f"cpu {cpu} fora de {minimo}–{maximo}")
    if regra == "0,5" and not _multiplo(cpu, 0.5):
        erros.append(f"cpu {cpu} não é múltiplo de 0,5")
    if regra == "0,5, 1 ou par" and cpu not in (0.5, 1) and not _multiplo(cpu, 2):
        erros.append(f"cpu {cpu} não é 0,5, 1 nem par")
    if not limites["memoria"][0] <= memoria <= limites["memoria"][1]:
        erros.append(f"memória {memoria} fora de {limites['memoria']}")
    if not _multiplo(memoria, 0.25):
        erros.append(f"memória {memoria} fora do passo de 0,25")
    if cpu and not 1 <= memoria / cpu <= 8:
        erros.append(f"memória por vCPU {memoria / cpu}")
    if "storage_gb" in valores:
        armazenamento = valores["storage_gb"]
        if not limites["armazenamento"]:
            erros.append("armazenamento num componente que não tem")
        elif not (0 <= armazenamento <= 100 and _multiplo(armazenamento, 1)):
            erros.append(f"armazenamento {armazenamento}")
    quantidades = [valores[k] for k in ("count", "min_count", "max_count") if k in valores]
    if limites["count"] is None:
        if quantidades:
            erros.append("quantidade num componente que não tem")
    elif not quantidades or not all(
        _multiplo(q, 1) and limites["count"][0] <= q <= limites["count"][1] for q in quantidades
    ):
        erros.append(f"quantidades {quantidades}")
    return erros


def test_o_composer_declara_os_componentes_da_estimativa():
    """O tamanho do ambiente não fixa os componentes (RVPC-1-03): o plano tem de mostrar o que a Capacidade §2.14 estimou."""
    componentes = _componentes()
    assert set(componentes) == set(LIMITES_AIRFLOW_3)
    assert componentes["worker"]["min_count"] == 2 and componentes["worker"]["max_count"] == 4


@pytest.mark.parametrize("nome", sorted(LIMITES_AIRFLOW_3))
def test_cada_componente_cabe_nos_limites_do_airflow_3(nome):
    """Valor fora da tabela oficial só falha no `apply`, depois de minutos de criação (RVPC-2-01)."""
    assert _violacoes(nome, _componentes()[nome]) == []


def _com(nome: str, **troca: str) -> str:
    """O `composer.tf` com atributos de um componente trocados."""
    inicio = TF.index(f"      {nome} {{")
    fim = TF.index("}", inicio)
    corpo = TF[inicio:fim]
    for chave, valor in troca.items():
        corpo = re.sub(rf"({chave}\s*=\s*)\S+", rf"\g<1>{valor}", corpo)
    return TF[:inicio] + corpo + TF[fim:]


# Os casos da rodada 3 (RVPC-3-01), que a guarda anterior aceitava, e o da rodada 2.
INVALIDOS = [
    ("scheduler", {"cpu": "0.75"}),
    ("scheduler", {"cpu": "2", "memory_gb": "9"}),
    ("worker", {"memory_gb": "2.1"}),
    ("worker", {"storage_gb": "1.5"}),
    ("worker", {"storage_gb": "-1"}),
    ("scheduler", {"count": "1.5"}),
    ("triggerer", {"memory_gb": "0.5"}),
]


@pytest.mark.parametrize(("nome", "troca"), INVALIDOS)
def test_a_guarda_recusa_o_que_a_tabela_recusa(nome, troca):
    assert _violacoes(nome, _componentes(_com(nome, **troca))[nome])
