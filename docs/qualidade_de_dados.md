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
| Versão | 1.10 |
| Última revisão | 06/09/2026 |

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
| Invariantes | As do [Modelo de Dados §4](modelo_de_dados.md#4-invariantes-de-negócio), sobre o conjunto em memória: as que atravessam linhas passariam pela carga sem serem notadas; a invariante 13 também é conferida no fator reduzido |
| Privacidade | Nenhum e-mail fora de `example.com`, nenhum documento com aparência de válido ([Geração §7](geracao_de_dados.md#7-privacidade-dos-dados-sintéticos)) |

A suíte roda em `make test`. Os testes de integração exigem banco; o que substitui a carga exige
autorização explícita e banco isolado — um teste não pode ser mais permissivo que o comando que
ele testa. Na revalidação de 05/09/2026 da D31: **91 passaram, 1 pulado** por ser destrutivo. Os
três testes de carga passaram separadamente em banco temporário, com migração aplicada do zero.

Os casos dirigidos de `tests/test_remessas.py` forçam as duas decisões do sorteio: unidade única,
vários itens unitários, quantidades 2/3 e mistura de quantidades. Conferem caixas não vazias e
conservação exata por item, sem usar o próprio repartidor como oráculo. A existência de pedido
entregue dividido é testada no fator padrão e no reduzido: o teste dbt correspondente não pode
passar por ausência do caso.

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

Cada uma das [invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) tem pelo
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
| `remessa_leva_ao_menos_um_item` | Invariante 13, bloqueante após o conserto da D31; evita a remessa sem representação na fato de itens |
| `invariante_10_causalidade_das_datas` | Nenhuma etapa do ciclo antecede a anterior, incluindo a promessa de prazo, que é feita **no** despacho |

`quarantine.rejected_shipment_deliveries` é o primeiro morador do schema `quarantine`, que até a
Etapa 8 existia declarado e vazio — o tratamento do legado, que o povoaria, é da Etapa 10. Ele chega
antes porque o ADR-0034 criou a primeira rejeição possível fora do legado, e a regra 4 do
[`CLAUDE.md`](../CLAUDE.md) não admite que ela seja descartada em silêncio. O código de rejeição
segue a convenção do [catálogo de falhas do legado](origem_legada.md#31-catálogo-de-falhas-obrigatórias):
`UPPER_SNAKE`, estável e nunca reaproveitado.

**Revalidação da D31, em 05/09/2026:** nenhuma remessa sem item na origem ou em `trusted`.
No mesmo universo de entregues, `sum(delivered_count)` em P13 e
`count(*) from trusted.shipments where is_delivered` deram **3.166** em ambos. Antes da correção,
eram 3.141 e 3.221 respectivamente. O novo número não é uma subtração das remessas vazias: o
efeito da geração sobre os dados dependentes foi medido, como registra
[Capacidade §2.7](capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026).

---

## 5. Tratamento do legado

- testes unitários para cada regra de conversão;
- comparação entre o resultado e o manifesto esperado do gerador — o manifesto é oráculo, nunca
  entrada da transformação;
- preservação de valor original, valor tratado e regra aplicada;
- idempotência: reprocessar o mesmo `snapshot_id` não duplica registros;
- `source_system` preenchido e dentro do domínio declarado em toda tabela empilhada
  ([ADR-0021](adr/0021-procedencia-no-empilhamento.md));
- a captura lida **existe** e traz todas as 40 tabelas — o que separa tabela legitimamente vazia de
  captura ausente, que no bruto são a mesma coisa;
- um tratamento por versão de catálogo: resultado diferente sob a mesma versão **recusa** substituir
  a auditoria guardada, em vez de apagá-la ([D33 a D35](pendencias.md#2-decisões-já-fechadas));
- invariante que atravessa entidades é exigida onde a quarentena não explica a diferença — e toda
  diferença tolerada tem contrapartida com motivo;
- cobertura do catálogo: **cada tipo injetável de falha** — 23 dos 25 declarados; `NULL_REQUIRED` e
  `PARENT_REJECTED` nascem do contexto, e não de um valor que se possa injetar numa célula — tem ao
  menos um registro gerado e um resultado esperado
  ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md)) — tipo sem registro é
  tratamento sem teste;
- reconciliação entre extraídos, aceitos, corrigidos, rejeitados e empilhados;
- bloqueio do empilhamento quando a regra de correção for ambígua;
- relatório de qualidade por tabela, coluna, tipo de erro e resultado do tratamento.

### 5.1 Validação dos valores tratados — 06/09/2026

Os testes de detecção passaram antes da correção, mas ler todas as colunas de
`staging.stg_legacy__cart_items` falhava em `31/02/2024`. O gerador SQL removia os ramos de rejeição
do `case` de limpeza; a data detectada como impossível chegava a `to_date` por uma regra posterior.
O otimizador podia eliminar essa expressão quando a consulta lia somente `achados`.

O gerador passou a respeitar a precedência também na conversão, preservando o original quando a
primeira regra rejeita. Nenhuma regra de negócio, lista do catálogo ou teto foi alterado.

| Verificação executada | Resultado |
|---|---|
| Build restrito às views de limpeza legada | 40 modelos; `PASS=40`, `WARN=0`, `ERROR=0` |
| Suíte de gerador, SQL derivado e detecção/conversão | 24 testes passaram, nenhum pulado |
| Achados de valor injetados encontrados nos modelos | 74 de 74; zero perdidos |
| Achados adicionais em relação ao manifesto | 13 em 12.749 linhas (0,10%); teto em teste permanece 0,5% |
| Leitura efetiva de todas as colunas das 40 views | Passou, sem exceção de conversão |

Casos dirigidos conferem dias impossíveis, ano bissexto válido, nulo disfarçado, e-mail malformado
e números equivalentes/ambíguos, com resultados esperados independentes do injetor. Testes sem
banco também conferem a ordem de todos os ramos e a igualdade entre os modelos versionados e a
saída do gerador.

Relatório local ignorado: `data/validacoes/etapa10/limpeza.xml`, incluindo as contagens como
propriedades JUnit. Com o ambiente carregado, a verificação é reproduzível por:

```bash
.venv/bin/pytest tests/test_legado_deteccao.py tests/test_legacy_models.py tests/test_legado.py \
  -q --tb=short -o junit_family=legacy --junitxml=data/validacoes/etapa10/limpeza.xml
```

**Escopo da evidência:** são achados de valor, não as falhas de contexto nem a classificação final
das ocorrências. A reconciliação das três saídas, a cascata, a quarentena, o empilhamento e a DAG
da Etapa 10 continuam pendentes. A origem principal não foi regenerada e nenhum build do datamart
principal foi executado nesta validação. A decisão de tratamento pendente está na
[D32](adr/README.md#3-decisões-pendentes).

---

## 6. Streaming de estoque

Construído e medido na Etapa 7. A tabela abaixo preserva o corte histórico então registrado;
não representa o estado atual. A revalidação após a D31 fica em
[Streaming §7.2](streaming.md#72-revalidação-da-d31), dono dos resultados vigentes.

| O que se verifica | Onde | Resultado histórico |
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

### 6.2 O que a reconstrução da D31 acrescenta à verificação

Flags `arrived_by_stream`/`arrived_by_batch` e igualdade de contagens não detectam payload antigo
sob chave reutilizada. Na reconstrução, compare também as colunas de negócio da origem, lote e
streaming, excluindo somente metadados de transporte e normalizando UUID, decimal, fuso e JSON.
Os hashes e diferenças foram guardados por corte — antes, carga inicial e cenário ao vivo —,
sem misturar a geração determinística com instantes reais do produtor.

As barreiras da manutenção estão em `tests/test_manutencao_streaming.py`: autorização explícita,
destino exato, recusa de slot ativo/de outro banco e consulta de confirmação após remoção.
A execução em bancos isolados também conferiu segunda chamada idempotente, tabelas vizinhas
preservadas e rollback do reset quando uma dependência impede truncamento sem `CASCADE`.

`WARN=0` no resultado do build significa **nenhum aviso de teste de dados**. Não significa log
sem avisos: a versão instalada ainda informa argumentos antigos em testes genéricos, constraints
não suportadas em views e `numeric` sem precisão explícita em contratos. Esses avisos não foram
suprimidos nem suas declarações alteradas para encerrar a D31.

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
