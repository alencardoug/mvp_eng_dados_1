"""As vigências SCD não dependem do fuso da sessão: gravadas e lidas em UTC explícito.

O `dbt snapshot` do dbt-postgres grava `now()::timestamp without time zone` — a hora
local da sessão — em `dbt_valid_from`, `dbt_valid_to` e `dbt_updated_at`. As dimensões
SCD leem essas colunas como instante UTC, para comparar com o `timestamptz` das fatos.
Os dois lados só concordam se o escritor gravar UTC: é a macro `snapshot_get_time` do
projeto que o garante, no caminho que grava, e não um teste depois dele (revisão do
lote 3 da v1.1.0, RVL3-5-01).
"""

from __future__ import annotations

import json
import re
import pathlib

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
DBT = RAIZ / "dbt"
DIMENSOES_SCD = ("dim_customer", "dim_coupon", "dim_product", "dim_support_agent")


def test_o_escritor_do_snapshot_grava_utc_explicito() -> None:
    macro = (DBT / "macros" / "snapshot_get_time.sql").read_text(encoding="utf-8")
    # As duas portas: a chamada direta e a que o `adapter.dispatch` procura (checagem de tipo).
    assert "macro snapshot_get_time()" in macro and "macro postgres__snapshot_get_time()" in macro
    assert macro.count("(now() at time zone 'UTC')") == 2


@pytest.mark.parametrize("dimensao", DIMENSOES_SCD)
def test_a_dimensao_le_as_vigencias_como_instante_utc(dimensao: str) -> None:
    sql = (DBT / "models" / "analytics" / f"{dimensao}.sql").read_text(encoding="utf-8")
    assert "v.dbt_valid_from at time zone 'UTC'" in sql
    assert "v.dbt_valid_to at time zone 'UTC'" in sql


def test_o_dbt_carrega_a_macro_do_projeto() -> None:
    """No manifest, a macro do projeto existe com o corpo em UTC — a do projeto raiz vence a global.

    Que é ela que o snapshot roda se conferiu no log de um `dbt snapshot` da revisão: 60
    ocorrências de `(now() at time zone 'UTC')` e nenhuma de `now()::timestamp`."""
    manifest = DBT / "target" / "manifest.json"
    if not manifest.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    macros = json.loads(manifest.read_text(encoding="utf-8"))["macros"]
    for nome in ("snapshot_get_time", "postgres__snapshot_get_time"):
        assert "(now() at time zone 'UTC')" in macros[f"macro.mvp_ed1.{nome}"]["macro_sql"]


#: Onde somar dias a um valor não depende de fuso: `date + interval` em `dim_date`.
SOMA_DE_DIAS_SEM_INSTANTE = {"dim_date.sql"}


def test_janela_de_dias_sobre_instante_passa_pelo_calendario_de_sao_paulo() -> None:
    """RVL3-6-04: `instante ± interval 'N days'` soma no fuso da sessão; a macro diz o calendário.

    Toda soma de dias nos modelos passa por `dias_no_calendario`, salvo a de `date`
    declarada acima — um `+ interval` novo sobre `timestamptz` falha aqui."""
    soltas = []
    # Modelos, testes e macros: uma janela num teste muda o veredito dele (RVL3-7-02).
    arquivos = [c for pasta in ("models", "tests", "macros") for c in sorted((DBT / pasta).rglob("*.sql"))]
    for caminho in arquivos:
        if caminho.name in SOMA_DE_DIAS_SEM_INSTANTE | {"dias_no_calendario.sql"} or "legacy" in caminho.parts:
            continue
        for numero, linha in enumerate(caminho.read_text(encoding="utf-8").splitlines(), 1):
            codigo = linha.split("--", 1)[0]
            if "interval '" in codigo and "days'" in codigo:
                soltas.append(f"{caminho.relative_to(DBT)}:{numero}")
    assert soltas == [], "some dias com {{ dias_no_calendario(instante, n) }}"
    macro = (DBT / "macros" / "dias_no_calendario.sql").read_text(encoding="utf-8")
    assert macro.count("at time zone 'America/Sao_Paulo'") == 2


def test_o_hoje_dos_modelos_e_a_meia_noite_de_sao_paulo() -> None:
    """`date 'as_of'` comparado com `timestamptz` seria a meia-noite do fuso da sessão."""
    for caminho in sorted((DBT / "models").rglob("*.sql")):
        if "legacy" in caminho.parts or caminho.name in SOMA_DE_DIAS_SEM_INSTANTE:
            continue
        texto = caminho.read_text(encoding="utf-8")
        assert "\"date '\" ~ var(\"as_of_date\")" not in texto, caminho.name


_LITERAL_TIMESTAMPTZ = re.compile(r"timestamptz\s+'([^']*)'", re.I)
_COM_FUSO = re.compile(r"(Z|[+-]\d{2}(:?\d{2})?)\s*$")


def test_todo_literal_timestamptz_diz_o_fuso() -> None:
    """RVL3-7-03: `timestamptz '2024-01-01'` é a meia-noite do fuso da **sessão**; o literal diz o seu."""
    sem_fuso = []
    for pasta in ("models", "tests", "macros", "snapshots"):
        for caminho in sorted((DBT / pasta).rglob("*.sql")):
            if "legacy" in caminho.parts:
                continue
            for numero, linha in enumerate(caminho.read_text(encoding="utf-8").splitlines(), 1):
                for valor in _LITERAL_TIMESTAMPTZ.findall(linha.split("--", 1)[0]):
                    if valor.strip().lower() not in ("infinity", "-infinity") and not _COM_FUSO.search(valor):
                        sem_fuso.append(f"{caminho.relative_to(DBT)}:{numero}: {valor}")
    assert sem_fuso == []
