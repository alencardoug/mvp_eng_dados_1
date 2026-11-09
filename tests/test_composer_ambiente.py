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
