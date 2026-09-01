# ADR-0005 — Gerar dados com Faker por meio de um motor orientado a configuração

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D05 |

## Contexto

São 40 tabelas na origem principal e mais 40 na origem legada, com relações, distribuições e
invariantes de negócio a respeitar. Escrever um gerador por tabela produziria dezenas de milhares
de linhas de Python quase idênticas — caras de revisar e piores ainda de alterar quando uma regra
mudar.

Há um agravante específico deste projeto: boa parte do código é escrita com apoio de IA. Volume de
código gerado que ninguém consegue revisar é o risco **R14**, e a forma de tratá-lo é reduzir a
superfície do que precisa ser revisado.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Motor genérico + configuração declarativa** | A modelagem vira dado, não código; revisar um arquivo declarativo é viável; mudar regra não exige mexer no motor | Exige projetar bem o motor e a linguagem de configuração |
| Um script por tabela | Simples de começar | 80 scripts para manter; mudança de regra se espalha; revisão inviável |
| Ferramenta pronta de dados sintéticos | Nada a construir | Não conhece as invariantes do domínio; pouco controle sobre determinismo e volume |

## Decisão

Um **motor genérico em Python** lê um arquivo declarativo (JSON ou YAML) que descreve tabelas,
colunas, tipos, chaves estrangeiras, cardinalidades e distribuições, e usa o **`Faker`**
dinamicamente conforme o tipo declarado.

Regras que o `Faker` não representa — sazonalidade, afinidade entre produto, categoria e preço,
disponibilidade de estoque no momento da venda — são **provedores próprios** registrados no motor.

A geração é determinística por `seed` e `as_of_date`: a mesma combinação recria exatamente os
mesmos dados.

## Consequências

- **Positivas:** acrescentar domínio ou alterar regra é editar configuração; a revisão humana
  recai sobre um arquivo declarativo em vez de milhares de linhas geradas; o determinismo sustenta
  o princípio **P2** e permite que o manifesto do legado sirva de oráculo de teste.
- **Negativas:** o motor precisa ser bem projetado antes de ser útil, e casos muito específicos
  ainda exigirão provedores em código. A configuração vira artefato crítico — se estiver errada,
  todos os dados estarão.
- **Paridade com o GCP:** a geração é local por natureza; os dados gerados alimentam a nuvem por
  carga, sem dependência de infraestrutura.
- **Documentos a atualizar:** [Geração de Dados](../geracao_de_dados.md),
  [Origem Legada](../origem_legada.md), [Modelo de Dados](../modelo_de_dados.md).
