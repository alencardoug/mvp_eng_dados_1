-- Conjunto apto da captura selecionada, antes do empilhamento por domínio.
-- Não lê quarantine: aptos e rejeitados partem da mesma classificação.
select * from {{ ref('legacy_classifications') }}
where classification in ('accepted', 'corrected')
