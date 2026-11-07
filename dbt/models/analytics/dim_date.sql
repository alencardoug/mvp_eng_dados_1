-- Calendário do período simulado — dimensão estática.
--
-- Gerada, não semeada: um CSV de 975 linhas seria dado derivado versionado à
-- mão, e mudaria de tamanho toda vez que `period_start` ou `as_of_date`
-- mudassem. A série sai das mesmas variáveis que o gerador usa.
--
-- A chave é *hash*, como em toda dimensão do projeto (ADR-0017). `yyyymmdd`
-- seria igualmente determinístico e mais legível, mas abrir exceção em uma
-- dimensão obriga quem lê o datamart a saber qual é a exceção — uniformidade
-- vale mais que legibilidade da chave, que ninguém lê de qualquer forma.

with dias as (

    -- O calendário vai **além** do fim dos fatos, de propósito: o caminho
    -- quente da Etapa 7 grava evento com o relógio real, e uma dimensão de data
    -- que parasse em `as_of_date` faria o `join` da fato descartá-lo sem dizer.
    {{ serie_de_datas(var("period_start"), var("as_of_date"), var("calendar_horizon_days")) }}

)

select
    {{ dbt_utils.generate_surrogate_key(['full_date']) }}   as date_key,
    full_date,
    cast(extract(year from full_date) as int)               as year_number,
    cast(extract(quarter from full_date) as int)            as quarter_number,
    cast(extract(month from full_date) as int)              as month_number,
    {{ parte_da_data('month_name', 'full_date') }}          as month_name,
    {{ parte_da_data('year_month', 'full_date') }}          as year_month,
    cast(extract(day from full_date) as int)                as day_of_month,
    cast({{ parte_da_data('isodow', 'full_date') }} as int) as day_of_week,
    {{ parte_da_data('day_name', 'full_date') }}            as day_name,
    cast({{ parte_da_data('isoweek', 'full_date') }} as int) as iso_week_number,
    {{ parte_da_data('month', 'full_date') }}               as month_start_date,
    {{ parte_da_data('quarter', 'full_date') }}             as quarter_start_date,
    {{ parte_da_data('year', 'full_date') }}                as year_start_date,
    {{ parte_da_data('isodow', 'full_date') }} >= 6         as is_weekend
from dias
