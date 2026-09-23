"""Oráculos do medidor (`docker/medir.sh`) e da espera do livro quente.

O medidor existe porque o projeto tinha três formas de medir e nenhuma delas
separava **disparar** de **rodar**: `dag-run` devolve o controle assim que o
Airflow aceita o disparo, e `stream-run` nunca devolve. Uma medição que
confunde as duas coisas não é um número errado — é um número que parece certo.

Nada aqui toca em banco, em Docker real ou no Airflow. O medidor roda contra um
`Makefile` de mentira num diretório temporário, com um `docker` falso à frente
do `PATH`; a espera do livro roda contra um contador injetado, com relógio e
`sleep` próprios.
"""

from __future__ import annotations

import json
import os
import pathlib
import subprocess
import textwrap

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MEDIR = RAIZ / "docker" / "medir.sh"

DOCKER_FALSO = textwrap.dedent(
    """\
    #!/usr/bin/env bash
    # `docker` SIMULADO: o medidor só o consulta para dizer o que está de pé.
    case "$1" in
      ps) ;;
      stats) echo "10MiB / 11.5GiB" ;;
    esac
    exit 0
    """
)


def _ambiente(tmp_path: pathlib.Path, *, makefile: str) -> tuple[dict[str, str], pathlib.Path]:
    trabalho = tmp_path / "trabalho"
    trabalho.mkdir()
    (trabalho / "Makefile").write_text(makefile, encoding="utf-8")

    binario = tmp_path / "bin"
    binario.mkdir()
    falso = binario / "docker"
    falso.write_text(DOCKER_FALSO, encoding="utf-8")
    falso.chmod(0o755)

    destino = tmp_path / "medicoes"
    ambiente = os.environ | {
        "PATH": f"{binario}:{os.environ['PATH']}",
        "MEDIR_DIR": str(destino),
        "MEDIR_INTERVALO": "1",
        "MEDIR_PRAZO_ENCERRAMENTO": "5",
    }
    return ambiente, trabalho


def _medir(
    tmp_path: pathlib.Path, *args: str, makefile: str, timeout: int = 120
) -> subprocess.CompletedProcess[str]:
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)
    return subprocess.run(
        [str(MEDIR), *args],
        cwd=trabalho,
        capture_output=True,
        text=True,
        env=ambiente,
        timeout=timeout,
    )


def _registro(tmp_path: pathlib.Path) -> dict:
    arquivos = sorted((tmp_path / "medicoes").glob("*.json"))
    assert len(arquivos) == 1, arquivos
    return json.loads(arquivos[0].read_text(encoding="utf-8"))


# ── A agregação: extremos amostrados, com o que os qualifica ────────────────


def test_agregacao_acha_extremos_e_diz_de_quantas_amostras(tmp_path):
    """Uma série sintética: nem docker, nem /proc, nem relógio de verdade.

    O mínimo de disponível e o máximo de contêineres vêm de instantes
    diferentes de propósito — são duas grandezas distintas, e o registro as põe
    lado a lado sem fingir que uma explica a outra.
    """
    serie = tmp_path / "amostras"
    serie.write_text(
        "\n".join(
            [
                "1000 8000 3000",
                "1002 6500 3900",   # mínimo de disponível
                "1004 7000 4200",   # máximo de contêineres
                "1006 7200 3100",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    r = subprocess.run(
        [str(MEDIR), "--agregar", str(serie)], capture_output=True, text=True, timeout=60
    )
    valores = dict(l.split("=", 1) for l in r.stdout.split())

    assert r.returncode == 0, r.stderr
    assert valores["amostras"] == "4"
    assert valores["disponivel_minimo_mb"] == "6500"
    assert valores["disponivel_minimo_em"] == "1002"
    assert valores["conteineres_maximo_mb"] == "4200"
    assert valores["conteineres_maximo_em"] == "1004"
    assert valores["janela_s"] == "6"


def test_agregacao_de_serie_vazia_nao_inventa_extremos(tmp_path):
    """Zero amostras é `amostras=0`, não um mínimo de zero que pareceria medição."""
    serie = tmp_path / "vazia"
    serie.write_text("", encoding="utf-8")

    r = subprocess.run(
        [str(MEDIR), "--agregar", str(serie)], capture_output=True, text=True, timeout=60
    )

    assert r.returncode == 0, r.stderr
    assert r.stdout.split() == ["amostras=0"]


def test_leitura_que_falhou_nao_entra_no_extremo_e_e_contada(tmp_path):
    """RVE2-02: `NA` é amostra sem a grandeza, não zero — o extremo sai só das válidas."""
    serie = tmp_path / "amostras"
    # Se `NA` valesse zero, o mínimo de disponível seria 0 em 1002.
    serie.write_text("1000 8000 NA\n1002 NA 3900\n1004 7000 3100\n", encoding="utf-8")

    r = subprocess.run(
        [str(MEDIR), "--agregar", str(serie)], capture_output=True, text=True, timeout=60
    )
    valores = dict(l.split("=", 1) for l in r.stdout.split())

    assert r.returncode == 0, r.stderr
    assert valores["amostras"] == "3"
    assert (valores["disponivel_minimo_mb"], valores["disponivel_minimo_em"]) == ("7000", "1004")
    assert (valores["conteineres_maximo_mb"], valores["conteineres_maximo_em"]) == ("3900", "1002")
    assert valores["disponivel_falhas"] == "1" and valores["conteineres_falhas"] == "1"


def test_grandeza_sem_nenhuma_leitura_e_null_e_nao_zero(tmp_path):
    serie = tmp_path / "amostras"
    serie.write_text("1000 8000 NA\n1002 7900 NA\n", encoding="utf-8")

    r = subprocess.run(
        [str(MEDIR), "--agregar", str(serie)], capture_output=True, text=True, timeout=60
    )
    valores = dict(l.split("=", 1) for l in r.stdout.split())

    assert valores["conteineres_maximo_mb"] == "null"
    assert "conteineres_maximo_em" not in valores, "não há instante de um extremo que não existe"
    assert valores["conteineres_falhas"] == "2"


# ── Recusar antes de medir ──────────────────────────────────────────────────


def test_alvo_inexistente_falha_antes_de_amostrar(tmp_path):
    """Medir o nada produziria um registro com cara de medição."""
    r = _medir(tmp_path, "alvo_que_nao_existe", makefile="real:\n\t@true\n")

    assert r.returncode == 2, r.stdout
    assert "não é um alvo do Makefile" in r.stderr
    assert not (tmp_path / "medicoes").exists()


def test_ate_inexistente_falha_antes_de_executar_o_alvo(tmp_path):
    """A espera é conferida antes, porque depois o alvo já rodou.

    Rodar `dbt-build` e só então descobrir que `ATE=` está errado custa a
    execução inteira — e a medição se perde junto.
    """
    makefile = "real:\n\t@touch rodou\n"
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)
    r = subprocess.run(
        [str(MEDIR), "real", "--ate", "espera_que_nao_existe"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60,
    )

    assert r.returncode == 2, r.stdout
    assert not (trabalho / "rodou").exists(), "o alvo não podia ter rodado"


def test_validar_o_alvo_nao_executa_receita_recursiva(tmp_path):
    """RVE-02: `make -n` executa de verdade toda linha com `$(MAKE)`.

    A "validação" de `airbyte-up` chamava `abctl local install` antes de o
    preflight rodar. O `Makefile` de mentira registra o que executa: a
    validação precisa reconhecer o alvo **sem** que o registrador rode antes
    da medição — e um alvo inexistente continua recusado.
    """
    makefile = (
        "instala:\n\t@echo instalou >> registro\n"
        "sobe:\n\t@if true; then $(MAKE) --no-print-directory instala; fi\n"
    )
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)

    r = subprocess.run(
        [str(MEDIR), "sobe"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60,
    )

    assert r.returncode == 0, r.stdout + r.stderr
    registro = (trabalho / "registro").read_text(encoding="utf-8")
    assert registro == "instalou\n", "a receita rodou uma vez — na medição, não na validação"

    r = subprocess.run(
        [str(MEDIR), "sobe", "--ate", "alvo_que_nao_existe"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60,
    )
    assert r.returncode == 2, r.stdout
    assert (trabalho / "registro").read_text(encoding="utf-8") == "instalou\n", (
        "recusar o `ATE` não pode ter executado o alvo"
    )


# ── A medição em si ─────────────────────────────────────────────────────────


def test_medicao_registra_duracao_codigo_e_a_linha_da_tabela(tmp_path):
    r = _medir(tmp_path, "trabalho", makefile="trabalho:\n\t@sleep 3\n")

    assert r.returncode == 0, r.stderr
    registro = _registro(tmp_path)
    assert registro["alvo"] == "trabalho"
    assert registro["ate"] is None
    assert registro["codigo_de_saida"] == 0
    assert registro["interrompido"] is False
    assert registro["duracao_involucro_s"] >= 3
    assert registro["amostragem"]["amostras"] >= 2
    assert registro["amostragem"]["intervalo_s"] == 1
    # O limite vai no registro, não num comentário que ninguém lê depois.
    assert "não inclui o Beam" in registro["limite"]
    # A linha impressa é a da tabela da Capacidade.
    linha = [l for l in r.stdout.splitlines() if l.startswith("| trabalho |")]
    assert len(linha) == 1, r.stdout
    assert "amostras a cada 1s" in linha[0]


def _docker_com_stats(tmp_path: pathlib.Path, stats: str) -> None:
    """Troca o `docker` simulado: `ps` diz o Airbyte de pé, `stats` faz o que o caso pede."""
    (tmp_path / "bin" / "docker").write_text(
        "#!/usr/bin/env bash\n"
        "# `docker` SIMULADO.\n"
        'case "$1" in\n'
        '  ps) [[ "$*" == *--filter* ]] || echo airbyte-abctl-control-plane; exit 0 ;;\n'
        f"  stats) {stats} ;;\n"
        "esac\n",
        encoding="utf-8",
    )


@pytest.mark.parametrize(
    "stats",
    [
        pytest.param('echo "daemon unavailable" >&2; exit 1', id="stats-falha"),
        pytest.param('echo "-- / --"; exit 0', id="linha-sem-numero"),
    ],
)
def test_docker_stats_que_nao_mede_vira_nao_medido_e_nao_zero(tmp_path, stats):
    """RVE2-02, a sonda do revisor: Airbyte de pé, `stats` falhando — e o JSON dizia máximo 0.

    O código de saída continua sendo o do alvo, que rodou; o que muda é o que
    o registro afirma sobre a memória dos contêineres.
    """
    ambiente, trabalho = _ambiente(tmp_path, makefile="alvo:\n\t@sleep 2\n")
    _docker_com_stats(tmp_path, stats)

    r = subprocess.run(
        [str(MEDIR), "alvo"], cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60
    )

    assert r.returncode == 0, r.stdout + r.stderr
    amostragem = _registro(tmp_path)["amostragem"]
    assert amostragem["amostras"] >= 2
    assert amostragem["conteineres_maximo_mb"] is None
    assert amostragem["conteineres_falhas"] == amostragem["amostras"]
    assert "conteineres_maximo_em" not in amostragem
    assert amostragem["disponivel_minimo_mb"] > 0 and amostragem["disponivel_falhas"] == 0
    linha = next(l for l in r.stdout.splitlines() if l.startswith("| alvo |"))
    assert "não medido" in linha and "0.0 GB" not in linha, linha
    assert "leitura que falhou não é zero" in r.stdout


def test_nenhum_conteiner_de_pe_e_zero_lido(tmp_path):
    """O outro lado: `stats` que responde sem linha nenhuma é soma zero **medida**."""
    ambiente, trabalho = _ambiente(tmp_path, makefile="alvo:\n\t@sleep 2\n")
    _docker_com_stats(tmp_path, "exit 0")

    r = subprocess.run(
        [str(MEDIR), "alvo"], cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60
    )

    assert r.returncode == 0, r.stdout + r.stderr
    amostragem = _registro(tmp_path)["amostragem"]
    assert amostragem["conteineres_maximo_mb"] == 0 and amostragem["conteineres_falhas"] == 0


def test_ate_roda_depois_do_alvo_e_entra_no_registro(tmp_path):
    makefile = "disparo:\n\t@echo disparei\nespera:\n\t@sleep 2\n"
    r = _medir(tmp_path, "disparo", "--ate", "espera", makefile=makefile)

    assert r.returncode == 0, r.stderr
    registro = _registro(tmp_path)
    assert registro["ate"] == "espera"
    assert registro["duracao_involucro_s"] >= 2, "a espera precisa estar dentro da medição"


def test_falha_da_espera_propaga_a_falha(tmp_path):
    """Disparar e falhar na espera é falha: a DAG não chegou a `success`.

    O código que chega é o do `make`, que achata qualquer `exit N` da receita
    em 2 — está escrito assim no medidor, porque fingir que o número original
    sobrevive seria pior que perdê-lo. O que distingue "falhou" de "venceu o
    prazo" é a mensagem do alvo de espera, não este inteiro.
    """
    makefile = "disparo:\n\t@true\nespera:\n\t@exit 3\n"
    r = _medir(tmp_path, "disparo", "--ate", "espera", makefile=makefile)

    assert r.returncode != 0, r.stdout
    registro = _registro(tmp_path)
    assert registro["codigo_de_saida"] == r.returncode
    assert registro["codigo_de_saida"] != 0


def test_duas_medicoes_do_mesmo_alvo_deixam_dois_registros(tmp_path):
    """RVE-13: snapshot, eventos novos e recuperação são três `cenario:streaming`.

    Um nome por dia deixava só a última — e a evidência de B5 se perdia entre
    si. O nome leva o instante e os parâmetros que distinguem as execuções.
    """
    makefile = "alvo:\n\t@true\nespera:\n\t@true\n"
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)
    for args in (["alvo"], ["alvo"], ["alvo", "--ate", "espera"]):
        r = subprocess.run(
            [str(MEDIR), *args],
            cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=60,
        )
        assert r.returncode == 0, r.stdout + r.stderr

    arquivos = sorted((tmp_path / "medicoes").glob("*.json"))
    assert len(arquivos) == 3, arquivos
    assert any(a.name.endswith("_ate_espera.json") for a in arquivos), [a.name for a in arquivos]
    registros = [json.loads(a.read_text(encoding="utf-8")) for a in arquivos]
    assert [r["parametros"] for r in registros] == [
        {"limite": None, "corte": None},
        {"limite": None, "corte": None},
        {"limite": None, "corte": None},
    ]


def test_interrupcao_deixa_o_registro_com_a_marca(tmp_path):
    """RVE-12: o trap saía com 130 e nenhum JSON — a medição abortada não
    deixava rastro nem de ter começado."""
    import signal
    import time

    makefile = "alvo:\n\t@touch pronto; sleep 2\n"
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)
    processo = subprocess.Popen(
        [str(MEDIR), "alvo"],
        cwd=trabalho, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        env=ambiente, start_new_session=True,
    )
    try:
        limite = time.monotonic() + 10
        while not (trabalho / "pronto").exists() and time.monotonic() < limite:
            time.sleep(0.05)
        processo.send_signal(signal.SIGTERM)
        saida, _ = processo.communicate(timeout=30)
    finally:
        if processo.poll() is None:
            os.killpg(processo.pid, signal.SIGKILL)

    assert processo.returncode == 130, saida
    registro = _registro(tmp_path)
    assert registro["interrompido"] is True
    assert registro["codigo_de_saida"] == 130
    assert "[medir] interrompido" in saida


# ── O modo de cenário: processo concorrente sob guarda ──────────────────────

CENARIO_OK = textwrap.dedent(
    """\
    stream-up:
    \t@echo subiu
    stream-run:
    \t@echo $$$$ > pipeline.pid; sleep 600
    stream-produce:
    \t@echo "produzi $(LIMITE)" > produziu
    stream-corte:
    \t@cat corte 2>/dev/null || echo 7
    stream-wait:
    \t@echo "esperei ate $(ATE_SEQ) vigiando $(PID)" > esperou
    """
)


def test_cenario_le_o_corte_depois_do_produtor(tmp_path):
    """RV12-2-06: corte lido antes do produtor fecharia no snapshot.

    O `Makefile` de mentira muda o corte **durante** a produção: se o medidor
    lesse antes, esperaria o número velho.
    """
    makefile = CENARIO_OK.replace(
        '\t@echo "produzi $(LIMITE)" > produziu',
        '\t@echo "produzi $(LIMITE)" > produziu; echo 99 > corte',
    )
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)
    (trabalho / "corte").write_text("7\n", encoding="utf-8")

    r = subprocess.run(
        [str(MEDIR), "--cenario", "streaming", "--limite", "5"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=120,
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert (trabalho / "produziu").read_text(encoding="utf-8").strip() == "produzi 5"
    assert "esperei ate 99" in (trabalho / "esperou").read_text(encoding="utf-8")
    # O que distingue esta execução das outras do mesmo cenário vai no registro (RVE-13).
    registro = _registro(tmp_path)
    assert registro["parametros"] == {"limite": 5, "corte": 99}
    assert "_limite_5" in sorted((tmp_path / "medicoes").glob("*.json"))[0].name


def test_cenario_sem_limite_fecha_no_corte_inicial(tmp_path):
    """O *snapshot* não tem produtor: o corte inicial é o fim, e não muda."""
    ambiente, trabalho = _ambiente(tmp_path, makefile=CENARIO_OK)
    (trabalho / "corte").write_text("7\n", encoding="utf-8")

    r = subprocess.run(
        [str(MEDIR), "--cenario", "streaming"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=120,
    )

    assert r.returncode == 0, r.stdout + r.stderr
    assert not (trabalho / "produziu").exists(), "não há produtor neste cenário"
    assert "esperei ate 7" in (trabalho / "esperou").read_text(encoding="utf-8")


def test_cenario_encerra_o_que_iniciou_e_so_isso(tmp_path):
    """O pipeline sobe em segundo plano e precisa morrer no fim — e nada além.

    Um processo alheio, iniciado fora do medidor, é a contraprova: se ele
    também morrer, o encerramento está matando pelo que encontra, não pelo que
    anotou.
    """
    ambiente, trabalho = _ambiente(tmp_path, makefile=CENARIO_OK)
    (trabalho / "corte").write_text("7\n", encoding="utf-8")
    alheio = subprocess.Popen(["sleep", "120"])
    try:
        r = subprocess.run(
            [str(MEDIR), "--cenario", "streaming"],
            cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=120,
        )

        assert r.returncode == 0, r.stdout + r.stderr
        pid = int((trabalho / "pipeline.pid").read_text(encoding="utf-8").strip())
        with pytest.raises(OSError):
            os.kill(pid, 0)  # o pipeline que o medidor iniciou morreu
        assert alheio.poll() is None, "o medidor matou um processo que não iniciou"
    finally:
        alheio.kill()
        alheio.wait()


def test_cenario_propaga_a_falha_de_quem_morre(tmp_path):
    """Pipeline que não sobe é falha da medição, não uma medição de zero."""
    makefile = CENARIO_OK.replace(
        "\t@echo $$$$ > pipeline.pid; sleep 600", "\t@exit 1"
    )
    ambiente, trabalho = _ambiente(tmp_path, makefile=makefile)

    r = subprocess.run(
        [str(MEDIR), "--cenario", "streaming"],
        cwd=trabalho, capture_output=True, text=True, env=ambiente, timeout=120,
    )

    assert r.returncode != 0, r.stdout
    assert not (trabalho / "esperou").exists(), "não se espera o que não subiu"


# ── A espera do livro quente: o fim que o pipeline não tem ──────────────────

from mvp_ed1.streaming import espera  # noqa: E402 — depois dos utilitários acima


class Relogio:
    """Relógio e `sleep` de mentira: a espera é medida, não vivida."""

    def __init__(self) -> None:
        self.agora = 0.0
        self.dormidas: list[float] = []

    def __call__(self) -> float:
        return self.agora

    def dormir(self, s: float) -> None:
        self.dormidas.append(s)
        self.agora += s


def _faltantes(faltam: int, *, origem: int = 10, intrusas: int = 0) -> espera.Faltantes:
    return espera.Faltantes(
        origem=origem, livro=origem - faltam, faltam=faltam, intrusas=intrusas
    )


def test_espera_continua_depois_de_o_produtor_terminar(tmp_path, monkeypatch):
    """A contraprova da segunda rodada de revisão do plano.

    O produtor termina quando gravou na origem; o último evento ainda está em
    trânsito pelo CDC. Fechar a espera aí mediria o produtor, não o caminho
    quente — e diria que chegou o que não chegou.
    """
    leituras = [_faltantes(3), _faltantes(1), _faltantes(1), _faltantes(0)]
    monkeypatch.setattr(espera, "pendentes", lambda *_a, **_k: leituras.pop(0))
    relogio = Relogio()

    r = espera.aguardar(
        99, prazo_s=600, intervalo_s=2, relogio=relogio, dormir=relogio.dormir
    )

    assert r.alcancado and r.motivo == "alcancado"
    assert leituras == [], "a espera parou antes do livro alcançar o corte"
    assert relogio.dormidas == [2, 2, 2]


def test_espera_de_snapshot_fecha_no_corte_inicial(tmp_path, monkeypatch):
    """Sem produtor, o corte é o `max` do início e o livro já pode tê-lo."""
    monkeypatch.setattr(espera, "pendentes", lambda *_a, **_k: _faltantes(0))
    relogio = Relogio()

    r = espera.aguardar(7, prazo_s=600, relogio=relogio, dormir=relogio.dormir)

    assert r.alcancado
    assert relogio.dormidas == [], "não havia o que esperar"


def test_prazo_vencido_nao_e_sucesso(tmp_path, monkeypatch):
    monkeypatch.setattr(espera, "pendentes", lambda *_a, **_k: _faltantes(2))
    relogio = Relogio()

    r = espera.aguardar(
        99, prazo_s=10, intervalo_s=2, relogio=relogio, dormir=relogio.dormir
    )

    assert not r.alcancado and r.motivo == "prazo"
    assert r.ultimo.faltam == 2


def test_pipeline_que_morre_encerra_a_espera_na_hora(tmp_path, monkeypatch):
    """Esperar o prazo inteiro por um processo morto é desperdiçar meia hora."""
    monkeypatch.setattr(espera, "pendentes", lambda *_a, **_k: _faltantes(2))
    relogio = Relogio()

    r = espera.aguardar(
        99, prazo_s=1800, intervalo_s=2, vivo=lambda: False,
        relogio=relogio, dormir=relogio.dormir,
    )

    assert not r.alcancado and r.motivo == "morreu"
    assert relogio.dormidas == [], "não dormiu nem uma vez com o pipeline morto"


def test_o_oraculo_e_de_chaves_e_nao_de_contagem(tmp_path, monkeypatch):
    """Uma chave faltando e outra sobrando mantêm a contagem igual.

    É a mesma insuficiência que a revisão da Etapa 12 achou no oráculo da
    quarentena (RV12-4-02): contar os dois lados aceita a troca de uma linha
    por outra. Aqui o livro tem o mesmo tamanho da origem e **não** a contém.
    """
    monkeypatch.setattr(espera, "_motor", lambda _p: None)
    monkeypatch.setattr(
        espera,
        "_chaves",
        lambda _motor, relacao, _ate: (
            {"a", "b", "c"} if "inventory_movements" == relacao.split(".")[-1] else {"a", "b", "z"}
        ),
    )

    f = espera.pendentes(99, destino="raw.inventory_movements_stream")

    assert f.origem == f.livro == 3, "as contagens são iguais — é esse o ponto"
    assert not f.alcancado
    assert f.faltam == 1 and f.exemplos == ["c"]
    assert f.intrusas == 1
