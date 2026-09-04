# Dicionário de Dados e Catálogo

> **O que vive aqui:** o **registro** — os objetos que existem, o significado e a classificação de
> cada campo, e a linhagem entre camadas.
>
> **O que não vive aqui:** as **regras** de classificação, acesso e retenção (ver
> [Política de Governança de Dados](governanca_de_dados.md)); o inventário de tabelas e o seu
> propósito (ver [Modelo de Dados](modelo_de_dados.md)); os conceitos de negócio (ver
> [Glossário de Negócio](glossario_de_negocio/)).

| Campo | Informação |
|---|---|
| Fonte de verdade | Arquivos `.yml` do projeto dbt |
| Este documento | Índice navegável e registro do que ainda não está no dbt |
| Como é gerado | `make catalog`, a partir dos modelos SQLAlchemy |
| Versão | 2.0 |
| Situação | Schema `oltp` preenchido; camadas do armazém a partir da Etapa 5 |
| Última revisão | 04/09/2026 |

---

## 1. Como este catálogo é mantido

A descrição campo a campo **não é digitada aqui**. Ela vive nos arquivos `.yml` do dbt, junto do
modelo que descreve, conforme o [padrão de metadados](governanca_de_dados.md#51-padrão-de-metadados).
Manter a descrição ao lado do código é o que impede que catálogo e realidade divirjam.

Este documento cumpre três papéis que o dbt não cobre:

1. **Índice** dos objetos por camada, para leitura sem executar nada;
2. **Registro** da camada transacional, que não é modelada pelo dbt;
3. **Rastro de decisões** de classificação que precisam de justificativa em texto.

### 1.1 Regra de atualização

Toda etapa que cria ou altera um objeto de dados atualiza este catálogo **na mesma entrega**.
Objeto sem descrição ou campo sem classificação bloqueia a conclusão da etapa — é o mecanismo que
sustenta o princípio **P3** e trata o risco **R4**.

### 1.2 Como consultar o catálogo completo

```bash
make dbt-docs      # gera e serve o site com dicionário, linhagem e glossário integrados
```

---

## 2. Catálogo de objetos e campos

<!-- gerado a partir dos modelos; não editar à mão -->

As tabelas abaixo são **geradas** a partir dos modelos SQLAlchemy — a coluna
*Classificação* vem do metadado declarado em cada campo, e é ela que vira
*policy tag* no BigQuery na fase GCP.

| Métrica | Valor |
|---|---:|
| Tabelas no schema `oltp` | 40 |
| Campos classificados | 418 |

### Domínio `clientes` — 5 tabelas

#### `customer_segments`

Segmentos comerciais associáveis ao cadastro do cliente.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável do segmento, usado como chave natural. |
| `name` | `varchar(80)` | sim | — | `public` | Nome comercial do segmento. |
| `description` | `text` | não | — | `public` | Critério de enquadramento do segmento. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o segmento continua em uso. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `customers`

Cadastro principal do cliente e estado do relacionamento.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `customer_code` | `varchar(32)` | sim | UK | `internal` | Chave natural do cliente na origem; estável entre cargas. |
| `segment_id` | `bigint` | não | FK | `internal` | Segmento comercial ao qual o cliente pertence. |
| `first_name` | `varchar(80)` | sim | — | `personal` | Primeiro nome do cliente (sintético). |
| `last_name` | `varchar(120)` | sim | — | `personal` | Sobrenome do cliente (sintético). |
| `document` | `varchar(32)` | sim | UK | `personal` | Documento de identificação do cliente (sintético). |
| `birth_date` | `date` | não | — | `personal` | Data de nascimento do cliente (sintética). |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do relacionamento: active, inactive, blocked ou pending. |
| `registered_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio do cadastro, distinto de `created_at`. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `customer_addresses`

Endereços de cobrança e entrega, com vigência e indicação de principal.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `customer_id` | `bigint` | sim | FK | `internal` | Cliente dono do endereço. |
| `address_type` | `varchar(16)` | sim | — | `internal` | Finalidade do endereço: billing ou shipping. |
| `street` | `varchar(160)` | sim | — | `personal` | Logradouro (sintético). |
| `number` | `varchar(20)` | não | — | `personal` | Número do endereço (sintético). |
| `complement` | `varchar(80)` | não | — | `personal` | Complemento do endereço (sintético). |
| `district` | `varchar(80)` | não | — | `personal` | Bairro (sintético). |
| `city` | `varchar(80)` | sim | — | `public` | Cidade; alimenta a dimensão de geografia. |
| `state` | `varchar(2)` | sim | — | `public` | Unidade federativa em sigla de duas letras. |
| `postal_code` | `varchar(16)` | sim | — | `personal` | Código postal (sintético). |
| `country` | `varchar(2)` | sim | — | `public` | País em código ISO de duas letras. |
| `is_primary` | `boolean` | sim | — | `internal` | Endereço principal do cliente para o tipo indicado. |
| `valid_from` | `timestampwithtimezone` | sim | — | `internal` | Início da vigência do endereço. |
| `valid_to` | `timestampwithtimezone` | não | — | `internal` | Fim da vigência; nulo enquanto vigente. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `customer_contacts`

E-mails e telefones sintéticos associados ao cliente.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `customer_id` | `bigint` | sim | FK | `internal` | Cliente dono do contato. |
| `contact_type` | `varchar(16)` | sim | — | `internal` | Natureza do contato: email, phone ou mobile. |
| `contact_value` | `varchar(160)` | sim | — | `personal` | Endereço de e-mail ou número de telefone (sintético). |
| `is_primary` | `boolean` | sim | — | `internal` | Contato principal do cliente para o tipo indicado. |
| `is_verified` | `boolean` | sim | — | `internal` | Indica se o contato passou por verificação simulada. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `customer_preferences`

Preferências de comunicação, idioma e consentimentos simulados.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `customer_id` | `bigint` | sim | FK UK | `internal` | Cliente dono das preferências; uma linha por cliente. |
| `language` | `varchar(10)` | sim | — | `internal` | Idioma preferido, em código BCP 47. |
| `currency` | `varchar(3)` | sim | — | `public` | Moeda preferida, em código ISO 4217. |
| `marketing_opt_in` | `boolean` | sim | — | `confidential` | Consentimento simulado para comunicações de marketing. |
| `newsletter_opt_in` | `boolean` | sim | — | `confidential` | Consentimento simulado para a newsletter. |
| `consent_updated_at` | `timestampwithtimezone` | não | — | `confidential` | Momento da última alteração de consentimento. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `catalogo` — 6 tabelas

#### `brands`

Marcas associadas aos produtos.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável da marca. |
| `name` | `varchar(120)` | sim | — | `public` | Nome da marca. |
| `country` | `varchar(2)` | não | — | `public` | País de origem, em código ISO. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se a marca continua ativa no catálogo. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `product_categories`

Hierarquia de categorias e subcategorias do catálogo.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável da categoria; chave natural. |
| `name` | `varchar(120)` | sim | — | `public` | Nome comercial da categoria. |
| `parent_id` | `bigint` | não | FK | `public` | Categoria imediatamente superior; nulo na raiz. |
| `depth` | `integer` | sim | — | `public` | Profundidade na hierarquia, com a raiz em zero. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se a categoria continua em uso. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `price_lists`

Listas de preço por canal, moeda e período de vigência.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável da lista. |
| `name` | `varchar(120)` | sim | — | `public` | Nome comercial da lista de preços. |
| `sales_channel_id` | `bigint` | não | FK | `public` | Canal ao qual a lista se aplica; nulo quando vale para todos. |
| `currency` | `varchar(3)` | sim | — | `public` | Moeda da lista, em código ISO 4217. |
| `valid_from` | `timestampwithtimezone` | sim | — | `public` | Início da vigência da lista. |
| `valid_to` | `timestampwithtimezone` | não | — | `public` | Fim da vigência; nulo enquanto vigente. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se a lista está em uso. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `products`

Produto conceitual vendido pelo marketplace.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `product_code` | `varchar(32)` | sim | UK | `public` | Chave natural do produto na origem. |
| `category_id` | `bigint` | sim | FK | `public` | Categoria comercial do produto. |
| `brand_id` | `bigint` | não | FK | `public` | Marca do produto. |
| `name` | `varchar(200)` | sim | — | `public` | Nome comercial do produto. |
| `description` | `text` | não | — | `public` | Descrição comercial do produto. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do produto: draft, active ou discontinued. |
| `launched_at` | `timestampwithtimezone` | não | — | `public` | Momento de lançamento comercial. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `product_variants`

SKUs e variações de tamanho, cor ou embalagem.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `product_id` | `bigint` | sim | FK | `public` | Produto do qual a variante deriva. |
| `sku` | `varchar(40)` | sim | UK | `public` | Código de estoque da variante; chave natural do SKU. |
| `size` | `varchar(20)` | não | — | `public` | Tamanho da variante. |
| `color` | `varchar(40)` | não | — | `public` | Cor da variante. |
| `package` | `varchar(40)` | não | — | `public` | Embalagem ou unidade de venda. |
| `barcode` | `varchar(32)` | não | UK | `public` | Código de barras da variante (sintético). |
| `weight_grams` | `integer` | não | — | `public` | Peso em gramas, usado no cálculo de frete. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o SKU continua disponível para venda. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `product_prices`

Preço de cada SKU em uma lista e intervalo de vigência.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `price_list_id` | `bigint` | sim | FK | `public` | Lista à qual o preço pertence. |
| `product_variant_id` | `bigint` | sim | FK | `public` | SKU precificado. |
| `unit_price` | `numeric(14,4)` | sim | — | `confidential` | Preço unitário de venda na lista e vigência. |
| `valid_from` | `timestampwithtimezone` | sim | — | `public` | Início da vigência do preço. |
| `valid_to` | `timestampwithtimezone` | não | — | `public` | Fim da vigência; nulo enquanto vigente. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `compras` — 5 tabelas

#### `suppliers`

Cadastro sintético dos fornecedores.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `supplier_code` | `varchar(32)` | sim | UK | `internal` | Chave natural do fornecedor na origem. |
| `legal_name` | `varchar(200)` | sim | — | `confidential` | Razão social do fornecedor (sintética). |
| `trade_name` | `varchar(200)` | não | — | `public` | Nome fantasia do fornecedor. |
| `document` | `varchar(32)` | sim | UK | `confidential` | Documento de identificação do fornecedor (sintético). |
| `contact_email` | `varchar(160)` | não | — | `personal` | E-mail de contato comercial (sintético). |
| `country` | `varchar(2)` | sim | — | `public` | País do fornecedor, em código ISO. |
| `payment_terms_days` | `integer` | sim | — | `confidential` | Prazo de pagamento negociado, em dias. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o fornecedor continua ativo. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `purchase_orders`

Cabeçalho das ordens de compra enviadas a fornecedores.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `po_number` | `varchar(32)` | sim | UK | `internal` | Número da ordem de compra; chave natural. |
| `supplier_id` | `bigint` | sim | FK | `internal` | Fornecedor da ordem. |
| `status` | `varchar(24)` | sim | — | `internal` | Estado da ordem; transições válidas em Modelo de Dados §4. |
| `ordered_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de emissão da ordem. |
| `expected_at` | `timestampwithtimezone` | não | — | `internal` | Data prometida de entrega pelo fornecedor. |
| `currency` | `varchar(3)` | sim | — | `public` | Moeda da ordem, em código ISO 4217. |
| `total_amount` | `numeric(14,2)` | sim | — | `confidential` | Valor total da ordem, somando os itens. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `goods_receipts`

Registro do recebimento físico de uma ordem de compra.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `receipt_number` | `varchar(32)` | sim | UK | `internal` | Número do recebimento; chave natural. |
| `purchase_order_id` | `bigint` | sim | FK | `internal` | Ordem de compra recebida. |
| `warehouse_id` | `bigint` | sim | FK | `internal` | Armazém que recebeu a mercadoria. |
| `received_at` | `timestampwithtimezone` | sim | — | `internal` | Momento do recebimento físico. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do recebimento: pending, completed ou rejected. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `purchase_order_items`

Produtos, quantidades e custos solicitados ao fornecedor.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `purchase_order_id` | `bigint` | sim | FK | `internal` | Ordem de compra à qual o item pertence. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU solicitado. |
| `quantity_ordered` | `integer` | sim | — | `internal` | Quantidade solicitada ao fornecedor. |
| `unit_cost` | `numeric(14,4)` | sim | — | `confidential` | Custo unitário negociado. |
| `total_cost` | `numeric(14,2)` | sim | — | `confidential` | Custo total do item, já arredondado. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `goods_receipt_items`

Quantidades efetivamente recebidas por item da ordem de compra.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `goods_receipt_id` | `bigint` | sim | FK | `internal` | Recebimento ao qual o item pertence. |
| `purchase_order_item_id` | `bigint` | sim | FK | `internal` | Item da ordem de compra correspondente. |
| `quantity_received` | `integer` | sim | — | `internal` | Quantidade efetivamente recebida. |
| `unit_cost` | `numeric(14,4)` | sim | — | `confidential` | Custo unitário no recebimento. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `vendas` — 6 tabelas

#### `sales_channels`

Canais de venda como web, aplicativo e loja física.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável do canal. |
| `name` | `varchar(80)` | sim | — | `public` | Nome do canal de venda. |
| `channel_type` | `varchar(16)` | sim | — | `public` | Natureza do canal: web, app ou store. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o canal continua operando. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `carts`

Carrinhos abertos, convertidos, abandonados ou expirados.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `cart_code` | `varchar(40)` | sim | UK | `internal` | Chave natural do carrinho. |
| `customer_id` | `bigint` | não | FK | `internal` | Cliente dono do carrinho; nulo em sessão anônima. |
| `sales_channel_id` | `bigint` | sim | FK | `public` | Canal em que o carrinho foi aberto. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do carrinho: open, converted, abandoned ou expired. |
| `expires_at` | `timestampwithtimezone` | não | — | `internal` | Momento previsto de expiração. |
| `converted_at` | `timestampwithtimezone` | não | — | `internal` | Momento da conversão em pedido. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `cart_items`

Produtos e quantidades incluídos nos carrinhos; maior tabela do projeto.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `cart_id` | `bigint` | sim | FK | `internal` | Carrinho ao qual o item pertence. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU adicionado ao carrinho. |
| `quantity` | `integer` | sim | — | `internal` | Quantidade do SKU no carrinho. |
| `unit_price` | `numeric(14,4)` | sim | — | `confidential` | Preço unitário vigente no momento em que o item foi adicionado. |
| `added_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o item entrou no carrinho. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `orders`

Cabeçalho do pedido: cliente, canal, valores e estado atual.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `order_number` | `varchar(32)` | sim | UK | `internal` | Número do pedido; chave natural. |
| `customer_id` | `bigint` | sim | FK | `internal` | Cliente que fez o pedido. |
| `sales_channel_id` | `bigint` | sim | FK | `public` | Canal em que o pedido foi feito. |
| `cart_id` | `bigint` | não | FK UK | `internal` | Carrinho que originou o pedido; nulo em venda direta. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado atual do pedido; o histórico vive em `order_status_history`. |
| `placed_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio em que o pedido foi feito. |
| `currency` | `varchar(3)` | sim | — | `public` | Moeda do pedido, em código ISO 4217. |
| `subtotal_amount` | `numeric(14,2)` | sim | — | `confidential` | Soma dos itens antes de desconto, frete e imposto. |
| `discount_amount` | `numeric(14,2)` | sim | — | `confidential` | Desconto total aplicado ao pedido. |
| `shipping_amount` | `numeric(14,2)` | sim | — | `confidential` | Valor de frete cobrado. |
| `tax_amount` | `numeric(14,2)` | sim | — | `confidential` | Imposto simulado sobre o pedido. |
| `total_amount` | `numeric(14,2)` | sim | — | `confidential` | Valor total do pedido; reconcilia os demais campos. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `order_items`

Grão comercial do pedido: um SKU comprado em uma linha.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `order_id` | `bigint` | sim | FK | `internal` | Pedido ao qual o item pertence. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU comprado. |
| `quantity` | `integer` | sim | — | `internal` | Quantidade comprada do SKU. |
| `unit_price` | `numeric(14,4)` | sim | — | `confidential` | Preço unitário praticado na venda. |
| `discount_amount` | `numeric(14,2)` | sim | — | `confidential` | Desconto aplicado a este item. |
| `tax_amount` | `numeric(14,2)` | sim | — | `confidential` | Imposto simulado sobre este item. |
| `total_amount` | `numeric(14,2)` | sim | — | `confidential` | Valor total da linha, já arredondado. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `order_status_history`

Histórico temporal das mudanças de estado do pedido.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `order_id` | `bigint` | sim | FK | `internal` | Pedido cujo estado mudou. |
| `from_status` | `varchar(16)` | não | — | `internal` | Estado anterior; nulo na criação do pedido. |
| `to_status` | `varchar(16)` | sim | — | `internal` | Estado resultante da transição. |
| `changed_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio da transição. |
| `reason` | `text` | não | — | `internal` | Motivo registrado para a transição. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o evento foi registrado na origem. |

### Domínio `pagamentos` — 4 tabelas

#### `payment_methods`

Tipos de pagamento aceitos, sem armazenar credenciais.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável do meio de pagamento. |
| `name` | `varchar(80)` | sim | — | `public` | Nome do meio de pagamento. |
| `method_type` | `varchar(20)` | sim | — | `public` | Natureza do meio: cartão, pix, boleto, carteira ou vale. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o meio continua aceito. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `payments`

Intenção de pagamento associada ao pedido.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `payment_code` | `varchar(40)` | sim | UK | `internal` | Chave natural do pagamento. |
| `order_id` | `bigint` | sim | FK | `internal` | Pedido que o pagamento quita. |
| `payment_method_id` | `bigint` | sim | FK | `public` | Meio de pagamento utilizado. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do pagamento; transições válidas em Modelo de Dados §4. |
| `amount` | `numeric(14,2)` | sim | — | `confidential` | Valor pretendido do pagamento. |
| `currency` | `varchar(3)` | sim | — | `public` | Moeda, em código ISO 4217. |
| `installments` | `integer` | sim | — | `public` | Número de parcelas acordadas. |
| `authorized_at` | `timestampwithtimezone` | não | — | `internal` | Momento da autorização pelo emissor simulado. |
| `captured_at` | `timestampwithtimezone` | não | — | `internal` | Momento da captura efetiva do valor. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `payment_transactions`

Tentativas, autorizações, capturas e falhas do pagamento.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `transaction_code` | `varchar(40)` | sim | UK | `internal` | Chave natural da transação. |
| `payment_id` | `bigint` | sim | FK | `internal` | Pagamento ao qual a transação pertence. |
| `transaction_type` | `varchar(20)` | sim | — | `internal` | Operação financeira: authorization, capture, void ou refund. |
| `result` | `varchar(16)` | sim | — | `internal` | Desfecho da operação: succeeded, failed ou pending. |
| `amount` | `numeric(14,2)` | sim | — | `confidential` | Valor movimentado nesta operação. |
| `gateway_response_code` | `varchar(32)` | não | — | `internal` | Código de retorno do adquirente simulado. |
| `occurred_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio da operação. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o evento foi registrado na origem. |

#### `refunds`

Reembolsos totais ou parciais de transações capturadas.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `refund_code` | `varchar(40)` | sim | UK | `internal` | Chave natural do reembolso. |
| `payment_transaction_id` | `bigint` | sim | FK | `internal` | Transação de captura que está sendo revertida. |
| `amount` | `numeric(14,2)` | sim | — | `confidential` | Valor reembolsado. |
| `reason` | `text` | não | — | `internal` | Motivo comercial do reembolso. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado do reembolso: requested, completed ou rejected. |
| `refunded_at` | `timestampwithtimezone` | não | — | `internal` | Momento em que o reembolso foi concluído. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `estoque` — 4 tabelas

#### `warehouses`

Centros de distribuição ou locais de estoque.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável do armazém. |
| `name` | `varchar(120)` | sim | — | `public` | Nome do armazém. |
| `city` | `varchar(80)` | sim | — | `public` | Cidade do armazém. |
| `state` | `varchar(2)` | sim | — | `public` | Unidade federativa do armazém. |
| `country` | `varchar(2)` | sim | — | `public` | País, em código ISO. |
| `capacity_units` | `integer` | não | — | `confidential` | Capacidade máxima em unidades. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o armazém está operando. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `inventory_balances`

Saldo atual de cada SKU por armazém.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `warehouse_id` | `bigint` | sim | FK | `internal` | Armazém do saldo. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU do saldo. |
| `quantity_on_hand` | `integer` | sim | — | `internal` | Quantidade fisicamente disponível. |
| `quantity_reserved` | `integer` | sim | — | `internal` | Quantidade reservada para carrinhos e pedidos. |
| `quantity_available` | `integer` | sim | — | `internal` | Quantidade livre para venda; derivada pelo banco. |
| `last_movement_at` | `timestampwithtimezone` | não | — | `internal` | Momento do último movimento aplicado ao saldo. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `inventory_movements`

Livro append-only de entradas, saídas, ajustes e transferências.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `movement_id` | `uuid` | sim | PK | `internal` | Chave primária estável do evento. |
| `event_sequence` | `bigint` | sim | UK | `internal` | Ordenação técnica local e paginação; atribuída pelo banco. |
| `idempotency_key` | `varchar(100)` | sim | UK | `internal` | Chave que impede aplicação duplicada pelo consumidor (ADR-0019). |
| `warehouse_id` | `bigint` | sim | FK | `internal` | Armazém afetado pelo movimento. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU afetado pelo movimento. |
| `movement_type` | `varchar(32)` | sim | — | `internal` | Tipo controlado do movimento; determina o sinal da quantidade. |
| `quantity_delta` | `integer` | sim | — | `internal` | Variação assinada da quantidade; nunca zero. |
| `unit_cost` | `numeric(14,4)` | não | — | `confidential` | Custo unitário, quando aplicável ao tipo. |
| `source_type` | `varchar(32)` | sim | — | `internal` | Processo de negócio que originou o movimento. |
| `source_id` | `varchar(64)` | sim | — | `internal` | Identificador do registro que causou o movimento. |
| `correlation_id` | `uuid` | não | — | `internal` | Agrupa eventos relacionados; obrigatório nos pares de transferência. |
| `causation_id` | `uuid` | não | — | `internal` | Evento ou comando que causou este movimento. |
| `aggregate_version` | `bigint` | sim | — | `internal` | Ordem do evento dentro do par armazém/SKU; sem lacuna nem repetição. |
| `occurred_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio do movimento; é por ele que o Beam janela (ADR-0019). |
| `recorded_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que a origem registrou o evento; base da leitura incremental. |
| `schema_version` | `smallint` | sim | — | `internal` | Versão do contrato do evento, para evolução sem quebrar consumidor. |
| `metadata` | `jsonb` | não | — | `internal` | Contexto adicional do evento, opcional e limitado a 4 KB. |

#### `stock_reservations`

Reserva de quantidade para carrinhos ou pedidos.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `reservation_code` | `varchar(40)` | sim | UK | `internal` | Chave natural da reserva. |
| `warehouse_id` | `bigint` | sim | FK | `internal` | Armazém em que a quantidade está reservada. |
| `product_variant_id` | `bigint` | sim | FK | `internal` | SKU reservado. |
| `cart_id` | `bigint` | não | FK | `internal` | Carrinho que originou a reserva; nulo quando a origem é um pedido. |
| `order_id` | `bigint` | não | FK | `internal` | Pedido que originou a reserva; nulo quando a origem é um carrinho. |
| `quantity` | `integer` | sim | — | `internal` | Quantidade reservada. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado da reserva: active, released, expired ou consumed. |
| `expires_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que a reserva expira se não for consumida. |
| `released_at` | `timestampwithtimezone` | não | — | `internal` | Momento em que a reserva deixou de ocupar saldo. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `logistica` — 4 tabelas

#### `carriers`

Transportadoras sintéticas e suas modalidades.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável da transportadora. |
| `name` | `varchar(120)` | sim | — | `public` | Nome da transportadora. |
| `service_level` | `varchar(16)` | sim | — | `public` | Modalidade: standard, express ou same_day. |
| `tracking_url_template` | `varchar(255)` | não | — | `public` | Modelo de URL de rastreio, com marcador do código. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se a transportadora está em uso. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `shipments`

Remessas criadas para atender pedidos.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `shipment_code` | `varchar(40)` | sim | UK | `internal` | Chave natural da remessa. |
| `order_id` | `bigint` | sim | FK | `internal` | Pedido que a remessa atende. |
| `carrier_id` | `bigint` | sim | FK | `public` | Transportadora responsável. |
| `warehouse_id` | `bigint` | sim | FK | `internal` | Armazém de origem da remessa. |
| `status` | `varchar(16)` | sim | — | `internal` | Estado da remessa; transições válidas em Modelo de Dados §4. |
| `tracking_code` | `varchar(64)` | não | — | `internal` | Código de rastreio junto à transportadora. |
| `freight_amount` | `numeric(14,2)` | sim | — | `confidential` | Custo de frete da remessa. |
| `shipped_at` | `timestampwithtimezone` | não | — | `internal` | Momento do despacho. |
| `estimated_delivery_at` | `timestampwithtimezone` | não | — | `public` | Prazo de entrega prometido ao cliente. |
| `delivered_at` | `timestampwithtimezone` | não | — | `internal` | Momento da entrega efetiva. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `delivery_events`

Eventos de coleta, trânsito, tentativa e entrega.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `shipment_id` | `bigint` | sim | FK | `internal` | Remessa à qual o evento se refere. |
| `event_type` | `varchar(24)` | sim | — | `public` | Natureza do evento de entrega. |
| `occurred_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio do evento. |
| `location` | `varchar(120)` | não | — | `public` | Localidade registrada pela transportadora. |
| `description` | `text` | não | — | `public` | Descrição textual do evento. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o evento foi registrado na origem. |

#### `shipment_items`

Quantidades de itens de pedido incluídas em cada remessa.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `shipment_id` | `bigint` | sim | FK | `internal` | Remessa à qual o item pertence. |
| `order_item_id` | `bigint` | sim | FK | `internal` | Item de pedido sendo enviado. |
| `quantity` | `integer` | sim | — | `internal` | Quantidade enviada nesta remessa. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

### Domínio `marketing` — 3 tabelas

#### `campaigns`

Campanhas de marketing e seus períodos de vigência.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código estável da campanha. |
| `name` | `varchar(120)` | sim | — | `public` | Nome da campanha. |
| `objective` | `varchar(20)` | sim | — | `public` | Objetivo comercial da campanha. |
| `valid_from` | `timestampwithtimezone` | sim | — | `public` | Início da vigência da campanha. |
| `valid_to` | `timestampwithtimezone` | sim | — | `public` | Fim da vigência da campanha. |
| `budget_amount` | `numeric(14,2)` | não | — | `confidential` | Orçamento previsto da campanha. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se a campanha está ativa. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `coupons`

Cupons, regras de desconto e limites de utilização.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `code` | `varchar(32)` | sim | UK | `public` | Código digitado pelo cliente. |
| `campaign_id` | `bigint` | sim | FK | `public` | Campanha à qual o cupom pertence. |
| `discount_type` | `varchar(16)` | sim | — | `public` | Natureza do desconto: percentage ou fixed. |
| `discount_value` | `numeric(14,2)` | sim | — | `confidential` | Valor do desconto: percentual quando `percentage`, moeda quando `fixed`. |
| `min_order_amount` | `numeric(14,2)` | não | — | `public` | Valor mínimo de pedido para o cupom ser elegível. |
| `max_redemptions` | `integer` | não | — | `internal` | Limite total de utilizações; nulo quando ilimitado. |
| `valid_from` | `timestampwithtimezone` | sim | — | `public` | Início da vigência do cupom. |
| `valid_to` | `timestampwithtimezone` | sim | — | `public` | Fim da vigência do cupom. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o cupom continua aceito. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `coupon_redemptions`

Uso efetivo de cupons por cliente e pedido.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `coupon_id` | `bigint` | sim | FK | `internal` | Cupom utilizado. |
| `customer_id` | `bigint` | sim | FK | `internal` | Cliente que utilizou o cupom. |
| `order_id` | `bigint` | sim | FK | `internal` | Pedido em que o cupom foi aplicado. |
| `discount_amount` | `numeric(14,2)` | sim | — | `confidential` | Desconto efetivamente concedido. |
| `redeemed_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio da utilização. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o evento foi registrado na origem. |

### Domínio `atendimento` — 3 tabelas

#### `support_agents`

Agentes sintéticos e suas equipes de atendimento.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `agent_code` | `varchar(32)` | sim | UK | `internal` | Chave natural do agente. |
| `first_name` | `varchar(80)` | sim | — | `personal` | Primeiro nome do agente (sintético). |
| `last_name` | `varchar(120)` | sim | — | `personal` | Sobrenome do agente (sintético). |
| `email` | `varchar(160)` | sim | UK | `personal` | E-mail corporativo do agente (sintético). |
| `team` | `varchar(60)` | sim | — | `public` | Equipe de atendimento à qual o agente pertence. |
| `hired_at` | `timestampwithtimezone` | sim | — | `internal` | Início do período de atuação do agente. |
| `is_active` | `boolean` | sim | — | `internal` | Indica se o agente continua atuando. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `support_tickets`

Solicitações associadas a clientes, pedidos ou entregas.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `ticket_number` | `varchar(32)` | sim | UK | `internal` | Número do chamado; chave natural. |
| `customer_id` | `bigint` | sim | FK | `internal` | Cliente que abriu o chamado. |
| `order_id` | `bigint` | não | FK | `internal` | Pedido relacionado ao chamado, quando houver. |
| `shipment_id` | `bigint` | não | FK | `internal` | Remessa relacionada ao chamado, quando houver. |
| `assigned_agent_id` | `bigint` | não | FK | `internal` | Agente responsável pelo chamado no momento. |
| `category` | `varchar(20)` | sim | — | `public` | Motivo do chamado. |
| `priority` | `varchar(10)` | sim | — | `internal` | Prioridade atribuída ao chamado. |
| `status` | `varchar(20)` | sim | — | `internal` | Estado atual do chamado. |
| `subject` | `varchar(200)` | sim | — | `personal` | Assunto escrito pelo cliente (sintético). |
| `opened_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de abertura do chamado. |
| `closed_at` | `timestampwithtimezone` | não | — | `internal` | Momento de encerramento do chamado. |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de criação do registro na origem. |
| `updated_at` | `timestampwithtimezone` | sim | — | `internal` | Momento da última alteração; cursor da carga incremental (ADR-0015). |
| `deleted_at` | `timestampwithtimezone` | não | — | `internal` | Exclusão lógica; nulo enquanto o registro está ativo (ADR-0015). |

#### `ticket_events`

Interações, atribuições e mudanças de estado do chamado.

| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |
|---|---|:---:|:---:|---|---|
| `id` | `bigint` | sim | PK | `internal` | Chave primária técnica, gerada pelo banco. |
| `ticket_id` | `bigint` | sim | FK | `internal` | Chamado ao qual o evento pertence. |
| `agent_id` | `bigint` | não | FK | `internal` | Agente autor do evento; nulo quando o autor é o cliente. |
| `event_type` | `varchar(20)` | sim | — | `internal` | Natureza do evento no chamado. |
| `occurred_at` | `timestampwithtimezone` | sim | — | `internal` | Momento de negócio do evento. |
| `message` | `text` | não | — | `personal` | Conteúdo da interação (sintético). |
| `created_at` | `timestampwithtimezone` | sim | — | `internal` | Momento em que o evento foi registrado na origem. |

<!-- fim do trecho gerado -->

---

## 3. Linhagem

*Vazia.* A linhagem detalhada é gerada pelo dbt; esta seção registra apenas as travessias que o dbt
não enxerga — a extração feita pelo Airbyte e o caminho de streaming.

| Origem | Destino | Mecanismo | Frequência | Observação |
|---|---|---|---|---|
| — | — | — | — | — |

---

## 4. Decisões de classificação

*Vazia.* Registra os casos em que a classificação de um campo não foi óbvia e precisou de
justificativa — por exemplo, um campo agregado derivado de dados sensíveis.

| Campo | Classificação | Justificativa | Data |
|---|---|---|---|
| — | — | — | — |
