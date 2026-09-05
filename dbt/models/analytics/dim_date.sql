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
    select generate_series(
        date '{{ var("period_start") }}',
        date '{{ var("as_of_date") }}' + interval '{{ var("calendar_horizon_days") }} days',
        interval '1 day'
    )::date as full_date

)

select
    {{ dbt_utils.generate_surrogate_key(['full_date']) }}   as date_key,
    full_date,
    extract(year from full_date)::int                       as year_number,
    extract(quarter from full_date)::int                    as quarter_number,
    extract(month from full_date)::int                      as month_number,
    to_char(full_date, 'TMMonth')                           as month_name,
    to_char(full_date, 'YYYY-MM')                           as year_month,
    extract(day from full_date)::int                        as day_of_month,
    extract(isodow from full_date)::int                     as day_of_week,
    to_char(full_date, 'TMDay')                             as day_name,
    extract(week from full_date)::int                       as iso_week_number,
    date_trunc('month', full_date)::date                    as month_start_date,
    date_trunc('quarter', full_date)::date                  as quarter_start_date,
    date_trunc('year', full_date)::date                     as year_start_date,
    extract(isodow from full_date) >= 6                     as is_weekend
from dias
