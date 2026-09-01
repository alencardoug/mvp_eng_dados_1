# Qualidade de Dados

> **O que vive aqui:** a estratégia de testes e de reconciliação por camada — o que é verificado,
> onde e com qual ferramenta.
>
> **O que não vive aqui:** as invariantes de negócio que os testes traduzem (ver
> [Modelo de Dados](modelo_de_dados.md#4-invariantes-de-negócio)); as regras de tratamento do
> legado (ver [Origem Legada](origem_legada.md)); a definição de pronto de cada entrega (ver
> [`CLAUDE.md`](../CLAUDE.md)).

| Campo | Informação |
|---|---|
| Ferramentas | `dbt` (testes nativos) + `dbt-expectations` + `pytest` para o código Python |
| Decisão | [ADR-0003](adr/0003-stack-airbyte-dbt-airflow.md) |
| Versão | 1.0 |
| Última revisão | 01/09/2026 |

---

## 1. Princípio

Teste de dados não é teste de software. O código pode estar correto e os dados, errados — e o
inverso também acontece. Por isso o projeto mantém duas famílias:

| Família | Ferramenta | Pergunta que responde |
|---|---|---|
| Testes de código | `pytest` | A função de conversão faz o que promete? |
| Testes de dados | `dbt` + `dbt-expectations` | O conteúdo das tabelas satisfaz as regras? |

**Falha de teste interrompe o pipeline.** Um dado errado que segue adiante custa mais caro do que
uma execução interrompida.

---

## 2. Banco transacional

- chaves primárias e estrangeiras válidas;
- unicidade de chaves naturais selecionadas;
- `NOT NULL`, `CHECK` e índices coerentes com o uso;
- valores monetários com precisão decimal — **nunca `float`**;
- *timestamps* com fuso horário quando representarem eventos;
- transições de estado validadas.

Boa parte destes controles é declarada no próprio schema: quando o banco pode garantir a regra, a
regra vive no banco, não em um teste posterior.

---

## 3. Ingestão e camada `raw`

- contagem de registros por tabela e por execução;
- controle de registros inseridos, alterados e removidos;
- captura dos metadados de sincronização do Airbyte;
- estratégia explícita de carga completa contra incremental por tabela (decisão pendente **D20**);
- tratamento documentado de exclusões na origem e de atualizações tardias (**D21**).

---

## 4. Transformação e camada dimensional

- testes nativos do dbt: `unique`, `not_null`, `relationships`, `accepted_values`;
- testes de `dbt-expectations` para regras que os nativos não cobrem — faixas de valores,
  distribuição, cardinalidade, comparação entre colunas;
- testes customizados para valores financeiros e para intervalos SCD que não podem se sobrepor;
- reconciliação de pedidos, pagamentos, estoque e remessas;
- testes de atualidade dos dados;
- documentação de fontes, modelos e colunas;
- exposição da linhagem da origem até as views de consumo.

Cada uma das doze [invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) tem pelo
menos um teste correspondente. Uma invariante sem teste é uma invariante que não existe.

---

## 5. Tratamento do legado

- testes unitários para cada regra de conversão;
- comparação entre o resultado e o manifesto esperado do gerador — o manifesto é oráculo, nunca
  entrada da transformação;
- preservação de valor original, valor tratado e regra aplicada;
- idempotência: reprocessar o mesmo `snapshot_id` não duplica registros;
- chave composta de procedência, impedindo colisão entre origens;
- reconciliação entre extraídos, aceitos, corrigidos, rejeitados e empilhados;
- bloqueio do empilhamento quando a regra de correção for ambígua;
- relatório de qualidade por tabela, coluna, tipo de erro e resultado do tratamento.

---

## 6. Streaming de estoque

- unicidade de `movement_id` e de `idempotency_key`;
- sequência sem duplicidade por armazém/SKU;
- validação do sinal da quantidade conforme `movement_type`;
- reconciliação de `inventory_balances` com o saldo inicial somado a `quantity_delta`;
- correspondência entre os dois lados de uma transferência;
- garantia de que reversões sejam eventos compensatórios, e não alterações do evento original;
- reprocessamento do mesmo lote sem duplicar efeitos na camada analítica;
- medição do atraso entre `occurred_at`, `recorded_at` e o processamento;
- reconciliação entre eventos confirmados na origem, capturados pelo CDC e aplicados pelo
  consumidor.

---

## 7. Reconciliação entre camadas

A reconciliação é o teste que dá sentido a todos os outros: prova que nada foi perdido nem criado
no caminho.

| Fronteira | O que deve fechar |
|---|---|
| `oltp` → `raw` | Contagem por tabela e por lote |
| `raw_legacy` → tratamento | `extraídos = aceitos + corrigidos + rejeitados` |
| `staging` → `trusted` | Contagem e regras aplicadas, com rejeições rastreáveis |
| `trusted` → `analytics` | Grão declarado e medidas somadas |
| *Batch* + streaming → view de saldo | Saldo unificado igual à soma dos deltas sobre o saldo inicial |

Nenhuma etapa descarta registros em silêncio: o que não passa vai para quarentena com motivo
registrado.

---

## 8. Geração assistida dos testes

São 40 tabelas na origem, mais o legado e a camada dimensional. Escrever manualmente cada teste de
unicidade, não nulo e relacionamento seria trabalho mecânico de baixo retorno.

A geração dos arquivos de teste é assistida por IA a partir do DDL e das invariantes documentadas —
inclusive dos testes menos óbvios, como "a data de pagamento nunca é anterior à data da compra" ou
"`status_logistica` só aceita este conjunto de valores".

O que **não** é delegado: decidir quais regras existem, revisar o que foi gerado e aceitar o
resultado. Testes gerados e não revisados dão falsa sensação de cobertura — risco **R14** do
[Registro de Riscos](riscos.md).
