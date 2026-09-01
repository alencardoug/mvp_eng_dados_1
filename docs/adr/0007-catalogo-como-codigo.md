# ADR-0007 — Manter o catálogo de dados como código

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | Ferramenta de catálogo da fase local |

## Contexto

O Termo de Abertura exige dicionário, catálogo, linhagem e classificação de sensibilidade desde o
início (**P3**). Com 40 tabelas na origem, mais o legado e 26 tabelas dimensionais, são centenas de
colunas a descrever e classificar.

A pergunta é onde esse conhecimento vive: em um sistema de catálogo ou no próprio repositório.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Catálogo como código** — `.yml` do dbt + glossário Markdown | Vive junto do modelo que descreve; revisável por *diff*; custo zero de infraestrutura; o `manifest.json` alimenta o Dataplex depois | Não tem interface de busca corporativa antes de `dbt docs generate` |
| Contêiner de catálogo local (OpenMetadata, DataHub) | Interface rica desde o início | Contêiner pesado — agrava o risco **R11**; metadados fora do versionamento; sem contrapartida direta no fluxo de migração |
| Planilha ou documento mantido à mão | Nenhum aprendizado inicial | Diverge do código na primeira semana; viola **P8** |

## Decisão

O catálogo é mantido **no repositório**, em dois pilares:

1. **Dicionário técnico** — arquivos `.yml` do dbt com descrição de cada modelo e coluna, testes e
   um bloco `meta:` de esquema estrito (`domain`, `owner`, `retention_days`, `sensitivity`,
   `data_type`).
2. **Glossário de negócio** — Markdown interligado em
   [`docs/glossario_de_negocio/`](../glossario_de_negocio/), importado pelos `.yml` por meio de
   blocos `{% docs %}`.

`dbt docs generate` consolida os dois em um site navegável onde linhagem técnica e conceito de
negócio aparecem juntos.

Na fase GCP, o `manifest.json` produzido pelo dbt alimenta o **Dataplex** e as descrições das
tabelas do BigQuery; o Terraform provisiona **policy tags**, aplicadas às colunas conforme o valor
de `sensitivity` — a classificação deixa de ser documental e passa a bloquear o acesso.

## Consequências

- **Positivas:** o preenchimento repetitivo de metadados pode ser gerado com apoio de IA a partir
  do DDL, cabendo ao Owner revisar; a governança fica versionada e revisável; o custo local
  permanece próximo de zero; a migração da governança consome os mesmos arquivos, sem redigitação.
- **Negativas:** o esquema do bloco `meta:` precisa ser respeitado com rigor — um campo mal
  preenchido vira uma *policy tag* errada na nuvem. Isso exige teste sobre os próprios metadados.
- **Paridade com o GCP:** total. Os mesmos arquivos descrevem as duas fases.
- **Documentos a atualizar:** [Política de Governança de Dados](../governanca_de_dados.md),
  [Dicionário de Dados](../dicionario_de_dados.md),
  [Glossário de Negócio](../glossario_de_negocio/).
