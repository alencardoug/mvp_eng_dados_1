"""SQL de detecção e de conversão, uma expressão por código do catálogo.

Este módulo é a ponte entre a declaração e o dbt. O catálogo diz **o que** cada
falha é; aqui está como se reconhece e como se converte, em SQL — e é daqui que
os modelos de limpeza são gerados (ADR-0022).

Duas coisas que a forma esconde e vale dizer:

* a **ordem** entre os códigos de um mesmo arquétipo é precedência de detecção,
  não preferência. `NULL_DISGUISED` vem antes de tudo porque um `N/A` num campo
  de data não é data em formato desconhecido: é nulo escrito errado;
* cada expressão recebe o valor **como texto**, porque é assim que ele está em
  `raw_legacy`. Converter antes de detectar inverteria o problema — o `cast`
  falharia justamente nas linhas que interessam.
"""

from __future__ import annotations

from dataclasses import dataclass

#: Fuso declarado da origem legada, aplicado quando o timestamp não traz o seu.
FUSO = "America/Sao_Paulo"

#: As formas **completas** de tempo que a origem antiga usa. A lista é fechada,
#: e é a string inteira que precisa casar: reconhecer por prefixo deixava
#: `2024-01-01 lixo` sem achado nenhum — data válida nos dez primeiros
#: caracteres, sujeira no resto, e o registro saía **aceito** com o texto
#: intacto para estourar no `cast` da ponte, três camadas adiante.
FORMA_ISO = "^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}$"
FORMA_PONTO = "^[0-9]{{4}}\\.[0-9]{{2}}\\.[0-9]{{2}}$"
FORMA_BR = "^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$"
FORMA_PARCIAL = "^[0-9]{{2}}/[0-9]{{4}}$"
#: O sufixo de fuso, escrito uma vez porque três regras o consultam.
#:
#: Os minutos são **opcionais** e isso foi o R02: `at time zone` devolve
#: `2024-01-01 15:30:00+00`, com duas casas de deslocamento, e a forma que
#: exigia quatro rejeitava o resultado da própria conversão — o valor saía
#: convertido e recebia `DATE_UNPARSEABLE` em seguida.
OFFSET = "(Z|[+-][0-9]{{2}}(:?[0-9]{{2}})?)"

FORMA_MOMENTO = (
    "^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}[ T][0-9]{{2}}:[0-9]{{2}}"
    "(:[0-9]{{2}}(\\.[0-9]+)?)?" + OFFSET + "?$"
)
FORMAS = (FORMA_ISO, FORMA_PONTO, FORMA_BR, FORMA_PARCIAL, FORMA_MOMENTO)


def _alguma_forma(valor: str = "{v}") -> str:
    """O valor tem alguma das formas declaradas, inteiro."""
    return "(" + " or ".join(f"{valor} ~ '{forma}'" for forma in FORMAS) + ")"


#: Os formatos monetários aceitos, **separados pela interpretação** que cada um
#: exige. A separação não é estética: é o que a conversão consulta para saber
#: qual separador é o decimal.
#:
#: Decidir isso pela cauda da string — "termina em vírgula e até quatro
#: dígitos" — foi o R04. `1,234,567` é milhar americano sem parte decimal,
#: termina exatamente assim, e virava `1.234.567`: não é `numeric`, e entrava
#: marcado como corrigido.
MOEDA_BR = (
    "^-?(R\\$)?\\s*[0-9]{{1,3}}(\\.[0-9]{{3}})*,[0-9]{{1,4}}$",
    "^-?(R\\$)?\\s*[0-9]+,[0-9]{{1,4}}$",
)
MOEDA_US = (
    "^-?(R\\$)?\\s*[0-9]{{1,3}}(,[0-9]{{3}})+(\\.[0-9]{{1,4}})?$",
    "^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{{1,4}})?$",
)

#: Decimal já pronto: nada a normalizar, e é também o que `MONEY_AMBIGUOUS`
#: exige do **resultado** da conversão.
MOEDA_DECIMAL_PURO = "^-?[0-9]+(\\.[0-9]{{1,4}})?$"

#: A célula **inteira** sobrevive à ida e volta `LATIN1 → UTF8`.
#:
#: Este é o R03. Detectar um par de mojibake autorizava recodificar a célula
#: toda, e a conversão derrubava a consulta em dois casos medidos:
#:
#: * um acento legítimo junto — `CafÃ© café`: o `é` vira o byte `0xE9`, que
#:   sozinho não é UTF-8 válido, e `convert_from` estoura com 22021;
#: * um emoji junto: não cabe em Latin-1, e `convert_to` estoura com 22P05.
#:
#: A condição é escrita como gramática do UTF-8 sobre code points de Latin-1 —
#: cada caractere de U+0000 a U+00FF é exatamente um byte de mesmo valor, então
#: casar a string é casar a sequência de bytes que `convert_to` produziria.
#: Qualquer caractere acima de U+00FF fica fora das classes e reprova a string,
#: que é o que se quer: ele não teria byte em Latin-1.
#:
#: Os ramos de três e quatro bytes são **subdivididos**, e foi o resto do R03:
#: aceitar qualquer continuação depois de um primeiro byte na faixa admite três
#: famílias de sequência que o UTF-8 proíbe e que o `convert_from` recusa com
#: 22021 — codificação excessivamente longa (`E0 80 80`, `F0 80 80 80`),
#: substitutos UTF-16 (`ED A0 80`) e pontos acima de U+10FFFF (`F4 90 80 80`).
#: Todas as três foram reproduzidas contra o conversor real antes desta divisão.
#:
#: A forma abaixo é a gramática da RFC 3629, escrita sobre code points de
#: Latin-1: `E0` exige continuação `A0-BF`, `ED` exige `80-9F`, `F0` exige
#: `90-BF` e `F4` exige `80-8F`.
#:
#: Foi conferido contra o `convert_from(convert_to(...))` real: o predicado é
#: verdadeiro exatamente nos valores em que a conversão não aborta.
LATIN1_REVERSIVEL = (
    "^([\\u0001-\\u007f]"
    "|[\\u00c2-\\u00df][\\u0080-\\u00bf]"
    "|\\u00e0[\\u00a0-\\u00bf][\\u0080-\\u00bf]"
    "|[\\u00e1-\\u00ec][\\u0080-\\u00bf]{{2}}"
    "|\\u00ed[\\u0080-\\u009f][\\u0080-\\u00bf]"
    "|[\\u00ee-\\u00ef][\\u0080-\\u00bf]{{2}}"
    "|\\u00f0[\\u0090-\\u00bf][\\u0080-\\u00bf]{{2}}"
    "|[\\u00f1-\\u00f3][\\u0080-\\u00bf]{{3}}"
    "|\\u00f4[\\u0080-\\u008f][\\u0080-\\u00bf]{{2}})*$"
)

#: Os pares que a dupla codificação UTF-8→Latin-1 produz de fato. É o indício
#: **positivo** de mojibake; sozinho ele não autoriza converter nada.
MOJIBAKE = "(Ã[\u0083-\u00bf]|Â[\u0080-\u00bf])"

#: Domínio canônico de uma coluna booleana, escrito uma vez.
#:
#: É o que `BOOL_VARIANT` produz e o que `ENUM_UNKNOWN` cobra do resultado —
#: sem ele, `talvez` num campo booleano ficava sem achado nenhum (R05).
DOMINIO_BOOLEANO = ("true", "false")


def _casa(formas: tuple[str, ...], valor: str = "{v}") -> str:
    """O valor tem alguma destas formas."""
    return " or ".join(f"{valor} ~ '{forma}'" for forma in formas)


def _sem_milhar(*separadores: str, valor: str = "{v}") -> str:
    """Tira moeda, espaço e os separadores de milhar informados.

    Quando dois separadores são passados, o **último** é o decimal e vira
    ponto; com um só, não há parte decimal a converter.
    """
    limpo = f"replace(replace({valor}, 'R$', ''), ' ', '')"
    milhar, *decimal = separadores
    limpo = f"replace({limpo}, {milhar}, '')"
    if decimal:
        limpo = f"replace({limpo}, {decimal[0]}, '.')"
    return limpo


#: Componentes de um momento, extraídos **por padrão** e não por posição.
#:
#: Foi o R02. `substring(v from 18 for 2)` devolve **string vazia** — não nulo —
#: quando os segundos não vêm, e `coalesce` não trata vazio: `2024-01-01 12:30`
#: abortava a consulta com 22P02, `invalid input syntax for type integer: ""`.
#: Pior que isso, num valor sem segundos mas com fuso a mesma posição lia os
#: dígitos do deslocamento **como se fossem segundos**.
#:
#: `substring(v from 'padrão')` devolve nulo quando o componente não existe, que
#: é o que o `coalesce` espera. Cada padrão tem exatamente um grupo, porque o
#: PostgreSQL devolve o primeiro parêntese quando há algum.
PARTE_HORA = "[ T]([0-9]{{2}}):[0-9]{{2}}"
PARTE_MINUTO = "[ T][0-9]{{2}}:([0-9]{{2}})"
PARTE_SEGUNDO = "[ T][0-9]{{2}}:[0-9]{{2}}:([0-9]{{2}})"
PARTE_OFFSET_HORA = "[+-]([0-9]{{2}})(:?[0-9]{{2}})?$"
PARTE_OFFSET_MINUTO = "[+-][0-9]{{2}}:?([0-9]{{2}})$"


def _parte(padrao: str, valor: str = "{v}") -> str:
    """Um componente do momento, ou nulo se ele não estiver lá."""
    return f"substring({valor} from '{padrao}')"


def _leitura_br(valor: str = "{v}") -> str:
    """O valor lido como brasileiro: ponto é milhar, vírgula é decimal."""
    return _sem_milhar("'.'", "','", valor=valor)


def _leitura_us(valor: str = "{v}") -> str:
    """O valor lido como americano: vírgula é milhar, ponto já é decimal."""
    return _sem_milhar("','", valor=valor)


def _moeda_ambigua(valor: str = "{v}") -> str:
    """O valor cabe nos dois formatos **e** eles discordam do número.

    Foi o resto do R04. `1,234` casa com o decimal brasileiro (`1,234` = um
    inteiro e 234 milésimos) e com o milhar americano (`1,234` = mil duzentos e
    trinta e quatro). O `case` escolhia o primeiro ramo e entregava `1.234`
    marcado como **corrigido** — uma das duas leituras, sem dizer que havia
    outra. A Origem Legada §3.1 manda o contrário: reparar quando o par é
    conhecido, rejeitar quando é ambíguo.

    A ambiguidade é **medida**, não deduzida do formato: as duas leituras são
    convertidas e comparadas. Se um padrão mudar amanhã, a comparação continua
    respondendo certo.
    """
    return (
        f"(({_casa(MOEDA_BR, valor=valor)})"
        f" and ({_casa(MOEDA_US, valor=valor)})"
        f" and {_leitura_br(valor)} is distinct from {_leitura_us(valor)})"
    )


def _hora_valida(hora: str, minuto: str, segundo: str) -> str:
    """Relógio possível, em aritmética pura.

    `99:00` passava: nenhuma regra olhava o relógio, `DATE_TZ_MISSING` casava
    pelo padrão e a conversão chamava `::timestamp`, que **aborta a consulta
    inteira** — não a linha, a consulta. Um valor derrubava o modelo.
    """
    return (
        f"({hora}::int between 0 and 23 and {minuto}::int between 0 and 59"
        f" and coalesce({segundo}, '00')::int between 0 and 59)"
    )


def _offset_valido(hora: str, minuto: str) -> str:
    """Deslocamento de fuso possível.

    `2024-01-01T12:30:00+99:99` casava a forma, não recebia achado nenhum e
    abortava adiante no `cast` para `timestamptz` com 22009, `time zone
    displacement out of range`. O PostgreSQL aceita até 15:59; acima disso não é
    dado ruim, é consulta derrubada.

    Ausência de deslocamento é deslocamento zero para efeito desta conta: quem
    trata o momento sem fuso é `DATE_TZ_MISSING`, não esta função.
    """
    return (
        f"(coalesce({hora}, '00')::int between 0 and 15"
        f" and coalesce({minuto}, '00')::int between 0 and 59)"
    )


def _valida(ano: str, mes: str, dia: str) -> str:
    """Data válida no calendário, em **aritmética pura**, sem `to_date`.

    O `to_date` do PostgreSQL 16 estoura com `date/time field value out of
    range` tanto para mês 13 quanto para 31 de fevereiro. Qualquer detecção que
    o chame derruba a consulta inteira antes de a linha virar um registro
    rejeitado — e como o `and` do PostgreSQL não garante curto-circuito, nem
    guardá-lo atrás de uma condição resolve. Só não chamá-lo resolve.

    O ano entra na conta porque o Postgres não tem ano zero: `0000-01-01`
    passava por mês e dia válidos e estourava no `cast` seguinte.
    """
    return (
        f"({ano}::int between 1 and 9999"
        f" and {mes}::int between 1 and 12 and {dia}::int between 1 and 31"
        f" and not ({mes}::int in (4, 6, 9, 11) and {dia}::int > 30)"
        f" and not ({mes}::int = 2 and {dia}::int > 29)"
        f" and not ({mes}::int = 2 and {dia}::int = 29"
        f" and not ({ano}::int % 4 = 0"
        f" and ({ano}::int % 100 <> 0 or {ano}::int % 400 = 0))))"
    )


@dataclass(frozen=True)
class Regra:
    """Como um código é reconhecido e, quando dá, corrigido.

    `deteccao` e `conversao` são moldes com `{v}` no lugar do valor textual.
    `conversao` é `None` quando o catálogo manda rejeitar: não há o que pôr no
    lugar, e inventar um valor seria a adivinhação que a Origem Legada proíbe.
    """

    codigo: str
    deteccao: str
    conversao: str | None = None
    #: A detecção olha **outras colunas** da mesma linha, e não só `{v}`.
    #:
    #: Só `TEXT_DELIMITER` faz isso: o deslocamento de uma linha importada só é
    #: observável se os campos seguintes estiverem vazios. A consequência é que
    #: a expressão dela **não** é avaliável sobre um valor isolado — quem testa
    #: regra a regra precisa saber disso em vez de descobrir com um
    #: `UndefinedColumn`.
    precisa_da_linha: bool = False


def _lista(valores: tuple[str, ...]) -> str:
    return ", ".join("'" + v.replace("'", "''") + "'" for v in valores)


def regras(nulos: tuple[str, ...], delimitador: str) -> dict[str, Regra]:
    """As 21 regras injetáveis, prontas para virar SQL."""
    nulos_sql = _lista(nulos)
    delim = delimitador.replace("'", "''")

    return {r.codigo: r for r in (
        # ── Vale para qualquer arquétipo, e vem antes de todos ───────────────
        # `btrim({v}) = ''` cobre a string vazia **e** a que só tem espaços, e
        # precisa estar aqui explicitamente: a lista de marcadores deixou de
        # conter a string vazia quando se mediu que ela não sobrevive ao
        # transporte, e com isso `'   '` deixou de casar por tabela.
        Regra(
            "NULL_DISGUISED",
            deteccao=f"btrim({{v}}) = '' or btrim({{v}}) in ({nulos_sql})",
            conversao="null",
        ),

        # ── Numéricos ────────────────────────────────────────────────────────
        Regra(
            "NUM_TEXT_EQUIV",
            deteccao=(
                "{v} !~ '^-?[0-9]+$' and ("
                "  lower(btrim({v})) in ('um','dois','três','tres','quatro','cinco',"
                "'seis','sete','oito','nove','dez')"
                "  or replace(btrim({v}), ',', '.') ~ '^-?[0-9]+\\.0+$')"
            ),
            conversao=(
                "case lower(btrim({v}))"
                " when 'um' then '1' when 'dois' then '2'"
                " when 'três' then '3' when 'tres' then '3'"
                " when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6'"
                " when 'sete' then '7' when 'oito' then '8' when 'nove' then '9'"
                " when 'dez' then '10'"
                " else split_part(replace(btrim({v}), ',', '.'), '.', 1) end"
            ),
        ),
        # A faixa impossível depende do que a coluna **significa**, e por isso
        # esta regra é parametrizada: `quantity_delta` é assinado por natureza —
        # saída de estoque é negativa —, e tratar o sinal como defeito
        # condenaria 388 movimentos corretos. Foi medido antes de a exceção
        # existir.
        Regra(
            "NUM_OUT_OF_RANGE",
            deteccao="{v} ~ '^-?[0-9]+$' and ({v}::numeric < 0 or {v}::numeric > 1000000)",
        ),
        Regra(
            "NUM_AMBIGUOUS",
            deteccao="{v} !~ '^-?[0-9]+$'",
        ),

        # ── Monetários ───────────────────────────────────────────────────────
        Regra(
            "MONEY_NEGATIVE",
            deteccao="btrim(replace(replace({v}, 'R$', ''), ' ', '')) ~ '^-'",
        ),
        # A detecção **enumera os formatos aceitos** em vez de aceitar tudo que
        # não seja decimal puro. A primeira versão fazia o contrário, e o
        # resultado era grave: `12,3456` virava `123456` — mil vezes o valor —
        # porque o separador decimal só era reconhecido com uma ou duas casas,
        # e `abc` saía "corrigido" sem nunca ter sido convertido.
        #
        # A escala vai a **quatro casas** porque é o que os modelos declaram:
        # `Numeric(14, 4)` em preço unitário. Reconhecer só duas truncaria dado
        # legítimo.
        Regra(
            "MONEY_LOCALE",
            deteccao=(
                "{v} !~ '" + MOEDA_DECIMAL_PURO + "'"
                " and (" + _casa(MOEDA_BR + MOEDA_US) + ")"
                # Sem leitura única não há correção: cai para `MONEY_AMBIGUOUS`,
                # que é a regra seguinte na precedência e rejeita.
                " and not " + _moeda_ambigua()
            ),
            # Quem decide o separador decimal é o **formato reconhecido**, e
            # não a cauda da string. Era o R04: `1,234,567` — milhar americano
            # sem parte decimal — termina em vírgula seguida de três dígitos, e
            # a regra antiga o lia como brasileiro. Virava `1.234.567`, que não
            # é `numeric`, e entrava marcado como corrigido.
            conversao=(
                "case when " + _casa(MOEDA_BR) +
                " then " + _leitura_br() +
                " else " + _leitura_us() + " end"
            ),
        ),
        # O que não casou com nenhum formato não é convertível. Sem esta regra,
        # ele saía aceito com o valor original — que é pior que rejeitar.
        Regra(
            "MONEY_AMBIGUOUS",
            deteccao="{v} !~ '^-?[0-9]+(\\.[0-9]{{1,4}})?$'",
        ),

        # ── Datas e tempo ────────────────────────────────────────────────────
        # **Nenhuma chamada a `to_date` na detecção**, e a razão custou uma
        # transação abortada para ser descoberta: no PostgreSQL 16 ele estoura
        # com `date/time field value out of range` tanto para mês 13 quanto
        # para 31 de fevereiro. A ideia de detectar pela ida e volta — converter
        # e comparar — não sobrevive a isso: a consulta inteira cai antes de a
        # linha virar um registro rejeitado.
        #
        # A validade é aritmética, e por isso não estoura nunca. É mais verbosa
        # e é a única forma correta aqui.
        # Duas formas de data impossível, e as duas precisam ser conferidas
        # **sem** chamar `to_date`: em ISO e ponto (`2024-02-31`, `2024.02.31`),
        # e em barra (`31/13/2026`). A primeira escapava desta regra e estourava
        # no cast seguinte; a segunda já era tratada.
        Regra(
            "DATE_IMPOSSIBLE",
            deteccao=(
                "case"
                # Momento: além do calendário, o relógio. `99:00` casava o
                # padrão de `DATE_TZ_MISSING` e abortava no `::timestamp`.
                " when {v} ~ '" + FORMA_MOMENTO + "'"
                "   then not (" + _valida("substring({v} from 1 for 4)",
                                          "substring({v} from 6 for 2)",
                                          "substring({v} from 9 for 2)") +
                " and " + _hora_valida(_parte(PARTE_HORA),
                                       _parte(PARTE_MINUTO),
                                       _parte(PARTE_SEGUNDO)) +
                # O deslocamento entra aqui e não numa regra própria: `+99:99`
                # não é uma data que precise de conserto, é uma data impossível.
                " and " + _offset_valido(_parte(PARTE_OFFSET_HORA),
                                         _parte(PARTE_OFFSET_MINUTO)) + ")"
                " when {v} ~ '^[0-9]{{4}}[-.][0-9]{{2}}[-.][0-9]{{2}}$'"
                "   then not " + _valida("substring({v} from 1 for 4)",
                                         "substring({v} from 6 for 2)",
                                         "substring({v} from 9 for 2)") +
                " when {v} ~ '" + FORMA_BR + "'"
                "   then not " + _valida("substring({v} from 7 for 4)",
                                         "substring({v} from 4 for 2)",
                                         "substring({v} from 1 for 2)") +
                " when {v} ~ '" + FORMA_PARCIAL + "' then true"
                " else false end"
            ),
        ),
        # A validade é conferida **antes** de o `to_date` da conversão ser
        # alcançado: `2024.02.31` casava com o formato e estourava no cast.
        Regra(
            "DATE_FORMAT_KNOWN",
            deteccao=(
                "case"
                " when {v} ~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$'"
                "   then " + _valida("substring({v} from 7 for 4)",
                                     "substring({v} from 4 for 2)",
                                     "substring({v} from 1 for 2)") +
                " when {v} ~ '^[0-9]{{4}}\\.[0-9]{{2}}\\.[0-9]{{2}}$'"
                "   then " + _valida("substring({v} from 1 for 4)",
                                     "substring({v} from 6 for 2)",
                                     "substring({v} from 9 for 2)") +
                " else false end"
            ),
            conversao=(
                "case when {v} ~ '^[0-9]{{2}}/'"
                " then to_date({v}, 'DD/MM/YYYY')::text"
                " else to_date({v}, 'YYYY.MM.DD')::text end"
            ),
        ),
        Regra(
            "DATE_TZ_MISSING",
            # Só age sobre momento **completo e possível**: a conversão chama
            # `::timestamp`, que aborta a consulta inteira num relógio inválido.
            deteccao=(
                "{v} ~ '" + FORMA_MOMENTO + "'"
                " and {v} !~ '" + OFFSET + "$'"
                " and " + _hora_valida(_parte(PARTE_HORA),
                                       _parte(PARTE_MINUTO),
                                       _parte(PARTE_SEGUNDO))
            ),
            conversao=f"({{v}}::timestamp at time zone '{FUSO}')::text",
        ),
        Regra(
            "DATE_FUTURE",
            deteccao=(
                "case when {v} ~ '^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}' and "
                + _valida("substring({v} from 1 for 4)", "substring({v} from 6 for 2)", "substring({v} from 9 for 2)")
                + " then left({v}, 10)::date > date '{{{{ var(\"as_of_date\") }}}}'"
                " else false end"
            ),
        ),
        # O que não é nenhum formato reconhecido não é data. Sem esta regra,
        # `sem data` num campo de tempo saía **aceito**, com o texto intacto.
        Regra(
            "DATE_UNPARSEABLE",
            # A string **inteira** precisa ter uma das formas declaradas. A
            # versão anterior olhava só o começo, e `2024-01-01 lixo` — dez
            # caracteres de data seguidos de sujeira — não recebia achado
            # nenhum: saía aceito, com o texto intacto, para estourar no `cast`
            # da ponte três camadas adiante.
            deteccao="not " + _alguma_forma(),
        ),

        # ── Texto ────────────────────────────────────────────────────────────
        Regra(
            "TEXT_DELIMITER",
            deteccao=f"{{v}} like '%{delim}%'",
        ),
        # A detecção era `~ '(Ã.|Â.)'` — qualquer `Ã` ou `Â` seguido de
        # qualquer coisa. `CÂMERA` casava, e a conversão **derrubava a view**
        # com `invalid byte sequence` (22021), porque o par não era reversível.
        #
        # Agora a lista é dos pares que a dupla codificação UTF-8→Latin-1 produz
        # de fato. `Â` seguido de letra maiúscula não está nela, e `CÂMERA`
        # passa intacto. O risco residual é o oposto e é aceito: mojibake com
        # um par fora da lista deixa de ser reconhecido — falha por omissão, não
        # por corrupção.
        Regra(
            "TEXT_ENCODING",
            deteccao=(
                "{v} ~ '" + MOJIBAKE + "'"
                " and {v} ~ '" + LATIN1_REVERSIVEL + "'"
            ),
            conversao="convert_from(convert_to({v}, 'LATIN1'), 'UTF8')",
        ),
        # O outro lado do R03, e a §3.1 já o mandava: "reparar quando o par
        # de codificações é conhecido; **rejeitar se ambíguo**". A célula com
        # mojibake que não se reverte por inteiro não é reparável — e tampouco
        # pode sair aceita com o texto corrompido intacto, que era o que
        # acontecia enquanto só existia a metade conversível.
        Regra(
            "TEXT_ENCODING_AMBIGUOUS",
            deteccao=(
                "{v} ~ '" + MOJIBAKE + "'"
                " and {v} !~ '" + LATIN1_REVERSIVEL + "'"
            ),
        ),
        Regra(
            "TEXT_WHITESPACE_CASE",
            deteccao="{v} <> btrim({v}) or {v} ~ '  '",
            conversao="regexp_replace(btrim({v}), '\\s+', ' ', 'g')",
        ),

        # ── Domínios ─────────────────────────────────────────────────────────
        # Duas correções numa. A detecção era `lower(...) not in (true,false)`,
        # e por isso `TRUE` passava sem ser canonizado — enquanto o índice
        # parcial de `customer_addresses` exige o texto `true`, e dois endereços
        # primários conflitantes eram aceitos. Agora a comparação é sensível a
        # caixa, e `TRUE` é convertido.
        #
        # E a conversão tinha um `else 'false'` que **inventava** valor:
        # `talvez` virava falso. O catálogo manda mapear *somente as variantes
        # declaradas*; o que não é variante declarada não é booleano escrito de
        # outro jeito — é valor fora do domínio, e quem o trata é o
        # `ENUM_UNKNOWN` — que só passou a alcançar colunas booleanas no R05,
        # apesar de este comentário já prometê-lo. Enquanto não alcançava,
        # `talvez` num campo booleano saía **aceito**, com o texto intacto.
        #
        # A comparação é com `{v}` cru, não com `btrim({v})`: era a segunda
        # metade do R05. ` true ` tem a forma canônica depois de aparado, mas o
        # que chega à ponte é o texto guardado, e o índice parcial de
        # `customer_addresses` compara com o literal `true`. Aparar antes de
        # comparar declarava canônico o que não era, e a canonização não
        # acontecia.
        Regra(
            "BOOL_VARIANT",
            deteccao=(
                f"{{v}} not in ({_lista(DOMINIO_BOOLEANO)})"
                " and lower(btrim({v})) in"
                " ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')"
            ),
            conversao=(
                "case when lower(btrim({v})) in ('true', 'sim', 's', '1', 'y', 'yes')"
                " then 'true' else 'false' end"
            ),
        ),
        Regra(
            "EMAIL_MALFORMED",
            deteccao="{v} !~ '^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$'",
        ),
    )}


def regra_truncado(limite: int) -> Regra:
    """`TEXT_TRUNCATED` depende do limite declarado da coluna.

    A heurística é assumida: um valor legítimo de comprimento exatamente igual
    ao limite é indistinguível de um cortado. O gerador produz de propósito
    valores nesse comprimento, e o controle **mede** o falso positivo em vez de
    fingir que ele não existe.
    """
    return Regra("TEXT_TRUNCATED", deteccao=f"length({{v}}) = {limite}")


def regra_faixa(permite_negativo: bool) -> Regra:
    """`NUM_OUT_OF_RANGE` para coluna assinada: só o teto é impossível."""
    if permite_negativo:
        return Regra("NUM_OUT_OF_RANGE", deteccao="{v} ~ '^-?[0-9]+$' and abs({v}::numeric) > 1000000")
    return Regra(
        "NUM_OUT_OF_RANGE",
        deteccao="{v} ~ '^-?[0-9]+$' and ({v}::numeric < 0 or {v}::numeric > 1000000)",
    )


def regra_delimitador(
    delimitador: str, seguintes: tuple[str, ...], alias: str = "c"
) -> Regra:
    """`TEXT_DELIMITER` precisa olhar os **vizinhos**, e não só o campo.

    A primeira versão testava apenas `like '%;%'`, e com isso rejeitava qualquer
    texto livre que contivesse um ponto e vírgula — ainda que a linha nunca
    tivesse sido deslocada. Era metade da condição declarada no catálogo.

    O efeito observável do deslocamento é o campo carregar o resto da linha **e**
    os seguintes ficarem vazios. Sem os vizinhos vazios, o delimitador é só
    pontuação.
    """
    delim = delimitador.replace("'", "''")
    if not seguintes:
        # Última coluna da tabela: não há vizinho para esvaziar, então o
        # deslocamento não é observável e a falha não se aplica.
        return Regra("TEXT_DELIMITER", deteccao="false")
    vazios = " and ".join(
        f'({alias}."{coluna}" is null or btrim({alias}."{coluna}") = \'\')'
        for coluna in seguintes
    )
    return Regra(
        "TEXT_DELIMITER",
        deteccao=f"{{v}} like '%{delim}%' and {vazios}",
        precisa_da_linha=True,
    )


def regra_enum(valores: tuple[str, ...]) -> Regra:
    """`ENUM_UNKNOWN` depende do domínio declarado da coluna.

    O domínio sai das `CHECK` dos modelos, como em toda a etapa: reescrevê-lo
    aqui criaria uma segunda lista, que divergiria na primeira enumeração nova.
    """
    return Regra("ENUM_UNKNOWN", deteccao=f"btrim({{v}}) not in ({_lista(valores)})")
