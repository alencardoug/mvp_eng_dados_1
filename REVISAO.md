# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `1e197ac..33d6451` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
1ddf9b5 docs: registra a D66 — a P13 não conta a remessa entregue sem item aceito
ff868a9 feat: herda a descrição de coluna por transporte, como a sensibilidade
1e7de44 test: acrescenta a catraca de descrição e de domain/owner por camada
eeae9d1 docs: registra a descrição derivada na Governança e no Dicionário
d4c2885 feat: deriva o domínio da tabela conduzida e declara o dono por camada
e0a04f2 feat: liga o persist_docs nos snapshots
68e84bc feat: dá a cada tabela da origem o texto do seu identificador
3c769bd docs: registra na Governança o domínio derivado, o dono por camada e os snapshots
14fdf30 fix: decide pelo disco, não pelo manifest, o que vai para o arquivo gerado
aaa3538 feat: escreve o domínio dos objetos que não conduzem tabela da origem
7cea1ee feat: escreve o texto das colunas que calculam, até o consumo
020638a docs: registra a D67 — o captured_amount da P09 é sempre zero
33d6451 docs: registra na Governança o vocabulário de domínio e o texto das medidas
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 42 arquivos

- `Makefile`
- `README.md`
- `dbt/dbt_project.yml`
- `dbt/models/_convencoes.md`
- `dbt/models/analytics/_analytics__models.yml`
- `dbt/models/consumption/_consumption__models.yml`
- `dbt/models/quarantine/_sensitivity.yml	dbt/models/quarantine/_derived.yml`
- `dbt/models/staging/_sensitivity.yml	dbt/models/staging/_derived.yml`
- `dbt/models/staging/_retail__models.yml`
- `dbt/models/staging/_retail__sources.yml`
- `dbt/models/staging/legacy/_sensitivity.yml`
- `dbt/models/trusted/_sensitivity.yml`
- `dbt/models/trusted/_trusted__models.yml`
- `dbt/models/trusted/legacy/_medidas__models.yml`
- `dbt/seeds/_seeds.yml`
- `dbt/snapshots/_sensitivity.yml`
- `docs/adr/README.md`
- `docs/dicionario_de_dados.md`
- `docs/governanca_de_dados.md`
- `docs/pendencias.md`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/ponte.py`
- `src/mvp_ed1/models/catalog.py`
- `src/mvp_ed1/models/customers.py`
- `src/mvp_ed1/models/descriptions.py`
- `src/mvp_ed1/models/domains.py`
- `src/mvp_ed1/models/inventory.py`
- `src/mvp_ed1/models/lineage.py`
- `src/mvp_ed1/models/logistics.py`
- `src/mvp_ed1/models/marketing.py`
- `src/mvp_ed1/models/payments.py`
- `src/mvp_ed1/models/procurement.py`
- `src/mvp_ed1/models/sales.py`
- `src/mvp_ed1/models/sensitivity.py`
- `src/mvp_ed1/models/support.py`
- `src/mvp_ed1/models/transport.py`
- `tests/conftest.py`
- `tests/test_classificacao.py`
- `tests/test_classificacao_derivada.py`
- `tests/test_descricao.py`
- `tests/test_descricao_derivada.py`
- `tests/test_linhagem.py`

### Gerados — 6 arquivos, revisar por amostragem

- `dbt/models/staging/legacy/_derived.yml`
- `dbt/models/staging/legacy/_legacy__models.yml`
- `dbt/models/staging/legacy/_legacy__sources.yml`
- `dbt/models/trusted/_derived.yml`
- `dbt/models/trusted/legacy/_pontes__models.yml`
- `dbt/snapshots/_derived.yml`

**Declaração desta entrega:** este lote é a etapa 1.8 da v1.1.0 (o catálogo: descrição herdada,
`domain` e `owner`) mais o registro das decisões D66 e D67. Revisão integral em:

- **O motor da herança:** `src/mvp_ed1/models/transport.py` (o que transporta e o que calcula,
  inclusive a regra da união), `descriptions.py` (texto-raiz, convenções, ponte, `description_reason`,
  o cache em `dbt/target`) e `domains.py` (`CONDUCTS`, `DECLARED`, `domain_reason`); e
  `sensitivity.py`, cujo `plan()` passou a decidir pelo disco (14fdf30).
- **O texto-raiz:** as `doc=` das chaves primárias e colunas nos modelos SQLAlchemy
  (`customers.py` … `support.py`, `catalog.py`), `dbt/models/_convencoes.md` e os `.yml` escritos à
  mão — `_trusted__models.yml`, `_analytics__models.yml`, `_consumption__models.yml`,
  `_retail__models.yml`, `trusted/legacy/_medidas__models.yml`, `dbt/seeds/_seeds.yml`. São os 247
  textos aprovados pelo Owner em 03/11/2026; a revisão é de coerência com o SQL, não de redação.
- **O gerador da ponte:** `src/mvp_ed1/legacy/ponte.py` e `legacy/dbt.py` (`description_from`).
- **A configuração:** `dbt/dbt_project.yml` (`owner` por camada, `persist_docs` nos snapshots).
- **As catracas:** `tests/test_descricao.py` (tetos por camada) e `tests/test_descricao_derivada.py`.

**Correção ao mapa acima:** as linhas com tabulação são renomeações (`_sensitivity.yml` →
`_derived.yml`) e o resultado é **gerado**, como `dbt/models/staging/_retail__sources.yml`, que o
`make catalog` escreve como espelho dos modelos (`descriptions.py:37`). Amostragem basta neles e
nos seis da lista de gerados.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
........................................................................ [ 85%]
........................................................................ [ 93%]
.....................................................................    [100%]
=========================== short test summary info ============================
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_remocao.py:643: sem mutações no diário: a prova entre capturas ainda não aconteceu
1002 passed, 3 skipped in 361.22s (0:06:01)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **O `make check` da seção 3 rodou na ponta `20ea4f3`, não em `33d6451`.** Entre os dois há 66
  commits (lotes 1 e 2, etapa 1.9), e o lote 1 já mexeu em arquivos daqui (`94e0d09` corrigiu a
  P09 da D67). Não se refez a medição no topo do intervalo; o que a ponta mostra é que a herança
  continua de pé depois de tudo, não que `33d6451` passava sozinho.
- **A semântica dos 247 textos-raiz.** O Owner os aprovou como redação; ninguém conferiu, um a um,
  que cada texto descreve o que o SQL calcula (aditividade, grão, filtro). É o melhor lugar para
  amostrar.
- **A regra de transporte contra SQL que as views ainda não usam.** `transport.py` foi exercitado
  pelo SQL compilado dos modelos de hoje e pelos casos dos testes; formas como `lateral`, `cast`
  para tipo de domínio, coalesce com literal ou `case` de um ramo só não foram provadas — o
  docstring diz que calculam, e só isso foi lido.
- **O cache da derivação em `dbt/target`.** A chave é "o que ela lê"; não se provou que toda
  entrada que muda o resultado está na chave (por exemplo, um `doc` de `_convencoes.md` alterado
  sem mudar o `.yml`). Um cache velho daria um `_derived.yml` velho com o `make check` verde.
- **A diferença entre a catraca e o banco.** A catraca conta, pelo manifest, colunas sem descrição
  (`trusted`: teto 125); o banco tem 132 colunas de `trusted` sem comentário (medido agora: 937 de
  1069). Não se explicou a diferença de 7 — provavelmente objetos sem `persist_docs` ou colunas
  que o manifest não declara, não conferido.
- **Os comentários dos snapshots.** O `persist_docs` foi ligado (e0a04f2) e o banco tem 103 de 109
  colunas de `snapshots` comentadas, mesma consulta; as 6 sem comentário batem com o teto 6 da
  catraca, mas não se confirmou que são as mesmas seis.
- **`raw` e `raw_legacy` sem comentário no banco** (0 de 545 e 0 de 616): é o declarado — o
  Airbyte recria as tabelas e o dbt não as constrói —, mas significa que quem lê o banco direto
  não vê a descrição da origem. Não é medida de defeito, é o limite.
- **D66 e D67 não são correção.** D66 (a P13 não conta 12 remessas entregues cujos itens foram
  todos rejeitados) segue pendente, por decisão do Owner, fora da v1.1.0. D67 foi registrada aqui e
  corrigida depois, em `94e0d09`, fora deste intervalo (lote 1). Os números da D67 (538 linhas,
  R$ 36,7 mi) são da época e não foram remedidos.
- **Três avisos do `make check`** (`legacy_classifications`: origem `c` de `position`/`name` não
  encontrada) vêm de `jsonb_array_elements_text(...) with ordinality c(name, position)`, uma função
  no `from` que a linhagem não resolve; o arquivo não mudou neste intervalo (último commit
  `9200b15`). Não se mediu se o aviso já existia em `1e197ac`.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **`persist_docs` do dbt-postgres** escreve `comment on column` em tabela, view e snapshot, e não
  em fonte. Medido para modelos e snapshots (seção 4); para as fontes, o motivo de ficarem de fora
  é o Airbyte recriar as tabelas, o que é premissa da Governança §5.1, não reconferida aqui.
- **sqlglot 30.18.0** representa o SQL compilado do dbt de modo que `traverse_scope` cubra todas as
  colunas de saída. Não se testou contra outra versão; a atualização do sqlglot pode mudar a
  árvore e a classificação de transporte calada — a catraca de descrição pegaria só o efeito.
- **O manifest de `dbt/target`** está em dia com o disco quando o `make catalog` roda. O 14fdf30
  existe justamente porque não estava (23 modelos de `trusted` sumiam do `_derived.yml`); a
  correção move a decisão para o disco, mas o resto da derivação ainda lê o manifest.
- **Texto `doc=` dos modelos SQLAlchemy** é a única fonte da descrição de origem. Não se conferiu
  se algum texto contradiz o comentário de coluna do `source_db` (que não existe hoje).

## 6. Ambiente que a revisão precisa

O que precisa estar de pé para as sondas, e como pôr de pé. **Subir é permitido;
alterar dado não.** A regra "deixar o ambiente como o encontrou" vale para o conteúdo
dos bancos e dos volumes — não para contêiner parado ou ausente, que o revisor sobe.

| Precisa de | Como subir | Como conferir |
|---|---|---|
| Os três bancos (`source_db`, `legacy_db`, `warehouse_db`) | `make up` — recria os contêineres sobre os volumes existentes; nada é regerado | `make ps`; portas no `.env` |
| Airbyte, Airflow ou streaming | `make airbyte-up` · `make airflow-up` · `make stream-up` — a troca é automática: pausa o conflitante, retoma depois | `make preflight ALVO=…` responde sem efeito |

Contêiner que não aparece em `docker ps -a` não está em outro contexto Docker: foi
derrubado por `make down`, que preserva os volumes. `make up` o traz de volta.

**Nunca** na revisão: `make reset`, `seed-*` ou `*-down` com `FORCE=1`, ou qualquer alvo que
reescreva dado — isso é execução, não revisão. Se o ambiente não puder ser preparado, a
indisponibilidade entra nos achados e o que dependia dela fica **não medido** — nunca inferido.

**Para esta revisão:** só os três bancos com o armazém construído — o estado que o `make check`
desta seção deixou em `20ea4f3`. Airbyte, Airflow e o *streaming* **não** são necessários: tudo
aqui se lê no manifest, nos `.yml`, no código e nos comentários do banco.

- O manifest está em `dbt/target/manifest.json`, do `make check` acima; se faltar,
  `set -a; . ./.env; set +a; cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt parse` o recria sem
  tocar em dado (a mesma invocação da variável `DBT` do `Makefile:39`).
- Consulta de superusuário só por `~/Projetos/bi-como-codigo/evidence/20261022/ro.sh` com
  `ENG_DADOS_DIR` apontando para este checkout (somente leitura).
- **Não** rodar `make catalog`, `make legacy-models`, `make dbt-build` ou `dbt-rebuild`: reescrevem
  os gerados ou o armazém. Para conferir a geração, copie o checkout para `/tmp` e rode lá, ou
  chame as funções de derivação em memória e compare com o disco.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Herdar só por transporte, nunca por linhagem.** A linhagem diria que `sum(amount)` vem de
  `amount`; herdar daí daria à soma o texto do valor unitário. A regra conservadora deixa sem texto
  tudo que calcula, e por isso foram precisos 247 textos à mão — custo aceito em troca de nenhum
  texto errado por herança.
- **Na união, o ramo constante não vota.** O membro desconhecido das dimensões (`-1`, `'unknown'`)
  não impede a herança. A alternativa — exigir que todo ramo transporte — deixaria toda dimensão
  sem texto. O risco é um ramo literal que não seja preenchimento e mude o sentido da coluna.
- **`cast` transporta só quando volta ao tipo declarado na origem.** Um `cast` para tipo mais largo
  também não muda o valor, mas aceitar isso pedia saber, salto a salto, se o tipo de chegada contém
  o de partida. Ficou de fora: calcula.
- **Texto à mão contra herdado:** quando os dois existem, vale o à mão só com
  `description_reason`; sem motivo, o herdado vence (15 casos: 14 ganharam motivo, 1 cedeu). A
  alternativa — o à mão sempre vence — esconderia texto atrasado.
- **`owner` por camada, não por objeto.** Um só dono no projeto hoje; declarar por objeto seria
  repetição sem informação. O custo aparece quando houver dois donos numa mesma camada.
- **`domain` transversal para calendário e geografia (N51),** em vez de forçar um dos nove domínios
  da origem.
- **D66 adiada e D67 registrada sem corrigir aqui:** ambas mudam números de negócio, e a regra do
  projeto é que a correção de tratamento é decisão do Owner (`CLAUDE.md` §5).

---

## Achados da revisão

Revisão de `1e197ac..33d6451` (13 commits), em 05/11/2026. O checkout usado está em
`d7d7f44`; os testes gerais e as consultas ao banco medem esse ambiente posterior.
As sondas do motor usam o código de `33d6451`, extraído por `git archive` em
`/tmp/rvl3-33d6451`. **Parecer técnico, sem aceite ou poder de aprovação.** Nenhuma
correção implementada; Situação fica para o autor/Owner.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-01 | `src/mvp_ed1/models/descriptions.py:266` | **Texto anteriormente herdado vira raiz escrita quando o SQL passa a calcular.** Na sonda sobre `stg_retail__order_items.quantity`, trocar o SQL compilado por `cast(quantity as integer) * 100` produz `Computed(mul)`, mas mantém “Quantidade comprada do SKU.” como `written`, propaga-o para `trusted` e não pede alteração em arquivo algum. A expressão nova foi analisada: não é cache nem manifest atrasado. É necessário distinguir a proveniência do texto persistido e exigir revisão da raiz quando cessa o transporte. | `bloqueante` | **Corrigido.** Reproduzido: o ramo `escrito and entrada.kind == "hand"` aceitava como raiz escrita o herdado que a derivação gravara no `.yml` à mão. Agora, coluna que não transporta, sem `description_reason`, cujo texto é igual ao de uma das suas folhas imediatas (`derivation.leaves`), é **problema** — `make catalog` recusa e diz para escrever o texto do cálculo ou declarar motivo. Teste `test_texto_herdado_que_ficou_no_yml_a_mao_nao_vira_raiz_quando_a_coluna_passa_a_calcular`; contraprova com `descriptions.py` de `20ea4f3` em memória: `assert [] == [...]`. Nos modelos reais, a regra acusou duas colunas de P07/P08 (`on_time_rate`, `avg_order_to_delivery_days`) que usam, de propósito, o mesmo bloco do glossário da marca que leem; ganharam `description_reason`. |
| RVL3-02 | `src/mvp_ed1/models/transport.py:95` | **União pode alterar o valor e continuar sendo `Carry`.** `select id ... union all select 0::real` ignora o ramo constante e a coerção de tipo da união: PostgreSQL converte `16777217::bigint` para `16777216`, mas o motor mantém a folha de `id`. Além disso, qualquer literal de negócio é tratado como preenchimento, sem declaração que comprove isso. A regra precisa cobrir a coerção implícita e delimitar a exceção dos preenchimentos; não basta conferir o `cast` explícito de cada projeção. | `bloqueante` | **Corrigido.** `combine_union` recebe o tipo declarado das folhas; `Computed` guarda o tipo da constante com `cast`. A união calcula (`union_coercion`) quando a resolução de tipo pode mudar o valor transportado: famílias diferentes, ponto flutuante de tipo diferente, ou constante de ponto flutuante diante de folha de tipo desconhecido. Inteiro com numérico exato e texto com texto continuam transportando. Teste `test_uniao_nao_transporta_quando_a_resolucao_de_tipo_pode_mudar_o_valor` (seu `0::real`, `cast(null as text)`, `real` × `bigint`; e os que continuam: `-1`, `null::bigint`, `-1::integer`); contraprova com `transport.py` antigo: `Carry == Computed`. Nos modelos reais, nenhum texto derivado mudou. A exceção dos preenchimentos (N45) continua sendo a decisão aceita; o limite — literal de negócio num ramo também não vota — está no docstring e na Governança §5.1. |
| RVL3-03 | `dbt/models/analytics/_analytics__models.yml:1714` e `:2511`; raízes em `trusted/_trusted__models.yml` | **Aditividade herdada atravessa mudança de grão.** `fact_shipment_item.failed_attempt_count` repete a contagem da remessa em cada item; `fact_support_ticket_event.reopening_count` repete a contagem do chamado em cada evento. Ambas recebem “Aditiva”. No banco atual, somar as linhas dá **879 contra 437** tentativas por remessa e **63 contra 14** reaberturas por chamado. O valor individual é transportado, mas a instrução de agregação deixou de valer. Declarar a restrição no destino com `description_reason` e conferir as demais medidas repetidas em fatos/SCD. | `bloqueante` | **Corrigido**, e conferido além dos dois: listei toda coluna de `analytics`, `snapshots` e `consumption` com texto herdado de aditividade e a raiz dela. Os seus dois casos (`fact_shipment_item.failed_attempt_count`, `fact_support_ticket_event.reopening_count`) ganharam texto "Não aditiva entre itens/eventos" com `description_reason`. Achei o mesmo defeito nos snapshots: um SCD guarda uma linha por **versão**, e cinco contagens acumuladas herdavam "Aditiva" — novo `dbt/snapshots/_snapshots.yml` à mão, com "Semiaditiva … nunca entre versões" e motivo, para `scd_coupon` (2), `scd_customer` (2) e `scd_support_agent` (1); o resto das entradas é derivado. Hoje os SCD têm uma versão por entidade (1574/1574, 19/19, 7/7), por isso a soma ainda não diverge — diverge na primeira mudança capturada. As dimensões têm uma linha por entidade (medido), e `fact_purchase_order_item`, `fact_payment_transaction` e `fact_inventory_movement` herdam do mesmo grão. Governança §5.1 v2.13 diz a regra. |
| RVL3-04 | `dbt/models/consumption/_consumption__models.yml:1122` | **P16 declara `repeat_order_count` aditiva sem a restrição por categoria.** O CTE `classificado` produz uma linha por pedido/categoria de chamado, e a view agrupa por `support_category_name`. Um pedido com recompra e chamados em duas categorias entra duas vezes ao reagregar categorias. O texto de `order_count`, imediatamente acima, já explica essa duplicação; o novo texto do numerador a omite. Explicitar a não aditividade entre categorias e o grão completo. | `bloqueante` | **Corrigido.** `repeat_order_count`: "**Não aditiva entre categorias** — … por mês, canal, ter ou não chamado e categoria do chamado. Um pedido com chamados de duas categorias conta nas duas linhas", como já diz `order_count`. |
| RVL3-05 | `dbt/models/consumption/_consumption__models.yml:584` | **P11 descreve um filtro de custo inexistente.** `inventory_value_amount` diz usar o custo unitário médio “das saídas de venda”. O CTE `saldo` calcula `avg(m.unit_cost)` sobre **todos os tipos de movimento com custo não nulo**, sem filtro de venda e sem recorte trimestral. O filtro `m.is_sale` pertence ao outro CTE, `saidas`. Ajustar a raiz para descrever o cálculo existente; mudar o cálculo seria outra decisão. | `bloqueante` | **Corrigido** o texto, não o cálculo: "o saldo atual vezes o custo unitário médio de **todos os movimentos** do SKU no armazém que têm custo, de qualquer tipo e de todo o período". Mudar o cálculo para o custo das saídas de venda seria outra decisão; não a tomei. |
| RVL3-06 | `dbt/models/trusted/_trusted__models.yml:1294` e textos relacionados de `purchase_order_items` | **Recebimentos descritos como “todos” são somente os concluídos.** O SQL filtra `goods_receipt_status = 'completed'` antes de somar quantidade/custo e obter primeiro/último recebimento. O texto de `quantity_received` diz “somando todos os recebimentos”; os textos relacionados também não identificam essa população. Explicitar o filtro na raiz e propagar para a fato. | `bloqueante` | **Corrigido** na raiz de `trusted.purchase_order_items`, e propagado pela herança para `fact_purchase_order_item` (`make catalog` imprimiu as sete trocas): `quantity_received`, `received_cost_amount`, `first_received_at`, `last_received_at`, `quantity_outstanding`, `is_fully_received` e `is_not_received` agora dizem "recebimento concluído", o filtro `goods_receipt_status = 'completed'` do SQL. |
| RVL3-07 | `src/mvp_ed1/models/sensitivity.py:306`, `:354`; premissa do dossiê §5 | **14fdf30 corrige o destino dos arquivos, não a atualidade do SQL.** Alterar apenas o `.sql` em disco mantém a chave do cache e faz `--check` retornar zero com o manifest anterior. A premissa de compilação recente continua obrigatória. É uma limitação observada do fluxo documentado, não prova de que o `make check` completo, que faz build antes, aceite esse estado. | `observação` | **Corrigido** em vez de só declarado: `sensitivity.stale_nodes` compara o `raw_code` de cada modelo do manifest com o `.sql` no disco (o miolo do bloco, nos snapshots); diferença faz `make catalog` e `--check` recusarem antes de tocar em arquivo, mandando rodar `make dbt-build`. Teste `test_manifest_com_sql_mais_velho_que_o_disco_e_recusado`. Hoje: 196 nós, zero atrasados. Governança §5.1 diz a premissa e a recusa. |
| RVL3-08 | `dbt/dbt_project.yml`, `dbt/seeds/_seeds.yml`, `tests/test_descricao.py` | **Diferença 125 × 132 explicada: sete descrições de seeds sem `persist_docs`.** São duas de `brazilian_states`, uma de `order_status_transitions` e quatro de `support_categories`. As seis colunas sem comentário nos snapshots são exatamente as seis sem descrição no manifest. A catraca mede catálogo, não comentário físico; não confundir as duas coberturas. | `observação` | **Corrigido**, além de explicado: `+persist_docs` (relação e colunas) ligado também nas seeds em `dbt_project.yml`, e as sete descrições passam ao banco no build. A Governança §5.1 diz agora que a catraca conta o catálogo, não o comentário físico. |
| RVL3-09 | `src/mvp_ed1/models/sensitivity.py:318` | **A chave não cobre um cabeçalho CSV com quebra de linha dentro de aspas.** `_seed_columns()` lê o registro CSV completo, mas o digest lê só a primeira linha física. A contraprova muda a coluna lida sem mudar a chave e recupera a derivação antiga. É caso adversarial fora da convenção `snake_case` do repositório; não encontrei seed atual afetada. `_convencoes.md` não apresentou esse defeito: seus textos não são guardados nessa derivação, que propaga referências `doc()`. | `observação` | **Corrigido.** `_inputs_digest` lê o cabeçalho de cada seed com `csv.reader` — o registro inteiro, com quebra entre aspas — e não a primeira linha física. Teste `test_cabecalho_de_seed_com_quebra_entre_aspas_entra_na_chave`; contraprova com `sensitivity.py` antigo: os dois digests iguais. |
| RVL3-10 | Texto preexistente de `analytics.fact_inventory_movement.quantity_delta` | **Fora do intervalo quanto à redação:** o texto chama o delta de “Semiaditiva” e proíbe soma temporal, embora o SQL carregue movimentos assinados, cuja soma temporal dá a variação de estoque. A frase já existe em `1e197ac`; neste lote ganhou `description_reason`, conservando-a. Registrar separadamente para decisão do Owner, sem ampliar esta revisão para corrigir a fato. | `observação` | **Corrigido por decisão do Owner** (05/11/2026), levado a ele como você propôs: "**Aditiva** — variação assinada do saldo: positiva na entrada, negativa na saída; a soma num período é a variação líquida do estoque nele." O `description_reason` continua, agora dizendo por que é aditiva. O `quantity_on_hand` de P11, que é saldo, segue semiaditivo, e está certo. |

### Evidências e reprodução

Todos os caminhos de linha acima se referem a `33d6451`. Nos blocos de saída,
foram omitidos apenas espaços ao fim das linhas. Os scripts auxiliares e saídas
estão em `/tmp/rvl3-evidence`; apenas este dossiê foi alterado no checkout. SQL de
superusuário foi executado exclusivamente por:

```sh
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh arquivo.sql
```

A sonda inicial retornou `transaction_read_only = on`. Não foram executados build,
catalog, legacy-models, concessões, comandos de ingestão, reset ou operações no DAG.

**RVL3-01 — contraprova com SQL compilado atualizado.** Comando:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp/rvl3-33d6451/src \
  .venv/bin/python /tmp/rvl3-evidence/probe_drift.py
```

O script carrega o manifest e a derivação de referência, substitui **em memória** a
expressão `cast(quantity as integer)` por `cast(quantity as integer) * 100` no nó
`model.mvp_ed1.stg_retail__order_items`, executa novamente `sensitivity.derive`,
`descriptions.derive_texts`, `plan` e `render_files`, e compara com o disco da cópia.
Saída literal:

```text
ANTES Carry(leaves=frozenset({('raw', 'order_items', 'quantity')})) inherited 'Quantidade comprada do SKU.'
SQL_LINHA_ANTES ['cast(quantity as integer)                 as quantity,']
DEPOIS Computed(kind='mul', shape=None) written 'Quantidade comprada do SKU.'
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
PROPAGADO_TRUSTED 'Quantidade comprada do SKU.'
```

**RVL3-02 — transporte adversarial.** `probe_transport.py` passa cada SQL por
`sqlglot.parse_one(..., read="postgres")`, `qualify(..., dialect="postgres")` e
`transport.carries_by_output`, com esquema e tipo declarado da origem. Casos:
`coalesce(quantity,100)`, `nullif(quantity,0)`, `case when id>0 then quantity end`,
laterais com `quantity` e `quantity*10`, `distinct quantity`,
`first_value(quantity) over(order by id)`, casts para domínio, `bigint` e `integer`,
CTE aninhado calculado e `select *`. Os dois SQLs de união são:

```sql
select quantity as q from wh.raw.orders union all select 1000000 as q;
select id as q from wh.raw.orders union all select 0::real as q;
```

Saída de `PYTHONPATH=/tmp/rvl3-33d6451/src .venv/bin/python /tmp/rvl3-evidence/probe_transport.py`:

```text
sqlglot 30.18.0
coalesce => {'q': Computed(kind='coalesce', shape=None)}
nullif => {'q': Computed(kind='nullif', shape=None)}
case => {'q': Computed(kind='case', shape=None)}
lateral_calculo => {'q': Computed(kind='mul', shape=None)}
lateral_transporte => {'q': Carry(leaves=frozenset({('raw', 'orders', 'quantity')}))}
distinct => {'q': Carry(leaves=frozenset({('raw', 'orders', 'quantity')}))}
janela => {'q': Computed(kind='window', shape=None)}
cast_domain => {'q': Computed(kind='cast', shape=None)}
cast_largo => {'q': Computed(kind='cast', shape=None)}
cast_origem => {'q': Carry(leaves=frozenset({('raw', 'orders', 'quantity')}))}
union_literal_negocio => {'q': Carry(leaves=frozenset({('raw', 'orders', 'quantity')}))}
union_coercao_tipo => {'q': Carry(leaves=frozenset({('raw', 'orders', 'id')}))}
cte_aninhado => {'q': Computed(kind='mul', shape=None)}
select_star => {'quantity': Carry(leaves=frozenset({('raw', 'orders', 'quantity')})), 'total_amount': Carry(leaves=frozenset({('raw', 'orders', 'total_amount')})), 'id': Carry(leaves=frozenset({('raw', 'orders', 'id')}))}
lateral_alias => {'q': Computed(kind='unresolved', shape=None)}
```

O `unresolved` da lateral com lista de apelidos é conservador, não um falso transporte.
Para provar a perda de valor sem criar tabela, `ro.sh` recebeu:

```sql
with original as (select 16777217::bigint as id),
     uniao as (select id from original union all select 0::real)
select id, pg_typeof(id), id::bigint=16777217 as valor_preservado
from uniao where id<>0;
```

```text
      id       | pg_typeof | valor_preservado
---------------+-----------+------------------
 1.6777216e+07 | real      | f
(1 row)
```

Não encontrei essa união com perda de precisão nos modelos atuais; é a
contraprova pedida para uma forma que eles ainda não usam. A exceção irrestrita
para literais coincide com a regra escrita na Governança, mas a perda de valor
contradiz a promessa de transporte intacto.

**RVL3-03 — grão e valor preservado são verificações diferentes.** O SQL compilado
projeta `r.failed_attempt_count` em uma linha por item da remessa e
`t.reopening_count` em uma linha por evento do chamado. A derivação de `33d6451`
classifica ambas como `inherited`. As raízes, no grão da remessa e do chamado,
podem ser aditivas; a cópia literal da instrução de soma nas fatos é que erra.

`ro.sh /tmp/rvl3-evidence/grain.sql` compara `sum(medida)` com a soma de
`max(medida)` por `(source_system, shipment_id)` ou
`(source_system, support_ticket_id)` e lista exemplos. Saída:

```text
       measure        | soma_itens | soma_remessas
----------------------+------------+---------------
 failed_attempt_count |        879 |           437
(1 row)

     measure     | soma_eventos | soma_chamados
-----------------+--------------+---------------
 reopening_count |           63 |            14
(1 row)

 source_system | shipment_id | itens | tentativas_remessa | soma_itens
---------------+-------------+-------+--------------------+------------
 legacy        |           5 |     3 |                  1 |          3
 legacy        |           8 |     2 |                  1 |          2
 legacy        |          35 |     2 |                  1 |          2
(3 rows)

 source_system | support_ticket_id | eventos | reaberturas_chamado | soma_eventos
---------------+-------------------+---------+---------------------+--------------
 retail        |                 2 |       4 |                   1 |            4
 retail        |                33 |       6 |                   1 |            6
 retail        |                34 |       4 |                   1 |            4
(3 rows)
```

Os totais são do ambiente atual, não reconstrução do volume de 03/11. Os SQLs das
duas fatos e do tratamento correspondente não mudaram entre `33d6451` e o checkout.
As métricas correntes repetidas em versões SCD também exigem restrição por entidade;
no estado consultado havia 1.574 linhas/1.574 clientes e 19 linhas/19 cupons, portanto
não medi multiplicação por múltiplas versões nessas duas dimensões.

**RVL3-04 — P16.** Trechos de `33d6451`, lidos com `sed`:

```text
# _consumption__models.yml
      - name: order_count
        description: >
          Pedidos com janela fechada. Um pedido que gerou chamados de duas
          categorias aparece nas duas linhas — somar entre categorias o conta
          duas vezes.
      - name: repeat_order_count
        description: "Aditiva — pedidos com recompra em até 90 dias, por mês, canal e por ter ou não chamado."
```

O SQL faz `select distinct source_system, order_id, support_category_key` em
`com_chamado`, junta essa relação aos pedidos e agrupa o numerador por categoria.
A consulta de categorias por pedido encontrou estes exemplos no banco:

```text
 source_system | order_id | categorias
---------------+----------+------------
 retail        |       16 |          2
 retail        |       71 |          2
 retail        |      119 |          2
(3 rows)
```

A sonda acima prova a multiplicidade de categorias, não que esses três pedidos
específicos recomprem na janela. A duplicação condicional do numerador decorre do
mesmo `classificado` e do filtro `where cl.has_post_order_repeat` no SQL.

**RVL3-05 e RVL3-06 — filtros.** Saída de `nl -ba`/`sed` nos SQLs de `33d6451`:

```text
# inventory_turnover_by_sku_and_warehouse.sql:56
round(b.quantity_on_hand * avg(m.unit_cost), 2) as inventory_value_amount
from {{ ref('inventory_balances') }} b
join {{ ref('inventory_movements') }} m
  on  m.source_system = b.source_system
 and m.warehouse_id = b.warehouse_id
 and m.product_variant_id = b.product_variant_id
 and m.unit_cost is not null

# purchase_order_items.sql:23
sum(gri.quantity_received)                  as quantity_received,
sum(gri.quantity_received * gri.unit_cost)  as received_cost_amount,
min(gr.received_at)                         as first_received_at,
max(gr.received_at)                         as last_received_at
...
where gr.goods_receipt_status = 'completed'
```

`ro.sh /tmp/rvl3-evidence/filter.sql` compara a média de todos os movimentos com a
média filtrada por `movement_type='sale_dispatch'`. Não são intercambiáveis:

```text
  movement_type   | movimentos | custo_medio
------------------+------------+-------------
 adjustment_in    |       4475 |    447.6595
 adjustment_out   |        453 |    402.9830
 customer_return  |        328 |    495.1929
 purchase_receipt |       1899 |    444.1050
 sale_dispatch    |       8087 |    431.9926
 supplier_return  |        144 |    473.6220
 transfer_in      |        506 |    407.8429
 transfer_out     |        506 |    407.8429
(8 rows)

 source_system | warehouse_id | product_variant_id | custo_todos | custo_so_venda
---------------+--------------+--------------------+-------------+----------------
 legacy        |            1 |                  4 |    278.4415 |       283.3794
 legacy        |            1 |                  7 |     71.7255 |        73.7041
 legacy        |            2 |                  4 |    281.2593 |       283.3794
(3 rows)
```

**RVL3-07 — manifest antigo.** `probe_freshness.py` guarda o cache de referência
na cópia em `/tmp`, muda só o SQL em disco de `stg_retail__order_items.quantity`
para multiplicar por 100, chama `sensitivity.main(['--check'])` e restaura o
arquivo da cópia em `finally`. Saída literal:

```text
SQL_DISCO_MUDOU=True
CHAVE_CACHE_IGUAL=True
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
RETORNO_CHECK 0
```

Isso também ocorreria sem cache, pois `derive()` lê `compiled_code` do manifest.
O teste novo de 14fdf30 cobre `patch_path` antigo após remoção de YAML e passou;
não cobre a atualização do SQL ou de `sensitivity_reason`, ainda lidos do manifest.
Não atribuo a 14fdf30 uma garantia de atualização que ele não implementa.

**RVL3-08 — catálogo contra comentários físicos.** Inventário obtido por `ro.sh`,
com `pg_class`, `pg_namespace`, `pg_attribute` e `col_description`, e cruzado com
`dbt/target/manifest.json` por schema/relação/coluna. Saída de
`.venv/bin/python /tmp/rvl3-evidence/compare_db.py`:

```text
SNAPSHOT_SEM_COMENTARIO scd_coupon.first_redeemed_at manifest_sem_descricao= True
SNAPSHOT_SEM_COMENTARIO scd_coupon.last_redeemed_at manifest_sem_descricao= True
SNAPSHOT_SEM_COMENTARIO scd_customer.second_order_at manifest_sem_descricao= True
SNAPSHOT_SEM_COMENTARIO scd_customer.is_active manifest_sem_descricao= True
SNAPSHOT_SEM_COMENTARIO scd_customer.is_repeat_buyer manifest_sem_descricao= True
SNAPSHOT_SEM_COMENTARIO scd_product.source_updated_at manifest_sem_descricao= True
DIFERENCA trusted.brazilian_states.state_name manifest= 'Nome da unidade federativa por extenso.' banco= None persist_docs= {}
DIFERENCA trusted.brazilian_states.region manifest= 'Região do IBGE a que a unidade federativa pertence.' banco= None persist_docs= {}
DIFERENCA trusted.order_status_transitions.from_status manifest= 'Vazio na transição inicial — o pedido não vem de estado nenhum.' banco= None persist_docs= {}
DIFERENCA trusted.support_categories.category_code manifest= 'Código estável da categoria de chamado; chave natural.' banco= None persist_docs= {}
DIFERENCA trusted.support_categories.category_name manifest= 'Nome da categoria de chamado.' banco= None persist_docs= {}
DIFERENCA trusted.support_categories.category_group manifest= 'Grupo que reúne categorias de chamado afins.' banco= None persist_docs= {}
DIFERENCA trusted.support_categories.description manifest= 'O que a categoria de chamado cobre.' banco= None persist_docs= {}
SEM_DESCRICAO_MANIFEST {'quarantine': 5, 'snapshots': 6, 'staging': 5, 'trusted': 125}
SEM_COMENTARIO_BANCO {'governance': 16, 'quarantine': 5, 'raw': 545, 'raw_legacy': 616, 'snapshots': 6, 'staging': 5, 'trusted': 132}
```

Os quatro snapshots têm `persist_docs: {relation: true, columns: true}` no
manifest de `33d6451`. O banco atual tem 103/109 comentários, compatíveis com a
configuração e com as seis ausências de texto; não executei snapshots para testar
a aplicação do comando. Fontes `raw`/`raw_legacy` continuam com 0/545 e 0/616
comentários, conforme a limitação declarada. Os 16 comentários ausentes em
`governance` são outra diferença entre catálogo e banco, fora da entrega aqui revista.

**RVL3-09 — entrada lida fora do digest.**
`PYTHONPATH=/tmp/rvl3-33d6451/src .venv/bin/python /tmp/rvl3-evidence/probe_cache.py`
usa uma seed temporária com bytes `"a\nb"\n1\n`, depois `"a\nc"\n1\n`, mantendo
manifest e primeira linha física. Ambas são CSVs válidos, mas os nomes de coluna
não atendem ao `snake_case` do projeto. Compara `load()` e `derive()` direto:

```text
chave_igual True
antes {'seed.p.x': {'a\nb': 'internal'}}
cache {'seed.p.x': {'a\nb': 'internal'}}
sem_cache {'seed.p.x': {'a\nc': 'internal'}}
```

Não demonstrado defeito do cache para as três seeds atuais, cujos cabeçalhos
estão em uma linha. Alterar o corpo de `_convencoes.md` não altera `Derivation`:
o texto final de `doc()` é resolvido pelo dbt ao atualizar o manifest, e
`derive_texts()` não fica nesse pickle. A exclusão de `descriptions.py` do digest
é coerente com essa separação; não é, por si, entrada esquecida.

**RVL3-10 — delimitação histórica.**
`git show 1e197ac:dbt/models/analytics/_analytics__models.yml | sed -n '1073,1082p'`:

```text
      - name: quantity_delta
        meta:
          sensitivity: internal
        description: '**Semiaditiva** — soma por armazém e SKU, nunca ao longo do tempo.'
        data_tests: [not_null]
```

O SQL de `trusted.inventory_movements` transporta `quantity_delta`; seu comentário
explica que somá-lo dá o saldo. O lote acrescenta o motivo de preservação, sem
reescrever aquela frase. Esta observação não autoriza correção de dados ou modelagem.

### Verificações sem novo achado e limites

**Derivação, amostras e versões.** O código foi extraído com:

```sh
mkdir -p /tmp/rvl3-33d6451
git archive 33d6451 | tar -x -C /tmp/rvl3-33d6451
```

`dbt parse --no-partial-parse` na cópia passou. As tentativas de
`dbt compile --no-introspect --no-populate-cache` **não passaram**: a primeira
parou na operação `mvp_ed1-on-run-end-0`, a segunda, selecionando apenas modelos e
snapshots, em `rejected_legacy_records`, ambas com `connection never acquired for
thread`. Não foi habilitada introspecção nem executado build para contornar isso.

Para a comparação, usei as declarações do parse de `33d6451` com SQL compilado do
manifest atual **somente nos 195 nós com `raw_code` idêntico**. O único modelo SQL
diferente, P09, foi renderizado da versão histórica substituindo suas três chamadas
`ref()` pelos `relation_name` do manifest. Macros, snapshots e `dbt_project.yml`
não mudaram entre as pontas. Isso é uma reconstrução controlada para análise, não
um `make check` histórico nem uma compilação integral bem-sucedida.

Saídas de `prepare_manifest.py`, `derive.py` e `legacy_compare.py`:

```text
SQLs_com_raw_code_identico_reutilizados 195
SQLs_diferentes_renderizados_so_ref ['model.mvp_ed1.payment_approval_rate_by_method']
ROOT /tmp/rvl3-33d6451
NOS 199 SEM_COMPILED []
SEM_COMPILED_APOS_ARQUIVOS []
PROBLEMAS [] [] AVISOS ['model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica', 'model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica', 'model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica']
ARQUIVOS_CONFERIDOS 5 DIFERENTES []
OBSOLETOS []
DOMINIOS_PATCHES {}
DOMINIO_NAO_MAPEADO staging []
DOMINIO_NAO_MAPEADO trusted ['legacy_order_totals_divergence']
DOMINIO_NAO_MAPEADO quarantine []
DOMINIO_NAO_MAPEADO snapshots []
DOMAIN_REASON []
ORIGENS {'declared': 1233, 'written': 311, 'inherited': 1315, 'convention': 79, 'generator': 1137}
```

```text
dbt/models/trusted/legacy/_pontes__models.yml igual= True
dbt/models/staging/legacy/_legacy__sources.yml igual= True
PARES_INVENTORY [('event_sequence', False), ('arrived_by_stream', False), ('arrived_by_batch', False), ('ingested_at', False)]
PARES_ORDER_ITEMS [('order_item_id', True), ('order_id', True), ('product_variant_id', True), ('quantity', True), ('unit_price', True), ('discount_amount', True), ('tax_amount', True), ('line_total_amount', True), ('source_created_at', True), ('source_updated_at', True), ('source_deleted_at', True), ('is_deleted', True), ('ingested_at', False)]
```

Os cinco arquivos integralmente gerados por `render_files` ficaram idênticos ao
commit. Os patches de descrição/domínio/sensibilidade ficaram vazios. A ponte e
as fontes legadas também foram comparadas byte a byte, chamando apenas funções
que retornam strings. Não executei os geradores que gravam arquivos.

Amostras de texto herdado nos `_derived.yml`:

```text
dbt/models/quarantine/_derived.yml rejected_shipment_deliveries.shipment_id 'Identificador da remessa na origem, gerado pelo banco transacional.' Carry(leaves=frozenset({('trusted', 'shipments', 'shipment_id')}))
dbt/models/staging/_derived.yml stg_retail__goods_receipt_items.goods_receipt_item_id 'Identificador do item do recebimento de mercadoria na origem, gerado pelo banco transacional.' Carry(leaves=frozenset({('raw', 'goods_receipt_items', 'id')}))
dbt/models/staging/legacy/_derived.yml sem coluna com descrição herdada
dbt/models/trusted/_derived.yml delivery_events.delivery_event_id 'Único depois da deduplicação de entrega ao menos uma vez.' Carry(leaves=frozenset({('trusted', 'legado__delivery_events', 'delivery_event_id'), ('staging', 'stg_retail__delivery_events', 'delivery_event_id')}))
dbt/snapshots/_derived.yml scd_coupon.source_system '{{ doc("source_system") }}' Carry(leaves=frozenset({('trusted', 'coupons', 'source_system')}))
```

Confronto com o SQL compilado dessas amostras (`compiled-samples.txt`):

```text
stg_retail__goods_receipt_items
select * from "warehouse_db"."raw"."goods_receipt_items"
id                                        as goods_receipt_item_id,
select * from renomeado
delivery_events
from "warehouse_db"."staging"."stg_retail__delivery_events"
union all
from "warehouse_db"."trusted"."legado__delivery_events"
delivery_event_id,
shipment_id,
scd_coupon
select * from "warehouse_db"."trusted"."coupons"
rejected_shipment_deliveries
shipment_id,
from "warehouse_db"."trusted"."shipments"
```

Nessas amostras, o identificador é referência/renome, o snapshot usa `select *`
e a união de `delivery_events` leva o mesmo texto nos dois ramos. O arquivo de
staging legado não tem coluna com descrição herdada para amostrar. Também foram
conferidos `source_system`, os quatro metadados `dbt_*`, o par da ponte de
`order_items` e a exclusão de `event_sequence`/`ingested_at` da herança da ponte.
A ressalva de grão das medidas está em RVL3-03, mesmo com o valor transportado.

Amostras manuais adicionais: P01 (`is_realised`, pedidos distintos por origem e
pedido), P02 (receita/pedidos), P04 (coorte da estreia e janela de 90 dias), P09
histórica (somente autorizações), P10 (captura repetida entre motivos), P13
(remessas com item aceito), `payment_transactions` (tipo e sucesso),
`shipments.delivered_at` (último evento de entrega) e
`support_tickets.hours_to_resolution` (primeira resolução). Não apareceu
contradição adicional nessas amostras. Os 39 textos de PK do diff identificam a
entidade correspondente; não alteram tipo, identidade ou chave.

**Domínio e dono.** Conferidos os 25 domínios de analytics e os 16 de consumption:
os nove domínios de origem, `transversal` para calendário/geografia e `legado`
para infraestrutura/medidas do legado correspondem à regra da Governança.
`CONDUCTS` e `DECLARED` cobrem os modelos não gerados que precisam de derivação;
`legacy_order_totals_divergence` tem declaração manual em `_medidas__models.yml`.
Não há `domain_reason` no conjunto atual nem domínio final divergente que
exija a exceção. Ressalva nominal: `rejected_shipment_deliveries` aponta para
`delivery_events` em `CONDUCTS`, embora selecione remessas de `shipments`;
ambas as tabelas são de `logistica`, portanto não há erro no domínio produzido
hoje. O vínculo nominal merece confirmação se esses domínios forem separados.

O `owner` efetivo é `data_custodian` nos 199 nós. A configuração é herdada dos
blocos de models/snapshots/seeds; “por camada” descreve a herança, não nove
repetições literais no YAML. A declaração manual preexistente de owner em `_medidas__models.yml`
não contradiz o valor herdado.

**Catracas.** Executei as duas funções de teste de teto de `33d6451` diretamente,
com o inventário somente leitura do banco e o manifest reconstruído, e injetei
124/126 no contador trusted. Saída:

```text
CATRACAS {'undescribed_raw': 0, 'undescribed_raw_legacy': 0, 'undescribed_staging': 5, 'undescribed_trusted': 125, 'undescribed_analytics': 0, 'undescribed_consumption': 0, 'undescribed_quarantine': 5, 'undescribed_snapshots': 6, 'undescribed_governance': 0}
CONTRAPROVA -1 ['trusted: 124 colunas sem descrição — melhorou: baixe o teto de 125 para 124']
CONTRAPROVA 1 ['trusted: 126 colunas sem descrição, acima do teto 125']
DOMAIN_OWNER [('staging', Counter({'data_custodian': 77})), ('trusted', Counter({'data_custodian': 75})), ('analytics', Counter({'data_custodian': 25})), ('consumption', Counter({'data_custodian': 16})), ('quarantine', Counter({'data_custodian': 2})), ('snapshots', Counter({'data_custodian': 4}))]
```

Logo, os tetos conferem no inventário atual e a comparação falha nos dois sentidos.
Isso não prova a semântica dos textos: RVL3-01 a RVL3-06 passam por uma catraca que
só exige a existência de descrição.

**Documentação e pendências.** Governança §5.1 e Dicionário §1/§2 correspondem aos
locais de declaração, `description_from`, `description_reason`, transporte,
`domain`, `owner` e `persist_docs` examinados, sujeitos às limitações acima.
A regra geral dos textos de medidas não é satisfeita semanticamente pelos casos
identificados na tabela. A frase do Dicionário sobre escrever à mão só o calculado
é uma simplificação: a Governança também permite a exceção justificada no transporte.

D66 permanece deliberadamente pendente. A descrição da P13 em `33d6451` diz
explicitamente que conta remessas entregues com pelo menos um item aceito.
Conferi as saídas históricas locais referidas pela pendência:

```text
# evidence/20261023/q1_p13_shipment_universe.out.txt, bi-como-codigo
 source_system | trusted_delivered
 legacy        |               144
 retail        |              3166
 source_system | fact_delivered
 legacy        |            132
 retail        |           3166
 trusted_only | fact_only
           12 |         0

# evidence/20261103/q18_p13_rejected_parent.out.txt, bi-como-codigo
 level |   source_table   | rejection_origin | records
     0 | shipment_items   | parent_rejected  |      17
     1 | order_items      | parent_rejected  |      17
     2 | product_variants | parent_rejected  |       6
     3 | products         | own_invalid      |       4
 excluded_shipments | with_order_in_trusted | order_without_trusted_items
                 12 |                    12 |                           8
```

São trechos das saídas arquivadas, não nova medição do banco histórico. Sustentam
os números e o escopo da D66; o 8% é arredondamento de 12/144.

D67 em `33d6451` está corretamente aberta: a P09 filtra autorizações enquanto
`captured_amount` só nasce em capturas bem-sucedidas. O texto da coluna declara
que é sempre zero. A saída arquivada de
`evidence/20261104/q22_h4_stage_1_5_checks.out.txt` registra:

```text
 captured_in_stage_1_5_view | captured_in_fact
                36719765.95 |      36719765.95
 na_view |   na_fato
       0 | 36719765.95
```

Isso corrobora a divergência e o total capturado histórico. As 538 linhas aparecem
no inventário/exportação de 22/10; **não reconfirmei a contagem em 03/11, o total
autorizado de R$ 39.254.835,44 nem as contagens 3.302/3.826 daquela data**. A base
foi regenerada depois. A correção `94e0d09` pertence ao lote 1 já fechado e não é
reaberta aqui. Não encerro D66 ou D67 nesta revisão.

**Regressões executadas.** No checkout `d7d7f44`, os dois comandos pedidos saíram
com código zero. Trechos literais:

```text
$ make check-offline
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 664 citações de ADR — nada quebrado
817 passed, 188 deselected in 149.14s (0:02:29)
check-offline: as três etapas passaram

$ make secrets-history
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os testes do motor na cópia histórica também passaram:

```text
$ PYTHONPATH=/tmp/rvl3-33d6451/src .venv/bin/pytest -q -p no:cacheprovider \
    /tmp/rvl3-33d6451/tests/test_descricao_derivada.py \
    /tmp/rvl3-33d6451/tests/test_classificacao_derivada.py
25 passed in 2.47s
```

**Não verificado:** não rodei `make check` em nenhuma ponta, não reconstruí o
warehouse de `33d6451`, não validei todos os 247 textos-raiz individualmente e
não medi uma nova execução de `persist_docs`. Não testei outra versão de
sqlglot; as sondas usam 30.18.0. A compilação integral histórica ficou limitada
pelos erros relatados; a comparação usou a reconstrução explicitada. Não
reproduzi os avisos de `legacy_classifications` no manifest de `1e197ac`, nem
reexecutei ingestão para provar a recriação de fontes pelo Airbyte. As consultas
não alteraram dados, memória do legado, concessões ou estado do DAG.


## Rodada 2 — lote 3

Revisão de `d7d7f44..ed08efa`, oito commits, com checkout em
`ed08efa7691d4e61897a435ebf3c8379c98dafa6`, em 05/11/2026. **Parecer técnico,
sem aceite nem poder de aprovação.** RVL3-10 foi incluído conforme a decisão do
Owner. Nenhuma correção foi implementada. As situações abaixo ficam para o
autor/Owner. **O lote 3 ainda não pode ser encerrado tecnicamente.**

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-2-01 | `src/mvp_ed1/models/descriptions.py:273–279` | **RVL3-01 não está fechado: igualdade com o texto atual da folha não recupera proveniência.** A sonda original de `quantity * 100` é detectada, mas um texto herdado de dois saltos acima vira `written` sem problema quando a folha imediata já recebeu o texto novo. Duas referências equivalentes ao mesmo `doc()` com aspas diferentes também escapam. É necessário distinguir texto persistido por herança de raiz efetivamente revista; comparar apenas strings não fecha o defeito original. Evidência R2-A. | `bloqueante` | **Corrigido com proveniência, não com string.** `dbt/_descricoes_herdadas.json` — gerado por `make catalog`, conferido pelo `--check` — registra todo texto que a derivação escreveu num `.yml` à mão (hoje 1089 colunas em 87 modelos). Coluna que deixou de transportar e ainda guarda, sem motivo, o texto que o registro diz herdado é problema, venha ele de um salto ou de dois; a comparação normaliza espaços e as aspas de `doc()`. A entrada com problema fica no registro até ser resolvida, para que uma geração não apague a prova. A igualdade com a folha continua como segunda rede. Testes `test_o_registro_do_herdado_pega_o_texto_de_dois_saltos_e_o_doc_de_outras_aspas` e `test_o_registro_guarda_o_que_a_derivacao_escreveu_no_yml_a_mao`; contraprova com o código de `ed08efa`: `TypeError` (o registro não existia). |
| RVL3-2-02 | `src/mvp_ed1/models/transport.py:145–164` | **RVL3-02 não está fechado: uma subunião de constantes apaga o tipo resolvido.** `BIGINT UNION ALL (0::real UNION ALL 1::double precision)` fica `Carry`, porque os dois tipos de constantes viram `type=None`. No PostgreSQL, `9007199254740993` sai `9007199254740992`. A recusa funciona no caso original simples, mas não nesta composição. Preservar/resolver o tipo de saída da subunião ou recusar a herança quando não for possível prová-lo. Evidência R2-B. | `bloqueante` | **Corrigido.** A subunião só de constantes guarda **todos** os tipos que viu (`"DOUBLE PRECISION\|REAL"`), e a união de fora os confere com as folhas. Sua composição `BIGINT ∪ (0::real ∪ 1::double precision)` dá `union_coercion`; `(-1 ∪ null)` continua transportando. Caso no mesmo teste da união; contraprova com `transport.py` de `ed08efa`: `Carry == Computed`. |
| RVL3-2-03 | `dbt/models/analytics/_analytics__models.yml`, entradas `dim_customer`, `dim_coupon`, `dim_support_agent` e `fact_shipment_item.quantity_ordered` | **RVL3-03 não está fechado: a revisão de medidas repetidas deixou as dimensões SCD de fora.** As cinco medidas acumuladas corrigidas nos snapshots continuam aditivas nas dimensões: duas de cliente, duas de cupom e `handled_event_count`. Seus SQLs juntam **todas** as versões a métricas atuais de `trusted`, sem `is_current`; uma versão por entidade hoje não prova o grão futuro. `handled_ticket_count`, tanto no snapshot quanto na dimensão, restringe atendentes, mas não versões. `quantity_ordered` da fato de remessa também repete o total da linha do pedido sem explicar esse grão: soma 15.534, contra 13.278 reduzindo à linha do pedido. Completar os textos próprios e os motivos no destino. Evidência R2-C. | `bloqueante` | **Corrigido.** As dimensões SCD repetem o valor atual de `trusted` em cada versão (`dim_*` junta `versoes` a `atual`): `dim_customer.order_count`/`lifetime_net_revenue_amount`, `dim_coupon.redemption_count`/`redeemed_discount_amount` e `dim_support_agent.handled_event_count` dizem agora "Aditiva entre … **só na versão vigente** (`is_current`)", e `handled_ticket_count` "Não aditiva entre atendentes nem entre versões", todos com motivo. `fact_shipment_item.quantity_ordered`: "Não aditiva entre itens de remessa — … repetida em cada item de remessa da linha", com motivo. |
| RVL3-2-04 | `dbt/snapshots/_snapshots.yml:14,19,126,131,257` | **Os novos textos dão uma leitura temporal que os snapshots não garantem.** “Até esta versão”/“numa mesma data de vigência” não informa que os acumulados ficam congelados na **captura que abriu a versão**: nenhum entra em `check_cols`. Novo resgate sem mudança de atributo não atualiza o acumulado nem abre versão; escolher versões vigentes na mesma data pode reunir acumulados capturados em datas diferentes. Explicitar essa limitação, sem alterar a estratégia SCD. As duas descrições de cliente também perderam o filtro de pedidos **realizados** presente na raiz e no SQL. Evidência R2-C. | `bloqueante` | **Corrigido.** Os seis acumulados dos snapshots (inclui agora `scd_support_agent.handled_ticket_count`) dizem "**Não soma entre versões** — … na captura que abriu esta versão; fica congelado enquanto a versão vale — a coluna não está em `check_cols`, e uma mudança só dela não a atualiza nem abre versão. O valor atual está em `trusted.…`". Os de cliente voltaram a dizer pedidos **realizados**. A estratégia SCD não mudou. |
| RVL3-2-05 | `src/mvp_ed1/models/sensitivity.py:326–341` | **RVL3-07 foi atendido apenas parcialmente.** A comparação por substring aceita `where coupon_id < 0` acrescentado antes de `endsnapshot`: `stale_nodes=[]`, `--check=0`. No sentido oposto, um modelo com CRLF recém-processado pelo dbt é recusado: o manifest conserva `\r\n`, mas `read_text()` normaliza o disco para `\n`. Comparar o bloco inteiro do snapshot e normalizar as quebras dos dois lados. Evidência R2-D. | `ajuste` | **Corrigido.** `stale_nodes` compara o miolo do bloco `{% snapshot %}` do disco com o `raw_code`, por igualdade, e normaliza CRLF/CR dos dois lados, lendo o disco em bytes. Seu `where coupon_id < 0` acrescentado agora acusa; o manifest com `\r\n` não acusa mais. Casos no teste do manifest atrasado; contraprova com `ed08efa`: `assert [] == ['scd']`. |
| RVL3-2-06 | `dbt/models/analytics/_analytics__models.yml:1603,2257`; commit `636895e` | **Regressão da correção de RVL3-10 em duas declarações alheias.** `fact_shipment_item.quantity_shipped` e `fact_coupon_redemption.coupon_discount_amount` receberam o motivo “aditiva, porque é delta assinado (RVL3-10)”. São quantidade expedida e desconto concedido, não o delta assinado de estoque. O próprio texto de `quantity_delta` está correto; retirar/corrigir os dois motivos copiados indevidamente. Evidência R2-F. | `bloqueante` | **Corrigido** — o erro foi meu: o `sed` do RVL3-10 trocou o motivo em toda linha igual do arquivo. `quantity_shipped` e `coupon_discount_amount` voltaram ao motivo que tinham antes de `636895e`; só `quantity_delta` ficou com o novo. |
| RVL3-2-07 | Limites de `stale_nodes` e da premissa de compilação | **Observação fora da correção direta de SQL:** mudanças em macro e em metadado YAML ainda podem deixar o manifest antigo aceito. Na cópia, trocar `union all` por `union` em `empilhado.sql`, ou mudar a sensibilidade declarada de uma ponte, mantém `--check=0`. A nova função não é um verificador geral de atualidade do projeto. A comparação também só considera nós habilitados que já estão no manifest. A compilação recente continua sendo pré-requisito; não atribuir à guarda garantia maior. Evidência R2-D. | `observação` | **Parcialmente coberto, e o resto declarado.** As macros do projeto entram em `stale_nodes`: o `macro_sql` do manifest tem de estar no arquivo (seu `union all` → `union` em `empilhado.sql` agora acusa; caso de teste). Metadado de `.yml`, macro nova ou apagada e nó ausente do manifest ficam como limite, escrito no docstring de `stale_nodes` e na Governança §5.1 v2.14: a compilação recente continua sendo a premissa, que o `make check` cumpre com o build antes. |
| RVL3-2-08 | `dbt/models/analytics/fact_inventory_movement.sql:123–126` | **Observação fora dos arquivos alterados:** o comentário SQL preexistente ainda chama `quantity_delta` de semiaditiva e proíbe soma temporal, contradizendo o novo YAML correto. Distinguir isso do comentário físico do banco: este último permanecer antigo até o próximo build é esperado e não constitui achado novo. Evidência R2-F. | `observação` | **Corrigido.** O comentário de `fact_inventory_movement.sql` diz agora que `quantity_delta` é aditiva e que semiaditivo é o saldo. Ao editar, `stale_nodes` acusou o modelo até o build — a guarda nova em uso. |

| RVL3-2-09 | `src/mvp_ed1/models/sensitivity.py:321` | **RVL3-09 corrige a quebra de linha, mas introduz outra colisão de cabeçalhos.** A serialização por `"\x1f".join(cabecalho)` não escapa o separador: os cabeçalhos `["a", "b"]` e `["a\x1fb"]` produzem a mesma chave. `load()` devolve as duas colunas antigas enquanto `derive()` direto lê uma coluna nova. Usar codificação inequívoca da lista de campos. É CSV válido, mas fora de `snake_case`; nenhuma seed atual foi identificada como afetada. Evidência R2-D. | `ajuste` | **Corrigido.** O cabeçalho entra na chave como `json.dumps(lista)`, sem separador ambíguo: `["a\x1fb"]` e `["a", "b"]` dão chaves diferentes (caso no teste; contraprova com `ed08efa`: digests iguais). |

### Conferência das dez respostas

“Fechado” abaixo significa que o achado técnico específico foi atendido; não é
aceite da entrega. Cada referência R2 aponta para comando e saída colados adiante.

| Achado original | Resultado desta rodada | Comando/evidência |
|---|---|---|
| RVL3-01 | **Não fechado.** O caso simples é corrigido; persistem os escapes de proveniência e `doc()`. Os dois motivos de P07/P08 são justificados. | `python /tmp/rvl3-r2/drift.py`: `QUANTITY_X100 … não transporta mais`; `DOIS_SALTOS_ISOLADO … written PROBLEMAS []`; `DOC_ASPAS … PROBLEMAS []` (R2-A). |
| RVL3-02 | **Não fechado.** Recusa a coerção simples; perde o tipo na união aninhada. Inteiro com `numeric/decimal` exato não estreitou os valores extremos/escala testados. | `python /tmp/rvl3-r2/union.py` e `ro.sh …/oracle.sql`: `ANINHADA … Carry`; saída numérica arredondada (R2-B). |
| RVL3-03 | **Não fechado.** Os dois fatos apontados originalmente foram corrigidos e os YAMLs dos snapshots coexistem corretamente; faltam medidas das dimensões e precisão temporal nos novos textos. | `baseline.py`, `ro.sh …/oracle.sql`, `…/grain.sql`, `…/grain_more.sql` (R2-C). |
| RVL3-04 | **Fechado.** P16 explicita a janela fechada, o grão e a duplicação entre categorias. | `python /tmp/rvl3-r2/texts.py`; SQL com `is_repeat_window_closed`, `classificado` por categoria e `count(*) filter` (R2-E). |
| RVL3-05 | **Fechado.** P11 descreve a média de todos os movimentos com custo, sem recorte trimestral no CTE `saldo`. | `texts.py`; `round(b.quantity_on_hand * avg(m.unit_cost), 2)` e `and m.unit_cost is not null` (R2-E). |
| RVL3-06 | **Fechado.** Os sete textos de `purchase_order_items` delimitam recebimentos concluídos e a derivação propaga o texto à fato. | `texts.py`; `where gr.goods_receipt_status = 'completed'`; `baseline.py`: `ARQUIVOS_DIFERENTES []` (R2-E). |
| RVL3-07 | **Não fechado integralmente.** A edição de modelo comum é recusada; há falso negativo em snapshot e falso positivo CRLF. Macros/YAML permanecem limite separado. | `freshness.py`: `RETORNO_SQL 1`, `RETORNO_SNAPSHOT 0`; `parse_check.py`: `STALE_PARSE ['crlf']` (R2-D). |
| RVL3-08 | **Fechado.** As sete descrições de seeds já estão fisicamente no banco. O teto trusted de 125 coincide agora com as ausências físicas; a distinção catálogo/comentário na Governança está correta. | `ro.sh …/oracle.sql`; `check_types.py`: `DIFERENCAS_TRUSTED []` (R2-G). |
| RVL3-09 | **Não fechado integralmente.** A quebra de linha original é corrigida, mas a nova serialização dos campos permite colisão e reaproveita cache incorreto. | `freshness.py` e `csv_collision.py`: `CHAVE_IGUAL True`, `CACHE` diferente de `SEM_CACHE` (R2-D). |
| RVL3-10 | **Fechado quanto ao texto solicitado de `quantity_delta`.** A medida é delta assinado aditivo; o commit introduziu a regressão separada RVL3-2-06. Nenhum build foi feito para atualizar o comentário físico. | `texts.py`, `ro.sh …/grain_more.sql`: `deltas_divergentes=0`; diff de `636895e` (R2-F). |

### Evidências da rodada 2

Scripts e saídas desta rodada: `/tmp/rvl3-r2`. Python usado nos comandos abaixo:
`.venv/bin/python`, com `PYTHONDONTWRITEBYTECODE=1`. `derive()` e `derive_texts()`
rodaram em memória; `--check` das contraprovas rodou somente na cópia sob `/tmp`.
Todas as consultas passaram pelo invólucro autorizado:

```sh
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh arquivo.sql
```

Saída inicial de `oracle.sql`:

```text
 transaction_read_only
-----------------------
 on
(1 row)
```

**R2-A — herança que deixa de transportar.**
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/drift.py`:

```text
QUANTITY_X100 Computed(kind='mul', shape=None, type=None) ['stg_retail__order_items.quantity: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, ou declare `description_reason`']
DOC_ASPAS written "{{ doc('on_time_delivery') }}" PROBLEMAS []
DOIS_SALTOS_ISOLADO imediata= 'Valor total do pedido; reconcilia os demais campos. Texto revisado.' destino= 'Valor total do pedido; reconcilia os demais campos.' written PROBLEMAS []
```

A primeira sonda troca o SQL compilado de `stg_retail__order_items.quantity`
em memória e refaz a derivação completa. A última usa o helper `_textos` dos
testes com `raw.orders.total_amount → staging.a.v → trusted.b.v`: a raiz é
revisada, `a` transporta e recebe o texto novo, `b` passa a `Computed('mul')`,
mas conserva no YAML o texto antigo. A folha de `b` é apenas `a.v`. Não há
`description_reason`. A saída prova que o texto antigo é aceito como raiz.

Na sonda de `doc()`, a folha usa `{{ doc("on_time_delivery") }}` e o destino
usa `{{ doc('on_time_delivery') }}`. São referências Jinja válidas ao mesmo
bloco, mas a igualdade literal não reconhece a coincidência. Não foi necessária
mudança do conteúdo do glossário para escapar.

A tentativa adicional sobre `trusted.order_items` **não** escapou sem ajustar a
ponte: havia uma segunda folha legada ainda com o texto antigo, e ela fez a guarda
acusar a coluna, além de acusar a ponte desatualizada. Esse resultado também está
em `drift.txt`; não o apresento como escape em produção. O caso de dois saltos
acima isola a condição que o algoritmo deixa passar.

Os motivos adicionados às colunas chamadas P07/P08 na resposta são coerentes:
`docs/glossario_de_negocio/entrega_no_prazo.md` define tanto `is_on_time` quanto
`on_time_count / delivered_count`; `ciclo_de_entrega.md` define a duração do
pedido e sua média sobre ciclos fechados. Os SQLs das views reduzem a fato a
remessas/pedidos antes da taxa/média. Portanto, usar o mesmo bloco com motivo
explícito não mascara um cálculo diferente nesses dois casos. Os cabeçalhos SQL
identificam essas views como P13/P14; foram conferidas pelos nomes dos modelos.

**R2-B — resolução de tipo e limite desconhecido.**
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/union.py`, trechos:

```text
SQL_TYPE FLOAT DOUBLE PRECISION
SQL_TYPE DOUBLE DOUBLE PRECISION
SQL_TYPE DATETIME TIMESTAMPTZ
SQL_TYPE VARCHAR(80) VARCHAR(80)
SQL_TYPE NUMERIC(14, 2) DECIMAL(14, 2)
SQL_TYPE BOOLEAN BOOLEAN
UNION 'BIGINT' 0::real {'x': Computed(kind='union_coercion', shape=None, type=None)}
UNION 'DOUBLE PRECISION' 0::double precision {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
UNION 'DOUBLE' 0::double precision {'x': Computed(kind='union_coercion', shape=None, type=None)}
UNION 'TIMESTAMP WITH TIME ZONE' null::timestamptz {'x': Computed(kind='union_coercion', shape=None, type=None)}
UNION 'TIMESTAMPTZ' null::timestamptz {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
UNION 'VARCHAR(80)' null::text {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
UNION 'DATE' null::timestamp {'x': Computed(kind='union_coercion', shape=None, type=None)}
UNION 'TIMESTAMP' null::timestamptz {'x': Computed(kind='union_coercion', shape=None, type=None)}
UNION 'BOOLEAN' false {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
UNION 'DECIMAL(14, 2)' 0::numeric(4,3) {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
UNION 'BIGINT' 0::numeric(2,1) {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
ANINHADA {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
```

`_sql_type` já passa o tipo SQLAlchemy pelo sqlglot. Assim, os falsos negativos
de equivalência ao injetar manualmente `DOUBLE` ou `TIMESTAMP WITH TIME ZONE`
não demonstram regressão nos tipos hoje fornecidos por essa função. Datas versus
timestamps e timestamps com versus sem fuso são recusados conservadoramente;
booleanos canônicos e varchar/text são aceitos. Não encontrei perda no caso
direto de inteiro com `NUMERIC/DECIMAL`: o resultado comum não impõe o typmod
estreito do outro ramo. O rótulo `exato` inclui também `MONEY`, que não deve ser
confundido com a conclusão específica para numeric/decimal.

A contraprova bloqueante é esta expressão, analisada por `carries_by_output`:

```sql
select x from wh.raw.a
union all (select 0::real union all select 1::double precision)
```

A folha foi declarada `BIGINT`. `ro.sh /tmp/rvl3-r2/oracle.sql` executa o
mesmo formato com o valor da folha como constante, e também os controles:

```text
  caso  |       tipo       |         valor
--------+------------------+-----------------------
 nested | double precision | 9.007199254740992e+15
 nested | double precision | 0
 nested | double precision | 1
(3 rows)

      caso       |  tipo   |        valor
-----------------+---------+---------------------
 integer_numeric | numeric | 9223372036854775807
 integer_numeric | numeric | 0.1
(2 rows)

      caso      |  tipo   |      valor
----------------+---------+-----------------
 numeric_scales | numeric | 123456789012.12
 numeric_scales | numeric | 0.123
(2 rows)
```

Entradas: `9007199254740993::bigint`; `9223372036854775807::bigint` com
`0.1::numeric(2,1)`; `123456789012.12::numeric(14,2)` com
`0.123::numeric(4,3)`. A sonda original com `16777217::bigint` e `0::real`
ainda produz `1.6777216e+07` no banco; agora o motor a classifica corretamente.
O erro permanece na subunião cujos tipos distintos são apagados.

O limite de folha desconhecida alcança modelos reais, especialmente as pontes
legadas e colunas calculadas a montante. Cruzamento com `pg_attribute`, sem
usar o banco para alterar a derivação:

```text
$ .venv/bin/python /tmp/rvl3-r2/check_types.py
CARRY_MULTIFOLHA_COM_TIPO_DESCONHECIDO 321
TIPOS_FISICOS_NAO_PRESERVADOS []
EXEMPLO ('model.mvp_ed1.order_items', 'quantity', {'INT'})
```

Esse inventário cobre saídas `Carry` com mais de uma folha; não prova todos os
ramos constantes internos. Não encontrei, nos tipos físicos dessas folhas,
uma coerção incompatível atual. Isso não torna seguro ignorar desconhecidos em
consultas futuras. A exceção declarada de literal de preenchimento continua a
não distinguir literal de negócio; não reabro a decisão N45 nesta rodada.

**R2-C — grão, snapshots e composição dos YAMLs.**
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/baseline.py`:

```text
STALE []
NOS 199 COLUNAS 2983
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
OBSOLETOS []
SNAPSHOTS_DISCO [('scd_product', '_derived.yml'), ('scd_coupon', '_snapshots.yml'), ('scd_customer', '_snapshots.yml'), ('scd_support_agent', '_snapshots.yml')]
MEDIDA analytics.dim_support_agent.handled_event_count 'Aditiva — eventos de chamado registrados pelo atendente.'
MEDIDA analytics.dim_coupon.redemption_count 'Aditiva — número de resgates do cupom; zero quando ele nunca foi usado.'
MEDIDA analytics.dim_coupon.redeemed_discount_amount 'Aditiva — desconto total concedido nos resgates do cupom; zero quando ele nunca foi usado.'
MEDIDA analytics.dim_customer.order_count 'Aditiva entre clientes — número de pedidos realizados do cliente; zero para quem nunca comprou.'
MEDIDA analytics.dim_customer.lifetime_net_revenue_amount 'Aditiva entre clientes — receita líquida dos itens de todos os pedidos realizados do cliente; zero para quem nunca comprou.'
```

`render_files` retornou conteúdo idêntico ao disco; não o gravou. As entradas dos
três snapshots saíram do gerado e são mantidas no arquivo à mão; `scd_product`
permanece no gerado. Não há entrada duplicada ou remoção pendente. Os três avisos
preexistentes de `legacy_classifications` continuam, sem problema de derivação.

Os SQLs de `dim_customer`, `dim_coupon` e `dim_support_agent` têm a mesma forma:
`versoes` lê o snapshot inteiro; `atual` lê a entidade de trusted; a projeção leva
as medidas de `a`, e a junção é pela origem/identidade, sem filtrar versão atual.
`ro.sh …/oracle.sql`, `…/grain.sql` e `…/grain_more.sql`:

```text
      modelo       | linhas | entidades
-------------------+--------+-----------
 dim_customer      |   1574 |      1574
 dim_support_agent |      8 |         8
 dim_coupon        |     19 |        19
(3 rows)

           caso            | linhas | soma | por_cliente
---------------------------+--------+------+-------------
 dim_customer_duas_versoes |      2 |    2 |           1

              caso              | linhas | soma | por_agente
--------------------------------+--------+------+------------
 dim_support_agent_duas_versoes |      2 |    4 |          2

          caso           | linhas | soma | por_cupom
-------------------------+--------+------+-----------
 dim_coupon_duas_versoes |      2 |   80 |        40

    entidade    | soma | uma_vez
----------------+------+---------
 shipment_items |  879 |     437
 ticket_events  |   63 |      14

      medida      | soma  | por_linha_pedido
------------------+-------+------------------
 quantity_ordered | 15534 |            13278
```

As três sondas de duas versões usam CTE com uma entidade real e duas linhas
sintéticas de versão, reproduzindo a junção do SQL. **Não são contagens de
versões existentes, nem foram inseridas versões no banco.** Exemplificam o
fan-out que os SQLs permitem. A contagem atual isolada havia ocultado esse caso.
As somas de fatos são medições das relações existentes. Os dois novos textos
de `failed_attempt_count` e `reopening_count` descrevem corretamente a redução
necessária; `quantity_ordered` ainda não explica que é quantidade da linha do
pedido repetida entre remessas, e não quantidade desta caixa.

Também conferi medidas sem a palavra “Aditiva”: `handled_ticket_count` precisa
da restrição de versões além da de atendentes; as quantidades/valores por linha
em `fact_purchase_order_item` e `fact_sales_order_item` mantêm o grão; os totais
de pedido de `fact_coupon_redemption` têm relação um a um com resgate. O índice
`uq_coupon_redemptions_pedido` declara um resgate por pedido, e a consulta atual
retornou `resgates_com_pedido_repetido=0`. Durações de remessa/chamado continuam
repetidas nos fatos, mas seus textos não autorizam soma; os comentários SQL
orientam reduzir ao pedido/chamado antes da média. Não atribuo a esta rodada uma
prova universal de todos os textos de catálogo.

Para a temporalidade, os três snapshots usam `strategy='check'` e excluem os
acumulados de `check_cols`. Os macros instalados em
`.venv/lib/python3.11/site-packages/dbt/include/global_project/macros/materializations/snapshots/`
(`strategies.sql`, `helpers.sql`) formam `row_changed` apenas com essas colunas;
sem mudança, não há inserção nem atualização de versão. A sonda de condição
sobre `scd_coupon`, mudando só a contagem em um CTE, retornou:

```text
 acumulado_congelado | acumulado_novo | cria_versao
---------------------+----------------+-------------
                  40 |             41 | f
(1 row)
```

Isso é contraprova da interpretação de acumulado atualizado em toda a vigência,
não execução de snapshot. O dado é observado ao abrir a versão; não é total
histórico reconstruído para qualquer data entre `dbt_valid_from` e `dbt_valid_to`.
Os comentários dos próprios SQLs das dimensões reconhecem o congelamento.
Além disso, `trusted.customers` agrega somente `where o.is_realised`, condição
que os novos textos de cliente precisam conservar.

**R2-D — atualidade e CSV.**
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/freshness.py` usa
cópia dos arquivos dbt e do manifest em `/tmp/rvl3-r2/copy`, com `ROOT`, `DBT`,
`MANIFEST` e `CACHE` apontados para lá. Trechos literais:

```text
BASE []
MODEL_ALTERADO ['stg_retail__order_items']
manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (stg_retail__order_items); rode `make dbt-build` antes — nenhum arquivo é tocado
RETORNO_SQL 1
EPHEMERAL_IDENTICO []
EPHEMERAL_ALTERADO ['stg_retail__order_items']
DISABLED_FORA_DOS_NOS []
SNAPSHOT_WHERE_NOVO []
classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
RETORNO_SNAPSHOT 0
```

A alteração de snapshot acrescenta literalmente `where coupon_id < 0` antes de
`{% endsnapshot %}`. O SQL antigo inteiro ainda é substring do arquivo novo;
a guarda não detecta que o snapshot passou a selecionar outra população.

A primeira sonda CRLF, sobre um manifest LF anterior, passou; por isso fiz
**parse real**, sem conexão ao banco, de um projeto mínimo em `/tmp`:

```sh
DBT_SEND_ANONYMOUS_USAGE_STATS=false .venv/bin/dbt parse \
  --project-dir /tmp/rvl3-r2/parse --profiles-dir /tmp/rvl3-r2/parse \
  --no-partial-parse
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/parse_check.py
```

```text
Running with dbt=1.12.3
Registered adapter: postgres=1.11.0
Performance info: /tmp/rvl3-r2/parse/target/perf_info.json
PARSE_NOS [('eph', 'ephemeral'), ('crlf', 'view'), ('s', 'snapshot')]
DISABLED ['model.probe.disabled']
STALE_PARSE ['crlf']
RAW eph "{{ config(materialized='ephemeral') }}\nselect 1 as x"
RAW crlf '{% set x = 1 %}\r\nselect {{ x }} as x'
RAW s "{{ config(target_schema='probe',unique_key='x',strategy='check',check_cols=['x']) }}\nselect 1 as x"
```

O snapshot mínimo usa `{%- snapshot s -%}`/`{%- endsnapshot -%}`; a remoção de
whitespace Jinja não causou alarme. O modelo ephemeral idêntico também não.
O disabled fica em `manifest.disabled`, não em `nodes`, e é corretamente
ignorado enquanto desabilitado; ativação posterior por configuração ainda
exige parse/compilação. O CRLF falha mesmo após parse novo e, portanto, pedir
outro build sem normalizar a comparação não resolve sua causa.

Limites separados, `python /tmp/rvl3-r2/extra_freshness.py`:

```text
classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
MACRO_UNION_ALL_PARA_UNION [] RETORNO 0
classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
YML_SENSITIVITY [] RETORNO 0
```

A primeira mudança troca o operador da macro `empilhado`; a segunda troca o
primeiro `sensitivity: internal` por `personal` em `_pontes__models.yml`, cujo
manifest permanece anterior. Ambas são restauradas na cópia. Não são alegação
de que `make check` completo, com build prévio, aceite essas mudanças. Outra
precisão sobre a resposta: `main()` chama `load()` **antes** de `stale_nodes`;
a recusa precede a escrita do catálogo, mas não necessariamente a derivação
nem a escrita do cache.

CSV, mesma execução de `freshness.py`:

```text
CSV b'"a\nb",c\n1,2\n' ['a\nb', 'c'] 87ed40bff950452930913d1f624ce5a8833d2d376783f6b8e527c5162fa7609d
CSV b'"a\nc",c\n1,2\n' ['a\nc', 'c'] 0e95e1239b7be659eb1bfbee2a264ac7561f7da7ef56aaaf5ad5b51db72e2203
CSV b'"a\r\nb",c\r\n1,2\r\n' ['a\r\nb', 'c'] 70c86e0339412b57b55c748146687b68bb2d07c2ce2be6d9f08512746878ab9d
CSV b'a,b\n1,2\n' ['a', 'b'] 22b034503554245984b8ea2daa58e5ee2812c031ead54085482d93897b19c184
CSV b'a,b\n9,8\n' ['a', 'b'] 22b034503554245984b8ea2daa58e5ee2812c031ead54085482d93897b19c184
```

As duas funções usam `csv.reader` com UTF-8 e `newline=""`. O digest serializa
os campos do primeiro registro; não perde a quebra entre aspas. CSV vazio tem
tratamento distinto (`[]` no digest, `StopIteration` na leitura), mas não é uma
seed válida com cabeçalho; não demonstrou cache incorreto.


A equivalência da **leitura** não basta: a serialização com separador sem escape
introduz uma colisão nova. `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python
/tmp/rvl3-r2/csv_collision.py` usa manifest mínimo de seed, cache e CSV apenas
em `/tmp/rvl3-r2/csv-collision`. O manifest declara previamente as colunas das
duas variantes, para isolar a chave; troca-se `a,b\n1,2\n` por
`"a\x1fb"\n1\n`. Saída literal:

```text
HEADER_ANTES ['a', 'b']
HEADER_DEPOIS ['a\x1fb']
CHAVE_IGUAL True
CACHE {'seed.p.x': {'a': 'internal', 'b': 'internal'}}
SEM_CACHE {'seed.p.x': {'a\x1fb': 'internal'}}
```

`\x1f` é o caractere separador de unidade dentro do nome, não os quatro
caracteres barra/x/1/f. Os dois registros são aceitos por `csv.reader`, mas não
representam o mesmo cabeçalho. Tal como a sonda original com quebra de linha,
o nome adversarial não segue a convenção de identificadores do projeto. Não
confundir a ausência de caso atual afetado com equivalência do digest.

**R2-E — textos de P16, P11 e recebimentos.**
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r2/texts.py`, trechos de
SQL impressos pelo script:

```text
consumption/repeat_purchase_rate_after_support.sql:37 where f.is_realised
consumption/repeat_purchase_rate_after_support.sql:38 and f.is_repeat_window_closed
consumption/repeat_purchase_rate_after_support.sql:100 count(*) filter (where cl.has_post_order_repeat)    as repeat_order_count,
consumption/repeat_purchase_rate_after_support.sql:116 group by 1, 2, 3, 4, 5, 6
consumption/inventory_turnover_by_sku_and_warehouse.sql:56 round(b.quantity_on_hand * avg(m.unit_cost), 2) as inventory_value_amount
consumption/inventory_turnover_by_sku_and_warehouse.sql:62 and m.unit_cost is not null
trusted/purchase_order_items.sql:23 sum(gri.quantity_received)                  as quantity_received,
trusted/purchase_order_items.sql:24 sum(gri.quantity_received * gri.unit_cost)  as received_cost_amount,
trusted/purchase_order_items.sql:25 min(gr.received_at)                         as first_received_at,
trusted/purchase_order_items.sql:26 max(gr.received_at)                         as last_received_at
trusted/purchase_order_items.sql:31 where gr.goods_receipt_status = 'completed'
trusted/purchase_order_items.sql:46 coalesce(round(r.received_cost_amount, 2), 0)   as received_cost_amount,
trusted/purchase_order_items.sql:47 i.quantity_ordered - coalesce(r.quantity_received, 0) as quantity_outstanding,
trusted/purchase_order_items.sql:51 coalesce(r.quantity_received, 0) >= i.quantity_ordered      as is_fully_received,
trusted/purchase_order_items.sql:52 coalesce(r.quantity_received, 0) = 0                        as is_not_received,
```

O texto de P16 agora começa “**Não aditiva entre categorias** — pedidos com
janela fechada…” e explica o pedido em duas categorias; o CTE `com_chamado`
distingue origem/pedido/categoria e `classificado` mantém essa multiplicidade.
P11 diz “todos os movimentos … que têm custo, de qualquer tipo e de todo o
período”, exatamente o CTE `saldo`; `where m.is_sale` pertence ao CTE `saidas`.
Nos sete campos de recebimento, o filtro está antes das somas/mínimo/máximo;
zero/nulo, pendência e marcas derivadas correspondem às expressões acima.
A conferência em memória não pediu alteração no texto propagado à fato.

**R2-F — decisão de RVL3-10 e regressão.** `texts.py`:

```text
fact_inventory_movement.quantity_delta '**Aditiva** — variação assinada do saldo: positiva na entrada, negativa na saída; a soma num período é a variação líquida do estoque nele.' MOTIVO 'diz a aditividade da medida nesta fato, que o texto herdado não diz; aditiva, porque é delta assinado (RVL3-10)'
fact_shipment_item.quantity_shipped '**Aditiva** — unidades que viajaram nesta caixa.' MOTIVO 'diz a aditividade da medida nesta fato, que o texto herdado não diz; aditiva, porque é delta assinado (RVL3-10)'
fact_coupon_redemption.coupon_discount_amount '**Aditiva** — desconto efetivamente concedido.' MOTIVO 'diz a aditividade da medida nesta fato, que o texto herdado não diz; aditiva, porque é delta assinado (RVL3-10)'
trusted/inventory_movements.sql:46 quantity_delta,
trusted/inventory_movements.sql:47 case when quantity_delta > 0 then quantity_delta else 0 end     as quantity_in,
trusted/inventory_movements.sql:48 case when quantity_delta < 0 then -quantity_delta else 0 end    as quantity_out,
analytics/fact_inventory_movement.sql:127 m.quantity_delta,
```

`git diff 636895e^ 636895e -- dbt/models/analytics/_analytics__models.yml`
mostra as três inclusões de “delta assinado”; as duas últimas não pertencem à
medida corrigida. Os valores dos fatos de expedição/resgate continuam sendo
transportados de suas respectivas origens, sem cálculo de delta de estoque.

`ro.sh /tmp/rvl3-r2/grain_more.sql`:

```text
 deltas_divergentes
--------------------
                  0
(1 row)
```

Consulta por `(source_system, movement_id)` entre fato e trusted. A primeira
tentativa usou por engano `inventory_movement_id`, inexistente na fato, e foi
recusada pelo PostgreSQL; a saída válida acima é da consulta corrigida.
Nenhuma delas escreve dados. O comentário físico, obtido por `oracle.sql`, é:

```text
                        quantity_delta_banco
--------------------------------------------------------------------
 **Semiaditiva** — soma por armazém e SKU, nunca ao longo do tempo.
(1 row)
```

Isso é esperado porque não houve novo build após a correção de texto. A
observação RVL3-2-08 refere-se ao comentário **no arquivo SQL**, que também
permanece errado, independentemente de executar build.

**R2-G — seeds e cobertura física.** `ro.sh /tmp/rvl3-r2/oracle.sql`, sete
colunas que faltavam na rodada 1:

```text
trusted | brazilian_states         | state_name     | Nome da unidade federativa por extenso.
trusted | brazilian_states         | region         | Região do IBGE a que a unidade federativa pertence.
trusted | order_status_transitions | from_status    | Vazio na transição inicial — o pedido não vem de estado nenhum.
trusted | support_categories       | category_code  | Código estável da categoria de chamado; chave natural.
trusted | support_categories       | category_name  | Nome da categoria de chamado.
trusted | support_categories       | category_group | Grupo que reúne categorias de chamado afins.
trusted | support_categories       | description    | O que a categoria de chamado cobre.
```

As outras quatro colunas dessas seeds não têm texto declarado nem comentário.
`ro.sh /tmp/rvl3-r2/catalog.sql -At` exporta somente metadados para JSON;
`python /tmp/rvl3-r2/check_types.py` cruza catálogo físico e manifest:

```text
SEM_COMENTARIO {'governance': 16, 'quarantine': 5, 'raw': 545, 'raw_legacy': 616, 'snapshots': 6, 'staging': 5, 'trusted': 125}
SEM_DESCRICAO {'quarantine': 5, 'snapshots': 6, 'staging': 5, 'trusted': 125}
DIFERENCAS_TRUSTED []
```

A afirmação da Governança de que `persist_docs` inclui seeds está sustentada
pela configuração e pelo estado físico. A catraca continua contando descrição
no catálogo, não comparando comentário do banco; o comentário antigo de
`quantity_delta` é um exemplo concreto dessa distinção. A coincidência dos
números trusted agora não transforma a catraca em teste de sincronização física.

**R2-H — regressões e limites.** Os comandos pedidos terminaram com código zero
na ponta `ed08efa`. Saídas de `/tmp/rvl3-r2/check-offline.txt` e
`/tmp/rvl3-r2/secrets-history.txt`:

```text
$ make check-offline
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 664 citações de ADR — nada quebrado
821 passed, 188 deselected in 164.19s (0:02:44)
check-offline: as três etapas passaram

$ make secrets-history
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Não executei `make check`, build, catalog, legacy-models, atualização de
comentários ou snapshots. Os 907 testes dbt e 1006 testes Python informados
pelo autor não são nova medição desta rodada. Não alterei bancos, memória do
legado, concessões, serviços ou o DAG `fluxo_batch`. As provas futuras de duas
versões e de novo acumulado são consultas com CTE, não novas cargas. Não há
aprovação, commit ou push nesta revisão. No checkout, a única edição deliberada
é o acréscimo desta seção em `REVISAO.md`; os arquivos não rastreados que já
existiam (`GEMINI.md` e `NAVEGANDO_GCP/parecer_migracao_gcp.md`) foram preservados.
