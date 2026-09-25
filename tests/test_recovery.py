"""O pacote de recuperação: o re-base das gerações e os oráculos do manifesto.

Sem banco, sem Docker e sem pacote. O que se prova aqui são as duas regras que
a revisão do plano da Etapa 12 mostrou serem insuficientes como estavam:

* o re-base "negativo e idempotente" (D52) admitia uma implementação que funde
  classes de geração no **segundo** ciclo — RV12-4-01;
* os oráculos por **contagem** aceitam uma linha trocada por outra do mesmo
  grupo — RV12-3-05 no SCD, RV12-4-02 na quarentena.

Os dois casos têm a mesma assinatura: o número continua igual e o conteúdo
mudou. É por isso que cada contraprova abaixo mantém a contagem constante de
propósito — se ela mudasse, o oráculo antigo também teria pego.
"""

from __future__ import annotations

import pytest

from mvp_ed1.recovery import oraculos, rebase

# ── O re-base (D52 + RV12-4-01) ─────────────────────────────────────────────


def test_primeiro_ciclo_manda_as_gerações_retidas_para_a_faixa_negativa():
    """`raw_legacy.customers` retém as gerações 1–28, uma por job, de 9 a 43."""
    mapa = rebase.plano(range(1, 29))

    assert mapa[1] == -28 and mapa[28] == -1
    assert rebase.conforme(mapa) == []
    assert all(v < 0 for v in mapa.values())
    assert len(set(mapa.values())) == 28, "nenhuma classe foi fundida"


def test_aplicar_duas_vezes_e_aplicar_uma():
    mapa = rebase.plano(range(1, 29))
    de_novo = rebase.plano(mapa.values())

    assert all(de_novo[destino] == destino for destino in mapa.values())


def test_segundo_ciclo_nao_funde_o_retido_com_o_da_restauracao_anterior():
    """O contraexemplo da quarta rodada de revisão, agora como contrato.

    Depois de uma restauração o bruto tem geração `-1` antiga e `1` nova. Um
    re-base que apenas negue as positivas e mantenha as negativas satisfaz
    "negativo" e "idempotente" — e **funde as duas em `-1`**. A sonda mediu o
    veredito passando de `complete` a `inconsistent` sem o hash mudar: a
    captura recusada com o conteúdo correto.
    """
    ingenuo = {-1: -1, 1: -1}
    problemas = rebase.conforme(ingenuo)
    assert any("fundidas" in p for p in problemas), problemas

    honesto = rebase.plano([-1, 1])
    assert rebase.conforme(honesto) == []
    assert honesto[-1] != honesto[1], "as duas classes continuam distintas"
    assert honesto[-1] < honesto[1] < 0, "a ordem é preservada e tudo fica negativo"


def test_segundo_ciclo_completo_com_vinte_e_oito_retidas_e_duas_novas():
    mapa = rebase.plano(list(range(-28, 0)) + [1, 2])

    assert len(set(mapa.values())) == 30
    assert rebase.conforme(mapa) == []
    assert max(mapa.values()) == -1 and min(mapa.values()) == -30
    # As retidas continuam **abaixo** das que acabaram de chegar: a ordem
    # cronológica das gerações sobrevive ao re-base.
    assert mapa[-28] < mapa[-1] < mapa[1] < mapa[2]


def test_geracao_nula_recua_em_vez_de_inventar_faixa():
    """Sem geração não há faixa, e a conferência de intrusas fica cega nela."""
    with pytest.raises(rebase.RebaseImpossivel) as erro:
        rebase.plano([1, 2, None])

    assert "não foi aplicado" in str(erro.value)


def test_o_dominio_aceita_um_iterador_sem_perder_a_segunda_passagem():
    """RVE-16: a contagem de nulos esgotava o iterador antes da busca por positivas."""
    assert rebase.dominio_valido(iter([0, 1])) != []
    assert rebase.dominio_valido(iter([None, -1])) != []
    assert rebase.dominio_valido(iter([-2, -1])) == []


def test_o_dominio_confere_nulo_e_nao_so_ausencia_de_positiva():
    """"Nenhuma geração positiva" é satisfeito por um nulo — e era o oráculo antigo."""
    assert rebase.dominio_valido([-3, -2, -1]) == []

    so_nulo = rebase.dominio_valido([-3, None, -1])
    assert any("nula" in p for p in so_nulo), so_nulo

    com_positiva = rebase.dominio_valido([-3, 0, 5])
    assert any("não negativas" in p for p in com_positiva), com_positiva


def test_a_particao_das_linhas_e_o_oraculo_do_passo():
    """Mesma quantidade de classes não basta: as linhas podem ter trocado de lugar."""
    antes = rebase.particao([("a", 1), ("b", 1), ("c", 2)])
    mapa = rebase.plano([1, 2])
    depois = rebase.particao([("a", mapa[1]), ("b", mapa[1]), ("c", mapa[2])])

    assert rebase.particao_preservada(antes, depois) == []

    # Duas classes antes, duas depois — e `b` mudou de lado.
    permutado = rebase.particao([("a", -2), ("b", -1), ("c", -1)])
    problemas = rebase.particao_preservada(antes, permutado)
    assert any("agrupamento" in p for p in problemas), problemas


def test_intrusa_ja_presente_no_conjunto_retido_continua_detectavel():
    """O re-base não pode esconder o que a certificação existe para achar.

    Se duas linhas de `sync_id` diferentes compartilhavam uma geração antes —
    que é como uma intrusa se apresenta —, elas precisam continuar
    compartilhando depois. Separá-las por *job* faria a intrusa desaparecer do
    radar sem que nada tivesse sido corrigido.
    """
    linhas = [(("43", "a"), 28), (("99", "intrusa"), 28), (("42", "b"), 27)]
    antes = rebase.particao([(chave, g) for chave, g in linhas])
    mapa = rebase.plano(g for _chave, g in linhas)
    depois = rebase.particao([(chave, mapa[g]) for chave, g in linhas])

    assert rebase.particao_preservada(antes, depois) == []
    intrusa_e_hospedeira = next(c for c in depois.values() if len(c) == 2)
    assert {("43", "a"), ("99", "intrusa")} == set(intrusa_e_hospedeira)


# ── Os oráculos do manifesto (RV12-3-05 e RV12-4-02) ────────────────────────


def _versao(scd_id: str, de: str, ate: str | None, atributo: str) -> dict:
    return {
        "dbt_scd_id": scd_id,
        "dbt_valid_from": de,
        "dbt_valid_to": ate,
        "nome": atributo,
    }


ORIGINAL = [
    _versao("a", "2026-01-01", "2026-02-01", "antigo"),
    _versao("b", "2026-02-01", None, "atual"),
]


def test_o_oraculo_scd_distingue_atributo_de_versao_fechada():
    """O oráculo da revisão 4 devolvia o mesmo hash para os três casos."""
    alterado = [_versao("a", "2026-01-01", "2026-02-01", "OUTRO"), ORIGINAL[1]]

    assert oraculos.digest(ORIGINAL) != oraculos.digest(alterado)
    assert len(ORIGINAL) == len(alterado), "a contagem não muda — é esse o ponto"


def test_o_oraculo_scd_distingue_validade_de_versao_vigente():
    """Com 1.574 de 1.575 linhas vigentes, o hash antigo se resumia à única fechada."""
    alterado = [ORIGINAL[0], _versao("b", "2026-03-01", None, "atual")]

    assert oraculos.digest(ORIGINAL) != oraculos.digest(alterado)


def test_o_nulo_entra_como_marcador_e_nao_some():
    """`x ‖ NULL` é nulo em SQL, e o `string_agg` o descartava."""
    vigente = _versao("b", "2026-02-01", None, "atual")
    fechada = _versao("b", "2026-02-01", "", "atual")

    assert oraculos.digest([vigente]) != oraculos.digest([fechada]), (
        "`NULL` e string vazia são valores diferentes"
    )
    assert '"dbt_valid_to":null' in oraculos.linha_canonica(vigente)


# ── A codificação tipada (RVE-07) ───────────────────────────────────────────
#
# Os seis pares que a revisão da entrega mediu na serialização anterior: dois
# conteúdos diferentes com o mesmo hash (colisão), quatro conteúdos iguais com
# hashes diferentes (falso diferente). Cada um é uma regra da codificação.

import datetime as _dt  # noqa: E402
import decimal as _decimal  # noqa: E402


@pytest.mark.parametrize(
    "nome, a, b",
    [
        ("nulo × o texto \\N", {"v": None}, {"v": "\\N"}),
        ("separador dentro do texto", {"a": "x\x1fb=y", "b": "z"}, {"a": "x", "b": "y\x1fb=z"}),
        ('o texto "1" × o inteiro 1', {"v": "1"}, {"v": 1}),
        ("o inteiro 1 × numeric 1", {"v": 1}, {"v": _decimal.Decimal("1")}),
        ("verdadeiro × o inteiro 1", {"v": True}, {"v": 1}),
    ],
)
def test_conteudos_diferentes_tem_hashes_diferentes(nome, a, b):
    assert oraculos.digest([a]) != oraculos.digest([b]), nome


@pytest.mark.parametrize(
    "nome, a, b",
    [
        (
            "o mesmo instante em dois fusos",
            {"v": _dt.datetime(2026, 9, 21, 12, tzinfo=_dt.timezone.utc)},
            {"v": _dt.datetime(2026, 9, 21, 9, tzinfo=_dt.timezone(_dt.timedelta(hours=-3)))},
        ),
        ("numeric com escalas diferentes", {"v": _decimal.Decimal("1.00")}, {"v": _decimal.Decimal("1.0")}),
        ("numeric 100 × 1E+2", {"v": _decimal.Decimal("100")}, {"v": _decimal.Decimal("1E+2")}),
        ("bytes × memoryview", {"v": b"abc"}, {"v": memoryview(b"abc")}),
        ("duas memoryviews do mesmo conteúdo", {"v": memoryview(b"abc")}, {"v": memoryview(b"abc")}),
    ],
)
def test_representacoes_equivalentes_tem_o_mesmo_hash(nome, a, b):
    assert oraculos.digest([a]) == oraculos.digest([b]), nome


def test_o_formato_do_oraculo_e_versionado():
    """Um manifesto escrito com outra codificação não é comparável — e diz isso."""
    assert oraculos.FORMATO == 2
    assert oraculos.linha_canonica({"v": None}) == '{"v":null}'


def test_duplicar_uma_linha_muda_o_hash_e_a_contagem():
    """RV12-4-05: a redação anterior dizia que a contagem não mudava, e era falsa."""
    duplicado = [*ORIGINAL, ORIGINAL[1]]

    assert oraculos.digest(ORIGINAL) != oraculos.digest(duplicado)
    assert len(duplicado) == len(ORIGINAL) + 1


def test_a_ordem_em_que_o_banco_devolveu_nao_muda_o_hash():
    assert oraculos.digest(ORIGINAL) == oraculos.digest(list(reversed(ORIGINAL)))


def test_a_ordem_das_chaves_de_um_jsonb_nao_muda_o_hash():
    """`to_jsonb` não promete ordem de chaves entre execuções."""
    a = [{"id": 1, "payload": {"x": 1, "y": 2}}]
    b = [{"id": 1, "payload": {"y": 2, "x": 1}}]

    assert oraculos.digest(a) == oraculos.digest(b)


# ── A continência da quarentena ─────────────────────────────────────────────


def _rejeicao(captura: int, versao: int, impressao: str, motivo: str, payload: str) -> dict:
    return {
        "source_system": "legacy",
        "snapshot_id": captura,
        "catalog_version": versao,
        "treatment_fingerprint": impressao,
        "rejection_reason": motivo,
        "payload": payload,
    }


CHAVE = ("source_system", "snapshot_id", "catalog_version", "treatment_fingerprint")

QUARENTENA = [
    _rejeicao(43, 9, "607e6288", "NULL_REQUIRED", "linha-1"),
    _rejeicao(43, 9, "607e6288", "BAD_DATE", "linha-2"),
    _rejeicao(39, 9, "607e6288", "NULL_REQUIRED", "linha-3"),
]


def test_troca_de_payload_mantem_a_contagem_e_muda_o_digest():
    """A insuficiência do RV12-4-02, medida na sonda: contagens iguais, uma linha perdida."""
    trocado = [
        _rejeicao(43, 9, "607e6288", "NULL_REQUIRED", "OUTRA"),
        *QUARENTENA[1:],
    ]

    antes = oraculos.por_chave(QUARENTENA, CHAVE)
    depois = oraculos.por_chave(trocado, CHAVE)
    fatia = next(c for c in antes if "43" in c)

    assert antes[fatia]["linhas"] == depois[fatia]["linhas"], "a contagem não muda"
    assert oraculos.contido(antes, depois) != []
    assert any("conteúdo mudou" in p for p in oraculos.contido(antes, depois))


def test_troca_de_motivo_tambem_e_acusada():
    trocado = [
        _rejeicao(43, 9, "607e6288", "OUTRO_MOTIVO", "linha-1"),
        *QUARENTENA[1:],
    ]

    problemas = oraculos.contido(
        oraculos.por_chave(QUARENTENA, CHAVE), oraculos.por_chave(trocado, CHAVE)
    )
    assert any("conteúdo mudou" in p for p in problemas), problemas


def test_perda_compensada_por_duplicacao_e_acusada():
    """Uma linha some e outra do mesmo grupo entra no lugar: o total não muda."""
    compensado = [QUARENTENA[0], QUARENTENA[0], QUARENTENA[2]]

    antes = oraculos.por_chave(QUARENTENA, CHAVE)
    depois = oraculos.por_chave(compensado, CHAVE)
    fatia = next(c for c in antes if "43" in c)

    assert antes[fatia]["linhas"] == depois[fatia]["linhas"] == 2
    assert any("conteúdo mudou" in p for p in oraculos.contido(antes, depois))


def test_fatia_que_some_e_acusada():
    problemas = oraculos.contido(
        oraculos.por_chave(QUARENTENA, CHAVE),
        oraculos.por_chave(QUARENTENA[:2], CHAVE),
    )
    assert any("sumiu" in p for p in problemas), problemas


def test_a_captura_nova_e_acrescimo_nomeado_e_nao_quebra_a_continencia():
    """O total **não** é igual depois da restauração, e não deve ser.

    A sincronização do passo 8 traz uma captura nova, que vira a selecionada; a
    fatia da 43 é **retida**, não recalculada, e a da nova entra ao lado. O
    oráculo é continência exata mais acréscimo declarado.
    """
    depois_do_rebuild = [*QUARENTENA, _rejeicao(44, 9, "607e6288", "NULL_REQUIRED", "nova")]

    antes = oraculos.por_chave(QUARENTENA, CHAVE)
    depois = oraculos.por_chave(depois_do_rebuild, CHAVE)

    assert oraculos.contido(antes, depois) == []
    novas = oraculos.acrescimo(antes, depois)
    assert len(novas) == 1
    assert "44" in next(iter(novas))


# ── O pacote: destino, checksums e árvore suja ──────────────────────────────

import json  # noqa: E402
import os  # noqa: E402
import pathlib  # noqa: E402
import subprocess  # noqa: E402

from mvp_ed1.recovery import pacote  # noqa: E402

RAIZ = pathlib.Path(__file__).resolve().parent.parent


def test_recovery_dir_relativo_e_recusado():
    """RV12-09: num alvo composto o relativo resolve contra quem chama.

    Em B5 quem chama é o clone, e o pacote do *checkout* antigo seria procurado
    dentro do clone novo — onde ele não está.
    """
    with pytest.raises(pacote.PacoteRecusado) as erro:
        pacote.Destino(pathlib.Path("data/recovery"))

    assert "absoluto" in str(erro.value)
    absoluto = pacote.Destino(pathlib.Path("/tmp/pacote"))
    assert absoluto.candidato.name == "candidato" and absoluto.aprovado.name == "aprovado"


def test_checksum_alterado_e_acusado(tmp_path):
    pasta = tmp_path / "candidato"
    pasta.mkdir()
    (pasta / "source_db.dump").write_bytes(b"conteudo-do-dump")
    pacote.escrever_checksums(pasta)

    assert pacote.conferir_checksums(pasta) == []

    (pasta / "source_db.dump").write_bytes(b"conteudo-trocado")
    problemas = pacote.conferir_checksums(pasta)
    assert any("checksum não confere" in p for p in problemas), problemas


def test_arquivo_que_aparece_depois_tambem_e_acusado(tmp_path):
    """Conferir só um sentido deixaria passar um dump trocado por outro ao lado."""
    pasta = tmp_path / "candidato"
    pasta.mkdir()
    (pasta / "source_db.dump").write_bytes(b"x")
    pacote.escrever_checksums(pasta)

    (pasta / "source_db.dump.novo").write_bytes(b"y")
    problemas = pacote.conferir_checksums(pasta)
    assert any("não foi declarado" in p for p in problemas), problemas


def test_arquivo_declarado_que_some_e_acusado(tmp_path):
    pasta = tmp_path / "candidato"
    pasta.mkdir()
    (pasta / "source_db.dump").write_bytes(b"x")
    pacote.escrever_checksums(pasta)
    (pasta / "source_db.dump").unlink()

    assert any("ausente do disco" in p for p in pacote.conferir_checksums(pasta))


def test_manifesto_gravado_e_lido_de_volta(tmp_path):
    pasta = tmp_path / "candidato"
    pasta.mkdir()
    dados = {
        "corte": "2026-09-20T20:00:00+00:00",
        "commit": "0" * 40,
        "oraculo_quarentena": oraculos.por_chave(QUARENTENA, CHAVE),
        "oraculo_scd": {"scd_customer": {"linhas": 2, "versoes": 2, "digest": oraculos.digest(ORIGINAL)}},
    }
    pacote.Manifesto(dados).gravar(pasta)

    lido = pacote.Manifesto.ler(pasta)
    assert lido.dados == dados
    assert json.loads((pasta / pacote.NOME_DO_MANIFESTO).read_text(encoding="utf-8")) == dados


def test_pasta_sem_manifesto_nao_e_pacote(tmp_path):
    with pytest.raises(pacote.PacoteRecusado) as erro:
        pacote.Manifesto.ler(tmp_path)
    assert "não é um pacote" in str(erro.value)


def test_promover_troca_o_aprovado_e_apaga_o_anterior(tmp_path):
    destino = pacote.Destino(tmp_path)
    destino.aprovado.mkdir(parents=True)
    (destino.aprovado / "velho.dump").write_bytes(b"antigo")
    destino.candidato.mkdir(parents=True)
    (destino.candidato / "novo.dump").write_bytes(b"recente")

    pacote.promover(destino)

    assert (destino.aprovado / "novo.dump").exists()
    assert not (destino.aprovado / "velho.dump").exists()
    assert not destino.candidato.exists()


def test_promover_sem_candidato_recusa(tmp_path):
    with pytest.raises(pacote.PacoteRecusado):
        pacote.promover(pacote.Destino(tmp_path))


# ── A sequência, simulada com o Makefile real ───────────────────────────────
#
# A técnica é a da §14.3 do plano: o Makefile **de verdade**, com registradores
# no lugar dos executáveis. O que se prova é a composição — quem chama quem, em
# que ordem, e com que variáveis —, e não o efeito de cada comando.

def _receita(alvo: str) -> str:
    """As linhas de receita de um alvo, lidas do `Makefile`.

    **Por que estático, e não `make -n`.** O `make` executa de verdade toda
    linha de receita que contenha `$(MAKE)`, mesmo sob `-n`, para poder traçar
    a recursão. A sequência de restauração é feita de submakes, e expandi-la
    com `-n` disparava `airbyte-up` — que tentava instalar o cluster. Medido
    aqui: a primeira versão destes testes chamou `abctl local install`, e só
    não reinstalou nada porque a armadilha do `PG_VERSION` (Execução Local §6)
    abortou antes. A linha foi corrigida em 23/09/2026, e
    `tests/test_makefile.py` guarda a regra; a leitura aqui continua estática,
    porque o que se confere é a composição, não o efeito.

    O que se confere é a **composição declarada**: quem chama quem, em que
    ordem e com que variáveis. O efeito de cada comando é de B5.
    """
    texto = (RAIZ / "Makefile").read_text(encoding="utf-8")
    marca = f"\n{alvo}:"
    inicio = texto.index(marca) + 1
    resto = texto[inicio:]
    linhas = []
    for numero, linha in enumerate(resto.splitlines()):
        if numero and not linha.startswith("\t"):
            break
        # Comentário de receita (`\t@#`) é prosa, não comando: o que se confere
        # aqui é o que o alvo **faz**, e a prosa cita alvos que ele não chama.
        if linha.startswith("\t@#"):
            continue
        linhas.append(linha)
    return "\n".join(linhas)


def test_restore_sem_autorizacao_nao_toca_em_banco(tmp_path):
    """`RESTAURAR=1`, e não `FORCE`: a autorização é própria e é consumida na entrada.

    Este roda o alvo **de verdade** — é seguro, porque ele para na guarda — e o
    oráculo é que nenhum comando de banco foi chamado.
    """
    binario = tmp_path / "bin"
    binario.mkdir()
    log = tmp_path / "log"
    log.write_text("", encoding="utf-8")
    for nome in ("pg_restore", "pg_dump", "docker"):
        alvo = binario / nome
        alvo.write_text(
            '#!/usr/bin/env bash\necho "$(basename "$0") $*" >> "$SIM_LOG"\nexit 0\n',
            encoding="utf-8",
        )
        alvo.chmod(0o755)

    saida = subprocess.run(
        ["make", "--no-print-directory", "recovery-restore"],
        cwd=RAIZ, capture_output=True, text=True,
        env=os.environ | {"PATH": f"{binario}:{os.environ['PATH']}", "SIM_LOG": str(log)},
        timeout=120,
    )

    assert saida.returncode != 0, saida.stdout
    assert "RESTAURAR=1" in saida.stdout
    assert log.read_text(encoding="utf-8") == "", "nada foi executado antes da autorização"


def test_a_sequencia_nunca_chama_dbt_drop_snapshots():
    """RV12-2-01: derrubar os snapshots depois de um restore perde o que voltou."""
    receita = _receita("recovery-restore")

    assert "dbt-rebuild" in receita
    assert "dbt-drop-snapshots" not in receita
    assert "dbt-build" not in receita


def test_o_rebase_vem_depois_do_restore_e_antes_da_carga_nova():
    """D52: um Airbyte novo escreve na geração 1, onde estão as linhas retidas."""
    receita = _receita("recovery-restore")

    assert receita.index("restore-dumps") < receita.index("recovery-rebase") < receita.index("sync-legacy")


def test_a_quarentena_volta_antes_do_rebuild():
    """D51: `rejected_legacy_records` lê a própria tabela anterior — e ela precisa existir."""
    receita = _receita("recovery-restore")

    assert receita.index("restore-dumps") < receita.index("dbt-rebuild")


def test_a_conferencia_contra_o_manifesto_vem_logo_depois_do_rebase():
    """O passo 5 existe para pegar o restore que "funcionou" e trouxe outra coisa."""
    receita = _receita("recovery-restore")

    assert receita.index("recovery-rebase") < receita.index("CONTRA_O_BANCO=1")
    assert receita.index("CONTRA_O_BANCO=1") < receita.index("airbyte-up")


def test_force_nao_atravessa_a_subida_do_ambiente():
    """RV12-06: herdar FORCE faria a subida ignorar o R11 com a máquina carregada."""
    receita = _receita("recovery-restore")

    assert "airbyte-up FORCE=\n" in receita + "\n", "a subida recebe FORCE vazio, explicitamente"
    assert "stream-down FORCE=1" in receita, "o descarte recebe FORCE=1, um a um"
    assert "stream-reset-sink FORCE=1" in receita
    assert "FORCE=1" not in receita.split("8/9")[-1], "nada de FORCE=1 na parte que sobe"


def test_recovery_dir_e_impresso_em_toda_execucao():
    """RV12-09: em B5 o alvo roda do clone, e precisa dizer de onde está lendo."""
    for alvo in ("recovery-pack", "recovery-verify", "recovery-restore", "recovery-promote"):
        assert "RECOVERY_DIR" in _receita(alvo), alvo


def test_o_dbt_rebuild_nao_e_o_dbt_build_reset():
    """A diferença entre os dois alvos é uma linha e é o bloco inteiro."""
    rebuild = _receita("dbt-rebuild")
    build = _receita("dbt-build")

    assert "--full-refresh" in rebuild
    assert "dbt-drop-snapshots" not in rebuild
    assert "dbt-drop-snapshots" in build, "o alvo antigo continua derrubando, e deve"


def test_o_pack_recusa_arvore_suja():
    """O manifesto grava o commit como a versão do código que produziu o estado."""
    assert pacote.arvore_suja(RAIZ) is not None  # a função existe e responde
    receita = _receita("recovery-pack")
    assert "preflight" in receita, "janela parada é pré-condição do corte"


# ── A revisão da entrega (RVE-03/04/05/06/10/15): o que cada passo confere ──
#
# Motores, leituras e o `pg_restore` são dublês; as funções de decisão da CLI
# são reais. O que se prova é que os estados que a revisão viu passar agora
# são recusados — e que o estado certo continua passando.

import argparse  # noqa: E402
import contextlib  # noqa: E402
import copy  # noqa: E402
import io  # noqa: E402
from unittest.mock import Mock, patch  # noqa: E402

from mvp_ed1.recovery import cli, leitura  # noqa: E402


def test_a_assinatura_da_particao_e_invariante_ao_rebase_e_ve_a_fusao():
    """RVE-04: o oráculo do passo 4b que o manifesto guarda."""
    linhas = [("a", 1), ("b", 1), ("c", 5), ("d", 28), ("e", 28)]
    mapa = rebase.plano(g for _, g in linhas)
    rebaseadas = [(k, mapa[g]) for k, g in linhas]
    fundidas = [("a", -1), ("b", -1), ("c", -1), ("d", -2), ("e", -2)]
    trocadas = [("a", -3), ("b", -3), ("c", -1), ("d", -2), ("e", -2)]

    antes = rebase.assinatura(linhas)
    assert antes["classes"] == 3 and antes["linhas"] == 5 and antes["nulas"] == 0
    assert rebase.assinatura(rebaseadas) == antes
    assert rebase.particao_preservada_por_assinatura(antes, rebase.assinatura(rebaseadas)) == []
    assert any("classes" in p for p in rebase.particao_preservada_por_assinatura(antes, rebase.assinatura(fundidas)))
    assert any("agrupamento" in p for p in rebase.particao_preservada_por_assinatura(antes, rebase.assinatura(trocadas)))


def test_o_manifesto_incompleto_ou_de_outro_formato_e_dito(tmp_path):
    """RVE-15 e RVE-07: campo obrigatório ausente e formato diferente são problemas nomeados."""
    antigo = pacote.Manifesto({"corte": "x", "commit": "y", "contagens": {}})
    problemas = antigo.problemas_de_forma(oraculos.FORMATO)
    assert any("`oraculo_particao`" in p for p in problemas)
    assert any("`geracao`" in p for p in problemas)

    outro_formato = pacote.Manifesto({c: {} for c in pacote.CAMPOS_OBRIGATORIOS} | {"oraculo_formato": 1})
    assert any("não são comparáveis" in p for p in outro_formato.problemas_de_forma(oraculos.FORMATO))
    assert pacote.Manifesto({c: {} for c in pacote.CAMPOS_OBRIGATORIOS} | {"oraculo_formato": oraculos.FORMATO}).problemas_de_forma(oraculos.FORMATO) == []


def test_refazer_o_pacote_preserva_o_candidato_anterior_ate_o_novo_existir(tmp_path):
    """RVE-10: `rmtree(candidato)` antes do primeiro dump perdia a única volta."""
    destino = pacote.Destino(tmp_path)
    destino.candidato.mkdir(parents=True)
    (destino.candidato / "volta.dump").write_bytes(b"pacote anterior")
    args = argparse.Namespace(dir=str(tmp_path), permitir_arvore_suja=False)

    def falha(pasta):
        (pasta / "source_db.dump").write_bytes(b"parcial")
        raise pacote.PacoteRecusado("falha simulada no primeiro dump")

    with patch.object(pacote, "arvore_suja", return_value=""), patch.object(cli, "_montar", side_effect=falha), \
            contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        with pytest.raises(pacote.PacoteRecusado):
            cli.comando_pack(args)

    assert (destino.candidato / "volta.dump").read_bytes() == b"pacote anterior"
    assert not destino.em_montagem.exists(), "a montagem abandonada não fica para trás"

    def sucesso(pasta):
        (pasta / "novo.dump").write_bytes(b"pacote novo")

    with patch.object(pacote, "arvore_suja", return_value=""), patch.object(cli, "_montar", side_effect=sucesso), \
            contextlib.redirect_stdout(io.StringIO()):
        assert cli.comando_pack(args) == 0

    assert (destino.candidato / "novo.dump").exists()
    assert not (destino.candidato / "volta.dump").exists()
    assert not destino.descartado.exists() and not destino.em_montagem.exists()


def test_pg_restore_com_erro_acumulado_e_recusado_numa_transacao_so(tmp_path):
    """RVE-03: o código 1 do `pg_restore` é `n_errors > 0`, não aviso benigno."""
    dump = tmp_path / "falso.dump"
    dump.write_bytes(b"nenhum dump real")
    erro = b"pg_restore: error: COPY failed: duplicate key\npg_restore: warning: errors ignored on restore: 1\n"
    chamadas: list[list[str]] = []

    def run(comando, **kw):
        chamadas.append(comando)
        return subprocess.CompletedProcess(comando, 1, b"", erro)

    with patch.object(cli, "_conteineres", return_value="docker-falso"), patch.object(cli.subprocess, "run", side_effect=run):
        with pytest.raises(pacote.PacoteRecusado) as recusa:
            cli._pg_restore("source_db", "usuario", "banco", dump)

    assert "COPY failed" in str(recusa.value), "o diagnóstico inteiro, não só a última linha"
    assert "--single-transaction" in chamadas[0] and "--clean" in chamadas[0] and "--if-exists" in chamadas[0]


def test_restore_dumps_garante_os_papeis_antes_de_qualquer_dump(tmp_path):
    """RVB5-01: o dump da memória traz `GRANT … TO ingestor`, e num armazém recém-criado por `make up`
    os papéis ainda não existem — o `pg_restore` recusava e desfazia o dump inteiro (medido num destino
    novo em 25/09/2026). Os papéis vêm antes do primeiro dump: sem eles, nada é tocado."""
    ordem: list[str] = []
    with patch.object(cli, "_pasta_do_pacote", return_value=tmp_path), \
            patch.object(cli, "_motor", return_value="motor-do-armazem"), \
            patch.object(cli.governance, "garantir_papeis", side_effect=lambda motor: ordem.append(f"papéis em {motor}")), \
            patch.object(cli, "_pg_restore", side_effect=lambda servico, *a: ordem.append(servico)), \
            contextlib.redirect_stdout(io.StringIO()):
        assert cli.comando_restore_dumps(argparse.Namespace(dir=None)) == 0

    assert ordem == ["papéis em motor-do-armazem", "source_db", "legacy_db", "warehouse_db"], ordem


MANIFESTO = {
    "corte": "2026-09-21T12:00:00+00:00",
    "commit": "0" * 40,
    "oraculo_formato": oraculos.FORMATO,
    "alembic": {"source_db": "head-source", "legacy_db": "head-legacy"},
    "geracao": {"source_db": None, "legacy_db": None},
    "governance_versions": ["v1"],
    "max_event_sequence": 100,
    "contagens": {
        "source_db": {"oltp.customers": 10, "oltp.inventory_movements": 100},
        "legacy_db": {"legacy.customers": 10},
        "warehouse_db": {"raw_legacy.customers": 20},
    },
    "tamanhos": {"source_db": {}, "legacy_db": {}, "warehouse_db": {}},
    "oraculo_scd": {"scd_customer": {"linhas": 2, "versoes": 2, "digest": "igual"}},
    "oraculo_quarentena": {'["legacy",43,9,"hash"]': {"linhas": 1, "digest": "igual"}},
    "oraculo_capturas": {
        "maior_snapshot": 43,
        "certificadas": [9, 43],
        "geracoes_por_tabela": {"customers": {"minima": 1, "maxima": 2, "classes": 2, "nulas": 0}},
    },
    "oraculo_particao": {"customers": {"linhas": 20, "classes": 2, "nulas": 0, "digest": "particao"}},
    "oraculo_exclusoes": {"linhas": 4, "digest": "exclusoes"},
    "artefatos_copiados": [],
    "artefatos_ausentes": [],
    "artefatos_links": {},
    "limite": "…",
}

#: O estado que a revisão viu passar no passo 5 com `problemas=[]`: contagens
#: divergentes, Alembic errado, versões erradas, nenhuma captura certificada.
ESTADO_INVALIDO = {
    "contagens": lambda engine, schemas: {f"{schemas[0]}.customers": 0},
    "alembic_current": lambda raiz, secao=None: "versao-errada",
    "versoes_do_armazem": lambda engine: ["versao-errada"],
    "maior_event_sequence": lambda engine: 100,
    "oraculo_scd": lambda engine: copy.deepcopy(MANIFESTO["oraculo_scd"]),
    "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
    "oraculo_das_capturas": lambda engine: {"certificadas": [], "maior_snapshot": None, "geracoes_por_tabela": {}},
    "oraculo_da_particao": lambda engine, apenas_retidas=False: {},
    "oraculo_das_exclusoes": lambda engine: None,
}

#: O mesmo estado do pacote, logo depois do `pack`.
ESTADO_DO_PACOTE = {
    "contagens": lambda engine, schemas: copy.deepcopy(
        {"oltp": MANIFESTO["contagens"]["source_db"], "legacy": MANIFESTO["contagens"]["legacy_db"]}.get(
            schemas[0], MANIFESTO["contagens"]["warehouse_db"]
        )
    ),
    "alembic_current": lambda raiz, secao=None: "head-legacy" if secao else "head-source",
    "versoes_do_armazem": lambda engine: ["v1"],
    "maior_event_sequence": lambda engine: 100,
    "oraculo_scd": lambda engine: copy.deepcopy(MANIFESTO["oraculo_scd"]),
    "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
    "oraculo_das_capturas": lambda engine: copy.deepcopy(MANIFESTO["oraculo_capturas"]),
    "oraculo_da_particao": lambda engine, apenas_retidas=False: copy.deepcopy(MANIFESTO["oraculo_particao"]),
    "oraculo_das_exclusoes": lambda engine: copy.deepcopy(MANIFESTO["oraculo_exclusoes"]),
}


@contextlib.contextmanager
def _leituras(estado: dict):
    with contextlib.ExitStack() as pilha:
        pilha.enter_context(patch.object(cli, "_motor", return_value=Mock()))
        for nome, funcao in estado.items():
            pilha.enter_context(patch.object(leitura, nome, side_effect=funcao))
        pilha.enter_context(contextlib.redirect_stdout(io.StringIO()))
        yield


def test_o_passo_5_recusa_o_estado_que_a_revisao_viu_passar():
    """RVE-04: contagens, Alembic, versões e capturas divergentes passavam com `problemas=[]`."""
    with _leituras(ESTADO_INVALIDO):
        problemas = cli._conferir_contra_o_banco(pacote.Manifesto(copy.deepcopy(MANIFESTO)))

    assert any("contagens em source_db" in p for p in problemas), problemas
    assert any("alembic" in p for p in problemas)
    assert any("governance._versions" in p for p in problemas)
    assert any("capturas certificadas" in p for p in problemas)
    assert any("partição" in p for p in problemas)
    assert not any("exclusões" in p for p in problemas), (
        "a memória de exclusões é `trusted`, que renasce no rebuild do passo 8 — é oráculo do passo 9"
    )


def test_o_passo_5_recusa_o_armazem_sem_a_memoria_em_vez_de_estourar():
    """Achado ao medir o RVB5-01: num armazém sem a memória — recém-criado, ou com a restauração
    desfeita — a leitura da quarentena estourava em *traceback* (`UndefinedTable`). Continua recusando,
    mas com o diagnóstico numa linha, como os outros problemas."""
    import sqlalchemy.exc

    def sem_quarentena(engine):
        raise sqlalchemy.exc.ProgrammingError(
            "select * from quarantine.rejected_legacy_records", {},
            Exception('relation "quarantine.rejected_legacy_records" does not exist\nLINE 1: ...'),
        )

    with _leituras(ESTADO_DO_PACOTE | {"oraculo_da_quarentena": sem_quarentena}):
        problemas = cli._conferir_contra_o_banco(pacote.Manifesto(copy.deepcopy(MANIFESTO)))

    assert problemas == [
        'a leitura dos bancos falhou — relation "quarantine.rejected_legacy_records" does not exist: '
        "eles não têm o estado que o manifesto descreve"
    ], problemas


def test_o_passo_5_aceita_o_mesmo_estado_do_pacote_antes_e_depois_do_rebase():
    with _leituras(ESTADO_DO_PACOTE):
        assert cli._conferir_contra_o_banco(pacote.Manifesto(copy.deepcopy(MANIFESTO))) == []

    rebaseado = dict(ESTADO_DO_PACOTE)
    rebaseado["oraculo_das_capturas"] = lambda engine: {
        "certificadas": [9, 43], "maior_snapshot": 43,
        "geracoes_por_tabela": {"customers": {"minima": -2, "maxima": -1, "classes": 2, "nulas": 0}},
    }
    with _leituras(rebaseado):
        assert cli._conferir_contra_o_banco(pacote.Manifesto(copy.deepcopy(MANIFESTO))) == []

    fundido = dict(rebaseado)
    fundido["oraculo_da_particao"] = lambda engine, apenas_retidas=False: {
        "customers": {"linhas": 20, "classes": 1, "nulas": 0, "digest": "outra"}
    }
    with _leituras(fundido):
        problemas = cli._conferir_contra_o_banco(pacote.Manifesto(copy.deepcopy(MANIFESTO)))
    assert any("partição" in p for p in problemas), problemas


def _passo_9(estado: dict, job: int = 44) -> tuple[int, str]:
    erro = io.StringIO()
    with _leituras(estado), patch.object(cli, "_pasta_do_pacote", return_value=pathlib.Path("/nao-usado")), \
            patch.object(pacote.Manifesto, "ler", return_value=pacote.Manifesto(copy.deepcopy(MANIFESTO))), \
            contextlib.redirect_stderr(erro):
        codigo = cli.comando_conferir_restauracao(argparse.Namespace(dir=None, job=job))
    return codigo, erro.getvalue()


#: O estado que a revisão viu o passo 9 aceitar com exit 0: só o certificado
#: 44, sem os retidos, gerações só positivas, quarentena sem fatia nova.
ESTADO_RESTAURADO_INVALIDO = dict(ESTADO_INVALIDO) | {
    "versoes_do_armazem": lambda engine: ["v1"],
    "oraculo_das_capturas": lambda engine: {
        "certificadas": [44], "maior_snapshot": 44,
        "geracoes_por_tabela": {"customers": {"minima": 1, "maxima": 1, "classes": 1, "nulas": 0}},
    },
    "capturas_certificadas_desde": lambda engine, corte: [44],
    "classificacao_corrente": lambda engine: None,
    "comparar_caminhos": lambda engine, corte: {
        "corte": corte, "so_no_lote": 3, "so_no_fluxo": 0, "payloads_diferentes": 1,
        "saldos_diferentes": 0, "soma_lote": 10, "soma_fluxo": 9, "linhas_lote": 1, "linhas_fluxo": 1,
    },
}

FATIA_44 = '["legacy",44,9,"hash"]'

#: Uma restauração de verdade bem-sucedida: tudo do manifesto de volta, a
#: captura 44 certificada acima da 43, a fatia dela na quarentena igual ao que
#: a classificação dela rejeitou, o livro da origem inteiro nos dois caminhos.
ESTADO_RESTAURADO = dict(ESTADO_DO_PACOTE) | {
    "oraculo_das_capturas": lambda engine: {
        "certificadas": [9, 43, 44], "maior_snapshot": 44,
        "geracoes_por_tabela": {"customers": {"minima": -2, "maxima": 1, "classes": 3, "nulas": 0}},
    },
    "capturas_certificadas_desde": lambda engine, corte: [44],
    "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"])
    | {FATIA_44: {"linhas": 1, "digest": "nova"}},
    "classificacao_corrente": lambda engine: {
        "tratadas": [FATIA_44], "rejeitadas": {FATIA_44: {"linhas": 1, "digest": "nova"}},
    },
    "comparar_caminhos": lambda engine, corte: {
        "corte": corte, "so_no_lote": 0, "so_no_fluxo": 0, "payloads_diferentes": 0,
        "saldos_diferentes": 0, "soma_lote": 10, "soma_fluxo": 10, "linhas_lote": 100, "linhas_fluxo": 100,
    },
}


def test_o_passo_9_recusa_a_restauracao_que_a_revisao_viu_ser_anunciada():
    """RVE-05: certificados retidos ausentes, livro diferente, contagens erradas — e saía 0."""
    codigo, erro = _passo_9(ESTADO_RESTAURADO_INVALIDO)

    assert codigo == 1
    assert "capturas certificadas do manifesto que sumiram: [9, 43]" in erro
    assert "so_no_lote = 3" in erro and "payloads_diferentes = 1" in erro and "soma dos deltas" in erro
    assert "contagens em source_db" in erro
    assert "exclusões" in erro


def test_o_passo_9_aceita_a_restauracao_inteira_e_relaciona_a_captura_ao_job_real():
    codigo, erro = _passo_9(ESTADO_RESTAURADO, job=44)
    assert codigo == 0, erro

    codigo, erro = _passo_9(ESTADO_RESTAURADO, job=45)
    assert codigo == 1 and "o job disparado foi 45" in erro


def test_o_passo_9_exige_o_job_do_passo_8():
    """RVE2-01: sem `--job`, "a captura nova" seria a que o banco disser."""
    with pytest.raises(SystemExit) as saida, contextlib.redirect_stderr(io.StringIO()):
        cli.main(["conferir-restauracao"])
    assert saida.value.code == 2


def test_o_passo_9_recusa_a_falta_da_auditoria_da_captura_nova():
    """RVE2-01, a sonda do revisor: a fixture válida sem a fatia da 44 saía 0.

    A captura 44 continua certificada, com job e partições certos; só a
    auditoria dela não está na quarentena. Conferir que o acréscimo "não tinha
    fatia estranha" aceitava isso — nada a mais é diferente de nada faltando.
    """
    sem_a_fatia = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
    }
    codigo, erro = _passo_9(sem_a_fatia, job=44)
    assert codigo == 1 and "auditoria da captura nova: fatia sumiu" in erro, erro


def test_o_passo_9_compara_contagem_e_conteudo_da_auditoria_nova():
    outra = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"])
        | {FATIA_44: {"linhas": 2, "digest": "outra"}},
    }
    codigo, erro = _passo_9(outra, job=44)
    assert codigo == 1 and "contagem mudou" in erro and "conteúdo mudou" in erro, erro

    a_mais = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"])
        | {FATIA_44: {"linhas": 1, "digest": "nova"}, '["legacy",44,8,"velha"]': {"linhas": 1, "digest": "x"}},
    }
    codigo, erro = _passo_9(a_mais, job=44)
    assert codigo == 1 and "que a classificação dela não rejeitou" in erro, erro


def test_captura_nova_sem_rejeicao_tem_acrescimo_vazio_e_passa():
    """Rejeição nenhuma é legítima: o esperado vem da classificação, não de um total positivo."""
    limpa = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
        "classificacao_corrente": lambda engine: {"tratadas": [FATIA_44], "rejeitadas": {}},
    }
    codigo, erro = _passo_9(limpa, job=44)
    assert codigo == 0, erro


def test_a_classificacao_precisa_ser_a_da_captura_nova():
    """Sem o build da captura nova, a classificação ainda é a da 43 — e o esperado seria o dela."""
    da_retida = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
        "classificacao_corrente": lambda engine: {
            "tratadas": ['["legacy",43,9,"hash"]'],
            "rejeitadas": copy.deepcopy(MANIFESTO["oraculo_quarentena"]),
        },
    }
    codigo, erro = _passo_9(da_retida, job=44)
    assert codigo == 1 and "a classificação corrente trata a(s) captura(s) [43]" in erro, erro

    sem_classificacao = dict(ESTADO_RESTAURADO) | {"classificacao_corrente": lambda engine: None}
    codigo, erro = _passo_9(sem_classificacao, job=44)
    assert codigo == 1 and "legacy_classifications não existe" in erro, erro


def test_o_passo_9_recusa_o_livro_vazio_nos_dois_caminhos():
    """Dois caminhos vazios são iguais entre si — e o livro não voltou.

    Achado próprio na aplicação da segunda rodada: a terceira sonda do revisor
    (`livros_ambos_vazios`) também saía 0, sem ter virado achado.
    """
    vazio = dict(ESTADO_RESTAURADO) | {
        "comparar_caminhos": lambda engine, corte: {
            "corte": corte, "so_no_lote": 0, "so_no_fluxo": 0, "payloads_diferentes": 0,
            "saldos_diferentes": 0, "soma_lote": 0, "soma_fluxo": 0, "linhas_lote": 0, "linhas_fluxo": 0,
        },
    }
    codigo, erro = _passo_9(vazio, job=44)
    assert codigo == 1 and "e a origem tem 100" in erro, erro


def test_o_passo_9_recusa_acrescimo_que_nao_e_da_captura_nova():
    estranha = dict(ESTADO_RESTAURADO) | {
        "oraculo_da_quarentena": lambda engine: copy.deepcopy(MANIFESTO["oraculo_quarentena"])
        | {'["legacy",44,9,"hash"]': {"linhas": 1, "digest": "nova"}, '["legacy",41,9,"hash"]': {"linhas": 1, "digest": "x"}},
    }
    codigo, erro = _passo_9(estranha)
    assert codigo == 1 and "não são da captura nova" in erro

    sem_nova = dict(ESTADO_RESTAURADO) | {
        "oraculo_das_capturas": lambda engine: copy.deepcopy(MANIFESTO["oraculo_capturas"]),
        "capturas_certificadas_desde": lambda engine, corte: [],
    }
    codigo, erro = _passo_9(sem_nova)
    assert codigo == 1 and "não produziu identidade nova" in erro


# ── D50: o contador de jobs de um Airbyte novo (RVE-06) ─────────────────────


def _avancar(retido: list[int], ler: dict, depois: dict | None = None) -> tuple[int, list[tuple[str, ...]], str]:
    chamadas: list[tuple[str, ...]] = []

    def jobs(*acao):
        chamadas.append(acao)
        return dict(ler if acao[0] == "ler" else depois)

    saida = io.StringIO()
    with patch.object(cli, "_motor", return_value=Mock()), patch("mvp_ed1.legacy.captura.certificadas", return_value=retido), \
            patch.object(cli, "_airbyte_jobs", side_effect=jobs), contextlib.redirect_stdout(saida):
        try:
            codigo = cli.comando_avancar_jobs(argparse.Namespace(dir=None))
        except pacote.PacoteRecusado as erro:
            return 2, chamadas, str(erro)
    return codigo, chamadas, saida.getvalue()


def test_com_o_mesmo_airbyte_o_passo_le_e_nao_escreve():
    codigo, chamadas, saida = _avancar([28, 43], {"maior_job": 43, "ultimo_valor": 43, "chamado": True, "sequencia": "public.jobs_id_seq"})

    assert codigo == 0
    assert chamadas == [("ler",)]
    assert "nada a avançar" in saida


def test_num_airbyte_novo_a_sequencia_vai_para_o_retido_e_o_proximo_nasce_acima():
    """A instalação nova: três jobs, captura 43 retida — avança para 43, o próximo é 44."""
    codigo, chamadas, saida = _avancar(
        [28, 43],
        {"maior_job": 3, "ultimo_valor": 3, "chamado": True, "sequencia": "public.jobs_id_seq"},
        {"maior_job": 3, "ultimo_valor": 43, "chamado": True, "sequencia": "public.jobs_id_seq"},
    )

    assert codigo == 0, saida
    assert chamadas == [("ler",), ("avancar", "43")]
    assert "próximo job nasce como 44 > 43" in saida


def test_sequencia_nunca_usada_nao_e_confundida_com_o_maior_job():
    """`is_called = false`: o próximo valor é o próprio `last_value`, não `+ 1`."""
    codigo, chamadas, _ = _avancar(
        [43],
        {"maior_job": 0, "ultimo_valor": 43, "chamado": False, "sequencia": "s"},
        {"maior_job": 0, "ultimo_valor": 43, "chamado": True, "sequencia": "s"},
    )
    assert codigo == 0 and chamadas == [("ler",), ("avancar", "43")]


def test_pos_condicao_de_d50_nao_satisfeita_recusa():
    codigo, chamadas, erro = _avancar(
        [43],
        {"maior_job": 3, "ultimo_valor": 3, "chamado": True, "sequencia": "s"},
        {"maior_job": 3, "ultimo_valor": 3, "chamado": True, "sequencia": "s"},
    )
    assert codigo == 2 and "pós-condição" in erro


def test_o_script_do_contador_para_na_premissa_que_falhar(tmp_path):
    """`docker/airbyte_jobs.sh` com um `docker` que registra o SQL e responde o que o teste manda."""
    binario = tmp_path / "bin"
    binario.mkdir()
    log = tmp_path / "sql"
    log.write_text("", encoding="utf-8")
    (binario / "docker").write_text(
        "#!/usr/bin/env bash\n"
        'sql="${@: -1}"; echo "$sql" >> "$SIM_SQL"\n'
        'case "$sql" in\n'
        '  *to_regclass*) printf "%s\\n" "$SIM_TABELA" ;;\n'
        '  *pg_get_serial_sequence*) printf "%s\\n" "$SIM_SEQ" ;;\n'
        '  *setval*) printf "%s\\n" "${sql##*, }" | tr -d ")" ;;\n'
        '  *max\\(id\\)*) printf "%s\\n" "$SIM_LINHA" ;;\n'
        "esac\n",
        encoding="utf-8",
    )
    (binario / "docker").chmod(0o755)
    ambiente = os.environ | {"PATH": f"{binario}:{os.environ['PATH']}", "SIM_SQL": str(log)}
    script = str(RAIZ / "docker" / "airbyte_jobs.sh")

    ok = subprocess.run([script, "ler"], capture_output=True, text=True, timeout=30,
                        env=ambiente | {"SIM_TABELA": "jobs", "SIM_SEQ": "public.jobs_id_seq", "SIM_LINHA": "3|3|t"})
    assert ok.returncode == 0, ok.stdout + ok.stderr
    assert ok.stdout.split() == ["maior_job=3", "ultimo_valor=3", "chamado=t", "sequencia=public.jobs_id_seq"]

    log.write_text("", encoding="utf-8")
    avancado = subprocess.run([script, "avancar", "43"], capture_output=True, text=True, timeout=30,
                              env=ambiente | {"SIM_TABELA": "jobs", "SIM_SEQ": "public.jobs_id_seq", "SIM_LINHA": "3|43|t"})
    assert avancado.returncode == 0, avancado.stdout + avancado.stderr
    assert "select setval('public.jobs_id_seq', 43)" in log.read_text(encoding="utf-8")
    assert "ultimo_valor=43" in avancado.stdout

    sem_tabela = subprocess.run([script, "ler"], capture_output=True, text=True, timeout=30,
                                env=ambiente | {"SIM_TABELA": "", "SIM_SEQ": "", "SIM_LINHA": ""})
    assert sem_tabela.returncode == 3 and "premissa falhou" in sem_tabela.stderr

    sem_sequencia = subprocess.run([script, "avancar", "43"], capture_output=True, text=True, timeout=30,
                                   env=ambiente | {"SIM_TABELA": "jobs", "SIM_SEQ": "", "SIM_LINHA": ""})
    assert sem_sequencia.returncode == 3 and "não tem sequência" in sem_sequencia.stderr
    assert "setval" not in log.read_text(encoding="utf-8").split("43)")[-1]


def test_o_job_do_passo_8_chega_ao_passo_9():
    """RVE2-01: o Makefile não passava `--job`, e o passo 9 aceitava a identidade que o banco dissesse."""
    receita = _receita("recovery-restore")
    apaga = receita.index('rm -f "$(RECOVERY_JOB)"')
    grava = receita.index('sync-legacy JOB_EM="$(RECOVERY_JOB)"')
    le = receita.index('cat "$(RECOVERY_JOB)"')
    assert apaga < grava < le, "o job de uma restauração anterior não pode ser o desta"
    assert 'conferir-restauracao --job "$$job"' in receita
    assert '--job-em "$(JOB_EM)"' in _receita("sync-legacy")


def test_o_passo_d50_vem_depois_do_airbyte_e_antes_de_qualquer_sincronizacao():
    receita = _receita("recovery-restore")

    assert receita.index("airbyte-up") < receita.index("recovery-airbyte-jobs") < receita.index("sync-airbyte")
    assert receita.index("sync-airbyte") < receita.index("sync-legacy")


def test_a_manutencao_nao_ignora_a_pausa_que_falhou():
    """RVE-17: `pausar … || true` seguia com um scheduler capaz de disparar a DAG."""
    receita = _receita("recovery-restore")

    assert "pausar $(DAG) || true" not in receita
    assert "-eq 3" in receita, "Airflow ausente é o único caso em que se segue"


def test_a_geracao_registrada_nunca_e_inferida(tmp_path):
    """RVE-15: sem registro, `None` com o motivo — nunca o padrão do YAML."""
    sem_nada = leitura.geracao_registrada(tmp_path)
    assert sem_nada["source_db"] is None and "nada foi inferido" in sem_nada["source_db_motivo"]
    assert sem_nada["legacy_db"] is None

    (tmp_path / "data" / "source").mkdir(parents=True)
    (tmp_path / "data" / "source" / "geracao.json").write_text('{"semente": 7, "as_of": "2026-09-01", "fator": "dev"}', encoding="utf-8")
    (tmp_path / "data" / "legacy").mkdir()
    (tmp_path / "data" / "legacy" / "manifesto.json").write_text('{"lote": {"hash": "abc", "parametros": {"semente": 20260906}}}', encoding="utf-8")
    com_registro = leitura.geracao_registrada(tmp_path)
    assert com_registro["source_db"]["semente"] == 7
    assert com_registro["legacy_db"] == {"parametros": {"semente": 20260906}, "hash": "abc"}


# ── Os artefatos de trabalho: o que o pacote traz, e o que ele não traz ─────


LOTE_ABC = '{"lote": {"hash": "abc", "parametros": {"semente": 1}}}'


def _pacote_com_artefatos(tmp_path: pathlib.Path) -> tuple[pathlib.Path, pathlib.Path]:
    """Um *checkout* com um lote do legado e o cursor, empacotado — o manifesto é o que o pack grava."""
    checkout, pasta = tmp_path / "checkout", tmp_path / "pacote"
    legado = checkout / "data" / "legacy"
    legado.mkdir(parents=True)
    (legado / "manifesto-abc.json").write_text(LOTE_ABC, encoding="utf-8")
    (legado / "manifesto.json").symlink_to("manifesto-abc.json")
    (checkout / ".stream").mkdir()
    (checkout / ".stream" / "producer_state.json").write_text('{"cursor": 7}', encoding="utf-8")
    pasta.mkdir()
    copiados, ausentes, links = pacote.copiar_artefatos(checkout, pasta)
    pacote.Manifesto(
        copy.deepcopy(MANIFESTO) | {"artefatos_copiados": copiados, "artefatos_ausentes": ausentes, "artefatos_links": links}
    ).gravar(pasta)
    return checkout, pasta


def _restaurar_artefatos(checkout: pathlib.Path, pasta: pathlib.Path) -> tuple[int, str]:
    saida = io.StringIO()
    with patch.object(cli, "RAIZ", checkout), patch.object(cli, "_pasta_do_pacote", return_value=pasta), \
            contextlib.redirect_stdout(saida), contextlib.redirect_stderr(saida):
        codigo = cli.comando_restore_artefatos(argparse.Namespace(dir=None))
    return codigo, saida.getvalue()


def test_o_pack_registra_o_link_e_guarda_o_conteudo(tmp_path):
    _checkout, pasta = _pacote_com_artefatos(tmp_path)
    dados = pacote.Manifesto.ler(pasta).dados

    assert dados["artefatos_links"] == {"data/legacy/manifesto.json": "manifesto-abc.json"}
    assert dados["artefatos_ausentes"] == ["data/source/geracao.json"]
    copia = pasta / "data" / "legacy" / "manifesto.json"
    assert not copia.is_symlink() and copia.read_text(encoding="utf-8") == LOTE_ABC


def test_restaurar_os_artefatos_restaura_a_ausencia(tmp_path):
    """RVE2-05, a sonda do revisor: o registro de uma carga posterior sobrevivia.

    Em B5 o `seed-data` roda antes da restauração e cria o registro; o pacote
    declara a ausência dele. Sem afastá-lo, o próximo pacote atribuía à origem
    restaurada os parâmetros da carga que a restauração desfez.
    """
    checkout, pasta = _pacote_com_artefatos(tmp_path)
    posterior = checkout / leitura.REGISTRO_DA_GERACAO
    posterior.parent.mkdir(parents=True)
    posterior.write_text('{"semente": "carga-posterior-ao-pacote"}', encoding="utf-8")

    codigo, saida = _restaurar_artefatos(checkout, pasta)

    assert codigo == 0, saida
    assert not posterior.exists()
    assert leitura.geracao_registrada(checkout)["source_db"] is None
    afastados = list(posterior.parent.glob(f"geracao.json{pacote.SUFIXO_AFASTADO}*"))
    assert len(afastados) == 1, "afastado, não apagado — o que ele dizia continua legível"
    assert "carga-posterior-ao-pacote" in afastados[0].read_text(encoding="utf-8")
    assert "afastado: data/source/geracao.json" in saida


def test_o_link_volta_como_link_e_nada_e_escrito_atraves_dele(tmp_path):
    """Achado próprio: `copy2` sobre o link escrevia no lote que ele apontasse.

    Depois de uma recarga do legado, `manifesto.json` aponta para o lote novo; a
    restauração sobrescrevia o manifesto **dele** com o conteúdo do antigo, e o
    diário de mutações — que grava no arquivo apontado — seguia no errado.
    """
    checkout, pasta = _pacote_com_artefatos(tmp_path)
    legado = checkout / "data" / "legacy"
    (legado / "manifesto-novo.json").write_text('{"lote": {"hash": "novo"}}', encoding="utf-8")
    (legado / "manifesto.json").unlink()
    (legado / "manifesto.json").symlink_to("manifesto-novo.json")

    codigo, saida = _restaurar_artefatos(checkout, pasta)

    assert codigo == 0, saida
    assert (legado / "manifesto.json").is_symlink()
    assert (legado / "manifesto.json").readlink() == pathlib.Path("manifesto-abc.json")
    novo = list(legado.glob(f"manifesto-novo.json{pacote.SUFIXO_AFASTADO}*"))
    assert len(novo) == 1 and novo[0].read_text(encoding="utf-8") == '{"lote": {"hash": "novo"}}', (
        "o lote novo não pode ter recebido o conteúdo do antigo"
    )
    assert (checkout / ".stream" / "producer_state.json").read_text(encoding="utf-8") == '{"cursor": 7}'


def test_pacote_incoerente_recusa_antes_de_mexer_em_qualquer_arquivo(tmp_path):
    checkout, pasta = _pacote_com_artefatos(tmp_path)
    posterior = checkout / leitura.REGISTRO_DA_GERACAO
    posterior.parent.mkdir(parents=True)
    posterior.write_text("{}", encoding="utf-8")
    (pasta / "data" / "legacy" / "manifesto-abc.json").unlink()

    codigo, saida = _restaurar_artefatos(checkout, pasta)

    assert codigo == 1 and "manifesto-abc.json: declarado no manifesto e ausente do pacote" in saida
    assert posterior.exists(), "recusar é não tocar em nada — nem afastar"

    dados = pacote.Manifesto.ler(pasta).dados
    dados["artefatos_copiados"].remove("data/legacy/manifesto-abc.json")
    pacote.Manifesto(dados).gravar(pasta)

    codigo, saida = _restaurar_artefatos(checkout, pasta)

    assert codigo == 1 and "link para manifesto-abc.json, que o pacote não traz" in saida
    assert posterior.exists() and (checkout / "data" / "legacy" / "manifesto.json").is_symlink()


def test_pacote_sem_registro_de_links_e_refeito_e_nao_restaurado(tmp_path):
    checkout, pasta = _pacote_com_artefatos(tmp_path)
    dados = pacote.Manifesto.ler(pasta).dados
    del dados["artefatos_links"]
    pacote.Manifesto(dados).gravar(pasta)

    codigo, saida = _restaurar_artefatos(checkout, pasta)

    assert codigo == 1 and "make recovery-pack" in saida
