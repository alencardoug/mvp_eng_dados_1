"""O armazém da nuvem antes da época inicial: zerar e conferir (Etapa 13, A43)."""

from __future__ import annotations

import types

from mvp_ed1.gcp import armazem_janela


class _Cliente:
    def __init__(self, tabelas: dict[str, list[tuple[str, str, int]]]):
        self.tabelas = {ds: {nome: (tipo, linhas) for nome, tipo, linhas in itens} for ds, itens in tabelas.items()}
        self.apagadas: list[str] = []

    def list_tables(self, dataset):
        ds = dataset.split(".", 1)[1]
        return [types.SimpleNamespace(table_id=n, table_type=tipo) for n, (tipo, _) in self.tabelas.get(ds, {}).items()]

    def get_table(self, nome):
        _, ds, tabela = nome.split(".")
        return types.SimpleNamespace(num_rows=self.tabelas[ds][tabela][1])

    def delete_table(self, nome, not_found_ok=False):
        _, ds, tabela = nome.split(".")
        self.apagadas.append(f"{ds}.{tabela}")
        self.tabelas[ds].pop(tabela)


def _desenvolvimento() -> _Cliente:
    return _Cliente({
        "raw_legacy": [("legacy_customers", "TABLE", 100)],
        "governance": [("_versions", "TABLE", 2), ("legacy_captures", "TABLE", 760)],
        "consumption": [("vw_vendas", "VIEW", 0)],
        "raw": [("inventory_movements_stream", "TABLE", 0)],
    })


def test_o_desenvolvimento_impede_a_epoca():
    achados = armazem_janela.residuos(_desenvolvimento(), "p", ["raw_legacy", "governance", "consumption", "raw"])
    assert achados == ["raw_legacy.legacy_customers (100 linhas)", "governance.legacy_captures (760 linhas)",
                       "consumption.vw_vendas (view)"]


def test_zerar_apaga_tudo_e_depois_so_a_governanca_nova_passa():
    cliente = _desenvolvimento()
    datasets = ["raw_legacy", "governance", "consumption", "raw"]
    assert armazem_janela.zerar(cliente, "p", datasets) == {"raw_legacy": 1, "governance": 2, "consumption": 1, "raw": 1}
    # O que o `governanca` cria: o `_versions` com as migrações e o certificado vazio.
    cliente.tabelas["governance"] = {"_versions": ("TABLE", 2), "legacy_captures": ("TABLE", 0)}
    assert armazem_janela.residuos(cliente, "p", datasets) == []


def test_zerar_pede_o_id_do_projeto(monkeypatch, capsys):
    monkeypatch.setenv("GCP_PROJECT_ID", "p")
    monkeypatch.setattr(armazem_janela, "_cliente", lambda projeto: _desenvolvimento())
    assert armazem_janela.main(["zerar", "--datasets", '["raw"]', "--confirmar", "outro"]) == 1
    assert "CONFIRMA=p" in capsys.readouterr().err
    assert armazem_janela.main(["zerar", "--datasets", "[]", "--confirmar", "p"]) == 1
