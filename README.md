# mvp_eng_dados_1 — Engenharia e Governança de Dados de Referência

MVP que constrói, de ponta a ponta, um fluxo de dados sobre um **marketplace de varejo
*omnichannel* sintético**: de um banco transacional PostgreSQL até um **datamart dimensional** com
**governança**, views de consumo e documentação. O projeto é conduzido primeiro em **infraestrutura
local** e, quando maduro, **replicado no Google Cloud Platform** com Terraform, preservando as
mesmas boas práticas.

Todos os dados são **sintéticos**. Nenhum dado pessoal real é usado em nenhuma fase.

```text
Faker → PostgreSQL → Airbyte → dbt → datamart → consumption     (batch, orquestrado por Airflow)
                  ↘ Debezium → Redpanda → Apache Beam ↗        (streaming de estoque)
        legado defeituoso → snapshot → limpeza → quarentena     (segunda origem)
```

## Fases

1. **Local (pré-GCP)** — duas origens transacionais, geração determinística de dados, ingestão,
   transformação em camadas, datamart dimensional, um fluxo contínuo restrito ao estoque,
   governança e testes. Tudo reproduzível a partir do repositório.
2. **GCP** — replicação do fluxo com Cloud SQL, BigQuery, Datastream, Pub/Sub e Dataflow,
   provisionado por Terraform, com a mesma governança materializada em *policy tags*.

## Mapa da documentação

Cada assunto tem **um único dono documental**. Se a informação está em dois lugares, é defeito.

| Artefato | O que só existe ali | Situação |
|---|---|---|
| [Termo de Abertura](Abertura_de_projeto.md) | Justificativa, objetivo, escopo, entregas, critérios de sucesso, premissas, restrições, papéis e aprovação | v1.2 — **aprovado** |
| [`CLAUDE.md`](CLAUDE.md) | Idioma, nomenclatura, *commits*, modo de desenvolvimento assistido e definição de pronto | Vigente |
| [Princípios](docs/principios.md) | As dez regras **P1**–**P10** que governam as decisões | Vigente |
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v2.9 — Etapa 10 em implementação |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.1 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | v1.6 — inventário e diagrama **gerados** |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | v3.2 — gerador corrigido na D31 |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, catálogo de falhas, limpeza, quarentena e empilhamento | v2.3 |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | v2.1 — revalidado na D31 |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | v1.10 |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Dimensionamento por cobertura, medição e ponto único de recuperação | v2.8 — medições da D31 separadas das históricas |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.1 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | **Gerado** — 40 tabelas, 418 campos |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo e as perguntas de negócio, importados pelo dbt | 16 perguntas, 16 conceitos |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | Nenhuma decisão pendente em 15/09/2026 |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 47 aceitos, 0 pendentes |
| [Materialização no dbt](docs/materializacao.md) | Materializações, estratégias de incremental e o critério de robustez que escolhe entre elas | Vigente — base do [ADR-0016](docs/adr/0016-materializacao-por-camada.md) |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | Vigente |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | v1.7 — reconstrução dos dois caminhos conferida |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

**47 ADRs aceitos.** As escolhas que mais definem o projeto: domínio de varejo *omnichannel* ·
Airbyte, dbt e Airflow desde a fase local · Terraform como infraestrutura como código · geração com
Faker orientada a configuração · streaming de estoque com Debezium sobre Kafka Connect, Redpanda e
Apache Beam · catálogo como código · **nove schemas no armazém**, com `governance` restrito a
controle e auditoria · **SQLAlchemy e Alembic** · quatro níveis de classificação e cinco papéis de
acesso · `src/` como pacote Python instalável · prefixo por tipo nos objetos de banco ·
**volume por proporções e fator de escala**, com o alto volume reservado à fase GCP · views e
tabelas por camada, com incremental como exceção justificada · chaves substitutas por *hash* e
SCD tipo 2 por *snapshot* · Cloud Composer e Airbyte em contêiner na nuvem, em janela curta ·
**`uv` e Python 3.11** · configuração do gerador em YAML, com o piso de cobertura derivado dos
modelos · **entrega medida em dois grãos** — no prazo pela remessa, ciclo pelo pedido — com a data
realizada tirada do livro de eventos, e não da coluna da remessa · **dimensão que nenhuma pergunta
recorta não é construída**, e a recompra pós-atendimento é ancorada no pedido · **nulo obrigatório
após a limpeza é rejeitado**, sem apagar a evidência da conversão · **a captura legada é
reconciliada na fato incremental por `delete+insert`**, com o *streaming* mantendo o filtro por
tempo de evento · **cada captura do legado é certificada por conteúdo, por *stream* e por *job***,
e só captura certificada é elegível · **a exclusão física do legado é detectada no bruto retido**,
entre capturas certificadas, sem marca nas dimensões — a cascata e o `delete+insert` já retiram do
datamart o que dependia do registro · **a fase local é validada por partes**, sem exigir *batch* e
*streaming* simultâneos — a concorrência entre os dois é medida na fase GCP · **o CTE de limpeza do legado é materializado no
PostgreSQL** — o planejador o embutia em cada referência, a 10× o custo.

Contexto, alternativas e consequências de cada uma em [`docs/adr/`](docs/adr/).

## Status

**Etapa 10 — Corte 6: origem legada, reaberta em 07/09/2026 — achados da terceira revisão
implementados e medidos em 15/09/2026, aguardando revisão.** Foi declarada
concluída em 06/09 e duas revisões por outro agente mostraram que não estava. O empilhamento em
`trusted`, ausente na primeira revisão, existe desde 07/09 e teve a identidade por origem conferida
no SQL pela terceira. Esta, de 08/09, deixou treze achados abertos; nove foram fechados com
contraprova — validação de data, reversibilidade de codificação, ambiguidade monetária, recuperação
do valor injetado, identidade do vínculo com a auditoria, guarda de configuração da impressão
digital, avaliação real das views, e dois na troca automática de ambientes. Os que continuavam abertos —
**R09, R10, R12, R13, R14 e R26** — foram implementados em 14–15/09/2026 sob um plano revisado três
vezes pelo outro agente: cada captura do legado é **certificada por conteúdo** em duas fases
([ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md)); a **exclusão física** é
detectada no bruto retido entre capturas certificadas
([ADR-0045](docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md)); o schema legado
entrou no **Alembic**; o manifesto tem **veredito esperado de toda ocorrência** e a captura é
conferida por hash antes de comparar; e a identidade da captura passou a ser o *job* do Airbyte,
porque a geração se mostrou por *stream*. **Medido em 15/09/2026:** 12.747 vereditos iguais ao
oráculo; oito capturas certificadas (jobs 28–36), uma recusada de propósito (39/40 tabelas);
remoção, inclusão, redução, persistência e reaparecimento medidos entre capturas reais;
`make dbt-build` completo com `PASS=891 ERROR=0`; DAG `fluxo_batch` com 12 tarefas em 13 min,
certificando a captura dentro dela; `make test FATO=1` com 180 passed. **Aguarda a revisão do
desenvolvimento; a etapa não está aceita.** O R25 foi implementado em 08/09 pelo
[ADR-0042](docs/adr/0042-reconciliar-a-captura-legada-na-fato-incremental.md) e provado por
reprocessamento, não por reconstrução; a revisão dessa entrega (08/09) confirmou o mecanismo em
sondas isoladas, e os quatro achados dela foram fechados em 14/09. **Estado do armazém medido em
15/09/2026:** captura selecionada 36 (*job* da DAG), tratamento na versão 8 — a árvore está na 9 desde o
[ADR-0047](docs/adr/0047-materializar-o-cte-de-limpeza-do-legado.md), sem regra nova, e o armazém a
receberá no próximo *build* completo —,
16 das 16 views publicadas, fato com 16.403 linhas (15.900 `retail` + 503 `legacy`); `make dbt-build`
completo com `PASS=891 ERROR=0`. As observações anteriores — 2 das 16 views e tratamento na versão 5
em 08/09; captura 16 e versão 7 em 14/09 — descrevem o banco **antes** das reconstruções seguintes.
Termo aprovado (**M0**), decisões em ADR (**M1**), ambiente
subindo do zero com um comando (**M2**), **fluxo completo origem → consumo** em operação (**M3**) e
**streaming em operação com o *batch* intacto** (**M4**).

Seis cortes verticais entregues — comercial, financeiro e estoque, o caminho quente, entrega e
logística, relacionamento e a **origem legada**. O modelo dimensional está completo: 10 fatos e 15
dimensões, e as 16 perguntas de negócio têm view com `contract: enforced`. O armazém tem **36 fluxos
de ingestão em lote** da origem principal, o **CDC de `inventory_movements`** e **40 do legado**, e o
`dbt build` passa com **863 objetos, `WARN=0` e `ERROR=0`** (medido em 08/09/2026).

**A segunda origem atravessa da captura até o modelo dimensional.** São 12.747 ocorrências
capturadas: **81,9% aceitas, 17,9% rejeitadas** em quarentena com motivo e **0,2% corrigidas**, com
valor original, resultado e regra registrados. Das 10.467 aptas, **10.233 são empilhadas** em
`trusted` ao lado da origem principal — as outras 234 estão em quatro tabelas que o legado tem e a
origem principal não, e por isso não têm com que se unir. A equação
`extraídos = aceitos + corrigidos + rejeitados` é conferida a cada *build*, e agora também
`empilhados = aceitos + corrigidos`, tabela por tabela. Os modelos de limpeza encontram os **106
achados** injetados em 88 ocorrências — medidos contra o manifesto, que a transformação nunca lê.

A procedência viaja junto: `source_system` é coluna em toda tabela empilhada, entra na chave
substituta das dimensões e qualifica cada junção. "Quantos registros vieram do legado?" é uma
cláusula `WHERE` — 74 clientes em `dim_customer`, 264 itens em `fact_sales_order_item`. A DAG `fluxo_batch` roda **dez
tarefas** de ponta a ponta em **5 min 20 s**, com as duas capturas em paralelo.

O mesmo livro de estoque chega por **dois caminhos independentes** — Debezium sobre Kafka Connect e
carga completa do Airbyte —, com sobreposição total e de propósito. A revalidação comparou
**chaves e payloads**, saldo por armazém/SKU, duplicatas no transporte, alertas e fato incremental
contra reconstrução completa. Detalhes do corte atual em
[Streaming §7.2](docs/streaming.md#72-revalidação-da-d31).

A geração corrigida preservou a cobertura das 40 tabelas e dos pedidos divididos. A nova
[invariante 13](docs/modelo_de_dados.md#4-invariantes-de-negócio) impede caixas vazias, e P13
reconcilia com as remessas entregues em `trusted`. Volumes, tempos e comparação anterior/posterior
em [Capacidade §2.7](docs/capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026), sem substituir
as medições históricas.

O ponto de partida da operação é [Execução Local](docs/execucao_local.md):

```bash
make env && make install && make up && make migrate && make seed-data
make tools && make airbyte-up && make airbyte-config && make airflow-up && make dag-run
```

E o caminho quente, que sobe separado do frio de propósito — os dois não precisam conviver fora da
validação final (risco **R11**):

```bash
make stream-up && make stream-run          # o pipeline fica em primeiro plano
make stream-produce && make stream-alerts  # em outro terminal
```
