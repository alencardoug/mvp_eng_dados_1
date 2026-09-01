# ADR-0002 — Adotar um marketplace de varejo *omnichannel* como domínio

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D01 |

## Contexto

O [Termo de Abertura](../../Abertura_de_projeto.md) define **como** construir o fluxo, mas não
**o quê** modelar. Sem domínio não existe modelo relacional, e sem modelo relacional nenhuma etapa
de construção pode começar.

Critérios exigidos do domínio:

- gerar naturalmente fatos e dimensões, com processos distintos e comparáveis;
- ter regras de negócio não triviais — estados, cancelamentos, correções retroativas;
- permitir campos sensíveis **sintéticos** que exercitem a classificação de dados;
- não envolver dado real de terceiros nem exigir conhecimento regulatório especializado.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Varejo *omnichannel*** | Nove domínios de negócio interligados; eventos de alta cardinalidade; estados e reconciliações financeiras ricas; vocabulário amplamente compreendido | Escopo grande — exige controle explícito de volume |
| Saúde / clínica | Rico em regras e em dados sensíveis | **Descartado**: domínio de paciente é sensível por natureza, exige cuidado regulatório desproporcional ao MVP e conflita com a política de dados |
| Logística isolada | Eventos naturais e séries temporais | Poucos processos financeiros; modelo dimensional pobre |
| Financeiro isolado | Reconciliação exigente | Menor variedade de dimensões; menos exercício de qualidade |

## Decisão

O domínio é um **marketplace de varejo *omnichannel***, modelado em **40 tabelas transacionais
distribuídas em 9 domínios** — clientes, catálogo e preços, fornecedores e compras, vendas,
pagamentos, estoque, logística, marketing e atendimento — descritas no
[Modelo de Dados](../modelo_de_dados.md).

Os dados **não são de saúde nem de pacientes**. Campos que representam dado pessoal são sempre
sintéticos e mesmo assim classificados como sensíveis, para exercitar o controle real.

## Consequências

- **Positivas:** os nove domínios permitem cortes verticais independentes, cada um entregando
  fluxo completo; há material natural para SCD, reconciliação financeira, eventos de alta
  cardinalidade e um livro de eventos apto a streaming.
- **Negativas:** 40 tabelas é volume grande para construção manual — daí a geração orientada a
  configuração ([ADR-0005](0005-geracao-com-faker-orientada-a-configuracao.md)) e o controle
  explícito de armazenamento ([Capacidade](../capacidade_e_recuperacao.md)).
- **Paridade com o GCP:** o domínio é neutro quanto à infraestrutura; nenhuma tabela depende de
  recurso específico do PostgreSQL sem equivalente no BigQuery.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md),
  [Geração de Dados](../geracao_de_dados.md), [Glossário de Negócio](../glossario_de_negocio/).
