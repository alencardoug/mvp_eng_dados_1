# ADR-0016 — Materializar por camada, com incremental como exceção justificada

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D23 |

## Contexto

A materialização decide, para cada modelo dbt, se o resultado é recalculado a cada leitura, gravado
inteiro a cada execução, ou combinado com o que já existe. É a escolha que mais afeta correção — não
desempenho — porque o modelo incremental é a única das três que carrega **estado entre execuções**.

O [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md) retirou a pressão de volume do
ambiente local. Sem ela, o incremental deixa de se justificar por custo e passa a precisar de
justificativa própria.

A fundamentação completa — as cinco materializações, as quatro estratégias de incremental, os quatro
modos de falhar em silêncio e os quatro critérios de robustez — está em
[Materialização no dbt](../materializacao.md), escrita para que esta decisão pudesse ser tomada com
conhecimento de causa.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Views + tabelas + um incremental blindado** | Aplica o critério que a fundamentação deriva: três dos quatro testes de robustez apontam para `table`, e só o custo em escala aponta para `incremental`. O único incremental fica onde ele é **semântico** — `fact_inventory_movement` é alimentada por um fluxo contínuo cujo propósito é não reprocessar o passado | Um modelo com estado a manter e a testar, quando zero seria mais seguro |
| Incremental blindado nas nove fatos | Exercita em nove lugares o padrão que mais causa incidente em produção; nenhuma surpresa quando o volume subir no GCP | Nove blocos `is_incremental()` e nove testes de reconciliação para revisar, sem pressão de desempenho que os justifique — complexidade sem valor demonstrável, vedada pelo Termo §8 |
| Views + tabelas, zero incremental | Pontua melhor em três dos quatro critérios: todo *rebuild* é completo, determinístico e sem estado | A fato alimentada por *streaming* seria reconstruída por inteiro a cada execução, o que contradiz o propósito do fluxo contínuo do [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) |
| Tabelas em todas as camadas | Facilita inspecionar o estado intermediário, útil para depurar o tratamento do legado | Mascara erro de dependência: tabela desatualizada não reclama, apenas responde errado |

## Decisão

| Camada | Materialização | Razão |
|---|---|---|
| `staging` | `view` | Só renomeia e tipa; reexecutar é barato e nunca serve dado velho |
| `trusted` | `table` | Aplica invariantes e trata o legado; é lógica pesada e muito referenciada |
| `analytics` | `table` | O datamart é lido por gente e por BI; o custo se paga uma vez no *build* |
| `consumption` | `view` | O contrato é interface, não cópia |

**Exceção única:** `fact_inventory_movement` é `incremental` com estratégia `merge`, e vem com as
quatro proteções obrigatórias — sem elas a exceção não é concedida:

1. `unique_key` declarada no identificador do evento;
2. filtro por **tempo de evento**, com margem de atraso, nunca por tempo de carga;
3. `--full-refresh` agendado e registrado no plano;
4. teste de reconciliação que compara a tabela incremental com o resultado da reconstrução completa.

A regra geral que decorre disto: **`incremental` é exceção justificada, nunca padrão.**

## Consequências

- **Positivas:** uma única fonte de estado no projeto inteiro, e ela é testada contra a
  reconstrução completa; a razão da exceção é semântica e está escrita, então revisá-la no futuro
  não exige reconstituir o raciocínio.
- **Negativas:** a decisão foi tomada **sem** pressão de volume, por consequência direta do
  ADR-0014. Se na fase GCP as demais fatos precisarem de incremental, esta decisão será revista —
  e o motivo será volume, que hoje não existe. Fica registrado para que a revisão não seja lida como
  erro de julgamento.
- **Paridade com o GCP:** `view` e `table` funcionam igual no BigQuery. O incremental muda de
  estratégia — `merge` local, `insert_overwrite` particionado no BigQuery —, diferença configurável
  por perfil do dbt, mas que **precisa** ser traduzida e não replicada.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §2;
  [Qualidade de Dados](../qualidade_de_dados.md) — o teste de reconciliação da exceção;
  [Materialização no dbt](../materializacao.md) §4 — marcar a decisão como tomada.
