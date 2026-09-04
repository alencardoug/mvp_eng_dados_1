# ADR-0028 — Acrescentar uma fato de carrinho para o funil de conversão

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (lacuna encontrada ao redigir as perguntas de negócio) |
| Substitui / é substituída por | — |

## Contexto

O [ADR-0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) fixou que as perguntas de
negócio vêm antes do primeiro modelo. Ao escrevê-las, na abertura da Etapa 5, apareceu uma lacuna
que nenhuma leitura isolada dos documentos teria mostrado.

O [Glossário de Negócio](../glossario_de_negocio/README.md) prometia *carrinho abandonado* e *taxa
de conversão* como conceitos da Etapa 5. O [Modelo de Dados](../modelo_de_dados.md) §3.1 declarava
**nove fatos, e nenhuma com grão de carrinho**. A pergunta "qual a taxa de conversão de carrinho em
pedido, por canal e mês?" simplesmente não era respondível pelo modelo dimensional como ele estava.

O peso do problema está no volume: `carts` e `cart_items` somam **1,5 dos 2,5 milhões de linhas** da
proporção de referência — 59% do dado do projeto. Sem uma fato de carrinho, essa massa é gerada
pela Etapa 4, ingerida pelo Airbyte, tipada em `staging`, tratada em `trusted` — e não alimenta
pergunta nenhuma. É o oposto do que o ADR-0018 foi buscar ao decidir que nenhuma medida existe sem
consumidor declarado.

Este ADR existe porque o método funcionou: escrever as perguntas antes do SQL revelou que o modelo
estava incompleto, e revelou antes de custar retrabalho.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **`fact_cart_event` — grão de evento de ciclo de vida** | É transacional, como o §3 do Modelo de Dados exige de toda fato do projeto; espelha `fact_order_status_event`, então o funil e o ciclo do pedido se leem do mesmo jeito; a taxa de conversão vira razão entre duas contagens de evento, sem sub-consulta | Torna-se a maior fato do projeto — cerca de 780 mil linhas na proporção de referência —, e leva o modelo dimensional de 9 para 10 fatos |
| `fact_cart_item` — grão do item adicionado | Daria as 1,1 milhão de linhas de `cart_items` um destino e responderia "quais SKUs são mais abandonados" | A pergunta feita é de **carrinho**, não de item. Responder contagem de carrinho a partir de grão de item exige contagem distinta — misturar grãos na mesma fato é o erro clássico de modelagem dimensional, e aqui seria cometido de propósito |
| *Accumulating snapshot* de carrinho | Metade das linhas, e responde a pergunta diretamente: uma linha por carrinho com os marcos como colunas | O Modelo de Dados §3 declara que **não há fatos do tipo *snapshot*** no projeto. Abrir a exceção para uma tabela reabriria o princípio inteiro, e o ganho é só de tamanho |
| Responder a partir de `trusted`, sem fato | Zero mudança de modelo | `consumption` passaria a ler de duas camadas diferentes, e a linhagem do datamart deixaria de ser uniforme — exatamente o que a separação de camadas do [ADR-0008](0008-schemas-do-armazem.md) existe para impedir |
| Tirar a conversão do escopo | Mantém o modelo como declarado | A maior tabela do projeto passaria a existir só para ser ingerida, e a análise de funil sairia do MVP. Recusada pelo Owner |

## Decisão

O modelo dimensional ganha uma décima fato: **`fact_cart_event`**, com grão de **um evento de ciclo
de vida de um carrinho**.

São até dois eventos por carrinho:

| Evento | Quando | Existe sempre? |
|---|---|---|
| `created` | Abertura do carrinho | Sim |
| `converted` · `abandoned` · `expired` | Desfecho do carrinho | Não — carrinho ainda aberto e dentro do prazo não tem desfecho |

Cada linha carrega **duas chaves de data**: a do evento e a da **criação do carrinho**. É essa
segunda que as views usam para agregar, porque o carrinho pertence ao mês em que foi aberto — um
carrinho de 30 de novembro convertido em 2 de dezembro contaria duas vezes em recortes diferentes,
e a taxa de dezembro poderia passar de 100%.

Carrinhos **sem item** não geram evento: nunca houve intenção de compra registrada, e incluí-los
infla o denominador do funil.

## Consequências

- **Positivas:** o funil ganha onde pousar, e a maior massa de dado do projeto ganha consumidor
  declarado; a taxa de conversão é razão entre duas contagens de evento, uniforme com o resto do
  datamart; o modelo passa a exercitar uma fato de **evento sem valor monetário**, que é um tipo que
  as outras nove não representavam.
- **Negativas:** o modelo dimensional cresce de 9 fatos e 26 tabelas para **10 e 27**, e toda
  contagem agregada do §3 muda junto. `fact_cart_event` passa a ser a maior tabela de `analytics`,
  o que desloca a expectativa de tamanho do armazém — número que só a medição da Etapa 5 fecha
  (**P5**). O evento `created` é redundante para a taxa de conversão em si: ele existe para que a
  fato seja de evento de verdade e para que o topo do funil seja legível sozinho.
- **Paridade com o GCP:** é uma tabela como as outras nove — mesma materialização, mesmo `dbt`,
  mesmo BigQuery. Na Etapa 13 ela é a candidata mais óbvia a particionamento por data de criação do
  carrinho, pelo tamanho; o ajuste é de configuração, não de modelo.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md) §3.1 e §3.2 — a décima fato
  e as contagens; [Glossário de Negócio](../glossario_de_negocio/) — a pergunta **P07** e os
  conceitos de carrinho abandonado e taxa de conversão;
  [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — o escopo da Etapa 5.
