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
import pathlib
import re
import zoneinfo

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
DBT = RAIZ / "dbt"
DIMENSOES_SCD = ("dim_customer", "dim_coupon", "dim_product", "dim_support_agent")

#: As macros de dialeto da Etapa 13 (`dbt/macros/portavel.sql`) que escrevem instante. As guardas
#: abaixo leem o SQL que o alvo **local** compila — o mesmo que sempre leram —, e por isso cada
#: chamada é trocada pelo que a metade `default__` dela emite, renderizada de verdade. O argumento
#: `var(...)` fica como Jinja, com as aspas que tinha: é o que a contraprova das aspas exercita.
_MACROS_DE_INSTANTE = ("meia_noite", "vigencia_do_snapshot")
_CHAMADA = re.compile(r"\b(" + "|".join(_MACROS_DE_INSTANTE) + r")\(")
_SENTINELA = "\x00"


def _portavel():
    import jinja2

    modulo = None

    class _Adaptador:
        def dispatch(self, nome, pacote=None):
            return getattr(modulo, "default__" + nome)

    fonte = (DBT / "macros" / "portavel.sql").read_text(encoding="utf-8")
    modulo = jinja2.Environment().from_string(fonte, globals={"adapter": _Adaptador(), "return": lambda v: v}).module
    return modulo


def _fecha(texto: str, i: int) -> int:
    """O índice depois do `)` que fecha o `(` em `i - 1`, saltando o que está entre aspas."""
    nivel, aspa = 1, None
    while nivel:
        c = texto[i]
        if aspa:
            aspa = None if c == aspa else aspa
        elif c in "'\"":
            aspa = c
        else:
            nivel += (c == "(") - (c == ")")
        i += 1
    return i


def _argumentos(texto: str) -> list[str]:
    """Os argumentos da chamada: string vira o valor dela; `var(...)` vira a sentinela, e o texto
    dele vai junto, para ser devolvido como Jinja no lugar certo."""
    partes, nivel, aspa, atual = [], 0, None, ""
    for c in texto:
        if aspa:
            aspa = None if c == aspa else aspa
        elif c in "'\"":
            aspa = c
        elif c == "," and nivel == 0:
            partes.append(atual.strip())
            atual = ""
            continue
        else:
            nivel += (c == "(") - (c == ")")
        atual += c
    partes.append(atual.strip())
    return partes


def renderizado_local(texto: str, modulo=None) -> str:
    """O texto com cada chamada das macros de instante trocada pela metade local renderizada.

    Chamada em `{{ … }}` vira o SQL, com o `var(...)` como `{{ var(...) }}`; chamada dentro de outra
    expressão Jinja (`{% set x = meia_noite(var("d")) %}`, `"…" ~ meia_noite(…) ~ "…"`) vira a
    concatenação Jinja que monta o mesmo literal — a forma que o modelo tinha antes da Etapa 13."""
    modulo = modulo or _portavel()
    saida, i = [], 0
    while (m := _CHAMADA.search(texto, i)) is not None:
        fim = _fecha(texto, m.end())
        brutos = _argumentos(texto[m.end():fim - 1])
        jinja = []
        args = []
        for a in brutos:
            if a.startswith("var("):
                jinja.append(a)
                args.append(_SENTINELA)
            elif len(a) >= 2 and a[0] == a[-1] and a[0] in "'\"":
                args.append(a[1:-1])
            else:
                raise AssertionError(f"argumento que a guarda não sabe ler: {a!r}")
        sql = str(getattr(modulo, m.group(1))(*args)).strip()
        antes = texto.rfind("{{", 0, m.start())
        dentro_de_chaves = antes >= 0 and texto[antes + 2:m.start()].strip() == ""
        if dentro_de_chaves and (fecho := re.match(r"\s*\}\}", texto[fim:])):
            pedacos = sql.split(_SENTINELA)
            sql = "".join(p + ("{{ " + jinja[k] + " }}" if k < len(jinja) else "") for k, p in enumerate(pedacos))
            saida.append(texto[i:antes] + sql)
            i = fim + fecho.end()
        else:
            pedacos = sql.split(_SENTINELA)
            expressao = " ~ ".join(
                x for k, p in enumerate(pedacos)
                for x in ([json.dumps(p, ensure_ascii=False)] + ([jinja[k]] if k < len(jinja) else []))
            )
            saida.append(texto[i:m.start()] + "(" + expressao + ")")
            i = fim
    saida.append(texto[i:])
    return "".join(saida)


def _sem_a_macro(texto: str, nome: str) -> str:
    """O texto sem o corpo de uma macro; as quebras de linha ficam, e a numeração das outras linhas
    continua a do arquivo."""
    inicio = texto.index("{% macro " + nome + "(")
    fim = texto.index("{%- endmacro %}", inicio) + len("{%- endmacro %}")
    return texto[:inicio] + "\n" * texto[inicio:fim].count("\n") + texto[fim:]


def _arquivos_lidos(pastas=("models", "tests", "macros", "snapshots")) -> dict[pathlib.Path, str]:
    """Os `.sql` fora do legado, como o alvo local os compila. Em `portavel.sql` sai o corpo da
    `default__meia_noite`: o literal dela tem o fuso no argumento, e o que se confere é cada chamada."""
    modulo = _portavel()
    arquivos = {}
    for pasta in pastas:
        for c in sorted((DBT / pasta).rglob("*.sql")):
            if "legacy" in c.parts:
                continue
            texto = c.read_text(encoding="utf-8")
            if c.name == "portavel.sql":
                # Onde as macros se definem não há chamada a renderizar.
                arquivos[c] = _sem_a_macro(texto, "default__meia_noite")
            else:
                arquivos[c] = renderizado_local(texto, modulo)
    return arquivos


def test_a_meia_noite_local_e_de_sao_paulo_por_padrao() -> None:
    """A guarda confia na renderização; esta é a contraprova da macro: o padrão é o fuso de São Paulo."""
    modulo = _portavel()
    assert str(modulo.meia_noite("2024-01-01")).strip() == "timestamptz '2024-01-01 00:00-03'"
    assert str(modulo.meia_noite("9999-12-31", "+00")).strip() == "timestamptz '9999-12-31 00:00+00'"
    assert renderizado_local("{{ meia_noite(var('as_of_date')) }}") == "timestamptz '{{ var('as_of_date') }} 00:00-03'"
    assert renderizado_local('{% set x = meia_noite(var("d")) %}') == '{% set x = ("timestamptz \'" ~ var("d") ~ " 00:00-03\'") %}'


def test_o_escritor_do_snapshot_grava_utc_explicito() -> None:
    macro = (DBT / "macros" / "snapshot_get_time.sql").read_text(encoding="utf-8")
    # As duas portas: a chamada direta e a que o `adapter.dispatch` procura (checagem de tipo).
    assert "macro snapshot_get_time()" in macro and "macro postgres__snapshot_get_time()" in macro
    assert macro.count("(now() at time zone 'UTC')") == 2


@pytest.mark.parametrize("dimensao", DIMENSOES_SCD)
def test_a_dimensao_le_as_vigencias_como_instante_utc(dimensao: str) -> None:
    sql = renderizado_local((DBT / "models" / "analytics" / f"{dimensao}.sql").read_text(encoding="utf-8"))
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


#: Onde somar dias a um valor não depende de fuso: `date + interval` em `dim_date` — desde a Etapa 13,
#: na metade local da macro que gera a série de datas dele.
SOMA_DE_DIAS_SEM_INSTANTE = {"dim_date.sql"}
MACROS_DE_SOMA_SEM_INSTANTE = {"portavel.sql": ("default__serie_de_datas",)}


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
        texto = caminho.read_text(encoding="utf-8")
        for macro in MACROS_DE_SOMA_SEM_INSTANTE.get(caminho.name, ()):
            texto = _sem_a_macro(texto, macro)
        for numero, linha in enumerate(texto.splitlines(), 1):
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


#: O fuso vem **depois de uma hora**: o `-31` de `9999-12-31` é o dia, não um offset (RVL3-8-02).
#: Offset numérico, `Z`, ou zona nomeada que o catálogo IANA conhece — `AM` não é fuso (RVL3-10-02).
_COM_FUSO = re.compile(r"\d{1,2}:\d{2}(:\d{2}(\.\d+)?)?\s*(Z|[+-]\d{1,2}(:?\d{2})?)\s*$")
_COM_ZONA = re.compile(r"\d{1,2}:\d{2}(:\d{2}(\.\d+)?)?\s+([A-Za-z][A-Za-z0-9_+\-]*(/[A-Za-z0-9_+\-]+)*)\s*$")
_ZONAS = zoneinfo.available_timezones() | {"UTC", "GMT", "Z"}

#: Os tokens do SQL que importam para a guarda; comentário e espaço não são token (RVL3-10-02).
_TOKEN = re.compile(r"""
    (?P<string>'(?:[^']|'')*')
  | (?P<palavra>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<numero>\d+)
  | (?P<duplo>::)
  | (?P<outro>\S)
""", re.X)


#: O que uma expressão Jinja dentro de uma string SQL vira para a guarda: opaca, sem aspas — o valor
#: dela só se conhece renderizado.
JINJA = "{{…}}"


def _jinja(texto: str, i: int) -> int | None:
    """Se em `i` abre `{{` ou `{%`, o índice depois do fecho; as aspas de dentro são do Jinja, não do SQL (RVL3-11-03)."""
    for abre, fecha in (("{{", "}}"), ("{%", "%}")):
        if texto.startswith(abre, i):
            j = texto.find(fecha, i + 2)
            return len(texto) if j < 0 else j + 2
    return None


def _sem_comentarios(texto: str) -> str:
    """O texto com comentários trocados por espaço: `--` até o fim da linha, `/* */` aninhado (como o
    PostgreSQL lê) e `{# #}` do Jinja. A string SQL é copiada inteira — `--` dentro dela não é comentário —,
    e a expressão Jinja **dentro dela** vira `JINJA`: em `'{{ var('x') }} 00:00-03'` a aspa de `'x'` não
    fecha a string SQL (RVL3-11-03). Fora da string a expressão continua lida como texto: o literal que
    um `{% set %}` monta (`"timestamptz '" ~ var("as_of_date") ~ " 00:00-03'"`) é lido nela."""
    saida, i, n = [], 0, len(texto)
    while i < n:
        if texto.startswith("{#", i):
            j = texto.find("#}", i + 2)
            i = n if j < 0 else j + 2
            saida.append(" ")
        elif texto.startswith("--", i):
            j = texto.find("\n", i)
            i = n if j < 0 else j
            saida.append(" ")
        elif texto.startswith("/*", i):
            nivel, i = 1, i + 2
            while i < n and nivel:
                if texto.startswith("/*", i):
                    nivel, i = nivel + 1, i + 2
                elif texto.startswith("*/", i):
                    nivel, i = nivel - 1, i + 2
                else:
                    i += 1
            saida.append(" ")
        elif texto[i] == "'":
            partes, i = ["'"], i + 1
            while i < n:
                if (j := _jinja(texto, i)) is not None:
                    partes.append(JINJA)
                    i = j
                elif texto.startswith("''", i):
                    partes.append("''")
                    i += 2
                else:
                    partes.append(texto[i])
                    i += 1
                    if partes[-1] == "'":
                        break
            saida.append("".join(partes))
        else:
            saida.append(texto[i])
            i += 1
    return "".join(saida)


def _tokens(texto: str) -> list[tuple[str, str]]:
    return [(m.lastgroup, m.group()) for m in _TOKEN.finditer(_sem_comentarios(texto))]


def _tipo_com_fuso(tokens: list[tuple[str, str]], i: int) -> int | None:
    """Se em `i` começa `timestamptz[(p)]` ou `timestamp[(p)] with time zone`, o índice depois dele."""
    def palavra(k: int, valor: str) -> bool:
        return k < len(tokens) and tokens[k][0] == "palavra" and tokens[k][1].lower() == valor

    def precisao(k: int) -> int:
        if k + 2 < len(tokens) and tokens[k][1] == "(" and tokens[k + 1][0] == "numero" and tokens[k + 2][1] == ")":
            return k + 3
        return k
    if palavra(i, "timestamptz"):
        return precisao(i + 1)
    if palavra(i, "timestamp"):
        k = precisao(i + 1)
        if palavra(k, "with") and palavra(k + 1, "time") and palavra(k + 2, "zone"):
            return k + 3
    return None


def _valor(string: str) -> str:
    return string[1:-1].replace("''", "'")


def _tem_fuso(valor: str) -> bool:
    if valor.strip().lower() in ("infinity", "-infinity") or _COM_FUSO.search(valor):
        return True
    zona = _COM_ZONA.search(valor)
    return bool(zona) and zona.group(3) in _ZONAS


def literais_sem_fuso(texto: str) -> list[str]:
    """Os literais de instante do SQL sem fuso escrito, lidos **por token**: prefixo de tipo, `::` e
    `cast(… as …)`, com precisão opcional, atravessando linha e comentário (RVL3-9-03, RVL3-10-02)."""
    tokens = _tokens(texto)
    achados = []
    for i, (tipo, valor) in enumerate(tokens):
        literal = None
        if (depois := _tipo_com_fuso(tokens, i)) is not None and depois < len(tokens) and tokens[depois][0] == "string":
            literal = tokens[depois][1]                                            # timestamptz '…'
        elif tipo == "string" and i + 1 < len(tokens) and tokens[i + 1][0] == "duplo" and _tipo_com_fuso(tokens, i + 2) is not None:
            literal = valor                                                        # '…'::timestamptz
        elif (tipo == "palavra" and valor.lower() == "cast" and i + 3 < len(tokens) and tokens[i + 1][1] == "("
              and tokens[i + 2][0] == "string" and tokens[i + 3][0] == "palavra" and tokens[i + 3][1].lower() == "as"
              and _tipo_com_fuso(tokens, i + 4) is not None):
            literal = tokens[i + 2][1]                                             # cast('…' as timestamptz)
        if literal is not None and not _tem_fuso(_valor(literal)):
            achados.append(_valor(literal))
    return achados


def test_todo_literal_timestamptz_diz_o_fuso() -> None:
    """RVL3-7-03: `timestamptz '2024-01-01'` é a meia-noite do fuso da **sessão**; o literal diz o seu."""
    sem_fuso = [f"{caminho.relative_to(DBT)}: {v}" for caminho, texto in _arquivos_lidos().items()
                for v in literais_sem_fuso(texto)]
    assert sem_fuso == []


@pytest.mark.parametrize("sql", [
    "select timestamptz '9999-12-31'", "select '9999-12-31'::timestamptz", "select cast('9999-12-31' as timestamptz)",
    "select timestamp with time zone '9999-12-31'", "select timestamptz\n    '9999-12-31'",
    "select '2024-01-01' :: timestamp with time zone",
])
def test_toda_grafia_de_literal_de_instante_sem_fuso_e_acusada(sql: str) -> None:
    """RVL3-9-03: a contraprova das grafias que o leitor por linha deixava passar."""
    assert literais_sem_fuso(sql) == ["9999-12-31"] or literais_sem_fuso(sql) == ["2024-01-01"]
    assert literais_sem_fuso(sql.replace("9999-12-31", "9999-12-31 00:00+00").replace("2024-01-01", "2024-01-01 00:00-03")) == []


def test_literal_em_comentario_nao_conta() -> None:
    assert literais_sem_fuso("select 1 -- timestamptz '2024-01-01'\n{# '2024-01-01'::timestamptz #}") == []


@pytest.mark.parametrize(("literal", "tem_fuso"), [
    ("2024-01-01", False), ("9999-12-31", False), ("2024-01-01 00:00", False),
    ("2024-01-01 00:00-03", True), ("9999-12-31 00:00+00", True), ("2024-01-01T12:30:00.5Z", True),
    ('" ~ var("period_start") ~ " 00:00-03', True), ("{{ var(\"as_of_date\") }} 00:00-03", True),
    ("2024-01-01 00:00 America/Sao_Paulo", True), ("2024-01-01 00:00 UTC", True),
    ("2024-01-01 00:00 AM", False), ("2024-01-01 00:00 America/Atlantida", False),
])
def test_a_guarda_le_o_fuso_e_nao_o_dia(literal: str, tem_fuso: bool) -> None:
    """RVL3-8-02, RVL3-10-02: a contraprova da própria guarda — zona nomeada só se o catálogo IANA a conhece."""
    assert _tem_fuso(literal) is tem_fuso


@pytest.mark.parametrize("sql", [
    "select timestamptz /* limite aberto */ '9999-12-31'",
    "select '9999-12-31' /* limite aberto */ ::timestamptz",
    "select cast('9999-12-31' /* limite aberto */ as timestamptz)",
    "select timestamptz -- limite aberto\n '9999-12-31'",
    "select timestamptz {# limite aberto #} '9999-12-31'",
    "select timestamptz(6) '9999-12-31'",
    "select cast('9999-12-31' as timestamptz(6))",
    "select '9999-12-31'::timestamp(3) with time zone",
    "select TIMESTAMP ( 3 ) WITH /* x */ TIME ZONE '9999-12-31'",
])
def test_comentario_entre_tokens_e_precisao_nao_escondem_o_literal(sql: str) -> None:
    """RVL3-10-02: o comentário separa tokens, não some com a expressão; a precisão é parte do tipo."""
    assert literais_sem_fuso(sql) == ["9999-12-31"]
    assert literais_sem_fuso(sql.replace("9999-12-31", "9999-12-31 00:00+00")) == []


@pytest.mark.parametrize("sql", [
    "/* timestamptz '2024-01-01' */ select 1",
    "/* fora /* aninhado */ timestamptz '2024-01-01' */ select 1",
    "select 'timestamptz ''2024-01-01'''",
    "select '-- não é comentário', timestamptz '2024-01-01 00:00-03'",
    "select timestamptz '2024-01-01 00:00 America/Sao_Paulo'",
    "select x at time zone 'America/Sao_Paulo'",
    "select timestamp '2024-01-01'",
])
def test_comentario_string_e_zona_nomeada_nao_sao_falso_positivo(sql: str) -> None:
    """RVL3-10-02: o exemplo em comentário ou dentro de string não é literal; zona IANA é fuso escrito.
    `timestamp` sem fuso não é instante — não é o que esta guarda vigia."""
    assert literais_sem_fuso(sql) == []


@pytest.mark.parametrize("aspas", ['"', "'"])
@pytest.mark.parametrize("forma", ["timestamptz '{x}'", "'{x}'::timestamptz", "cast('{x}' as timestamptz)"])
def test_a_aspa_do_jinja_dentro_do_literal_nao_fecha_a_string(aspas: str, forma: str) -> None:
    """RVL3-11-03: `'{{ var('as_of_date') }} 00:00-03'` renderiza o mesmo SQL que a grafia com aspas duplas;
    a aspa simples do argumento não fecha a string SQL — com offset passa, sem offset é acusado."""
    jinja = "{{ var(" + aspas + "as_of_date" + aspas + ") }}"
    assert literais_sem_fuso("select " + forma.format(x=jinja + " 00:00-03")) == []
    assert literais_sem_fuso("select " + forma.format(x=jinja + " 00:00")) == [JINJA + " 00:00"]
    assert literais_sem_fuso("select " + forma.format(x=jinja)) == [JINJA]


def test_a_guarda_acusa_cada_literal_atual_sem_o_offset_nas_duas_aspas() -> None:
    """RVL3-11-03: a contraprova sobre os arquivos reais — trocar as aspas do `var` não muda nada, e tirar o
    offset de qualquer literal é acusado, inclusive o que um `{% set %}` monta fora de `{{ }}`."""
    arquivos = _arquivos_lidos()
    simples = {c: re.sub(r"""(\{\{\s*var\()"([a-z_]+)"(\)\s*\}\})""", r"\1'\2'\3", t) for c, t in arquivos.items()}
    assert simples != arquivos and all(literais_sem_fuso(t) == [] for t in simples.values())
    for versao in (arquivos, simples):
        offsets = [(c, m.start()) for c, t in versao.items() for m in re.finditer(r" 00:00[-+]0[03]", t)]
        assert len(offsets) == 15  # 14 até a D76, que deu o fuso ao `hired_at` do membro desconhecido
        for caminho, inicio in offsets:
            texto = versao[caminho]
            sem = texto[:inicio] + " 00:00" + texto[inicio + len(" 00:00-03"):]
            assert len(literais_sem_fuso(sem)) == 1, f"{caminho.relative_to(DBT)}@{inicio}"
