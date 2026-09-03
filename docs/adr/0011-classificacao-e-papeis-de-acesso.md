# ADR-0011 — Fixar os níveis de classificação e os papéis de acesso

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 03/09/2026 |
| Decisor | Owner principal · Líder de Governança |
| Decisão pendente resolvida | D09 |

## Contexto

O princípio **P3** exige que todo campo receba classificação na entrega que o cria, e a Etapa 11
promete papéis de acesso "implementados e **testados**". Nada disso é executável enquanto o
vocabulário de classificação e os papéis não estiverem fixados.

A proposta original da [Política de Governança](../governanca_de_dados.md) tinha dois defeitos.

**O nível `Restrito` não era uma classificação, era uma proibição.** Nenhum campo podia carregá-lo,
porque a seção 3 da própria política já declara que esses dados não existem no projeto. Um nível que
nenhum campo pode ter faz toda classificação oferecer uma opção inválida, e não corresponde a
nenhuma *policy tag* no GCP — não há coluna para etiquetar. Manter a proibição em dois lugares é
ainda uma duplicação, contra o **P8**.

**Faltava um nível para dado não pessoal e mesmo assim fechado.** `unit_cost` em
`inventory_movements` e `purchase_order_items`, condições de fornecedor e margem cairiam em
`Interno` — descrito como "livre no repositório" —, o que é incorreto para um marketplace.

Um terceiro ponto, menor: a proposta misturava idiomas no vocabulário controlado
(`sensitivity: "sensivel"` ao lado de `data_type: "pii"`). Cada valor vira nome de *policy tag* no
BigQuery, portanto é identificador técnico, e o [`CLAUDE.md`](../../CLAUDE.md) §2 já determina o
inglês.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Quatro níveis revisados** — `public`, `internal`, `confidential`, `personal` | Todo nível é atribuível a algum campo real do modelo; a proibição fica com um dono só; vocabulário coerente com as chaves | Reescreve a seção 4 da política antes de qualquer campo existir |
| Proposta original, com `Restrito` | Documenta a fronteira dentro do próprio esquema | Nível inatribuível; duplica a seção 3; sem contrapartida no GCP; deixa custo e margem sem nível adequado |
| Esquema de três níveis | Mais simples de aplicar | Volta a não distinguir dado comercialmente fechado de dado meramente operacional |

## Decisão

### Níveis de classificação

Todo campo de todas as camadas recebe exatamente um valor de `sensitivity`:

| Valor | Definição | Exemplo no modelo |
|---|---|---|
| `public` | Pode ser exposto sem restrição | `product_categories`, contagens agregadas |
| `internal` | Operacional, sem valor sensível | Chaves técnicas, `recorded_at`, identificador de lote |
| `confidential` | Não pessoal, mas de valor comercial | `unit_cost`, condições de fornecedor, margem |
| `personal` | Seria dado pessoal se fosse real | Nome, e-mail, telefone, endereço, documento |

O vocabulário é inglês, como as chaves do bloco `meta:`. `personal` foi preferido a `sensitive`
por declarar **por que** o campo é restrito, que é a razão que governa a regra.

A proibição de dados reais permanece exclusivamente na
[seção 3 da política](../governanca_de_dados.md#3-dados-não-permitidos). Ela não é um nível.

### Papéis de acesso

| Papel | Escreve | Lê | Equivalente na fase GCP |
|---|---|---|---|
| `ingestor` | `raw`, `raw_legacy` | as próprias | Conta de serviço do Airbyte |
| `transformer` | `staging`, `trusted`, `analytics`, `quarantine` | camadas anteriores | Conta de serviço do dbt |
| `streamer` | `analytics` | — | Conta de serviço do Dataflow |
| `analyst` | — | `consumption` apenas | Grupo IAM no dataset das views |
| `auditor` | — | `quarantine` | Grupo IAM de auditoria |

`streamer` é separado de `transformer` porque no Dataflow **é** outra identidade: a separação local
tem contrapartida direta, e uni-las agora obrigaria a separá-las na Etapa 13.

O schema `consumption` ([ADR-0008](0008-schemas-do-armazem.md)) torna o teste da Etapa 11 trivial:
`analyst` recebe `USAGE` e `SELECT` em um schema e nada mais, e o teste é um `SELECT` contra `raw`
que precisa falhar.

## Consequências

- **Positivas:** todo nível é atribuível, o que torna a classificação um exercício real; o controle
  de acesso passa a ser testável por asserção de falha, não por declaração; cada papel tem
  identidade correspondente na nuvem.
- **Negativas:** cinco papéis para criar e manter em um projeto de um só operador — custo aceito
  porque cada um existe na fase GCP de todo modo. A seção 4 da política é reescrita antes de existir
  qualquer campo classificado.
- **Paridade com o GCP:** cada `sensitivity` vira uma *policy tag*; cada papel vira conta de serviço
  ou grupo IAM. A classificação deixa de ser documental e passa a bloquear acesso.
- **Documentos a atualizar:** [Política de Governança](../governanca_de_dados.md) §4, §5.1 e §7.
