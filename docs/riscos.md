# Registro de Riscos

> **O que vive aqui:** os riscos do projeto, o seu impacto e o tratamento adotado.
>
> **O que não vive aqui:** as decisões que alguns tratamentos exigem (ver
> [Registro de Decisões](adr/README.md)); a etapa em que cada tratamento é aplicado (ver
> [Plano de Desenvolvimento](plano_de_desenvolvimento.md)).

| Campo | Informação |
|---|---|
| Versão | 1.0 |
| Responsável | Owner principal |
| Última revisão | 01/09/2026 |

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
| **R10** | Documentação desatualizada | Médio | Documentação versionada junto ao código; atualização é critério de pronto |
| **R14** | Código, testes e documentação gerados por IA sem revisão efetiva | Alto | Revisão do Owner é obrigatória; geração orientada a configuração declarativa revisável; manifesto do legado como oráculo independente |

## Riscos de dados e governança

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R4** | Governança tratada como etapa final | Alto | Catálogo, linhagem e classificação desde a primeira tabela; atualizar o dicionário é critério de conclusão de etapa |
| **R5** | Dados sintéticos irrealistas | Médio | Distribuições revisadas, invariantes de negócio testadas, recalibração após medição |
| **R7** | Segredos versionados por engano | Muito alto | `.gitignore` + `.env.example` sem valores + revisão em toda entrega |

## Riscos técnicos e de ambiente

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R6** | Falta de reprodutibilidade | Alto | Contêineres, `seed` explícita, migrações versionadas, ponto único de recuperação |
| **R11** | Consumo de memória e disco do ambiente local com Airbyte, Airflow, Redpanda e Debezium simultâneos | Alto | Alvos de `Makefile` sobem apenas o subconjunto necessário; perfil `smoke` para desenvolvimento; medir antes de concluir cada etapa |
| **R12** | Estouro do orçamento de 4 GB | Médio/Alto | Medição automática, alerta em 3,7 GB, bloqueio em 4 GB, `staging` em views ([detalhes](capacidade_e_recuperacao.md)) |
| **R13** | Complexidade do streaming e curva de aprendizado do Apache Beam | Médio/Alto | Escopo de um único domínio; entra apenas na Etapa 7, com o fluxo *batch* já funcionando; *boilerplate* assistido e revisado |

## Riscos da fase GCP

| ID | Risco | Impacto | Tratamento |
|---|---|---|---|
| **R9** | Custos inesperados na nuvem | Médio | Faixas gratuitas, estimativa por serviço antes de provisionar, Terraform revisado com `plan` antes de `apply` |
