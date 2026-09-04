# Termo de Abertura do Projeto

| Campo | Informação |
|---|---|
| **Projeto** | MVP — Engenharia e Governança de Dados de Referência (`mvp_eng_dados_1`) |
| **Repositório** | `github.com/alencardoug/mvp_eng_dados_1` (pasta local: `mvp_ed1`) |
| **Versão** | 1.2 — **aprovada** |
| **Data** | 04/09/2026 |
| **Owner principal** | Douglas Alencar |
| **Natureza** | MVP técnico de engenharia de dados, evolutivo, público |
| **Documentação** | Mapa completo dos artefatos no [README](README.md) |

## 1. Requisição e justificativa

Solicita-se a abertura formal do projeto, destinado a construir de ponta a ponta um fluxo que parte
de um banco transacional estruturado e alcança um datamart analítico com governança, views de
consumo e documentação. O projeto é conduzido primeiro em infraestrutura local e, quando maduro,
replicado no Google Cloud Platform, preservando as mesmas boas práticas.

Projetos de engenharia de dados costumam ser apresentados como diagramas ou trechos de pipeline,
sem um caminho completo, reproduzível e governado do transacional até o consumo. Este MVP
constitui uma **referência prática e auditável** desse caminho. A solução é tratada como produto de
engenharia: versionada, documentada, testada e evoluída de forma controlada.

## 2. Objetivo

Os dados são sintéticos e as duas origens são simuladas; **o padrão de execução não é simulado**. A
analogia é o simulador de voo: ele é conduzido com a disciplina do voo real justamente porque vai
virar voo — não com a tolerância de um experimento. Toda escolha é a que um ambiente corporativo
faria (**P10**), e o resultado é avaliado como produto de engenharia, não como exercício.

Construir e publicar um MVP capaz de:

1. manter um banco transacional aderente a boas práticas de modelagem relacional;
2. simular dados de origem de forma controlada, repetível e realista;
3. executar ingestão, transformação e orquestração versionadas e testáveis;
4. entregar um datamart dimensional com views de consumo e governança aplicada;
5. tratar uma origem legada defeituosa e um fluxo contínuo de eventos;
6. replicar a arquitetura no GCP de forma reproduzível, de baixo custo e segura.

## 3. Escopo da fase local

Banco transacional normalizado com migrações versionadas · geração determinística de dados
sintéticos · segunda origem legada, deliberadamente defeituosa, com limpeza e quarentena ·
ingestão, transformação e orquestração em camadas explícitas · datamart dimensional com views de
consumo · fluxo de streaming restrito a um único domínio · governança de dados desde a primeira
tabela · testes de qualidade e reconciliação entre camadas · documentação reproduzível.

Detalhamento técnico em [Arquitetura](docs/arquitetura.md) e
[Modelo de Dados](docs/modelo_de_dados.md); sequência em
[Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md).

## 4. Fora do escopo

BI e dashboards finais · data lake e formatos colunares distribuídos · fontes externas reais ou
origens além das duas previstas · otimização de performance em larga escala · multi-tenant ·
operação continuada na nuvem após a replicação.

**CI/CD** permanece fora do escopo, com **uma exceção declarada**: a aplicação automática das
*policy tags* no BigQuery a partir do YAML de classificação, na Etapa 13. A exceção existe porque
governança aplicada à mão não é governança verificável, e é limitada a esse fluxo — a autenticação
usa federação de identidade, sem credencial longeva no repositório.

## 5. Entregas principais

| ID | Entrega | ID | Entrega |
|---|---|---|---|
| **E1** | Repositório versionado e documentado | **E7** | Datamart dimensional com views de consumo |
| **E2** | Termo, arquitetura e registro de decisões | **E8** | Dicionário de dados, catálogo e linhagem |
| **E3** | Schema transacional com migrações | **E9** | Regras de classificação, acesso e retenção |
| **E4** | Gerador de dados sintéticos parametrizável | **E10** | Suíte de testes de qualidade de dados |
| **E5** | Pipeline de ingestão para as camadas brutas | **E11** | Instruções de execução reproduzível |
| **E6** | Transformações até a camada analítica | **E12** | Replicação no GCP |

## 6. Critérios de sucesso

| Dimensão | Critério |
|---|---|
| **Produto** | A partir do repositório é possível subir os bancos, gerar os dados, executar o pipeline completo, consultar as views de consumo e consultar catálogo e linhagem. |
| **Técnico** | Execução reproduzível de ponta a ponta, migrações aplicáveis do zero, testes passando, reconciliação de contagens entre camadas, ausência de segredos e documentação coerente com o código. |
| **Governança** | Todo campo sensível classificado, linhagem origem → consumo documentada, decisões relevantes registradas em ADR e nomenclatura padronizada. |

## 7. Premissas

O Owner é responsável por escopo, decisões e aprovação · todos os dados são sintéticos · a fase
local precede e condiciona a fase GCP · o ambiente local usa contêineres e custa próximo de zero ·
o volume local é reduzido de propósito, e o trabalho com alto volume pertence à fase GCP ·
o Claude Code atua como ferramenta de desenvolvimento assistido, sem poder de aprovação e com
revisão obrigatória do Owner · o repositório é público.

## 8. Restrições

Evitar custos recorrentes desnecessários · não introduzir serviço de nuvem antes da fase GCP ·
não adicionar ferramenta apenas para ampliar a *stack* · manter paridade conceitual entre local e
GCP · dimensionar o ambiente local pela **cobertura** — todas as tabelas, todos os casos de borda —
e não pelo volume · observar integralmente a
[Política de Governança de Dados](docs/governanca_de_dados.md), que define dados permitidos, dados
proibidos e tratamento de segredos.

Complexidade sem valor demonstrável continua vedada — com a ressalva de que **fidelidade à prática
de produção é valor demonstrável** (**P10**): o projeto existe para enfrentar os desafios comuns de
um ambiente real, e a alternativa mais simples não vence só por ser mais simples.

O projeto é governado pelos [Princípios](docs/principios.md) **P1**–**P10**; os riscos e seus
tratamentos estão no [Registro de Riscos](docs/riscos.md).

## 9. Papéis e responsabilidades

Todos os papéis são exercidos por **Douglas Alencar**: *Owner principal* (aprova escopo, decisões e
prioridades), *Líder de Governança* (aderência às regras do projeto), *DPO / Encarregado* (revisa
exposição e classificação de dados), *Data Custodian* (mantém dados, catálogo e linhagem corretos)
e *Responsável técnico* (arquitetura, implementação e testes).

## 10. Gestão de mudanças

**Operacional** — não altera objetivo, escopo ou arquitetura central: implementada e documentada
diretamente. **Relevante** — altera modelagem central, camadas, arquitetura ou tratamento de dados:
exige decisão explícita do Owner e ADR. **De escopo** — nuvem antecipada, novas fontes ou BI: passa
por avaliação de valor, custo, risco e aderência a este Termo.

## 11. Aprovação

**Situação: aprovado em 04/09/2026 por Douglas Alencar, Owner principal.** Decisão tomada:
*autorizar o início e a execução da fase local (pré-GCP) do projeto, conforme escopo, princípios,
premissas, restrições e critérios estabelecidos neste Termo.*

A aprovação fecha o marco **M0**. As pendências remanescentes do Owner seguem reunidas em
[Pendências](docs/pendencias.md).

| Versão | Data | Alteração |
|---|---|---|
| 1.0 | 01/09/2026 | Redação inicial |
| 1.1 | 01/09/2026 | Detalhamento redistribuído para artefatos específicos; inclusão do objetivo de aprendizado, da origem legada e do fluxo de streaming no escopo |
| 1.2 | 04/09/2026 | Orçamento de 4 GB substituído por critério de cobertura (alto volume passa à fase GCP); exceção de CI/CD para *policy tags*; princípio **P10** incorporado às restrições; objetivo de aprendizado retirado do Termo — o estudo do resultado é atividade posterior à entrega, não parte dela |
