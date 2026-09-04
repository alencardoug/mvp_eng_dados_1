# Execução Local

> **O que vive aqui:** como operar o projeto pelo terminal — pré-requisitos, comandos e ordem de
> execução.
>
> **O que não vive aqui:** o que cada componente faz (ver [Arquitetura](arquitetura.md)); os
> parâmetros do gerador (ver [Geração de Dados](geracao_de_dados.md)); o orçamento de disco (ver
> [Capacidade e Recuperação](capacidade_e_recuperacao.md)).

| Campo | Informação |
|---|---|
| Interface | `Makefile` — a operação inteira acontece no terminal |
| Versão | 1.3 |
| Situação | Alvos da **Etapa 2** implementados e conferidos; os demais nascem na etapa indicada |
| Última revisão | 04/09/2026 |

Este documento é, hoje, o **contrato** do que a execução local deve oferecer. Cada alvo é
preenchido e conferido — executando-o — na etapa em que nasce, conforme o
[Plano de Desenvolvimento](plano_de_desenvolvimento.md).

---

## 1. Pré-requisitos

| Requisito | Observação |
|---|---|
| Docker e Docker Compose | Todo o ambiente roda em contêineres |
| `uv` | Gerencia interpretador, dependências e ambiente ([ADR-0026](adr/0026-uv-para-ambiente-e-dependencias.md)). Instala o Python 3.11 sozinho — não é preciso ter Python antes |
| Python 3.11 | Fixado por paridade com o Cloud Composer. `make install` cria o `.venv` e instala o pacote ([ADR-0012](adr/0012-repositorio-com-pacote-instalavel.md)) |
| `make` | Interface única de operação |
| Disco livre | **Pelo menos 8 GB** — o volume de dados é baixo por desenho ([ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)); o espaço é para imagem, log e WAL |
| Memória | **A restrição real do ambiente.** Airbyte, Airflow, Redpanda e Kafka Connect não precisam subir ao mesmo tempo; ver seção 5 |

Nenhum serviço de nuvem é necessário na fase local, e nenhuma credencial de nuvem deve existir na
máquina para executá-la.

---

## 2. Configuração

```bash
make env        # gera o .env com portas padrão e senhas aleatórias, permissão 600
make install    # instala o Python 3.11 e o pacote no .venv
```

O `.env.example` é versionado com as chaves e **sem** valores, e serve para declarar quais chaves
existem — não para ser copiado e preenchido à mão. `make env` recusa sobrescrever um `.env`
existente, porque trocar as senhas torna os volumes já criados inacessíveis. Ver
[Política de Governança de Dados](governanca_de_dados.md#9-tratamento-de-segredos).

---

## 3. Ciclo completo

A sequência abaixo leva de um repositório recém-clonado até as views de consumo.

| # | Comando | O que faz | Disponível na |
|---|---|---|---|
| 1 | `make up` | Sobe os contêineres base: `source_db`, `legacy_db`, `warehouse_db` | Etapa 2 |
| 2 | `make migrate` | Aplica as migrações Alembic do zero | Etapa 3 |
| 3 | `make seed-data` | Gera os dados sintéticos da origem principal | Etapa 4 |
| 4 | `make seed-legacy` | Gera a origem legada com as falhas intencionais | Etapa 10 |
| 5 | `make sync-airbyte` | Executa as sincronizações para `raw` e `raw_legacy` | Etapa 5 |
| 6 | `make dbt-build` | Roda os modelos dbt e os testes de dados | Etapa 5 |
| 7 | `make stream-up` | Sobe Redpanda, Kafka Connect com o conector Debezium e o *job* Beam | Etapa 7 |
| 8 | `make stream-produce` | Executa o produtor de eventos de estoque | Etapa 7 |
| 9 | `make dbt-docs` | Gera e serve o catálogo com dicionário, linhagem e glossário | Etapa 5 |
| 10 | `make size-report` | Relatório de tamanho por banco, schema, tabela e índice — observação, não limite | Etapa 4 |
| 11 | `make check` | Verificação completa: testes, reconciliações e revisão de segredos | Etapa 12 |

Parâmetros de execução — perfil de volume, `seed` e `as_of_date` — são passados por variável de
ambiente ou por argumento do alvo, nunca editados no código.

```bash
make seed-data                      # fator `dev`, padrão em todas as etapas
make seed-data SCALE=10             # fator maior, quando houver motivo declarado
```

O volume é expresso por **fator de escala** sobre um conjunto único de proporções
([ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)). Não há perfis de tamanho.

---

## 4. Alvos auxiliares

| Comando | O que faz | Disponível na |
|---|---|---|
| `make help` | Lista os alvos já implementados | Etapa 2 |
| `make ps` | Estado e portas dos contêineres | Etapa 2 |
| `make logs` | Acompanha os logs; `SERVICE=source_db` filtra | Etapa 2 |
| `make psql-source` · `make psql-legacy` · `make psql-warehouse` | Abre o `psql` no banco correspondente | Etapa 2 |
| `make down` | Derruba os contêineres preservando os volumes | Etapa 2 |
| `make reset` | Derruba e apaga os volumes — recomeço do zero | Etapa 2 |
| `make test` | Testes de código Python (`pytest`) | Etapa 4 |
| `make dbt-test` | Somente os testes de dados | Etapa 5 |
| `make airflow-up` | Sobe o Airflow | Etapa 5 |
| `make dag-run` | Dispara a DAG do fluxo completo | Etapa 5 |
| `make stream-down` | Derruba Kafka Connect, mensageria e o *job* | Etapa 7 |
| `make recover-dump` | Gera o pacote candidato do ponto de recuperação | Etapa 12 |
| `make recover-restore` | Restaura as origens a partir do pacote aprovado | Etapa 12 |

> `make reset` e `make recover-restore` **destroem estado**. `recover-restore` só é executado
> mediante decisão explícita do responsável técnico.

---

## 5. Executando por partes

Não é necessário — nem recomendável — manter tudo ativo ao mesmo tempo. O ambiente foi desenhado
para subir em subconjuntos, mitigação direta do risco **R11**:

| Cenário | O que precisa estar de pé |
|---|---|
| Desenvolver modelos dbt | `make up` + dados já carregados |
| Ajustar o gerador | `make up` apenas |
| Trabalhar no streaming | `make up` + `make stream-up` |
| Execução completa de validação | Tudo simultaneamente — apenas na Etapa 12 |

---

## 6. Solução de problemas

*Vazio.* Será preenchido com os problemas realmente encontrados, e não com hipóteses — princípio
**P5** (verdade por padrão).
