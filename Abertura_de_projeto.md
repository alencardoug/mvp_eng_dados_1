# Requisição do Termo de Abertura do Projeto

## 1. Identificação

| Campo | Informação |
|---|---|
| **Projeto** | MVP — Engenharia e Governança de Dados de Referência (`mvp_eng_dados_1`) |
| **Repositório** | `github.com/alencardoug/mvp_eng_dados_1` (pasta local: `mvp_ed1`) |
| **Versão** | 1.0 |
| **Status** | Rascunho para aprovação / Em iniciação |
| **Data** | 01/09/2026 |
| **Owner principal** | Douglas Alencar |
| **Líder de Governança** | Douglas Alencar |
| **DPO / Encarregado** | Douglas Alencar |
| **Data Custodian** | Douglas Alencar |
| **Responsável técnico** | Douglas Alencar |
| **Apoio de desenvolvimento** | Claude Code |
| **Natureza** | MVP técnico de engenharia de dados, evolutivo, público |
| **Idioma dos documentos** | Português brasileiro |
| **Idioma de código** | Inglês (código Python, nomes de objetos de banco, identificadores) |
| **Evolução prevista** | Fase local (pré-GCP) → Fase GCP |

---

## 2. Requisição de Abertura

Solicita-se a abertura formal do projeto **MVP — Engenharia e Governança de Dados de Referência**, destinado a construir, de ponta a ponta, um fluxo de dados que parta de um banco transacional estruturado e alcance um datamart analítico com camada de governança, views de consumo e documentação.

O projeto será conduzido primeiro em **infraestrutura local** (PostgreSQL + Python) e, quando maduro, **replicado no Google Cloud Platform** (Cloud SQL + BigQuery), preservando as mesmas boas práticas de modelagem, Data Warehouse e governança.

A solução será tratada como produto de engenharia: versionada, documentada, testada, reproduzível e evoluída de forma controlada.

---

## 3. Contexto e Justificativa

Projetos de engenharia de dados costumam ser apresentados apenas como diagramas ou trechos de pipeline, sem um caminho completo, reproduzível e governado do transacional até o consumo analítico.

Este MVP busca constituir uma **referência prática e auditável**, com evidências públicas como:

- modelo de dados transacional estruturado;
- geração/simulação de dados de origem;
- pipelines de ingestão e transformação;
- modelagem dimensional / datamart;
- catálogo, linhagem e regras de governança;
- testes de qualidade de dados;
- documentação de decisões e arquitetura;
- caminho de migração local → GCP.

O posicionamento central é demonstrar **engenharia e governança de dados de ponta a ponta**, com infraestrutura simples na origem e evolução para nuvem em estado da arte.

---

## 4. Objetivo

Construir e publicar um MVP de engenharia de dados capaz de:

1. manter um **banco transacional PostgreSQL** aderente a boas práticas de modelagem relacional;
2. **simular dados de origem** de forma controlada e repetível;
3. executar **ingestão e transformação em Python**, versionadas e testáveis;
4. entregar um **datamart analítico** (modelagem dimensional) com boas práticas de Data Warehouse;
5. aplicar **governança de dados**: dicionário, catálogo, linhagem, classificação e regras de acesso;
6. expor **views de consumo** estáveis para análise;
7. garantir **qualidade de dados** por testes automatizados;
8. manter **documentação** de arquitetura, decisões e execução;
9. preparar a arquitetura para **replicação no GCP** (Cloud SQL → BigQuery → views);
10. operar de forma **reproduzível, de baixo custo e segura**.

---

## 5. Meta Estratégica

Transformar o repositório em um **ativo técnico de referência**, capaz de:

- demonstrar domínio de modelagem transacional e dimensional;
- evidenciar prática real de governança de dados;
- comprovar capacidade de levar um fluxo do zero ao consumo;
- servir de base replicável para a fase GCP;
- sustentar futura apresentação em portfólio profissional.

A meta não é volume de dados ou de ferramentas, mas **um fluxo completo, correto, governado e explicável**.

---

## 6. Escopo Inicial — Fase Local (pré-GCP)

### 6.1 Banco transacional
- modelagem relacional normalizada (3FN como referência);
- chaves primárias e estrangeiras, constraints e índices;
- convenções de nomenclatura em inglês;
- migrações versionadas do schema;
- dados de exemplo (seed) mínimos.

### 6.2 Simulação de dados de origem
- geração programática de registros transacionais (Python);
- volume e distribuição parametrizáveis;
- execução repetível e determinística por semente (seed).

### 6.3 Ingestão e transformação
- extração do PostgreSQL para uma camada de staging;
- transformações em Python (e/ou SQL) versionadas;
- camadas explícitas: `raw` / `staging` / `trusted` / `analytics` (nomenclatura a confirmar);
- orquestração local simples (scripts ou ferramenta leve a avaliar).

### 6.4 Camada analítica / datamart
- modelagem dimensional (fatos e dimensões);
- boas práticas de Data Warehouse (grão definido, SCD quando aplicável);
- views de consumo documentadas.

### 6.5 Governança de dados
- dicionário de dados e catálogo dos objetos;
- linhagem origem → consumo;
- classificação de sensibilidade dos campos;
- regras de acesso e de retenção;
- padrões de nomenclatura e versionamento.

### 6.6 Qualidade e testes
- testes de integridade (unicidade, não nulos, relacionamentos);
- testes de regras de negócio;
- validação de contagens e reconciliação entre camadas;
- execução automatizada.

### 6.7 Documentação
- `README.md` alinhado a este Termo de Abertura;
- documento de arquitetura;
- registro de decisões (ADR);
- instruções de execução reproduzível.

---

## 7. Fora do Escopo Inicial

Não fazem parte da fase local:

- provisionamento em nuvem;
- streaming / ingestão em tempo real;
- ferramentas pesadas de orquestração em produção;
- data lake / formatos colunares distribuídos;
- BI / dashboards finais;
- CI/CD de infraestrutura;
- dados reais de terceiros ou de pacientes;
- credenciais ou segredos versionados;
- otimização de performance em larga escala;
- multi-tenant ou múltiplas fontes heterogêneas.

---

## 8. Evolução Prevista — Fase GCP

Após a fase local estabilizada:

- **Cloud SQL (PostgreSQL)** como transacional;
- carga para **BigQuery** como Data Warehouse;
- boas práticas de DW e governança no BigQuery (datasets, particionamento, clustering, políticas de acesso, rótulos);
- **views** de consumo equivalentes às da fase local;
- IaC e automação de deploy a definir;
- paridade funcional com a fase local como critério de migração.

---

## 9. Princípios

### 9.1 Fluxo completo antes de sofisticação
Prioriza-se um caminho origem → consumo funcionando de ponta a ponta antes de otimizar qualquer etapa.

### 9.2 Reprodutibilidade por padrão
Qualquer pessoa deve conseguir recriar o ambiente e os dados a partir do repositório.

### 9.3 Governança desde o início
Catálogo, linhagem e classificação nascem junto com os dados, não depois.

### 9.4 Paridade local ↔ GCP
Decisões da fase local devem ser replicáveis na nuvem sem reprojeto.

### 9.5 Verdade por padrão
Não inventar métricas, volumes, linhagens ou resultados; o que não existe é marcado como pendente.

### 9.6 Simplicidade arquitetural
O menor número razoável de serviços, ferramentas e dependências.

### 9.7 Privacidade por desenho
Somente dados sintéticos/simulados; nenhum dado pessoal real.

### 9.8 Documentação como fonte de verdade
Decisões relevantes vivem no repositório, versionadas.

### 9.9 Idioma
Documentos em português; código, identificadores e objetos de banco em inglês. Ver seção 20.

---

## 10. Arquitetura de Referência

**Fase local (candidata, a confirmar em ADR):**

- PostgreSQL (Docker);
- Python 3.x;
- biblioteca de acesso a dados / ORM a avaliar (ex.: SQLAlchemy);
- ferramenta de migração a avaliar (ex.: Alembic);
- geração de dados a avaliar (ex.: Faker);
- transformação a avaliar (SQL puro e/ou framework tipo dbt);
- testes de dados a avaliar (framework dedicado ou asserts em Python);
- orquestração local: scripts `make` / CLI própria inicialmente;
- controle de versão: Git + GitHub.

**Fase GCP (referência):**

- Cloud SQL for PostgreSQL;
- BigQuery;
- serviço de carga a definir;
- IaC a definir.

Decisões centrais:

- camadas de dados explícitas e nomeadas;
- schema versionado por migração;
- dados sempre sintéticos;
- nenhum segredo no repositório.

---

## 11. Entregas Principais

1. Repositório Git versionado e documentado.
2. Termo de Abertura, arquitetura e registro de decisões.
3. Schema transacional PostgreSQL com migrações.
4. Gerador de dados sintéticos parametrizável.
5. Pipeline de ingestão para staging.
6. Transformações até a camada analítica.
7. Datamart dimensional com views de consumo.
8. Dicionário de dados, catálogo e linhagem.
9. Regras de classificação, acesso e retenção.
10. Suíte de testes de qualidade de dados.
11. Instruções de execução reproduzível (local).
12. Plano de replicação para o GCP.

---

## 12. Critérios de Sucesso

### Produto
A partir do repositório deve ser possível:

- subir o banco transacional;
- gerar dados sintéticos;
- executar o pipeline completo;
- consultar as views de consumo;
- consultar catálogo e linhagem.

### Técnico

- execução reproduzível de ponta a ponta;
- migrações aplicáveis do zero;
- testes de qualidade passando;
- reconciliação de contagens entre camadas;
- ausência de segredos no repositório;
- documentação coerente com o código.

### Governança

- todo campo sensível classificado;
- linhagem origem → consumo documentada;
- decisões relevantes registradas em ADR;
- nomenclatura padronizada.

---

## 13. Premissas

- Douglas é responsável por escopo, decisões e aprovação.
- Todos os dados do MVP serão sintéticos/simulados.
- A fase local precede e condiciona a fase GCP.
- O ambiente local usará contêineres.
- Custos da fase local são próximos de zero.
- Claude Code atua como ferramenta de desenvolvimento assistido, sem poder de aprovação.
- O repositório é público.

---

## 14. Restrições

- evitar custos recorrentes desnecessários;
- evitar complexidade sem valor demonstrável;
- não usar dados pessoais reais ou de terceiros;
- não versionar credenciais, tokens ou segredos;
- não introduzir serviço de nuvem antes da fase GCP;
- não adicionar ferramentas apenas para ampliar a stack;
- manter paridade conceitual entre local e GCP.

---

## 15. Riscos Iniciais

| Risco | Impacto | Tratamento |
|---|---|---|
| Escopo crescer além de um MVP | Alto | Termo de Abertura + controle de mudanças |
| Overengineering de orquestração | Médio/Alto | Começar com scripts simples |
| Divergência entre fase local e GCP | Alto | Princípio de paridade + ADR |
| Governança tratada como etapa final | Alto | Catálogo e linhagem desde o início |
| Dados sintéticos irrealistas | Médio | Parâmetros de distribuição revisados |
| Falta de reprodutibilidade | Alto | Contêineres + seeds + migrações |
| Segredos versionados por engano | Muito alto | `.gitignore` + revisão + convenção de `.env` |
| Dependências excessivas | Médio | Governança técnica + ADR |
| Custos inesperados na fase GCP | Médio | Faixas gratuitas + revisão antes de provisionar |
| Documentação desatualizada | Médio | Documentação versionada junto ao código |

---

## 16. Governança de Dados e Privacidade

### Dados permitidos
- dados sintéticos gerados pelo próprio projeto;
- metadados, dicionário e catálogo;
- estatísticas agregadas do pipeline.

### Dados não permitidos
- dados pessoais reais;
- dados de pacientes ou de terceiros;
- extrações de sistemas corporativos;
- datasets privados sem autorização;
- credenciais, tokens e segredos.

### Controles
- classificação de sensibilidade por campo;
- linhagem origem → consumo;
- regras de acesso por camada;
- política de retenção documentada;
- segredos apenas em `.env` local, nunca versionados.

---

## 17. Papéis e Responsabilidades

| Papel | Responsável | Responsabilidade |
|---|---|---|
| Owner principal | Douglas Alencar | Aprovar escopo e prioridades |
| Líder de Governança | Douglas Alencar | Garantir aderência às regras do projeto |
| DPO / Encarregado | Douglas Alencar | Revisar exposição e classificação de dados |
| Data Custodian | Douglas Alencar | Manter dados, catálogo e linhagem corretos |
| Responsável técnico | Douglas Alencar | Arquitetura, implementação e testes |

Claude Code atua como ferramenta de desenvolvimento assistido e não assume responsabilidade de aprovação.

---

## 18. Gestão de Mudanças

### Mudança operacional
Não altera objetivo, escopo ou arquitetura central. Implementada e documentada diretamente.

### Mudança relevante
Altera modelagem central, camadas de dados, arquitetura ou tratamento de dados. Requer decisão explícita do Owner e ADR.

### Mudança de escopo
Inclui nuvem antecipada, streaming, novas fontes ou BI. Passa por avaliação de valor, custo, risco e aderência a este Termo.

---

## 19. Controle de Qualidade

Antes de considerar uma entrega concluída:

- migrações aplicáveis do zero;
- pipeline executável de ponta a ponta;
- testes de qualidade de dados passando;
- reconciliação entre camadas conferida;
- catálogo e linhagem atualizados;
- revisão de segredos e de `.gitignore`;
- documentação revisada;
- README coerente com o Termo de Abertura.

---

## 20. Convenção de Idioma

- **Documentos, comentários de governança, READMEs, ADRs, dicionário de dados e textos explicativos:** português brasileiro.
- **Código Python, nomes de variáveis, funções, módulos, tabelas, colunas, schemas, views e identificadores técnicos:** inglês.
- **Mensagens de commit:** português.
- **Exceções:** termos técnicos consagrados (ex.: *staging*, *data warehouse*, *view*) podem permanecer em inglês dentro de textos em português; conteúdo que precise ser em inglês por exigência de ferramenta ou padrão externo é gerado em inglês.

---

## 21. Documentação de Referência

A fonte de verdade permanece no repositório, incluindo:

- `README.md`;
- `Abertura_de_projeto.md` (este documento);
- `CLAUDE.md` (a criar);
- documento de arquitetura (a criar);
- registro de decisões / ADR (a criar);
- dicionário de dados e catálogo (a criar);
- instruções de execução (a criar).

---

## 22. Aprovação

| Papel | Responsável | Situação |
|---|---|---|
| Owner principal | Douglas Alencar | Pendente de aprovação formal |
| Líder de Governança | Douglas Alencar | Pendente de aprovação formal |
| DPO / Encarregado | Douglas Alencar | Pendente de aprovação formal |
| Data Custodian | Douglas Alencar | Pendente de aprovação formal |
| Responsável técnico | Douglas Alencar | Pendente de aprovação formal |

### Decisão solicitada

**Autorizar o início e a execução da fase local (pré-GCP) do projeto MVP — Engenharia e Governança de Dados de Referência, conforme escopo, princípios, premissas, restrições e critérios estabelecidos neste Termo de Abertura.**
