# ADR-0026 — Adotar `uv` para o ambiente e as dependências Python

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada e fechada na Etapa 2) |

## Contexto

O [ADR-0012](0012-repositorio-com-pacote-instalavel.md) fixou `src/` como pacote instalável, mas
não disse **com que ferramenta** o ambiente é criado nem **como as versões são travadas**. A Etapa 2
tem "ambiente Python com versões fixadas" como critério de conclusão, então a lacuna bloqueia.

Há também um fato concreto da máquina: o Python de sistema é a **3.10**, cujo fim de suporte é
**outubro de 2026** — o mês corrente. A versão precisa ser escolhida e instalada deliberadamente,
não herdada do sistema operacional. Isso torna a escolha do interpretador parte da mesma decisão:
a ferramenta que gerencia dependências ou instala o interpretador, ou exige uma segunda ao lado.

## Alternativas consideradas

### Gerenciador

| Alternativa | A favor | Contra |
|---|---|---|
| **`uv`** | Uma ferramenta resolve, trava (`uv.lock`) e **instala o próprio interpretador** — o problema da versão do Python desaparece junto; `uv export` produz o `requirements.txt` com *hashes* que o Dataflow exige em `--requirements_file` e que o Composer consome, de modo que a trava local atravessa para a nuvem sem tradução | Ferramenta jovem: menos anos de estrada que o Poetry, e quem não a tiver instalada não reproduz o ambiente sem exportar antes |
| Poetry | Padrão corporativo consolidado há anos, com *lock* e `pyproject` nativos | Não gerencia o interpretador — exigiria `pyenv` ao lado, virando duas ferramentas para um problema; resolução lenta; e exportar para o formato que o Dataflow aceita depende de plugin |
| `pip` + `venv` + `pip-tools` | Nada além do que vem com o Python; `requirements.txt` com *hashes* é aceito nativamente pela nuvem, sem exportação | Não gerencia o interpretador; dois arquivos a manter em sincronia (`.in` e `.txt`); e o `pyproject.toml` fica apenas para empacotar, deixando a declaração de dependência fora dele |

### Versão do interpretador

| Alternativa | A favor | Contra |
|---|---|---|
| **3.11** | É a versão que o **Cloud Composer 2 executa** — paridade direta com o orquestrador escolhido no [ADR-0024](0024-airbyte-e-airflow-no-gcp.md) (**P4**); suportada por Beam, dbt e Airflow sem ressalva; fim de suporte em outubro de 2027 | Precisa ser instalada; não é a mais recente |
| 3.12 | Dois anos a mais de folga; suportada pelas versões atuais de Beam, dbt e Airflow | As imagens do Composer vão atrás, então a paridade com a nuvem fica um passo mais frouxa — e paridade é justamente o **P4** |
| 3.10, a do sistema | Já instalada; zero configuração | Fim de suporte **neste mês**. Iniciar o projeto sobre um interpretador que para de receber correção de segurança em semanas é indefensável sob **P10** |

## Decisão

**`uv` gerencia o ambiente, as dependências e o interpretador.** O projeto fixa **Python 3.11**, com
`requires-python = ">=3.11,<3.12"` — série fechada, não `>=3.11`.

A restrição é estrita de propósito: permitir 3.12 tornaria o ambiente local diferente do da nuvem
sem que ninguém percebesse, e a divergência apareceria só na Etapa 13.

| Artefato | Papel |
|---|---|
| `pyproject.toml` | Declara o pacote, a faixa de interpretador e as dependências |
| `uv.lock` | **Versionado.** É a trava: garante versões idênticas entre máquinas |
| `.python-version` | Declara `3.11` para o `uv` selecionar o interpretador sem pergunta |

O *backend* de construção é o `hatchling`, padrão do `uv` — sub-escolha desta decisão, sem efeito
sobre a arquitetura.

## Consequências

- **Positivas:** um comando (`make install`) cria o ambiente completo, interpretador incluído, em
  máquina limpa; a trava é um arquivo único e versionado; e a resolução é rápida o bastante para
  que atualizar dependência deixe de ser evento.
- **Negativas:** o projeto passa a depender de uma ferramenta externa ao Python padrão, e quem não
  tiver `uv` precisa exportar para `requirements.txt` antes de reproduzir. Além disso, a fixação
  estrita em 3.11 obrigará **um ADR novo** quando o Composer mudar de versão — o que é intencional:
  a mudança de interpretador deve ser deliberada, não silenciosa.
- **Paridade com o GCP:** `uv export --format requirements-txt` produz o arquivo com *hashes* que o
  Dataflow recebe em `--requirements_file` e que o Composer instala no ambiente. O interpretador
  3.11 é o do Composer 2. A trava local e a da nuvem passam a ser o mesmo conjunto de versões.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §3 e §7;
  [Execução Local](../execucao_local.md) §1.
