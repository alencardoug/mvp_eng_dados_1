"""A guarda da identidade da captura — antes do disparo, em toda entrada.

`snapshot_id` é o `job_id` do Airbyte. Um Airbyte reinstalado recomeça o
contador em 1, e o pacote de recuperação retém capturas 9–43: a primeira
sincronização depois de uma restauração reusaria uma identidade certificada, e
a captura 43 passaria a ler duas linhas onde havia uma.

**O oráculo destes testes é o número de `POST /jobs`.** Recusar depois do
disparo não desfaz nada — o *append* do Airbyte já aconteceu. Por isso os casos
recusados exigem **zero** requisições, e não uma mensagem de erro.

Nada aqui fala com o Airbyte nem com banco: a listagem de *jobs* e a lista de
capturas certificadas são injetadas.
"""

from __future__ import annotations

import pytest

from mvp_ed1 import airbyte
from mvp_ed1.legacy import identidade


class Airbyte:
    """Um Airbyte de mentira que **conta** os disparos."""

    def __init__(self, jobs: list[int]) -> None:
        self.jobs = list(jobs)
        self.posts: list[tuple[str, str]] = []

    def listar(self) -> dict:
        return {"data": [{"jobId": j} for j in sorted(self.jobs, reverse=True)]}

    def disparar(self, connection_id: str, _jwt: str, tipo: str = "sync") -> dict:
        self.posts.append((connection_id, tipo))
        novo = max(self.jobs, default=0) + 1
        self.jobs.append(novo)
        return {"jobId": novo}


@pytest.fixture
def armazem(monkeypatch):
    """`captura.certificadas` sem banco: a lista é o que interessa aqui."""

    def certificadas(lista: list[int]):
        monkeypatch.setattr(
            "mvp_ed1.legacy.captura.certificadas", lambda _armazem: sorted(lista)
        )

    return certificadas


# ── A regra, isolada ────────────────────────────────────────────────────────


def test_contador_atras_do_certificado_recusa(armazem):
    """O caso da instalação nova: contador em 3, captura 43 retida."""
    armazem([28, 43])
    falso = Airbyte([1, 2, 3])

    with pytest.raises(identidade.IdentidadeReutilizada) as erro:
        identidade.exigir(object(), falso.listar)

    assert "43" in str(erro.value) and "o maior job é 3" in str(erro.value)
    assert "NÃO foi disparado" in str(erro.value)
    assert "44" in str(erro.value), "a mensagem diz para onde avançar a sequência"


def test_airbyte_sem_job_nenhum_recusa(armazem):
    """Instalação recém-criada é o caso perigoso, não o inofensivo."""
    armazem([43])

    with pytest.raises(identidade.IdentidadeReutilizada) as erro:
        identidade.exigir(object(), Airbyte([]).listar)

    assert "nenhum job" in str(erro.value)


def test_contador_igual_ao_certificado_libera(armazem):
    """Com o maior job igual a 43, o próximo é 44 — acima do retido."""
    armazem([43])
    identidade.exigir(object(), Airbyte([41, 42, 43]).listar)


def test_armazem_sem_captura_certificada_libera(armazem):
    """Não há identidade a proteger: a primeira captura pode ser o job 1."""
    armazem([])
    identidade.exigir(object(), Airbyte([]).listar)


def test_reset_do_legado_e_recusado_e_o_da_principal_nao():
    with pytest.raises(identidade.ResetDoLegadoRecusado) as erro:
        identidade.recusar_reset(identidade.CONEXAO_LEGADA)
    assert "memória" in str(erro.value) and "NÃO foi disparado" in str(erro.value)

    identidade.recusar_reset("oltp_para_raw")  # a recarga do gerador depende dele


# ── As entradas: nenhuma escapa, e recusa não faz POST ──────────────────────


class _Motor:
    """Nenhuma conexão é aberta: a guarda só precisa de um objeto para descartar."""

    def dispose(self) -> None:
        pass


@pytest.fixture
def entradas(monkeypatch, armazem):
    """Intercepta o transporte: `sincronizar` é a única porta para o `/jobs`."""
    falso = Airbyte([1, 2, 3])
    armazem([28, 43])
    monkeypatch.setattr(airbyte, "sincronizar", falso.disparar)
    monkeypatch.setattr(airbyte, "jobs", lambda _jwt, limite=100: falso.listar())
    monkeypatch.setattr("mvp_ed1.db.database_url", lambda _p=None: "postgresql+psycopg://x/y")
    monkeypatch.setattr("sqlalchemy.create_engine", lambda *_a, **_k: _Motor())
    return falso


def test_disparo_da_conexao_legada_recusado_nao_faz_post(entradas):
    with pytest.raises(identidade.IdentidadeReutilizada):
        airbyte.disparar(identidade.CONEXAO_LEGADA, "id-ficticio", "jwt")

    assert entradas.posts == [], "a recusa precisa acontecer ANTES do POST"


def test_reset_da_conexao_legada_recusado_nao_faz_post(entradas):
    with pytest.raises(identidade.ResetDoLegadoRecusado):
        airbyte.disparar(identidade.CONEXAO_LEGADA, "id-ficticio", "jwt", "reset")

    assert entradas.posts == []


def test_a_conexao_principal_passa_livre(entradas):
    """A guarda é da identidade da captura legada — a principal não tem uma."""
    airbyte.disparar("oltp_para_raw", "id-principal", "jwt")
    airbyte.disparar("oltp_para_raw", "id-principal", "jwt", "reset")

    assert [tipo for _c, tipo in entradas.posts] == ["sync", "reset"]


def test_com_o_contador_avancado_o_legado_dispara(entradas, armazem):
    armazem([28, 43])
    entradas.jobs = [43]

    job = airbyte.disparar(identidade.CONEXAO_LEGADA, "id-ficticio", "jwt")

    assert job["jobId"] == 44
    assert entradas.posts == [("id-ficticio", "sync")]


# ── A tarefa da DAG que efetivamente dispara ────────────────────────────────


def test_a_tarefa_da_dag_dispara_pela_porta_com_guarda():
    """A tarefa que dispara é `sincronizar`, não a fase 1 — e é nela que a
    pré-condição tem de estar.

    `iniciar_captura_do_legado` e `sincronizar_legado_para_raw_legacy` são
    tarefas distintas: reexecutar a segunda sozinha **não** repete a primeira,
    e uma guarda posta só na fase 1 não a alcançaria (RV12-4-03).

    **Limite declarado:** esta é uma conferência estrutural, por AST, e não a
    execução da tarefa. O Airflow instalado no `.venv` não traz
    `airflow.providers`, então o módulo da DAG não é importável aqui; quem
    exercita a tarefa de verdade é a DAG rodando, em B5. O que este teste
    garante é que ninguém troque `disparar` por `sincronizar` de volta sem que
    a suíte reclame — que é exatamente como a entrada escapou da primeira vez.
    """
    import ast
    import pathlib

    fonte = (
        pathlib.Path(__file__).resolve().parent.parent / "airflow" / "dags" / "fluxo_batch.py"
    ).read_text(encoding="utf-8")
    arvore = ast.parse(fonte)

    tarefa = next(
        no
        for no in ast.walk(arvore)
        if isinstance(no, ast.FunctionDef) and no.name == "sincronizar"
    )
    chamadas = {
        f"{no.func.value.id}.{no.func.attr}"
        for no in ast.walk(tarefa)
        if isinstance(no, ast.Call)
        and isinstance(no.func, ast.Attribute)
        and isinstance(no.func.value, ast.Name)
    }

    assert "airbyte.disparar" in chamadas, chamadas
    assert "airbyte.sincronizar" not in chamadas, (
        "a tarefa voltou a chamar o transporte cru, por fora da guarda"
    )
