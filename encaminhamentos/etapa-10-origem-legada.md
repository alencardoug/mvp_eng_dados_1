# Etapa 10 — plano de execução da origem legada

> **Este arquivo é ordem de execução, não pedido de parecer.** O parecer está na seção 2 e foi
> conferido contra o repositório em 05/09/2026 — as lacunas ali são para resolver, não para
> redescobrir.
>
> **Estado em 05/09/2026:** implementação e medições ainda não executadas.
>
> **Pré-requisito de execução:** a [D31](d31-remessa-sem-item.md) entregue, com os dois caminhos
> do estoque reconstruídos e reconciliados. Depois disso, resolver as lacunas de tratamento e
> modelagem da seção 2 antes de implementar as partes dependentes.
>
> **Parecer:** viável com PostgreSQL, Airbyte, dbt e Airflow já adotados. O trabalho alcança o
> datamart existente: acrescentar somente um gerador e um `union all` não aplica o ADR-0021.
> Os contratos de captura e de classificação precisam ficar completos antes da implementação.

## 1. Leitura obrigatória e limites

A especificação de negócio permanece em [Origem Legada](../docs/origem_legada.md), a ser lida
integralmente. Este encaminhamento organiza a execução; não substitui o catálogo ou replica suas
21 regras. Leia também [Qualidade de Dados](../docs/qualidade_de_dados.md),
[Governança](../docs/governanca_de_dados.md), [Arquitetura](../docs/arquitetura.md) e a Etapa 10 do
[Plano de Desenvolvimento](../docs/plano_de_desenvolvimento.md).

| Decisão vigente | Aplicação nesta etapa |
|---|---|
| [ADR-0021](../docs/adr/0021-procedencia-no-empilhamento.md) | `source_system` explícito; chaves substitutas incluem origem e chave natural |
| [ADR-0022](../docs/adr/0022-catalogo-declarativo-de-falhas-do-legado.md) | Um catálogo YAML gera injeção, regras de tratamento e testes |
| [ADR-0015](../docs/adr/0015-sincronizacao-e-exclusoes.md) | Legado usa carga completa e exclusões físicas detectadas entre snapshots |
| [ADR-0008](../docs/adr/0008-schemas-do-armazem.md) | `raw_legacy` imutável e retido; fluxo unidirecional; quarentena é destino |
| [ADR-0017](../docs/adr/0017-chaves-substitutas-e-scd.md) | Hash determinístico e historização por `dbt snapshot` |
| [ADR-0031](../docs/adr/0031-aterrissagem-do-caminho-quente-em-raw.md) | CDC e lote reconciliam a mesma origem de estoque |
| [ADR-0023](../docs/adr/0023-escopo-do-schema-governance.md) | Controle e auditoria, sem transformar `governance` em fonte de negócio |

Reutilizar o pacote instalável: o caminho real proposto é **`src/mvp_ed1/legacy/`**. A referência
`src/legacy/` no plano permanente está desatualizada e deve ser corrigida na entrega de
implementação. `legacy_db` já é um dos três bancos do Compose; não é necessário acrescentar
outro serviço.

O corte inclui os 40 nomes de tabela do legado, a cobertura do catálogo e a chegada dos registros
aptos aos consumidores correspondentes. Não cria perguntas de negócio, dimensões aposentadas ou
um segundo domínio de streaming. Governança dos campos novos acompanha a entrega; a consolidação
integral de papéis e acessos continua na Etapa 11.

## 2. Pontos que o Codex deve avaliar antes de construir

### 2.1 Captura completa com retenção imutável

**Evidência:** [airbyte/main.tf](../airbyte/main.tf) traduz `full_refresh` como
`full_refresh_overwrite` e configura somente `oltp_para_raw`. Copiar esse arranjo para o legado
sobrescreveria o snapshot anterior exigido pelos ADRs 0008 e 0015.

**Proposta para avaliação:** conexão independente para o legado, extração completa com retenção
por captura, identificada antes da ingestão por `snapshot_id`, `snapshot_at` e `source_system`.
Validar no conector instalado o modo de retenção compatível; completar o desenho de publicação de
snapshot antes de aplicar Terraform. Não presumir que `full_refresh` sozinho garante imutabilidade.

O contrato precisa responder de forma concreta:

- como identificar cada ocorrência física, inclusive duas linhas de negócio idênticas;
- como manter a mesma identidade e o mesmo instante da captura em uma tentativa repetida;
- como distinguir tentativa incompleta de snapshot completo, inclusive tabelas legitimamente vazias;
- como publicar um conjunto consistente entre tabelas e impedir mudanças da origem durante a
  extração de teste;
- como tratar nova tentativa sem perder a anterior ou empilhar novamente a mesma captura;
- como reter dois snapshots distintos e detectar exclusão física sem confundir captura parcial
  com registro apagado.

Registrar o mecanismo escolhido e sua paridade GCP nos documentos responsáveis. Se houver mudança
de camada, materialização ou tratamento não coberta pelas decisões vigentes, levar a proposta ao
Owner conforme `CLAUDE.md` §5 antes de implementá-la.

### 2.2 Duplicata exata versus reconciliação de registros

**Lacuna do contrato:** `DUP_EXACT` manda manter uma ocorrência; ao mesmo tempo, as equações
vigentes exigem `extraídos = aceitos + corrigidos + rejeitados` e
`empilhados = aceitos + corrigidos`. Contar duas ocorrências como corrigidas e empilhar uma quebra
a segunda equação; simplesmente eliminar a segunda quebra a primeira.

**Proposta para decisão do Owner:** contar ocorrências extraídas, manter uma ocorrência canônica
determinística e preservar as excedentes em quarentena, com `DUP_EXACT` e vínculo à mantida.
Assim as três saídas continuam exclusivas e as equações podem fechar. Isso precisa ser aceito
como tratamento; não está implicitamente decidido pelo termo “deduplicar”.

Alternativa a apresentar: separar formalmente contagens físicas e lógicas, com reconciliação
própria para as duplicatas. Essa opção altera as equações documentadas e não deve ser adotada
silenciosamente. Duplicata de negócio e reentrega do Airbyte são fenômenos diferentes: preservar
a identidade da ocorrência permite distingui-los.

### 2.3 Regras detectáveis e dependências de rejeição

O catálogo declara a intenção, mas faltam parâmetros executáveis: faixas por campo, formatos,
fuso da origem, dicionários de equivalência e condições observáveis de falha. O Codex deve montar
uma matriz de cobertura, referenciando os 21 códigos, sem decidir casos ambíguos por conveniência.

Dois casos merecem demonstração antecipada: `TEXT_TRUNCATED` não é detectável apenas por atingir
o tamanho máximo de um texto, e um delimitador dentro de uma coluna PostgreSQL não desloca
automaticamente as demais colunas. A injeção precisa produzir evidência que a transformação
consiga reconhecer, sem consultar o manifesto ou um marcador que entregue a resposta.
Se isso exigir metadado adicional ou regra de negócio nova, apresentar o desenho ao Owner.

Definir também a precedência quando a mesma ocorrência tiver várias falhas: registrar todos os
achados, mas contar a ocorrência uma única vez. A proposta é rejeitar quando qualquer falha for
irrecuperável; em caso contrário, classificar como corrigida se houve conversão, ou aceita.

Referência existente no bruto pode apontar para pai rejeitado no tratamento. Propor e validar a
política de rejeição dependente antes do empilhamento, cobrindo pedido/itens, remessas, pagamentos
e estoque. Não usar membro desconhecido para esconder um `FK_ORPHAN` que o catálogo manda rejeitar.
O efeito sobre agregados e sobre a invariante 13 também precisa ser explícito.

### 2.4 Procedência no código atual

**Evidência:** os snapshots atuais usam chaves como `customer_id`; dimensões e fatos geram hashes
sem origem; há junções e partições somente por IDs locais. O ADR-0021 ainda precisa ser aplicado
ao conjunto dessas referências.

A inclusão de origem já está decidida. Inventariar a implementação faltante, sem reabrir o ADR:
colunas, chaves naturais/estrangeiras, hashes, `unique_key`, partições, agrupamentos e junções
temporais. Calendário, geografia e demais dimensões conformadas precisam ter sua identidade
respeitada; não prefixar indiscriminadamente tudo com origem.

Distinguir **sistema de origem** de **caminho de ingestão**: Airbyte e Beam transportam a mesma
origem principal. Legado não chega pelo CDC; o teste de dois caminhos não deve passar a exigir
streaming para ele.

### Como encaminhar as lacunas

Nesta entrega de planejamento, os pontos ficam aqui para avaliação, respeitando o limite dos
quatro arquivos. Na execução, conferir se já foram resolvidos na conversa ou no repositório.
Para os ainda abertos que dependam do Owner, apresentar evidência, alternativas, recomendação e
documentos afetados; formalizar pendência conforme `CLAUDE.md` §5 e atualizar os índices juntos.
Consultar a numeração real antes de atribuir `Dnn`; não reservar números neste plano.
Pausar as partes dependentes, mantendo o avanço das verificações independentes já autorizadas.

## 3. Plano de execução após a D31

Cada fase termina com uma evidência revisável. Os caminhos novos abaixo são **propostos**, não
arquivos ou comandos já implementados.

### Fase A — fixar a base e completar o contrato

1. Confirmar o encerramento da D31, sua revisão Git, parâmetros de geração e reconciliações.
   Preservar essa base; desenvolver o legado não requer regenerar a origem principal.
2. Inventariar as 40 tabelas: campos, restrições relaxadas, dependências, falhas aplicáveis,
   ingestão, destino após tratamento e teste/consumidor. Os 36 streams atuais não substituem esse
   inventário: `customer_contacts`, `customer_preferences`, `price_lists` e `product_prices` ainda
   não são ingeridas no caminho principal. Definir o tratamento e a reconciliação das 40 legadas
   sem acrescentar streams à origem principal apenas para igualar contagens de tabelas.
3. Resolver os pontos da seção 2. Declarar domínio de `source_system`, identidade de ocorrência,
   contrato de snapshot, precedência de regras e tratamento de exclusões/duplicatas.
4. Preparar o menor exemplo que atravesse as três saídas e uma relação pai/filho. Implementar
   primeiro esse exemplo pelas fases B a F até um consumidor existente, validando o contrato;
   depois expandir a mesma declaração e o mesmo fluxo às 40 tabelas.

**Saída:** declaração revisável e nenhum ponto ambíguo nas partes que serão implementadas.

### Fase B — catálogo, schema legado, gerador e manifesto

1. Criar o catálogo YAML único em `src/mvp_ed1/legacy/`, com os campos do ADR-0022, parâmetros
   por campo lógico e frequência/piso de injeção. Não embutir Python ou SQL arbitrário no YAML.
2. Derivar a estrutura legada dos modelos SQLAlchemy e de uma declaração explícita das
   flexibilizações; manter os modelos da origem principal intactos.
3. Implementar migrações dirigidas ao banco/schema legado. O
   [ambiente Alembic atual](../db/migrations/env.py) usa apenas `Base.metadata` e a conexão
   principal: ampliar a seleção de destino de modo que uma migração legada não altere `oltp`.
   Testar aplicação do zero e recusa de destino errado em ambiente isolado.
4. Gerar primeiro um conjunto consistente e depois injetar defeitos, com semente própria e
   parâmetros explícitos. Herdar o significado das tabelas e as invariantes aplicáveis, incluindo
   a 13; não copiar a D31 para o legado como falha não declarada.
5. Produzir manifesto por ocorrência com códigos esperados, resultado esperado e, quando
   aplicável, valores finais. Resultado esperado não pode ser calculado executando o limpador.
   Manter o manifesto fora das fontes, modelos e credenciais de leitura da transformação.
6. Construir o alvo proposto `make seed-legacy`, com recusa de sobrescrita por padrão,
   alternativa de geração em memória e proteção do destino. Manifestos e dados
   gerados ficam em área ignorada; declaração e código ficam versionados.

Os **100 registros falhos** são a distribuição planejada de Origem Legada §3, não um resultado
já obtido. Medir registros falhos, total de achados e cobertura dos 21 tipos separadamente.
Demonstrar determinismo e piso de cobertura com a escala reduzida.

### Fase C — ingerir e preservar snapshots

1. Ampliar [streams.yml](../airbyte/streams.yml) para representar origens distintas, mantendo-o
   como declaração única dos modos. Adaptar Terraform, variáveis e testes de coerência.
2. Configurar fonte e conexão legadas com destino `raw_legacy`, conforme o contrato da fase A.
   Validar nomes de schema, seleção de tabelas e metadados; não copiar a política destrutiva de
   `raw` para a área imutável.
3. Reutilizar o cliente [airbyte.py](../src/mvp_ed1/airbyte.py), que já recebe
   `--connection`; ampliar os alvos do Makefile e a DAG para escolher a conexão declarada.
   Não confundir o atual comando `status`, que resolve o identificador, com prova de carga concluída.
4. Demonstrar captura completa, falha parcial e retomada, nova captura e releitura de captura
   existente. Medir contagens e impressão digital do payload bruto por tabela/snapshot.
5. Garantir que os modelos só consumam capturas completas e identificadas. Preservar os valores
   recebidos, inclusive inválidos, e a distinção entre ocorrência e tentativa de transporte.

**Saída:** pelo menos duas capturas distintas retidas e uma retomada/reexecução comprovada, sem
sobrescrever a evidência original.

### Fase D — limpeza, classificação e quarentena

1. Gerar do catálogo as macros/modelos de tipagem defensiva, detecção e conversão para o dbt.
   Uma conversão inválida deve produzir diagnóstico por registro, sem abortar um cast do lote
   inteiro antes de registrar a rejeição.
2. Respeitar as camadas: padronização e tipagem em `staging`; regras de negócio e empilhamento
   em `trusted`; rejeitados em `quarantine`. Não criar schema “limpeza” nem dependência de
   `staging` para `trusted` por causa de dicionários de conversão.
3. Produzir uma classificação exclusiva por ocorrência e um registro de todos os achados.
   Correções preservam valor original, valor final e regra; rejeições preservam o registro,
   códigos e motivos. Aplicar a política aprovada de duplicatas e de dependências rejeitadas.
4. Confrontar o resultado com o manifesto apenas nos testes. Acrescentar controles independentes:
   casos válidos parecidos com falhas, formatos ambíguos, múltiplas falhas e pais rejeitados.
   Não derivar todas as expectativas pela mesma lógica que faz a conversão.
5. Verificar a impressão digital de `raw_legacy` antes/depois. Publicar relatório por tabela,
   coluna, tipo de erro e saída, distinguindo quantidade de registros de quantidade de achados.

**Saída:** os 21 tipos detectados/tratados conforme o contrato, com reconciliação exata e bruto
inalterado.

### Fase E — empilhar e propagar identidade até o consumo

1. Introduzir `source_system` também no caminho principal, desde sua fronteira de ingestão,
   com domínio declarado e teste. Preservar procedência em cada tabela que recebe múltiplas
   origens até `analytics`; não representar `batch` e `stream` como sistemas distintos.
2. Adaptar conjuntamente chaves, junções, agrupamentos, snapshots e hashes inventariados na fase A.
   Nas SCD tipo 2, manter a distinção de versão e o join no instante do evento.
3. Empilhar somente as ocorrências aptas da captura aplicável. Reter os snapshots brutos não
   significa somar todas as fotografias em `trusted`. Reprocessar uma captura antiga deve poder
   ser auditado sem duplicar o estado corrente ou desfazer uma exclusão posterior.
4. Aplicar a política de exclusão física aprovada e demonstrar duas capturas com remoção de um
   registro. Preservar evidência anterior e tratar o efeito nas referências e na história SCD.
5. Adaptar o incremental de estoque para identidade por origem e entrada histórica do legado:
   dados antigos não podem ficar fora da janela `atraso_maximo_dias`. Planejar reconstrução
   inicial e provar depois incremental equivalente à reconstrução completa.
6. Manter a reconciliação CDC/lote restrita ao sistema principal; validar estoque legado por suas
   próprias relações entre livro e projeção. Conferir origem em `movement_id`, correlações,
   versões de agregado e pares armazém/SKU para impedir colisões.
7. Testar explicitamente IDs iguais nas duas origens e valores diferentes. Nenhuma fato deve
   apontar para a dimensão da outra origem ou multiplicar receita por junção cruzada.
8. Executar as 16 views existentes com seus contratos. Comparar o resultado atribuível à origem
   principal com a base pós-D31 e reconciliar a contribuição do legado por origem em
   `trusted`/`analytics`. Alteração de contrato ou significado de métrica volta ao Owner.

A troca das chaves pode exigir reconstrução coordenada dos snapshots e da fato incremental no
ambiente de desenvolvimento. Preparar e registrar o alcance antes de executar; não transportar
a receita de descarte de histórico para uma rotina normal de carga legada.

### Fase F — orquestrar e validar o corte completo

Ampliar [fluxo_batch.py](../airflow/dags/fluxo_batch.py) com captura do legado, verificação de
conclusão e dependências explícitas de transformação e teste. Capturas independentes podem ser
executadas em paralelo; o empilhamento só começa com seus insumos completos.

As tarefas continuam por responsabilidade/camada, e **a camada `quarantine` já tem tarefa própria**
(`dbt_quarantine`, entre `dbt_trusted` e `dbt_snapshots`) desde a Etapa 8: modelo novo de quarentena
entra nela sozinho, sem tarefa nova. O que a DAG ainda não tem é captura e tratamento do legado.
Limpeza é responsabilidade das camadas existentes, não motivo automático para criar uma nova. Ordenar os testes que comparam aptos e
quarentena depois da construção de ambos, evitando que o primeiro build dependa de tabela que
ainda não existe. Falha de reconciliação impede publicação em `analytics`/`consumption`.

Na execução normal, a DAG captura uma origem já preparada; não chama geradores nem
`FORCE=1`/`RESET=1` automaticamente. Manter reexecução parcial e identificação do snapshot nas
tentativas. Medir uma DAG completa e uma reexecução da mesma captura, identificando os runs.

## 4. Critérios de aceitação e evidências

| Verificação | Evidência exigida |
|---|---|
| Schema/gerador | 40 tabelas representadas; migrações do zero; semente e parâmetros registrados |
| Cobertura | Todos os 21 tipos presentes; totais de registros e achados medidos separadamente |
| Oráculo independente | Classificação e valores confrontados com o manifesto; transformação sem acesso a ele |
| Reconciliação | Equações vigentes fecham por origem, tabela e snapshot, com o tratamento de duplicatas aprovado |
| Bruto imutável | Payload e contagens de cada snapshot preservados após limpeza, nova captura e reprocessamento |
| Correção/rejeição | Original, resultado e regra rastreáveis; rejeitados preservados; múltiplos motivos não multiplicam registros |
| Idempotência | Mesma captura reexecutada sem duplicar aptos, quarentena ou versões SCD; contagens e conteúdo conferidos |
| Exclusão física | Duas capturas completas distinguem remoção real de falha de ingestão e preservam histórico |
| Identidade | IDs iguais entre origens não colidem; relacionamentos e junções temporais conferidos |
| Regressão | D31 continua verde; estoque principal mantém reconciliação CDC/lote; incremental equivale ao completo |
| Ponta a ponta | dbt sem erros/avisos, suíte Python pertinente passando, 16 contratos válidos e DAG concluída |
| Governança | Campos novos classificados, incluindo payloads de auditoria; catálogo e linhagem gerados na mesma entrega |

Testes que escrevem usam ambiente isolado e destino explícito. Medição real de duração, tamanho,
quantidade de objetos e resultado só entra depois da execução; não projetar contagens de testes
ou tempos a partir das etapas anteriores.

## 5. Entrega documental e encerramento

Na implementação, atualizar uma vez no dono correto:

- [Origem Legada](../docs/origem_legada.md): contratos resolvidos, caminho real do gerador,
  captura, classificação e exclusões. Quando o YAML existir, a apresentação das regras deve ser
  gerada dele ou referenciá-lo, sem manter outro catálogo editável.
- [Qualidade de Dados](../docs/qualidade_de_dados.md): testes, reconciliações e evidências.
- Modelos/metadados, [Modelo de Dados](../docs/modelo_de_dados.md),
  [Dicionário](../docs/dicionario_de_dados.md) e [Governança](../docs/governanca_de_dados.md):
  campos, identidade, classificação e linhagem, regenerando os trechos derivados.
- [Execução Local](../docs/execucao_local.md): somente os comandos realmente implementados e
  testados, inclusive seleção de origem/snapshot e recuperação de tentativa incompleta.
- [Capacidade e Recuperação](../docs/capacidade_e_recuperacao.md): volumes, tamanhos e tempos
  medidos, distinguindo esta execução das históricas.
- [Plano](../docs/plano_de_desenvolvimento.md), [README](../README.md) e
  [Pendências](../docs/pendencias.md): conclusão com evidências e passagem à Etapa 11 somente
  quando todos os critérios estiverem satisfeitos.

ADRs aceitos não são reescritos. Decisões novas, se necessárias, recebem o procedimento próprio,
com atualização conjunta dos índices e verificação por
`python3 .claude/skills/adr/verificar.py`.

Organizar commits por assunto revisável, mantendo geração orientada ao declarativo. Só apagar
este encaminhamento e sua entrada no [índice](README.md) no commit que completar a entrega;
commits intermediários não encerram a Etapa 10.
