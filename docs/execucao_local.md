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
| Versão | 1.0 |
| Situação | **Nenhum comando implementado ainda.** Cada alvo passa a existir na etapa indicada |
| Última revisão | 01/09/2026 |

Este documento é, hoje, o **contrato** do que a execução local deve oferecer. Cada alvo é
preenchido e conferido — executando-o — na etapa em que nasce, conforme o
[Plano de Desenvolvimento](plano_de_desenvolvimento.md).

---

## 1. Pré-requisitos

| Requisito | Observação |
|---|---|
| Docker e Docker Compose | Todo o ambiente roda em contêineres |
| Python 3.x | Versão exata fixada na Etapa 2 |
| `make` | Interface única de operação |
| Disco livre | **Pelo menos 8 GB** — os dados cabem em 4 GB, o resto é imagem, log e WAL |
| Memória | Airbyte, Airflow e a mensageria não precisam subir ao mesmo tempo; ver seção 5 |

Nenhum serviço de nuvem é necessário na fase local, e nenhuma credencial de nuvem deve existir na
máquina para executá-la.

---

## 2. Configuração

```bash
cp .env.example .env      # preencher localmente; nunca versionar
```

O `.env.example` é versionado com as chaves e **sem** valores. Ver
[Política de Governança de Dados](governanca_de_dados.md#9-tratamento-de-segredos).

---

## 3. Ciclo completo

A sequência abaixo leva de um repositório recém-clonado até as views de consumo.

| # | Comando | O que faz | Disponível na |
|---|---|---|---|
| 1 | `make up` | Sobe os contêineres base: `source_db`, `legacy_db`, `warehouse_db` | Etapa 2 |
| 2 | `make migrate` | Aplica as migrações de schema do zero | Etapa 3 |
| 3 | `make seed-data` | Gera os dados sintéticos da origem principal | Etapa 4 |
| 4 | `make seed-legacy` | Gera a origem legada com as falhas intencionais | Etapa 10 |
| 5 | `make sync-airbyte` | Executa as sincronizações para `raw` e `raw_legacy` | Etapa 5 |
| 6 | `make dbt-build` | Roda os modelos dbt e os testes de dados | Etapa 5 |
| 7 | `make stream-up` | Sobe CDC, mensageria e o *job* Beam | Etapa 7 |
| 8 | `make stream-produce` | Executa o produtor de eventos de estoque | Etapa 7 |
| 9 | `make dbt-docs` | Gera e serve o catálogo com dicionário, linhagem e glossário | Etapa 5 |
| 10 | `make size-report` | Relatório de tamanho por banco, schema, tabela e índice | Etapa 4 |
| 11 | `make check` | Verificação completa: testes, reconciliações e revisão de segredos | Etapa 12 |

Parâmetros de execução — perfil de volume, `seed` e `as_of_date` — são passados por variável de
ambiente ou por argumento do alvo, nunca editados no código.

```bash
make seed-data PROFILE=smoke        # subconjunto rápido para desenvolvimento
make seed-data PROFILE=demo_4gb     # perfil de portfólio
```

---

## 4. Alvos auxiliares

| Comando | O que faz | Disponível na |
|---|---|---|
| `make down` | Derruba os contêineres preservando os volumes | Etapa 2 |
| `make reset` | Derruba e apaga os volumes — recomeço do zero | Etapa 2 |
| `make test` | Testes de código Python (`pytest`) | Etapa 4 |
| `make dbt-test` | Somente os testes de dados | Etapa 5 |
| `make airflow-up` | Sobe o Airflow | Etapa 5 |
| `make dag-run` | Dispara a DAG do fluxo completo | Etapa 5 |
| `make stream-down` | Derruba CDC, mensageria e o *job* | Etapa 7 |
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
| Execução completa de validação | Tudo, com o perfil `demo_4gb` |

---

## 6. Solução de problemas

*Vazio.* Será preenchido com os problemas realmente encontrados, e não com hipóteses — princípio
**P5** (verdade por padrão).
