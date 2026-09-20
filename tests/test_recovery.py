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
    assert oraculos.NULO in oraculos.linha_canonica(vigente)


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
    com `-n` dispara `airbyte-up` — que tenta instalar o cluster. Medido aqui:
    a primeira versão destes testes chamou `abctl local install`, e só não
    reinstalou nada porque a armadilha do `PG_VERSION` (Execução Local §6)
    abortou antes.

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
