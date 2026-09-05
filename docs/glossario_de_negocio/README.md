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
| Consumido por | dbt, via blocos `docs … enddocs` |
| Situação | 16 perguntas de negócio; 16 conceitos, e a lista fechada |
| Última revisão | 05/09/2026 |

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
- Cada arquivo contém **um bloco `docs … enddocs`** cujo nome é um identificador técnico em inglês
  (`active_customer`, `gross_profit`), conforme a convenção de idioma do
  [`CLAUDE.md`](../../CLAUDE.md). O conteúdo é em português.
- Conceitos se referenciam com links relativos: a definição de *churn* aponta para a de *cliente
  ativo*, e vice-versa.
- Todo conceito declara **como é calculado** e **em qual modelo dbt** está implementado.

### 2.1 Formato

O bloco abaixo é um exemplo **válido e vivo**: o dbt o interpreta normalmente, com o nome
`exemplo_formato`, e ele serve de modelo para os demais arquivos.

> A abertura do bloco não aparece escrita em nenhum outro lugar deste arquivo, nem entre crases: o
> dbt varre o `.md` inteiro procurando a marcação, e uma menção em texto vira um bloco sem
> fechamento — que derruba o `dbt parse` com "nested tags".

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

## 3. Conceitos

| Conceito | Onde é usado | Etapa | Situação |
|---|---|---|---|
| [Receita líquida](receita_liquida.md) | `fact_sales_order_item` | 5 | **Escrito** |
| [Ticket médio](ticket_medio.md) | View de consumo de P02 | 5 | **Escrito** |
| [Cliente ativo](cliente_ativo.md) | `dim_customer` | 5 | **Escrito** |
| [Recorrência de compra](recorrencia_de_compra.md) | `dim_customer`, `fact_sales_order_item` | 5 | **Escrito** |
| [Carrinho abandonado](carrinho_abandonado.md) | `fact_cart_event` | 5 | **Escrito** |
| [Taxa de conversão](taxa_de_conversao.md) | View de consumo de P07 | 5 | **Escrito** |
| [Lucro bruto](lucro_bruto.md) | Views de consumo de P08 | 6 | **Escrito** |
| [Custo do produto vendido](custo_do_produto_vendido.md) | `fact_inventory_movement` | 6 | **Escrito** |
| [Giro de estoque](giro_de_estoque.md) | View de consumo de P11 | 6 | **Escrito** |
| [Ruptura de estoque](ruptura_de_estoque.md) | View de consumo de P12 | 7 | **Escrito** |
| [Cobertura de estoque](cobertura_de_estoque.md) | View de consumo de P12 | 7 | **Escrito** |
| [Entrega no prazo](entrega_no_prazo.md) | View de consumo de P13, `fact_shipment_item` | 8 | **Escrito** |
| [Prazo prometido](entrega_no_prazo.md) | `shipments`, `dim_carrier` | 8 | **Escrito** |
| [Ciclo de entrega](ciclo_de_entrega.md) | View de consumo de P14 | 8 | **Escrito** |
| [Churn](churn.md) | `dim_customer` | 9 | **Escrito** |
| [Recompra pós-pedido](recompra_pos_pedido.md) | View de consumo de P16 | 9 | **Escrito** |

Dois arquivos carregam mais de um bloco, pelo mesmo motivo nos dois casos: o de ruptura carrega
**saldo disponível**, e o de entrega no prazo carrega **prazo prometido**. São medidas que só fazem
sentido uma ao lado da outra, e separá-las faria o leitor abrir dois arquivos para entender um
conceito.

*Recompra pós-atendimento* estava previsto aqui e não foi escrito com esse nome: o
[ADR-0036](../adr/0036-recompra-ancorada-no-pedido.md) mudou a âncora da medida do chamado para o
pedido, e com ela o nome — é a [recompra pós-pedido](recompra_pos_pedido.md) acima.

Cada definição é escrita na etapa em que o modelo correspondente é construído — nunca depois.

---

## 4. Perguntas de negócio

O [ADR-0018](../adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) fixou o método: **as
perguntas vêm antes do primeiro modelo de `analytics`.** São elas que determinam quais medidas cada
fato carrega e quais views de consumo existem — e não o contrário.

**As 16 perguntas estão em [`perguntas_de_negocio.md`](perguntas_de_negocio.md)**, redigidas na
abertura da Etapa 5 porque usam o vocabulário que este glossário define. Cada uma resulta em:

- as **medidas** que o fato precisa carregar, classificadas como aditiva, semiaditiva ou não
  aditiva;
- as **dimensões conformadas** que a atendem;
- uma **view de consumo** nomeada pela pergunta, com `contract: enforced`.

Uma pergunta é concreta quando nomeia a métrica, o recorte e o período — *"qual a margem por
categoria e canal no trimestre?"* é pergunta; *"analisar vendas"* não é.

Escrevê-las antes do SQL já pagou: a lista revelou que o funil de conversão não tinha fato onde
pousar, e a lacuna virou o [ADR-0028](../adr/0028-fato-de-carrinho-para-o-funil.md) antes de custar
retrabalho.
