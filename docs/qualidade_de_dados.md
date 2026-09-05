# Qualidade de Dados

> **O que vive aqui:** a estratégia de testes e de reconciliação por camada — o que é verificado,
> onde e com qual ferramenta.
>
> **O que não vive aqui:** as invariantes de negócio que os testes traduzem (ver
> [Modelo de Dados](modelo_de_dados.md#4-invariantes-de-negócio)); as regras de tratamento do
> legado (ver [Origem Legada](origem_legada.md)); a definição de pronto de cada entrega (ver
> [`CLAUDE.md`](../CLAUDE.md)).

| Campo | Informação |
|---|---|
| Ferramentas | `dbt` (testes nativos) + `dbt-expectations` + `pytest` para o código Python |
| Decisão | [ADR-0003](adr/0003-stack-airbyte-dbt-airflow.md) |
| Versão | 1.7 |
| Última revisão | 05/09/2026 |

---

## 1. Princípio

Teste de dados não é teste de software. O código pode estar correto e os dados, errados — e o
inverso também acontece. Por isso o projeto mantém duas famílias:

| Família | Ferramenta | Pergunta que responde |
|---|---|---|
| Testes de código | `pytest` | A função de conversão faz o que promete? |
| Testes de dados | `dbt` + `dbt-expectations` | O conteúdo das tabelas satisfaz as regras? |

**Falha de teste interrompe o pipeline.** Um dado errado que segue adiante custa mais caro do que
uma execução interrompida.

---

## 2. Banco transacional

- chaves primárias e estrangeiras válidas;
- unicidade de chaves naturais selecionadas;
- `NOT NULL`, `CHECK` e índices coerentes com o uso;
- valores monetários com precisão decimal — **nunca `float`**;
- *timestamps* com fuso horário quando representarem eventos;
- transições de estado validadas.

Boa parte destes controles é declarada no próprio schema: quando o banco pode garantir a regra, a
regra vive no banco, não em um teste posterior.

### 2.1 O gerador, e por que o banco é o teste dele

A carga por `COPY` da [Etapa 4](../src/mvp_ed1/generator/) atravessa toda `CHECK`, toda unicidade e
toda chave estrangeira do modelo. Uma linha incoerente não entra: a execução para. Escrever um teste
Python que repita essas mesmas regras seria manter duas opiniões sobre a mesma restrição — e a
segunda opinião estaria sempre atrasada em relação ao modelo.

O que o `pytest` cobre é o que o banco **não** consegue dizer:

| Família | O que verifica |
|---|---|
| Configuração | A declaração do gerador confere com os modelos: tabela ausente, coluna inexistente, peso que esquece um valor de enumeração, piso sem motivo |
| Determinismo | A mesma `seed` com a mesma `as_of_date` produz o mesmo conjunto, comparado por impressão digital; sementes diferentes produzem conjuntos diferentes |
| Cobertura | As 40 tabelas populadas, todo valor de enumeração presente, proporção dentro da tolerância declarada — e o mesmo em um fator vinte vezes menor, que é o que prova que a garantia é do piso e não do volume |
| Invariantes | As doze do [Modelo de Dados §4](modelo_de_dados.md#4-invariantes-de-negócio), sobre o conjunto em memória: sete delas atravessam linhas e passariam pela carga sem serem notadas |
| Privacidade | Nenhum e-mail fora de `example.com`, nenhum documento com aparência de válido ([Geração §7](geracao_de_dados.md#7-privacidade-dos-dados-sintéticos)) |

A suíte roda em `make test` e não depende de banco de pé, exceto a carga, que exige autorização
explícita — um teste não pode ser mais permissivo que o comando que ele testa.

---

## 3. Ingestão e camada `raw`

- contagem de registros por tabela e por execução;
- **deduplicação da entrega ao menos uma vez**: os fluxos em modo `append` releem a fronteira do
  cursor e reescrevem linhas já entregues. `raw` é *at least once*; `staging` deduplica pela chave
  e entrega exatamente uma vez, que é a mesma resposta que o
  [ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) dá ao *streaming*. Sem isso, nove
  duplicatas dobraram uma captura e uma desalinhou um saldo — pouco o bastante para ninguém notar
  sem teste;
- controle de registros inseridos, alterados e removidos;
- captura dos metadados de sincronização do Airbyte;
- conferência de que cada tabela usa o modo declarado no critério de sincronização
  ([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)) — tabela sem modo declarado é falha de *build*,
  não escolha implícita;
- para as tabelas incrementais, teste de **atualização tardia**: um registro com `updated_at`
  anterior ao último cursor precisa entrar na carga seguinte;
- para a origem transacional, propagação de `deleted_at` até o datamart;
- para a origem legada, detecção de exclusão física por comparação com o *snapshot* anterior.

---

## 4. Transformação e camada dimensional

- testes nativos do dbt: `unique`, `not_null`, `relationships`, `accepted_values`;
- **`not_null` + `relationships` em toda chave de fato** — é a salvaguarda estrutural que o
  [ADR-0029](adr/0029-exclusao-logica-como-marca-na-dimensao.md) exige. Se alguém filtrar membros
  excluídos de uma dimensão, as linhas de fato correspondentes ficam sem par e o *build* quebra: o
  erro silencioso vira falha alta. O que este teste **não** pega é o inverso — uma view que devia
  mostrar só ativos e mostra todos passa em tudo. Isso fica para a revisão humana, e é custo
  declarado no ADR;
- testes de `dbt-expectations` para regras que os nativos não cobrem — faixas de valores,
  distribuição, cardinalidade, comparação entre colunas;
- teste próprio `vigencias_sem_sobreposicao` para os intervalos SCD tipo 2
  ([ADR-0017](adr/0017-chaves-substitutas-e-scd.md)): duas versões válidas no mesmo instante fariam
  o *join* temporal duplicar a linha de fato, e o resultado não seria uma falha — seria receita
  maior;
- teste de **grão** por fato: a chave declarada é única, o que prova que o grão é o que se afirma
  ([ADR-0018](adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md));
- verificação de **contrato** nas views de consumo: `contract: enforced` quebra o *build* quando
  colunas, tipos ou obrigatoriedade mudam;
- para `fact_inventory_movement`, único modelo incremental do projeto
  ([ADR-0016](adr/0016-materializacao-por-camada.md)), **reconciliação contra a reconstrução
  completa**: o resultado incremental e o `--full-refresh` precisam ser idênticos. Este teste já
  pagou o próprio custo — pegou uma linha duplicada que o incremental herdara de uma carga anterior
  e que o `staging` passara a remover;
- as invariantes que **atravessam linhas** têm cada uma o seu teste singular em `dbt/tests/`, com o
  motivo escrito de por que elas não são `CHECK`: a 2 compara pedido com a soma dos itens, a 3 e a 4
  comparam eventos financeiros entre si, a 5 soma remessas do mesmo pedido, a 6 soma recebimentos,
  a 7 exige origem no movimento, a 8 confere a **direção** da diferença de reserva, a 9 confronta
  cada transição observada com a lista de transições legais, a 10 percorre a causalidade do ciclo
  — pedido, despacho, coleta, entrega e devolução — nomeando na falha **qual** elo saiu de ordem, e
  a 12 verifica as três condições do cupom uma a uma, mais uma quarta que só apareceu construindo:
  o desconto não pode passar do valor do pedido;
- reconciliação de pedidos, pagamentos, estoque e remessas;
- testes de atualidade dos dados;
- documentação de fontes, modelos e colunas;
- exposição da linhagem da origem até as views de consumo.

Cada uma das doze [invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) tem pelo
menos um teste correspondente. Uma invariante sem teste é uma invariante que não existe.

### 4.1 A regra da máquina de estados vive fora do modelo

A invariante 9 depende de saber **quais pares de estados são legais**, e essa lista não está em
`case` dentro de modelo: está na *seed* `order_status_transitions`. Regra escondida em SQL é regra
que ninguém revisa; em artefato declarativo, cabe numa olhada — é a §5 do
[`CLAUDE.md`](../CLAUDE.md) aplicada ao teste, e não só ao modelo.

Quem **produz** as transições é o gerador, a partir dos seus caminhos de estado. São dois artefatos
declarando a mesma máquina, e o `pytest` `test_transicoes_declaradas_batem_com_os_caminhos_do_gerador`
confere que concordam: regra que o gerador nunca produz é regra morta, e caminho que a regra não
permite quebraria a invariante 9 no primeiro `build`.

### 4.2 Três regras em *seed*, e o espelho que as guarda

A partir da Etapa 8, a regra que um teste verifica passou a viver em artefato declarativo, e não em
`case` dentro de modelo. São três, e cada uma tem um `pytest` que confere a *seed* contra quem
produz o dado — porque uma regra escrita em dois lugares só é útil enquanto os dois concordam:

| *Seed* | Regra | Espelho conferido por `pytest` |
|---|---|---|
| `order_status_transitions` | Quais transições de estado do pedido são legais (invariante 9) | Os caminhos de estado do gerador |
| `support_categories` | As seis categorias de chamado, com nome e agrupamento | O `CHECK` de `support_tickets.category` no modelo transacional |
| `brazilian_states` | As 27 UFs e a região de cada uma | — dado de referência externo, sem produtor no projeto |

É o mesmo arranjo de `as_of_date` e do ponto de reposição, pelo mesmo motivo: dois lugares precisam
do valor e só um pode ser o dono. A diferença é que aqui o segundo lugar é uma **regra**, não um
número, e a divergência não apareceria como falha — apareceria como uma categoria sumindo do recorte
sem que nada quebrasse.

### 4.3 A entrega, e a primeira quarentena fora do legado

A data de entrega vem do livro `delivery_events`; `shipments.delivered_at` é conferência
([ADR-0034](adr/0034-entrega-do-livro-de-eventos.md)). Três testes sustentam o arranjo:

| Teste | O que prova |
|---|---|
| `entrega_projetada_tem_evento_no_livro` | A coluna e o livro não divergem — e quando divergirem, a remessa está em `quarantine.rejected_shipment_deliveries`, com código e motivo, não descartada |
| `pedido_dividido_fecha_na_ultima_remessa` | O ciclo de entrega do pedido nunca é menor que a chegada de qualquer remessa dele, e só é declarado fechado quando **todas** chegaram ([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)) |
| `invariante_10_causalidade_das_datas` | Nenhuma etapa do ciclo antecede a anterior, incluindo a promessa de prazo, que é feita **no** despacho |

`quarantine.rejected_shipment_deliveries` é o primeiro morador do schema `quarantine`, que até a
Etapa 8 existia declarado e vazio — o tratamento do legado, que o povoaria, é da Etapa 10. Ele chega
antes porque o ADR-0034 criou a primeira rejeição possível fora do legado, e a regra 4 do
[`CLAUDE.md`](../CLAUDE.md) não admite que ela seja descartada em silêncio. O código de rejeição
segue a convenção do [catálogo de falhas do legado](origem_legada.md#31-catálogo-de-falhas-obrigatórias):
`UPPER_SNAKE`, estável e nunca reaproveitado.

---

## 5. Tratamento do legado

- testes unitários para cada regra de conversão;
- comparação entre o resultado e o manifesto esperado do gerador — o manifesto é oráculo, nunca
  entrada da transformação;
- preservação de valor original, valor tratado e regra aplicada;
- idempotência: reprocessar o mesmo `snapshot_id` não duplica registros;
- `source_system` preenchido e dentro do domínio declarado em toda tabela empilhada
  ([ADR-0021](adr/0021-procedencia-no-empilhamento.md));
- cobertura do catálogo: **cada um dos 21 tipos de falha** tem ao menos um registro gerado e um
  resultado esperado ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md)) — tipo sem
  registro é tratamento sem teste;
- reconciliação entre extraídos, aceitos, corrigidos, rejeitados e empilhados;
- bloqueio do empilhamento quando a regra de correção for ambígua;
- relatório de qualidade por tabela, coluna, tipo de erro e resultado do tratamento.

---

## 6. Streaming de estoque

Construído e medido na Etapa 7. O que segue está implementado; os resultados estão em
[Streaming §7.1](streaming.md#71-o-que-foi-medido).

| O que se verifica | Onde | Resultado |
|---|---|---|
| Unicidade de `movement_id` e de `idempotency_key` | testes de schema em `_analytics__models.yml` | passa |
| **Duplicata injetada deliberadamente no transporte** | `make stream-duplicate` | 250 republicadas, **0 gravadas** |
| Reprocessar o mesmo lote não altera o resultado | o mesmo alvo, e o log do destino | contagem e saldo idênticos |
| *Backfill* e streaming não duplicam linhas na fato | `caminhos_de_ingestao_reconciliam` e a chave da fato | 15.446 distintos, 15.446 na fato |
| Nenhum caminho perde evento | `caminhos_de_ingestao_reconciliam` | **0** movimentos só pelo lote |
| Correspondência entre os dois lados de uma transferência | `transferencia_confere_dos_dois_lados` | passa |
| Sinal da quantidade conforme `movement_type` | `CHECK` na origem | recusado na escrita |
| `UPDATE` ou `DELETE` capturado falha o pipeline | `envelope.decodificar` | levanta `ContratoViolado` |
| Saldo reconstruído confere com a projeção da origem | `saldo_reconstruido_confere_com_a_projecao` | passa, com o corte comum |
| Atraso entre `occurred_at` e `recorded_at` | medição sobre a fato | p50 403 s · máx 900 s |
| Alerta emitido ao cruzar o limiar | `make stream-alerts` | 10 aberturas, 2 correções |

### 6.1 O corte comum, e por que dois caminhos o exigem

A descoberta mais cara da Etapa 7 não foi um defeito no fluxo: foi um **teste que passou a mentir**.

`saldo_reconstruido_confere_com_a_projecao` compara o livro reconstruído com a projeção
`inventory_balances`. Até a Etapa 6 os dois vinham da mesma carga, no mesmo instante, e comparar era
trivial. Com o livro chegando pelo CDC em segundos e a projeção pelo Airbyte sob demanda, o teste
acusou **1.284 divergências que não eram divergências** — era a diferença de latência entre dois
caminhos, apresentada como defeito na projeção.

A regra que sai daí vale para qualquer reconciliação em arquitetura de caminho quente e frio:
**comparar dois números exige cortá-los no mesmo instante**. Aqui o corte é
`recorded_at <= ingested_at` da projeção — a fotografia lida em T reflete todo movimento registrado
antes de T, porque a origem grava o movimento e move o saldo na mesma transação.

O corte é por tempo de **registro**, não de negócio: evento atrasado tem tempo de negócio antigo e
tempo de registro novo, e é o de registro que diz se a projeção já o tinha visto.

---

## 7. Reconciliação entre camadas

A reconciliação é o teste que dá sentido a todos os outros: prova que nada foi perdido nem criado
no caminho.

| Fronteira | O que deve fechar |
|---|---|
| `oltp` → `raw` | Contagem por tabela e por lote |
| `raw_legacy` → tratamento | `extraídos = aceitos + corrigidos + rejeitados` |
| `staging` → `trusted` | Contagem e regras aplicadas, com rejeições rastreáveis |
| Livro de entrega ↔ coluna da remessa | Toda remessa que a origem projeta como entregue tem evento `delivered`; a que não tem fica em `quarantine` com motivo ([ADR-0034](adr/0034-entrega-do-livro-de-eventos.md)) |
| `trusted` → `analytics` | Grão declarado e medidas somadas |
| *Batch* + streaming → view de saldo | O saldo da view é a soma dos deltas que a fato absorveu mais os que ela ainda não contém, sem interseção — a fronteira é a ausência do `movement_id` na fato ([ADR-0031](adr/0031-aterrissagem-do-caminho-quente-em-raw.md)) |
| CDC ↔ carga completa | Todo movimento chega pelos dois caminhos; o que chega só pelo lote é lacuna do CDC |

Nenhuma etapa descarta registros em silêncio: o que não passa vai para quarentena com motivo
registrado.

---

## 8. Geração assistida dos testes

São 40 tabelas na origem, mais o legado e a camada dimensional. Escrever manualmente cada teste de
unicidade, não nulo e relacionamento seria trabalho mecânico de baixo retorno.

A geração dos arquivos de teste é assistida por IA a partir do DDL e das invariantes documentadas —
inclusive dos testes menos óbvios, como "a data de pagamento nunca é anterior à data da compra" ou
"`status_logistica` só aceita este conjunto de valores".

O que **não** é delegado: decidir quais regras existem, revisar o que foi gerado e aceitar o
resultado. Testes gerados e não revisados dão falsa sensação de cobertura — risco **R14** do
[Registro de Riscos](riscos.md).
