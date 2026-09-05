# ADR-0039 — Aplicar a procedência onde as duas origens se encontram

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 10) |
| Substitui / é substituída por | Detalha o alcance do [ADR-0021](0021-procedencia-no-empilhamento.md) |

## Contexto

O [ADR-0021](0021-procedencia-no-empilhamento.md) decidiu **o quê**: a procedência viaja em coluna
própria, e a chave substituta sai do *hash* de (`source_system`, chave natural). Não decidiu **onde**
— e a Etapa 10 é a primeira em que isso deixa de ser abstrato.

O datamart hoje tem 10 fatos e 15 dimensões, e nenhuma delas carrega `source_system`. Nem todas
precisam: as dimensões dividem-se em três naturezas diferentes, e tratá-las igual é que seria o erro.

| Natureza | Exemplos | De onde vem a identidade |
|---|---|---|
| Recebe registros de sistemas | `dim_customer`, `dim_product`, `dim_supplier` | Do sistema que os cadastrou |
| Derivada de referência externa | `dim_geography`, `dim_support_category` | De uma *seed*, não de sistema nenhum |
| Gerada | `dim_date` | De uma série de datas |

Prefixar `dim_date` com a origem criaria duas linhas para o mesmo dia — uma "do legado" e outra "da
origem principal" —, e a conformação morreria justamente onde ela é a razão de a dimensão existir.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Onde as duas origens se encontram** | Respeita a natureza de cada dimensão: quem recebe registro de sistema ganha procedência, quem nasce de referência ou de série não. Mantém a conformação intacta, e a mudança fica proporcional ao que a etapa realmente introduz | Duas convenções de chave convivendo no mesmo datamart. A diferença precisa estar escrita **onde a chave é lida**, não só neste ADR — senão vira armadilha para quem chegar depois |
| Em tudo que vem de origem transacional | Uma convenção só, sem exceção a memorizar, e a terceira origem não exigiria reabrir nada | Reconstrução coordenada de todos os *snapshots* SCD e da fato incremental para trocar as chaves — a operação que já produziu 13.514 linhas órfãs quando foi feita sem cuidado —, por um ganho hipotético. E não resolve o caso de `dim_date`, que continuaria precisando de exceção |
| Renumerar o legado na entrada | Nenhuma chave muda, nada é reconstruído | Contraria o ADR-0021, que pôs a origem **dentro** da chave. E identificador reescrito na entrada deixa de ser o identificador da origem: a rastreabilidade até `raw_legacy` quebra, que é o oposto de procedência |

## Decisão

`source_system` existe **em toda tabela que recebe registros de mais de um sistema**, de `staging` a
`analytics`, e entra na chave substituta dessas tabelas. Nas demais, não existe.

O critério, para quem for aplicar em tabela nova, é uma pergunta só: **a identidade desta linha vem
de um sistema que a cadastrou?** Se vem, a procedência é parte dela. Se a linha nasce de uma *seed*,
de uma série gerada ou de uma derivação do próprio armazém, não vem — e acrescentar origem ali
criaria duplicata onde deveria haver conformação.

O domínio de `source_system` é declarado e fechado: `retail` para a origem transacional e `legacy`
para a origem antiga. **Caminho de ingestão não é sistema de origem** — Airbyte e Beam transportam o
mesmo `retail`, e representá-los como origens distintas faria a reconciliação entre os dois caminhos
do estoque comparar uma coisa com ela mesma sob outro nome.

A divergência entre as duas convenções fica registrada na descrição da chave de cada dimensão que a
carrega, e não apenas aqui.

## Consequências

- **Positivas:** a mudança fica proporcional ao que a etapa introduz, e as dimensões conformadas
  continuam conformadas — que é a propriedade pela qual o projeto pagou desde a Etapa 5. O critério
  é uma pergunta única, aplicável a tabela futura sem consultar uma lista.
- **Negativas:** duas convenções de chave no mesmo datamart, e a diferença não é visível na forma da
  chave — as duas são *hash*. Quem for compor uma chave nova precisa saber qual regra vale, e a
  única defesa é a descrição estar em cada dimensão. Se uma terceira origem aparecer para uma
  dimensão hoje de origem única, a chave dela **muda** naquele momento, e a reconstrução que se
  evitou agora acontece lá.
- **Paridade com o GCP:** nenhuma. É composição de chave; o BigQuery faz igual.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md) §3 — o critério e quais
  dimensões carregam procedência; [Origem Legada](../origem_legada.md) §6 — o domínio de
  `source_system`; [Governança de Dados](../governanca_de_dados.md) — a classificação do campo novo.
