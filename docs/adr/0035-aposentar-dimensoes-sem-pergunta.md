# ADR-0035 — Aposentar `dim_time` e `dim_currency`, que nenhuma pergunta recorta

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 9) |
| Substitui / é substituída por | — |

## Contexto

O inventário dimensional do [Modelo de Dados](../modelo_de_dados.md#3-modelo-dimensional) foi
escrito na Etapa 0, antes de existir uma linha de SQL, e lista **17 dimensões**. Duas delas
atravessaram cinco etapas sem que nada as tocasse:

| Dimensão | Linhas previstas | Quem a referencia hoje |
|---|---:|---|
| `dim_time` | 1.440 — hora, minuto e faixas do dia | Ninguém |
| `dim_currency` | 1 — moeda e código ISO | Ninguém |

"Ninguém" é literal: nenhum modelo dbt, nenhuma view de consumo e **nenhuma das 16 perguntas de
negócio**. As duas aparecem exclusivamente na tabela do inventário, e a Etapa 9 é a etapa em que o
critério de conclusão manda construir as dimensões restantes.

O projeto já decidiu essa questão duas vezes, em camadas diferentes, e nas duas na mesma direção:

- o [ADR-0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) fixou que **fato e dimensão
  nascem da pergunta**, e não de um inventário anterior a elas;
- o [`airbyte/streams.yml`](../../airbyte/streams.yml) aplica a mesma regra à ingestão, com estas
  palavras: *"ingerir tabela que nenhum modelo lê é volume sem consumidor"*.

Construir 1.440 linhas de hora que nada recorta é a mesma coisa, uma camada adiante. A pergunta é se
a lista da Etapa 0 vence a regra do ADR-0018, ou o contrário.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Aposentar as duas do inventário** | Faz o inventário obedecer à regra que o próprio projeto adotou depois de escrevê-lo. O `dbt docs` deixa de ganhar dois nós sem linhagem de saída, que é o sintoma exato que o ADR-0018 existe para evitar, e o critério da Etapa 9 passa a contar o que foi construído em vez do que foi previsto | Se aparecer pergunta por faixa do dia ou por segunda moeda, a dimensão precisa ser criada naquele momento. É custo real, e pequeno: `dim_time` é uma série gerada, como `dim_date` já é |
| Construir as duas | Cumpre o inventário à risca, e `dim_time` é dimensão clássica em datamart de varejo. A moeda conformada prepara o dia em que houver a segunda | Entram duas dimensões que nenhum fato recorta e nenhuma view lê. E cria precedente ruim: passa a valer construir por antecipação, que é a porta pela qual o modelo cresce sem que ninguém consiga dizer para quê |
| Construir só `dim_time` | Hora do dia costuma aparecer cedo como recorte, e as fatos já carregam o instante do evento | Mantém metade do problema e perde o critério: as duas são órfãs pela mesma razão, e separá-las exigiria um motivo que não existe. "Esta parece mais provável de ser usada" não é critério, é palpite |
| Deixar as duas no inventário como *previstas*, sem construir | Não perde a intenção de projeto | É o pior dos dois: o documento continua prometendo o que o repositório não entrega, e a divergência entre inventário e realidade é justamente o defeito que o **P8** trata |

## Decisão

`dim_time` e `dim_currency` **saem do inventário dimensional**. O modelo dimensional do projeto passa
a ter **10 fatos e 15 dimensões**, e o critério de conclusão da Etapa 9 passa a nomear esses números.

A moeda continua existindo como **atributo** em `trusted.orders` (`currency`), onde sempre esteve.
Não é perda de informação: é a diferença entre um atributo constante e uma dimensão.

Se uma pergunta futura pedir recorte por faixa do dia ou por moeda, a dimensão nasce ali, pelo
caminho normal do ADR-0018 — da pergunta para o modelo.

## Consequências

- **Positivas:** o inventário passa a descrever o que existe. Toda dimensão do datamart tem pelo
  menos um fato que a recorta, e isso vira asserção verificável em vez de intenção — nó sem linhagem
  de saída no `dbt docs` passa a ser sintoma, não paisagem.
- **Negativas:** o projeto deixa de exercitar `dim_time`, que é um padrão dimensional de verdade e
  que alguém estudando o resultado poderia esperar encontrar. Aceita-se: exercitar um padrão sem uso
  é exercitar a forma, não a decisão, e o que este MVP existe para praticar é a segunda.
- **Paridade com o GCP:** nenhuma. É escopo de inventário, e vale igual nas duas fases. O efeito lá
  é favorável na margem — duas tabelas a menos no dataset e no `dbt docs`.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md) §3 — o total e a tabela de
  dimensões; [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — o critério de conclusão da
  Etapa 9.
