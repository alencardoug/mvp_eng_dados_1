# Pendências do Owner

> **O que vive aqui:** o que está parado **esperando decisão sua** — aprovações, decisões
> bloqueantes e questões em aberto —, em ordem de urgência.
>
> **O que não vive aqui:** as opções de cada decisão e o seu contexto (ver
> [Registro de Decisões](adr/README.md)); os critérios de conclusão das etapas (ver
> [Plano de Desenvolvimento](plano_de_desenvolvimento.md)). Esta é uma **vista por responsável**,
> não uma segunda cópia do conteúdo.

| Campo | Informação |
|---|---|
| Etapa atual | Etapa 10 — Corte 6: origem legada, reaberta; três rodadas de revisão de desenvolvimento respondidas (RV10-01…12, RV10-2-01…10, RV10-3-01…04 — a terceira em 16/09/2026, dois bloqueantes e dois ajustes corrigidos), **aguardando a quarta rodada** |
| Aprovações pendentes | 0 |
| Decisões pendentes | 1 (D43, adiada de propósito para a fase GCP) |
| Última revisão | 16/09/2026 |

---

## 1. Esperando você

### D43 — a guarda de identidade como função no armazém (adiada em 16/09/2026)

**Pergunta:** a macro `chave_canonica` deve continuar reproduzindo a gramática do `cast` de inteiro
em SQL (regex + soma de dígitos em `numeric`, provada forma a forma contra o cast nativo), ou virar
uma função plpgsql `safe_cast` criada pelo dbt — em que a guarda **é** o próprio `cast`, par exato do
`SAFE_CAST` do BigQuery?

**Decisão de 16/09/2026: adiar.** A gramática fica na macro; a alternativa entra aqui para ser
decidida na fase GCP (Etapa 13), quando a paridade com `SAFE_CAST` for medida de fato e não suposta.
Levantada pela terceira rodada de revisão (RV10-3-01): o cast do PostgreSQL 16 aceita hexadecimal,
octal, binário e `_`, e a guarda os negava — a nota de 16/09 no
[ADR-0045](adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md) registra o conserto.

*Efeito de não decidir:* nenhum na fase local — cada forma nova do `cast` numa versão futura do
PostgreSQL exige remedir a guarda, e o teste contra o cast nativo a acusa **se a forma estiver na
lista**; ele não descobre sozinho uma mudança de gramática. O custo da alternativa é DDL novo no
armazém e uma subtransação por linha (~100 mil no *build*). A quarta rodada de revisão (16/09)
acrescentou uma terceira saída a considerar na Etapa 13: `pg_input_is_valid(texto, tipo)` guardando
o `cast` num `case` — nativo do PostgreSQL 16, já usado em `legacy/classification.sql`, sem função
nova no armazém.

---

## 1.1 Decididas e implementadas

As três questões que a revisão da Etapa 10 levantou — D33, D34 e D35 — foram decididas em
07/09/2026 e estão implementadas; o registro delas está abaixo.

Os achados que a terceira revisão deixou abertos — R09, R10, R12, R13, R14 e R26 — foram
**implementados e medidos em 14–15/09/2026** (D39, D40 e D41 decididas no caminho, mais a identidade
da captura em 15/09), e estão **aguardando a revisão do desenvolvimento** pelo outro agente. Entrega
técnica não é aceite: a etapa continua reaberta até essa revisão e a sua decisão.

---

## 2. Decisões já fechadas

### D44 — decidida em 16/09/2026

**O próximo bloco de sincronizações refaz o diário de mutações no formato novo, com uma mutação só
de representação; até lá `efeito_liquido` mantém as duas leituras.** Duas consequências da terceira
rodada de revisão, decididas juntas:

- as 16 entradas do diário de produção não têm `presenca_apos_commit` (RV10-2-06/07) e continuam
  lidas pelo `RETURNING` canonizado — são a única prova do ciclo real hoje, e reconstruir presença
  passada a partir da origem atual fabricaria evidência. A leitura antiga sai de `efeito_liquido`
  quando o diário for refeito;
- as 40 PKs do bruto real são inteiros e UUIDs limpos, e a fronteira da identidade (`08`, `+8`,
  `0x8`) só é medida em teste (macro renderizada e ciclo em bancos efêmeros). No próximo bloco, a
  CLI altera a PK de uma testemunha apta para outra representação (`'8'` → `'0x8'`) entre duas
  capturas certificadas, e o diário e os modelos reais provam `mantida` — sem tocar catálogo,
  gerador ou oráculo. Injetar representações alternativas pelo gerador foi descartado: mudaria
  catálogo, oráculo, versão do catálogo (D34) e limpeza, e exigiria ADR.

### D42 — decidida em 15/09/2026

**O CTE `limpo` dos modelos de limpeza do legado é `materialized` no PostgreSQL, e fica como estava
nos demais adaptadores.** Fechada pelo [ADR-0047](adr/0047-materializar-o-cte-de-limpeza-do-legado.md),
que registra o custo aceito: o SQL emitido pelo gerador passa a depender do adaptador, o custo do
mesmo CTE no BigQuery não foi medido, e a impressão digital da D34 move com o texto — a `versao`
do catálogo avança para 9 sem que uma regra tenha mudado, leitura literal decidida por você.

Levantada e decidida no mesmo dia, pela contraprova (b) da revisão de desenvolvimento: o planejador
embutia o CTE em cada referência do `case` de achados e reavaliava a limpeza inteira a cada uma —
`carts` 94 s → 8,7 s, `cart_items` 295 s → 25 s, o lote inteiro 656 s → 47 s
([Capacidade §2.11](capacidade_e_recuperacao.md#211-o-cte-limpo-embutido-em-cada-referência--15092026)).

### D36 — decidida em 15/09/2026

**A Etapa 12 valida a fase local por partes; a exigência de *batch* e *streaming* simultâneos sai
do plano, e a demonstração sob concorrência é contrapartida da fase GCP.** Fechada pelo
[ADR-0046](adr/0046-validar-a-fase-local-por-partes.md), que registra o custo aceito: a fase local
termina sem medir contenção de recursos entre o Airbyte e o Beam, e o primeiro número disso é da
nuvem.

Levantada em 07/09/2026 pela medição de capacidade (~8 GB de ambiente + ~4 GB de trabalho numa
máquina de 11,5 GB; travamento com OOM *killer* 151 vezes em uma hora). A parte estrutural já tinha
sido fechada pelo [ADR-0041](adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md); o que restava era
escopo, e das três saídas — terminal puro, fatiar a validação, tirar a simultaneidade — o Owner
escolheu a terceira.

### D39 — decidida em 14/09/2026, em três rodadas

**A exclusão física do legado é detectada só no bruto retido, pela PK declarada por tabela e
canonizada pelo tipo, entre capturas certificadas, em dois modelos de `trusted` (memória e
intervalo) — e nenhuma dimensão recebe marca por isso.** Fechada pelo
[ADR-0045](adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md), que registra o custo
aceito: o datamart não retém o membro removido — a memória é o bruto e a tabela de auditoria —, e a
comparação cumulativa cresce com o número de capturas.

As duas primeiras formas (aptos entre capturas; marca `is_deleted` por `hard_deletes` nos
*snapshots*) foram descartadas pelas consequências que a revisão do plano mostrou (P03/P04/P12,
P14/P24–P27) e pela constatação de que, sob os ADRs 0038 e 0042, a remoção já cascateia para fora
das fatos — a marca não protegeria integridade. O ADR-0042 fica **confirmado**.

### D40 — decidida em 14/09/2026

**Nas linhas legadas, `event_sequence = legacy_row_id` é desempate técnico dentro da captura, e só
isso** — sem promessa de ordem observada do evento nem de estabilidade entre recapturas. Fechada por
nota de referência no [ADR-0039](adr/0039-alcance-da-procedencia.md) (nenhum ADR aceito prometia
o contrário); o dono é [Origem Legada §4.1](origem_legada.md#41-a-identidade-da-captura-e-a-da-ocorrência).
Levantada pelo achado R26 da terceira revisão. Alternativas recusadas: exigir estabilidade entre
recapturas (impossível com identificador renumerado; exigiria chave de negócio + instante, e ainda
seria ordem de captura) e anular a coluna no legado (exigiria conferir todo consumidor que assume
não-nulo).

### D41 — decidida em 14/09/2026

**Toda captura do legado é certificada por conteúdo, por *stream* e por *job*, em duas fases, em
`governance.legacy_captures`; só captura `complete` nas 40 tabelas é elegível.** Fechada pelo
[ADR-0044](adr/0044-certificar-cada-captura-do-legado-por-conteudo.md), que registra o custo aceito:
uma exceção **delimitada** ao [ADR-0023](adr/0023-escopo-do-schema-governance.md) — o fluxo lê uma
tabela de `governance`, só para elegibilidade —, e o contrato `sync_id = job_id` fixado por teste na
versão instalada do Airbyte.

Levantada e decidida no mesmo dia, no plano de fechamento da Etapa 10 (achado R09 da terceira
revisão, e P01, P02, P15 e P30 das revisões do plano). O que a motivou, medido em 14/09/2026: a
geração 15 retida tem 39 tabelas e o *job* dela terminou `succeeded` com `rowsSynced` exato — máximo
e total a aceitariam; e contagem não vê alteração sem mudança de contagem nem perda compensada por
duplicata.

### D38 — decidida em 08/09/2026

**O armazém roda com `jit=off`, o `staging` do ramo legado é materializado como tabela, e os três
contêineres PostgreSQL declaram teto de 2 GB.** Fechada pelo
[ADR-0043](adr/0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md), que registra o custo
aceito: o [ADR-0016](adr/0016-materializacao-por-camada.md) passa a ter uma exceção **por origem**, e
`jit=off` vale para o armazém inteiro, inclusive para consultas que poderiam se beneficiar do JIT.

Levantada e decidida no mesmo dia, porque a estação travou duas vezes antes de a causa ser
encontrada. O que a motivou, medido em 08/09/2026: a mesma view de limpeza, na mesma sessão nova,
custa **281 MB com `jit=off` e passa de 2 GB com `jit=on`**; e a união de quarenta braços do
`legacy_records` passa de 2 GB sobre views mesmo com o JIT desligado, contra **180 MB** sobre
tabelas. Um `backend` chegou a **7,7 GB numa máquina de 11,5 GB**, e o que morreu foi o ambiente de
trabalho, não a consulta.

É também o que desbloqueia o **R13**: os `timeouts` que a segunda e a terceira revisões registraram
como "detecção integral no banco não medida" eram esta falha.

### D37 — decidida em 08/09/2026

**A captura legada é reconciliada na fato incremental por `delete+insert` no ramo legado**, com o
ramo de *streaming* mantendo o filtro por tempo de evento. Fechada pelo
[ADR-0042](adr/0042-reconciliar-a-captura-legada-na-fato-incremental.md), que registra o custo
aceito: a exceção do [ADR-0016](adr/0016-materializacao-por-camada.md) passa a ter duas estratégias,
uma por origem, e a idempotência do ramo legado deixa de vir da `unique_key`.

Levantada pelo achado R25 da terceira revisão. O que a motivou, medido em 08/09/2026: a janela
incremental alcançava **7 de 553** movimentos legados, porque o corte usa `max(occurred_at)` global e
o retail está quatro dias à frente da captura legada.

### D35 — decidida em 07/09/2026

**O pai sobrevive à rejeição do filho.** A invariante que atravessa entidades é exigida em todo
lugar onde a quarentena **não** explica a diferença — e só ali. Nenhum registro bom é descartado, e
nenhuma divergência fica muda: cada uma precisa de contrapartida rastreável até o motivo.

O ADR-0038 continua valendo sem inversão: a rejeição cascateia do pai para o filho, e não ao
contrário. O que mudou é que os testes passaram a afirmar algo **mais forte** do que antes — não que
os números fecham, mas que todo lugar onde não fecham tem registro em quarentena explicando. A
implementação é a macro `explicado_pela_quarentena`, aplicada a quatro invariantes.

Medido no fechamento: 75 linhas divergentes, todas do legado e **todas explicadas** — 58 pedidos, 12
remessas sem caixa, 3 saldos e 2 reservas.

### D34 — decidida em 07/09/2026

**A versão declarada continua sendo o rótulo, e uma impressão digital passa a guardá-la.**
`catalog_version` segue legível e avançando à mão; `treatment_fingerprint` é derivada do SQL que o
tratamento **gera** — os 40 modelos de limpeza e a classificação —, e não do código-fonte. A
distinção importa: hashear `regras.py` faria uma variável renomeada invalidar auditoria sem que uma
linha do armazém mudasse.

A quarentena passou a **recusar a substituição** quando a impressão diverge sob a mesma versão: a
auditoria antiga fica, a nova entra ao lado, e `legacy_versao_do_tratamento_e_univoca` diz em voz
alta que a versão precisa avançar.

A regra foi exercitada na própria entrega. Acrescentar a coluna mudou o que o tratamento produz, o
teste acusou, e o remédio foi o que ele prescreve: `versao` avançou de 3 para 4. A recusa também já
está observada em dado real — a versão 3 guarda duas impressões lado a lado, 2.280 linhas de uma e
19.243 da auditoria anterior ao contrato.

### D33 — decidida em 07/09/2026

**A classificação continua conferindo contra a origem inteira, e uma medida separada responde pelo
armazém.** Conferir o total do pedido contra o conjunto empilhado mediria a pergunta mais útil e
seria circular: o que é empilhado depende da classificação, que passaria a depender do
empilhamento. A circularidade não é hipótese — custou 114 pedidos falsamente não reconciliados.

O que faltava não era trocar de universo, era ter o segundo número. Ele agora existe em
`legacy_order_totals_divergence`, que é **medida e não regra**: nenhuma linha ali rejeita nada. As
duas origens entram, de propósito, para que o zero da origem principal seja resultado observado e
não suposição embutida.

Medido no fechamento: 66 pedidos do legado divergem, somando **R$ 465.293,49**, e os 66 têm
contrapartida em quarentena. A origem principal não aparece.

---

**D32 — decidida em 06/09/2026.** O Owner autorizou `NULL_REQUIRED`, preservando
`NULL_DISGUISED` como achado de conversão e mantendo campos opcionais corrigíveis.
Contexto e consequências no [ADR-0040](adr/0040-rejeitar-nulo-em-campo-obrigatorio.md).
A decisão libera a implementação; não significa aceite de conclusão da Etapa 10.

### D31 — encerrada

A remessa que nascia sem item: 91 das 3.647, todas em pedidos divididos, porque o repartidor do
gerador dava zero unidades ao primeiro lote quando cada item do pedido tinha quantidade 1.

| | |
|---|---|
| **Decisão** | Corrigir o gerador e re-medir, entre as três alternativas apresentadas |
| **Código** | `522a8fc` gerador e testes · `04a824a` descarte conferido do estado do streaming · `e5ff5ca` teste dbt bloqueante · `1e6da99` re-medição publicada |
| **Resultado** | Nenhuma remessa sem item; P13 e `trusted.shipments` reconciliam em 3.166 dos dois lados, contra 3.141 e 3.221 antes; `dbt build` com `WARN=0` |
| **Regra que impede a volta** | [Invariante 13](modelo_de_dados.md#4-invariantes-de-negócio) — toda remessa contém ao menos um item —, com teste bloqueante |
| **Evidências** | [Capacidade §2.7](capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026) · [Streaming §7.2](streaming.md#72-revalidação-da-d31) · [Execução Local §3.2](execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming) |

**O que ela ensinou, e vale além dela:** regerar a origem com o caminho quente de pé corrompia em
silêncio — 2.246 movimentos órfãos e 13.626 chaves com payload diferente antes do descarte do
estado —, porque nenhum alvo limpava o destino do *streaming* e o `staging` desempata em favor dele.
O procedimento reproduzível nasceu daí.

Nenhum ADR novo foi necessário, e nenhum aceito foi reescrito: a re-medição entrou como execução
nova, ao lado das históricas.

---

## 2. O que já foi fechado

As três lacunas de contrato que a Etapa 10 levantou na abertura foram fechadas em 05/09/2026, por
interrogatório: como o legado retém as capturas
([ADR-0037](adr/0037-reter-capturas-do-legado-por-acrescimo.md)), o que acontece com a duplicata
exata e com o filho de um pai rejeitado
([ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)), e onde a procedência passa
a existir ([ADR-0039](adr/0039-alcance-da-procedencia.md)).

As decisões de abertura das Etapas 8 e 9 foram fechadas
no mesmo dia em que foram levantadas, em 05/09/2026: o grão em que a entrega é medida
([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)), a procedência da data realizada
([ADR-0034](adr/0034-entrega-do-livro-de-eventos.md)), o escopo do inventário dimensional
([ADR-0035](adr/0035-aposentar-dimensoes-sem-pergunta.md)) e a âncora da janela de recompra de P16
([ADR-0036](adr/0036-recompra-ancorada-no-pedido.md)). As da Etapa 7 foram fechadas em 04/09/2026
nos
[ADR-0031](adr/0031-aterrissagem-do-caminho-quente-em-raw.md) e
[ADR-0032](adr/0032-fonte-python-no-lugar-do-kafkaio.md). Todas por interrogatório com alternativas.

Os marcos **M0** (Termo aprovado), **M1** (decisões registradas), **M2** (ambiente reproduzível),
**M3** (primeiro fluxo completo) e **M4** (*streaming* em operação) estão fechados. As Etapas 3 a 10
foram entregues — o modelo dimensional está completo, as 16 perguntas de negócio têm view e a
segunda origem atravessa o fluxo inteiro —, e a próxima é a **Etapa 11 — Consolidação de governança
e qualidade**.

O único número que o projeto ainda carregava rotulado como **não medido** — o *allowed lateness* do
[ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) — foi medido na Etapa 7, e a
medição derrubou a hipótese: 300 s ficavam abaixo da mediana do atraso real. O valor vigente é
1200 s ([Streaming §3.3](streaming.md#33-eventos-atrasados)).

## 4. Onde cada item foi parar

Registro de encerramento, para que nenhuma decisão pareça ter sumido.

### Aprovações

| # | O que | Resultado |
|---|---|---|
| A1 | Termo de Abertura | **Aprovado em 04/09/2026** — [Termo](../Abertura_de_projeto.md) v1.2, §11 |
| A2 | Riscos e princípios em artefatos próprios | Confirmado — [Riscos](riscos.md) e [Princípios](principios.md) permanecem separados |
| A3 | Estrutura de artefatos e mapa da documentação | Confirmado, com a contagem de artefatos removida: a tabela do [README](../README.md) é a fonte |

### Decisões

As dezoito foram fechadas em quatorze ADRs temáticos, **0012** a **0025**. A correspondência está na
seção 2 do [Registro de Decisões](adr/README.md), coluna *Resolve*.

Depois delas, cada etapa trouxe escolhas novas, decididas por você na hora com as alternativas na
mesa — do ambiente Python ([ADR-0026](adr/0026-uv-para-ambiente-e-dependencias.md)) ao grão da
medição de entrega ([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)). Todas estão na seção 2 do
[Registro de Decisões](adr/README.md).

### Questões que não eram ADR

| # | Questão | Resultado |
|---|---|---|
| Q1 | *Policy tags* aplicadas à mão ou por automação | Escopo aberto para CI/CD mínimo — [ADR-0025](adr/0025-policy-tags-por-fluxo-automatizado.md), com federação de identidade como condição |
| Q2 | Orçamento de 4 GB e conforto do ambiente local | Premissa substituída: alto volume passa à fase GCP, e o ambiente local é dimensionado por cobertura — [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) e [Termo](../Abertura_de_projeto.md) §8 |
| Q3 | Perfil padrão de desenvolvimento | Absorvida pela Q2: os perfis antigos foram aposentados pelo [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) |
| Q4 | O que significa "revisado" na definição de pronto | Revisão integral do declarativo, amostragem no derivado — [`CLAUDE.md`](../CLAUDE.md) §5 e §7 |

## 5. Medido e não explicado

**Duas fatos ficaram lentas depois do empilhamento (07/09/2026).**
`fact_payment_transaction` leva **595 s** e `fact_sales_order_item`, **186 s**; as outras oito ficam
abaixo de 3,3 s. As tabelas envolvidas são pequenas — 7.427 transações, 3.830 pagamentos, 3.661
pedidos e 1.574 versões de cliente —, e nada nesse tamanho justifica dez minutos.

Duas hipóteses, **nenhuma verificada**: a junção temporal com `dim_customer` deixou de ter
`source_system = 'retail'` como constante e passou a ser igualdade entre colunas, o que tira do
planejador a seletividade que ele tinha; ou a máquina estava sob pressão de memória durante as
medições (9,2 GB de 11,7 GB em uso, com o Airbyte segurando ~3,6 GB em JVMs).

Não há medição anterior ao empilhamento para comparar, então **não afirmo que seja regressão**. O
que está registrado é o número, não a causa.

---

## 6. Do lado do assistente

A D31 está encerrada. Na Etapa 10, tudo o que a terceira revisão pediu está **implementado e
medido** (15/09/2026): certificação de captura por conteúdo em duas fases (ADR-0044), detecção de
exclusão física no bruto retido (ADR-0045), schema legado no Alembic, oráculo por ocorrência para
o lote inteiro, contrato de `event_sequence`, e os documentos com o estado medido. As medições
estão no dossiê de revisão entregue ao outro agente e nos donos documentais. A revisão de
desenvolvimento voltou em 15/09/2026 com seis bloqueantes e seis ajustes (RV10-01…12); onze foram
corrigidos e medidos no mesmo dia, e o décimo segundo (prova local da escrita BigQuery) foi adiado
por decisão sua para a Etapa 13 — a situação de cada um está no `REVISAO.md`, que espera a próxima
rodada. **Nenhum aceite da Etapa 10 foi presumido**: a etapa fecha quando a revisão do
desenvolvimento e você o disserem.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
