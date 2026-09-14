"""O reprocessamento da fato incremental, medido em vez de presumido.

Este arquivo existe por causa do achado **R25** da terceira revisão, e a frase
dele vale repetida: *reconstrução inicial não prova reprocessamento*. A fato
estava consistente com `trusted` nos dois sentidos, zero órfãos — e estava
assim porque tinha nascido de um `--full-refresh`, não porque a estratégia
incremental soubesse reconciliar. O teste que confere o estado saudável
(`dbt/tests/legado_na_fato_segue_a_captura_corrente.sql`) passava antes e
depois do [ADR-0042](../docs/adr/0042-reconciliar-a-captura-legada-na-fato-incremental.md).

A única prova possível é **estragar de propósito e mandar reprocessar**. É o que
o teste abaixo faz, nos dois caminhos que o `merge` com janela global não
fechava:

* **remoção** — um movimento legado materializado que a captura corrente não tem
  mais. `merge` só faz *upsert*: sem o `delete+insert` do ramo legado, ele
  sobreviveria até o `--full-refresh` agendado, corrompendo o saldo no
  meio-tempo;
* **atualização fora da janela** — um movimento legado cujo valor na fato
  divergiu do que a captura diz. O `occurred_at` dele é anterior ao corte da
  margem de atraso, então a janela por tempo de evento **nunca** o releria.

O teste escreve na fato e exige autorização explícita, pelo mesmo critério de
`test_carga.py`: um teste não pode ser mais permissivo que o comando que ele
testa. E devolve a fato ao estado anterior mesmo quando falha — por SQL direto,
**não** pela operação sob teste: a revisão (achado MR02) mostrou que um `finally`
que reprocessa "passa" justamente quando a estratégia é a defeituosa, e deixa o
fantasma e a divergência dentro da fato.
"""

from __future__ import annotations

import os
import pathlib
import subprocess

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

from mvp_ed1.db import WAREHOUSE, database_url

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
FATO = "analytics.fact_inventory_movement"
AUTORIZA_ESCRITA = "MVP_TESTE_CARGA"

#: Identificador do movimento fantasma. Nomeado pelo achado de propósito: se ele
#: aparecer num banco fora deste teste, a origem é esta e não a captura.
FANTASMA = "R25-MOVIMENTO-QUE-A-CAPTURA-NAO-TEM"


@pytest.fixture(scope="module")
def engine():
    motor = create_engine(database_url(WAREHOUSE), poolclass=NullPool)
    with motor.connect() as conexao:
        existe = conexao.execute(
            text(
                "select count(*) from information_schema.tables "
                "where table_schema = 'analytics' and table_name = 'fact_inventory_movement'"
            )
        ).scalar_one()
    if not existe:
        pytest.skip("fato não construída; rode `make dbt-build`")
    return motor


def _reprocessar() -> subprocess.CompletedProcess:
    """Uma execução **incremental** do modelo — sem `--full-refresh`.

    O `--full-refresh` reconstruiria tudo e provaria o que já se sabia. O que
    está sob teste é a execução do dia a dia.
    """
    return subprocess.run(
        [
            "../.venv/bin/dbt",
            "run",
            "--select",
            "fact_inventory_movement",
        ],
        cwd=RAIZ / "dbt",
        env={**os.environ, "DBT_PROFILES_DIR": "."},
        capture_output=True,
        text=True,
        timeout=300,
    )


def _colunas(conexao) -> list[str]:
    return [
        linha[0]
        for linha in conexao.execute(
            text(
                "select column_name from information_schema.columns "
                "where table_schema = 'analytics' and table_name = 'fact_inventory_movement' "
                "order by ordinal_position"
            )
        )
    ]


@pytest.mark.skipif(
    os.environ.get(AUTORIZA_ESCRITA) != "1",
    reason=f"escreve na fato; exija {AUTORIZA_ESCRITA}=1 para rodar",
)
def test_o_reprocessamento_remove_e_corrige_o_ramo_legado(engine, record_property) -> None:
    """Estraga a partição legada de duas formas e confere que reprocessar conserta."""
    with engine.connect() as conexao:
        corte = conexao.execute(
            text(
                f"select max(occurred_at) - interval '7 days' from {FATO} "
                "where source_system = 'retail'"
            )
        ).scalar_one()
        alvo = conexao.execute(
            text(
                f"select movement_id, quantity_delta, occurred_at from {FATO} "
                "where source_system = 'legacy' and occurred_at < :corte "
                "order by occurred_at limit 1"
            ),
            {"corte": corte},
        ).one_or_none()

    assert alvo is not None, (
        "nenhum movimento legado fora da janela de atraso; sem ele o teste não "
        "distingue o reprocessamento da releitura pela janela"
    )
    movimento, valor_correto, ocorrido_em = alvo
    assert ocorrido_em < corte, "o alvo precisa estar fora da janela para a prova valer"
    record_property("target_movement_outside_window_by_days", (corte - ocorrido_em).days)

    try:
        with engine.begin() as conexao:
            colunas = _colunas(conexao)
            # Fantasma: cópia de uma linha legada real com outra identidade, para
            # que ela seja indistinguível de uma linha legítima que a captura
            # anterior trouxe e a corrente não traz mais.
            projecao = ", ".join(
                f"'{FANTASMA}' as {c}"
                if c == "movement_id"
                else f"md5('{FANTASMA}') as {c}"
                if c == "movement_key"
                else c
                for c in colunas
            )
            conexao.execute(
                text(
                    f"insert into {FATO} select {projecao} from {FATO} "
                    "where source_system = 'legacy' order by movement_id limit 1"
                )
            )
            # Divergência de valor num movimento fora da janela.
            conexao.execute(
                text(
                    f"update {FATO} set quantity_delta = quantity_delta + 1000 "
                    "where source_system = 'legacy' and movement_id = :m"
                ),
                {"m": movimento},
            )

        with engine.connect() as conexao:
            assert conexao.execute(
                text(f"select count(*) from {FATO} where movement_id = :m"),
                {"m": FANTASMA},
            ).scalar_one() == 1, "o fantasma precisa existir antes do reprocessamento"

        execucao = _reprocessar()
        assert execucao.returncode == 0, f"dbt run falhou:\n{execucao.stdout}\n{execucao.stderr}"

        with engine.connect() as conexao:
            sobrou = conexao.execute(
                text(f"select count(*) from {FATO} where movement_id = :m"),
                {"m": FANTASMA},
            ).scalar_one()
            depois = conexao.execute(
                text(
                    f"select quantity_delta from {FATO} "
                    "where source_system = 'legacy' and movement_id = :m"
                ),
                {"m": movimento},
            ).scalar_one()

        assert sobrou == 0, (
            "o movimento ausente da captura sobreviveu ao reprocessamento — é o "
            "caminho que o `merge` sozinho nunca fecha, porque `merge` só faz upsert"
        )
        assert depois == valor_correto, (
            f"o valor divergente não foi corrigido ({depois} != {valor_correto}); "
            "o movimento está fora da janela de atraso, então só o recorte por "
            "captura poderia relê-lo"
        )
    finally:
        _desfazer_o_estrago(engine, movimento, valor_correto)


def _desfazer_o_estrago(engine, movimento: str, valor_correto) -> None:
    """Devolve a fato ao estado anterior ao teste, sem passar pelo dbt.

    O reparo é independente da operação sob teste de propósito: se ela é a
    defeituosa, reprocessar de novo "passa" e deixa o estrago onde está — foi o
    que a revisão reproduziu. Aqui se desfaz exatamente o que o teste fez, e
    nada mais: o fantasma sai pela identidade que só ele tem, e o valor volta
    ao que foi lido antes da adulteração. Quando o reprocessamento já consertou,
    as duas operações não tocam linha nenhuma. O estado é conferido depois, e
    sair daqui com a fato ainda adulterada é erro — o próximo `make dbt-build`
    acusaria um defeito que este teste plantou. Quando o corpo já falhou, o erro
    original continua visível como causa.
    """
    with engine.begin() as conexao:
        conexao.execute(
            text(f"delete from {FATO} where movement_id = :m"), {"m": FANTASMA}
        )
        conexao.execute(
            text(
                f"update {FATO} set quantity_delta = :v "
                "where source_system = 'legacy' and movement_id = :m "
                "and quantity_delta is distinct from :v"
            ),
            {"m": movimento, "v": valor_correto},
        )
    with engine.connect() as conexao:
        fantasmas = conexao.execute(
            text(f"select count(*) from {FATO} where movement_id = :m"), {"m": FANTASMA}
        ).scalar_one()
        valor = conexao.execute(
            text(
                f"select quantity_delta from {FATO} "
                "where source_system = 'legacy' and movement_id = :m"
            ),
            {"m": movimento},
        ).scalar_one_or_none()
    if fantasmas != 0 or valor != valor_correto:
        raise RuntimeError(
            "a fato ficou com o estado que este teste plantou "
            f"(fantasmas={fantasmas}, quantity_delta={valor!r}, esperado={valor_correto!r}); "
            "rode `make dbt-build DBT_ARGS='--select fact_inventory_movement+ --full-refresh'`"
        )
