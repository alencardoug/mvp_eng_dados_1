# Geração de Dados Sintéticos

> **O que vive aqui:** como os dados nascem — motor de geração, perfis de volume, parâmetros,
> ordem de geração, realismo e o produtor de eventos de estoque.
>
> **O que não vive aqui:** quais tabelas existem e o que significam (ver
> [Modelo de Dados](modelo_de_dados.md)); a origem legada defeituosa (ver
> [Origem Legada](origem_legada.md)); o limite de armazenamento (ver
> [Capacidade e Recuperação](capacidade_e_recuperacao.md)); as regras de privacidade (ver
> [Política de Governança de Dados](governanca_de_dados.md)).

| Campo | Informação |
|---|---|
| Ferramenta | Python + `Faker` ([ADR-0005](adr/0005-geracao-com-faker-orientada-a-configuracao.md)) |
| Volume | Proporções + fator de escala ([ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)) |
| Fator padrão | `dev` (1) |
| Declaração | [`src/mvp_ed1/generator/geracao.yml`](../src/mvp_ed1/generator/geracao.yml) |
| Versão | 3.0 |
| Situação | Motor da origem principal **implementado e medido** (Etapa 4) |
| Última revisão | 04/09/2026 |

---

## 1. Motor orientado a configuração

O gerador **não** é um conjunto de scripts por tabela. São 40 tabelas na origem principal e mais 40
na legada: escrever e manter 80 geradores manuais seria caro e frágil.

O desenho é o inverso:

1. Um **motor genérico** em Python lê um arquivo de configuração declarativo em **YAML**
   ([ADR-0027](adr/0027-configuracao-do-gerador-em-yaml.md)) que descreve o que os modelos não
   dizem: quantas linhas, com que proporção, com que piso e com que distribuição.
2. O motor usa o `Faker` dinamicamente conforme o tipo declarado, respeitando a ordem de
   dependência entre tabelas.
3. Regras que o `Faker` não representa — sazonalidade, afinidade produto/categoria/preço,
   disponibilidade de estoque no momento da venda — são implementadas como **provedores próprios**
   registrados no motor.

**Consequência prática:** mudar uma regra de negócio ou acrescentar um domínio é editar
configuração, não milhares de linhas de Python. É também o que torna a revisão humana viável — o
Owner revisa um arquivo declarativo, não código gerado em massa.

### 1.1 O que é declaração e o que é processo

A implementação da Etapa 4 tornou explícita uma fronteira que o [ADR-0005](adr/0005-geracao-com-faker-orientada-a-configuracao.md)
já previa ao reservar "provedores próprios" — e que vale dizer por escrito, porque ela é o limite do
que a configuração alcança:

| O motor sabe | De onde vem |
|---|---|
| Que colunas existem, de que tipo, obrigatórias, com que chave estrangeira | **Dos modelos** SQLAlchemy ([ADR-0009](adr/0009-sqlalchemy-para-acesso-a-dados.md)) — a configuração é *conferida* contra eles, nunca os repete |
| Quantas linhas cada tabela tem, com que distribuição e que valor cada coluna recebe | **Do YAML** — proporção, fator, piso, provedor por coluna |
| Que um pedido nasce de um carrinho, que a captura não excede a autorização, que o saldo não fica negativo | **Dos construtores de domínio**, um por domínio do modelo |

As 40 tabelas se dividem em duas origens, declaradas linha a linha no YAML:

- **`origem: declarativa`** — o motor preenche coluna a coluna a partir da declaração. São as
  tabelas de referência e as entidades mestres.
- **`origem: processo`** — a contagem e o conteúdo caem do processo de negócio que as produz. São
  as tabelas de evento e as derivadas.

Os dois caminhos passam pelo mesmo preenchimento: o construtor monta o **esqueleto** da linha — de
quem ela é filha, que data veio antes de qual — e o motor completa o resto. Nenhum construtor
escreve um nome de pessoa; nenhuma declaração decide um estado de pedido.

**Por que a causalidade não é declarativa.** Uma tabela de configuração consegue dizer "3.500
pedidos, 2,1 itens cada". Não consegue dizer que o total do pedido reconcilia itens, desconto,
frete e imposto com igualdade exata em `numeric(14,2)`. As doze
[invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) são regra de geração e
critério de teste ao mesmo tempo, e é por isso que elas vivem em código — pequeno, por domínio, e
revisado por amostragem como o [`CLAUDE.md`](../CLAUDE.md) §5 manda.

---

## 2. Princípios de geração

- Usar `Faker("pt_BR")` onde houver suporte adequado ao cenário brasileiro.
- Aceitar uma `seed` explícita e registrar a semente usada em cada execução.
- Registrar `as_of_date`: a mesma combinação de `seed` e `as_of_date` recria exatamente os mesmos
  dados.
- Separar geração de **entidades**, **eventos** e **estados derivados**.
- Não depender da ordem não determinística de estruturas como conjuntos ou consultas sem
  `ORDER BY`.
- Permitir que o banco seja recriado integralmente a partir das migrações e da configuração.
- Emitir mudanças temporais em lotes reproduzíveis, para que cargas incrementais construam
  históricos SCD sem *snapshot* integral.
- Validar a configuração contra os modelos **antes** de gerar a primeira linha: coluna que não
  existe, peso que esquece um valor de enumeração ou piso sem motivo bloqueiam a execução inteira.
- Escrever por `COPY` na conexão bruta, não pelo *unit of work*
  ([ADR-0009](adr/0009-sqlalchemy-para-acesso-a-dados.md), fronteira 1) — e deixar que o banco
  reprove o que estiver errado: toda `CHECK`, unicidade e chave estrangeira do modelo é conferida
  na carga.

---

## 3. Ordem de geração

A ordem respeita as dependências referenciais e a causalidade dos eventos:

1. **Dados de referência** — canais, categorias, marcas, meios de pagamento e moedas.
2. **Entidades mestres** — clientes, produtos, SKUs, fornecedores, armazéns, transportadoras e
   agentes.
3. **Preços, campanhas e cupons**, com intervalos de vigência.
4. **Ordens de compra e recebimentos.**
5. **Carrinhos, pedidos, itens e histórico de estado.**
6. **Pagamentos, transações e reembolsos**, seguindo o estado de cada pedido.
7. **Remessas, itens de remessa e eventos de entrega.**
8. **Livro de estoque, reservas e saldo** — nesta ordem, e depois de tudo que move estoque.
9. **Chamados de atendimento**, vinculados a fatos já existentes.

O passo 8 é o que mais depende da ordem. `inventory_movements` é livro de eventos: os movimentos
não são sorteados, são **montados** do que já aconteceu — o recebimento que entrou, a remessa que
saiu, a devolução que voltou —, acrescidos da formação do estoque inicial, das transferências e dos
ajustes. Só depois o livro é percorrido em ordem de acontecimento, e o saldo existe como projeção
dele ([Modelo de Dados §2.10](modelo_de_dados.md#210-desvios-deliberados-da-3fn)).

Duas consequências desse percurso, e nenhuma delas seria possível sorteando movimentos:

- **o saldo nunca fica negativo** — quando a expedição não tem lastro, entra antes dela um ajuste de
  entrada com motivo documentado, que é o que uma operação real faz ao descobrir divergência de
  inventário;
- **`aggregate_version` é sequencial e sem lacuna** dentro de cada par armazém/SKU, que é o que a
  `UNIQUE (warehouse_id, product_variant_id, aggregate_version)` do modelo exige e o que o
  consumidor do *streaming* vai usar para ordenar.

Mudanças históricas para cenários SCD nascem na Etapa 5, junto com as dimensões que as consomem.

---

## 4. Parâmetros, proporções e fator de escala

O [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) fixou como o volume é expresso:
**um único conjunto de proporções entre as tabelas, um fator de escala que multiplica tudo, e um
piso por tabela que garante cobertura em qualquer escala.** Não há mais perfis de tamanho —
`smoke`, `demo` e `demo_4gb` foram aposentados.

| Nome | Fator | Quando roda |
|---|---|---|
| `dev` | 1 | Padrão em **todas** as etapas locais |
| `cloud` | a definir na Etapa 13, por medição | Fase GCP |

### 4.1 O piso de cobertura

O piso é o que torna o ambiente local suficiente sem ser grande. Independentemente do fator, a
geração precisa produzir:

- toda tabela populada — nenhuma das 40 vazia;
- todo valor de enumeração presente ao menos uma vez;
- todo tipo de falha do [catálogo do legado](origem_legada.md) representado
  ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md));
- toda invariante de negócio do [Modelo de Dados](modelo_de_dados.md#4-invariantes-de-negócio)
  exercida ao menos uma vez, incluindo os casos que devem falhar.

**O piso não é reescrito: é derivado.** O motor lê as `CHECK` de enumeração dos próprios modelos e
já sabe que `carriers` precisa de ao menos três linhas — uma por modalidade — e `payment_methods`
de seis. Onde a cobertura exige mais do que enumeração, a configuração declara `min_rows` **com o
motivo escrito na linha**; é o caso de `product_categories`, que precisa de 24 linhas para que a
hierarquia chegue mesmo ao terceiro nível. Piso sem motivo é recusado na carga da configuração.

Duas garantias de construção sustentam isso, e nenhuma delas depende de sorte:

- as **primeiras linhas** de toda coluna enumerada recebem, uma a uma, cada valor que o modelo
  aceita — com peso 1 em 10 e oito linhas, um valor sumiria em 43% das sementes;
- valor que o domínio torna **impossível** é dispensado por declaração, não por omissão:
  `order_status_history.from_status` nunca vale `cancelled` nem `returned`, porque não existe
  transição saindo de um estado terminal. A dispensa está no YAML, com o motivo, e é revisada.

**Piso e fator interagem, e isso precisa ser dito.** Em fator 1, o piso domina em várias tabelas
pequenas, e a proporção efetiva entre elas deixa de ser a proporção declarada. Isso é intencional —
cobertura vence realismo de proporção quando os dois competem —, mas significa que
**proporções só são fiéis a partir do fator em que o piso deixa de ser o limite**. A verificação de
cobertura é um teste; a de proporção, outro.

### 4.2 Parâmetros gerais

- `seed`;
- período inicial e final;
- quantidade por entidade principal;
- distribuição de pedidos por cliente e canal;
- probabilidades de abandono, falha, cancelamento, devolução e atraso;
- proporção de alterações cadastrais para SCD;
- moeda e localidade;
- **fator de escala**;
- opção de geração de casos inválidos em ambiente isolado de teste.

### 4.3 Onde os números vivem

**Os valores estão em [`geracao.yml`](../src/mvp_ed1/generator/geracao.yml), e só ali.** Repeti-los
aqui criaria a segunda declaração que o [ADR-0009](adr/0009-sqlalchemy-para-acesso-a-dados.md)
existe para impedir — e a cópia divergiria no primeiro ajuste. O arquivo declara, por tabela: a
proporção de referência, o piso quando ele é estrutural, a origem — declarativa ou processo — e o
provedor de cada coluna que o tipo sozinho não determina.

A regra que liga a configuração ao [Modelo de Dados](modelo_de_dados.md): a proporção declarada é a
de referência, e **o fator 1 corresponde a um décimo dela**. Dividir uma tabela por outro fator
quebraria a razão entre elas — 400 mil carrinhos para 35 mil pedidos são 91% de abandono; 4 mil para
3,5 mil seriam 12%, que é outro negócio. Por isso o divisor é único e está declarado uma vez.

Consequência direta: a seção 2 do [Modelo de Dados](modelo_de_dados.md#2-modelo-transacional--40-tabelas-em-9-domínios)
é **gerada** por `make catalog` a partir dos modelos e desta configuração. O documento não guarda
contagem própria.

```bash
make seed-plan            # as 40 tabelas, o piso e a origem de cada uma
```

#### Tabelas de processo não caem exatamente na proporção

A contagem de uma tabela de `origem: processo` é consequência: quantos pedidos chegaram a
`delivered`, quantas remessas foram divididas, quantas expedições precisaram de ajuste de
inventário. A configuração declara a **tolerância** — quanto essa consequência pode se afastar da
referência antes de virar desvio de modelagem — e um teste a cobra a cada execução.

Um número foi corrigido pela geração real, como esta seção previa: `payment_transactions` passou de
52.500 para 71.500 na proporção de referência. Toda intenção de pagamento tem uma autorização e 90%
dos pedidos chegam a capturado; 1,43 transações por pagamento era aritmeticamente incompatível com
a distribuição de estados declarada em `orders`.

#### Parâmetros que ainda não existem

Estes pertencem a etapas seguintes e **não** estão na configuração do gerador da origem principal:

| Parâmetro | Nasce na |
|---|---|
| `inventory_movement_stream_max_count`, `stream_events_per_second`, `stream_seed` | Etapa 7 — [produtor de eventos](#6-produtor-de-eventos-de-estoque) |
| `legacy_faulty_row_count` | Etapa 10 — [Origem Legada](origem_legada.md) |

O `legacy_faulty_row_count` é o único parâmetro cujo piso é qualitativo: ele não pode ficar abaixo
do número de tipos declarados no catálogo, porque um tipo sem registro é um tratamento sem teste.

---

---

## 5. Realismo e coerência

O `Faker` responde por valores sintáticos — nomes, cidades, textos. A **lógica do domínio** é
responsabilidade da aplicação geradora, que controla:

- sazonalidade e distribuição temporal dos eventos;
- afinidade entre produto, categoria, preço e fornecedor;
- recorrência de clientes e abandono de carrinhos;
- consistência entre endereço, cidade, estado e código postal sintético;
- disponibilidade de estoque no momento da venda;
- divisão de pedidos em mais de uma remessa;
- pagamentos com tentativas e resultados coerentes;
- chamados originados por atraso, falha, cancelamento ou devolução;
- histórico de atributos suficiente para validar dimensões SCD.

O período iniciado em 01/01/2024 se aplica **aos eventos**, não por multiplicação uniforme de todas
as tabelas: cadastros e referências podem atravessar todo o intervalo, enquanto pedidos,
pagamentos, movimentos, entregas e chamados têm distribuição temporal coerente, incluindo
sazonalidade.

Todas as [invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) valem para os dados
gerados: elas são simultaneamente regra de geração e critério de teste.

**O que já vale e o que ainda não.** Depois da Etapa 4, a lista acima está implementada com uma
exceção declarada: o **histórico de atributos para dimensões SCD** ainda não é gerado. Ele nasce na
Etapa 5, junto com as dimensões que o consomem — antes disso não haveria contra o que validá-lo. O
`updated_at` de toda tabela mutável já é cursor de carga incremental
([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)), e a exclusão lógica já existe no dado, em
fração pequena, para que a propagação de `deleted_at` tenha o que propagar.

---

## 6. Produtor de eventos de estoque

A carga inicial cria os movimentos históricos coerentes entre `period_start` e `as_of_date` — na
proporção declarada para `inventory_movements`, como toda tabela. Um **produtor Python separado**,
construído na Etapa 7, acrescenta eventos ao livro depois disso, alimentando o
[fluxo de streaming](streaming.md); o teto dele é proporcional ao mesmo fator de escala.

Ele vive em `mvp_ed1/streaming/producer.py`, é acionado por `make stream-produce`, e os parâmetros
dele — rajada, ociosidade, fração de atrasados, fração de transferências — são declarados em
[`streaming/fluxo.yml`](../streaming/fluxo.yml), não no código.

> Até 04/09/2026 esta seção citava 120.000 e 50.000 como absolutos. São a **proporção de
> referência**, não o fator 1: o [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)
> passou por aqui e não atualizou os dois números.

O produtor:

- gera somente eventos compatíveis com SKU, armazém, compra, venda, devolução ou ajuste existentes;
- mantém uma `stream_seed` própria, para repetibilidade do cenário — e, porque repetibilidade e
  retomada se contradizem se ingênuas, deriva de cada retomada uma subsemente do ponto em que a
  execução anterior parou: a sequência continua determinística sem recriar as mesmas chaves
  primárias, que colidiriam;
- produz rajadas, intervalos ociosos e taxas configuráveis;
- cria uma quantidade pequena e configurável de **eventos atrasados**, com
  `occurred_at < recorded_at`;
- gera transferências como dois movimentos correlacionados e balanceados;
- usa chaves de idempotência determinísticas;
- persiste cursor e contagem emitida, para permitir retomada;
- respeita um relógio simulado que nunca gera `occurred_at` no futuro;
- encerra de forma controlada ao alcançar 50.000 novos eventos ou o limite de armazenamento — o que
  ocorrer primeiro.

**Duplicatas são simuladas no transporte ou no consumidor**, reutilizando a mesma
`idempotency_key` — nunca por registros duplicados na tabela de origem. Assim a fonte permanece
íntegra enquanto o pipeline demonstra deduplicação e reprocessamento.

### 6.1 Convivência entre carga histórica e streaming

A carga histórica inicial ocorre **antes** da ativação do streaming. O processo registra o último
`event_sequence` e o cursor de CDC, e o consumidor inicia a partir do próximo evento.

Sobreposições entre *backfill* e streaming são toleradas por deduplicação de `movement_id` e
`idempotency_key` — mas nunca podem criar duas linhas na fato para o mesmo movimento.

Com o streaming ativo, o Airbyte **não** grava os mesmos movimentos novamente no destino de
consumo. Pode executar reconciliação periódica em área separada para identificar lacunas,
permanecendo o streaming como caminho oficial de ingestão incremental dessa tabela.

---

## 7. Privacidade dos dados sintéticos

Mesmo sintéticos, campos que representam nome, endereço, telefone e e-mail são classificados
conforme a sua natureza, para demonstrar governança por desenho. As regras de classificação estão
na [Política de Governança de Dados](governanca_de_dados.md); os controles que cabem ao gerador
são:

- usar domínios reservados, como `example.com`, nos e-mails;
- não gerar números de cartão, contas ou credenciais utilizáveis;
- usar tokens opacos e claramente sintéticos em integrações simuladas;
- evitar documentos nacionais válidos que possam coincidir com pessoas reais;
- não copiar amostras de bases externas;
- incluir metadados de execução que comprovem a origem sintética;
- manter segredos e configurações locais fora do versionamento.

**Como isso ficou implementado.** Documento de pessoa e de empresa saem em formato reconhecível com
o sufixo `-SIN` no lugar do dígito verificador: nenhum CPF ou CNPJ real tem letra, então a colisão
com pessoa real é impossível por construção — e é por isso que o gerador **não** usa `faker.cpf()`,
que produz documento aritmeticamente válido. Todo e-mail termina em `example.com`. Cidade, UF e CEP
são coerentes entre si, sobre geografia real, com o endereço sintético construído por cima. As três
regras são cobradas por teste, não por convenção.
