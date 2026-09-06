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
        Regra(
            "MONEY_LOCALE",
            deteccao="{v} !~ '^-?[0-9]+(\\.[0-9]+)?$'",
            # `1.234,56` e `1,234.56`: o separador decimal é o **último** que
            # aparece. Trocar isso por regra fixa erraria metade dos casos.
            conversao=(
                "case when btrim(replace(replace({v}, 'R$', ''), ' ', '')) ~ ',[0-9]{{1,2}}$'"
                " then replace(replace(replace(replace({v}, 'R$', ''), ' ', ''), '.', ''), ',', '.')"
                " else replace(replace(replace({v}, 'R$', ''), ' ', ''), ',', '') end"
            ),
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
        Regra(
            "DATE_IMPOSSIBLE",
            deteccao=(
                "{v} !~ '^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}' and ("
                " {v} ~ '^[0-9]{{2}}/[0-9]{{4}}$'"
                " or ({v} ~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$' and ("
                "   substring({v} from 4 for 2)::int not between 1 and 12"
                "   or substring({v} from 1 for 2)::int not between 1 and 31"
                "   or (substring({v} from 4 for 2)::int in (4, 6, 9, 11)"
                "       and substring({v} from 1 for 2)::int > 30)"
                "   or (substring({v} from 4 for 2)::int = 2"
                "       and substring({v} from 1 for 2)::int > 29)"
                "   or (substring({v} from 4 for 2)::int = 2"
                "       and substring({v} from 1 for 2)::int = 29"
                "       and not (substring({v} from 7 for 4)::int % 4 = 0"
                "                and (substring({v} from 7 for 4)::int % 100 <> 0"
                "                     or substring({v} from 7 for 4)::int % 400 = 0))))))"
            ),
        ),
        Regra(
            "DATE_FORMAT_KNOWN",
            deteccao=(
                "{v} !~ '^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}' and ("
                " ({v} ~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$'"
                "  and substring({v} from 4 for 2)::int between 1 and 12"
                "  and substring({v} from 1 for 2)::int between 1 and 31)"
                " or {v} ~ '^[0-9]{{4}}\\.[0-9]{{2}}\\.[0-9]{{2}}$')"
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
                "{v} ~ '^[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}'"
                " and left({v}, 10)::date > date '{{{{ var(\"as_of_date\") }}}}'"
            ),
        ),

        # ── Texto ────────────────────────────────────────────────────────────
        Regra(
            "TEXT_DELIMITER",
            deteccao=f"{{v}} like '%{delim}%'",
        ),
        Regra(
            "TEXT_ENCODING",
            deteccao="{v} ~ '(Ã.|Â.)'",
            conversao="convert_from(convert_to({v}, 'LATIN1'), 'UTF8')",
        ),
        Regra(
            "TEXT_WHITESPACE_CASE",
            deteccao="{v} <> btrim({v}) or {v} ~ '  '",
            conversao="regexp_replace(btrim({v}), '\\s+', ' ', 'g')",
        ),

        # ── Domínios ─────────────────────────────────────────────────────────
        Regra(
            "BOOL_VARIANT",
            deteccao="lower(btrim({v})) not in ('true', 'false')",
            conversao=(
                "case when lower(btrim({v})) in ('sim', 's', '1', 'y', 'yes')"
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


def regra_enum(valores: tuple[str, ...]) -> Regra:
    """`ENUM_UNKNOWN` depende do domínio declarado da coluna.

    O domínio sai das `CHECK` dos modelos, como em toda a etapa: reescrevê-lo
    aqui criaria uma segunda lista, que divergiria na primeira enumeração nova.
    """
    return Regra("ENUM_UNKNOWN", deteccao=f"btrim({{v}}) not in ({_lista(valores)})")
