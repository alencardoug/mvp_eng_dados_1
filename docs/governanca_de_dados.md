# Política de Governança de Dados

> **O que vive aqui:** as **regras** sobre os dados — o que pode existir, como classificar, quem
> acessa o quê, por quanto tempo, como os segredos são tratados e como o catálogo é mantido como
> código.
>
> **O que não vive aqui:** o **registro** da aplicação dessas regras — campos, classificações e
> linhagem concretas (ver [Dicionário de Dados](dicionario_de_dados.md)); a estrutura das camadas
> (ver [Arquitetura](arquitetura.md)); os testes (ver [Qualidade de Dados](qualidade_de_dados.md)).

| Campo | Informação |
|---|---|
| Versão | 2.1 |
| Situação | Vigente para a fase local |
| Responsável | Líder de Governança |
| Última revisão | 03/09/2026 |

---

## 1. Propósito

Tornar o princípio **P3** operacional: catálogo, linhagem e classificação nascem junto com os
dados, não depois. A política vale para todo dado, metadado e artefato produzido no repositório,
nas duas fases.

---

## 2. Dados permitidos

- dados sintéticos gerados pelo próprio projeto — origem principal e origem legada;
- metadados, dicionário e catálogo;
- estatísticas agregadas do pipeline.

## 3. Dados não permitidos

- dados pessoais reais, de qualquer natureza ou origem;
- extrações de sistemas corporativos;
- *datasets* privados sem autorização;
- credenciais, tokens e segredos.

A proibição vale inclusive para exemplos em documentação, mensagens de *commit*, capturas de tela e
*issues*. Um dado sintético que reproduza um registro real deixa de ser sintético.

---

## 4. Classificação de sensibilidade

Todo campo de todas as camadas recebe exatamente um nível. Campo sem classificação bloqueia a
conclusão da etapa que o criou.

Os níveis estão fixados em [ADR-0011](adr/0011-classificacao-e-papeis-de-acesso.md). O vocabulário
é inglês, por ser identificador técnico: cada valor vira nome de *policy tag* no BigQuery.

| Valor de `sensitivity` | Definição | Exemplos no projeto | Regra |
|---|---|---|---|
| `public` | Pode ser exposto sem restrição | Catálogo, contagens agregadas, `product_categories` | Livre |
| `internal` | Operacional, sem valor sensível | Chaves técnicas, `recorded_at`, identificadores de lote | Livre no repositório |
| `confidential` | Não pessoal, mas de valor comercial | `unit_cost`, condições de fornecedor, margem | Fora das views de consumo abertas ao perfil de análise |
| `personal` | Campo que, se fosse real, seria dado pessoal | Nome, e-mail, telefone, endereço, documento — sempre sintéticos | Nunca exibido em exemplos; mascarado nas views de consumo quando não for necessário |

O nível `personal` é aplicado mesmo aos dados sintéticos: o objetivo é exercitar o controle real,
não presumir que dado simulado dispensa governança. É essa classificação que, na fase GCP, vira
*policy tag* e passa a **bloquear** o acesso.

**A proibição de dados reais não é um nível.** Ela vive exclusivamente na
[seção 3](#3-dados-não-permitidos) — repeti-la aqui criaria dois donos para a mesma regra (**P8**),
e nenhum campo do projeto poderia recebê-la.

---

## 5. Catálogo como código

O catálogo não é um sistema à parte: **o repositório é a fonte de verdade**. A alternativa —
subir um contêiner pesado de catálogo no ambiente local — foi rejeitada por custo de memória e por
não ter contrapartida direta no GCP ([ADR-0007](adr/0007-catalogo-como-codigo.md)).

A estrutura tem dois pilares:

| Pilar | Formato | Conteúdo |
|---|---|---|
| **Dicionário técnico** | Arquivos `.yml` do dbt | Descrição de cada modelo e coluna, testes e bloco `meta:` |
| **Glossário de negócio** | Markdown em [`glossario_de_negocio/`](glossario_de_negocio/) | Conceitos do varejo *omnichannel*, interligados entre si |

O dbt importa o glossário nos `.yml` por meio de blocos `{% docs %}`, e `dbt docs generate`
consolida tudo em um site navegável onde **linhagem técnica e conceito de negócio aparecem juntos**.

### 5.1 Padrão de metadados

O bloco `meta:` é a ponte para a nuvem — e por isso é estrito. As chaves são fixas e ficam em
inglês, por serem identificadores técnicos; o conteúdo descritivo fica em português.

```yaml
models:
  - name: dim_customer
    description: '{{ doc("active_customer") }}'
    meta:
      domain: "vendas"
      owner: "data_custodian"
      retention_days: 365
    columns:
      - name: customer_document
        description: "Documento de identificação do cliente (sintético)."
        meta:
          sensitivity: "personal"
          data_type: "pii"
```

Chaves obrigatórias: `domain` e `owner` no modelo; `sensitivity` em toda coluna. `retention_days` e
`data_type` conforme aplicável.

### 5.2 Materialização da governança na fase GCP

O trabalho já está codificado; a migração consome os mesmos arquivos:

1. **Descrições e metadados** — o `manifest.json` gerado pelo dbt é lido, o que atualiza as
   descrições das tabelas no BigQuery e popula o **Dataplex** com o conteúdo do bloco `meta:`. O
   caminho pode ser um pacote de código aberto do ecossistema dbt (por exemplo,
   `dbt-google-data-catalog`) ou um script próprio chamando a API do GCP — a escolha é feita na
   Etapa 13, com a avaliação do pacote antes de escrever código.
2. **Políticas de acesso** — o Terraform provisiona *policy tags* no BigQuery; a coluna marcada
   como `sensitivity: "personal"` recebe automaticamente a *tag* correspondente, e apenas
   identidades autorizadas pelo IAM conseguem executar `SELECT` sobre ela.

A classificação deixa de ser documental e passa a ser **controle efetivo**, sem que nenhuma
descrição precise ser reescrita.

---

## 6. Controles obrigatórios

| Controle | O que exige | Onde é registrado |
|---|---|---|
| Classificação por campo | Todo campo tem um nível da seção 4 | `.yml` do dbt e [Dicionário de Dados](dicionario_de_dados.md) |
| Linhagem origem → consumo | Toda coluna analítica aponta para a sua origem | Linhagem do dbt |
| Procedência entre origens | Registro empilhado identifica se veio da origem principal ou da legada | [Origem Legada](origem_legada.md) |
| Regras de acesso por camada | Cada camada tem papéis de leitura e escrita | Seção 7 |
| Retenção | Todo objeto tem prazo e critério de descarte | Seção 8 e `meta.retention_days` |
| Segredos fora do repositório | Credenciais só em `.env` local; `.env.example` versionado sem valores | `.gitignore` + revisão de cada entrega |

---

## 7. Regras de acesso por camada

Os papéis estão fixados em [ADR-0011](adr/0011-classificacao-e-papeis-de-acesso.md). Na fase local
são *roles* do PostgreSQL; na fase GCP, contas de serviço e grupos IAM por dataset.

| Papel | Escreve | Lê | Equivalente na fase GCP |
|---|---|---|---|
| `ingestor` | `raw`, `raw_legacy` | as próprias | Conta de serviço do Airbyte |
| `transformer` | `staging`, `trusted`, `analytics`, `quarantine` | camadas anteriores | Conta de serviço do dbt |
| `streamer` | `analytics` | — | Conta de serviço do Dataflow |
| `analyst` | — | `consumption` apenas | Grupo IAM no dataset das views |
| `auditor` | — | `quarantine` | Grupo IAM de auditoria |

Nenhum consumidor de análise recebe acesso direto a `raw`, `raw_legacy`, `staging`, `trusted` ou
`analytics`. O contrato de consumo é a view, e o schema `consumption`
([ADR-0008](adr/0008-schemas-do-armazem.md)) torna a regra testável por asserção de falha: um
`SELECT` de `analyst` contra `raw` **precisa** falhar.

---

## 8. Retenção

| Objeto | Retenção | Critério de descarte |
|---|---|---|
| Dados sintéticos gerados localmente | Enquanto o ambiente existir | Recriáveis pela `seed`; descartáveis a qualquer momento |
| Lotes em `raw` | Os necessários à reconciliação | Definido na Etapa 5 do [plano](plano_de_desenvolvimento.md) |
| `raw_legacy` | Permanente enquanto o *snapshot* for o vigente | Substituído apenas por novo *snapshot* aprovado |
| `quarantine` | Permanente | Nunca descartado sem decisão registrada — é evidência de auditoria |
| `staging`, `trusted`, `analytics` | Reconstruíveis | Descartáveis; nunca são fonte de verdade |
| Catálogo, dicionário e linhagem | Permanente | Versionados no Git |

Como todo dado é sintético e reconstruível, a retenção neste MVP é **exercício de disciplina**, não
obrigação legal. A estrutura, porém, é a mesma que se aplicaria a dados reais.

---

## 9. Tratamento de segredos

- segredos apenas em `.env` local, nunca versionados;
- `.env.example` versionado com as chaves e **sem** valores;
- toda entrega passa por revisão de `.gitignore` e de segredos;
- um segredo exposto por engano é considerado comprometido: deve ser rotacionado, não apenas
  removido do histórico.

---

## 10. Revisão desta política

Alterações aqui são **mudanças relevantes**: exigem decisão explícita do Owner e ADR, conforme o
[Termo de Abertura](../Abertura_de_projeto.md).
