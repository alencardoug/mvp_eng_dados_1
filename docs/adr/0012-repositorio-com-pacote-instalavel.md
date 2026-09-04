# ADR-0012 — Organizar o repositório com `src/` como pacote instalável

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D10 |

## Contexto

A [Arquitetura](../arquitetura.md#7-organização-do-repositório) propôs uma árvore de diretórios
marcada como "a confirmar em **D10**". Nenhum arquivo da Etapa 2 pode ser criado antes disso.

A pergunta que parece estar em jogo — onde ficam os diretórios — não é a que importa. A que importa
é **como o código Python é encontrado por quem o executa**, e são três executores com raízes
diferentes: o Airflow carrega DAGs de um diretório próprio dentro do contêiner, o `pytest` roda a
partir da raiz do repositório, e o gerador roda por linha de comando. Um mesmo módulo precisa ser
importável nos três.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Árvore da Arquitetura §7 + `src/` instalável** | Cada ferramenta permanece visível na raiz, que é como um leitor entende a arquitetura; `pip install -e .` dá um caminho de importação único aos três executores; dependências e versão passam a ter um arquivo declarado | Um `pyproject.toml` a manter e um passo de instalação no ambiente, desde a Etapa 2 |
| Mesma árvore, `src/` como diretório comum | Zero cerimônia de empacotamento no início | Airflow e `pytest` precisam achar o módulo, e a solução vira `PYTHONPATH` espalhado pelo `docker-compose` e pelo Dockerfile: configuração duplicada em lugares que divergem sem avisar |
| Tudo dentro do pacote (`src/mvp_ed1/` absorve `dbt/` e `airflow/`) | O layout mais pythônico e o melhor para distribuir | Esconde `dbt/` e `airflow/` três níveis abaixo. O repositório é público e didático: a arquitetura precisa ser legível na raiz, não descoberta por navegação |
| Monorepo por domínio (`vendas/`, `estoque/`) | Escala bem quando há times separados por domínio | Fragmenta o projeto dbt, que é um só, e multiplica arquivos de configuração num projeto de autor único |

## Decisão

A árvore da [Arquitetura §7](../arquitetura.md#7-organização-do-repositório) é confirmada, e
**`src/` passa a ser um pacote Python instalável**, declarado em `pyproject.toml` na raiz e
instalado em modo editável (`pip install -e .`).

Os três subpacotes previstos — `generator`, `legacy` e `streaming` — passam a ser importáveis por
caminho absoluto a partir do nome do pacote, e nenhum executor depende de `PYTHONPATH`.

## Consequências

- **Positivas:** um único caminho de importação para gerador, origem legada, produtor de streaming,
  DAGs e testes; dependências e versão declaradas em um arquivo em vez de espalhadas; a imagem
  Docker instala o pacote em vez de copiar caminhos, o que elimina a classe de erro "funciona na
  minha máquina e não no contêiner".
- **Negativas:** `pip install -e .` vira pré-requisito do ambiente local e passo do Dockerfile; há
  um arquivo de empacotamento a manter desde a Etapa 2, antes de existir código que o justifique.
- **Paridade com o GCP:** o mesmo pacote é instalado na imagem que o Cloud Composer executa e é
  empacotado para o Dataflow — que **exige** que o código do pipeline seja distribuível. A escolha
  antecipa uma exigência da nuvem em vez de criar trabalho novo na Etapa 13.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §7;
  [Execução Local](../execucao_local.md) (pré-requisitos e comandos).
