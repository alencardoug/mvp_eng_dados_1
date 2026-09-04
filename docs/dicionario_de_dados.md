# Dicionário de Dados e Catálogo

> **O que vive aqui:** o **registro** — os objetos que existem, o significado e a classificação de
> cada campo, e a linhagem entre camadas.
>
> **O que não vive aqui:** as **regras** de classificação, acesso e retenção (ver
> [Política de Governança de Dados](governanca_de_dados.md)); o inventário de tabelas e o seu
> propósito (ver [Modelo de Dados](modelo_de_dados.md)); os conceitos de negócio (ver
> [Glossário de Negócio](glossario_de_negocio/)).

| Campo | Informação |
|---|---|
| Fonte de verdade | Arquivos `.yml` do projeto dbt |
| Este documento | Índice navegável e registro do que ainda não está no dbt |
| Versão | 1.1 |
| Situação | **Vazio** — preenchido a partir da Etapa 3 |
| Última revisão | 04/09/2026 |

---

## 1. Como este catálogo é mantido

A descrição campo a campo **não é digitada aqui**. Ela vive nos arquivos `.yml` do dbt, junto do
modelo que descreve, conforme o [padrão de metadados](governanca_de_dados.md#51-padrão-de-metadados).
Manter a descrição ao lado do código é o que impede que catálogo e realidade divirjam.

Este documento cumpre três papéis que o dbt não cobre:

1. **Índice** dos objetos por camada, para leitura sem executar nada;
2. **Registro** da camada transacional, que não é modelada pelo dbt;
3. **Rastro de decisões** de classificação que precisam de justificativa em texto.

### 1.1 Regra de atualização

Toda etapa que cria ou altera um objeto de dados atualiza este catálogo **na mesma entrega**.
Objeto sem descrição ou campo sem classificação bloqueia a conclusão da etapa — é o mecanismo que
sustenta o princípio **P3** e trata o risco **R4**.

### 1.2 Como consultar o catálogo completo

```bash
make dbt-docs      # gera e serve o site com dicionário, linhagem e glossário integrados
```

---

## 2. Catálogo de objetos

*Nenhum objeto criado até o momento.* A primeira carga acontece na Etapa 3, com o schema `oltp`.

| Camada | Objeto | Tipo | Domínio | Descrição | Responsável |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

---

## 3. Dicionário de campos

*Vazio.* Formato adotado quando o preenchimento começar:

| Objeto | Campo | Tipo | Obrigatório | Classificação | Origem | Descrição |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

A coluna **Classificação** usa exclusivamente os níveis da
[política](governanca_de_dados.md#4-classificação-de-sensibilidade).

### 3.1 Campos técnicos padrão

Alguns campos aparecem em muitas tabelas por decisão de arquitetura, e são descritos **uma vez**
aqui em vez de repetidos em cada objeto:

| Campo | Onde aparece | Tipo | Classificação | Origem |
|---|---|---|---|---|
| `source_system` | Toda tabela que recebe mais de uma origem, de `raw` a `analytics` | Texto, domínio restrito | Interno | [ADR-0021](adr/0021-procedencia-no-empilhamento.md) |
| `deleted_at` | Toda tabela transacional mutável | `timestamptz`, nulo quando ativo | Interno | [ADR-0015](adr/0015-sincronizacao-e-exclusoes.md) |
| `valid_from` / `valid_to` | As sete dimensões SCD tipo 2 | `timestamptz` | Interno | [ADR-0017](adr/0017-chaves-substitutas-e-scd.md) |

---

## 4. Linhagem

*Vazia.* A linhagem detalhada é gerada pelo dbt; esta seção registra apenas as travessias que o dbt
não enxerga — a extração feita pelo Airbyte e o caminho de streaming.

| Origem | Destino | Mecanismo | Frequência | Observação |
|---|---|---|---|---|
| — | — | — | — | — |

---

## 5. Decisões de classificação

*Vazia.* Registra os casos em que a classificação de um campo não foi óbvia e precisou de
justificativa — por exemplo, um campo agregado derivado de dados sensíveis.

| Campo | Classificação | Justificativa | Data |
|---|---|---|---|
| — | — | — | — |
