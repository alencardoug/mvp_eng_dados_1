# Registro de Riscos

> **O que vive aqui:** os riscos do projeto, o seu impacto e o tratamento adotado.
>
> **O que não vive aqui:** as decisões que alguns tratamentos exigem (ver
> [Registro de Decisões](adr/README.md)); a etapa em que cada tratamento é aplicado (ver
> [Plano de Desenvolvimento](plano_de_desenvolvimento.md)).

| Campo | Informação |
|---|---|
| Versão | 1.4 |
| Responsável | Owner principal |
| Última revisão | 25/09/2026 — revisão de fim da Etapa 12: nenhum risco novo; R6, R7, R10 e R11 com tratamento ampliado pelo que a etapa mediu |

Um risco só sai desta tabela quando deixa de existir — não quando deixa de incomodar. Riscos
novos entram a qualquer momento; a revisão obrigatória acontece ao final de cada etapa.

---

## Riscos de projeto

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R1** | Escopo crescer além de um MVP | Alto | Termo de Abertura + controle de mudanças; nada entra sem avaliação de valor |
| **R2** | *Overengineering* de orquestração | Médio/Alto | DAGs mínimas no Airflow; complexidade só quando o fluxo simples falhar |
| **R3** | Divergência entre fase local e GCP | Alto | Princípio **P4**, [mapa de paridade](arquitetura.md#5-mapa-de-paridade-local--gcp) e ADR obrigatório |
| **R8** | Dependências excessivas | Médio | Nenhum componente entra sem ADR declarando o problema resolvido |
| **R10** | Documentação desatualizada | Médio | Documentação versionada junto ao código; atualização é critério de pronto. Desde a Etapa 12, links, âncoras e citações de ADR são **conferidos a cada `make check`** (`docs-check`, 20/09/2026), e a [Execução Local](execucao_local.md) foi seguida linha a linha num ciclo do zero, com os desvios corrigidos no documento (25/09/2026) |
| **R14** | Código, testes e documentação gerados por IA sem revisão efetiva | Alto | Revisão do Owner é obrigatória; geração orientada a configuração declarativa revisável; manifesto do legado como oráculo independente |

## Riscos de dados e governança

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R4** | Governança tratada como etapa final | Alto | Catálogo, linhagem e classificação desde a primeira tabela; atualizar o dicionário é critério de conclusão de etapa. Desde a Etapa 11 (18/09/2026) as três são **cobradas a cada `make check`**: classificação 100 % derivada dos modelos, linhagem por coluna gerada e conferida contra o SQL, acesso por papel assumido e executado |
| **R5** | Dados sintéticos irrealistas | Médio | Distribuições revisadas, invariantes de negócio testadas, recalibração após medição |
| **R7** | Segredos versionados por engano | Muito alto | `.gitignore` + `.env.example` sem valores + revisão em toda entrega — a primeira etapa do `make check` desde 17/09/2026, e os papéis de acesso são grupos sem login, sem senha nova no `.env`. Desde a Etapa 12, também o **histórico inteiro**, na definição de pronto (`make secrets-history`, 20/09/2026), com cada achado já tratado no [registro](segredos_tratados.yml) pela política da D48 ([Governança §9](governanca_de_dados.md#9-tratamento-de-segredos)) |

## Riscos técnicos e de ambiente

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R6** | Falta de reprodutibilidade | Alto | Contêineres, `seed` explícita, migrações versionadas, ponto único de recuperação. **Provado do zero na Etapa 12** (25/09/2026): um clone novo, com `.env` novo, percorreu a [Execução Local](execucao_local.md) sobre bancos, Airbyte e Airflow instalados do zero, e o ponto único de recuperação foi restaurado e conferido ([Capacidade §3](capacidade_e_recuperacao.md#3-ponto-único-de-recuperação)). Quatro defeitos só apareceram ali, porque no ambiente de trabalho tudo já existia; a prova numa máquina que nunca viu o projeto é contrapartida da fase GCP (D45) |
| **R11** | Consumo de memória do ambiente local com Airbyte, Airflow, Redpanda e Kafka Connect simultâneos | Alto | Alvos de `Makefile` sobem apenas o subconjunto necessário e pausam o conflitante; *batch* e *streaming* não sobem juntos — nem na Etapa 12, que valida por partes ([ADR-0046](adr/0046-validar-a-fase-local-por-partes.md)); fator de escala `dev` no gerador; medir antes de concluir cada etapa. No ciclo do zero da Etapa 12 (25/09/2026), o pico foi a DAG: 6,5 GB nos contêineres e 1,1 GB livres — o par que o preflight permite cabe, com pouca folga ([Capacidade §2.12](capacidade_e_recuperacao.md#212-o-ciclo-do-zero-medido--b5-25092026)) |
| **R13** | Complexidade do streaming e curva de aprendizado do Apache Beam | Médio/Alto | Escopo de um único domínio; entra apenas na Etapa 7, com o fluxo *batch* já funcionando; *boilerplate* assistido e revisado |

## Riscos da fase GCP

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R9** | Custos inesperados na nuvem | Médio | Faixas gratuitas, estimativa por serviço antes de provisionar, Terraform revisado com `plan` antes de `apply`; Composer e Airbyte existem apenas na janela da Etapa 13, destruídos pelo mesmo Terraform ([ADR-0024](adr/0024-airbyte-e-airflow-no-gcp.md)) |

---

## Riscos encerrados

Um risco só sai da tabela quando **deixa de existir**. Quando isso acontece, fica registrado aqui —
o identificador não é reaproveitado.

| ID | Risco | Encerrado em | Por quê |
|---|---|---|---|
| **R12** | Estouro do orçamento de 4 GB | 04/09/2026 | O orçamento foi aposentado pelo [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md): o ambiente local passou a ser dimensionado por cobertura, e não há mais limite de bytes a estourar |
