"""A re-execução de tarefas na mesma execução do Composer: ensaio sempre, limpeza só pedida (Registro §55)."""

from __future__ import annotations

import pathlib

import pytest

from mvp_ed1.gcp import composer_api

MAKEFILE = (pathlib.Path(__file__).resolve().parent.parent / "Makefile").read_text(encoding="utf-8")


class _Resposta:
    def __init__(self, status, dados):
        self.status_code, self._dados, self.text = status, dados, str(dados)

    def json(self):
        return self._dados


class _Sessao:
    def __init__(self, tarefas, status=200):
        self.pedidos, self._tarefas, self._status = [], tarefas, status

    def post(self, url, json):
        self.pedidos.append((url, json))
        return _Resposta(self._status, {"task_instances": [{"task_id": t, "state": "failed"} for t in self._tarefas]})


def test_sem_tarefas_limpa_so_as_falhas_e_nunca_vizinhas():
    c = composer_api.corpo("r1", None, ensaio=True)
    assert c["only_failed"] is True and "task_ids" not in c
    assert c["include_upstream"] is False and c["include_downstream"] is False and c["dry_run"] is True


def test_com_tarefas_limpa_exatamente_as_nomeadas():
    c = composer_api.corpo("r1", ["sincronizar_oltp_para_raw", "dbt_seed"], ensaio=False)
    assert c["task_ids"] == ["sincronizar_oltp_para_raw", "dbt_seed"] and c["only_failed"] is False
    assert c["dry_run"] is False


def test_sem_aplicar_so_ensaia(monkeypatch, capsys):
    sessao = _Sessao(["dbt_seed"])
    monkeypatch.setattr(composer_api, "_sessao", lambda: sessao)
    assert composer_api.main(["limpar", "--uri", "https://x/", "--dag", "fluxo_batch", "--run", "r1"]) == 0
    assert [p[1]["dry_run"] for p in sessao.pedidos] == [True]
    assert sessao.pedidos[0][0] == "https://x/api/v2/dags/fluxo_batch/clearTaskInstances"
    assert "nada foi limpo" in capsys.readouterr().out


def test_com_aplicar_ensaia_e_depois_limpa(monkeypatch):
    sessao = _Sessao(["dbt_seed"])
    monkeypatch.setattr(composer_api, "_sessao", lambda: sessao)
    assert composer_api.main(["limpar", "--uri", "u", "--dag", "d", "--run", "r", "--aplicar"]) == 0
    assert [p[1]["dry_run"] for p in sessao.pedidos] == [True, False]


@pytest.mark.parametrize("tarefas,status", [([], 200), (["x"], 403)])
def test_ensaio_vazio_ou_erro_da_api_e_falha(monkeypatch, tarefas, status):
    sessao = _Sessao(tarefas, status)
    monkeypatch.setattr(composer_api, "_sessao", lambda: sessao)
    assert composer_api.main(["limpar", "--uri", "u", "--dag", "d", "--run", "r", "--aplicar"]) == 1
    assert all(p[1]["dry_run"] for p in sessao.pedidos)


def test_o_alvo_do_makefile_so_limpa_com_aplicar():
    reexecutar = MAKEFILE.split("\ngcp-composer-reexecutar:", 1)[1].split("\n\n", 1)[0]
    assert "mvp_ed1.gcp.composer_api limpar" in reexecutar and "$(if $(APLICAR),--aplicar)" in reexecutar
