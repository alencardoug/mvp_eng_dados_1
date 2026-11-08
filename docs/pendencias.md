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
| Etapa atual | Etapa 12 aceita em 04/10/2026: o **M5** está fechado e a fase local, concluída (`v1.0.0`). A versão de manutenção `v1.1.0` foi aceita em 05/11/2026, com a *tag* `v1.1.0` (§1.1; [plano](plano_de_desenvolvimento.md#versão-de-manutenção-v110)). A Etapa 13 — replicação no GCP com Terraform (M6) — foi **autorizada em 06/11/2026** e está em planejamento, no plano transitório `PLANO_etapa_13.md` |
| Aprovações pendentes | 0 |
| Verificações adiadas | 1 (V1, da revisão da v1.1.0, lotes 1 a 3, registrada em 05/11/2026) |
| Decisões pendentes | 4 (D63 e D64, levantadas pela validação do material de estudo em 04/10/2026; D66, levantada pela revisão do roteiro de regeneração da v1.1.0 e adiada para depois dela; D43, adiada de propósito para a fase GCP e **medida em 07/11/2026**). A D65 e a D67 foram fechadas pela v1.1.0, a D68 a D74 na abertura da Etapa 13, a D76 e a D77 no G1 dela, a D62 e a D78 no G2.3, a D79 no G4, a D80 no G5, a D81 no G2.4, a D82 e a D83 no G2.3 e a D84 a D87 na revisão dos roteiros da janela (§2) |
| Última revisão | 08/11/2026 — D84 a D87 levantadas pela revisão dos roteiros da janela e decididas; 07/11/2026 — D76 decidida, D43 medida, D77 levantada e decidida, no G1 da Etapa 13; D62 e D78 no G2.3; D79 no G4; D80 no G5; D81 no G2.4; D82 e D83 no G2.3 (08/11) |

---

## 1. Esperando você

As duas primeiras nasceram da validação do material de estudo da fase local, em 04/10/2026, que
rodou cada laboratório na máquina. Nada foi alterado no código; as saídas estão em
`data/medicoes/material_estudo/` (fora do Git), e o relato inteiro, na §15 de
[`CONVERSAS_COM_CHAT/PLANO_material_de_estudo.md`](../CONVERSAS_COM_CHAT/PLANO_material_de_estudo.md),
onde aparecem como achados A a C. O B, a contagem dupla no saldo do alerta, foi a D62, fechada no
G2.3 da Etapa 13 (§2). O achado D, a venda antes do lançamento, foi a D65, fechada pela
v1.1.0 (§2).

### D63 — o medidor do *streaming* encerra o Beam antes de o ramo de alerta drenar

**Pergunta:** o que `make medir CENARIO=streaming` deve esperar antes do SIGINT, e a restauração deve
reposicionar o *offset* do grupo do Beam?

**Medido em 04/10/2026.** O medidor espera o destino alcançar o corte (`stream-wait`, ramo 1) e
encerra o Beam; os alertas saem do ramo 2, que só recebe painéis quando o *watermark* fecha as
janelas. Com `LIMITE=2200`, zero alertas e nenhuma linha "saldo semeado" no *log*, contra cerca de
60 aberturas que um oráculo por janela, em SQL, previa. Repetido com 200 eventos e 90 s de espera: 8
alertas logo em seguida, e 14 alguns minutos mais tarde. O *offset* confirmado do grupo `mvp_ed1_beam` era 6009, num tópico
cujo *log* começa em 13700 — estado deixado pela restauração de 25/09 —, e o Beam releu 13.700
mensagens antes das novas. O "11 alertas" da linha 6 do B5 também dependeu de tempo.

*Opções:* **(a)** esperar, com prazo, um sinal do ramo de alerta (o *watermark* passar do maior tempo
de evento produzido, ou o contador `alertas_emitidos` estabilizar) e, na restauração, reposicionar o
grupo no início do *log* ao refazer o *snapshot* — recomendada; **(b)** uma espera fixa depois do
`stream-wait`; **(c)** só documentar que o medidor não mede alertas.

*Efeito de não decidir:* a contagem de alertas de uma medição não é reproduzível, e o oráculo de
alerta do roteiro pode passar ou falhar por tempo.

### D64 — a chave Fernet do Airflow gerada pelo projeto é inválida

**Pergunta:** corrigir a geração da `AIRFLOW_FERNET_KEY` e trocar a chave desta máquina?

**Medido em 04/10/2026.** `airflow connections add` e `airflow variables set` falham com
`Could not create Fernet object: Fernet key must be 32 url-safe base64-encoded bytes`. O `Makefile`
gera a chave com 32 caracteres alfanuméricos, em `make env` e em `airflow-up`;
o Airflow exige 32 bytes em base64 seguro para URL (44 caracteres). Nunca apareceu porque nada no
projeto grava Connection nem Variable.

*Opções:* **(a)** gerar nos dois lugares com `head -c 32 /dev/urandom | base64 | tr '+/' '-_'`, sem
pré-requisito novo, com teste em `test_makefile.py`, e trocar a chave desta máquina recriando os
contêineres do Airflow — sem dado cifrado a perder, porque nada foi gravado — recomendada; **(b)**
só documentar a limitação.

*Efeito de não decidir:* nenhum no fluxo atual; qualquer uso futuro de Connections ou Variables
falha.

### D66 — a P13 não conta a remessa entregue cujos itens foram todos rejeitados

**Pergunta:** a P13 passa a ler uma fato no grão da remessa, para contar toda remessa entregue como o
[ADR-0033](adr/0033-entrega-medida-em-dois-graos.md) a define, ou a definição muda?

**Medido em 23/10 e 03/11/2026,** em sessão somente leitura: 144 remessas legadas entregues em
`trusted.shipments` e 132 em `analytics.fact_shipment_item`; do varejo, 3.166 nos dois. As 12 que
faltam são legadas, aceitas como remessa e com o pedido em `trusted`, e nenhum item delas chegou lá:
os 17 itens da captura selecionada foram rejeitados em cascata (`PARENT_REJECTED`) — 17 itens de
pedido, 6 variantes e, na raiz, 4 produtos do legado rejeitados por defeito próprio. A view
`on_time_delivery_rate_by_carrier` reduz a fato do item a remessa com `distinct`, e remessa sem item
aceito não tem linha para reduzir; o ADR-0033 diz que o denominador são as remessas entregues. As
consultas e as saídas estão no `bi-como-codigo` — M27, M32 e M38 do
[plano](https://github.com/alencardoug/bi-como-codigo/blob/c7690fe/PLAN.md#2-what-was-measured),
onde a questão nasceu como o O6 do
[roteiro de regeneração](https://github.com/alencardoug/bi-como-codigo/blob/c7690fe/docs/regeneration_runbook.md#7-not-verified-and-observations).

**Decisão de 03/11/2026: fora da v1.1.0.** Corrigir agora reabriria a conciliação da P13 no roteiro
de regeneração e acrescentaria uma fato no meio da manutenção; a regeneração da v1.1.0 muda o número
de qualquer forma. Até a decisão, a descrição da view diz qual população é contada.

*Opções:* **(a)** uma fato no grão da remessa, com ADR, lida pela P13 — recomendada: a pontualidade
é atributo da remessa, e estas passaram pelas regras; o que se rejeitou foi o conteúdo, três níveis
acima; **(b)** emendar o ADR-0033 e o [glossário](glossario_de_negocio/entrega_no_prazo.md): a
entrega no prazo conta só a remessa com algum item aceito.

*Efeito de não decidir:* nenhum teste falha; a taxa do ramo legado deixava de fora 12 de 144
remessas entregues (8%) no dado da v1.0.0. No da v1.1.0 ficam de fora **16** remessas legadas
entregues, todas com os itens rejeitados em cascata (`parent_rejected`), cada uma explicada pela
reconciliação da P13 (04/11/2026, na regeneração); o total de remessas entregues não foi recontado.

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

*Acrescentado em 17/09/2026, para decidir junto:* há **três** noções de "mesma chave" no código —
igualdade textual na resolução do pai (`classification.sql`, CTE `edges`), `identidade_canonica`
(decimal por extenso, R29, reconciliação da quarentena) e `chave_canonica` (gramática do `cast`,
ADR-0045). Um cliente cuja PK passasse de `'8'` a `'0x8'` seria `mantida` no intervalo e órfãria
os filhos na limpeza. O bruto real não tem chave assim; até a decisão, o teste
`legado_vinculo_nao_diverge_por_representacao` (gerado, 56 vínculos) acusa o filho que só encontra o
pai pela forma canônica — contraprova feita em 17/09 com um cupom apontando `0x1` para a campanha
`1`. Unificar é mudança de tratamento (versão do catálogo, oráculo, auditorias) e pede ADR.

*Medido em 07/11/2026* (Etapa 13, G1.6; `python -m mvp_ed1.gcp.identidades`, as macros reais
renderizadas na metade de cada alvo, uma forma por consulta, sobre as 115 formas de
`tests/test_legado_remocao.py::FORMAS`):

| Noção | Paridade PostgreSQL × BigQuery | Divergência com a `chave_canonica` (PostgreSQL) |
|---|---|---|
| texto | igual por construção | separa **todos** os 264 pares que a chave junta (227 `bigint`, 8 `integer`, 8 `smallint`, 21 `uuid`) |
| `identidade_canonica` | 114 de 115 (1 recusada pelos dois; **1 divergente**, a D77); **115 de 115** depois dela | separa 241 desses 264 pares — `'8'`×`'+8'`, `'8'`×`'0x8'`, `'8'`×`'0b1000'`, UUID em outra caixa —; **nunca** junta o que a chave separa |
| `chave_canonica` | **115 de 115** | — |

A `chave_canonica` é paritária nas formas medidas. As três
noções são uma cadeia — texto mais fina que identidade, identidade mais fina que chave —, e a
divergência entre elas é a do cliente `'8'` → `'0x8'` acima, agora contada. **Ainda não se declara
paridade de identidade** (PLANO_etapa_13 §2.3): o Owner decide com o número, depois da janela.

### V1 — verificações adiadas da revisão da v1.1.0, lotes 1 a 3 (registrada em 05/11/2026)

**Pergunta:** quando voltar às verificações que a revisão da v1.1.0 deixou de fora? Nenhuma é
bloqueante: os três lotes fecharam sem achado aberto — o 1 em `28044c7`, o 2 em `20ea4f3` e o 3 em
`4cf41ff`. Os limites **aceitos** já estão nos donos documentais e não se repetem aqui; esta lista
é do que **não foi exercitado**, para medir depois. Não é decisão de modelagem: é marcar o momento.

**Nos três lotes.** O Codex rodou o `check-offline`, o histórico de segredos e sondas em cópia, nunca
o `make check` completo nem os testes de integração; o número completo de cada lote é do autor
(`PASS=907` e 1079 testes no fim do lote 3, em `7e12874`).

**Lote 1 — o livro retido, a recuperação H7, o portão H6 e o oráculo T3.** Os limites aceitos estão
na [Origem Legada §4.3](origem_legada.md): um chamador de captura vivo por vez, a colisão de
`hashtext` e o SCD fora do T3. Ficaram sem exercitar:

1. a concorrência real de dois chamadores de captura, que é o limite declarado;
2. a retomada depois da parada por ambiguidade de janela (RVL1-2-02). Não há comando que associe o
   *job* à tentativa, e a saída é o caminho de volta pelo pacote ou uma resolução sua; nenhuma
   das duas foi ensaiada;
3. testes de integração mutantes do livro e da recuperação.

**Lote 2 — identidade no consumo, ADR-0049, `lineage --json` e o login de leitura.** Os limites
aceitos estão na [Governança §7](governanca_de_dados.md): o alcance de "não interfere" e o recorte do
oráculo do leitor. Ficaram sem exercitar:

4. a guarda de identidade é **sintática**: "as 16 views dão `[]`" quer dizer a guarda aplicada ao SQL
   de cada modelo, não as views executadas no armazém nem as métricas recalculadas, e não há prova
   exaustiva das construções SQL;
5. um inventário do estado do armazém antes e depois das sondas do login de leitura. A obrigação do
   consumidor do `lineage --json` — `generated` não é quebra (RVL2-06) — está no contrato do
   [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/895b886/PLAN.md#35-the-contract-with-eng_dados).

**Lote 3 — catálogo: descrição herdada, `domain`/`owner`, D66/D67.** Os limites aceitos estão na
[Governança §5.1](governanca_de_dados.md) (o escritor só em bloco) e na
[Qualidade §4](qualidade_de_dados.md) (as formas que a guarda do fuso não lê). Ficaram sem exercitar:

6. um `.yml` à mão que não seja em bloco — coluna em fluxo (`- {name: x, …}`) ou `-   name:`. Hoje a
   saída é recusada, o que foi medido; o escritor não as edita;
7. as formas de literal de instante que a guarda não lê — Jinja montado em partes, dollar quoting,
   `E'…'`, `cast(('…') as …)` e uma string do próprio Jinja com `}}` ou `%}`. A semântica de
   `E'…'` e de `cast(('…'))` não foi conferida no PostgreSQL;
8. uma fonte de pacote de verdade. A recusa (`foreign_sources`, `overrides`) foi exercitada por
   injeção no manifest e em projeto mínimo, sem pacote real com fontes e sem manifest adulterado;
9. as premissas da compilação recente: macro nova ou apagada e o `dbt_project.yml` não entram na
   conferência de manifest atrasado (RVL3-2-07); quem as cumpre é o *build* que o `make check` faz
   antes.

*Recomendação:* voltar a cada grupo antes da próxima alteração que toque o código dele —
`src/mvp_ed1/recovery/` e o livro (lote 1), a guarda de identidade e o login de leitura (lote 2),
`src/mvp_ed1/models/` e `tests/test_vigencia_em_utc.py` (lote 3) —, e a todos na abertura da
Etapa 13 (GCP), que reescreve recuperação, acesso, catálogo e guardas para o BigQuery.

*Efeito de não decidir:* nenhum no projeto como está. Uma edição futura em uma das formas acima é
recusada ou fica fora da guarda, e a lista diz onde olhar.

---

## 1.1 Decididas e implementadas

As três questões que a revisão da Etapa 10 levantou — D33, D34 e D35 — foram decididas em
07/09/2026 e estão implementadas; o registro delas está abaixo.

Os achados que a terceira revisão deixou abertos — R09, R10, R12, R13, R14 e R26 — foram
**implementados e medidos em 14–15/09/2026** (D39, D40 e D41 decididas no caminho, mais a identidade
da captura em 15/09). A revisão do desenvolvimento correu em sete rodadas (15–17/09/2026), com os
achados de cada uma fechados e medidos antes da seguinte; a sétima não trouxe achado. **A Etapa 10
foi aceita em 17/09/2026, condicionada ao bloco da D44** — executado e medido no mesmo dia (§2); a
condição está satisfeita.

**A Etapa 11 foi aceita em 18/09/2026**, no mesmo dia em que fechou: os seis critérios medidos
(plano, Etapa 11), a definição de pronto aplicada e três rodadas de revisão por outro agente
(Codex) sobre `b1a3975..118f17a` — sete achados, quatro bloqueantes e três ajustes, todos aplicados
e confirmados pelo revisor na rodada seguinte; a terceira não abriu nada. Os achados: a
regeneração parcial da classificação apagava modelos do `_sensitivity.yml`; a reconciliação
`oltp → raw` comparava contagens, não conjuntos; o `streamer` recebia `create` em `raw`; um leitor
com `create` a mais não o perdia no `on-run-end`; o espelho de `raw` sobrepunha a declaração
SQLAlchemy; um manifest de `dbt parse` fazia o gerador apagar classificações (e a §3 do Dicionário)
antes de acusar erro; e promover um modelo a um `.yml` à mão era impossível pelo caminho real do
dbt. Cada um tem teste próprio (`tests/test_classificacao_derivada.py`,
`tests/test_reconciliacao_raw.py`, `tests/test_acesso_macro.py`). O aceite ratificou também a
leitura da tabela da [Governança §7](governanca_de_dados.md#7-regras-de-acesso-por-camada) feita em
18/09 (a §10 exige decisão explícita para alteração na política): `streamer` escreve só
`raw.inventory_movements_stream`, sem `create` no schema; `governance` é escrito pela ingestão e
lido pelo dbt e pelo `auditor`; `transformer` escreve também `consumption` e `snapshots`.

**A Etapa 12 foi aceita em 04/10/2026, e com ela o M5**: a fase local está concluída, e o *commit*
de fechamento leva a *tag* `v1.0.0` (D47). Os seis critérios foram medidos em 25/09/2026, num ciclo
do zero ([plano, Etapa 12](plano_de_desenvolvimento.md#etapa-12--fechamento-da-fase-local--m5)), e
a definição de pronto aplicada no mesmo dia. O caminho: o plano transitório passou por seis rodadas
de revisão até 20/09/2026, com D45–D52 decididas na abertura; a revisão de B0, B1 e B4, por seis
rodadas até 24/09 — 26 achados, 15 bloqueantes e 11 ajustes —, com D53–D56 no caminho; o roteiro do
B5, por três rodadas em 25/09 — sete achados —, com D57–D61; e o B5 rodou no mesmo dia, autorizado
por você, no clone `~/Projetos/mvp_eng_dados_1`, que passou a ser o *checkout* de trabalho (D58),
com oito desvios corrigidos na origem. A **revisão final** por outro agente (Codex) cobriu B2, B3, o
código que o B5 corrigiu e o B6, em quatro rodadas entre 03 e 04/10/2026: onze achados na primeira
— dois bloqueantes, a senha de fábrica do Airflow fora do registro e a D48 sem ADR —, seis ajustes
na segunda, três ajustes e uma observação na terceira, nenhum achado na quarta; todos tratados,
cada um reproduzido antes, e três achados próprios no caminho. Três decisões suas saíram dela: o
[ADR-0048](adr/0048-tratar-segredo-achado-no-historico-pelo-tipo-da-credencial.md), que formaliza
a D48; o *chart* do Airbyte fixado em 2.3.0; e a limpeza do usuário web do Airflow, cuja senha de
fábrica nunca chegou a valer. O plano transitório e o dossiê da revisão final saíram do repositório
no *commit* de fechamento e estão no histórico em `46d8243` (`PLANO_etapa_12.md` e `REVISAO.md`); o
diário do B5 está em `data/medicoes/diario_b5.md`, fora do Git.

**A versão de manutenção `v1.1.0` foi aceita em 05/11/2026**, e o *commit* do aceite leva a *tag*
`v1.1.0`. Os critérios foram medidos entre 23/10 e 04/11/2026
([plano](plano_de_desenvolvimento.md#versão-de-manutenção-v110)). A revisão de outro agente (Codex)
cobriu primeiro os documentos da etapa 1.9 e depois a versão inteira, em três lotes por risco: o
livro retido e a recuperação em três rodadas, a identidade no consumo e o login de leitura em sete,
o catálogo em doze — 96 achados, todos tratados, e a última rodada de cada lote sem achado aberto.
As decisões suas tomadas no caminho são as N57 a N63 do
[plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/895b886/PLAN.md#12-the-decisions),
e o que a revisão não exercitou é a V1 (§1). Os dossiês saíram do repositório no fechamento de
cada lote e estão no histórico em `28044c7^`, `20ea4f3^` e `4cf41ff^`.

---

## 2. Decisões já fechadas

### D84 a D87 — da revisão dos roteiros da janela da Etapa 13 (decididas em 08/11/2026)

Levantadas pela revisão dos roteiros (Registro §37 e §38) e decididas antes da P3, todas pela opção
recomendada. Como ficou: [Registro §41](registro_fase_gcp.md#41-as-decisões-d84-a-d87-08112026-tarde).

- **D84 — o segredo no plano salvo** (RV13J-1-01): o binário do plano nasce só do dono (`umask 077`)
  e sai depois do `apply` que o consumiu; o texto, com os sensíveis mascarados, é a evidência. Os
  `.tfplan` já aplicados de `data/medicoes/etapa_13/planos/` saem também. Descartada: autenticação
  `exec` no Kubernetes/Helm e senhas em atributos só de escrita, que mudam *providers* às vésperas.
- **D85 — a paridade local × nuvem é do estado corrente** (RV13J-1-09): o `gcp-oraculos` compara as
  contagens das camadas de estado, o conteúdo das *views* de `consumption` e o catálogo. A
  classificação do legado por captura, que casa por `snapshot_id` (o *job* de cada Airbyte), é
  declarada não comparável entre ambientes, e as contagens de `raw_legacy`, `governance` e
  `snapshots` saem no relatório sem reprovar. Descartada: regerar o local com a mesma sequência de
  capturas, horas de máquina.
- **D86 — o plano da raiz `airbyte/` não chega a `data/`** (RV13J-1-11): nasce e é aplicado na pasta
  temporária do `gcp-airbyte-config`, e só o texto fica (§6.3 do plano). Descartada: guardá-lo em
  `data/medicoes/etapa_13/planos/`, com as senhas dentro.
- **D87 — o caminho quente entra na quarta declarado incompleto** (RV13J-2-01): os lotes concorrentes
  com a mesma chave nova e a recuperação do *worker* no mesmo *job* ficam garantidos pelo desenho e
  não atendidos como prova, e o reenvio fora da janela, provado só na escrita. Descartadas: cortar o
  caminho quente, que tira a reconciliação com *streaming* simultâneo da §7.2; e provar a recuperação
  apagando a VM do *worker* na janela.

### D83 — o Dataflow tem um ensaio de ~1 h na terça (decidida em 08/11/2026)

**Decisão**, a opção recomendada: o primeiro *job* do Dataflow sobe na terça, ~1 h, depois da prova
do caminho quente com o Debezium no GKE, e não na manhã da parte cara — o que só o Dataflow mostra
(instalação no *worker*, rede sem IP público, *watermark* pelo atributo) aparece na véspera. Resolve
a divergência entre o plano ("só na janela") e a Capacidade §2.14 ("~6 h de ensaio"), que foram
alinhados. Como ficou: [Registro §29](registro_fase_gcp.md#29-g23-e-g6-o-lançamento-no-dataflow-08112026-madrugada).

### D82 — os *workers* do Dataflow rodam como `mvp-streamer` (decidida em 08/11/2026)

**Decisão**, a opção recomendada: a conta do papel do caminho quente é a dos *workers*, e ganha
`roles/dataflow.worker` só enquanto o degrau do Dataflow está ligado. Descartada: uma conta própria
do Dataflow, que precisaria receber as concessões do `streamer` — o Beam não personifica dentro do
*worker*, como o Composer faz (D81). Como ficou: [Registro §29](registro_fase_gcp.md#29-g23-e-g6-o-lançamento-no-dataflow-08112026-madrugada).

### D81 — o Composer roda com conta própria, que personifica as contas de papel (decidida em 07/11/2026)

**Decisão**, a opção recomendada, no G2.4/G3 da Etapa 13: o ambiente do Composer tem uma conta só, e
a `fluxo_batch` faz trabalho de dois papéis do ADR-0011 — a captura do legado é do `ingestor`, o dbt
é do `transformer`. A conta do ambiente, `mvp-composer`, tem só `composer.worker`, o *bucket* dele e
a leitura dos segredos da DAG, e **personifica** por token de curta duração o `ingestor` nas tarefas
Python e o `transformer` no dbt; os cinco papéis ficam como estão. Descartadas: um sexto papel com a
união das concessões (ADR novo, e o dbt passaria a escrever `raw`) e rodar como `transformer` com as
do `ingestor` somadas. Como ficou: [Registro §28](registro_fase_gcp.md#28-g24-e-g3-o-composer-em-terraform-07112026-noite).

### D80 — a linhagem por coluna é a nativa do BigQuery; o metadado vai em *labels* (decidida em 07/11/2026)

**Decisão**, as duas opções recomendadas, no G5 da Etapa 13: **por coluna**, a linhagem que o
BigQuery captura sozinho dos *jobs* do dbt, **medida** contra o módulo do Dicionário §3 em vez de
publicada a partir dele — evento OpenLineage customizado não leva linhagem por coluna
([about-data-lineage](https://docs.cloud.google.com/dataplex/docs/about-data-lineage)); **por
tabela**, as travessias de fora do BigQuery publicadas pela API; e `domain`/`owner`/`retention`
como ***labels*** do BigQuery, derivados do `meta` por um *post-hook* do dbt, no lugar de um tipo de
*aspect* do Dataplex (recurso novo e uma API a mais para provar). Revê o texto do G5 no plano, que
previa publicar as arestas do módulo. Como ficou: [Registro §23](registro_fase_gcp.md#23-g5-catálogo-e-linhagem-07112026-noite).

### D79 — as *policy tags*: quais níveis, quem cria, quem lê, quando o fluxo roda (decidida em 07/11/2026)

**Decisão**, as quatro opções recomendadas, no G4 da Etapa 13:

- **Só `confidential` e `personal` viram *tag*** com controle ligado: em `public` e `internal` não há o
  que negar, e cada *tag* ligada exige concessão a todo papel que lê a coluna.
- **O Terraform cria** a taxonomia, as *tags* e o IAM de leitura; o dbt **aplica** as *tags* nas
  tabelas que materializa (D71); o fluxo do ADR-0025 **converge** as que ele não materializa. Resolve
  a divergência entre a Governança §8 ("o Terraform provisiona a taxonomia") e a nota de 07/11 do
  ADR-0025 ("o fluxo cria e mantém"), a favor da primeira — a nota foi corrigida.
- **Os cinco papéis leem** coluna marcada (dado sintético, exposição livre pelo ADR-0049), e o Owner
  também, para o `dbt build` desta máquina; a negação se prova com `mvp-prova-sem-leitura`, o acesso
  de *dataset* do `analyst` sem a concessão.
- **O fluxo roda só na janela**: em *push* do YAML e por disparo manual, pulado enquanto a variável
  do repositório `MVP_GCP_ATIVO` não for `true` — o Owner a liga na janela e a desliga no desmonte.

Como se faz: [Registro §22](registro_fase_gcp.md#22-g4-as-policy-tags-07112026-noite).

### D62 — a semente do saldo do alerta corta no instante em que o *pipeline* é construído (decidida em 07/11/2026)

**Decisão:** opção (a), a recomendada — o instante de início é capturado em `pipeline.construir` e
passado ao `AcumularSaldoEAlertar`, e a semente corta por ele, não pelo `setup`. Vale nas duas fases;
a (b), semear pelo *offset* confirmado, não existe no Pub/Sub. Levantada pela validação do material
de estudo em 04/10/2026 (o evento 15930 entrou na semente e voltou pelo fluxo: 27 → −2 no lugar de
56 → 27) e decidida quando bloqueou o critério "alerta observado" da Etapa 13: na prova do caminho
quente da nuvem, a semente veio com os três movimentos ao vivo que a própria execução já tinha
gravado, e o alerta não saiu ([Registro §19](registro_fase_gcp.md#19-g23-o-lado-do-beam-pubsub-a-escrita-da-d75-e-o-debezium-server-gerado-07112026-tarde)).

### D78 — o tempo de evento do caminho quente chega ao Pub/Sub como atributo (decidida em 07/11/2026)

**Decisão:** envelope achatado no Debezium Server (`ExtractNewRecordState` com `op` e `lsn` como
campos, *deletes* reescritos) e `occurred_at` copiado para cabeçalho pelo `HeaderFrom`, que o *sink*
Pub/Sub passa a atributo; o Beam lê o tempo de evento por `timestamp_attribute`. Debezium Server
`3.7.1.Final` por *digest*. Opção recomendada; as outras eram manter o envelope e perder o tempo de
evento (o atraso que corrige a janela ficaria sem prova no GCP) ou três SMTs que perdiam o `lsn`.
Fontes e o que se conferiu: [Registro §18](registro_fase_gcp.md#18-g23-aberto-o-tempo-de-evento-no-pubsub-07112026-tarde).

### D77 — a `identidade_canonica` local só aceita os brancos que o `numeric` aceita (decidida em 07/11/2026)

**Decisão:** a classe de espaço da `default__identidade_canonica` passa a ser `[ \t\n\v\f\r]`,
a mesma da metade BigQuery e da `chave_canonica` (ADR-0045) — opção (a), a recomendada. Antes, o `\s`
da expressão regular do PostgreSQL casava espaço Unicode (`'\u20038\u2003'`, o 8 entre espaços
*em*), o `::numeric` seguinte o recusava e a **consulta inteira abortava**; o BigQuery devolvia a
forma intacta. Levantada pela medição da D43, no G1 da Etapa 13. Agora a forma passa como texto nos
dois alvos.

**Medido em 07/11/2026:** paridade da `identidade_canonica` em **115 de 115** formas
(`python -m mvp_ed1.gcp.identidades`; era 114); as contagens de pares contra a `chave_canonica` não
mudaram. O caso entrou em `test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai`. O bruto atual
não tem essa forma — se tivesse, o *build* já abortaria —, e por isso nenhuma linha de
`explicado_pela_quarentena` nem de `legacy_order_totals_divergence` muda.

### D76 — o membro desconhecido do agente é contratado à meia-noite de São Paulo (decidida em 07/11/2026)

**Decisão:** o `hired_at` do membro desconhecido de `dim_support_agent` é
`{{ meia_noite(var("period_start")) }}`, como o `valid_from` da mesma linha — opção (a), a
recomendada. Antes, a linha escrevia `date 'period_start'` numa coluna `timestamptz`, e o
PostgreSQL convertia a data na meia-noite do **fuso da sessão** (`2024-01-01 00:00 UTC` no armazém
local, que roda em UTC): uma sessão noutro fuso mudaria o valor sem nada mudar na entrada — a classe
do RVL3-6-04. Levantada pelo G1 da Etapa 13, quando o BigQuery recusou a união de DATE com
TIMESTAMP.

**Medido em 07/11/2026:** `hired_at` = `valid_from` = `2024-01-01 03:00 UTC` nos dois alvos, depois
de `dbt build --select dim_support_agent+` em cada um (31 nós, 0 erros). Nenhuma view de consumo lê
o `hired_at`; muda uma linha sintética, em 3 horas.

### D69 a D74 — decididas em 07/11/2026, na revisão do plano da Etapa 13

Decididas pelo Owner sobre a rodada 1 da revisão do plano transitório `PLANO_etapa_13.md`, que
guarda as alternativas até sair; o escopo inteiro da Etapa 13 foi reafirmado na mesma data.

- **D69 — o CDC da fase GCP pelo Debezium Server com *sink* `pubsub`.** O Datastream não entrega em
  Pub/Sub. [ADR-0051](adr/0051-cdc-da-fase-gcp-pelo-debezium-server.md).
- **D70 — retenção sem trava no *bucket* do livro retido, na janela.** Travar a retenção é
  irreversível e põe um *lien* que impede apagar o projeto
  ([bucket-lock](https://docs.cloud.google.com/storage/docs/bucket-lock)); a trava do
  [ADR-0050](adr/0050-guardar-a-memoria-do-legado-num-livro-retido.md) fica como contrapartida de
  produção, não medida. Nota datada no ADR-0050.
- **D71 — o dbt aplica as *policy tags*** pela propriedade `policy_tags`, gerada do YAML de
  classificação; o fluxo do [ADR-0025](adr/0025-policy-tags-por-fluxo-automatizado.md) cria e mantém
  a taxonomia e converge as tabelas que o dbt não materializa. Motivo: substituir uma tabela no
  BigQuery apaga as *tags* dela. Nota datada no ADR-0025.
- **D72 — o Airbyte grava no BigQuery por *Batched Standard Inserts*, com a identidade do *pod***,
  sem chave de conta de serviço nem HMAC.
- **D73 — `us-central1`, Composer 3 com Airflow 3.2.2, GKE Standard, *chart* do Airbyte 2.3.0.**
- **D74 — projeto dedicado, estado local do Terraform e desmonte em três camadas**, com relógio de
  emergência que desliga o faturamento mesmo se o `destroy` falhar.

### D68 — a fase GCP roda no fator `dev` (decidida em 06/11/2026)

**Decisão:** a Etapa 13 roda no mesmo fator `dev` da fase local, e o trabalho com alto volume sai do
M6 e fica para depois dele, com a operação continuada. Nenhum critério de conclusão da Etapa 13 nem
do [Termo](../Abertura_de_projeto.md) §6 exige volume; a premissa estava no Termo §7, emendado na
versão 1.3, e nas consequências do [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) e
do [ADR-0016](adr/0016-materializacao-por-camada.md), que ganharam nota datada. O motivo é o prazo da
avaliação gratuita da conta GCP: carga maior no Cloud SQL, sincronizações e *build* mais longos são
tempo e crédito que a janela não tem. O fator `cloud` do gerador continua sem número (P5).

### D65 e D67 — decididas em 22/10 e 03/11/2026, fechadas pela v1.1.0

- **D65 — o gerador passa a respeitar o lançamento antes da venda, com a invariante 14.** Decidida
  em 22/10/2026 como a N6 do
  [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/895b886/PLAN.md#12-the-decisions)
  — corrigir o dado sintético agora, antes de tudo —, que é a opção (b), com o lançamento sorteado
  entre o início do período e a primeira venda do produto (N39). Implementada na etapa 1.5 da
  v1.1.0 — a [invariante 14](modelo_de_dados.md#4-invariantes-de-negócio) e o
  [realismo da geração](geracao_de_dados.md#5-realismo-e-coerência) — e levada ao armazém pela
  regeneração de 04/11/2026 — eram 3.130 de 7.500 itens do varejo vendidos antes do lançamento; o
  resultado medido no armazém está nos critérios da
  [versão de manutenção](plano_de_desenvolvimento.md#versão-de-manutenção-v110).
  *Descartada:* a limitação declarada, a opção (a). *Custo aceito:* a regeneração das duas origens
  com a memória do armazém mantida
  ([Capacidade §2.13](capacidade_e_recuperacao.md#213-a-regeneração-da-v110-medida--04112026)), e o
  pedido ORD-0000037 mudou de conteúdo.
- **D67 — a P09 leva o valor capturado dos pagamentos que as autorizações do grupo abriram.**
  Decidida em 03/11/2026, a opção (a), e implementada em `94e0d09`: o capturado de cada pagamento
  entra no grupo da primeira autorização aprovada dele, uma vez só, e
  `p09_capturado_reconcilia_com_a_fato` cobra que o total da view seja o da fato. O tipo do contrato
  não mudou. A regeneração achou que o teste tinha nascido sem a etiqueta `fronteira`, e a primeira
  execução da DAG terminou com o consumo vazio; corrigido em `6d93d72`, com a guarda que confere a
  etiqueta ([Qualidade §7](qualidade_de_dados.md#7-reconciliação-entre-camadas)). *Descartada:*
  tirar a coluna da view e do contrato.

### D61 — decidida em 25/09/2026, ao encerrar a revisão do roteiro do B5

- **D61 — o candidato do pacote é refeito na véspera do B5.** A P4 mandava refazê-lo depois da
  revisão do roteiro, com a ponta revisada, e passou a exigir que nada rode entre o
  `recovery-pack` e o desmonte, porque o recuo da fase 1 devolve os bancos ao corte. Refeito na
  véspera, como o primeiro passo depois da autorização do B5, o corte fica colado no desmonte, e o
  ambiente fica livre até lá. A cópia da P5 é a do candidato refeito. *Descartada:* refazê-lo ao
  fechar a revisão — ficaria pronto, mas qualquer sincronização, DAG ou geração até o B5 o
  invalidaria. *Custo aceito:* o B5 começa com um passo a mais, de alguns minutos.

### D59 e D60 — decididas em 25/09/2026, na resposta à revisão do roteiro do B5

Duas decisões tomadas para responder a achados da primeira rodada de revisão do roteiro
(RVB5-02 e RVB5-04, no dossiê `REVISAO.md`, no histórico em `6065485`). Nenhuma troca ferramenta,
camada ou modelagem; nenhum ADR.

- **D59 — o `make medir` coleta o tamanho, como o B1 declarou.** O plano (§3) mandava o medidor
  rodar, ao fim, o `make size-report` e registrar o total por banco, e a Execução Local dizia que ele
  registrava tamanho; o código nunca fez, e o roteiro não produzia a dimensão que C2 pede. O medidor
  passa a rodar o `size-report` depois de o intervalo e a amostragem fecharem, e grava o total de
  cada banco e a soma no registro e na linha da Capacidade; relatório que falha fica como não
  medido. *Descartada:* o roteiro chamar o `size-report` à parte, com o plano e a Execução Local
  corrigidos para dizer que o medidor não mede tamanho — sem código antes do B5, mas com a
  transcrição manual. *Custo aceito:* código e testes novos no B1, revisados na rodada seguinte, e
  ~20 s depois de cada medição, que o `ANALYZE` do relatório custa.
- **D60 — o pacote aprovado vai para o `data/recovery` do clone.** O `recovery-promote` só renomeia
  o candidato para `aprovado` dentro do `RECOVERY_DIR` que o roteiro exporta, o do *checkout*
  antigo, que o §7.5 deixa arquivar ou apagar. Antes de liberá-lo, o aprovado é copiado para o
  `data/recovery` do clone — o caminho padrão da D46 no *checkout* de trabalho da D58 —, o
  `RECOVERY_DIR` deixa de ser exportado e o `make recovery-verify` do clone o confere. *Descartada:*
  um diretório fora dos *checkouts*, que sobrevive a apagar ou reclonar, mas pede o `export` em toda
  sessão, porque o `Makefile` não lê o `RECOVERY_DIR` do `.env`. *Custo aceito:* o pacote mora num
  diretório que um `git clean -x` ou um `rm` do *checkout* levaria — a cópia da P5, fora dos
  *checkouts*, é a segunda.

### D57 e D58 — decididas em 24/09/2026, para o roteiro do B5

Duas decisões de operação tomadas ao escrever o roteiro do B5 (revisão 8 do §7 do plano). Como as
anteriores desta etapa, nenhuma troca ferramenta, camada ou modelagem; nenhum ADR.

- **D57 — a rede do projeto sai à mão no desmonte do B5.** O plano exige inventário vazio, inclusive
  de redes, e pela D55 nenhum alvo remove a rede do projeto. Depois do `make reset`, `docker network
  rm mvp_ed1_default`, registrado no diário: o inventário fica vazio de verdade, e o `make up` do
  clone exercita a criação da rede do zero — o caminho da D55 que ainda não rodou de verdade no
  projeto. *Descartada:* aceitar a rede como a única sobra declarada, com o clone reaproveitando-a.
  *Custo aceito:* um comando fora do `Makefile`, no desmonte, que já é inventariado à mão.
- **D58 — o clone do B5 vira o *checkout* de trabalho.** O clone sobe os bancos com as senhas novas
  do `make env`, e o `.env` do *checkout* antigo deixa de abrir os volumes, que são os mesmos porque
  o nome do projeto é o mesmo. O B5 prova que o clone sobe do zero, e ele segue como o *checkout* do
  projeto: o B6 e a Etapa 13 continuam nele. O antigo fica parado, com o pacote, até o
  `recovery-promote`, e o Owner o arquiva ou apaga quando quiser. *Descartada:* voltar ao antigo,
  copiando para ele o `.env` e os artefatos do clone — um passo manual que o B5 não mede. *Custo
  aceito:* o Owner troca de diretório.

### D55 e D56 — decididas em 24/09/2026

Duas decisões de operação que o exercício real da D53 e da D54 levantou, com a memória liberada.
Como D45–D54, nenhuma troca ferramenta, camada ou modelagem; nenhum ADR.

- **D55 — a rede do projeto é externa, e nenhum `down` a remove.** As três composições compartilham o
  projeto e a rede padrão dele. Gerida pelo Compose, ela ia embora no `make down` dos bancos, e os
  contêineres pausados do Airflow e do *streaming* ficavam presos ao ID antigo: em 21/09 um down/up
  a recriou, e de lá até 24/09 nenhuma retomada do Airflow funcionaria — `airflow-resume` recusou
  ("network … not found"), e `airflow-up` não recriou o `airflow_db`. Agora as três declaram
  `<projeto>_default` como externa — o nome que o Compose já dava, para não recriar o que está de pé
  —, e `up`, `airflow-up` e `stream-up` a garantem antes de subir. Medido: numa composição
  descartável, a rede gerida reproduz a falha e a externa não; no projeto, `make down` manteve a rede
  com o mesmo ID, e `make airflow-resume` religou depois do down/up. *Descartadas:* `make down`
  recusar com contêiner parado de outra composição — atrito, e não conserta o que já quebrou —; as
  retomadas recriarem pelo Compose o que perdeu a rede — a retomada passaria a conhecer o Compose, e
  o preflight também —; e só documentar, com o defeito voltando a cada `make down`. *Custo aceito:*
  um recurso que o `Makefile` cria e nenhum alvo remove — nem `make reset`, porque removê-la é o que
  prendia os pausados —, e o nome `_default`, que parece do Compose e não é mais.
- **D56 — a pausa do Airbyte continua terminando em SIGKILL, documentada.** O `docker stop` dá 10 s,
  e o desligamento ordenado do nó do `kind` leva ~91 s (90,7 s medidos, código 130): a pausa termina
  em 137, e a do Kafka Connect também. Para o Postgres interno do Airbyte, cada pausa é uma queda com
  recuperação na volta; ela não falhou em nenhuma retomada medida, e o contador de *jobs* continuou em
  43. *Descartada:* a parada limpa (`docker stop -t 120`) na pausa, ~80 s a mais em toda troca que
  pausa o Airbyte. *Risco aceito:* uma recuperação que falhe, que ninguém mediu falhando. A nota
  operacional está na [Execução Local §5](execucao_local.md#5-executando-por-partes).

### D53 e D54 — decididas e implementadas em 24/09/2026

Duas decisões de operação sobre subir e retomar ambiente pesado, levantadas em 23/09/2026 na
verificação do RVE3-02 (a terceira rodada de revisão da entrega). Como D45–D52, nenhuma troca
ferramenta, camada ou modelagem; nenhum ADR.

- **D53 — o que já está de pé não é cobrado de novo.** O *preflight* não cobra o custo do alvo que
  já está inteiro de pé, nos três `*-up`; de pé pela metade, cobra inteiro. A troca não muda: a outra
  família é pausada do mesmo jeito, com a mesma guarda de trabalho em andamento. `make airbyte-up`
  passa a decidir por três estados lidos: ausente instala, pausado retoma e de pé confere a API —
  sem o `abctl local install`, que sobre o cluster de pé abortou no `PG_VERSION` em 05/09 e em
  23/09/2026. Consulta ao Docker que falha, ou estado que nenhum caminho trata, recusa antes da
  troca. Medido em 24/09/2026, com o Airbyte de pé e 2,3 GB livres: o *preflight* anterior recusava
  ("sobraria -2,5 GB"), o novo diz "nada a cobrar", e `make airbyte-up` terminou em 0,32 s, com a
  API respondendo na primeira consulta. *Descartadas:* cobrar só o acréscimo até o pico, lendo o
  consumo do cluster com `docker stats` — mais uma leitura que pode falhar, e proteção só para quem
  roda `airbyte-up` antes de sincronizar —; e manter, com a recusa pela conta e, atravessada por
  `FORCE=1`, o `abctl` no `PG_VERSION`. *Custo aceito:* `airbyte-up` deixa de reaplicar o chart
  ([Execução Local §6](execucao_local.md#a-sincronização-do-airbyte-fica-running-para-sempre-e-não-move-linha)),
  e o acréscimo de uma sincronização sobre o Airbyte ocioso, até o pico de 4,95 GiB, continua sem
  conferência — como já era com `sync-airbyte`, que nunca passou pelo *preflight*.
- **D54 — retomar passa pela mesma troca que subir.** `airbyte-resume`, `stream-resume` e
  `airflow-resume` chamam o *preflight* antes de religar e, antes dele, conferem que há o que
  religar — sem isso, a troca pausaria o outro ambiente à toa. `FORCE=1` continua sendo o caminho
  sem conferência, agora o único, e é autorização do Owner. A regra — todo alvo que liga ambiente
  pesado chama o *preflight* da própria família antes — é teste sobre o texto do `Makefile`
  (`tests/test_makefile.py`). Medido em 24/09/2026: `make preflight ALVO=airflow`, com 2,6 GB
  livres, recusa ("sobraria 1,2 GB"); o `airflow-resume` anterior religava os quatro contêineres
  sem essa pergunta. *Descartadas:* só apontar a mensagem para os `*-up`, a recomendação registrada
  em 23/09 — quem digitasse `*-resume` por hábito, como a Execução Local e o `CLAUDE.md` ensinavam,
  continuaria podendo subir as duas famílias juntas —; e manter. *Custo aceito:* retomar com a
  memória curta pede `FORCE=1`; devolver a máquina ao estado de antes de uma pausa, como na
  verificação de 23/09, passa pela autorização do Owner.

### D45 a D52 — decididas entre 18 e 19/09/2026, na abertura da Etapa 12

Oito decisões de execução do fechamento da fase local, tomadas sobre o plano transitório da
Etapa 12 (`PLANO_etapa_12.md`, §10, com as alternativas descartadas, no histórico em `46d8243`) —
as quatro últimas nas três
rodadas de revisão do plano. Nenhuma troca ferramenta,
camada ou modelagem. Nenhuma teve ADR na abertura; a D48 ganhou o seu em 03/10/2026, porque altera
a política de segredos da Governança.

- **D45 — "ambiente limpo" é (c):** clone novo, `.env` novo, `make airbyte-down` e `make reset`
  nesta máquina; "máquina que nunca viu o projeto" fica registrada como contrapartida da fase
  seguinte (a VM do §4.1 da conversa de custos, depois da Etapa 13).
- **D46 — o pacote de recuperação vive em `data/recovery/`** (ignorado pelo Git), com
  `RECOVERY_DIR` sobrescrevível.
- **D47 — a versão da fase local é `v1.0.0`**, marcada no *commit* que fecha M5; a fase GCP será
  `v2.0.0`.
- **D48 — segredo achado no histórico:** senha de contêiner local se regenera e se registra, sem
  reescrever histórico; chave de nuvem ou token externo se revoga **e** se reescreve, só pela
  mão do Owner (hoje não existe nenhuma). Formalizada no
  [ADR-0048](adr/0048-tratar-segredo-achado-no-historico-pelo-tipo-da-credencial.md) em 03/10/2026,
  pela revisão final da etapa (RVF12-02).
- **D49 — o pacote de recuperação guarda as fontes e a memória do armazém** (`raw_legacy`,
  `governance`, `snapshots`): decidida sobre o achado RV12-01 da revisão do plano — a
  [Capacidade §3.3](capacidade_e_recuperacao.md#33-regras) dizia "warehouse fora" e foi escrita
  antes dos ADRs 0037, 0044 e 0045, que fizeram do armazém guardião de capturas, certificados e
  histórico SCD que nenhuma reconstrução reproduz. O resto do armazém continua sendo refeito e
  provado igual. A §3 é reescrita no fechamento da etapa como consequência dos ADRs, sem ADR novo.
  **Ampliada por D51** em 19/09/2026: a `quarantine` também é memória, e entra no mesmo *dump*.
- **D50 — a identidade da captura num Airbyte novo:** guarda na certificação (captura com
  `sync_id ≤ max(snapshot_id)` já certificado é recusada com motivo próprio) e regra operacional
  para instalação nova do Airbyte (avançar a sequência de *jobs* além do maior retido, conferido
  antes da primeira sincronização). Decidida sobre o achado RV12-2-02 da segunda rodada de
  revisão do plano: `snapshot_id` é o `job_id` do Airbyte, que recomeça em 1 numa instalação nova
  e colidiria com as capturas retidas pelo pacote. A identidade do ADR-0044 não muda; o ADR ganha a
  consequência. A alternativa de identidade composta (modelagem, ADR novo) foi descartada.
  **Completada em 19/09/2026 (terceira rodada, RV12-3-04):** a guarda passa a ser pré-condição de
  **disparar** o *job*, nos dois chamadores, porque recusar depois do *append* não desfaz a
  mistura; a guarda na regra pura de `decidir` fica como rede.
  **Ampliada em 20/09/2026 (quarta rodada, RV12-4-03):** a pré-condição vale em **todo** disparo da
  conexão legada pelos pontos de entrada do projeto — o `sync` da CLI sem `--certificar-legado` e o
  `reset` chegavam ao `POST /jobs` por fora da fase 1 —, e a guarda em `decidir` é recusa do
  certificado, sem proteção retroativa do bruto.
- **D51 — o pacote de recuperação guarda também a `quarantine`** (19/09/2026, sobre o achado
  RV12-3-01 da terceira rodada): `quarantine.rejected_legacy_records` tem 63.802 linhas de
  auditoria e uma reconstrução do zero reproduz 3.207 — a fatia da captura corrente sob o
  tratamento vigente —, perdendo **60.595** que o rebuild da captura corrente não recalcula (nem
  todas de tratamento extinto: 9.586 ainda estão sob a versão vigente — correção da quarta rodada,
  RV12-4-05, que não altera a decisão). `dbt_project.yml` e
  a [Governança §8](governanca_de_dados.md#8-retenção) já a declaravam `permanent`; a revisão 4 do
  plano a listava como reconstruível pelo dbt, e era premissa falsa. As alternativas — perda
  explicitamente decidida e evidência só em arquivo — foram descartadas.
- **D52 — as gerações do bruto num Airbyte novo** (19/09/2026, sobre o achado RV12-3-02 da
  terceira rodada): a restauração **re-baseia** para faixa negativa o `_airbyte_generation_id` das
  linhas retidas de `raw_legacy`, antes da primeira sincronização. Avançar a sequência de *jobs*
  (D50) não bastava: a certificação recusa como `inconsistent` a captura cuja geração contenha
  linha de outro `sync_id`, e um Airbyte novo recomeça a geração em 1 sobre as gerações 1–28
  retidas. Nenhum certificado guarda a geração e só `captura.py` a lê, então o re-base não muda a
  identidade nem o contrato do ADR-0044 — que ganha a consequência. As alternativas — avançar
  também o contador de gerações (segundo interno não documentado), marca-d'água na certificação
  (mudaria o contrato) e limite declarado (C4 com lacuna) — foram descartadas.
  **Completada em 20/09/2026 (quarta rodada, RV12-4-01):** o re-base precisa **preservar a
  equivalência de geração por tabela** — negar as positivas e manter as negativas funde as faixas
  no segundo ciclo e faz a certificação recusar uma captura correta, sem que o hash mude. A
  implementação que não alcançar essas propriedades para e devolve a consequência ao Owner.


### D44 — decidida em 16/09/2026, implementada e medida em 17/09/2026

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

**Executado em 17/09/2026**, com duas decisões tomadas no caminho: a carga do mesmo lote **encerra**
o diário em vez de o herdar (`mutacoes_encerradas`, com data e motivo — depois de truncar e
recarregar, o diário antigo descrevia um estado que não existia), e o bloco incluiu uma remoção real
além da troca de representação, para que o diário novo também prove `removida`. A testemunha foi
`campaigns/4` e não um cliente: a classificação resolve o vínculo pai por igualdade textual
(`classification.sql`, CTE `edges`), e `'0x8'` num cliente órfãria os filhos dele — comportamento
real da limpeza, fora do escopo deste bloco, registrado em §5. Medido: origem recarregada (lote
`3f9e5088…`, diário de 16 entradas encerrado) → captura **38** certificada 40/40 (2 min 11 s) →
`make dbt-build` `PASS=891` (12 min 57 s) → `make test` **253 passed, 3 skipped**, com os seis testes
de detecção rodando sobre a captura corrente (12.747 vereditos); `alterar campaigns.id 4 → 0x4` e
`remover customers --quantidade 3` pela CLI, ambos com `presenca_apos_commit` → captura **39**
certificada (12.744 linhas, 1 min 19 s) → `PASS=891` (12 min 39 s); no intervalo 38→39,
`campaigns/4` é `mantida` (1→1) com `'0x4'` no bruto, `accepted` na limpeza e `campaign_id = 4` em
`trusted`; `customers/1,2,3` são `removida` com `removed_in = 39`, e `customers/99001` — inserido pelo
diário antigo — aparece na memória com `last_seen = 36`, `removed_in = 38`, que é o que a recarga fez;
`make test` **248 passed, 8 skipped** (os seis de detecção pulam na captura mutada, por desenho). A
leitura antiga saiu de `efeito_liquido`, que agora recusa entrada sem o campo.

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
**M3** (primeiro fluxo completo), **M4** (*streaming* em operação) e **M5** (fase local concluída,
em 04/10/2026) estão fechados. As Etapas 3 a 10 foram entregues — o modelo dimensional está
completo, as 16 perguntas de negócio têm view e a segunda origem atravessa o fluxo inteiro —, a
Etapa 11, que consolidou governança e qualidade, foi aceita em 18/09/2026, e a Etapa 12, que provou
o repositório do zero, em 04/10/2026 (§1.1).

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

**Duas fatos ficaram lentas depois do empilhamento (07/09/2026) — explicado e corrigido em 17/09/2026.**
`fact_payment_transaction` leva **595 s** e `fact_sales_order_item`, **186 s**; as outras oito ficam
abaixo de 3,3 s. As tabelas envolvidas são pequenas — 7.427 transações, 3.830 pagamentos, 3.661
pedidos e 1.574 versões de cliente —, e nada nesse tamanho justifica dez minutos.

Duas hipóteses, **nenhuma verificada**: a junção temporal com `dim_customer` deixou de ter
`source_system = 'retail'` como constante e passou a ser igualdade entre colunas, o que tira do
planejador a seletividade que ele tinha; ou a máquina estava sob pressão de memória durante as
medições (9,2 GB de 11,7 GB em uso, com o Airbyte segurando ~3,6 GB em JVMs).

Não há medição anterior ao empilhamento para comparar, então **não afirmo que seja regressão**. O
que está registrado é o número, não a causa.

**Explicado e corrigido em 17/09/2026.** A mesma consulta leva 0,3 s sozinha e 680 s dentro do
*build*; nos últimos 7 min ela era o único nó ativo, e o pior plano de junção forçado à mão dá 11 s
— não era a consulta, o volume, a concorrência nem a memória. O `auto_explain` gravou o plano real:
sem estatística nas tabelas recém-criadas pelo *build*, o planejador assume `source_system`
seletivo (a coluna tem **dois** valores desde o empilhamento, ADR-0021 — daí "ficaram lentas depois
do empilhamento") e junta `payment_transactions` a `orders` **só por ela**: 24,9 milhões de linhas
intermediárias, hash em 2 048 lotes, 17 GB de arquivo temporário (`temp written=2199505` blocos)
para 7 419 linhas de resultado. `fact_sales_order_item` é o mesmo mecanismo. Nenhuma das duas
hipóteses acima estava certa: a junção temporal aparece no plano com 3 657 linhas, e a máquina tinha
4,5 GB livres. A correção é declarativa — `post-hook` `analyze {{ this }}` em toda materialização de
tabela (`dbt_project.yml`, macro `analisar_apos_materializar`), vazio para *views* e para o BigQuery,
que não tem `ANALYZE` nem o problema.

O *build* com o `ANALYZE` expôs um segundo mecanismo, em `fact_shipment_item`: **326 s** com a
estatística presente. O CTE `remessas` é lido três vezes, e com mais de uma referência o PostgreSQL o
materializa — a estatística de `shipments` deixa de existir para o planejador (`CTE Scan`,
`rows=2` onde havia 3.767), e o resultado é o mesmo desenho: pedidos juntados a remessas só por
`source_system`, 12,6 milhões de linhas, `external sort` de 3,7 GB. Nos *builds* anteriores esse
modelo levava 6–16 s: o plano oscilava com a amostra da estatística, e o defeito só era visível
quando caía do lado errado. Correção no modelo: `with remessas as not materialized (...)`, guardada
por `target.type` como o `materialized` da D42. Seis outros modelos têm CTE com mais de uma referência
(`dim_product`, `cart_lifecycle_events`, `customers`, `inventory_balances`, `orders`, `product_skus`)
e todos rodam abaixo de 3 s; ficam como estão, e este parágrafo é o lugar de olhar se algum deles
aparecer lento.

**Medido em 17/09/2026, captura 39, os dois consertos juntos:** `fact_payment_transaction` 680 s →
**2,0 s**, `fact_sales_order_item` 212 s → **1,2 s**, `fact_shipment_item` 326 s → **1,2 s**; `make
dbt-build` completo **12 min 39 s → 1 min 25 s**, `PASS=892`. O mais lento agora é
`stg_legacy__cart_items`, 25 s. Este item sai de "medido e não explicado". O `auto_explain` que
revelou os dois planos ficou **declarado** no `docker/docker-compose.yml` do armazém (limiar de
30 s): a próxima instrução lenta deixa o plano executado no `docker logs`, sem rodada de
instrumentação.

**Identidade do vínculo pai é textual na limpeza (17/09/2026).** `classification.sql` resolve a
referência ao pai por `p.cleaned_payload->>chave = valor_do_filho`, enquanto a comparação entre
capturas canoniza a chave por tipo (`chave_canonica`, ADR-0045). Um cliente cuja PK passasse de `'8'`
a `'0x8'` seria `mantida` no intervalo e, ao mesmo tempo, deixaria todos os filhos `FK_ORPHAN`. Não
acontece no bruto real (PKs inteiras e UUIDs limpos) e o bloco da D44 escolheu uma testemunha sem
filhos por isso. Fica registrado como divergência entre duas noções de identidade, não como defeito
medido; se um dia importar, a decisão é do Owner e pede ADR.

**Quatro tabelas da origem fora da ingestão, sem motivo escrito (04/10/2026) — explicado em 19/10/2026.** `customer_contacts`,
`customer_preferences`, `price_lists` e `product_prices` não estão em
[`airbyte/streams.yml`](../airbyte/streams.yml): são 36 de 40 tabelas, e o
[Dicionário §3](dicionario_de_dados.md#3-linhagem) registra o número, mas nenhum documento diz por
quê. Não verificado se é escolha (nenhuma pergunta de negócio as lê, como o ADR-0035 decidiu para as
dimensões) ou omissão. No mesmo arquivo, o comentário de `support_agents` diz "42 linhas"; a origem
tem 6, medido no mesmo dia. Achado E da validação do material de estudo.

**Explicado em 19/10/2026: é escolha.** A regra "cada tabela entra na etapa que a consome — ingerir
tabela que nenhum modelo lê é volume sem consumidor" está no `streams.yml` desde a abertura da
Etapa 5 (55fdf5a), e `test_toda_tabela_do_stream_tem_fonte_declarada_no_dbt` a guarda. Nenhuma das
16 perguntas lê as quatro, então nenhuma etapa as ingeriu, e o histórico confirma que nunca
estiveram na origem `retail`. O motivo agora está escrito na
[§7 das Perguntas de Negócio](glossario_de_negocio/perguntas_de_negocio.md#7-o-que-estas-perguntas-deixam-de-fora),
e o `streams.yml` aponta para ela. O comentário de `support_agents` passou a dizer as duas
contagens: 42 na proporção de referência, 6 no volume gerado.

---

## 6. Do lado do assistente

**Etapa 12 (18/09–04/10/2026):** o ponto único de recuperação — pacote, verificação, re-base das
gerações, restauração em nove passos e promoção —, a medição por `make medir`, a troca automática
entre ambientes pesados com a guarda de trabalho em andamento, a varredura do histórico e a
coerência dos documentos; o ciclo do zero executado e medido, os documentos atualizados com o que
ele mediu, e as quatro rodadas da revisão final respondidas. O *commit* de fechamento leva a *tag*
`v1.0.0`; o *push* dos dois é seu. Nada mais está do meu lado na fase local.

**Etapa 11 (17–18/09/2026):** `make check` como comando único com *fail fast*; classificação de
4.161 de 4.161 colunas derivada dos modelos por linhagem; retenção declarada por objeto; cinco
papéis de acesso sem login com concessão declarada por camada, assumida e testada; linhagem por
coluna do consumo até as fontes, gerada e conferida; reconciliação automática nas oito fronteiras.
O fechamento das fronteiras achou três estados da origem regenerada discordando entre si (seis
saldos e 2.200 movimentos velhos em `raw` e na fato incremental) — corrigidos pelo procedimento da
Execução Local §3.2 no mesmo dia. Nada está do meu lado: o item acima é o aceite, que é seu.

A D31 está encerrada. Na Etapa 10, tudo o que a terceira revisão pediu está **implementado e
medido** (15/09/2026): certificação de captura por conteúdo em duas fases (ADR-0044), detecção de
exclusão física no bruto retido (ADR-0045), schema legado no Alembic, oráculo por ocorrência para
o lote inteiro, contrato de `event_sequence`, e os documentos com o estado medido. As medições
estão no dossiê de revisão entregue ao outro agente e nos donos documentais. A revisão de
desenvolvimento voltou em 15/09/2026 com seis bloqueantes e seis ajustes (RV10-01…12); onze foram
corrigidos e medidos no mesmo dia, e o décimo segundo (prova local da escrita BigQuery) foi adiado
por decisão sua para a Etapa 13. Seguiram-se mais cinco rodadas até 17/09/2026 — a última sem
achado —, e o dossiê `REVISAO.md` foi fechado e apagado nesse dia; a situação de cada achado está
no histórico do *git* dele. **A Etapa 10 está aceita desde 17/09/2026, sob a condição da D44**; o
que falta dela é executar o bloco de sincronizações, não decidir.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
