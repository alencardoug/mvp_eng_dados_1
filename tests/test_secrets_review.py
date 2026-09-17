"""A revisão de segredos de `make check`, provada num repositório efêmero.

Cada forma de quebrar a regra inviolável nº 1 tem a sua contraprova: o teste
monta um repositório limpo que passa, introduz a quebra e exige o achado.
"""

from __future__ import annotations

import pathlib
import subprocess

import pytest

from mvp_ed1 import secrets_review


def _git(root: pathlib.Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)


@pytest.fixture
def repositorio(tmp_path: pathlib.Path) -> pathlib.Path:
    _git(tmp_path, "init", "-q")
    _git(tmp_path, "config", "user.email", "teste@exemplo.local")
    _git(tmp_path, "config", "user.name", "teste")
    (tmp_path / ".gitignore").write_text(".env\n*.log\n", encoding="utf-8")
    (tmp_path / ".env.example").write_text("# modelo\nWAREHOUSE_DB_NAME=\nWAREHOUSE_DB_PASSWORD=\nAIRFLOW_JWT_SECRET=\n", encoding="utf-8")
    (tmp_path / ".env").write_text(
        "WAREHOUSE_DB_NAME=warehouse_db\nWAREHOUSE_DB_PASSWORD=s3nh4-muito-longa-e-aleatoria\nAIRFLOW_JWT_SECRET=jwt0123456789abcdef\n",
        encoding="utf-8",
    )
    (tmp_path / "docs.md").write_text("O banco chama-se warehouse_db e a senha vem do .env.\n", encoding="utf-8")
    _git(tmp_path, "add", "-A")
    _git(tmp_path, "commit", "-q", "-m", "base")
    return tmp_path


def test_repositorio_limpo_passa_e_o_nome_do_banco_nao_e_segredo(repositorio: pathlib.Path) -> None:
    assert secrets_review.review(repositorio) == []
    assert set(secrets_review.secret_values(secrets_review.read_env(repositorio / ".env"))) == {
        "WAREHOUSE_DB_PASSWORD", "AIRFLOW_JWT_SECRET",
    }


def test_valor_do_env_num_arquivo_rastreado_e_acusado_com_a_chave(repositorio: pathlib.Path) -> None:
    (repositorio / "conector.yml").write_text("password: s3nh4-muito-longa-e-aleatoria\n", encoding="utf-8")
    _git(repositorio, "add", "conector.yml")
    assert secrets_review.review(repositorio) == ["conector.yml: contém o valor de WAREHOUSE_DB_PASSWORD do .env"]


def test_env_example_com_valor_e_env_rastreado_sao_acusados(repositorio: pathlib.Path) -> None:
    (repositorio / ".env.example").write_text("WAREHOUSE_DB_NAME=\nWAREHOUSE_DB_PASSWORD=abc\n", encoding="utf-8")
    _git(repositorio, "add", "-f", ".env", ".env.example")
    achados = secrets_review.review(repositorio)
    assert ".env está rastreado pelo git — remova do índice e rode o histórico" in achados
    assert ".env.example:2: chave com valor preenchido (WAREHOUSE_DB_PASSWORD)" in achados
    # O próprio .env rastreado contém os seus valores, e é acusado como qualquer arquivo.
    assert ".env: contém o valor de WAREHOUSE_DB_PASSWORD do .env" in achados
    # Rastreado e ignorado ao mesmo tempo: a contradição que engoliu os seeds do dbt.
    assert ".env: rastreado, mas o .gitignore o ignora — o próximo `git add` não o vê" in achados


def test_forma_generica_de_credencial_e_acusada_sem_depender_do_env(repositorio: pathlib.Path) -> None:
    (repositorio / "chave.pem").write_text("-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n", encoding="utf-8")
    (repositorio / ".env").unlink()
    _git(repositorio, "add", "chave.pem")
    assert secrets_review.review(repositorio) == ["chave.pem: forma de credencial `-----BEGIN RSA PRIVATE K…`"]


def test_gitignore_que_deixa_de_ignorar_o_env_e_acusado(repositorio: pathlib.Path) -> None:
    (repositorio / ".gitignore").write_text("*.log\n", encoding="utf-8")
    assert secrets_review.review(repositorio) == [".env não é ignorado pelo .gitignore"]


def test_o_repositorio_deste_projeto_passa() -> None:
    """A regra vale para o repositório real, não só para o efêmero."""
    raiz = pathlib.Path(__file__).resolve().parent.parent
    assert secrets_review.review(raiz) == []
