# Origem Legada

> **O que vive aqui:** a segunda origem do projeto — um banco antigo, deliberadamente
> desorganizado, e todo o ciclo de tratamento dos seus dados: geração, *snapshot* imutável,
> limpeza, quarentena e empilhamento controlado.
>
> **O que não vive aqui:** a estrutura lógica das tabelas, idêntica à da origem principal (ver
> [Modelo de Dados](modelo_de_dados.md)); os testes de reconciliação (ver
> [Qualidade de Dados](qualidade_de_dados.md)).

| Campo | Informação |
|---|---|
| Banco | `legacy_db`, schema `legacy` |
| Gerador | `generate_legacy_database.py` (proposto) |
| Versão | 1.0 |
| Última revisão | 01/09/2026 |

---

## 1. Por que existe

Um pipeline que só recebe dados limpos não demonstra engenharia de dados — demonstra sorte. A
origem legada existe para exercitar a parte do trabalho que aparece em todo projeto real:
interpretar dados sujos, decidir o que é corrigível, rejeitar o que não é e **provar** que nada foi
inventado nem perdido no caminho.

---

## 2. Estrutura

O `legacy_db` reproduz os mesmos 40 nomes de tabela e o mesmo significado de campos do `source_db`,
mas representa uma origem antiga sem governança adequada:

- estrutura **logicamente idêntica**, não uma cópia literal do DDL normalizado;
- colunas que precisam aceitar valores incompatíveis são declaradas como `text`;
- *constraints*, chaves estrangeiras e validações são seletivamente relaxadas.

A tipagem frouxa é necessária: uma coluna PostgreSQL tipada como número ou data rejeitaria os
exemplos defeituosos antes da engenharia de limpeza — que é exatamente o que se quer exercitar.

---

## 3. Falhas intencionais

O legado tem um pequeno conjunto consistente que fornece contexto referencial e **cerca de 100
registros portadores de falhas intencionais**:

| Domínio | Registros falhos |
|---|---:|
| Clientes e endereços | 15 |
| Catálogo e preços | 12 |
| Fornecedores e compras | 12 |
| Vendas | 20 |
| Pagamentos | 12 |
| Estoque | 10 |
| Logística | 10 |
| Marketing | 4 |
| Atendimento | 5 |
| **Total** | **100** |

Uma linha pode conter mais de uma falha — a quantidade de **erros detectados** pode ser maior que a
quantidade de **registros falhos**.

### 3.1 Catálogo de falhas obrigatórias

| Campo lógico | Valores legados | Tratamento esperado |
|---|---|---|
| `quantity` | `8`, `oito`, `8.0`, `8,0` | Converter para inteiro quando a equivalência for inequívoca. |
| `quantity` | `8.5`, `oito caixas`, vazio | Rejeitar: não há regra determinística válida para o grão. |
| `birth_date` | `21/03/1990`, `1990.03.21` | Interpretar pelo formato conhecido e normalizar para ISO. |
| `birth_date` | `13/13/2013`, `01/1800` | Rejeitar: data impossível, incompleta ou fora da regra de negócio. |
| `amount` | `1.234,56`, `1234.56`, `R$ 1.234,56` | Normalizar *locale* e moeda antes da conversão decimal. |
| `boolean_value` | `sim`, `não`, `S`, `N`, `1`, `0` | Mapear somente valores previstos no dicionário de conversão. |
| Chaves e textos | Espaços, caixa inconsistente, duplicatas, referências órfãs | Padronizar quando seguro; rejeitar duplicidade ou órfão sem resolução inequívoca. |

Outras falhas cobrem e-mails malformados, estados desconhecidos, valores monetários
inconsistentes, quantidades negativas, datas futuras indevidas, totais que não reconciliam e
codificações textuais divergentes.

### 3.2 Manifesto de falhas

A geração é determinística, recebe `seed` própria e produz um **manifesto** declarando o erro
esperado em cada registro.

O manifesto é o **oráculo dos testes**. A transformação nunca o consulta para descobrir a resposta
— se consultasse, o teste passaria a medir a si mesmo.

---

## 4. Snapshot imutável

O Airbyte realiza uma carga `full refresh` identificada por `snapshot_id`, `snapshot_at` e
`source_system`. O conteúdo original permanece **imutável** em `raw_legacy`, preservando
exatamente o valor recebido antes de qualquer limpeza.

Diferente do [ponto de recuperação](capacidade_e_recuperacao.md#3-ponto-único-de-recuperação), cuja
finalidade é restaurar o ambiente, este *snapshot* existe para **linhagem, auditoria e
reprocessamento** da limpeza.

---

## 5. Limpeza e classificação

O dbt classifica cada registro legado em exatamente uma saída:

| Saída | Significado | Destino |
|---|---|---|
| `accepted` | Válido, sem necessidade de correção | Empilhado em `trusted` |
| `corrected` | Corrigido por regra determinística, com valor original, valor final e regra aplicada registrados | Empilhado em `trusted` |
| `rejected` | Não consertável com segurança | Schema `quarantine`, com código e descrição do motivo |

Regras invioláveis:

- o tratamento **não adivinha** valores;
- o tratamento **não corrige em silêncio** — toda correção registra origem, resultado e regra;
- o tratamento **não altera** `raw_legacy`;
- registros `rejected` **não são descartados**: permanecem em quarentena para auditoria;
- o empilhamento é **bloqueado** quando a regra de correção for ambígua.

---

## 6. Empilhamento e reconciliação

Somente `accepted` e `corrected` são empilhados aos dados principais na camada `trusted`, usando
uma chave de procedência que impede colisão entre origens (decisão pendente **D15**).

A reconciliação é obrigatória e deve fechar exatamente:

```text
extracted_rows = accepted_rows + corrected_rows + rejected_rows
stacked_rows   = accepted_rows + corrected_rows
```

Reprocessar o mesmo `snapshot_id` não pode duplicar registros: o tratamento é idempotente.

---

## 7. Conceitos exercitados

Esta origem existe para praticar, com evidência verificável: *schema-on-read* contra
*schema-on-write*, tipagem defensiva, dicionário de conversões determinísticas, quarentena em vez
de descarte, procedência de dados, reconciliação de contagens e teste contra oráculo.
