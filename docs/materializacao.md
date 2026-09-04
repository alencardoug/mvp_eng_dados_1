# Materialização no dbt

> **O que vive aqui:** o que é uma materialização, as estratégias disponíveis, o que cada uma custa
> e o que cada uma protege — e o critério para escolher entre elas em cada camada.
>
> **O que não vive aqui:** a estratégia de testes que roda sobre os modelos (ver
> [Qualidade de Dados](qualidade_de_dados.md)); os schemas e as camadas (ver
> [ADR-0008](adr/0008-schemas-do-armazem.md)); a decisão adotada, que é registrada em ADR quando
> **D23** for fechada.

| Campo | Informação |
|---|---|
| Natureza | Documento de fundamentação — apoia a decisão **D23** |
| Decisão que sustenta | **D23**, fechada pelo [ADR-0016](adr/0016-materializacao-por-camada.md) |
| Versão | 1.0 |
| Última revisão | 04/09/2026 |

---

## 1. O que uma materialização é

Todo modelo dbt é um `SELECT`. A **materialização** é a estratégia que o dbt usa para transformar
esse `SELECT` em um objeto no banco: ele envolve a sua consulta no DDL apropriado e decide o que
fazer com o objeto que já existe.

O mesmo SQL, com materializações diferentes, produz coisas diferentes:

```sql
-- models/analytics/fact_sales_order_item.sql
select ... from {{ ref('trusted_order_items') }}
```

| Materialização | DDL gerado, em essência | O que sobra no banco |
|---|---|---|
| `view` | `CREATE OR REPLACE VIEW … AS <select>` | Uma definição. Nenhum dado. |
| `table` | `CREATE TABLE … AS <select>` (recriando do zero) | Uma cópia física, congelada no último `run`. |
| `incremental` | `CREATE TABLE` na primeira vez; depois `MERGE`/`INSERT` só do que mudou | Uma cópia física com estado acumulado. |
| `ephemeral` | Nada — o `SELECT` vira CTE dentro de quem o referencia | Nenhum objeto. |
| `materialized_view` | `CREATE MATERIALIZED VIEW …` | Cópia física atualizada pelo próprio banco. |
| `snapshot` | Tabela com `valid_from`/`valid_to`, atualizada por comparação | Histórico versionado (SCD tipo 2). |

A escolha responde a três perguntas, nesta ordem: **quando o dado precisa estar correto**, **quanto
do passado precisa ser preservado** e **quanto do trabalho pode ser refeito sem consequência**.

---

## 2. As cinco estratégias, uma a uma

### 2.1 `view` — a consulta é reexecutada a cada leitura

Não guarda dado. Quem consulta a view executa a transformação naquele instante.

**Protege contra:** dado velho. Uma view **nunca** está desatualizada — é impossível consultar uma
view e obter o resultado de ontem. Também não ocupa espaço e não tem custo de build.

**Custa:** processamento a cada consulta. Views empilhadas sobre views multiplicam esse custo, e uma
cadeia de cinco níveis pode ficar lenta mesmo com pouco dado.

**Onde é a escolha corporativa:** camadas intermediárias de baixa complexidade, onde o valor está em
nunca servir dado obsoleto e a consulta final é sempre feita por outro modelo, não por gente.

### 2.2 `table` — recriada inteira a cada execução

Apaga e reconstrói. Simples, determinística, sem estado.

**Protege contra:** deriva. Toda execução parte do zero, então não existe "linha que ficou de uma
carga antiga com a lógica velha". É a materialização mais fácil de raciocinar e a mais difícil de
corromper: se a lógica muda, a tabela inteira reflete a lógica nova.

**Custa:** tempo e recurso proporcionais ao volume total, toda vez. Em produção com bilhões de
linhas, refazer tudo diariamente é inviável — e é exatamente por isso que o `incremental` existe.

**Onde é a escolha corporativa:** a camada de consumo. O datamart é lido por muita gente e por
ferramenta de BI; pagar o custo uma vez no build, e não a cada consulta, é a decisão certa.

### 2.3 `incremental` — processa só o que mudou

Na primeira execução cria a tabela. Nas seguintes, executa a consulta filtrada pelo bloco
`{% if is_incremental() %}` e combina o resultado com o que já existe.

Não é uma estratégia, são quatro — e a diferença entre elas é onde mora a maior parte dos bugs de
pipeline em produção:

| Estratégia | Como combina | Quando é correta |
|---|---|---|
| `append` | Só insere | Fatos puramente imutáveis — um evento nunca é corrigido. Duplica se você reprocessar. |
| `merge` | `MERGE` por `unique_key`: atualiza o que existe, insere o resto | O caso geral. Suporta reprocessamento e correção tardia. |
| `delete+insert` | Apaga as chaves afetadas e reinsere | Bancos sem `MERGE` eficiente; efeito equivalente, menos atômico. |
| `insert_overwrite` | Substitui partições inteiras | O padrão em BigQuery: reprocessa um dia ou um mês por completo, sem tocar no resto. |

**Protege contra:** custo. É a única forma de manter uma fato de alto volume atualizada com
frequência sem reprocessar história inteira todo dia.

**Custa:** correção. É a materialização com mais formas de dar errado silenciosamente:

- **Filtro por tempo de carga em vez de tempo de evento.** Um registro que chega atrasado tem
  `event_time` de ontem; se o filtro incremental usa `event_time > (select max(event_time) …)`, ele
  nunca entra. Some sem erro nenhum.
- **`unique_key` errada ou ausente.** Com `append`, reprocessar duplica. Com `merge` e chave errada,
  atualiza a linha errada.
- **Mudança de lógica não retroage.** Corrigir a regra de cálculo só afeta as linhas novas; as
  antigas continuam com o valor velho até alguém rodar `--full-refresh`.
- **Estado divergente entre ambientes.** A tabela em desenvolvimento e a em produção acumularam
  históricos diferentes, e o mesmo código produz resultados diferentes.

Nenhum desses erros aparece com pouco dado. Todos aparecem em produção.

**Onde é a escolha corporativa:** fatos de alto volume, e fatos onde o incremental é **semântico**,
não uma otimização — o caso de `fact_inventory_movement`, alimentada por um fluxo contínuo cujo
propósito é justamente não reprocessar o passado.

### 2.4 `ephemeral` — não existe no banco

O modelo vira CTE dentro de quem o referencia. Serve para organizar SQL sem poluir o schema.

**Custa:** o modelo não é consultável nem testável isoladamente, e o SQL final fica maior e mais
difícil de depurar. Em ambiente corporativo, o uso saudável é raro e localizado — nomear um trecho
reaproveitado, não estruturar uma camada.

### 2.5 `materialized_view` — o banco mantém atualizada

Cópia física que o próprio banco atualiza quando a origem muda. Une frescor de view com leitura de
tabela.

**Custa:** portabilidade. As restrições variam radicalmente entre PostgreSQL (atualização manual via
`REFRESH`, sem incremento automático) e BigQuery (atualização automática, mas com forte limitação de
sintaxe — sem `OUTER JOIN`, sem funções de janela). Um modelo que funciona local pode simplesmente
não ser aceito na nuvem — tensão direta com a paridade do princípio **P4**.

### 2.6 `snapshot` — o caso à parte

Materialização própria para historizar mudança (SCD tipo 2). Já está decidida em **D25** para as
sete dimensões SCD-2 e não compete com as demais.

---

## 3. O que "mais robusto corporativamente" significa aqui

Robustez não é a materialização que roda mais rápido, nem a que consome menos. É a que **falha menos
em silêncio** e a que **sobrevive à mudança**. Quatro critérios, aplicáveis a qualquer modelo:

1. **Reconstrutibilidade.** Consigo apagar tudo e reproduzir o mesmo resultado a partir do código e
   da origem? `view` e `table` sim, sempre. `incremental` só com `--full-refresh` — e apenas se a
   origem ainda tiver a história.
2. **Retroatividade da correção.** Quando a regra muda, o dado antigo acompanha? Em `view` e
   `table`, automaticamente. Em `incremental`, apenas por ação deliberada — e esquecer disso é o
   defeito mais comum em pipelines reais.
3. **Ausência de estado oculto.** O resultado depende só do código e da origem, ou também do que
   ficou de execuções anteriores? Estado oculto é o que faz dois ambientes divergirem sem
   explicação.
4. **Custo de operar em escala.** Reprocessar tudo é viável no volume-alvo? Aqui, localmente, sim.
   Na nuvem, para as fatos maiores, não.

Os três primeiros critérios apontam para `table`. O quarto, e só ele, apontam para `incremental`.
**A regra corporativa que decorre disso: `incremental` é exceção justificada, nunca padrão.** Onde
ele entra, entra com `unique_key` declarada, filtro por tempo de evento com margem de atraso,
`full-refresh` periódico agendado e um teste de reconciliação que compara a tabela incremental com o
resultado da reconstrução completa.

---

## 4. Aplicação a este projeto

O que segue é a análise camada a camada. A escolha foi tomada em 04/09/2026 e está registrada no
[ADR-0016](adr/0016-materializacao-por-camada.md) — inclusive as quatro proteções obrigatórias da
única exceção incremental, que este documento fundamenta mas não decide.

| Camada | Natureza | Materialização coerente com os critérios acima |
|---|---|---|
| `staging` | Renomeia, tipa e limpa. Sem regra de negócio. | `view` — reexecutar é barato, e nunca serve dado velho. |
| `trusted` | Aplica invariantes, deduplicação e tratamento do legado. | `table` se a lógica for pesada e muito referenciada; `view` se for fina. |
| `analytics` | O datamart, lido por gente e por BI. | `table` — o custo se paga uma vez no build. |
| `fact_inventory_movement` | Alimentada pelo streaming, append-only por natureza. | `incremental` com `merge` e `unique_key` no id do evento. |
| `consumption` | Contratos de consumo ([ADR-0018](adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md)). | `view` sobre o datamart — o contrato é a interface, não uma cópia. |

**Paridade com o GCP (P4):** `view` e `table` funcionam igual em PostgreSQL e BigQuery. O
`incremental` muda de estratégia: `merge` local, `insert_overwrite` particionado no BigQuery. Essa
diferença é conhecida e configurável por perfil do dbt — mas precisa estar escrita no ADR, porque é
uma das poucas coisas que não se replicam sem tradução.

---

## 5. Referências

- [dbt — Materializations](https://docs.getdbt.com/docs/build/materializations)
- [dbt — Incremental models e estratégias](https://docs.getdbt.com/docs/build/incremental-models)
- [dbt — Best practices: materializations por camada](https://docs.getdbt.com/best-practices/materializations/1-guide-overview)
- Kimball, R. — *The Data Warehouse Toolkit*, cap. 19 (ETL subsystems 8–13: manutenção de fatos)
