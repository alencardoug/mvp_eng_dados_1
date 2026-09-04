# ADR-0029 — Carregar a exclusão lógica como marca até a dimensão

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D30 |
| Substitui / é substituída por | **Esclarece** o [ADR-0015](0015-sincronizacao-e-exclusoes.md); não o substitui |

## Contexto

O [ADR-0015](0015-sincronizacao-e-exclusoes.md) diz as duas coisas, em seções diferentes, e a
implementação da camada `trusted` na Etapa 5 obrigou a escolher entre elas:

- a **Decisão** diz que `deleted_at` "é preenchido e o incremental **o propaga até o datamart**" — o
  que só faz sentido se o datamart souber da exclusão, isto é, se ela viajar como marca;
- as **Consequências** dizem que "todo modelo de `staging` precisa **filtrá-la**".

A ambiguidade não apareceu antes porque nada consumia a camada. Ela apareceu no primeiro modelo que
precisa juntar uma fato a uma dimensão.

### O que a medição mostrou

Com a origem carregada em `raw` e a `staging` construída, a consequência de filtrar deixou de ser
hipótese:

| Medida | Valor |
|---|---:|
| SKUs com exclusão lógica | 8 de 600 |
| Itens de pedido que os referenciam | 111 |
| Pedidos afetados | 110 |
| Itens de carrinho afetados | 1.734 |
| Receita líquida nesses itens | R$ 612.348,64 |
| **Fração da receita do datamart** | **1,74%** |

Clientes excluídos acrescentam 11 pedidos e R$ 97.714,96. E a fração **cresce com o tempo**:
exclusões se acumulam, o histórico não muda.

O ponto não é o tamanho — é a direção. Filtrar em `staging` faz o **pedido de 2024 mudar porque o
catálogo mudou hoje**. Nenhum teste pega isso: ele compararia um resultado coerente consigo mesmo.
É tensão direta com o princípio **P2**, reprodutibilidade por padrão.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Marca até a dimensão** | Mantém o fato histórico verdadeiro: a dimensão guarda o membro excluído com `is_deleted`, e a fato faz *join* normalmente. É a leitura da **Decisão** do ADR-0015, e a resposta padrão do modelo dimensional — a Etapa 13 no BigQuery não tem nada a traduzir | Todo modelo adiante passa a decidir se filtra, e "produtos ativos" e "todos os produtos" viram perguntas diferentes. Esquecer o filtro é erro silencioso, e por isso exige convenção e teste |
| Filtrar em `staging` | A leitura literal das **Consequências**. Tudo adiante é "só ativo", sem decisão repetida — a mais simples de escrever e de revisar | Apaga 1,74% da receita do datamart, retroativamente e de forma crescente. E apaga sem deixar rastro: a reconciliação entre `raw` e `staging` fecharia, porque as duas pontas concordariam com o número errado |
| Filtrar em `staging`, com linha "desconhecido" | O *unknown member* clássico do Kimball. Preserva o ADR-0015 literal **e** o valor no datamart | Sobrevive o valor, morre a identidade: 111 itens viram "Produto desconhecido", e a P03 — "top 25 SKUs por receita" — ganha uma linha fantasma no ranking. Também deixa de distinguir "foi excluído" de "nunca existiu", que são defeitos diferentes e recebem tratamento diferente |

## Decisão

**A exclusão lógica viaja como atributo, não como ausência.**

1. `staging` **não filtra**: renomeia, tipa e expõe `deleted_at` como `source_deleted_at` mais o
   booleano `is_deleted`. É coerente com o [ADR-0016](0016-materializacao-por-camada.md), que define
   a camada como "só renomeia e tipa".
2. `trusted` e as **dimensões preservam todos os membros**, excluídos inclusive, marcados com
   `is_deleted`. Uma dimensão nunca perde linha por exclusão na origem.
3. **Filtrar é decisão da pergunta**, tomada onde a pergunta vive — na view de consumo ou no modelo
   que declara responder por "ativos" —, sempre com o filtro visível e comentado.

Duas salvaguardas, porque sem elas isto é promessa:

- **Convenção de nome:** modelo que entrega apenas registros ativos declara isso no nome ou na
  descrição. "Todos" é o padrão; "ativos" é o que precisa ser dito.
- **Teste estrutural:** toda chave de fato tem `not_null` e `relationships` contra a sua dimensão.
  Se alguém filtrar excluídos em uma dimensão, as linhas de fato correspondentes ficam sem par e o
  *build* quebra — o erro silencioso vira falha alta.

## Consequências

- **Positivas:** o dado histórico para de depender do cadastro de hoje, que é o que **P2** exige; a
  exclusão passa a ser consultável em vez de invisível, e "quanto vendemos de produtos que saíram de
  linha" vira pergunta respondível; a reconciliação entre camadas fica exata, sem diferença a
  explicar.
- **Negativas:** a responsabilidade de filtrar se espalha por todos os modelos adiante, e é
  irreversível no sentido de que cada modelo novo herda a decisão. O teste de *relationships* pega o
  caso grave — dimensão que perde membro —, mas **não** pega o inverso: uma view que devia mostrar só
  ativos e mostra todos passa em todos os testes. Isso fica para a revisão humana, e é o custo
  aceito.
- **Paridade com o GCP:** nenhuma. `is_deleted` é uma coluna booleana e o *join* é o mesmo no
  BigQuery. A alternativa recusada é que teria custo lá: *authorized views* que escondem linhas por
  filtro implícito são exatamente o que dificulta auditar acesso.
- **Documentos a atualizar:** [Qualidade de Dados](../qualidade_de_dados.md) — o teste estrutural de
  chave de fato; [Modelo de Dados](../modelo_de_dados.md) §3.2 — a marca nas dimensões;
  [Governança de Dados](../governanca_de_dados.md) §7 — o que a view de consumo mostra.
