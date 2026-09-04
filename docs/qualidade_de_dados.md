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
| Versão | 1.2 |
| Última revisão | 04/09/2026 |

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

### 2.1 O gerador, e por que o banco é o teste dele

A carga por `COPY` da [Etapa 4](../src/mvp_ed1/generator/) atravessa toda `CHECK`, toda unicidade e
toda chave estrangeira do modelo. Uma linha incoerente não entra: a execução para. Escrever um teste
Python que repita essas mesmas regras seria manter duas opiniões sobre a mesma restrição — e a
segunda opinião estaria sempre atrasada em relação ao modelo.

O que o `pytest` cobre é o que o banco **não** consegue dizer:

| Família | O que verifica |
|---|---|
| Configuração | A declaração do gerador confere com os modelos: tabela ausente, coluna inexistente, peso que esquece um valor de enumeração, piso sem motivo |
| Determinismo | A mesma `seed` com a mesma `as_of_date` produz o mesmo conjunto, comparado por impressão digital; sementes diferentes produzem conjuntos diferentes |
| Cobertura | As 40 tabelas populadas, todo valor de enumeração presente, proporção dentro da tolerância declarada — e o mesmo em um fator vinte vezes menor, que é o que prova que a garantia é do piso e não do volume |
| Invariantes | As doze do [Modelo de Dados §4](modelo_de_dados.md#4-invariantes-de-negócio), sobre o conjunto em memória: sete delas atravessam linhas e passariam pela carga sem serem notadas |
| Privacidade | Nenhum e-mail fora de `example.com`, nenhum documento com aparência de válido ([Geração §7](geracao_de_dados.md#7-privacidade-dos-dados-sintéticos)) |

A suíte roda em `make test` e não depende de banco de pé, exceto a carga, que exige autorização
explícita — um teste não pode ser mais permissivo que o comando que ele testa.

---

## 3. Ingestão e camada `raw`

- contagem de registros por tabela e por execução;
- controle de registros inseridos, alterados e removidos;
- captura dos metadados de sincronização do Airbyte;
- conferência de que cada tabela usa o modo declarado no critério de sincronização
  ([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)) — tabela sem modo declarado é falha de *build*,
  não escolha implícita;
- para as tabelas incrementais, teste de **atualização tardia**: um registro com `updated_at`
  anterior ao último cursor precisa entrar na carga seguinte;
- para a origem transacional, propagação de `deleted_at` até o datamart;
- para a origem legada, detecção de exclusão física por comparação com o *snapshot* anterior.

---

## 4. Transformação e camada dimensional

- testes nativos do dbt: `unique`, `not_null`, `relationships`, `accepted_values`;
- testes de `dbt-expectations` para regras que os nativos não cobrem — faixas de valores,
  distribuição, cardinalidade, comparação entre colunas;
- testes customizados para valores financeiros e para intervalos SCD que não podem se sobrepor —
  vigências de uma mesma chave natural não podem ter interseção nem deixar lacuna
  ([ADR-0017](adr/0017-chaves-substitutas-e-scd.md));
- teste de **grão** por fato: a chave declarada é única, o que prova que o grão é o que se afirma
  ([ADR-0018](adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md));
- verificação de **contrato** nas views de consumo: `contract: enforced` quebra o *build* quando
  colunas, tipos ou obrigatoriedade mudam;
- para `fact_inventory_movement`, único modelo incremental do projeto
  ([ADR-0016](adr/0016-materializacao-por-camada.md)), **reconciliação contra a reconstrução
  completa**: o resultado incremental e o `--full-refresh` precisam ser idênticos;
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
- `source_system` preenchido e dentro do domínio declarado em toda tabela empilhada
  ([ADR-0021](adr/0021-procedencia-no-empilhamento.md));
- cobertura do catálogo: **cada um dos 21 tipos de falha** tem ao menos um registro gerado e um
  resultado esperado ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md)) — tipo sem
  registro é tratamento sem teste;
- reconciliação entre extraídos, aceitos, corrigidos, rejeitados e empilhados;
- bloqueio do empilhamento quando a regra de correção for ambígua;
- relatório de qualidade por tabela, coluna, tipo de erro e resultado do tratamento.

---

## 6. Streaming de estoque

- unicidade de `movement_id` e de `idempotency_key`;
- **duplicata injetada deliberadamente**: reenviar o mesmo evento não pode alterar o saldo. É o
  teste que transforma a idempotência do [ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md)
  de intenção em garantia;
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
