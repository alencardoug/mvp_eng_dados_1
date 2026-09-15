# ADR-0046 — Validar a fase local por partes, sem exigir *batch* e *streaming* simultâneos

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 15/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D36 — levantada em 07/09/2026, pela medição de capacidade |
| Substitui / é substituída por | — ; complementa o [ADR-0041](0041-teto-de-memoria-nos-servicos-do-airbyte.md), que tratou a parte estrutural da mesma pendência |

## Contexto

O plano da Etapa 12 exigia, entre os critérios de conclusão, "execução completa com *batch* e
*streaming* simultâneos, com tamanho e tempo medidos e registrados", e a [Execução Local
§5](../execucao_local.md#5-executando-por-partes) reservava a essa etapa o único cenário em que
tudo sobe ao mesmo tempo. O dimensionamento que sustentava a exigência —
[Capacidade §2.4](../capacidade_e_recuperacao.md#24-medido-na-etapa-7--o-caminho-quente), ~8 GB
com o caminho quente de pé — media **só o ambiente**. Em 07/09/2026 a máquina travou (OOM *killer*
151 vezes em uma hora, carga 32 sobre 4 CPUs, reinício forçado) porque as ferramentas de trabalho —
VS Code, sessões de agente e navegador, ~4 GB — correm sobre a mesma RAM de 11,5 GB. São 12 GB
pedidos numa máquina de 11,5: déficit, não margem
([Capacidade §2.8](../capacidade_e_recuperacao.md#28-o-número-de-dimensionamento-não-incluía-o-ambiente-de-trabalho--07092026)).

O que já foi tratado desde então não fecha o déficit: o [ADR-0041](0041-teto-de-memoria-nos-servicos-do-airbyte.md)
pôs teto de memória nos serviços permanentes do Airbyte (o ocioso caiu 7%; o pico durante a
sincronização, dominado pelos *pods* de *job*, não caiu), e a troca automática entre ambientes
pesados (`make airbyte-up`, `airflow-up`, `stream-up` pausando o conflitante, **R11**) resolve o
dia a dia — mas por definição não resolve uma validação que exige os dois de pé.

A pergunta que restava era de **escopo**, não técnica: o que a fase local demonstra sobre
simultaneidade, e o que fica para a fase GCP.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| Rodar a Etapa 12 por terminal puro, com o ambiente de trabalho fechado | Libera os ~4 GB e o número da §2.4 cabe com folga; nenhum critério muda | A validação passa a ser conduzida por `make` e lida por log, sem quem a acompanhe; e "cabe com folga" é sobre a média — o pico da sincronização com o *streaming* de pé nunca foi medido, e o que travou a estação foi o pico |
| Fatiar a validação em blocos que caibam | Preserva o ambiente de trabalho; cada bloco é medido no cenário em que já roda hoje | Exige definir o que uma execução única comprova que a soma dos blocos não comprova — e essa definição é justamente a contenção de recursos sob concorrência, que só a execução única mede |
| **Tirar do plano a exigência de simultaneidade** (escolhida) | Diz a verdade sobre a máquina: a fase local dimensiona por cobertura ([ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md)), não por carga, e a concorrência entre *batch* e *streaming* é uma propriedade do ambiente de execução, que na fase GCP é outro; os critérios que restam continuam todos mensuráveis por partes | A fase local **não demonstra** o comportamento sob concorrência — nem contenção de memória, nem interferência entre o Airbyte e o Beam no mesmo armazém —, e a primeira medição disso acontece na nuvem, onde errar custa dinheiro |

## Decisão

**A Etapa 12 valida a fase local por partes: cada cenário da [Execução Local §5](../execucao_local.md#5-executando-por-partes)
é executado e medido no subconjunto de ambiente em que já roda, e a exigência de *batch* e
*streaming* simultâneos sai dos critérios de conclusão. A demonstração sob concorrência é
contrapartida registrada da fase GCP.**

1. O critério "execução completa com *batch* e *streaming* simultâneos" é substituído por
   "execução completa de cada cenário no seu subconjunto de ambiente, com tamanho, tempo e pico de
   memória medidos e registrados" — a troca entre subconjuntos é a do **R11**, já automática.
2. A reconciliação entre os dois caminhos (`caminhos_de_ingestao_reconciliam`,
   [ADR-0031](0031-aterrissagem-do-caminho-quente-em-raw.md)) continua exigida — ela compara o que
   cada caminho deixou em `raw`, e não depende de os dois terem corrido ao mesmo tempo.
3. `docker/preflight.sh` deixa de ter o cenário "tudo de pé" como exceção prevista: **R11** passa a
   valer também na Etapa 12, e `FORCE=1` continua sendo autorização do Owner, não atalho.
4. A fase GCP recebe o critério que saiu: no Cloud Composer e no Dataflow, *batch* e *streaming*
   correm ao mesmo tempo por construção, e a Etapa 13 mede o que a fase local não mediu.

## Consequências

- **Positivas:** o critério da Etapa 12 volta a ser cumprível na máquina que existe, sem depender
  de fechar o ambiente de trabalho nem de uma medição de pico que nunca foi feita; a validação por
  partes é a mesma que já roda etapa a etapa, então nada novo precisa ser construído; e o plano
  deixa de prometer o que o [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md) já tinha
  tirado da fase local — carga e concorrência.
- **Negativas:** a fase local termina **sem** demonstrar contenção de recursos sob concorrência
  entre o Airbyte e o Beam, e o primeiro número disso é da nuvem; um defeito que só aparece com os
  dois de pé (uma tabela de `raw` disputada, um *lock* longo do `delete+insert` durante a chegada
  de eventos) chega à Etapa 13 sem ter sido visto. É custo aceito: medir na nuvem é mais barato do
  que travar a estação de novo.
- **Paridade com o GCP:** a simultaneidade é o estado normal da fase GCP — Composer agenda o
  *batch* enquanto o Dataflow consome o Pub/Sub —, e o critério que sai daqui entra lá: a Etapa 13
  registra tamanho, tempo e custo da execução com os dois caminhos de pé, e a reconciliação entre
  eles é a mesma `caminhos_de_ingestao_reconciliam` sobre o *dataset* `raw`.
- **Documentos a atualizar:** [Plano](../plano_de_desenvolvimento.md) — critérios das Etapas 12 e
  13; [Execução Local](../execucao_local.md) §5 — a linha "tudo simultaneamente" sai;
  [Capacidade](../capacidade_e_recuperacao.md) §2.8 — a consequência "em aberto" fecha;
  [Riscos](../riscos.md) — **R11** sem a exceção da Etapa 12; [Pendências](../pendencias.md) e
  [`docs/adr/README.md`](README.md) — D36 sai da tabela de pendentes.
