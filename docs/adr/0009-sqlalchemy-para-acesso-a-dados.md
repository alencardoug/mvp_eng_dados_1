# ADR-0009 — Usar SQLAlchemy para o acesso a dados em Python

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 03/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D03 |

## Contexto

O Python encosta no banco em quatro lugares: o gerador de dados sintéticos (Etapa 4), o gerador da
origem legada (Etapa 10), o produtor de eventos de estoque e o *pipeline* Beam (Etapa 7). Nenhum
deles é uma aplicação transacional — não há CRUD, objetos de domínio de vida longa nem ciclo de
sessão de usuário.

A questão central não é ergonomia de escrita, e sim **onde vive a definição do schema**. São 40
tabelas na origem principal: qualquer desenho que as declare em dois lugares independentes viola o
princípio **P8** em forma de código, porque as duas declarações divergem.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **SQLAlchemy** | Os modelos passam a ser a fonte única do schema, e o Alembic **deriva** as migrações deles por `autogenerate` — duas declarações viram uma derivação; ordenação de dependências referenciais resolvida pelo mapeamento; ecossistema Python maduro e amplamente documentado | Não alcança o destino BigQuery do Beam; *unit of work* é o instrumento errado para carga em massa; curva de aprendizado própria |
| Driver puro (`psycopg` 3) | SQL explícito e revisável; `COPY` nativo; zero acoplamento com a ferramenta de migração | Deixa o schema declarado nas migrações **e** na configuração do gerador, sem nada que force a coerência entre os dois além de disciplina |
| ORM só no transacional, SQL puro no analítico | Usa cada ferramenta onde ela é mais forte | Dobra o ferramental e cria duas formas de fazer a mesma coisa no mesmo repositório |

## Decisão

O acesso a dados em Python usa **SQLAlchemy**, e os **modelos são a fonte de verdade do schema**
da origem principal. As migrações são derivadas deles ([ADR-0010](0010-alembic-para-migracoes.md)).

Duas fronteiras ficam declaradas desde já, porque não são falhas do desenho e sim os seus limites:

1. **Carga em massa não passa pelo *unit of work*.** A geração de `cart_items` e das demais tabelas
   de alto volume usa `COPY` pela conexão bruta exposta pelo SQLAlchemy. Inserir mais de um milhão
   de linhas objeto a objeto é ordens de grandeza mais lento e não é o uso pretendido do ORM.
2. **O *pipeline* Beam não usa SQLAlchemy.** Ele escreve pelos conectores de I/O do próprio Beam —
   localmente no `warehouse_db`, no BigQuery na fase GCP. É o que preserva o princípio **P4**: o
   mesmo código Beam roda nos dois ambientes.

## Consequências

- **Positivas:** o schema tem um dono único e verificável; a configuração do gerador passa a ser
  validada contra os modelos em vez de repeti-los; a ordenação referencial da geração sai do
  mapeamento, não de uma lista mantida à mão.
- **Negativas:** duas formas de escrever no banco convivem no mesmo repositório — ORM para o
  caminho normal, `COPY` para o caminho de volume —, e a fronteira entre elas precisa estar
  documentada onde o gerador é descrito. O SQLAlchemy é uma dependência a mais e tem custo de
  aprendizado próprio, aceito em troca da fonte única de schema.
- **Paridade com o GCP:** o mesmo SQLAlchemy contra o Cloud SQL, sem alteração. O destino BigQuery
  é alcançado pelo Beam, não pelo ORM — fronteira declarada acima, não lacuna de paridade.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §3;
  [Geração de Dados](../geracao_de_dados.md) §1.
