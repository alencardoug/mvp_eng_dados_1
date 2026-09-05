# ADR-0031 — Aterrissar o caminho quente em `raw` e transformar o Airbyte em reconciliação

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 7) |
| Substitui / é substituída por | — |

## Contexto

O [ADR-0019](0019-saldo-em-deltas-com-entrega-idempotente.md) fixou **o que** o Beam escreve —
deltas imutáveis, um por movimento — sem dizer **onde**. Ao começar a Etapa 7, três documentos já
aceitos se contradiziam sobre isso:

| Documento | O que diz |
|---|---|
| [ADR-0008](0008-schemas-do-armazem.md) | As camadas são percorridas em ordem: *"nenhum lê de um posterior"* |
| [Streaming §2](../streaming.md) | O diagrama desenha o Beam escrevendo em `analytics` |
| [ADR-0016](0016-materializacao-por-camada.md) | A exceção incremental de `fact_inventory_movement` foi concedida **porque** *"a Etapa 7 alimenta esta fato por streaming"* |

Os três não cabem juntos. Se o caminho quente aterrissa em `analytics`, o `staging` teria de ler de
uma camada posterior para alimentar a fato — o que o ADR-0008 proíbe — ou a fato congela no
*backfill*, e a exceção que o ADR-0016 concedeu perde a razão de existir.

Há uma segunda pergunta presa na primeira. O critério de conclusão da etapa diz que **o Airbyte
deixa de ingerir incrementalmente `inventory_movements`**, e o [Streaming §6](../streaming.md)
promete que ele passa a fazer *"reconciliação periódica em área separada"*. Essa área nunca foi
definida, e sem ela a promessa não tem onde acontecer.

E uma terceira, que decide se o critério *"backfill e streaming não duplicam linhas na fato"* é
testável: o conector faz **snapshot inicial** da tabela, ou parte do WAL corrente? Se os dois
caminhos nunca se sobrepõem, a deduplicação não tem o que provar.

## Alternativas consideradas

### Onde o caminho quente aterrissa

| Alternativa | A favor | Contra |
|---|---|---|
| **`raw`, em tabela própria** | Ingestão é a função da camada, e o Beam faz ingestão. A ordem do ADR-0008 fica intacta — o `staging` continua lendo só de `raw`. Nada novo entra na arquitetura (**P6**). E a união com a tabela do Airbyte é o lugar exato onde o critério *"não duplicam linhas na fato"* se prova, em vez de ser afirmado | O `raw` deixa de ter um único escritor, e quem for procurar quem escreveu o quê precisa olhar o prefixo da coluna de procedência (`_airbyte_` contra `_stream_`) em vez do nome do schema |
| Schema `streaming` próprio | Dono legível de relance, e paridade explícita com um dataset separado no BigQuery | Emenda a lista de camadas do ADR-0008 para separar por **ferramenta** o que ele organizou por **estágio do fluxo**. A regra 5 do `CLAUDE.md` pede ADR para componente novo justamente para que isso seja pesado, e o peso não se justifica: a função já tem camada |
| `analytics`, como o diagrama desenhou | Menor latência até o consumo, e fiel ao desenho vigente | Quebra a ordem das camadas ou congela a fato — os dois problemas descritos no Contexto. O diagrama é anterior ao ADR-0008 e é ele que está desatualizado |

### Quem faz o *backfill* do caminho quente

| Alternativa | A favor | Contra |
|---|---|---|
| **`snapshot.mode=initial`** | É como o Debezium roda em produção, e é o que a [Capacidade §3.2](../capacidade_e_recuperacao.md) já documenta como procedimento de recuperação: *"descartar o estado do conector e deixá-lo refazer o snapshot"*. Torna o caminho quente autossuficiente, e faz a sobreposição entre snapshot e streaming um teste real de idempotência | Republica o livro inteiro a cada reinício limpo do conector. Só é aceitável porque o destino é idempotente por `movement_id` (ADR-0019) — sem essa propriedade, seria duplicação garantida |
| `snapshot.mode=no_data` | Mais leve para reiniciar; o histórico fica exclusivamente com o Airbyte | Contradiz o procedimento de recuperação já escrito, e os dois caminhos nunca se sobrepõem: o critério *"backfill e streaming não duplicam linhas na fato"* deixa de ter o que testar. A garantia viraria afirmação |

### O que acontece com o *stream* do Airbyte

| Alternativa | A favor | Contra |
|---|---|---|
| **`full_refresh` sob demanda** | Um caminho incremental só, e a carga completa vira a **área de reconciliação** que o Streaming §6 promete — a segunda opinião sobre o mesmo livro, contra a qual se pergunta se o CDC perdeu evento | A carga completa relê 15 mil linhas a cada execução; hoje é irrelevante, e em volume alto passa a ser custo real |
| Remover o *stream* | O mais barato: nada roda | O `raw` congela com o *backfill* de ontem e a reconciliação some. O projeto ficaria com um caminho de ingestão sem contraprova, exatamente no domínio em que perda silenciosa é mais cara |
| Manter o `append` | Nada muda | Dois caminhos incrementais para a mesma tabela, e a pergunta "qual dos dois está atrasado?" sem resposta possível |

## Decisão

1. **O pipeline Beam escreve em `raw.inventory_movements_stream`**, ao lado da tabela do Airbyte.
   O `staging` une as duas e deduplica por `movement_id`, registrando por qual caminho cada
   movimento chegou.
2. **O conector faz *snapshot* inicial.** O caminho quente carrega o livro inteiro, e a
   sobreposição com o *backfill* do Airbyte é total — por construção, e de propósito.
3. **O *stream* `inventory_movements` do Airbyte passa a `full_refresh`, fora do caminho crítico.**
   Ele deixa de ser ingestão incremental e passa a ser a área de reconciliação.

## Consequências

- **Positivas:** a ordem das camadas do ADR-0008 sobrevive intacta, e `fact_inventory_movement`
  continua sendo alimentada por *streaming*, que é o que sustenta a exceção do ADR-0016. A
  sobreposição total entre os dois caminhos transforma a deduplicação de promessa em medição: se ela
  falhar, a fato dobra de tamanho e nada mais fecha. E o projeto ganha, de graça, a contraprova
  permanente entre dois caminhos independentes sobre a mesma tabela — que é o que o Streaming §6
  prometia sem ter onde.
- **Negativas:** o `raw` passa a ter dois escritores, e a coluna de procedência vira a única forma
  de saber quem escreveu cada linha. O `staging` de `inventory_movements` fica sensivelmente mais
  complexo que os outros 26 — é o único que lê duas fontes —, e essa complexidade é permanente. A
  reconciliação entre os dois caminhos só fecha depois de uma carga do Airbyte, então o teste
  precisa tolerar a janela em que o fluxo já entregou e o lote ainda não.
- **Consequência descoberta ao implementar:** toda reconciliação que compara o livro com uma
  projeção passou a precisar de **corte comum**. Com um caminho só, os dois números vinham da mesma
  carga; com dois caminhos de latências diferentes, comparar o livro inteiro contra uma fotografia
  antiga mede a diferença de latência, não defeito. O teste `saldo_reconstruido_confere_com_a_projecao`
  acusou 1.284 falsas divergências na primeira execução, e o tratamento — cortar o livro em
  `recorded_at <= ingested_at` da projeção — está em `trusted/inventory_balances.sql`.
- **Paridade com o GCP:** o Dataflow escreve *streaming inserts* em uma tabela do dataset `raw` do
  BigQuery, ao lado do que o Airbyte carrega; o Datastream faz o *snapshot* inicial pelo mesmo
  modelo conceitual do conector aqui. A união com deduplicação em `staging` é a mesma consulta. O
  que muda é o custo relativo: no BigQuery a anti-junção por chave da view de tempo real é mais
  cara que localmente, e vira candidata a tabela particionada por data de evento.
- **Documentos a atualizar:** [Streaming](../streaming.md) — a aterrissagem, o *snapshot* e o novo
  papel do Airbyte; [Arquitetura](../arquitetura.md) — o destino no diagrama e no mapa de paridade;
  [Modelo de Dados](../modelo_de_dados.md) — a tabela de deltas;
  [Qualidade de Dados](../qualidade_de_dados.md) — os testes da etapa e o corte comum;
  [Execução Local](../execucao_local.md) — os alvos do caminho quente;
  [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — a memória dos dois serviços novos.
