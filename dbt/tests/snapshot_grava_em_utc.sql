-- A sessão do dbt está em UTC — a premissa das vigências das dimensões SCD.
--
-- O `dbt snapshot` grava `dbt_valid_from`/`dbt_valid_to` como `timestamp` **sem
-- fuso**, no fuso da sessão; as dimensões os leem como instante UTC
-- (`at time zone 'UTC'`). Se a sessão mudar de fuso, as versões novas passariam a
-- ser lidas deslocadas, sem erro nenhum. Este teste falha antes disso.

select current_setting('TimeZone') as fuso_da_sessao
where current_setting('TimeZone') not in ('UTC', 'Etc/UTC')
