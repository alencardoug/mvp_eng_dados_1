"""As origens no Cloud SQL a partir desta máquina: registros fora do `data/` local, proxy e replicação (Etapa 13)."""

from __future__ import annotations

import pathlib
import re

from mvp_ed1 import registros
from mvp_ed1.gcp import origens

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MAKEFILE = (RAIZ / "Makefile").read_text(encoding="utf-8")


def test_sem_a_variavel_os_registros_ficam_onde_sempre_ficaram(monkeypatch):
    from mvp_ed1.generator import cli as gerador
    from mvp_ed1.legacy import cli as legado

    monkeypatch.delenv(registros.ENV, raising=False)
    assert registros.raiz() is None and registros.raiz({registros.ENV: "  "}) is None
    assert gerador._registro_da_geracao() == gerador.REGISTRO_DA_GERACAO
    assert legado._manifestos() == legado.MANIFESTOS


def test_com_a_variavel_as_duas_cargas_gravam_na_outra_raiz(monkeypatch, tmp_path):
    from mvp_ed1.generator import cli as gerador
    from mvp_ed1.legacy import cli as legado

    monkeypatch.setenv(registros.ENV, str(tmp_path))
    assert gerador._registro_da_geracao() == tmp_path / "source" / "geracao.json"
    assert legado._manifestos() == tmp_path / "legacy"


def test_o_oraculo_le_o_manifesto_da_mesma_raiz_que_a_carga():
    fonte = (RAIZ / "src" / "mvp_ed1" / "recovery" / "sources.py").read_text(encoding="utf-8")
    assert 'outra / "legacy" / "manifesto.json"' in fonte
    assert "legacy_manifest=_load(str(legacy_manifest))" in fonte


def _receita(alvo: str) -> str:
    return MAKEFILE.split(f"\n{alvo}:", 1)[1].split("\n\n", 1)[0]


def test_os_alvos_do_cloud_sql_passam_pelo_proxy_e_nao_recarregam_o_env():
    alvos = [a for a in re.findall(r"^(gcp-[a-z0-9-]+):", MAKEFILE, re.M) if "$(GCP_ORIGENS)" in _receita(a)]
    assert set(alvos) == {"gcp-origens-migrar", "gcp-origens-povoar", "gcp-origens-oraculo",
                          "gcp-origens-replicacao", "gcp-g21-prova", "gcp-desmonte-slot", "gcp-livro-epoca"}
    for alvo in alvos:
        receita = _receita(alvo)
        assert receita.split("$(GCP_ORIGENS)")[0].count("$(GCP_LIMPEZA)") == 1, alvo
        # As macros locais recarregam o `.env` e apontariam de volta para os bancos locais.
        assert not re.search(r"\$\((ALEMBIC|ALEMBIC_LEGACY|GERADOR|RECOVERY|STREAM)\)", receita), alvo
    macro = MAKEFILE.split("\nGCP_ORIGENS = ", 1)[1].split("\n\n", 1)[0]
    assert 'export MVP_REGISTROS_DIR="$(GCP_REGISTROS)"' in macro
    assert 'pids="$$pids $$proxy"' in macro and "trap" not in macro and "mvp-ed1-$$origem-db-password" in macro
    # A carga não força: o gerador recusa banco com dados.
    assert "--force" not in _receita("gcp-origens-povoar")


def test_a_prova_do_g21_usa_o_legado_do_cloud_sql_como_coordenador():
    receita = _receita("gcp-g21-prova")
    assert 'WAREHOUSE_DB_NAME="$$LEGACY_DB_NAME"' in receita and "GCP_TESTES=1" in receita
    assert "PIPESTATUS[0]" in receita


class _Conexao:
    def __init__(self, tem: bool):
        self.tem, self.sql = tem, []

    def execution_options(self, **_):
        return self

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def execute(self, sql):
        texto = str(sql)
        self.sql.append(texto)
        if texto == origens.CONCEDER:
            self.tem = True
        return type("R", (), {"scalar_one": lambda _s: self.tem})()


class _Engine:
    def __init__(self, conexao):
        self.conexao = conexao

    def connect(self):
        return self.conexao


def test_a_replicacao_so_e_concedida_se_falta():
    falta = _Conexao(tem=False)
    assert origens.replicacao(_Engine(falta)) == (False, True)
    assert falta.sql == [origens.CONFERIR, origens.CONCEDER, origens.CONFERIR]
    ja = _Conexao(tem=True)
    assert origens.replicacao(_Engine(ja)) == (True, True)
    assert origens.CONCEDER not in ja.sql


def test_uma_limpeza_so_por_receita():
    limpeza = MAKEFILE.split("\nGCP_LIMPEZA = ", 1)[1].split("\n", 1)[0]
    assert "kill $$pids" in limpeza and 'rm -rf "$$base"' in limpeza
    airbyte = MAKEFILE.split("\nGKE_AIRBYTE = ", 1)[1].split("\n\n", 1)[0]
    assert 'pids="$$pids $$!"' in airbyte and "trap" not in airbyte
    for alvo in ("gcp-airbyte-config", "gcp-livro-epoca"):
        receita = _receita(alvo)
        assert receita.index("$(GCP_LIMPEZA)") < receita.index("$(GKE_KUBECTL)") < receita.index("$(GKE_AIRBYTE)"), alvo


def test_o_airbyte_da_nuvem_nao_muda_o_workspace_do_local():
    receita = _receita("gcp-airbyte-config")
    assert "TF_WORKSPACE=gcp $(TERRAFORM) apply -parallelism=1" in receita
    assert "workspace select gcp" not in receita and "-auto-approve" not in receita
    assert "TF_VAR_armazem=bigquery" in receita and "cloud_sql_ip_privado" in receita


def test_a_epoca_inicial_confere_antes_de_abrir():
    receita = _receita("gcp-livro-epoca")
    assert receita.index("armazem_janela pronto") < receita.index("mvp_ed1.recovery.ledger baseline")
    assert 'LEGACY_WAREHOUSE=bigquery LEGACY_LEDGER_DIR="$$raiz"' in receita and "livro_raiz" in receita
    assert '--confirmar "$(CONFIRMA)"' in _receita("gcp-armazem-zerar")
