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
| Versão | 2.0 |
| Catálogo de falhas | 21 tipos declarados ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md)) |
| Última revisão | 04/09/2026 |

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

Este catálogo é a **fonte da verdade** do tratamento do legado
([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md)). Dele saem três coisas geradas —
o injetor de falhas do gerador, as regras de limpeza e os testes — e é por isso que injetar e tratar
não podem divergir: são o mesmo arquivo.

Cada tipo tem **código estável**, usado como motivo de rejeição no schema `quarantine`. O código
nunca é reaproveitado.

**Numéricos e monetários**

| Código | Campo lógico | Valor legado | Tratamento |
|---|---|---|---|
| `NUM_TEXT_EQUIV` | `quantity` | `8`, `oito`, `8.0`, `8,0` | Converter: a equivalência é inequívoca |
| `NUM_AMBIGUOUS` | `quantity` | `8.5`, `oito caixas`, vazio | Rejeitar: não há regra determinística válida para o grão |
| `NUM_OUT_OF_RANGE` | `quantity` | Negativo onde não cabe, ou acima do limite físico | Rejeitar |
| `MONEY_LOCALE` | `amount` | `1.234,56`, `1234.56`, `R$ 1.234,56` | Normalizar *locale* e moeda antes da conversão decimal |
| `MONEY_NEGATIVE` | `amount` | Valor negativo em campo que não admite estorno | Rejeitar |

**Datas e tempo**

| Código | Campo lógico | Valor legado | Tratamento |
|---|---|---|---|
| `DATE_FORMAT_KNOWN` | `birth_date` | `21/03/1990`, `1990.03.21` | Interpretar pelo formato conhecido e normalizar para ISO |
| `DATE_IMPOSSIBLE` | `birth_date` | `13/13/2013`, `01/1800` | Rejeitar: data impossível, incompleta ou fora da regra de negócio |
| `DATE_FUTURE` | Datas de fato consumado | Nascimento ou pedido no futuro | Rejeitar |
| `DATE_TZ_MISSING` | *Timestamp* de evento | Sem fuso horário | Aplicar o fuso declarado da origem; rejeitar se a origem não o declara |

**Texto e codificação**

| Código | Campo lógico | Valor legado | Tratamento |
|---|---|---|---|
| `TEXT_ENCODING` | Qualquer texto | `JosÃ©`, `SÃ£o Paulo` | Reparar quando o par de codificações é conhecido; rejeitar se ambíguo |
| `TEXT_WHITESPACE_CASE` | Chaves e textos | Espaços à volta, caixa inconsistente | Padronizar |
| `TEXT_TRUNCATED` | Texto longo | Cortado no limite da coluna legada | Rejeitar: o que foi perdido não se restaura |
| `TEXT_DELIMITER` | Qualquer texto | Delimitador dentro do campo, deslocando as colunas | Rejeitar a **linha inteira** — as demais colunas também estão erradas |
| `NULL_DISGUISED` | Qualquer campo | `NULL`, `N/A`, `-`, `#N/D`, texto vazio | Converter para nulo real |

**Domínios, booleanos e formatos**

| Código | Campo lógico | Valor legado | Tratamento |
|---|---|---|---|
| `BOOL_VARIANT` | `boolean_value` | `sim`, `não`, `S`, `N`, `1`, `0` | Mapear somente valores previstos no dicionário de conversão |
| `ENUM_UNKNOWN` | Estado ou status | Valor fora do domínio conhecido | Rejeitar |
| `EMAIL_MALFORMED` | `email` | Sem `@`, com espaço, domínio inválido | Rejeitar |

**Integridade e consistência**

| Código | Campo lógico | Valor legado | Tratamento |
|---|---|---|---|
| `FK_ORPHAN` | Chave estrangeira | Referência a chave que não existe | Rejeitar |
| `DUP_EXACT` | Registro inteiro | Duplicata idêntica | Deduplicar, mantendo uma ocorrência |
| `DUP_PARTIAL` | Chave natural | Mesma chave, atributos divergentes | Rejeitar: não há critério de desempate seguro |
| `TOTAL_MISMATCH` | Total do pedido | Total ≠ soma dos itens | Rejeitar |

A separação entre **converter** e **rejeitar** é o problema central desta origem, e o critério é
único: converte-se quando existe **uma** interpretação possível; rejeita-se quando existe mais de
uma. `oito` → 8 converte; `oito caixas` não, porque o grão é desconhecido.

O piso de cobertura do [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) exige que
**todos os 21 tipos estejam representados em qualquer escala** — um tipo sem registro gerado é um
tratamento sem teste.

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

Somente `accepted` e `corrected` são empilhados aos dados principais na camada `trusted`. A colisão
entre origens é impedida por **`source_system` como coluna explícita**, com a chave substituta
derivada do *hash* de (`source_system`, chave natural) —
[ADR-0021](adr/0021-procedencia-no-empilhamento.md). A procedência permanece legível em todas as
camadas, o que torna "quantos registros vieram do legado?" uma cláusula `WHERE`.

A reconciliação é obrigatória e deve fechar exatamente:

```text
extracted_rows = accepted_rows + corrected_rows + rejected_rows
stacked_rows   = accepted_rows + corrected_rows
```

Reprocessar o mesmo `snapshot_id` não pode duplicar registros: o tratamento é idempotente.

**Exclusões.** Diferente da origem principal, que pratica *soft delete*, o legado **apaga
fisicamente** — é o comportamento verossímil de um sistema antigo. A ausência é detectada por
comparação contra o *snapshot* anterior, que é possível porque `raw_legacy` é imutável e retido
([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)). Registro que desaparece sem explicação é
divergência de reconciliação, nunca resultado.

---

## 7. Conceitos exercitados

Esta origem existe para praticar, com evidência verificável: *schema-on-read* contra
*schema-on-write*, tipagem defensiva, dicionário de conversões determinísticas, quarentena em vez
de descarte, procedência de dados, reconciliação de contagens e teste contra oráculo.
