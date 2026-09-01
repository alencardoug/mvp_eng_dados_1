# Modelo de Dados

> **O que vive aqui:** o inventário do que é modelado — as 40 tabelas transacionais por domínio, o
> modelo dimensional (9 fatos e 17 dimensões), as invariantes de negócio e o contrato do evento de
> estoque.
>
> **O que não vive aqui:** como os dados são gerados (ver [Geração de Dados](geracao_de_dados.md));
> a definição campo a campo e a classificação (ver
> [Dicionário de Dados](dicionario_de_dados.md)); o orçamento de armazenamento (ver
> [Capacidade e Recuperação](capacidade_e_recuperacao.md)); os testes (ver
> [Qualidade de Dados](qualidade_de_dados.md)).

| Campo | Informação |
|---|---|
| Domínio de negócio | Marketplace de varejo *omnichannel* ([ADR-0002](adr/0002-dominio-marketplace-omnichannel.md)) |
| Versão | 1.0 |
| Situação | Proposta — materializações e chaves substitutas dependem de ADR |
| Última revisão | 01/09/2026 |

As contagens de linhas são **metas de geração** do perfil `demo_4gb`, não resultados medidos. O
perfil é definido em [Geração de Dados](geracao_de_dados.md).

---

## 1. Origens

O projeto tem duas origens transacionais distintas, deliberadamente diferentes em qualidade:

| Origem | Banco | Estrutura | Papel |
|---|---|---|---|
| Principal | `source_db`, schema `oltp` | 40 tabelas normalizadas (3FN como referência), tipagem estrita, *constraints* completas | Sistema em operação, bem governado |
| Legada | `legacy_db`, schema `legacy` | Mesmos 40 nomes de tabela e mesmo significado de campos, com tipos flexíveis (`text`) e *constraints* relaxadas | Sistema antigo, sem governança, com falhas intencionais |

A estrutura legada é **logicamente idêntica**, não uma cópia literal do DDL normalizado: colunas
que precisam aceitar valores incompatíveis são declaradas como `text`, porque uma coluna tipada
como número ou data rejeitaria os exemplos defeituosos antes da engenharia de limpeza — que é
justamente o que se quer exercitar.

---

## 2. Modelo transacional — 40 tabelas em 9 domínios

### 2.1 Clientes — 5 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `customers` | 15.000 | Cadastro principal do cliente e estado do relacionamento. |
| `customer_addresses` | 21.000 | Endereços de cobrança e entrega, com vigência e indicação de endereço principal. |
| `customer_contacts` | 24.000 | E-mails e telefones sintéticos associados ao cliente. |
| `customer_preferences` | 15.000 | Preferências de comunicação, idioma e consentimentos simulados. |
| `customer_segments` | 8 | Segmentos comerciais associáveis ao cadastro do cliente. |

### 2.2 Catálogo e preços — 6 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `products` | 3.000 | Produto conceitual vendido pelo marketplace. |
| `product_categories` | 80 | Hierarquia de categorias e subcategorias. |
| `brands` | 180 | Marcas associadas aos produtos. |
| `product_variants` | 6.000 | SKUs e variações de tamanho, cor ou embalagem. |
| `price_lists` | 5 | Listas de preço por canal, moeda e período de vigência. |
| `product_prices` | 12.000 | Preço de cada SKU em uma lista e intervalo de vigência. |

### 2.3 Fornecedores e compras — 5 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `suppliers` | 300 | Cadastro sintético dos fornecedores. |
| `purchase_orders` | 4.000 | Cabeçalho das ordens de compra. |
| `purchase_order_items` | 16.000 | Produtos, quantidades e custos solicitados ao fornecedor. |
| `goods_receipts` | 3.800 | Registro do recebimento físico de uma ordem de compra. |
| `goods_receipt_items` | 15.200 | Quantidades efetivamente recebidas por item da ordem. |

### 2.4 Vendas — 6 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `sales_channels` | 3 | Canais como web, aplicativo e loja. |
| `carts` | 400.000 | Carrinhos abertos, convertidos, abandonados ou expirados. |
| `cart_items` | **1.100.000** | Produtos e quantidades incluídos nos carrinhos; maior tabela do projeto. |
| `orders` | 35.000 | Cabeçalho do pedido, cliente, canal, valores e estado atual. |
| `order_items` | 75.000 | Grão comercial do pedido: um SKU comprado em uma linha. |
| `order_status_history` | 175.000 | Histórico temporal das mudanças de estado do pedido. |

### 2.5 Pagamentos — 4 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `payment_methods` | 6 | Tipos de pagamento aceitos, sem armazenar credenciais reais. |
| `payments` | 36.750 | Intenção de pagamento associada ao pedido. |
| `payment_transactions` | 52.500 | Tentativas, autorizações, capturas e falhas do pagamento. |
| `refunds` | 1.400 | Reembolsos totais ou parciais de transações capturadas. |

### 2.6 Estoque — 4 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `warehouses` | 5 | Centros de distribuição ou locais de estoque. |
| `inventory_balances` | 25.000 | Saldo atual de cada SKU por armazém. |
| `inventory_movements` | 120.000 no seed; até 170.000 após o streaming | Livro *append-only* de entradas, saídas, ajustes e transferências. |
| `stock_reservations` | 42.000 | Reserva de quantidade para carrinhos ou pedidos. |

`inventory_movements` é a tabela que alimenta o fluxo de streaming — seu contrato de evento está na
[seção 5](#5-contrato-do-evento-de-estoque).

### 2.7 Logística — 4 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `carriers` | 8 | Transportadoras sintéticas. |
| `shipments` | 37.000 | Remessas criadas para atender pedidos. |
| `shipment_items` | 78.000 | Quantidades de itens de pedido incluídas em cada remessa. |
| `delivery_events` | 185.000 | Eventos de coleta, trânsito, tentativa e entrega. |

### 2.8 Marketing — 3 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `campaigns` | 28 | Campanhas e seus períodos de vigência. |
| `coupons` | 180 | Cupons, regras de desconto e limites de utilização. |
| `coupon_redemptions` | 6.000 | Uso efetivo de cupons por cliente e pedido. |

### 2.9 Atendimento — 3 tabelas

| Tabela | Linhas | Finalidade |
|---|---:|---|
| `support_agents` | 42 | Agentes sintéticos e suas equipes de atendimento. |
| `support_tickets` | 4.000 | Solicitações associadas a clientes, pedidos ou entregas. |
| `ticket_events` | 18.000 | Interações, atribuições e mudanças de estado do chamado. |

**Total da origem principal:** aproximadamente **2.526.495 linhas** após o seed, podendo alcançar
**2.576.495** com o lote máximo de streaming.

`cart_items` ultrapassa deliberadamente 1 milhão de linhas: o volume decorre de cerca de 400 mil
carrinhos com abandono, expiração e múltiplas alterações antes da conversão. As demais proporções
preservam coerência entre pedidos, itens, pagamentos, estoque e entregas.

---

## 3. Modelo dimensional — 26 tabelas em `analytics`

Não há fatos do tipo *snapshot*: todo processo é representado por eventos transacionais. As
métricas de estado ao longo do tempo são derivadas dos eventos, não de fotografias periódicas do
banco.

### 3.1 Tabelas fato — 9

| Tabela | Linhas | Grão | Tipo |
|---|---:|---|---|
| `fact_sales_order_item` | 75.000 | Uma linha de item de pedido. | Transacional |
| `fact_payment_transaction` | 52.500 | Uma tentativa ou operação financeira. | Transacional |
| `fact_refund` | 1.400 | Um reembolso realizado. | Transacional |
| `fact_purchase_order_item` | 16.000 | Um item de uma ordem de compra. | Transacional |
| `fact_inventory_movement` | 120.000 no seed; até 170.000 após o streaming | Uma movimentação de SKU em um armazém. | Transacional |
| `fact_shipment_item` | 78.000 | Um item de pedido em uma remessa. | Transacional |
| `fact_order_status_event` | 175.000 | Uma mudança de estado de um pedido. | Transacional |
| `fact_coupon_redemption` | 6.000 | Um uso de cupom em um pedido. | Transacional |
| `fact_support_ticket_event` | 18.000 | Uma interação ou mudança de estado de chamado. | Transacional |

### 3.2 Dimensões — 17

| Tabela | Linhas | Conteúdo principal | Tratamento |
|---|---:|---|---|
| `dim_date` | 975 | Calendário de 01/01/2024 a 01/09/2026, inclusive. | Estática |
| `dim_time` | 1.440 | Hora, minuto e faixas do dia. | Estática |
| `dim_customer` | 16.500 | Perfil, segmento e estado do cliente. | SCD tipo 2 |
| `dim_geography` | 1.500 | Cidade, estado, região e país. | Conformada |
| `dim_product` | 6.600 | SKU, produto e atributos da variante. | SCD tipo 2 |
| `dim_category` | 88 | Hierarquia comercial de categorias. | SCD tipo 2 quando aplicável |
| `dim_brand` | 180 | Marca do produto. | SCD tipo 1 |
| `dim_supplier` | 330 | Fornecedor e atributos comerciais. | SCD tipo 2 |
| `dim_sales_channel` | 3 | Canal de venda. | SCD tipo 1 |
| `dim_warehouse` | 5 | Local de estoque e capacidade. | SCD tipo 2 |
| `dim_carrier` | 8 | Transportadora e modalidade. | SCD tipo 1 |
| `dim_campaign` | 28 | Campanha, objetivo e vigência. | SCD tipo 1 |
| `dim_coupon` | 198 | Regra e tipo de desconto. | SCD tipo 2 |
| `dim_payment_method` | 6 | Meio e modalidade de pagamento. | SCD tipo 1 |
| `dim_currency` | 1 | Moeda e código ISO. | Estática |
| `dim_support_category` | 12 | Motivo e categoria do chamado. | Derivada e conformada |
| `dim_support_agent` | 46 | Agente, equipe e período de atuação. | SCD tipo 2 |

Identificadores operacionais como `order_number`, `ticket_number` e `tracking_number` são mantidos
nas respectivas fatos como **dimensões degeneradas**.

**Totais:** aproximadamente **541.900 linhas nas fatos** após o seed (até **591.900** com o lote
máximo de streaming) e **27.920 linhas nas dimensões**.

Históricos SCD representam mudanças de atributos de negócio — não são cópias de segurança nem
fotografias integrais do banco.

---

## 4. Invariantes de negócio

Estas regras orientam simultaneamente a **geração** dos dados e os **testes** de qualidade. Elas
são a definição de "dado coerente" neste projeto.

1. Todo item de pedido referencia um pedido e um SKU existentes.
2. O total do pedido reconcilia itens, descontos, frete, impostos simulados e arredondamentos.
3. Uma captura financeira nunca excede o valor autorizado sem uma nova autorização válida.
4. A soma dos reembolsos nunca excede o valor capturado.
5. Uma remessa não contém quantidade superior à quantidade vendida e ainda não enviada.
6. O recebimento de compra não supera a quantidade solicitada, exceto em cenários de teste
   explicitamente marcados.
7. Todo movimento de estoque possui origem de negócio identificável — compra, venda, devolução,
   transferência ou ajuste.
8. Reservas liberadas, expiradas ou consumidas não permanecem no saldo reservado.
9. Estados de pedidos, pagamentos, remessas e chamados seguem transições válidas.
10. Datas respeitam causalidade: criação, pagamento, separação, envio, entrega e eventual
    reembolso.
11. Períodos de vigência de registros SCD tipo 2 não se sobrepõem para a mesma chave natural.
12. Cupons somente são utilizados dentro da vigência e segundo suas regras de elegibilidade.

---

## 5. Contrato do evento de estoque

`inventory_movements` é a única tabela do projeto tratada como **livro de eventos**: aceita somente
inserções. Correções são novos eventos compensatórios, nunca `UPDATE` ou `DELETE` de um movimento
já publicado. É esse contrato que torna possível o
[fluxo de streaming](streaming.md).

### 5.1 Estrutura mínima

| Coluna | Tipo proposto | Responsabilidade |
|---|---|---|
| `movement_id` | `uuid` | Chave primária estável do evento. |
| `event_sequence` | `bigint generated always as identity` | Ordenação técnica local e paginação. |
| `idempotency_key` | `varchar(100)` | Chave única que impede aplicação duplicada. |
| `warehouse_id` | `bigint` | Armazém afetado. |
| `product_variant_id` | `bigint` | SKU afetado. |
| `movement_type` | `varchar(32)` | Tipo controlado do movimento. |
| `quantity_delta` | `integer` | Variação assinada e diferente de zero. |
| `unit_cost` | `numeric(14,4)` | Custo unitário quando aplicável. |
| `source_type` | `varchar(32)` | Processo de origem: compra, venda, ajuste. |
| `source_id` | `varchar(64)` | Identificador do registro que causou o movimento. |
| `correlation_id` | `uuid` | Agrupa eventos relacionados, especialmente transferências. |
| `causation_id` | `uuid` | Identifica o evento ou comando causador. |
| `aggregate_version` | `bigint` | Ordem do evento para um par armazém/SKU. |
| `occurred_at` | `timestamptz` | Momento de negócio em que o movimento ocorreu. |
| `recorded_at` | `timestamptz` | Momento em que a origem registrou o evento. |
| `schema_version` | `smallint` | Versão do contrato do evento. |
| `metadata` | `jsonb` | Contexto adicional, opcional e limitado em tamanho. |

### 5.2 Constraints e índices mínimos

- `PRIMARY KEY (movement_id)`;
- `UNIQUE (event_sequence)`;
- `UNIQUE (idempotency_key)`;
- `UNIQUE (warehouse_id, product_variant_id, aggregate_version)`;
- `CHECK (quantity_delta <> 0)`;
- `CHECK` para tipos de movimento aceitos e coerência entre tipo e sinal da quantidade;
- índice em `(recorded_at, event_sequence)` para leitura incremental;
- índice em `(source_type, source_id)` para linhagem e reconciliação;
- índice parcial em `correlation_id` quando preenchido;
- limite de tamanho para `metadata`, evitando que JSON arbitrário comprometa o orçamento de
  armazenamento.

### 5.3 Tipos de evento

| Tipo | Sinal | Observação |
|---|---|---|
| `purchase_receipt` | Positivo | Entrada por recebimento de compra. |
| `customer_return` | Positivo | Entrada por devolução de cliente. |
| `sale_dispatch` | Negativo | Saída por venda expedida. |
| `supplier_return` | Negativo | Saída por devolução ao fornecedor. |
| `transfer_out` / `transfer_in` | Negativo / positivo | Sempre em par, com o mesmo `correlation_id`. |
| `adjustment_in` / `adjustment_out` | Positivo / negativo | Sempre com motivo documentado. |

### 5.4 Garantias transacionais

- A transação da origem insere o movimento e atualiza `inventory_balances` **atomicamente**.
- O CDC publica apenas *commits* confirmados.
- Consumidores tratam entrega *at least once* por meio de `idempotency_key`, sem presumir
  processamento exatamente uma vez pelo transporte.

---

## 6. Camadas no armazém

O `warehouse_db` concentra as camadas analíticas. A quantidade e a nomenclatura definitivas
dependem da decisão **D02** ([decisões pendentes](adr/README.md)).

| Camada | Materialização proposta | Objetos estimados |
|---|---|---:|
| `raw` | Réplicas geradas pelo Airbyte a partir de `oltp` | Até 40 |
| `raw_legacy` | Réplica do *snapshot* imutável de `legacy` | Até 40 |
| `staging` | Views dbt das duas origens | Até 80 |
| `trusted` | Views ou modelos intermediários dbt | Variável |
| `analytics` | Tabelas dimensionais | 26 |
| `quarantine` | Registro genérico de rejeições do tratamento legado | 1 |
| `governance` | Objetos de catálogo e controle — escopo pendente (**D14**) | A definir |

Somando origens e armazém, o projeto prevê **até 187 tabelas persistidas conhecidas**. A contagem
não inclui views, tabelas internas do Airbyte, artefatos técnicos do dbt nem objetos adicionais do
schema `governance`. O número físico final depende das materializações aprovadas e está sujeito ao
[orçamento de armazenamento](capacidade_e_recuperacao.md).
