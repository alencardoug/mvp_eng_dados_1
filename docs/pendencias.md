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
| Etapa atual | Etapa 10 — Corte 6: origem legada, reaberta |
| Aprovações pendentes | 0 |
| Decisões pendentes | 1 — D36 |
| Última revisão | 08/09/2026 |

---

## 1. Esperando você

### D36 — a Etapa 12 não cabe na máquina como está dimensionada

A validação final exige tudo de pé ao mesmo tempo: ~8 GB só de ambiente
([Capacidade §2.4](capacidade_e_recuperacao.md#24-medido-na-etapa-7--o-caminho-quente)). O que esse
número nunca contou é o ambiente de trabalho — VS Code, sessões de agente e navegador somam ~4 GB,
medidos em 07/09/2026. Numa máquina de 11,5 GB são 12 GB pedidos: déficit, não margem. O travamento
que originou esta pendência está registrado na
[Capacidade §2.8](capacidade_e_recuperacao.md#28-o-número-de-dimensionamento-não-incluía-o-ambiente-de-trabalho--07092026).

Três saídas, e a escolha é de escopo, não técnica:

1. **Rodar a Etapa 12 por terminal puro**, com o ambiente de trabalho fechado — sem VS Code, sem
   agente, sem navegador. Libera os ~4 GB e faz o número de §2.4 caber com folga. Custa a
   observabilidade de quem acompanha: a validação é conduzida por `make` e lida por log.
2. **Fatiar a validação** em blocos que caibam, com o critério de conclusão da etapa satisfeito por
   partes em vez de por uma execução única. Preserva o ambiente de trabalho e exige definir o que
   uma execução completa comprova que a soma dos blocos não comprova.
3. **Tirar do plano** a exigência de simultaneidade, assumindo que a fase local não a demonstra e
   registrando a contrapartida na fase GCP.

**O agravante estrutural foi decidido e fechado** pelo
[ADR-0041](adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md): todo serviço permanente do Airbyte
passou a declarar teto de memória. A medição, porém, **não** resolveu o que esta pendência trata —
o ocioso caiu 7% e o pico durante a sincronização não caiu, porque é dominado pelos *pods de job*.
O déficit da Etapa 12 continua inteiro.

O risco imediato está tratado sem decisão sua: `make airbyte-up`, `airflow-up` e `stream-up` pausam
o ambiente conflitante antes de subir (**R11**), dimensionados pelo pico medido de 5,0 GB. Recusa só
resta quando nem a troca basta, e aí `FORCE=1` autoriza.

---

## 1.1 Decididas e implementadas

As três questões que a revisão da Etapa 10 levantou — D33, D34 e D35 — foram decididas em
07/09/2026 e estão implementadas; o registro delas está abaixo.

Os bloqueios que restam da revisão são **implementação**, não decisão: R10 (detecção de exclusão
física), R12 (migração Alembic do schema legado) e R13 (oráculo independente da cascata).

---

## 2. Decisões já fechadas

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

A D31 está encerrada. Na Etapa 10, gerador, ingestão com retenção e modelos de limpeza já existem.
A correção da precedência entre rejeição e conversão foi validada em 06/09/2026
([Qualidade §5.1](qualidade_de_dados.md#51-validação-dos-valores-tratados--06092026)).
Classificação com contexto, quarentena, empilhamento com procedência e DAG estão em implementação;
a D32 foi decidida e deixou de pausar o tratamento. Nenhum aceite da Etapa 10 foi presumido.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
