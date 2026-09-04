{#
    Histórico de atributos do SKU — SCD tipo 2 (ADR-0017).

    Recategorizar um produto ou trocar a marca muda como a venda de ontem se
    agrega. É exatamente para isso que a dimensão é tipo 2: o pedido de 2024
    continua contando na categoria que ele tinha em 2024.

    `is_deleted` entra nas colunas comparadas por causa do ADR-0029 — a exclusão
    é um atributo que muda, e a versão anterior continua existindo para a fato
    histórica se juntar a ela.
#}

{% snapshot scd_product %}

{{
    config(
        unique_key='product_variant_id',
        strategy='check',
        check_cols=[
            'product_category_id',
            'brand_id',
            'product_status',
            'variant_is_active',
            'is_deleted',
        ],
    )
}}

select * from {{ ref('product_skus') }}

{% endsnapshot %}
