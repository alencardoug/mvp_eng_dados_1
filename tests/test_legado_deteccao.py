"""As regras de detecção encontram o que o injetor produziu.

Este é o teste que **liga a declaração ao SQL**. O catálogo diz que
`MONEY_LOCALE` é um valor monetário com separadores; o injetor produz
`R$ 1.234,56`; e a regra precisa reconhecê-lo em `raw_legacy`. Se qualquer um
dos três discordar, é aqui que aparece.

Ele lê o **manifesto** — o oráculo — e confronta cada achado com a expressão de
detecção correspondente, executada contra a captura mais recente. A
transformação continua sem acesso ao manifesto: quem o consulta é o teste.

Cinco defeitos reais foram encontrados por esta verificação antes de existir
qualquer modelo dbt, e cada um teria custado caro depois:

* o `to_date` do PostgreSQL 16 **estoura** com data fora de faixa, e a detecção
  por ida e volta derrubava a consulta inteira em vez de rejeitar a linha;
* o corte no limite repetia o valor três vezes, o que não alcançava o limite de
  colunas mais largas — o defeito saía com o comprimento errado;
* a string vazia não sobrevive ao transporte: o destino a entrega como nulo;
* caixa alterada em texto livre não é reconhecível sem convenção declarada;
* e, ao tirar a string vazia da lista de marcadores, o valor só com espaços
  deixou de casar por tabela.
"""

from __future__ import annotations

import collections
import json
import pathlib

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.generator import enums
from mvp_ed1.legacy import dbt, ponte, schema
from mvp_ed1.legacy.catalogo import carregar
from mvp_ed1.legacy.regras import regra_enum, regra_truncado, regras

pytestmark = pytest.mark.integracao

MANIFESTO = pathlib.Path("data/legacy/manifesto.json")


@pytest.fixture(scope="module")
def manifesto() -> dict:
    if not MANIFESTO.exists():
        pytest.skip(f"sem manifesto em {MANIFESTO}; rode `make seed-legacy`")
    return json.loads(MANIFESTO.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def engine():
    """Motor **sem pool**: cada `connect()` é um `backend` novo, e fechá-lo devolve a memória.

    Contenção, não conserto. O que estoura a máquina é o JIT do PostgreSQL sobre
    estas views (ver `_achados_dos_modelos`), e `NullPool` não o desliga: medido
    em 08/09/2026, uma única view pesada numa sessão recém-aberta já passa de
    2 GB com `jit=on`. O que o `NullPool` evita é o acúmulo **entre** consultas —
    com o pool padrão as quarenta caem no mesmo `backend` e somam; sem ele, o
    pico de cada uma é independente. Enquanto a causa não é decidida, este
    arquivo ao menos não soma quarenta.
    """
    motor = create_engine(database_url(WAREHOUSE), poolclass=NullPool)
    with motor.connect() as conexao:
        existe = conexao.execute(
            text(
                "select count(*) from information_schema.tables where table_schema = 'raw_legacy'"
            )
        ).scalar_one()
    if not existe:
        pytest.skip("sem `raw_legacy`; rode `make sync-legacy`")
    return motor


def _regra(codigo: str, tabela: str, coluna: str, catalogo, limites):
    if codigo == "TEXT_TRUNCATED":
        return regra_truncado(limites[(tabela, coluna)])
    if codigo == "ENUM_UNKNOWN":
        valores = enums.enumeracoes().get(tabela, {}).get(coluna)
        return regra_enum(valores) if valores else None
    return regras(catalogo.nulos_disfarcados, catalogo.delimitador).get(codigo)


def test_toda_falha_injetada_e_detectada_pela_sua_regra(engine, manifesto) -> None:
    catalogo = carregar()
    limites = schema.limites(catalogo.limite_de_texto)
    injetados: collections.Counter[str] = collections.Counter()
    detectados: collections.Counter[str] = collections.Counter()
    escapou: list[str] = []

    for achado in manifesto["achados"]:
        coluna = achado["coluna"]
        if coluna is None:  # falha de linha inteira: não tem expressão de valor
            continue
        regra = _regra(achado["codigo"], achado["tabela"], coluna, catalogo, limites)
        if regra is None:
            continue

        injetados[achado["codigo"]] += 1
        expressao = regra.deteccao.format(v="valor").replace(
            '{{ var("as_of_date") }}', "2026-09-01"
        )
        tabela = achado["tabela"]
        consulta = (
            f"select ({expressao}) from ("
            f'  select "{coluna}" as valor from raw_legacy."{tabela}"'
            f"  where legacy_row_id = :linha"
            f'    and _airbyte_generation_id = ('
            f'      select max(_airbyte_generation_id) from raw_legacy."{tabela}")'
            f") alvo"
        )
        # Uma transação por consulta: uma expressão que estoure não pode
        # contaminar a medição das demais — foi assim que o primeiro defeito
        # apareceu disfarçado de cinco.
        with engine.connect() as conexao:
            resultado = conexao.execute(text(consulta), {"linha": achado["legacy_row_id"]}).scalar()
        if resultado:
            detectados[achado["codigo"]] += 1
        else:
            escapou.append(f"{achado['codigo']} em {tabela}.{coluna} #{achado['legacy_row_id']}")

    assert injetados, "o manifesto não tem achado de valor; a geração falhou antes"
    assert detectados == injetados, "falhas injetadas que a regra não encontra: " + "; ".join(
        escapou[:10]
    )


#: Teto de falso positivo aceito, em fração das linhas capturadas.
#
# Não é zero de propósito. `TEXT_TRUNCATED` é heurística declarada — comprimento
# igual à largura da coluna antiga —, e um valor legítimo desse tamanho é
# indistinguível de um cortado. O que não se aceita é que a heurística deixe de
# ser marginal: quando ela era aplicada a todas as colunas de texto, produzia
# 1.508 rejeições falsas, e foi essa medição que criou a lista de colunas
# estreitadas no catálogo.
TETO_DE_FALSO_POSITIVO = 0.005

#: Falhas que **não** são achados de valor, e por isso não aparecem no `achados`
#: dos modelos de limpeza. Três precisam de outras linhas ou de outra tabela; a
#: quarta, `NULL_REQUIRED`, nasce do contrato do registro **depois** da
#: conversão — reconhecer a ausência não torna a ocorrência válida (ADR-0040).
DE_CONTEXTO = frozenset(
    {"FK_ORPHAN", "DUP_EXACT", "DUP_PARTIAL", "TOTAL_MISMATCH", "NULL_REQUIRED"}
)


def _achados_dos_modelos(engine) -> set[tuple[str, int, str, str]]:
    """Lê o `achados` de cada modelo de limpeza — **uma consulta por tabela**.

    A forma óbvia é um `union all` das quarenta views numa consulta só, e foi
    assim até 08/09/2026, quando travou a estação duas vezes: um `backend` do
    armazém chegou a 7,7 GB numa máquina de 11 GB, e o que morreu não foi a
    consulta, foi o ambiente de trabalho junto.

    A causa não é volume — cada view tem uma linha. São **duas**, medidas em
    08/09/2026 nesta máquina, e só a segunda é tratada aqui:

    * **o JIT do PostgreSQL** (`jit=on`, padrão). A view de limpeza é código
      gerado de 60 a 120 kB, com dezenas de expressões regulares por coluna; o
      LLVM compila essa árvore e não devolve o que alocou. A mesma view, na
      mesma sessão nova, custa **281 MB com `jit=off` e passa de 2 GB com
      `jit=on`**. É a causa raiz, vale para `dbt build` também, e é decisão do
      Owner — não se conserta em teste.
    * **a união de quarenta braços**. O planejador embute a view no lugar da
      referência, e unir as quarenta dá uma árvore de três megabytes para
      pré-processar de uma vez: passa de 2 GB *mesmo com o JIT desligado*. Por
      tabela, o pico volta para o de uma view só.

    Consulta por tabela não perde nada: o resultado é um conjunto, e a união
    passa a acontecer em Python, onde quarenta conjuntos de dezenas de tuplas
    não custam nada. O modelo `legacy_records` tem a mesma forma e o mesmo
    problema, e esse não dá para resolver em Python.
    """
    achados: set[tuple[str, int, str, str]] = set()
    for tabela in schema.tabelas():
        consulta = (
            f"select '{tabela}' as tabela, legacy_row_id, chave as coluna, valor as codigo "
            f"from staging.stg_legacy__{tabela}, jsonb_each_text(achados) as e(chave, valor)"
        )
        # Uma conexão por tabela — e o `NullPool` do `engine` é que faz disso um
        # `backend` novo de fato. Sem ele, `connect()` devolve o mesmo do pool.
        with engine.connect() as conexao:
            achados.update(tuple(linha) for linha in conexao.execute(text(consulta)))
    return achados


def test_os_modelos_encontram_tudo_que_o_injetor_produziu(
    engine, manifesto, record_property
) -> None:
    """A ponta final: o SQL gerado acha no banco o que o manifesto declara.

    O teste anterior confere **regra a regra**, isolada. Este confere o
    resultado do modelo inteiro, onde a precedência entre falhas passa a
    valer — e é ela que erra em silêncio. Três defeitos apareceram só aqui:

    * a ordem do catálogo punha `DATE_FORMAT_KNOWN` antes de `DATE_IMPOSSIBLE`,
      e uma data que não existe era **convertida** em vez de rejeitada;
    * duas falhas caíam na mesma célula, e a segunda apagava o valor da
      primeira — o manifesto declarava um achado que já não existia;
    * o `TEXT_DELIMITER` esvaziava as colunas vizinhas, apagando defeitos que
      já estavam nelas.
    """
    with engine.connect() as conexao:
        # `tables`, não `views`: a pergunta é se o modelo existe, não como ele
        # foi materializado. Perguntar por `views` fazia este teste **pular em
        # silêncio** assim que o ADR-0043 tornou o staging legado tabela — e
        # pular em silêncio é o modo de falha que este arquivo existe para pegar.
        existe = conexao.execute(
            text(
                "select count(*) from information_schema.tables "
                "where table_schema = 'staging' and table_name like 'stg_legacy__%'"
            )
        ).scalar_one()
    if not existe:
        pytest.skip("modelos de limpeza não construídos; rode `make dbt-build`")

    de_contexto = DE_CONTEXTO
    esperados = {
        (a["tabela"], a["legacy_row_id"], a["coluna"], a["codigo"])
        for a in manifesto["achados"]
        if a["coluna"] is not None and a["codigo"] not in de_contexto
    }
    encontrados = _achados_dos_modelos(engine)

    perdidos = sorted(esperados - encontrados)
    record_property("injected_value_findings", len(esperados))
    record_property("detected_value_findings", len(esperados & encontrados))
    record_property("missed_value_findings", len(perdidos))
    assert not perdidos, f"injetados e não detectados pelos modelos: {perdidos[:8]}"


def test_o_falso_positivo_da_heuristica_continua_marginal(
    engine, manifesto, record_property
) -> None:
    """A heurística é aceita; deixar de ser marginal, não."""
    de_contexto = DE_CONTEXTO
    esperados = {
        (a["tabela"], a["legacy_row_id"], a["coluna"], a["codigo"])
        for a in manifesto["achados"]
        if a["coluna"] is not None and a["codigo"] not in de_contexto
    }
    encontrados = _achados_dos_modelos(engine)
    if not encontrados:
        pytest.skip("modelos de limpeza não construídos")

    with engine.connect() as conexao:
        linhas = sum(
            conexao.execute(
                text(
                    f"select count(*) from raw_legacy.\"{tabela}\" where _airbyte_generation_id = "
                    f"(select max(_airbyte_generation_id) from raw_legacy.\"{tabela}\")"
                )
            ).scalar_one()
            for tabela in schema.tabelas()
        )

    falsos = len(encontrados - esperados)
    record_property("false_positive_findings", falsos)
    record_property("captured_rows", linhas)
    assert falsos / linhas <= TETO_DE_FALSO_POSITIVO, (
        f"{falsos} falsos positivos em {linhas} linhas "
        f"({falsos / linhas:.2%}), acima do teto declarado"
    )


@pytest.mark.parametrize(
    "table,column,value,expected_code,expected_value",
    [
        ("orders", "placed_at", "31/02/2024", "DATE_IMPOSSIBLE", "31/02/2024"),
        ("orders", "placed_at", "29/02/2025", "DATE_IMPOSSIBLE", "29/02/2025"),
        ("orders", "placed_at", "29/02/2024", "DATE_FORMAT_KNOWN", "2024-02-29"),
        ("orders", "placed_at", "   ", "NULL_DISGUISED", None),
        ("support_agents", "email", " a @example.com ", "EMAIL_MALFORMED", " a @example.com "),
        ("cart_items", "quantity", "8,0", "NUM_TEXT_EQUIV", "8"),
        ("cart_items", "quantity", "8.5", "NUM_AMBIGUOUS", "8.5"),
        ("cart_items", "quantity", "8", None, "8"),
    ],
)
def test_detection_and_cleaning_share_precedence(
    engine, table, column, value, expected_code, expected_value
) -> None:
    """Detectar rejeição não basta: a coluna tratada não pode tentar convertê-la.

    Valores dirigidos, independentes do injetor. Consultar apenas `achados`
    permite ao PostgreSQL eliminar a avaliação das demais expressões da view;
    uma conversão que estoura ficava invisível na medição dos 74 achados.
    """
    catalog = carregar()
    limits = schema.limites(catalog.limite_de_texto, catalog.colunas_estreitadas)
    rules = dbt._aplicaveis(catalog, table, column, catalog.promessas, limits)

    # O arranjo espelha o modelo gerado, e precisa disso por duas razões que
    # apareceram consertando a revisão:
    #
    # * o achado de rejeição é conferido contra o valor **já convertido**, que
    #   no modelo vive numa CTE `l`. Sem ela, `-1.0` voltaria a sair corrigido;
    # * `TEXT_DELIMITER` olha as colunas **vizinhas** — o deslocamento de uma
    #   linha importada só é observável se os campos seguintes estiverem
    #   vazios. Um `c` de coluna única falharia com `UndefinedColumn`.
    #
    # Por isso `c` traz todas as colunas da tabela, com a alvo recebendo o valor
    # dirigido e as demais nulas.
    vizinhas = ",\n            ".join(
        f'null::text as "{outra}"' for outra in schema.colunas(table) if outra != column
    )
    query = (
        f"""
        with c as (
            select cast(:value as text) as "{column}",
            {vizinhas}
        ),
        l as (
            select {dbt._limpo(column, rules)} as "{column}" from c
        )
        select {dbt._achado(column, rules)} as code, l."{column}" as cleaned
        from c cross join l
        """
    ).replace('{{ var("as_of_date") }}', "2026-09-01")
    with engine.connect() as connection:
        actual = connection.execute(text(query), {"value": value}).one()
    assert tuple(actual) == (expected_code, expected_value)


def test_cleaned_models_materialize_every_column(engine) -> None:
    """Ler efetivamente todas as colunas, não só contar linhas ou achados.

    O hash não sai do banco e o teste não imprime payloads pessoais. A consulta
    é somente leitura: nem a captura nem os modelos são alterados.
    """
    for table in schema.tabelas():
        with engine.connect() as connection:
            count = connection.execute(text(
                f"select count(md5(to_jsonb(c)::text))"
                f" from staging.stg_legacy__{table} c"
            )).scalar_one()
        assert count > 0, f"{table}: o cenário gerado exige cobertura"


def test_as_pontes_expoem_o_mesmo_formato_do_staging(engine) -> None:
    """Cada `legado__<t>` expõe as colunas de `stg_retail__<t>`, na mesma ordem.

    É o que o `union all` do empilhamento exige e não verifica: ele casa por
    **posição**, e duas relações com a mesma contagem de colunas em ordem
    trocada se unem sem erro, escrevendo o valor de uma coluna dentro de outra.

    A ponte é gerada a partir do próprio modelo de `staging`, então a igualdade
    deveria vir de graça. Deveria — e é justamente por isso que se confere: o
    gerador lê o texto do SQL, e o que o empilhamento une é o que o banco
    materializou. A comparação é contra o **banco** por esse motivo, e também
    porque coluna que passa sem `as` não aparece numa leitura por expressão
    regular; a primeira versão deste teste falhou exatamente aí.
    """
    def colunas(schema_nome: str, relacao: str) -> list[str]:
        with engine.connect() as conexao:
            return [
                linha[0]
                for linha in conexao.execute(
                    text(
                        "select column_name from information_schema.columns "
                        "where table_schema = :s and table_name = :t "
                        "order by ordinal_position"
                    ),
                    {"s": schema_nome, "t": relacao},
                )
            ]

    divergentes = {}
    conferidas = 0
    for tabela in ponte.empilhaveis():
        do_retail = colunas("staging", f"stg_retail__{tabela}")
        do_legado = colunas("trusted", f"legado__{tabela}")
        if not do_retail or not do_legado:
            continue
        conferidas += 1
        if do_legado != do_retail:
            divergentes[tabela] = (
                f"só no legado: {set(do_legado) - set(do_retail)}; "
                f"só no retail: {set(do_retail) - set(do_legado)}; "
                f"ordem igual: {sorted(do_legado) == sorted(do_retail)}"
            )

    if conferidas == 0:
        pytest.skip("relações não construídas; rode `make dbt-build`")

    assert not divergentes, f"pontes fora de formato: {divergentes}"
    assert conferidas == len(ponte.empilhaveis()), (
        f"só {conferidas} das {len(ponte.empilhaveis())} pontes foram conferidas"
    )


def test_a_rejeicao_de_valor_alcanca_o_resultado_da_conversao(engine) -> None:
    """Conversão bem-sucedida não pode esconder que o resultado é inválido.

    Era o R06 da segunda revisão. O modelo prometia, em comentário, conferir os
    achados contra o valor já convertido; o SQL emitido só olhava o original. A
    consequência é silenciosa e cara: `-1.0` não casa `NUM_OUT_OF_RANGE`, que
    exige dígitos puros, mas casa `NUM_TEXT_EQUIV` — vira `-1`, é declarado
    **corrigido**, e uma quantidade negativa entra no armazém como boa.

    O teste executa o `case` que o gerador emite, contra valores construídos
    para o caso. Não depende de a origem gerada conter esses defeitos: o
    conjunto de hoje não contém nenhum deles, e por isso a correção não mudou
    contagem nenhuma — o que a torna exatamente o tipo de conserto que regride
    sem ninguém notar.
    """
    catalogo = carregar()
    limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
    aplicaveis = dbt._aplicaveis(catalogo, "order_items", "quantity", frozenset(), limites)

    consulta = f"""
        with captura(legacy_row_id, "quantity") as (values {{valores}}),
        limpo as (
            select c.legacy_row_id,
{dbt._limpo("quantity", aplicaveis)} as "quantity"
            from captura c
        )
        select c."quantity", l."quantity",
{dbt._achado("quantity", aplicaveis)}
        from captura c join limpo l on l.legacy_row_id = c.legacy_row_id
        order by c.legacy_row_id
    """.replace(
        "{valores}", "(1, '-1.0'), (2, '1000001,0'), (3, 'oito'), (4, '7')"
    )

    with engine.connect() as conexao:
        obtido = [tuple(linha) for linha in conexao.execute(text(consulta))]

    assert obtido == [
        # Convertem e o resultado é inválido: a rejeição vence a correção.
        ("-1.0", "-1", "NUM_OUT_OF_RANGE"),
        ("1000001,0", "1000001", "NUM_OUT_OF_RANGE"),
        # Convertem para valor válido: seguem corrigíveis.
        ("oito", "8", "NUM_TEXT_EQUIV"),
        ("7", "7", None),
    ], obtido


def test_a_validacao_de_data_olha_a_entrada_inteira(engine) -> None:
    """Calendário, relógio e a string toda — antes de qualquer `cast`.

    Era o R02 da segunda revisão, e os três casos falhavam de formas
    diferentes:

    * `0000-01-01` tinha mês e dia válidos e ninguém olhava o ano. O Postgres
      não tem ano zero, e o `cast` seguinte **abortava a consulta inteira** —
      não a linha, a consulta: um valor derrubava o modelo;
    * `2024-01-01 99:00` casava o padrão de `DATE_TZ_MISSING`, que convertia
      com `::timestamp` sem nunca olhar o relógio. Também abortava;
    * `2024-01-01 lixo` tinha dez caracteres de data e sujeira no resto. O
      reconhecimento era por **prefixo**, então nenhuma regra casava: o
      registro saía aceito, com o texto intacto, para estourar no `cast` da
      ponte três camadas adiante.

    Os três últimos casos guardam contra o conserto ir longe demais: data
    válida, formato conhecido e formato pontuado precisam continuar passando.
    """
    catalogo = carregar()
    limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
    aplicaveis = dbt._aplicaveis(catalogo, "customers", "birth_date", frozenset(), limites)

    valores = (
        "(1, '0000-01-01'), (2, '2024-01-01 99:00'), (3, '2024-01-01 lixo'),"
        " (4, '1990-05-12'), (5, '31/12/1990'), (6, '2024-02-31'), (7, '1990.05.12')"
    )
    consulta = f"""
        with captura(legacy_row_id, "birth_date") as (values {valores}),
        limpo as (
            select c.legacy_row_id,
{dbt._limpo("birth_date", aplicaveis)} as "birth_date"
            from captura c
        )
        select c."birth_date", l."birth_date",
{dbt._achado("birth_date", aplicaveis)}
        from captura c join limpo l on l.legacy_row_id = c.legacy_row_id
        order by c.legacy_row_id
    """.replace('{{ var("as_of_date") }}', "2026-09-01")

    with engine.connect() as conexao:
        obtido = [tuple(linha) for linha in conexao.execute(text(consulta))]

    assert obtido == [
        ("0000-01-01", "0000-01-01", "DATE_IMPOSSIBLE"),
        ("2024-01-01 99:00", "2024-01-01 99:00", "DATE_IMPOSSIBLE"),
        ("2024-01-01 lixo", "2024-01-01 lixo", "DATE_UNPARSEABLE"),
        ("1990-05-12", "1990-05-12", None),
        ("31/12/1990", "1990-12-31", "DATE_FORMAT_KNOWN"),
        ("2024-02-31", "2024-02-31", "DATE_IMPOSSIBLE"),
        ("1990.05.12", "1990-05-12", "DATE_FORMAT_KNOWN"),
    ], obtido


def _sobre_a_linha(engine, tabela: str, coluna: str, entradas: list[str]):
    """Roda o `case` emitido para uma coluna, com a linha inteira em volta.

    A linha inteira, e não só a coluna, porque `TEXT_DELIMITER` olha as colunas
    vizinhas: sem elas o SQL emitido nem compila. As demais entram nulas, que é
    o vizinho vazio que a heurística de deslocamento espera.
    """
    catalogo = carregar()
    limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
    aplicaveis = dbt._aplicaveis(catalogo, tabela, coluna, frozenset(), limites)

    outras = [c for c in schema.colunas(tabela) if c != coluna]
    declaracao = ", ".join(f'"{c}"' for c in [coluna] + outras)
    valores = ", ".join(
        f"(:i{n}, :v{n}" + ", null" * len(outras) + ")" for n in range(len(entradas))
    )
    consulta = f"""
        with captura(legacy_row_id, {declaracao}) as (values {valores}),
        limpo as (
            select c.legacy_row_id,
{dbt._limpo(coluna, aplicaveis)} as "{coluna}"
            from captura c
        )
        select c."{coluna}", l."{coluna}",
{dbt._achado(coluna, aplicaveis)}
        from captura c join limpo l on l.legacy_row_id = c.legacy_row_id
        order by c.legacy_row_id
    """.replace('{{ var("as_of_date") }}', "2026-09-01")

    parametros = {}
    for n, valor in enumerate(entradas):
        parametros[f"i{n}"] = n
        parametros[f"v{n}"] = valor
    with engine.connect() as conexao:
        return [tuple(linha) for linha in conexao.execute(text(consulta), parametros)]


def test_o_momento_e_lido_por_componente_e_nao_por_posicao(engine) -> None:
    """R02 da terceira revisão: o validador derrubava consulta e rejeitava válido.

    Três defeitos distintos, todos vindos de ler o momento por **posição fixa**
    e de exigir quatro dígitos de fuso:

    * `substring(v from 18 for 2)` devolve **string vazia** quando os segundos
      não vêm, e `coalesce` não trata vazio — `2024-01-01 12:30` abortava a
      consulta com 22P02, `invalid input syntax for type integer: ""`;
    * `at time zone` devolve `+00`, com duas casas. A forma exigia quatro, então
      o resultado da **própria conversão** era reprovado como `DATE_UNPARSEABLE`
      — o valor era corrigido e rejeitado no mesmo passe;
    * `+99:99` casava a forma, não recebia achado nenhum e abortava adiante no
      `cast` para `timestamptz` com 22009.

    Os dois últimos casos guardam o conserto: fuso completo e data futura
    precisam continuar respondendo como antes.
    """
    obtido = _sobre_a_linha(engine, "orders", "placed_at", [
        "2024-01-01 12:30",
        "2024-01-01T12:30Z",
        "2024-01-01T12:30:00",
        "2024-01-01T12:30:00+00",
        "2024-01-01T12:30:00+99:99",
        "2024-01-01T12:30:00+00:00",
        "01/01/2030",
    ])

    assert obtido == [
        # Segundos ausentes: converte, em vez de abortar.
        ("2024-01-01 12:30", "2024-01-01 15:30:00+00", "DATE_TZ_MISSING"),
        ("2024-01-01T12:30Z", "2024-01-01T12:30Z", None),
        # O resultado da conversão é aceito pela forma que a conversão produz.
        ("2024-01-01T12:30:00", "2024-01-01 15:30:00+00", "DATE_TZ_MISSING"),
        ("2024-01-01T12:30:00+00", "2024-01-01T12:30:00+00", None),
        # Deslocamento impossível é data impossível, não data a converter.
        ("2024-01-01T12:30:00+99:99", "2024-01-01T12:30:00+99:99", "DATE_IMPOSSIBLE"),
        ("2024-01-01T12:30:00+00:00", "2024-01-01T12:30:00+00:00", None),
        ("01/01/2030", "2030-01-01", "DATE_FUTURE"),
    ], obtido


def test_a_reversibilidade_recusa_utf8_invalido(engine) -> None:
    """R03 da terceira revisão: a gramática admitia sequências que o UTF-8 proíbe.

    Os ramos de três e quatro bytes aceitavam qualquer continuação depois do
    primeiro byte, o que autoriza três famílias que `convert_from` recusa com
    **22021 — e 22021 aborta a consulta inteira**, não a linha:

    * codificação excessivamente longa: `E0 80 80` e `F0 80 80 80`;
    * substituto UTF-16: `ED A0 80`;
    * ponto acima de U+10FFFF: `F4 90 80 80`.

    Os bytes chegam como texto Latin-1, que é como estão em `raw_legacy`. O
    primeiro caso guarda o conserto: mojibake genuíno continua sendo reparado.
    """
    obtido = _sobre_a_linha(engine, "products", "name", [
        "CafÃ©",
        "CafÃ© " + bytes.fromhex("eda080").decode("latin1"),
        "CafÃ© " + bytes.fromhex("e08080").decode("latin1"),
        "CafÃ© " + bytes.fromhex("f4908080").decode("latin1"),
    ])

    assert obtido == [
        ("CafÃ©", "Café", "TEXT_ENCODING"),
        # Não reversível é rejeitado — e, sobretudo, não é convertido.
        ("CafÃ© í\xa0\x80", "CafÃ© í\xa0\x80", "TEXT_ENCODING_AMBIGUOUS"),
        ("CafÃ© à\x80\x80", "CafÃ© à\x80\x80", "TEXT_ENCODING_AMBIGUOUS"),
        ("CafÃ© ô\x90\x80\x80", "CafÃ© ô\x90\x80\x80", "TEXT_ENCODING_AMBIGUOUS"),
    ], obtido


def test_moeda_com_duas_leituras_e_rejeitada_em_vez_de_escolhida(engine) -> None:
    """R04 da terceira revisão: `1,234` cabe nos dois formatos e eles discordam.

    Um inteiro e 234 milésimos, na leitura brasileira; mil duzentos e trinta e
    quatro, na americana. A regra escolhia o primeiro ramo do `case` e entregava
    `1.234` marcado como **corrigido** — uma das duas leituras, em silêncio.

    A Origem Legada §3.1 manda o contrário: reparar quando o par é conhecido,
    rejeitar quando é ambíguo. Os demais casos guardam o conserto: formato de
    leitura única continua sendo corrigido.
    """
    obtido = _sobre_a_linha(engine, "product_prices", "unit_price", [
        "1,234", "1,234,567", "12,34", "1.234,56", "1234.56",
    ])

    assert obtido == [
        ("1,234", "1,234", "MONEY_AMBIGUOUS"),
        # Milhar americano sem parte decimal: leitura única, corrige.
        ("1,234,567", "1234567", "MONEY_LOCALE"),
        ("12,34", "12.34", "MONEY_LOCALE"),
        ("1.234,56", "1234.56", "MONEY_LOCALE"),
        ("1234.56", "1234.56", None),
    ], obtido


def test_falha_representacional_devolve_o_valor_original(engine) -> None:
    """R07 da terceira revisão: injetar e detectar não prova **recuperar**.

    `MONEY_LOCALE` e `DATE_FORMAT_KNOWN` são declarados corrigíveis, e os
    formatadores do injetor descartavam informação: `12.3456` virava `12,34` —
    duas casas a menos —, e a forma de data pura descartava horário e fuso.
    Encontrar o código injetado provava que a detecção funciona; não provava que
    a limpeza devolve o valor que havia antes.

    O esperado aqui é **independente**: é o valor original, não o que o injetor
    produziu. É o que separa recuperar de reencontrar o próprio defeito.
    """
    from mvp_ed1.legacy import injetor

    class _SemFonte:
        pass

    fonte = _SemFonte()
    # Cada forma recebe os valores em que ela **é** uma falha. A americana
    # recusa o que não tem milhar, e a recusa é parte do contrato: ver `_en_us`.
    por_forma = {
        injetor._pt_br: ["12.3456", "1234.5", "12", "1999.99"],
        injetor._com_simbolo: ["12.3456", "1234.5", "12", "1999.99"],
        injetor._en_us: ["1234.5", "1999.99", "12345.6789"],
    }

    for forma, originais_moeda in por_forma.items():
        injetados = [forma(v, fonte) for v in originais_moeda]
        obtido = _sobre_a_linha(engine, "product_prices", "unit_price", injetados)
        for original, (entrada, limpo, achado) in zip(originais_moeda, obtido):
            assert achado == "MONEY_LOCALE", (forma.__name__, original, entrada, achado)
            assert float(limpo) == float(original), (forma.__name__, entrada, limpo)

    originais_data = ["1990-05-12", "2024-02-29", "2001-01-01"]
    for forma in (injetor._dd_mm_aaaa, injetor._aaaa_ponto_mm_dd):
        injetados = [forma(v, fonte) for v in originais_data]
        obtido = _sobre_a_linha(engine, "customers", "birth_date", injetados)
        for original, (entrada, limpo, achado) in zip(originais_data, obtido):
            assert achado == "DATE_FORMAT_KNOWN", (forma.__name__, entrada, achado)
            assert limpo == original, (forma.__name__, entrada, limpo)
