# Glossário de Negócio

> **O que vive aqui:** os conceitos do domínio — o que significa "cliente ativo", como se calcula
> "lucro bruto", o que conta como "churn". Um arquivo por conceito, interligados entre si.
>
> **O que não vive aqui:** termos técnicos de engenharia de dados (ver
> [Glossário Técnico](../glossario.md)); a descrição de tabelas e colunas (ver
> [Dicionário de Dados](../dicionario_de_dados.md)).

| Campo | Informação |
|---|---|
| Domínio | Marketplace de varejo *omnichannel* |
| Consumido por | dbt, via blocos `{% docs %}` |
| Situação | **Vazio** — preenchido a partir da Etapa 5 |
| Última revisão | 01/09/2026 |

---

## 1. Por que existe

Uma métrica sem definição escrita é uma métrica que cada pessoa calcula de um jeito. Este glossário
é o lado de negócio do catálogo: define os conceitos uma única vez, e o dbt os importa para dentro
da documentação técnica.

O resultado, ao rodar `dbt docs generate`, é um portal em que a linhagem técnica e o conceito de
negócio são navegáveis juntos — a coluna aponta para a definição, e a definição aponta para as
colunas que a implementam.

## 2. Convenção

- **Um arquivo por conceito**, nomeado em português: `cliente_ativo.md`, `lucro_bruto.md`.
- Cada arquivo contém **um bloco `{% docs %}`** cujo nome é um identificador técnico em inglês
  (`active_customer`, `gross_profit`), conforme a convenção de idioma do
  [`CLAUDE.md`](../../CLAUDE.md). O conteúdo é em português.
- Conceitos se referenciam com links relativos: a definição de *churn* aponta para a de *cliente
  ativo*, e vice-versa.
- Todo conceito declara **como é calculado** e **em qual modelo dbt** está implementado.

### 2.1 Formato

O bloco abaixo é um exemplo **válido e vivo**: o dbt o interpreta normalmente, com o nome
`exemplo_formato`, e ele serve de modelo para os demais arquivos.

{% docs exemplo_formato %}

**Cliente ativo** é o cliente com pelo menos um pedido concluído nos últimos 180 dias, contados a
partir de `as_of_date`.

- **Cálculo:** contagem distinta de `customer_id` em pedidos com estado final `concluido` dentro da
  janela.
- **Implementado em:** `dim_customer`, coluna `is_active`.
- **Relacionado:** churn, recorrência de compra.

{% enddocs %}

O diretório é declarado em `docs-paths` no `dbt_project.yml`.

---

## 3. Conceitos a definir

Nenhum conceito foi definido ainda. Os que a modelagem já exige:

| Conceito | Onde será usado | Etapa |
|---|---|---|
| Cliente ativo | `dim_customer` | 5 |
| Recorrência de compra | `dim_customer`, `fact_sales_order_item` | 5 |
| Carrinho abandonado | `carts`, análise de conversão | 5 |
| Taxa de conversão | Views de consumo | 5 |
| Ticket médio | `fact_sales_order_item` | 5 |
| Lucro bruto | `fact_sales_order_item`, `fact_purchase_order_item` | 6 |
| Ruptura de estoque | `fact_inventory_movement`, saldo em tempo real | 7 |
| Cobertura de estoque | Saldo em tempo real | 7 |
| Prazo de entrega prometido e realizado | `fact_shipment_item`, `delivery_events` | 8 |
| Churn | `dim_customer` | 9 |
| Recompra pós-atendimento | `fact_support_ticket_event` | 9 |

Cada definição é escrita na etapa em que o modelo correspondente é construído — nunca depois.
