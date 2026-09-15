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
| Versão | 2.8 |
| Catálogo de falhas | 25 tipos declarados ([ADR-0022](adr/0022-catalogo-declarativo-de-falhas-do-legado.md) e [ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)) |
| Última revisão | 14/09/2026 |

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

**O schema nasce de migração, desde 14/09/2026.** Até então `legacy_db` era criado por DDL emitido
na carga (`schema.ddl()`), fora do ciclo de evolução e reversão — o achado R12 da terceira revisão.
Agora a declaração é `legacy/schema.py::metadata()`, o histórico é `db/migrations_legacy/`
(`alembic -n legacy`, seção própria no `alembic.ini`, porque é outro banco com outra história), e a
carga **recusa** um banco que não esteja na cabeça das migrações. O `ddl()` continua existindo como
caminho de referência: o teste de migração cria dois bancos isolados — um pelo `upgrade`, outro pelo
`ddl()` — e compara os catálogos físicos (tabelas, colunas, tipos, nulabilidade, identidade,
*constraints*, índices); o `legacy_db` que já existia só recebeu `stamp` depois de o seu catálogo
ser igual aos dois (**medido em 14/09/2026: zero diferenças nas três comparações**). É o ADR-0010
aplicado à segunda origem, sem ADR novo.

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
| `MONEY_AMBIGUOUS` | `amount` | Não casa com nenhum formato monetário reconhecido | Rejeitar: converter exigiria adivinhar o separador |
| `DATE_UNPARSEABLE` | Campo de tempo | Texto que não é data em formato algum | Rejeitar: não há data a inferir |
| `TEXT_ENCODING_AMBIGUOUS` | Qualquer texto | Mojibake numa célula que não se reverte por inteiro | Rejeitar: reverter só o trecho reconhecido corromperia o resto |

**`MONEY_AMBIGUOUS` e `DATE_UNPARSEABLE` nasceram da revisão de 07/09/2026**, e a ausência delas
era omissão, não decisão: o critério da §3.1 já dizia o que fazer, e `NUM_AMBIGUOUS` já o aplicava
à quantidade. Faltava aplicá-lo ao dinheiro e à data. Sem elas, `abc` num campo monetário e
`sem data` num campo de tempo **saíam corrigidos** — marcados como consertados sem nunca terem sido
convertidos.

**`TEXT_ENCODING_AMBIGUOUS` nasceu da segunda revisão da mesma data**, e a omissão era da mesma
natureza: a linha de `TEXT_ENCODING` acima sempre disse "rejeitar se ambíguo", e só a metade
reparável existia. A metade que faltava não era inofensiva. Detectar um par de mojibake autorizava
recodificar a **célula inteira**, e a conversão derrubava a consulta quando a célula misturava o
par com um acento legítimo (`SQLSTATE 22021`) ou com um emoji (`22P05`) — não a linha: a consulta.
Agora a conversão só age quando a célula inteira sobrevive à ida e volta, e o que não sobrevive é
rejeitado em vez de sair aceito com o texto corrompido intacto.

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
| `31/02/2024` | `DATE_FORMAT_KNOWN` e `DATE_IMPOSSIBLE` | Tenta converter uma data inexistente; no PostgreSQL 16, a consulta falha antes da quarentena |
| `   ` | `TEXT_WHITESPACE_CASE` e `NULL_DISGUISED` | Um nulo disfarçado vira string vazia, em vez de nulo |
| `sem@arroba` | as regras de texto e `EMAIL_MALFORMED` | Um e-mail inválido é aceito depois de "limpo" |

A mesma precedência vale para a expressão que produz o **valor tratado**: a primeira regra que
rejeita preserva o original e impede conversões posteriores. Consultar só o código detectado não
exercita essa expressão; a verificação está em [Qualidade §5.1](qualidade_de_dados.md#51-validação-dos-valores-tratados--06092026).

### 3.1.2 Onde cada falha se aplica, e por quê nem toda coluna

Três listas no catálogo restringem onde uma falha faz sentido. Elas não são
otimização: sem elas, o tratamento rejeitava **1.508 registros perfeitos** —
12% da captura —, e a reconciliação deixava de informar qualquer coisa.

| Lista | Por que existe |
|---|---|
| `promessas` | `carts.expires_at` é uma data futura por natureza; `DATE_FUTURE` ali condenaria 127 carrinhos corretos |
| `quantidades_com_sinal` | `quantity_delta` é assinado — saída de estoque é negativa —, e o sinal ali não é defeito. Eram 388 movimentos |
| `colunas_estreitadas` | O sistema antigo apertou **alguns** campos livres, não todos. `currency` sempre teve três caracteres, e truncá-la produzia 987 rejeições de valores certos |
| `dominios_fechados` | Tabela que guarda **valores**, não coisas, não recebe injeção. O sorteio é uniforme, e acertar uma das três linhas de `sales_channels` cascateava para 3.564 carrinhos — 64% de toda a cascata vinha daí |

Depois das listas, o falso positivo residual é **13 em 12.749 linhas (0,10%)**,
e é quase todo `TEXT_TRUNCATED` — a heurística declarada, com o seu custo medido
em vez de escondido.

E a cascata passa a medir o que existe para demonstrar. Com os domínios fechados
fora do sorteio, a captura fecha em **82,0% aceitos, 17,8% rejeitados e 0,2%
corrigidos** — contra 44% de rejeição quando uma linha de três derrubava um
terço do dado.

### 3.1.3 Precedência quando a mesma ocorrência tem várias falhas

Uma linha pode carregar mais de um defeito, e **todos os achados são registrados**. O que não se
multiplica é a ocorrência: ela é contada uma vez, e classificada uma vez, pela regra:

1. qualquer falha irrecuperável → `rejected`;
2. senão, houve conversão → `corrected`;
3. senão → `accepted`.

O piso de cobertura do [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) exige que
**todos os tipos injetáveis estejam representados em qualquer escala** — um tipo sem registro gerado é um
tratamento sem teste. `PARENT_REJECTED` só aparece quando existe pai rejeitado com filho íntegro, e
a geração garante esse caso de propósito.

### 3.2 Manifesto de falhas

A geração é determinística, recebe `seed` própria — declarada em
[`catalogo.yml`](../src/mvp_ed1/legacy/catalogo.yml), distinta da origem principal — e produz um
**manifesto** declarando o erro esperado em cada registro.

O manifesto é escrito em `data/legacy/`, **fora do banco e fora do Git**. Guardá-lo ao lado do dado
tratado convidaria a transformação a consultá-lo, e o teste passaria a medir a si mesmo. Desde
14/09/2026 ele tem quatro partes, e um nome por lote:

| Parte | O que diz |
|---|---|
| `lote` | **A identidade do conteúdo**: `md5` da serialização canônica de cada tabela (todas as linhas, em ordem física, com `''` lido como nulo — a normalização que o transporte aplica), um hash global e os parâmetros efetivos da geração (semente, fator, `as_of`, versão do catálogo). Contagem e conjunto de `legacy_row_id` **não** identificam um lote: recomeçam em 1 a cada geração e se repetem com conteúdo diferente |
| `achados` | O que o injetor fez, célula a célula: ocorrência física, código, coluna, valor antes, valor depois, resultado esperado e o **valor esperado** depois da limpeza |
| `veredito` | O esperado de **toda** ocorrência — saída, origem da rejeição e o multiconjunto de achados, inclusive contexto e cascata —, recomputado por `legacy/oraculo.py` sobre as linhas finais (ver §5) |
| `mutacoes` | O diário do que foi feito à origem **depois** da carga — remoção, inserção, alteração —, com o que o banco devolveu; vazio ao nascer |

O arquivo chama-se `manifesto-<hash do lote>.json`, e `manifesto.json` é um *link* para o corrente.
Nenhum é apagado: regerar a origem produz outro arquivo, e o anterior continua descrevendo a captura
que já está retida em `raw_legacy`. O mesmo hash é conferido pelo `writer` no `legacy_db` logo
depois do `COPY` — carga cujo conteúdo não é o gerado não ganha manifesto — e pelos testes de
integração na captura selecionada: **captura cujo conteúdo não é o do manifesto não tem veredito
comparado**, é recusada. `python -m mvp_ed1.legacy.cli manifesto` recalcula o manifesto do lote
determinístico sem tocar o banco.

O **valor esperado** de um achado corrigível não é "o valor antes": sai do contrato `recuperacao`
declarado por falha no catálogo. `original` quando a informação foi preservada e a limpeza a
restaura (`R$ 1.234,56` volta a `1234.56`); `nulo` quando o alvo canônico é o nulo de verdade
(`NULL_DISGUISED`: `'N/A'` vira nulo, e o `Vermelho` que havia antes **não** volta, nem deve). Sem
esse contrato, o teste exigiria de uma conversão correta um valor que ela não tem como produzir.

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

**O que ele promete quando vira `event_sequence`** (D40, decidida em 14/09/2026): nas linhas
legadas empilhadas, `event_sequence = legacy_row_id` é **desempate técnico dentro da captura** —
presente e único por origem — e nada além disso. Não é ordem observada do evento, e não é estável
entre recapturas: o identificador recomeça em 1 a cada geração. Consumidor que precisar de ordem
de negócio nas linhas legadas usa o instante do evento, nunca esta coluna. O teste
`legado_event_sequence_e_desempate_tecnico` cobra exatamente o contrato.

**Medido em 05/09/2026:** duas capturas do mesmo conjunto, 12.749 linhas cada, retidas lado a lado
em `raw_legacy` e separáveis por `_airbyte_generation_id`. Nenhuma sobrescreveu a outra.

Diferente do [ponto de recuperação](capacidade_e_recuperacao.md#3-ponto-único-de-recuperação), cuja
finalidade é restaurar o ambiente, este *snapshot* existe para **linhagem, auditoria e
reprocessamento** da limpeza.

### 4.2 Qual captura a execução lê

Reter várias obriga a escolher uma, e a escolha é feita **uma vez**, no modelo
`legacy_selected_capture`: a mais recente, ou a que `legacy_snapshot_id` indicar quando se
reprocessa. Os 40 modelos de limpeza leem esse valor em vez de cada um tomar o máximo da sua própria
tabela — que parecia equivalente e não é. A tabela que não vem numa carga tem o seu máximo na
geração **anterior**, e serviria linhas velhas ao lado das novas sem que nada acusasse a mistura.

Que a captura escolhida exista e seja **íntegra** não é assumido — e, desde o
[ADR-0044](adr/0044-certificar-cada-captura-do-legado-por-conteudo.md) (14/09/2026), "íntegra" é
**certificada**, não inferida do bruto:

| Teste | O que afirma | O que ele separa |
|---|---|---|
| `legacy_captura_existe` | A geração selecionada está em `raw_legacy` | Pipeline correto de pipeline **vazio** — um `legacy_snapshot_id` inexistente selecionava zero linhas nas 40 origens, e nada falhava |
| `legacy_captura_completa` | A geração selecionada tem certificado `complete` nas 40 tabelas em `governance.legacy_captures`, e as contagens do bruto conferem com ele | Captura **íntegra** de captura anterior reutilizada, instável (a origem mudou durante o *job*), incompleta (tabela ou conteúdo faltando) ou inconsistente (linhas de outro *job* na mesma geração) |

O certificado nasce em duas fases, em volta de cada sincronização: **antes** do *job*, contagem e
hash de conteúdo de cada tabela na origem; **depois**, a origem de novo e o bruto da geração, com
`_airbyte_meta.sync_id` conferido linha a linha contra o `jobId`. Tabela com zero na origem e zero
no bruto é completa — "legitimamente vazia" passou a ser medida, e a lista `VAZIAS_LEGITIMAS`
deixou de existir. A geração **15**, retida com 39 tabelas e *job* `succeeded`, é o caso que só o
certificado recusa. As capturas 1–16 não têm certificado nem podem ter: não são elegíveis como
"anterior certificada" para a detecção de exclusão física.

Na DAG, a escolha viaja da sincronização para todas as tarefas de dbt como `legacy_snapshot_id`, e
é o `snapshot_id` **do certificado `complete`** — `geracao_do_legado` falha se o *job* não produziu
um. Sem isso, cada uma das sete invocações reabriria a escolha, e uma carga que chegasse no meio
faria camadas vizinhas lerem capturas diferentes. `make sync-legacy` passa pelas mesmas duas fases.

---

## 5. Limpeza e classificação

**Estado em 07/09/2026:** limpeza por coluna, classificação com falhas de contexto, quarentena,
DAG e empilhamento estão entregues. A [D32](adr/README.md#2-decisões-já-fechadas) foi decidida e
`NULL_REQUIRED` faz parte do catálogo. A [D35](pendencias.md#d35--decidida-em-07092026) foi
decidida: o pai sobrevive à rejeição de um filho, e a divergência que isso cria é tolerada **apenas**
onde a quarentena a explica. A [D33](pendencias.md#d33--decidida-em-07092026) manteve a classificação
conferindo contra a origem inteira, com o número do armazém em
`legacy_order_totals_divergence`; a [D34](pendencias.md#d34--decidida-em-07092026) acrescentou
`treatment_fingerprint`, e foi por causa dela que a versão do catálogo avançou para 4.

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

**Quatro casos que os ADRs não decidiam, fechados pelo Owner em 14/09/2026** — são o contrato que o
oráculo por ocorrência (`legacy/oraculo.py`) implementa e contra o qual a classificação é conferida:

| Caso | O que vale |
|---|---|
| Filho aponta para uma chave que existe numa excedente de `DUP_EXACT` rejeitada **e** numa canônica apta | **Não cascateia** — a referência resolve à canônica, e o pai de negócio está apto |
| `DUP_PARTIAL` rejeita as duas versões | Os filhos **cascateiam**: nenhuma versão está apta |
| Pai rejeitado por `NULL_REQUIRED` na própria chave | Os filhos são **`FK_ORPHAN`** (defeito próprio), não cascata — o vínculo não resolve para ocorrência nenhuma |
| Ciclo de auto-referência com raiz rejeitada | Toda a componente é `rejected`; a **raiz conserva a causa própria** (`own_invalid`), só os alcançados são `parent_rejected` |

A origem da rejeição segue a precedência **defeito próprio > excedente > cascata**: uma excedente que
também tem defeito próprio é `own_invalid`.

**Os modelos de limpeza são `table`, não `view`** — exceção por origem ao
[ADR-0016](adr/0016-materializacao-por-camada.md), concedida pelo
[ADR-0043](adr/0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md). A razão é o tamanho do
código gerado: cada `stg_legacy__<t>` tem de 60 a 120 kB de SQL, e como *view* essa árvore era
replanejada a cada leitura, o que esgotava a memória da estação em vez de falhar. O ramo `retail` do
`staging` continua sendo *view*. O custo medido está na
[Capacidade §2.10](capacidade_e_recuperacao.md#210-o-jit-do-postgresql-sobre-os-modelos-do-legado--08092026).

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

**Como o registro apto chega ao modelo.** O conjunto apto sai da classificação como
`cleaned_payload` em JSONB, com os nomes e a tipagem frouxa do sistema antigo; os modelos de
`trusted` leem colunas já renomeadas pelo `staging`. Entre as duas formas há uma **ponte** por
tabela, `legado__<tabela>`, que extrai, tipa e renomeia. Ela é gerada a partir do próprio modelo de
`staging` da origem principal — o mapa de renome tem um dono só, e uma coluna renomeada de um lado
não pode ficar para trás do outro. O empilhamento, no modelo, é então um `union all` entre duas
relações do mesmo formato, escrito pela macro `empilhado`.

**Quatro tabelas não são empilháveis.** `customer_contacts`, `customer_preferences`, `price_lists` e
`product_prices` existem no legado e **não têm modelo na origem principal** — não há relação com que
uni-las. Os seus registros aptos param na classificação: não são rejeitados, porque nada há de
errado com eles, e não são empilhados, porque não há destino. A lista está declarada em
`src/mvp_ed1/legacy/ponte.py`, e a reconciliação abaixo vale para as 36 restantes.

A reconciliação é obrigatória e deve fechar exatamente:

```text
extracted_rows = accepted_rows + corrected_rows + rejected_rows
stacked_rows   = accepted_rows + corrected_rows
```

Reprocessar o mesmo `snapshot_id` não pode duplicar registros: o tratamento é idempotente.

**A captura é retroativa, e a fato incremental precisa disso escrito.** As camadas até `trusted` são
reconstruídas por inteiro a cada execução, então a captura corrente é sempre o que elas mostram. A
única relação do projeto que **não** é reconstruída é `fact_inventory_movement`, e nela o ramo legado
entra por `delete+insert` — a partição é apagada e reescrita pela captura corrente — enquanto o ramo
`retail` mantém a janela por tempo de evento
([ADR-0042](adr/0042-reconciliar-a-captura-legada-na-fato-incremental.md)).

Sem isso, dois caminhos ficavam sem reconciliação: o registro que se torna **apto entre capturas**
nunca era relido, porque o `occurred_at` dele é antigo demais para a janela alcançar; e o que
**deixa de vir** na captura seguinte permanecia materializado, porque `merge` só faz *upsert*. Os
dois são invisíveis numa fato que nasceu de reconstrução completa, e é por isso que a prova exigida
é de **reprocessamento**, não de reconstrução — `tests/test_fato_incremental.py`.

**Exclusões.** Diferente da origem principal, que pratica *soft delete*, o legado **apaga
fisicamente** — é o comportamento verossímil de um sistema antigo. A ausência é detectada por
comparação contra as capturas anteriores, que é possível porque `raw_legacy` é imutável e retido
([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)). Registro que desaparece sem explicação é
divergência de reconciliação, nunca resultado.

Como se detecta, desde o [ADR-0045](adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md)
(14/09/2026): **só no bruto**, pela chave primária declarada por tabela (`id` em 39, `movement_id`
na 40ª), canonizada pelo tipo — chave nula ou não conversível é `sem identidade`, contada à parte —,
e só entre capturas **certificadas** ([ADR-0044](adr/0044-certificar-cada-captura-do-legado-por-conteudo.md)).
Dois modelos em `trusted` respondem duas perguntas diferentes:

| Modelo | Pergunta | O que guarda |
|---|---|---|
| `legacy_removed_records` | O que já sumiu e não voltou? — **memória** | Toda chave presente em alguma certificada anterior e ausente na selecionada: `last_seen_snapshot_id`, `removed_in_snapshot_id`, último payload bruto. Persiste por construção; sai quando a chave reaparece. Não entra em equação |
| `legacy_capture_transitions` | O que mudou entre a anterior certificada e esta? — **intervalo** | Por chave, com multiplicidade: `removida`, `adicionada`, `reduzida`, `aumentada`, `mantida`; `sem identidade` por lado. É o que fecha a equação em linhas físicas, a cada *build* |

**Nenhuma dimensão recebe marca por isso** — decisão do Owner, e a razão está no ADR: sob a cascata
do ADR-0038 e o `delete+insert` do ADR-0042, a remoção já retira do datamart tudo o que dependia do
registro; a memória é o bruto retido e a tabela de auditoria, não `dim_customer`. Rejeição nova sem
remoção **não** é remoção: a chave é `mantida`, e a perda de aptidão aparece na classificação.

---

## 7. Conceitos exercitados

Esta origem existe para praticar, com evidência verificável: *schema-on-read* contra
*schema-on-write*, tipagem defensiva, dicionário de conversões determinísticas, quarentena em vez
de descarte, procedência de dados, reconciliação de contagens e teste contra oráculo.
