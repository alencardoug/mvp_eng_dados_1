# ADR-0036 — Ancorar a recompra pós-atendimento no pedido, não na estreia nem no chamado

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 9) |
| Substitui / é substituída por | — |

## Contexto

A [P16](../glossario_de_negocio/perguntas_de_negocio.md) pergunta *"qual a taxa de recompra em 90
dias dos clientes que abriram chamado, comparada à dos que não abriram"*. É uma pergunta sobre
**efeito do atendimento**, e responder a ela exige dizer de onde os 90 dias correm.

O conceito de [recompra](../glossario_de_negocio/recorrencia_de_compra.md) que o projeto já tem,
escrito na Etapa 5 para a P04, conta os 90 dias a partir da **estreia** do cliente — o
`first_order_at`. Aplicá-lo aqui sem mudança produziria uma comparação que parece válida e não é: o
chamado pode ter sido aberto um ano depois da estreia, muito além de uma janela que já fechou. O
número mediria correlação com o **perfil** do cliente, não efeito do atendimento.

Há uma armadilha simétrica do outro lado. Ancorar no chamado é a leitura mais direta — *"depois de
ser atendido, o cliente voltou?"* —, mas quem **não** abriu chamado não tem esse marco. O grupo de
controle precisaria de uma âncora inventada, e âncora arbitrária de um lado só é precisamente o que
faz uma comparação parecer honesta sem ser.

O vínculo que resolve já existe na origem: `support_tickets.order_id`. O chamado nasce de um pedido.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Âncora no pedido** — a unidade é o pedido, e a comparação é entre pedidos que geraram chamado e pedidos que não geraram | Os dois grupos têm a **mesma** âncora e a mesma janela, então a diferença entre eles mede o atendimento e não o desenho da medida. O vínculo vem da origem, não de uma regra inventada. E o denominador é grande: todo pedido entra, não só o de quem reclamou | Exige um conceito **novo** no glossário — *recompra pós-pedido* —, que não é a recompra de P04 e precisa dizer isso na própria definição. Dois conceitos de recompra convivendo é custo permanente de leitura, e é o mesmo custo que o [ADR-0033](0033-entrega-medida-em-dois-graos.md) aceitou nos dois grãos de entrega |
| Âncora no fechamento do chamado | A leitura mais direta da pergunta, e a que isola melhor o efeito do atendimento em quem foi atendido | O grupo de controle não tem marco correspondente, e teria de receber um artificial — pedido sorteado, data média. A comparação passaria a depender de uma escolha que ninguém consegue defender |
| Reusar a recompra da estreia, segmentando por "abriu chamado alguma vez" | O mais barato, e diretamente comparável com P04 | Mede o cliente, não o atendimento. Um chamado aberto depois da janela entra na conta de uma janela fechada, e o número resultante responde a uma pergunta que ninguém fez |
| Janela contada do pedido **seguinte** ao chamado | Isola o atendimento sem inventar âncora | Muda a pergunta: passaria a medir intervalo entre compras, não retorno dentro de uma janela. E deixa de fora exatamente quem não voltou, que é o caso que a pergunta quer enxergar |

## Decisão

A **recompra pós-pedido** (`post_order_repeat_purchase`) é a fração dos pedidos após os quais o
cliente fez outro pedido em até **90 dias**, contados de `placed_at`. A unidade de contagem é o
**pedido**, não o cliente.

P16 compara essa taxa entre dois conjuntos de pedidos: os que geraram ao menos um chamado, pelo
vínculo `support_tickets.order_id`, e os que não geraram. O recorte por categoria de chamado é do
primeiro conjunto, e o segundo é o grupo de comparação.

O conceito entra no glossário como arquivo próprio e declara, na definição, que **não** é a recompra
da P04 e por quê. Os dois nunca se somam: um conta clientes de uma coorte de estreia, o outro conta
pedidos.

Pedido cujos 90 dias ainda não fecharam em `as_of_date` fica **fora** dos dois conjuntos — a janela
aberta não é ausência de recompra, e incluí-la faria a taxa dos meses recentes cair sozinha.

## Consequências

- **Positivas:** a comparação passa a ser entre iguais, e é isso que autoriza ler a diferença como
  efeito. O denominador deixa de depender de quem reclamou, o que dá base para o corte por categoria
  de chamado. E o projeto exercita, de propósito, a diferença entre **coorte de cliente** e **coorte
  de evento**, que é onde a maioria dos erros de métrica de relacionamento acontece.
- **Negativas:** dois conceitos de recompra no mesmo glossário, parecidos no nome e diferentes na
  unidade. Quem cruzar os dois produz número sem significado, e a única defesa é que cada definição
  diz onde a outra vive. A exclusão da janela aberta é um segundo custo: os últimos 90 dias do
  período simulado não têm taxa, e isso precisa aparecer na view em vez de virar um mês vazio sem
  explicação.
- **Paridade com o GCP:** nenhuma. É definição de métrica; o BigQuery calcula igual, e a definição
  viaja como bloco `docs` importado pelo dbt do mesmo jeito nas duas fases.
- **Documentos a atualizar:** [Glossário de Negócio](../glossario_de_negocio/) — o conceito novo, o
  índice, e a definição de recompra existente, que passa a apontar para ele; [Perguntas de
  Negócio](../glossario_de_negocio/perguntas_de_negocio.md) — o enunciado de P16 e a sua view.
