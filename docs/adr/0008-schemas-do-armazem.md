# ADR-0008 — Fixar os schemas do armazém e separar estágio de schema

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 03/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D02 |

## Contexto

A quantidade e os nomes das camadas condicionam as Etapas 5 a 7, a decisão **D09** — cujas regras
de acesso são indexadas por camada — e o padrão de nomenclatura **D13**. Nenhum modelo dbt pode ser
escrito antes disso.

A tabela de camadas da [Arquitetura](../arquitetura.md#2-camadas-de-dados) misturava dois eixos:
`raw` e `raw_legacy` são o mesmo **estágio do fluxo** com contratos distintos, enquanto
`quarantine` e `governance` não são estágios — são destino e apoio, ortogonais ao fluxo. A pergunta
"quantas camadas existem?" não tinha resposta estável porque estava mal formulada.

Havia ainda uma lacuna: as *views de consumo* apareciam como linha na tabela de camadas, sem schema
próprio.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Nomes descritivos** | O nome declara a função: `trusted` informa que as regras de negócio já foram aplicadas e validadas | Exige explicar a convenção a quem chega do vocabulário medalhão |
| Medalhão — `bronze`, `silver`, `gold` | Convenção difundida e reconhecível de imediato | Nomeia posição, não função: `silver` só informa que existe algo antes e algo depois. E não tem contrapartida nomeada no GCP — os datasets recebem o nome que o projeto der de todo jeito, então a ambiguidade apenas atravessa para a nuvem |
| Conjunto reduzido, sem `trusted` | Um schema a menos para manter | Elimina o lugar onde o legado tratado é empilhado ao principal: ou `staging` deixa de ser apenas tipagem, ou `analytics` passa a fazer conformação. Custa a Etapa 10 |

## Decisão

O armazém tem **sete schemas**, com um oitavo condicionado a decisão futura:

`raw` · `raw_legacy` · `staging` · `trusted` · `analytics` · `consumption` · `quarantine`

**`governance` não é declarado aqui.** O seu escopo é a decisão **D14**, na Etapa 11, e uma das
opções em avaliação é não existir schema algum. Declarar agora um schema de conteúdo indefinido é
o que o risco **R14** — e o princípio **P6** — pedem para evitar.

Os schemas se distribuem em dois eixos, que passam a ser declarados separadamente:

| Eixo | Schemas | Natureza |
|---|---|---|
| Estágios do fluxo | `raw` e `raw_legacy` · `staging` · `trusted` · `analytics` · `consumption` | Percorridos em ordem; nenhum lê de um posterior |
| Fora do fluxo | `quarantine` · `governance` (se D14 aprovar) | Destino e apoio; não são atravessados |

`raw` e `raw_legacy` ocupam o mesmo estágio com contratos incompatíveis — lote incremental e
descartável contra *snapshot* imutável de retenção permanente — e por isso permanecem separados: um
schema não carrega duas regras de retenção contraditórias sem que alguém erre.

### `consumption` — o schema acrescentado

As views de consumo passam a ter schema próprio, por duas razões independentes:

1. A [Política de Governança](../governanca_de_dados.md#7-regras-de-acesso-por-camada) promete que
   o perfil de análise só enxerga as views. Com as views dentro de `analytics`, isso exige conceder
   `USAGE` no schema e `SELECT` view a view, negando as tabelas — frágil, e é exatamente o que a
   Etapa 11 se compromete a **testar**.
2. No BigQuery, uma *authorized view* precisa viver em um dataset separado das tabelas que lê. No
   mesmo dataset, conceder acesso entrega as tabelas junto e a autorização perde a função. A
   separação não é conforto local: é a forma que a fase GCP exige.

## Consequências

- **Positivas:** a contagem de camadas deixa de ser ambígua; o teste de acesso da Etapa 11 vira uma
  concessão única sobre um schema; nada é renomeado, então a varredura na documentação é pequena.
- **Negativas:** um schema a mais para criar e conceder na Etapa 5. Se **D25** escolher
  `dbt snapshot` como mecanismo de SCD tipo 2, será preciso um schema de destino adicional — a
  decisão continua sendo de D25, e este ADR registra a possibilidade para que D02 não seja reaberta.
- **Paridade com o GCP:** um dataset por schema. `consumption` é o dataset das *authorized views*,
  padrão canônico do BigQuery.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §2, §5 e §7;
  [Modelo de Dados](../modelo_de_dados.md) §6;
  [Política de Governança](../governanca_de_dados.md) §7.
