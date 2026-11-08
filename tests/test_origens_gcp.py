"""As origens no Cloud SQL a partir desta máquina: registros fora do `data/` local, proxy e replicação (Etapa 13)."""

from __future__ import annotations

import pytest

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
                          "gcp-origens-replicacao", "gcp-g21-prova", "gcp-desmonte-slot", "gcp-livro-epoca",
                          "gcp-sync-legacy", "gcp-debezium-status", "gcp-quente-produzir", "gcp-quente-conferir",
                          "gcp-legado-mutar", "gcp-quente-latencia"}
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
    assert 'pids="$$pids $$encaminhamento"' in airbyte and "trap" not in airbyte
    for alvo in ("gcp-airbyte-config", "gcp-livro-epoca"):
        receita = _receita(alvo)
        assert receita.index("$(GCP_LIMPEZA)") < receita.index("$(GKE_KUBECTL)") < receita.index("$(GKE_AIRBYTE)"), alvo


def test_o_airbyte_da_nuvem_nao_muda_o_workspace_do_local():
    receita = _receita("gcp-airbyte-config")
    assert 'TF_WORKSPACE=gcp $(TERRAFORM) plan -input=false -no-color -parallelism=1 -out="$$base/airbyte.tfplan"' in receita
    assert 'TF_WORKSPACE=gcp $(TERRAFORM) apply -input=false -no-color -parallelism=1 "$$base/airbyte.tfplan"' in receita
    assert receita.index('test "$$resposta" = "$$GCP_PROJECT_ID"') < receita.index("apply -input=false"), \
        "o apply só depois de o Owner ler o plano e digitar o id (RV13J-1-11)"
    assert "workspace select gcp" not in receita and "-auto-approve" not in receita
    assert "TF_VAR_armazem=bigquery" in receita and "cloud_sql_ip_privado" in receita


def test_a_epoca_inicial_confere_antes_de_abrir():
    receita = _receita("gcp-livro-epoca")
    assert receita.index("armazem_janela pronto") < receita.index("mvp_ed1.recovery.ledger baseline")
    livro = MAKEFILE.split("\nGCP_LIVRO = ", 1)[1].split("\n\n", 1)[0]
    assert 'export LEGACY_WAREHOUSE=bigquery LEGACY_LEDGER_DIR="$$raiz"' in livro and "livro_raiz" in livro
    # A época e a captura do legado leem o mesmo livro e o mesmo armazém.
    for alvo in ("gcp-livro-epoca", "gcp-sync-legacy"):
        assert "$(GCP_ORIGENS); $(GCP_LIVRO);" in _receita(alvo), alvo
    assert '--confirmar "$(CONFIRMA)"' in _receita("gcp-armazem-zerar")


def test_a_captura_do_legado_e_a_certificada():
    assert "--connection legacy_para_raw_legacy --certificar-legado" in _receita("gcp-sync-legacy")
    assert "--connection oltp_para_raw" in _receita("gcp-sync-retail")


def test_as_tags_leem_o_manifest_do_alvo_gcp():
    for alvo in ("gcp-tags-convergir", "gcp-tags-inventario"):
        receita = _receita(alvo)
        assert "--manifest dbt/target_gcp/manifest.json" in receita and "output -json policy_tags" in receita, alvo


def test_o_destino_quente_confere_contra_a_origem():
    from mvp_ed1.gcp import quente

    origem = {"movimentos": 10, "max_event_sequence": 10}
    assert quente.comparar(origem, {"movimentos": 10, "linhas": 10, "max_event_sequence": 10}) == []
    atrasado = quente.comparar(origem, {"movimentos": 7, "linhas": 7, "max_event_sequence": 7})
    assert len(atrasado) == 1 and "7 de 10" in atrasado[0]
    repetido = quente.comparar(origem, {"movimentos": 10, "linhas": 12, "max_event_sequence": 10})
    assert repetido == ["destino com 2 linhas repetidas por movement_id"]


def test_a_memoria_e_os_jobs_leem_o_livro_da_nuvem():
    memoria = _receita("gcp-memoria-oraculo")
    assert "$(GCP_ENV); $(GCP_LIVRO);" in memoria and 'mvp_ed1.recovery.memory_oracle --diary "$$diario" --out' in memoria
    assert 'diario="$(GCP_REGISTROS)/legacy/manifesto.json"' in memoria
    assert "$(GCP_ENV); $(GCP_LIVRO); .venv/bin/python -m mvp_ed1.recovery.ledger treatment" in _receita("gcp-livro-tratamento")
    jobs = _receita("gcp-jobs-auditoria")
    assert jobs.index("$(GKE_AIRBYTE)") < jobs.index("$(GCP_LIVRO)") < jobs.index("mvp_ed1.recovery.job_audit")


def test_a_latencia_e_a_primeira_vez_que_o_destino_mostra_o_evento():
    import datetime as dt
    import types

    from mvp_ed1.gcp import quente

    t0 = dt.datetime(2026, 11, 10, 12, 0, tzinfo=dt.timezone.utc)
    consultas = [
        [(1, 0, 4)],                       # o evento 1, gravado em t0, visto em t0 + 4 s
        [(1, 0, 9), (2, 1, 9)],            # o 1 de novo não muda a sua; o 2 entra com 8 s
        [(1, 0, 14), (2, 1, 14), (3, 2, 14)],
    ]

    class Cliente:
        def query(self, sql):
            assert "not _stream_from_snapshot" in sql and "event_sequence > 10" in sql
            linhas = consultas.pop(0) if consultas else [(1, 0, 20), (2, 1, 20), (3, 2, 20)]
            return types.SimpleNamespace(result=lambda: [
                {"event_sequence": 10 + s, "recorded_at": t0 + dt.timedelta(seconds=r), "agora": t0 + dt.timedelta(seconds=a)}
                for s, r, a in linhas])

    relogio = iter(range(0, 10_000, 5))
    produtor = iter([None, 0])
    relatorio = quente.latencia(Cliente(), "p", "raw.t", 10, produtor=lambda: next(produtor, 0),
                                esperados=lambda: 3, prazo=900, intervalo=5, minimo=3,
                                relogio=lambda: next(relogio), pausa=lambda s: None)
    assert relatorio["completo"] and relatorio["vistos"] == 3 and relatorio["esperados"] == 3
    assert (relatorio["min_s"], relatorio["max_s"]) == (4.0, 12.0)


def _latencia_com(linhas, saidas, esperados, minimo=200):
    import types

    from mvp_ed1.gcp import quente

    class Cliente:
        def query(self, sql):
            return types.SimpleNamespace(result=lambda: list(linhas))

    relogio = iter(range(0, 10_000, 5))
    saidas = iter(saidas)
    return quente.latencia(Cliente(), "p", "raw.t", 10, produtor=lambda: next(saidas, None),
                           esperados=lambda: esperados, prazo=60, intervalo=5, minimo=minimo,
                           relogio=lambda: next(relogio), pausa=lambda s: None)


@pytest.mark.parametrize("saidas, esperados, motivo", [
    ([1], 0, "o produtor saiu com 1"),                   # falhou antes de gravar
    ([None, 1], 40, "o produtor saiu com 1"),            # falhou depois de uma rajada
    ([0], 0, "menos que os 200 pedidos"),                # terminou bem e nada chegou à origem
    ([0], 120, "menos que os 200 pedidos"),
    ([None] * 100, 0, "ainda rodava no fim do prazo"),
])
def test_a_latencia_sem_producao_valida_nao_e_completa(saidas, esperados, motivo):
    """RV13J-1-05: zero esperados e zero vistos não aprovam; o desfecho do produtor conta."""
    relatorio = _latencia_com([], saidas, esperados)
    assert not relatorio["completo"] and motivo in relatorio["motivo"]


def test_conferir_compara_chave_e_conteudo_e_nao_so_a_contagem():
    """RV13J-1-10: um perdido e um indevido não mudam contagem nem máximo; o conteúdo os vê."""
    import datetime as dt
    import decimal

    from mvp_ed1.gcp import quente

    def mov(i, **troca):
        linha = {c: None for c in quente.COLUNAS}
        linha.update(movement_id=f"m{i}", event_sequence=i, quantity_delta=-2,
                     unit_cost=decimal.Decimal("10.50"),
                     occurred_at=dt.datetime(2026, 11, 10, 9, 0, i, tzinfo=dt.timezone(dt.timedelta(hours=-3))))
        linha.update(troca)
        return linha

    origem = [mov(1), mov(2), mov(3)]
    igual = [mov(1, unit_cost=decimal.Decimal("10.5000"),
                 occurred_at=dt.datetime(2026, 11, 10, 12, 0, 1, tzinfo=dt.timezone.utc)), mov(2), mov(3)]
    assert quente.comparar_conteudo(origem, igual) == []
    trocado = [mov(1), mov(2), mov(4, event_sequence=3)]
    assert quente.comparar({"movimentos": 3, "max_event_sequence": 3},
                           {"movimentos": 3, "linhas": 3, "max_event_sequence": 3}) == []
    problemas = quente.comparar_conteudo(origem, trocado)
    assert any("sem 1 movimento(s) da origem: ['m3']" in p for p in problemas)
    assert any("que a origem não tem: ['m4']" in p for p in problemas)
    assert any("em ['unit_cost']" in p for p in quente.comparar_conteudo(origem, [mov(1, unit_cost=decimal.Decimal("10.51")), mov(2), mov(3)]))
    assert any("repetido" in p for p in quente.comparar_conteudo(origem, [mov(1), mov(1), mov(2), mov(3)]))


def test_o_tamanho_e_por_dataset_e_os_alvos_novos():
    import types

    from mvp_ed1.gcp import armazem_janela

    class Cliente:
        def query(self, sql):
            assert "__TABLES__" in sql
            return types.SimpleNamespace(result=lambda: [{"tabelas": 2, "linhas": 10, "bytes": 2048}])

    assert armazem_janela.tamanho(Cliente(), "p", ["raw", "governance"]) == {
        "governance": {"tabelas": 2, "linhas": 10, "bytes_logicos": 2048},
        "raw": {"tabelas": 2, "linhas": 10, "bytes_logicos": 2048},
    }
    assert "quente latencia --limite $(or $(LIMITE),200)" in _receita("gcp-quente-latencia")
    assert "armazem_janela tamanho" in _receita("gcp-armazem-tamanho")


def test_a_amostra_minima_e_de_ao_menos_um_evento():
    """RV13J-2-04: com `--limite 0`, zero esperados e zero vistos davam `completo`."""
    from mvp_ed1.gcp import quente

    with pytest.raises(ValueError, match="ao menos um evento"):
        _latencia_com([], [0], 0, minimo=0)
    with pytest.raises(SystemExit):
        quente.main(["latencia", "--limite", "0"])
