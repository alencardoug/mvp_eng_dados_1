# Revisão da governança para uma interface navegável

| Campo | Informação |
|---|---|
| Data | 10/11/2026 |
| Pedido | Registrar lacunas, falhas e limitações encontradas na avaliação de viabilidade do portal |
| Referência Git | `8e606d90277d47013d9b7df56a14f994a19bf863` |
| Escopo | Documentação, definições de dados, metadados e linhagem disponíveis localmente |
| Natureza | Parecer; nenhuma correção de implementação ou decisão de arquitetura foi executada |

Este arquivo registra os achados desta avaliação e os encaminhamentos sugeridos. Não substitui os
documentos responsáveis pelas regras, números, decisões ou pendências. Os valores citados abaixo
são fotografias datadas da revisão; sua manutenção continua nos artefatos indicados.

Havia alteração de outra sessão em `docs/registro_fase_gcp.md`; ela foi consultada e preservada.
Esta revisão não representa aceite de etapa, aprovação de declarativo nem reabertura automática
das limitações já aceitas pelo Owner.

## 1. Parecer

**A estrutura existente é viável para sustentar o portal.** Catálogo como código, glossário,
metadados e exportação da linhagem já permitem ligar perguntas, views, modelos e fontes.

Ainda não é possível prometer explicação integral de todas as colunas ou apresentar toda informação
documental como estado atual e uniforme dos ambientes. Há divergências documentais confirmadas,
descrições ausentes, limitações conhecidas e necessidades de integração com o futuro portal.

## 2. Evidências verificadas

| Verificação | Resultado observado |
|---|---|
| Definição transacional em SQLAlchemy | 40 tabelas, 418 colunas |
| Manifesto local | `dbt/target/manifest.json`, de `2026-11-09T15:23:16.533989Z`, adaptador `postgres` |
| Objetos de `analytics` no manifesto | 25: 10 fatos e 15 dimensões |
| Objetos de `consumption` no manifesto | 16 views, todas com contrato `enforced` |
| Colunas declaradas de `analytics` | 477; nenhuma sem descrição ou sensibilidade |
| Colunas declaradas de `consumption` | 188; nenhuma sem descrição ou sensibilidade |
| `owner` e `domain` nessas duas camadas | Presentes em todos os objetos examinados |
| Conferência existente de atualização | `sensitivity.stale_nodes(manifest)` retornou lista vazia, com os limites da §4 |
| Execução do exportador `models.lineage --json` | Concluída com sucesso; formato 1, 199 relações e 2.983 colunas |
| Origens terminais no JSON exportado | Nenhuma coluna sem origem terminal identificada |
| Receita líquida de P01 | Caminho de 15 nós e 14 ligações até colunas de `raw.order_items` e `raw_legacy.order_items` |

As contagens são sobre definições e artefatos locais, não sobre um inventário físico atualizado do
banco. A ausência de origem terminal vazia não equivale, por si só, à prova de correção semântica
de todas as transformações.

## 3. Achados e encaminhamentos

### G01 — Estado da fase GCP desatualizado na porta de entrada

**Tipo:** divergência documental confirmada.

**Evidência:** o [README](README.md), na tabela inicial e na seção de status, ainda diz que a fase
GCP não começou e aguarda autorização. A [pendência de abertura](docs/pendencias.md) registra a
autorização em 06/11/2026, e o [registro da fase GCP](docs/registro_fase_gcp.md) documenta
implementação e provas, incluindo atividades em 10/11/2026.

**Efeito:** o leitor recebe estados incompatíveis; um portal que consuma apenas o README poderá
exibir uma fase executada como ainda não iniciada.

**Encaminhamento sugerido:** atualizar o estado resumido no README com referência ao registro
responsável. Distinguir autorização, execução em andamento, prova de um componente e aceite do M6.
Não inferir conclusão da etapa a partir da existência de recursos ou de uma prova isolada.

### G02 — Resumos e versões do README misturam fotografias de entregas diferentes

**Tipo:** defasagem documental confirmada; não é evidência de falha dos testes.

**Evidência:** a tabela inicial do [README](README.md) apresenta 48 ADRs e números de qualidade
associados à entrega anterior, enquanto o próprio documento menciona 51 ADRs aceitos e descreve os
resultados posteriores da `v1.1.0`. O mapa aponta Arquitetura v2.5 e Governança v2.6; os cabeçalhos
consultados dos documentos responsáveis indicam v2.7 e v2.22, respectivamente.

**Efeito:** uma tela de indicadores não consegue assumir que os números do resumo pertencem à
mesma versão. Resultados históricos válidos podem ser interpretados como medição atual.

**Encaminhamento sugerido:** conferir as referências e explicitar a versão/data dos indicadores.
Preservar os relatos históricos de aceite; não substituí-los por medições novas nem reescrever ADRs
aceitos. Evitar manter contagens manualmente em várias partes do índice.

### G03 — O diagrama principal da arquitetura traz contagens dimensionais antigas

**Tipo:** divergência documental confirmada.

**Evidência:** a topologia da [Arquitetura §1](docs/arquitetura.md) rotula `analytics` como
“9 fatos + 17 dimensões”. O [Modelo de Dados §3](docs/modelo_de_dados.md) e o manifesto examinado
apresentam 10 fatos e 15 dimensões.

**Efeito:** o diagrama contradiz o inventário usado para navegar pelo datamart.

**Encaminhamento sugerido:** alinhar o diagrama ao modelo responsável; avaliar derivar o rótulo ou
retirar contagens do desenho, apontando para o inventário. Não criar outro inventário manual no portal.

### G04 — A política ainda apresenta como futura uma escolha de materialização de metadados já decidida

**Tipo:** defasagem documental confirmada.

**Evidência:** a [Governança §5.2](docs/governanca_de_dados.md) ainda apresenta a escolha entre pacote
do ecossistema e script próprio como algo a fazer na Etapa 13. A D80 nas
[Pendências](docs/pendencias.md), o [mapa de paridade](docs/arquitetura.md) e o
[Registro GCP §23](docs/registro_fase_gcp.md) já descrevem descrições via `persist_docs`, metadados
como labels por post-hook, linhagem por coluna capturada nativamente e travessias externas
publicadas pela API.

**Efeito:** a regra documental não acompanha a decisão e a implementação descritas pelos outros
artefatos. O leitor pode esperar um mecanismo de catálogo diferente do adotado.

**Encaminhamento sugerido:** conferir o restante da §5.2 contra as decisões da Etapa 13 e atualizar
o documento responsável, referenciando as evidências. Isso não exige escolher outra ferramenta nem
reabrir automaticamente a D80.

### G05 — O comentário do ambiente local descreve uma topologia Cloud SQL diferente do Terraform

**Tipo:** divergência entre explicação e infraestrutura declarada.

**Evidência:** o comentário inicial de [docker/docker-compose.yml](docker/docker-compose.yml)
justifica as instâncias separadas dizendo que cada banco terá uma instância Cloud SQL própria.
Em [terraform/cloud_sql.tf](terraform/cloud_sql.tf), o recurso `google_sql_database_instance.origens`
tem `count` de zero ou um, e os bancos de origem apontam para essa mesma instância. O cabeçalho
do Terraform explicita as duas origens no mesmo PostgreSQL gerenciado.

**Efeito:** confunde separação lógica de bancos com separação física de instâncias, justamente
uma das distinções necessárias à página local/GCP.

**Encaminhamento sugerido:** ajustar a explicação ao desenho decidido. Não alterar o Terraform
para satisfazer um comentário antigo. Esta revisão não consultou o inventário cloud atual.

### G06 — Há descrições ausentes em 141 colunas declaradas de camadas internas

**Tipo:** lacuna de completude explicativa; já representada pelos tetos de cobertura.

**Evidência:** contagem no manifesto local examinado, para modelos, snapshots e seeds:

| Camada | Colunas declaradas sem descrição |
|---|---:|
| `staging` | 5 |
| `trusted` | 125 |
| `quarantine` | 5 |
| `snapshots` | 6 |
| **Total** | **141** |

Esses valores coincidem com os tetos declarados em
[tests/test_descricao.py](tests/test_descricao.py). Não se trata de regressão nova demonstrada
por esta revisão. `analytics` e `consumption` estavam sem faltas no manifesto.

**Efeito:** é possível percorrer essas colunas, mas não explicar integralmente seu significado
a partir das descrições disponíveis. A completude física contra o banco não foi recontada agora.

**Encaminhamento sugerido:** priorizar descrições nos declarativos responsáveis, respeitando a
derivação por transporte e a revisão integral do declarativo. Se houver melhora medida da cobertura,
ajustar a catraca na mesma entrega. Enquanto houver faltas, exibi-las explicitamente no portal.

### G07 — A linhagem nativa GCP tem exceções por coluna e semântica diferente da origem de valor

**Tipo:** limitação já documentada; medição histórica, sem nova consulta à API nesta revisão.

**Evidência:** o [Registro GCP §23](docs/registro_fase_gcp.md) relata, em 07/11/2026, 4.399 de
4.982 arestas de valor encontradas na captura nativa. As ausências se concentram em
`trusted.legacy_presence_by_capture` e `analytics.fact_shipment_item`, com o motivo registrado
naquela seção. As travessias externas publicadas têm granularidade por tabela.

O módulo [models/lineage.py](src/mvp_ed1/models/lineage.py) descreve origens de valor. O módulo
[gcp/linhagem.py](src/mvp_ed1/gcp/linhagem.py) documenta que a captura nativa também pode trazer
dependências de junção e filtro. Essas relações não são automaticamente equivalentes.

**Efeito:** uma interface que use exclusivamente a captura cloud poderá omitir ligações por
coluna; uma união sem qualificação poderá atribuir a filtro/junção o significado de origem do valor.

**Encaminhamento sugerido:** preservar origem, granularidade, tipo e data da evidência. Exibir as
exceções e oferecer a linhagem local como referência identificada. Não inventar aresta por coluna
a partir de uma travessia por tabela, nem apresentar a medição de 07/11 como estado atual.

### G08 — A limitação de população da P13 permanece pendente na D66

**Tipo:** pendência conhecida de negócio/modelagem; não é achado novo desta revisão.

**Evidência:** a D66 nas [Pendências](docs/pendencias.md) registra que a view de entrega no prazo
não conta a remessa entregue cujos itens foram todos rejeitados. A descrição vigente da view
declara o recorte. O Owner adiou a decisão; as alternativas estão no documento responsável.

**Efeito:** navegar pelo SQL e encontrar linhagem completa não basta para concluir que a métrica
representa toda a população que o usuário pode supor pelo nome.

**Encaminhamento sugerido:** mostrar definição, população e referência à pendência junto da
pergunta de negócio. Qualquer mudança de grão, fato ou definição depende da decisão do Owner;
o portal não deve corrigir ou reinterpretar a métrica silenciosamente.

### G09 — Os artefatos locais disponíveis têm datas diferentes e não comprovam atualização integral

**Tipo:** limite da evidência disponível; a diferença de datas não demonstra, sozinha, conteúdo incorreto.

**Evidência:** os metadados de geração dos arquivos consultados indicam:

| Arquivo | Data de geração declarada |
|---|---|
| `dbt/target/catalog.json` | `2026-11-04T14:18:25.451356Z` |
| `dbt/target/manifest.json` | `2026-11-09T15:23:16.533989Z` |
| `dbt/target/run_results.json` | `2026-11-09T15:24:47.291748Z` |

O `run_results.json` registra 200 resultados `success` e 709 `pass`, de uma execução anterior.
A conferência `stale_nodes` tem os limites documentados em
[models/sensitivity.py](src/mvp_ed1/models/sensitivity.py) e na V1 das
[Pendências](docs/pendencias.md): não cobre, por exemplo, toda mudança em macro nova/apagada,
`dbt_project.yml` ou nó ausente do manifesto.

**Efeito:** juntar esses arquivos sem procedência pode misturar fotografias; uma conferência de
texto sem divergência não substitui um build recente nem prova equivalência com o banco atual.

**Encaminhamento sugerido:** identificar a execução e o commit dos insumos, validar a compatibilidade
do conjunto e explicitar sua atualização. Antes de publicar uma fotografia nova, executar as
validações apropriadas em trabalho autorizado separado e publicar seus resultados reais.

### G10 — A integração com um portal independente ainda precisa de um pacote completo e rastreável

**Tipo:** necessidade de integração do novo consumidor; não é defeito do escopo original do pipeline.

**Evidência:** [models/lineage.py](src/mvp_ed1/models/lineage.py) exporta, em formato público,
folhas imediatas e origens terminais por coluna. O payload de `to_json` não inclui sozinho as
descrições completas, perguntas, definições de acesso ou as travessias de `crossings`. Estas
últimas já alimentam a seção de linhagem do [Dicionário](docs/dicionario_de_dados.md).

Os insumos em `dbt/target/` ficam fora do Git, conforme [.gitignore](.gitignore). Um clone limpo
do portal não os recebe automaticamente.

**Efeito:** o exportador de linhagem é reutilizável, mas não é, isoladamente, todo o conteúdo
necessário para a compreensão da fonte às views e da infraestrutura dos dois ambientes.

**Encaminhamento sugerido:** definir no projeto `gdados` o contrato de composição e entrega dos
metadados, com identificadores estáveis, commit, ambiente, datas, limites de cobertura e política
de atualização. Consumir as fontes existentes, sem reimplementar a inferência da linhagem ou criar
outra documentação manual das mesmas regras. Ferramentas e mudanças na origem dependem do Owner.

## 4. Validações não executadas

Esta revisão não executou:

- `make check` ou nova suíte completa de testes;
- inventário físico de tabelas e colunas contra os bancos;
- nova medição de classificação, descrições ou permissões no banco;
- recálculo das métricas contra as origens;
- sincronizações Airbyte, DAGs, pipelines ou alterações de infraestrutura;
- consultas atuais ao inventário GCP ou à API de linhagem;
- prova exaustiva de correção semântica da linhagem;
- build, teste de navegador ou publicação da futura interface.

As evidências consultadas permitem avaliar a disponibilidade da base documental e técnica.
Não permitem declarar o estado operacional atual de todos os serviços, a atualização integral do
catálogo físico ou o fechamento de pendências de negócio.

## 5. Ordem de tratamento sugerida

1. Conciliar os documentos de entrada e as explicações de arquitetura com as decisões já tomadas
   (G01 a G05), sem reescrever ADRs aceitos.
2. Planejar o preenchimento das descrições faltantes nos declarativos responsáveis (G06).
3. Preservar os limites e a procedência das evidências de linhagem e métricas (G07 e G08).
4. Definir e validar o conjunto de artefatos que o portal consumirá (G09 e G10).
5. Realizar as verificações locais da interface e a avaliação pelo Owner antes da publicação.

A prioridade acima considera a compreensão e a fidelidade do portal. Não altera a situação formal
de aceite da fase local nem declara, por conta do agente, novos bloqueios de arquitetura ou ADR.

## 6. Fronteira desta entrega

Foi solicitado registrar os achados neste arquivo. Não foram alterados README, política,
arquitetura, modelos, tetos de cobertura, pendências ou infraestrutura. O plano e a base do portal
permanecem em `/home/doug/Projetos/gdados`; sua implementação aguarda avaliação do Owner.
