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

#: Validade de calendário em **aritmética pura**, sem `to_date`.
#:
#: O `to_date` do PostgreSQL 16 estoura com `date/time field value out of range`
#: tanto para mês 13 quanto para 31 de fevereiro. Qualquer detecção que o chame
#: derruba a consulta inteira antes de a linha virar um registro rejeitado — e
#: como o `and` do PostgreSQL não garante curto-circuito, nem guardá-lo atrás de
#: uma condição resolve. Só não chamá-lo resolve.
def _valida(ano: str, mes: str, dia: str) -> str:
    """Data válida no calendário, em aritmética pura."""
    return (
        f"({mes}::int between 1 and 12 and {dia}::int between 1 and 31"
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
                "{v} !~ '^-?[0-9]+(\\.[0-9]{{1,4}})?$' and ("
                "   {v} ~ '^-?(R\\$)?\\s*[0-9]{{1,3}}(\\.[0-9]{{3}})*,[0-9]{{1,4}}$'"
                "   or {v} ~ '^-?(R\\$)?\\s*[0-9]+,[0-9]{{1,4}}$'"
                "   or {v} ~ '^-?(R\\$)?\\s*[0-9]{{1,3}}(,[0-9]{{3}})+(\\.[0-9]{{1,4}})?$'"
                "   or {v} ~ '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{{1,4}})?$')"
            ),
            # O separador decimal é o **último** que aparece, e só depois de o
            # formato inteiro ter sido reconhecido acima.
            conversao=(
                "case when btrim(replace(replace({v}, 'R$', ''), ' ', '')) ~ ',[0-9]{{1,4}}$'"
                " then replace(replace(replace(replace({v}, 'R$', ''), ' ', ''), '.', ''), ',', '.')"
                " else replace(replace(replace({v}, 'R$', ''), ' ', ''), ',', '') end"
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
                " when {v} ~ '^[0-9]{{4}}[-.][0-9]{{2}}[-.][0-9]{{2}}'"
                "   then not " + _valida("substring({v} from 1 for 4)",
                                         "substring({v} from 6 for 2)",
                                         "substring({v} from 9 for 2)") +
                " when {v} ~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$'"
                "   then not " + _valida("substring({v} from 7 for 4)",
                                         "substring({v} from 4 for 2)",
                                         "substring({v} from 1 for 2)") +
                " when {v} ~ '^[0-9]{{2}}/[0-9]{{4}}$' then true"
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
            deteccao=(
                "{v} ~ '^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}[ T][0-9]{{2}}:[0-9]{{2}}'"
                " and {v} !~ '(Z|[+-][0-9]{{2}}:?[0-9]{{2}})$'"
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
            deteccao=(
                "{v} !~ '^[0-9]{{4}}[-.][0-9]{{2}}[-.][0-9]{{2}}'"
                " and {v} !~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$'"
                " and {v} !~ '^[0-9]{{2}}/[0-9]{{4}}$'"
            ),
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
                "{v} ~ '(Ã[\u0083-\u00bf]|Â[\u0080-\u00bf])'"
                " and {v} !~ '(Ã|Â)[A-ZÁÂÃÉÊÍÓÔÕÚÇ ]'"
            ),
            conversao="convert_from(convert_to({v}, 'LATIN1'), 'UTF8')",
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
        # `ENUM_UNKNOWN`, que agora alcança colunas booleanas.
        Regra(
            "BOOL_VARIANT",
            deteccao=(
                "btrim({v}) not in ('true', 'false')"
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
