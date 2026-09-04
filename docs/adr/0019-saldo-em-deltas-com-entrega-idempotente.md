# ADR-0019 — Manter o saldo de estoque como deltas imutáveis, com entrega idempotente

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D16, D17, D18 |

## Contexto

O [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) fixou o fluxo — Debezium, Redpanda,
Apache Beam — sem definir o que ele escreve, com que garantia, nem como se recupera de uma queda.
As três perguntas são a mesma decisão: a forma do destino determina o que uma duplicata causa, e a
garantia de entrega determina se o cursor pode ser reprocessado sem estrago.

Estoque é o pior domínio possível para perda ou duplicação silenciosa: uma duplicata vira estoque
fantasma, alimenta alerta e relatório, e só aparece na reconciliação — depois de já ter sido usada.

## Alternativas consideradas

| Materialização | A favor | Contra |
|---|---|---|
| **Deltas imutáveis + view de saldo** | O Beam grava apenas fatos imutáveis; o saldo é uma soma. Nada é sobrescrito, todo saldo é explicável movimento a movimento, e reprocessar é reler os eventos. Auditoria e correção retroativa ficam triviais | A view soma tudo a cada consulta; em escala, exigirá *snapshots* periódicos |
| Tabela agregada por janela | Leitura instantânea e previsível | O agregado vira a fonte da verdade: janela processada errado não tem de onde ser reconstruída. Perda de auditoria que um ambiente real não tolera em estoque |
| Modelo incremental dbt | Unifica *batch* e *streaming* num motor só | A latência passa a ser a do agendamento, não a do evento — deixa de ser tempo real e esvazia o [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) |
| Deltas + tabela materializada mantida pelo Beam | O arranjo mais próximo de produção: fonte auditável e projeção rápida | Dois caminhos de escrita e um teste de reconciliação permanente entre eles, sem necessidade de desempenho que os justifique hoje |

| Entrega | A favor | Contra |
|---|---|---|
| **At-least-once + escrita idempotente** | É como sistemas reais alcançam efeito *exactly-once* sem pagar o custo dele: duplicata reescreve o mesmo registro em vez de somar duas vezes. A garantia sobrevive a reinicialização, *replay* e falha do consumidor | Exige chave de evento estável e disciplina em toda escrita — idempotência quebrada em um ponto anula a garantia inteira |
| *Exactly-once* fim a fim | Garantia mais forte; dispensa pensar em duplicata | Exige coordenação transacional entre Redpanda, Beam e PostgreSQL, aumenta latência, e o equivalente no GCP tem armadilhas próprias — complexidade alta para uma garantia que a idempotência já entrega na prática |
| At-least-once sem deduplicação | Pipeline mais simples | Duplicata vira estoque fantasma. Inaceitável neste domínio |
| At-most-once | Trivial | Perda silenciosa, sem rastro, contra a regra 4 do `CLAUDE.md` |

| Cursor | A favor | Contra |
|---|---|---|
| **Offsets nos tópicos internos do transporte** | Mecanismo nativo do Debezium em produção: *offset*, histórico de schema e status persistidos pelo próprio conector; sobrevive a reinício do conector, do contêiner e da máquina, sem código a manter | O estado fica dentro do Redpanda, então recuperar exige entender o transporte, não abrir uma tabela |
| Estado em arquivo do conector | Simples de inspecionar e de reiniciar durante o desenvolvimento | O volume vira estado crítico não versionado e sem réplica; é o modo autoconfigurado, não o de produção |
| Tabela de controle no `warehouse_db` | Máxima visibilidade: consultável, auditável e corrigível por SQL | Reimplementa à mão o que o conector já faz e introduz a janela clássica entre "evento processado" e "cursor gravado" — fonte de duplicata ou de perda, conforme a ordem |

## Decisão

1. **Materialização:** o Beam escreve **apenas deltas imutáveis** — uma linha por movimento de SKU
   em armazém, com tempo de evento. O saldo em tempo real é uma **view** que agrega esses deltas, e
   a view unificada compõe o saldo do *streaming* com o do *batch*.
2. **Entrega:** **at-least-once no transporte, idempotência no destino**, por chave de evento
   estável vinda do CDC. Janela fixa de **1 minuto por tempo de evento**; *allowed lateness* inicial
   de 5 minutos, **a calibrar por medição** — o número é hipótese, e é rotulado como tal (**P5**).
3. **Cursor:** *offsets*, histórico de schema e status vivem nos **tópicos internos do Redpanda**,
   geridos pelo conector. Nenhuma tabela participa da recuperação.

## Consequências

- **Positivas:** reprocessar é seguro por construção, o que torna o *replay* uma operação de rotina
  e não um incidente; todo saldo é explicável movimento a movimento; a recuperação após queda não
  depende de código do projeto.
- **Negativas:** a view de saldo soma todo o histórico a cada consulta, e em volume alto isso
  exigirá *snapshot* periódico — trabalho previsto para a fase GCP, não feito agora; a idempotência
  precisa ser verificada por teste que injeta duplicata deliberada, sem o qual a garantia é apenas
  intenção; e o *allowed lateness* de 5 minutos permanece **não medido** até a Etapa 7.
- **Paridade com o GCP:** Pub/Sub entrega *at-least-once* e carrega `message_id` para
  deduplicação; o Dataflow executa o mesmo pipeline Beam com as mesmas janelas; o Datastream
  gerencia o próprio cursor, exatamente como o conector aqui. Os três pontos têm equivalente direto.
- **Documentos a atualizar:** [Streaming](../streaming.md) — materialização, garantia, janela e
  cursor; [Modelo de Dados](../modelo_de_dados.md) §5 — a chave de evento que sustenta a
  idempotência; [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — o ponto de recuperação
  passa a ser o *offset* no transporte;
  [Qualidade de Dados](../qualidade_de_dados.md) — teste de duplicata injetada.
