# Princípios do Projeto

> **O que vive aqui:** as dez regras que governam toda decisão do projeto. São referenciadas por
> identificador (**P1**–**P10**) em todos os demais documentos.
>
> **O que não vive aqui:** o objetivo e o escopo (ver [Termo de Abertura](../Abertura_de_projeto.md));
> as decisões concretas que aplicam estes princípios (ver [Registro de Decisões](adr/README.md)).

Um princípio serve para resolver discussão. Quando duas opções parecem equivalentes, vence a que
respeita o princípio — e quando uma decisão viola algum deles, ela precisa de ADR declarando o
porquê.

---

| ID | Princípio | O que significa na prática |
|---|---|---|
| **P1** | **Fluxo completo antes de sofisticação** | Um caminho origem → consumo funcionando de ponta a ponta vem antes de otimizar qualquer etapa. É por isso que o trabalho avança em cortes verticais, e não camada por camada. |
| **P2** | **Reprodutibilidade por padrão** | Qualquer pessoa recria ambiente e dados a partir do repositório. Contêineres, semente explícita, migrações versionadas e dependências fixadas. |
| **P3** | **Governança desde o início** | Catálogo, linhagem e classificação nascem junto com os dados. Campo sem classificação bloqueia a conclusão da etapa que o criou. |
| **P4** | **Paridade local ↔ GCP** | Toda decisão local tem contrapartida direta na nuvem, registrada no [mapa de paridade](arquitetura.md#5-mapa-de-paridade-local--gcp). Decisão sem equivalente não é aceitável. |
| **P5** | **Verdade por padrão** | Nada de métricas, volumes, linhagens ou resultados inventados. "Planejado" e "medido" são rótulos diferentes e nunca se misturam; o que não existe é marcado como pendente. |
| **P6** | **Simplicidade arquitetural** | O menor número razoável de serviços, ferramentas e dependências. Nenhum componente entra sem declarar o problema que resolve. |
| **P7** | **Privacidade por desenho** | Somente dados sintéticos — e ainda assim classificados e controlados como se fossem reais. Ver [Política de Governança de Dados](governanca_de_dados.md). |
| **P8** | **Documentação como fonte de verdade** | Decisões relevantes vivem no repositório, versionadas junto do código. Um assunto tem um único dono documental; duplicação é defeito. |
| **P9** | **Idioma** | Documentos em português; código, objetos de banco e identificadores em inglês. Detalhes em [`CLAUDE.md`](../CLAUDE.md). |
| **P10** | **Fidelidade à prática de produção** | Diante de alternativas, vence a que um ambiente produtivo real adotaria — ainda que custe mais processo, memória ou tempo. O objetivo do projeto é enfrentar os desafios comuns de produção, não contorná-los com atalhos que o volume baixo do ambiente local permitiria. |

---

## Quando os princípios se contradizem

Acontece — e o caso mais frequente é **P4** contra **P6**: a paridade com a nuvem às vezes pede uma
ferramenta a mais do que a simplicidade gostaria. Foi o que ocorreu ao adotar Airbyte, Airflow e
dbt desde a fase local ([ADR-0003](adr/0003-stack-airbyte-dbt-airflow.md)) e ao incluir o fluxo de
streaming ([ADR-0006](adr/0006-streaming-de-estoque-com-cdc-e-beam.md)).

A regra de desempate é simples: **P4 prevalece quando a alternativa mais simples criaria dois
caminhos diferentes entre as fases**, porque nesse caso a simplicidade é aparente — ela apenas
adia o custo para a migração. Fora disso, prevalece **P6**.

O segundo caso é **P10** contra **P6**: a prática de produção quase sempre pede mais peças do que a
simplicidade gostaria. Foi o que ocorreu ao escolher Kafka Connect em vez do Debezium Server
autônomo, e Cloud Composer em vez de orquestração nativa mais barata.

A regra de desempate: **P10 prevalece quando a alternativa mais simples só é viável porque o
ambiente local é pequeno** — ou seja, quando a simplicidade não sobreviveria ao volume real. Fora
disso, prevalece **P6**. O que **P10 não autoriza** é componente sem problema declarado: ele ordena
alternativas para um problema que existe, não cria motivo para ampliar a *stack*.

O desempate é registrado em ADR, nunca decidido em silêncio.
