# ADR-0013 — Nomear objetos de banco com prefixo por tipo

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D13 |

## Contexto

O [`CLAUDE.md`](../../CLAUDE.md) §3 já pratica prefixos por tipo, mas com a ressalva explícita de
que o padrão está "sujeito à decisão **D13**". A Etapa 3 cria as 40 tabelas transacionais e as
migrações que as versionam; a Etapa 5 cria os modelos dbt que as consomem. Renomear objeto depois
custa migração, modelo, teste e documentação — a convenção precisa estar fechada antes do primeiro
`CREATE TABLE`.

O ponto em disputa é a redundância: com sete schemas nomeados por função
([ADR-0008](0008-schemas-do-armazem.md)), o schema já informa a camada, e `analytics.dim_customer`
repete a informação duas vezes.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Prefixo por tipo** (`stg_`, `dim_`, `fact_`) | Convenção dominante na comunidade dbt, o que alinha o projeto ao material de referência; a ordenação alfabética agrupa por tipo; dentro de um `JOIN` com *aliases*, o papel de cada tabela continua legível sem consultar o schema | Redundância com o nome do schema |
| Sem afixos, separação apenas por schema | Nomes curtos; elimina a redundância; o schema é a fonte única da camada | Em consulta com CTEs e *aliases*, a pista do papel desaparece justamente onde ela é mais necessária; ferramentas de linhagem ficam mais ambíguas; diverge da convenção da maior parte do material de dbt |
| Sufixo por tipo (`customer_dim`) | Agrupa alfabeticamente por assunto, o que ajuda quando o catálogo cresce; é a convenção Kimball clássica | Minoritária nas ferramentas modernas; obrigaria a reescrever o §3 do `CLAUDE.md` e a divergir das fontes usadas |
| Prefixo apenas fora de `analytics` | Reduz a redundância onde ela incomoda, mantendo a desambiguação em `staging`, que é onde há colisão real entre origens | Regra com exceção é regra aplicada errado. Com geração assistida produzindo 40 tabelas de uma vez (risco **R14**), a exceção se propaga antes de alguém notar |

## Decisão

**Prefixo por tipo, em todos os schemas.** A convenção do `CLAUDE.md` §3 deixa de ser provisória e
passa a ser norma:

| Objeto | Padrão | Exemplo |
|---|---|---|
| Tabela transacional | plural, sem prefixo | `order_items` |
| Modelo de *staging* | `stg_<origem>__<tabela>` | `stg_retail__order_items` |
| Dimensão | `dim_` + singular | `dim_customer` |
| Fato | `fact_` + grão no singular | `fact_sales_order_item` |

A camada **nunca** vira prefixo de nome: a separação de camada é o schema, e duplicá-la no nome é o
único caso em que a redundância deixa de ser tolerável e passa a ser erro.

As **views de consumo** não recebem prefixo de tipo — são nomeadas pela pergunta de negócio que
respondem, conforme o [ADR-0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md).

## Consequências

- **Positivas:** o §3 do `CLAUDE.md` perde a ressalva e vira norma verificável; a geração das 40
  tabelas e dos modelos dbt passa a ter alvo único, conferível por teste estrutural em vez de
  revisão visual.
- **Negativas:** a redundância entre schema e prefixo é aceita em definitivo, e nomes como
  `analytics.fact_sales_order_item` ficam longos. O custo é de leitura, não de correção.
- **Paridade com o GCP:** nomes de tabela são idênticos no BigQuery e o schema vira *dataset*.
  Nada a traduzir.
- **Documentos a atualizar:** [`CLAUDE.md`](../../CLAUDE.md) §3 — remover a ressalva de **D13**;
  [Modelo de Dados](../modelo_de_dados.md) §6.
