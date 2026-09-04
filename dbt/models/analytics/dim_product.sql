-- SKU — SCD tipo 2, com atributos descritivos de tipo 1 (padrão misto).
--
-- ── Por que misto, e não tipo 2 puro ─────────────────────────────────────────
-- O `dbt snapshot` com `strategy='check'` só cria versão quando uma das colunas
-- **declaradas** muda; as demais ficam congeladas com o valor da primeira
-- captura. Um produto renomeado depois da carga inicial manteria para sempre o
-- nome antigo na dimensão — descoberto quando a view P03 continuou mostrando o
-- nome anterior depois de o `raw` já ter o novo.
--
-- A resposta não é jogar tudo em `check_cols`: o ADR-0017 recusa isso, porque
-- qualquer correção de digitação viraria versão nova. A resposta é a clássica:
--
--   **tipo 2** — o que muda o significado da venda: categoria, marca, estado,
--                exclusão. É por eles que a versão existe.
--   **tipo 1** — o que apenas descreve: nome, tamanho, cor, código de barras.
--                Corrigir um nome corrige em toda a história, porque a venda de
--                2024 foi do mesmo produto, só escrito errado.
--
-- Os nomes de categoria seguem a categoria **da versão**, não a atual: se o
-- produto mudou de categoria, a venda antiga continua na categoria antiga.

with versoes as (

    select
        *,
        row_number() over (partition by product_variant_id order by dbt_valid_from)
            as numero_da_versao
    from {{ ref('scd_product') }}

),

atual as (

    -- Estado corrente do SKU em `trusted`. É daqui que vêm os atributos de
    -- tipo 1, e é o que faz a correção descritiva alcançar toda a história.
    select * from {{ ref('product_skus') }}

),

categorias as (

    -- Nomes por categoria, para resolver a categoria **da versão**. Uma
    -- categoria tem o mesmo nome em qualquer SKU, então o `distinct on` é
    -- estável.
    select distinct on (product_category_id)
        product_category_id,
        leaf_category_name,
        sub_category_name,
        root_category_name
    from atual
    order by product_category_id, product_variant_id

),

marcas as (

    select distinct on (brand_id) brand_id, brand_name, brand_country
    from atual where brand_id is not null
    order by brand_id, product_variant_id

)

select
    {{ dbt_utils.generate_surrogate_key(['v.product_variant_id', 'v.dbt_valid_from']) }} as product_key,
    v.product_variant_id                                    as product_natural_key,

    -- ── Tipo 1: descrevem o SKU, não o classificam ──────────────────────────
    a.sku,
    a.product_code,
    a.product_name,
    a.variant_size,
    a.variant_color,
    a.variant_package,
    a.barcode,
    a.weight_grams,
    a.product_id,
    a.launched_at,

    -- ── Tipo 2: mudam o significado da venda ────────────────────────────────
    v.product_status,
    v.variant_is_active,
    v.product_category_id,
    c.leaf_category_name,
    c.sub_category_name,
    c.root_category_name,
    v.brand_id,
    coalesce(m.brand_name, 'Sem marca')                     as brand_name,
    m.brand_country,
    v.is_deleted,
    v.variant_is_deleted,
    v.product_is_deleted,

    -- ── A vigência da primeira versão ───────────────────────────────────────
    -- O `dbt snapshot` marca `dbt_valid_from` no instante em que **rodou pela
    -- primeira vez**. Sem tratamento, toda venda anterior a essa execução fica
    -- sem versão à qual se juntar, e a fato sai vazia — que foi exatamente o
    -- que aconteceu na primeira construção deste modelo.
    --
    -- `period_start` em vez de `-infinity` por portabilidade: o BigQuery da
    -- Etapa 13 não tem infinito em `timestamp`.
    case
        when v.numero_da_versao = 1 then timestamptz '{{ var("period_start") }} 00:00-03'
        else v.dbt_valid_from
    end                                                     as valid_from,
    v.dbt_valid_to                                          as valid_to,
    v.dbt_valid_to is null                                  as is_current
from versoes v
join atual a on a.product_variant_id = v.product_variant_id
join categorias c on c.product_category_id = v.product_category_id
left join marcas m on m.brand_id = v.brand_id
