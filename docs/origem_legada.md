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
| Gerador | `src/mvp_ed1/legacy/` — catálogo, schema, injetor e carga |
| Versão | 2.2 |
| Catálogo de falhas | 22 tipos declarados ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md) e [ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)) |
| Última revisão | 05/09/2026 |

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

**As colunas de texto do legado são mais estreitas que as de hoje.** É daí que o truncamento vem: um
`varchar(24)` recebendo um endereço de quarenta caracteres perde o fim dele, e o que sobra é o
começo. A largura é declarada uma vez no catálogo, e vale como teto — a coluna antiga nunca é mais
larga que a atual.

---

## 3. Falhas intencionais

O legado tem um pequeno conjunto consistente que fornece contexto referencial e **cerca de 100
registros portadores de falhas intencionais**. O gerador **não** produz esse conjunto do zero: parte
do mesmo motor da origem principal, com semente e fator próprios, e o **degrada**. Reescrever a
geração daria uma segunda definição do domínio, que divergiria da primeira no dia seguinte.

A distribuição por domínio abaixo é a **planejada**. A realizada é consequência de onde os
arquétipos do catálogo alcançam colunas, e é medida — não declarada:

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
| `TEXT_TRUNCATED` | Texto longo | Cortado na largura da coluna **antiga**, mais estreita que a atual | Rejeitar: o que foi perdido não se restaura |
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
| `PARENT_REJECTED` | Registro filho | Íntegro, mas o pai foi rejeitado | Rejeitar em cascata, com vínculo ao pai |

A separação entre **converter** e **rejeitar** é o problema central desta origem, e o critério é
único: converte-se quando existe **uma** interpretação possível; rejeita-se quando existe mais de
uma. `oito` → 8 converte; `oito caixas` não, porque o grão é desconhecido.

**`PARENT_REJECTED` é o único código que não descreve defeito do próprio registro**
([ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)). Ele existe porque o item
íntegro de um pedido que não fecha não pode ser empilhado — produziria receita sem pedido — nem
descartado em silêncio. É derivado: depende do resultado de outro registro, e por isso os pais são
classificados antes dos filhos.

### 3.1.1 A ordem do catálogo é a precedência de detecção

Uma coluna casa com mais de uma falha, e vale a **primeira**. O catálogo é
ordenado por **especificidade** — do caso exato para o amplo —, e desrespeitar
essa ordem produz erro silencioso, não falha. Três exemplos, todos medidos:

| O valor | Casa com | Se a ordem estiver errada |
|---|---|---|
| `31/02/2024` | `DATE_FORMAT_KNOWN` e `DATE_IMPOSSIBLE` | A data que não existe é **convertida** para 02/03, em vez de rejeitada |
| `   ` | `TEXT_WHITESPACE_CASE` e `NULL_DISGUISED` | Um nulo disfarçado vira string vazia, em vez de nulo |
| `sem@arroba` | as regras de texto e `EMAIL_MALFORMED` | Um e-mail inválido é aceito depois de "limpo" |

### 3.1.2 Onde cada falha se aplica, e por quê nem toda coluna

Três listas no catálogo restringem onde uma falha faz sentido. Elas não são
otimização: sem elas, o tratamento rejeitava **1.508 registros perfeitos** —
12% da captura —, e a reconciliação deixava de informar qualquer coisa.

| Lista | Por que existe |
|---|---|
| `promessas` | `carts.expires_at` é uma data futura por natureza; `DATE_FUTURE` ali condenaria 127 carrinhos corretos |
| `quantidades_com_sinal` | `quantity_delta` é assinado — saída de estoque é negativa —, e o sinal ali não é defeito. Eram 388 movimentos |
| `colunas_estreitadas` | O sistema antigo apertou **alguns** campos livres, não todos. `currency` sempre teve três caracteres, e truncá-la produzia 987 rejeições de valores certos |

Depois das três listas, o falso positivo residual é **13 em 12.749 linhas
(0,10%)**, e é quase todo `TEXT_TRUNCATED` — a heurística declarada, com o seu
custo medido em vez de escondido.

### 3.1.3 Precedência quando a mesma ocorrência tem várias falhas

Uma linha pode carregar mais de um defeito, e **todos os achados são registrados**. O que não se
multiplica é a ocorrência: ela é contada uma vez, e classificada uma vez, pela regra:

1. qualquer falha irrecuperável → `rejected`;
2. senão, houve conversão → `corrected`;
3. senão → `accepted`.

O piso de cobertura do [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) exige que
**todos os 22 tipos estejam representados em qualquer escala** — um tipo sem registro gerado é um
tratamento sem teste. `PARENT_REJECTED` só aparece quando existe pai rejeitado com filho íntegro, e
a geração garante esse caso de propósito.

### 3.2 Manifesto de falhas

A geração é determinística, recebe `seed` própria — declarada em
[`catalogo.yml`](../src/mvp_ed1/legacy/catalogo.yml), distinta da origem principal — e produz um
**manifesto** declarando o erro esperado em cada registro.

O manifesto é escrito em `data/legacy/manifesto.json`, **fora do banco e fora do Git**. Guardá-lo ao
lado do dado tratado convidaria a transformação a consultá-lo, e o teste passaria a medir a si
mesmo. Cada linha dele diz a ocorrência física, o código, a coluna, o valor antes, o valor depois e
o resultado que o tratamento deve alcançar.

O manifesto é o **oráculo dos testes**. A transformação nunca o consulta para descobrir a resposta
— se consultasse, o teste passaria a medir a si mesmo.

---

## 4. Snapshot imutável

O Airbyte realiza uma carga completa **por acréscimo** — `full_refresh_append`, o quarto modo de
sincronização, criado para este caso pelo
[ADR-0037](adr/0037-reter-capturas-do-legado-por-acrescimo.md). Cada captura é identificada por
`snapshot_id`, `snapshot_at` e `source_system`, e **nenhuma sobrescreve a anterior**.

A distinção importa mais do que parece. O modo `full_refresh` da origem principal é
`full_refresh_overwrite`: ele derruba a tabela de destino a cada carga. Copiá-lo para cá deixaria
sempre uma única fotografia, e a detecção de exclusão física — que o
[ADR-0015](adr/0015-sincronizacao-e-exclusoes.md) escolheu como o tratamento do legado — não teria
contra o que comparar. Imutabilidade aqui é propriedade da **ingestão**, não de um passo posterior
que pode não rodar.

O conteúdo original permanece **imutável** em `raw_legacy`, preservando exatamente o valor recebido
antes de qualquer limpeza. Reter não é acumular sem limite: o descarte de capturas antigas é decisão
futura, e enquanto ela não vier nenhuma captura é apagada.

### 4.1 A identidade da captura, e a da ocorrência

Duas identidades diferentes, e confundi-las é o erro que este arranjo evita.

| O que identifica | Coluna | Quem escreve |
|---|---|---|
| A **captura** | `_airbyte_generation_id`, com `_airbyte_extracted_at` como instante | O destino do Airbyte |
| A **ocorrência física** | `legacy_row_id` | O gerador, antes da ingestão |

O `snapshot_id` não precisou ser inventado: o destino já numera cada geração, e o instante vem com
ela. Acrescentar uma coluna própria para isso criaria uma segunda verdade sobre a mesma captura — e
a primeira continuaria existindo.

O `legacy_row_id` é do gerador e resolve outro problema: **duas linhas de negócio idênticas
precisam ser distinguíveis**. Sem ele, a duplicata exata do
[ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md) não teria como ter uma
canônica e uma excedente — seriam a mesma linha contada duas vezes.

**Medido em 05/09/2026:** duas capturas do mesmo conjunto, 12.749 linhas cada, retidas lado a lado
em `raw_legacy` e separáveis por `_airbyte_generation_id`. Nenhuma sobrescreveu a outra.

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
| `rejected` | Não consertável com segurança, excedente de duplicata, ou filho de pai rejeitado | Schema `quarantine`, com código e descrição do motivo |

**`rejected` tem três origens diferentes**, e a reconciliação as discrimina
([ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)): defeito do próprio
registro, **excedente de duplicata exata** e **cascata de pai rejeitado**. Sem discriminar, o número
fecha e não informa — e o legado parece pior do que é, porque um defeito raro no pai custa muitas
linhas.

A duplicata exata elege uma **ocorrência canônica** por regra determinística — a de menor
identificador físico dentro da captura —, que segue como `accepted` ou `corrected`; cada excedente é
uma linha `rejected` com o código `DUP_EXACT` e o vínculo à canônica.

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

O domínio é **declarado e fechado**: `retail` para a origem transacional e `legacy` para a antiga.
Caminho de ingestão **não** é sistema de origem — Airbyte e Beam transportam o mesmo `retail`, e
representá-los como origens distintas faria a reconciliação entre os dois caminhos do estoque
comparar uma coisa com ela mesma sob outro nome.

O alcance está no [ADR-0039](adr/0039-alcance-da-procedencia.md): `source_system` existe em toda
tabela que recebe registros de mais de um sistema, e **só nelas**. Dimensão que nasce de uma *seed*
ou de uma série gerada — `dim_date`, `dim_geography`, `dim_support_category` — não recebe: acrescentar
origem ali criaria duplicata onde deve haver conformação.

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
