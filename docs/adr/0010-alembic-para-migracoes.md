# ADR-0010 — Usar Alembic para as migrações de schema

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 03/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D04 |

## Contexto

A Etapa 3 exige migrações **aplicáveis do zero e reversíveis**, e o banco precisa ser reconstruível
integralmente a partir do repositório (**P2**).

Esta decisão depende de [ADR-0009](0009-sqlalchemy-para-acesso-a-dados.md): a razão de existir do
Alembic é derivar migrações de modelos SQLAlchemy. Com um driver puro ele seria um invólucro Python
em volta de SQL escrito à mão, arrastando o SQLAlchemy como dependência sem usar o que ele oferece.
Com o ORM adotado, a relação se inverte e o Alembic passa a ser a escolha natural.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Alembic** | `autogenerate` deriva a migração dos modelos, mantendo uma fonte de verdade só; integração direta com a decisão D03; ecossistema Python já presente no projeto | O SQL fica atrás de uma DSL Python — o que se revisa não é DDL puro; `autogenerate` não produz `downgrade` confiável sem revisão |
| SQL versionado com ferramenta de arquivo único (`dbmate`, `golang-migrate`) | `.sql` puro, revisável diretamente; independe da escolha de acesso a dados | Deixaria o schema declarado nos modelos **e** nos arquivos SQL, reintroduzindo a duplicação que D03 acabou de eliminar |
| *Runner* próprio | Zero dependência externa | Ordenação, *checksums*, tabela de controle e aplicação transacional são encanamento de aplicação, não engenharia de dados |

## Decisão

As migrações são geridas por **Alembic**, com `autogenerate` a partir dos modelos SQLAlchemy.

Duas regras de uso acompanham a decisão, e existem por causa do risco **R14**:

1. **`autogenerate` produz rascunho, não migração.** Toda migração gerada é lida e revisada antes
   de ser aplicada. O Alembic não detecta com segurança renomeações, mudanças de tipo com conversão
   de dados nem alterações de *constraint* — o que ele não vê é escrito à mão.
2. **`downgrade` é escrito e testado, não presumido.** O critério de reversibilidade da Etapa 3 só
   é considerado satisfeito quando a descida foi executada, e não apenas gerada.

## Consequências

- **Positivas:** uma fonte de verdade do schema; `make migrate` nasce na Etapa 3 conforme a
  [Execução Local](../execucao_local.md) já prevê; nenhuma ferramenta fora do ecossistema Python.
- **Negativas:** o artefato revisado é Python, não DDL — o que exige a disciplina de revisão acima,
  já que a revisão humana é o gargalo real do projeto (**R14**). O `downgrade` passa a ser trabalho
  explícito em toda migração.
- **Paridade com o GCP:** as mesmas migrações aplicadas ao Cloud SQL, sem alteração. O BigQuery não
  é destino de migração — `analytics` é construído pelo dbt.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §3;
  [Execução Local](../execucao_local.md) §3.
