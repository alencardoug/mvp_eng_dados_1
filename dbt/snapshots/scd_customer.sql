{#
    Histórico de atributos do cliente — SCD tipo 2 (ADR-0017).

    `strategy='check'` com colunas **declaradas**, nunca `check_cols='all'`: com
    "all", qualquer alteração irrelevante — um `updated_at` que mexeu sozinho —
    vira versão nova, e a dimensão incha com linhas que não mudam nada do que se
    consulta.

    As colunas abaixo são as que mudam o significado do cliente numa análise:
    segmento, estado do relacionamento e geografia. Nome e documento não entram
    de propósito — correção de cadastro não é fato novo de negócio.
#}

{% snapshot scd_customer %}

{{
    config(
        unique_key='customer_id',
        strategy='check',
        check_cols=[
            'customer_segment_id',
            'customer_status',
            'city',
            'state_code',
            'is_deleted',
        ],
    )
}}

select * from {{ ref('customers') }}

{% endsnapshot %}
