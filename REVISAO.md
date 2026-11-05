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

## Rodada 3 — lote 3

Revisão restrita a `ed08efa..2ab4d4e`, seis commits, com checkout em
`2ab4d4eefd915fe75ba28868700898a863c355e3`, em 05/11/2026. **Parecer técnico,
sem aceite nem poder de aprovação.** Nenhuma correção implementada. Somente
este dossiê foi editado no checkout; sondas, projetos dbt e gerações ficaram em
`/tmp/rvl3-r3-review`. Consultas exclusivamente pelo `ro.sh` autorizado. Nenhum
build, carga, alteração de serviço ou acionamento/pausa de `fluxo_batch`.

**O lote 3 ainda não pode ser encerrado tecnicamente.** As correções dos textos,
da subunião tipada, do snapshot/CRLF e do digest foram confirmadas. Restam
escapes de proveniência, de tipos desconhecidos e de atualidade do manifest.
Os cinco achados abaixo são **falhas preexistentes que a correção não cobre**,
não regressões demonstradas dos seis commits. A distinção importa: os testes
corrigidos passam, mas não provam a garantia inteira. A graduação aplica o
critério solicitado nesta rodada, inclusive aos limites antes declarados.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-3-01 | `src/mvp_ed1/models/descriptions.py:194–196,287–288,303–312`; `sensitivity.py:775–800` | **A prova de proveniência ainda pode desaparecer sem revisão do texto.** O registro atual está completo, mas só reconhece a chave literal modelo/coluna. Renomear a coluna ou o modelo junto com a mudança de expressão, ou promover um gerado a YAML à mão conservando o texto anterior, pode transformá-lo em `written` sem problema quando a folha imediata já mudou. A remoção de uma entrada é um escape comprovado também no projeto completo: substituindo `quantity` por constante e removendo só sua entrada, `--check=0`. Sem o arquivo, o primeiro `--check` acusa sua ausência, mas a primeira geração o recria incompleto, aceita o texto velho e o próximo `--check=0`. É necessário conservar/verificar a proveniência nessas transições e não interpretar ausência como revisão do autor. **Preexistente; fechamento incompleto de RVL3-01/RVL3-2-01.** R3-A/B. | `bloqueante` | **Corrigido, trocando o registro à parte por proveniência na própria coluna.** O `dbt/_descricoes_herdadas.json` saiu. Todo texto que a derivação escreve leva `meta.description_inherited: true`, no `.yml` à mão e no `_derived.yml` (1378 colunas marcadas). A marca anda com a coluna: renomear coluna ou modelo junto com a mudança de SQL, ou promover um gerado a `.yml` à mão copiando o bloco, leva a marca, e a coluna marcada que deixou de transportar é problema. Não há arquivo a apagar nem primeira geração que o recrie incompleto; tirar a marca é ato explícito, como escrever `description_reason`, e marca com motivo é contradição acusada. A igualdade com a folha imediata continua como segunda rede. Teste `test_a_marca_de_herdado_anda_com_a_coluna_e_acusa_quando_ela_deixa_de_transportar` (dois saltos, renomeada, revista, contradição) e `test_o_herdado_escrito_no_yml_a_mao_e_no_gerado_leva_a_marca`; contraprova com o código de `2ab4d4e`: `assert (0 == 1)`. |
| RVL3-3-02 | `src/mvp_ed1/models/descriptions.py:187–191,305–306` | **Formatação Jinja equivalente ainda apaga a prova de herança.** `_normal` iguala aspas e espaços repetidos, mas não iguala `{{ doc("x") }}` a `{{doc("x")}}` ou `{{ doc ("x") }}`. Todos renderizam o mesmo bloco; os dois últimos passam como texto novo, sem `description_reason`, e saem do registro. Não é caso adversarial: compactar a referência durante edição/formatação do YAML não revisa seu significado. Normalizar a referência semanticamente, preservando a distinção entre formatação e texto revisto. **Preexistente; a correção cobre as aspas da R2-A, mas não a equivalência de referências.** R3-A. | `ajuste` | **Corrigido.** `_normal` reescreve toda grafia de `{{ doc(...) }}` — espaço, aspas, `{{-`/`-}}`, espaço antes do parêntese — para a forma canônica antes de comparar. Teste `test_toda_grafia_do_mesmo_doc_e_a_mesma_referencia`; contraprova com `2ab4d4e`: as grafias ficavam distintas. |
| RVL3-3-03 | `src/mvp_ed1/models/transport.py:153–160`; `sensitivity.py:288–291`; Governança §5.1 | **União entre colunas de tipo desconhecido continua herdando após perder valor.** A correção `A\|B` funciona, mas o ramo `None` é descartado ao conferir tipos, salvo quando há constante flutuante diretamente na união. Com dois modelos calculados, um produzindo `16777217::bigint + 0` e outro `0::real`, ambos recebem tipo desconhecido; a união é `Carry`, herda “Quantidade exata de unidades.” e não registra problema. PostgreSQL entrega `16777216`. Consumir cálculos de modelos anteriores é uma composição comum; ponto flutuante aqui é uma medida não monetária. Não foi demonstrada perda nos dados atuais. Recusar herança cuja preservação não foi provada, ou resolver os tipos desses ramos, é necessário para a garantia de RVL3-02. **Preexistente, confirmado também com `transport.py` de `ed08efa`.** R3-C. | `ajuste` | **Corrigido, e achou um caso real.** (a) O tipo conhecido passou a vir também do cálculo: `cast`, testes e comparações (`BOOLEAN`), concatenação (`TEXT`), constantes e as colunas do snapshot (`dbt_valid_*` são `timestamp` sem fuso, medido no armazém). (b) Tipo desconhecido não prova: com mais de uma folha, ou diante de constante tipada, a união não transporta (`union_unproven`). (c) A regra passou a seguir a resolução do PostgreSQL: nas categorias numérica e de data/hora, o tipo resolvido é o mais alto presente, e só se herda se a conversão do **transportado** não muda o valor; entre categorias que o servidor recusaria unir (texto × `uuid`, texto × `jsonb`), a união construída prova tipos físicos iguais — o declarado na origem diverge do que o Airbyte grava. Nos modelos reais, a regra achou `dim_support_agent.valid_to`: o `dbt_valid_to` do snapshot (`timestamp`) unido a `cast(null as timestamptz)` é convertido pelo fuso da sessão, e herdava o texto de "fim da vigência" como valor intacto; ganhou texto próprio que diz a conversão, com motivo. Nenhum outro texto real mudou. Testes no da união (`ts` × `timestamptz` calcula; `timestamptz` × `date` transporta; `bigint` × `numeric` transporta; duas folhas desconhecidas não herdam; o tipo declarado do cálculo é anotado); contraprova com `2ab4d4e`: `Carry == union_unproven`. |
| RVL3-3-04 | `src/mvp_ed1/models/sensitivity.py:344–346,348–364`; Governança §5.1 | **A ressalva de YAML documenta, mas não impede, um `--check` silenciosamente verde com declaração alterada.** Na cópia atual, mudar `sensitivity: internal` para `personal` na primeira coluna correspondente de `_pontes__models.yml` mantém retorno zero e “0 arquivo(s) desatualizado(s)”. A derivação lê o metadado anterior no manifest; não identifica que a entrada da verificação mudou. É edição comum do declarativo, não SQL adversarial. Pela regra desta rodada, permanece ajuste: detectar o insumo declarativo atrasado ou recusar a verificação sem evidência de compilação correspondente. O `make check` completo compila antes; não foi demonstrado escape nesse fluxo completo. **Preexistente, já reproduzido em RVL3-2-07; a documentação do limite não é correção técnica.** R3-D. | `ajuste` | **Corrigido.** `_declaracao_atrasada` compara com o disco as três declarações de `.yml` que a derivação lê do manifest — o nível com `sensitivity_reason` (a ponte), o nível de cada coluna de seed e o de cada coluna das fontes não espelhadas — e entra em `stale_nodes`. Seu caso (nível da ponte trocado) agora faz `make catalog` e `--check` recusarem. O nível sem motivo, que é saída da derivação, não entra, para não recusar o fluxo `catalog → legacy-models → catalog`. Zero falsos alarmes no projeto atual. Teste `test_declaracao_do_yml_mudada_depois_do_build_e_recusada`; contraprova com `2ab4d4e`: `[] == ['declaração de ponte']`. Limite que fica, declarado: o `dbt_project.yml`. |
| RVL3-3-05 | `src/mvp_ed1/models/sensitivity.py:359–364`; Governança §5.1 | **A busca por substring de macro também aceita uma versão antiga dentro de comentário Jinja.** Manter o `macro_sql` anterior em `{# … #}` e alterar a macro ativa de `union all` para `union` resulta em `--check=0`. Um `dbt parse` independente confirma que a definição ativa é a nova. Comparar a definição ativa, e não sua ocorrência textual no arquivo. **Preexistente** quanto à falha — em `ed08efa` macros nem eram conferidas —, agora uma lacuna da nova guarda. É **observação**, pois guardar a definição antiga inteira em comentário exige um arranjo específico, distante das macros atuais, que mantêm uma definição ativa e usam o Git para histórico; arquivos com várias macros normais e `{%-` passaram. R3-D. | `observação` | **Corrigido.** Comentário Jinja `{# … #}` é retirado do arquivo e do `macro_sql` antes da comparação: a definição antiga guardada em comentário não passa pela ativa. Teste `test_definicao_antiga_em_comentario_nao_passa_pela_macro_ativa`; contraprova com `2ab4d4e`: aceitava. |

### Conferência das respostas e dos achados originais

“Fechado” significa atendimento do achado técnico específico, sem aprovação da
entrega. Cada evidência R3 abaixo tem comando e saída literal. R2-B foi
reexecutada; o novo caso de tipo desconhecido é separado dela.

| Achado | Resultado | Comando e saída que sustentam o resultado |
|---|---|---|
| RVL3-2-01 | **Não fechado integralmente.** Dois saltos, aspas e manutenção da entrada sinalizada funcionam; identidade, ausência do registro e outras grafias equivalentes escapam. | `registry.py`: `DOIS_SALTOS_COM_REGISTRO` e `SEGUNDA_RODADA_SINALIZADA` têm problema; `COLUNA_RENOMEADA PROBLEMAS []`; `full_check.py`: `CONSTANTE_ENTRADA_APAGADA RC 0` (R3-A/B). |
| RVL3-2-02 | **Fechado.** Os tipos da subunião continuam presentes em mais níveis; misturas seguras permanecem `Carry`. | `union.py`: `R2_B` e `PROFUNDA` → `Computed(kind='union_coercion', shape=None, type=None)`; `MISTA_SEGURA`/`MISTA_NULL` → `Carry` (R3-C). |
| RVL3-2-03 | **Fechado.** As seis medidas das dimensões distinguem versões; `quantity_ordered` distingue item de remessa de linha de pedido. | `texts.py`: textos/motivos próprios; `ro.sh …/oracle.sql`: `quantity_ordered 15534 13278`, dimensões com uma versão atual por entidade; `baseline.py`: `ARQUIVOS_DIFERENTES []` (R3-E). |
| RVL3-2-04 | **Fechado.** Os seis acumulados descrevem a captura de abertura e a ausência de atualização isolada; os de cliente recuperam “pedidos realizados”. | `texts.py`: `MEDIDAS_FORA True` nos três snapshots; `oracle.sql`: `acumulado_congelado=40`, `acumulado_novo=41`, `cria_versao=f`; SQL de `customers`: `where o.is_realised` (R3-E). |
| RVL3-2-05 | **Fechado.** O `WHERE` acrescentado é recusado; CRLF e controle de whitespace gerados pelo dbt não provocam falso alarme. | `full_check.py`: `SNAPSHOT_WHERE RC 1`; `parse_check.py`: `STALE_PARSE []`, com `RAW crlf …\r\n…` e snapshot `{%-` (R3-D). |
| RVL3-2-06 | **Fechado.** Os dois motivos voltaram exatamente ao conteúdo anterior a `636895e`. | `texts.py`: duas linhas `MOTIVO_RESTAURADO … True` (R3-E). |
| RVL3-2-07 | **Não fechado integralmente.** A mudança simples da macro agora é recusada e o limite YAML está documentado, mas o passe silencioso persiste; há também o escape por comentário. | `full_check.py`: `MACRO_UNION RC 1`, `YAML_SENSIBILIDADE RC 0`, `MACRO_VELHA_EM_COMENTARIO RC 0` (R3-D). |
| RVL3-2-08 | **Fechado.** O comentário SQL distingue delta aditivo de saldo semiaditivo. | `texts.py`: `COMENTARIO_SQL 123 … quantity_delta … aditiva` e linhas 124–126 (R3-E). |
| RVL3-2-09 | **Fechado.** A lista de campos tem serialização inequívoca para os casos levantados. | `digest.py`: `R2_COLISAO False`, `R1_MULTILINHA False`, `SO_CORPO_IGUAL True` (R3-F). |
| RVL3-01 | **Não fechado integralmente.** O texto antigo é recusado quando a chave e a grafia reconhecida sobrevivem; permanecem R3-01/02. | `full_check.py`: `CONSTANTE_COM_REGISTRO RC 1`, mas `CONSTANTE_ENTRADA_APAGADA RC 0`; `registry.py`: grafia compacta com `PROBLEMAS []` (R3-A/B). |
| RVL3-02 | **Não fechado integralmente.** Coerção simples e subunião tipada estão corrigidas, mas união de folhas desconhecidas ainda pode mudar valor e herdar. | `union.py`: `MODELOS_CALCULADOS … ORIGEM inherited PROBLEMAS [] []`; `oracle.sql`: `DUAS_FOLHAS real 1.6777216e+07` para entrada `16777217` (R3-C). |
| RVL3-03 | **Fechado para os defeitos de grão identificados e o inventário revisto.** Fatos, dimensões e acumulados de snapshots recebem as restrições correspondentes. Não encontrei outra descrição de soma em grão errado no inventário de medidas examinado. | `baseline.py`: inventário `MEDIDA`, sem diferenças de arquivos; `texts.py` e `oracle.sql`: restrições e somas repetidas confirmadas (R3-E). |
| RVL3-07 | **Não fechado integralmente quanto à garantia geral de atualidade.** Modelo, snapshot, CRLF e edição simples de macro estão cobertos; YAML e comentário de macro não. | `full_check.py` e `parse_check.py`: recusas/retornos zero discriminados em R3-D. |
| RVL3-09 | **Fechado.** Tanto a quebra de linha entre aspas quanto o separador dentro de campo alteram o digest. | `digest.py`: `R1_MULTILINHA False` e `R2_COLISAO False`; testes direcionados: `31 passed in 2.62s` (R3-F). |

### Evidências da rodada 3

Os scripts mencionados estão em `/tmp/rvl3-r3-review`. Python dos comandos:
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python`. As derivações iniciais foram feitas
com `derive()` em memória, sem `load()`/cache no checkout. Os comandos que
exercitam `sensitivity.main()` redirecionam `ROOT`, `DBT`, `MANIFEST`, `CACHE` e
`descriptions.INHERITED_FILE` à cópia. Não houve geração no checkout original.

**R3-A — inventário, determinismo e transições de proveniência.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/baseline.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/registry.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/doc_probe.py
```

Trecho de `baseline.txt`:

```text
STALE []
NOS 199 COLUNAS 2983
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
OBSOLETOS []
REGISTRO 87 1089 EXATO True
DETERMINISTICO True
```

O conjunto esperado foi reconstruído das saídas com origem `inherited`,
`convention` ou `bridge` e entrada de disco `kind='hand'`, incluindo o texto.
Igualdade de dicionários prova ausência de entradas faltantes e excedentes
**no estado atual**, não recuperabilidade histórica. Duas derivações produziram
o mesmo JSON. Permanecem os três avisos conhecidos de `legacy_classifications`
sobre `position`/`name`; não são novos nesta rodada.

`registry.py` monta `raw.orders.total_amount → staging.a.v → trusted.b.v`.
A raiz recebe “Texto revisado.”; `a` transporta e `b` passa a multiplicar,
conservando no YAML o texto anterior. Trechos literais:

```text
DOIS_SALTOS_COM_REGISTRO PROBLEMAS ['b.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, ou declare `description_reason`'] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {'b': {'v': 'Valor total do pedido; reconcilia os demais campos.'}}
SEGUNDA_RODADA_SINALIZADA PROBLEMAS ['b.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, ou declare `description_reason`'] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {'b': {'v': 'Valor total do pedido; reconcilia os demais campos.'}}
COLUNA_RENOMEADA PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
MODELO_RENOMEADO PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
ENTRADA_REMOVIDA PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
REGISTRO_AUSENTE PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
GERADO_PARA_HAND_COM_CALCULO PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
HAND_PARA_GERADO PROBLEMAS [] DESTINO None None REG_B {}
TEXTO_REVISTO PROBLEMAS [] DESTINO written 'Valor multiplicado por cem.' REG_B {}
MOTIVO_EXPLICITO PROBLEMAS [] DESTINO written 'Valor total do pedido; reconcilia os demais campos.' REG_B {}
```

O caso de promoção representa copiar a entrada antes derivada para um arquivo
à mão no mesmo trabalho que muda a expressão; ela não tinha registro anterior.
Mover apenas o arquivo entre dois caminhos à mão preserva a chave e não cria
este escape. De à mão para gerado, a expressão calculada fica sem texto, como
esperado. Coluna/modelo renomeado **sem** mudança de expressão continua herdando
e ganha a nova chave; o defeito exige perder o transporte na transição, ou
perder a proveniência antes de precisar dela. Não se afirma que toda renomeação
falhe.

A comparação de aspas da rodada 2 agora funciona. Já a compactação:

```text
DOC "{{ doc('x') }}" PROBLEMAS ['b.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, ou declare `description_reason`'] DESTINO written "{{ doc('x') }}" REG_B {'b': {'v': '{{ doc("x") }}'}}
DOC '{{doc("x")}}' PROBLEMAS [] DESTINO written '{{doc("x")}}' REG_B {}
DOC '{{ doc ("x") }}' PROBLEMAS [] DESTINO written '{{ doc ("x") }}' REG_B {}
JINJA '{{ doc("x") }}' RENDER Texto do mesmo bloco. NORMAL '{{ doc("x") }}'
JINJA "{{ doc('x') }}" RENDER Texto do mesmo bloco. NORMAL '{{ doc("x") }}'
JINJA '{{doc("x")}}' RENDER Texto do mesmo bloco. NORMAL '{{doc("x")}}'
JINJA '{{ doc ("x") }}' RENDER Texto do mesmo bloco. NORMAL '{{ doc ("x") }}'
```

A mesma falha de grafia foi confirmada pelo escritor completo, na cópia:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/full_doc.py
```

A sonda troca a projeção `v.source_system` de `dim_customer` por
`upper(v.source_system) as source_system`, atualiza também o SQL do manifest
e compacta somente a referência no YAML para `{{doc("source_system")}}`.
O texto do bloco continua o mesmo, embora a expressão deixe de transportar.
A geração aceita a mudança e retira a entrada do registro:

```text
GERACAO_DOC_COMPACTO RC 0 OUT escrito: dbt/_descricoes_herdadas.json
classificação e descrição derivadas de 2983 colunas em 199 nós; 1 arquivo(s) escrito(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
CHECK_DOC_COMPACTO RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
REGISTRO_DIM_SOURCE_SYSTEM None
```

**R3-B — entrada apagada e primeiro uso sem registro, pelo escritor completo.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/full_check.py
```

Na cópia, a sonda troca `cast(quantity as integer)` por `100` tanto no SQL de
`stg_retail__order_items` quanto em `raw_code` e `compiled_code` do manifest:
a expressão nova efetivamente entra na derivação, sem fingir uma recompilação
executada. O texto “Quantidade comprada do SKU.” permanece no YAML.

Trechos literais de `full_check.txt` (os três avisos conhecidos foram omitidos):

```text
BASE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
CONSTANTE_COM_REGISTRO RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
gerador: stg_retail__order_items.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, ou declare `description_reason`
CONSTANTE_ENTRADA_APAGADA RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
CONSTANTE_ARQUIVO_AUSENTE RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 1 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
desatualizado: dbt/_descricoes_herdadas.json
PRIMEIRA_GERACAO_SEM_REGISTRO RC 0 OUT escrito: dbt/_descricoes_herdadas.json
classificação e descrição derivadas de 2983 colunas em 199 nós; 1 arquivo(s) escrito(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
DEPOIS_DA_PRIMEIRA_GERACAO RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
```

A falta do arquivo **não** faz o primeiro `--check` passar: ele acusa o JSON
faltante. O escape é a geração aceitá-lo como vazio e recriá-lo sem a prova da
coluna problemática, ou a remoção isolada dessa entrada. Uma remoção acidental
em resolução de conflito tem o mesmo efeito; não depende de alterar o motor.

**R3-C — união aninhada e fronteira de modelos calculados.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/union.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/history_probe.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r3-review/oracle.sql
```

```text
R2_B {'x': Computed(kind='union_coercion', shape=None, type=None)}
PROFUNDA {'x': Computed(kind='union_coercion', shape=None, type=None)}
MISTA_SEGURA {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
MISTA_REAL {'x': Computed(kind='union_coercion', shape=None, type=None)}
MISTA_NULL {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
MODELOS_CALCULADOS CARRY Carry(leaves=frozenset({('trusted', 'b', 'x'), ('trusted', 'a', 'x')})) TIPOS [None, None] TEXTO Quantidade exata de unidades. ORIGEM inherited PROBLEMAS [] []
ED08EFA_DUAS_FOLHAS Carry(leaves=frozenset({('trusted', 'b', 'x'), ('trusted', 'a', 'x')}))
2AB4D4E_DUAS_FOLHAS Carry(leaves=frozenset({('trusted', 'b', 'x'), ('trusted', 'a', 'x')}))
```

`R2_B` é `BIGINT ∪ (0::real ∪ 1::double precision)`. `PROFUNDA` acrescenta
`null ∪ (-1 ∪ (0::real ∪ 1::double precision))`; `MISTA_SEGURA` usa
`null ∪ (-1 ∪ 0.1::numeric)`; `MISTA_NULL`, `-1 ∪ null`.
O caso com duas folhas passa por `sensitivity.derive()` e
`descriptions.derive_texts()`, não apenas por `combine_union`: as duas raízes
calculadas têm texto próprio igual, o destino herda, nenhum problema é emitido.

Oráculo PostgreSQL, sem escrita:

```text
 transaction_read_only
-----------------------
 on
(1 row)

 caso |       tipo       |         valor
------+------------------+-----------------------
 R2_B | double precision | 9.007199254740992e+15
 R2_B | double precision | 0
 R2_B | double precision | 1
(3 rows)

    caso     | tipo |     valor
-------------+------+---------------
 DUAS_FOLHAS | real | 1.6777216e+07
 DUAS_FOLHAS | real | 0
(2 rows)
```

Na primeira consulta, a entrada é `9007199254740993::bigint`; o motor agora
recusa corretamente a herança. Na segunda, são dois CTEs/subconsultas
representando os modelos `a` (`16777217::bigint + 0`) e `b` (`0::real`):
a promoção para `real` arredonda a primeira linha, mas o motor herda.
A profundidade e a mistura de constantes foram corrigidas; não se deve atribuir
a elas a falha distinta de perder informação de tipo na fronteira de modelos.

**R3-D — atualidade do manifest, CRLF, `{%-` e várias macros.**

`full_check.py` restaura a cópia após a sonda de proveniência e aplica as
alterações de R2-D separadamente. Trechos de saída:

```text
SNAPSHOT_WHERE RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (scd_coupon); rode `make dbt-build` antes — nenhum arquivo é tocado
MACRO_UNION RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (macro empilhado); rode `make dbt-build` antes — nenhum arquivo é tocado
YAML_SENSIBILIDADE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
MACRO_VELHA_EM_COMENTARIO RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
```

Na última sonda, a definição anterior de `empilhado` fica dentro de comentário
Jinja, antes da definição ativa alterada. A busca por substring encontra a
antiga no comentário. As outras macros do projeto não são alteradas.

Para não depender de pressupostos sobre `raw_code`/`macro_sql`, criei um projeto
mínimo sem conexão com banco e deixei o dbt produzir o manifest:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/prepare_parse.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/dbt parse \
  --project-dir /tmp/rvl3-r3-review/parse \
  --profiles-dir /tmp/rvl3-r3-review/parse --no-partial-parse
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/parse_check.py
```

```text
STALE_PARSE []
RAW m 'select {{ a() }} as x, {{ b() }} as y'
RAW crlf '{% set x = 1 %}\r\nselect {{ x }} as x'
RAW s "{{ config(target_schema='probe',unique_key='x',strategy='check',check_cols=['x']) }}\nselect 1 as x"
MACRO_SQL a '{%- macro a() -%}1{%- endmacro -%}\n\n'
MACRO_SQL b '{% macro b() %}2{% endmacro %}'
MULTIMACRO_ALTERADA ['macro b']
SNAPSHOT_ALTERADO ['s']
```

Portanto, não houve falso alarme no projeto atual (`STALE []`), no modelo CRLF,
no snapshot com abertura/fechamento `{%- … -%}` nem no arquivo com duas macros,
uma com controle de whitespace. Mudar só a segunda macro é detectado.

Depois, `parse_macro_comment.py` guarda `b=2` em comentário e deixa `b=3`
ativo; repetido o mesmo `dbt parse`, a leitura de `manifest['macros']` mostrou:

```text
MACRO_ATIVA_PARSE a '\n{%- macro a() -%}1{%- endmacro -%}\n\n'
MACRO_ATIVA_PARSE b '{% macro b() %}3{% endmacro %}'
```

O comentário não é uma segunda definição ativa nem faz o parse falhar. A
prova de retorno zero é a sonda completa com `empilhado`; esse projeto mínimo
confirma independentemente a interpretação do dbt.

**R3-E — textos, grão e documentação.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/texts.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r3-review/oracle.sql
```

`texts.py` imprime os textos e motivos das seis medidas de dimensão, seis de
snapshot, `quantity_ordered`, das duas medidas repetidas da R1 e dos dois
motivos revertidos. Exemplos literais:

```text
dim_customer.order_count TEXTO **Aditiva entre clientes, só na versão vigente** (`is_current`) — pedidos realizados do cliente, com o valor atual repetido em cada versão dele; zero para quem nunca comprou. MOTIVO o valor atual de trusted, repetido em cada versão da dimensão — o herdado diria aditiva sem a vigência (RVL3-2-03)
scd_customer.order_count TEXTO **Não soma entre versões** — pedidos realizados do cliente na captura que abriu esta versão; fica congelado enquanto a versão vale — a coluna não está em `check_cols`, e uma mudança só dela não a atualiza nem abre versão. O valor atual está em `trusted.customers`. MOTIVO o snapshot guarda o acumulado da captura que abriu a versão, não um valor que acompanha o tempo — o herdado diria aditiva (RVL3-03, RVL3-2-04)
CHECK_COLS scd_customer ['customer_segment_id', 'customer_status', 'city', 'state_code', 'is_deleted'] MEDIDAS_FORA True
CHECK_COLS scd_coupon ['campaign_id', 'discount_type', 'discount_value', 'min_order_amount', 'coupon_is_active', 'is_deleted'] MEDIDAS_FORA True
CHECK_COLS scd_support_agent ['agent_team', 'agent_is_active', 'is_deleted'] MEDIDAS_FORA True
MOTIVO_RESTAURADO fact_shipment_item.quantity_shipped True 'diz a aditividade da medida nesta fato, que o texto herdado não diz'
MOTIVO_RESTAURADO fact_coupon_redemption.coupon_discount_amount True 'diz a aditividade da medida nesta fato, que o texto herdado não diz'
COMENTARIO_SQL 123     -- `quantity_delta` é **aditiva**: é delta assinado, e a soma num período é a
COMENTARIO_SQL 124     -- variação líquida do estoque nele (RVL3-10). Semiaditivo é o saldo, que é
COMENTARIO_SQL 125     -- fotografia — esse não se soma ao longo do tempo. `quantity_in` e
COMENTARIO_SQL 126     -- `quantity_out` são aditivas em qualquer recorte e separam entrada de saída.
```

O SQL das três dimensões lê todas as versões e junta `trusted` pela chave
natural com `source_system`; `is_current` é `dbt_valid_to is null`. Logo, a
restrição agora escrita corresponde ao modo de somar os valores atuais.
Os snapshots leem `select *` de `trusted`, mas nenhuma das seis medidas entra
em `check_cols`. `trusted.customers` conta e soma apenas `where o.is_realised`.
Conferi essa regra contra o ADR-0017, sem modificar o ADR nem a estratégia.

Medição atual, não inferência sobre futuras versões:

```text
      modelo       | linhas | entidades | atuais
-------------------+--------+-----------+--------
 DIM_CUSTOMER      |   1574 |      1574 |   1574
 DIM_COUPON        |     19 |        19 |     19
 DIM_SUPPORT_AGENT |      8 |         8 |      8
(3 rows)

        medida        | soma  | uma_vez
----------------------+-------+---------
 quantity_ordered     | 15534 |   13278
 failed_attempt_count |   879 |     437
 reopening_count      |    63 |      14
(3 rows)

 acumulado_congelado | acumulado_novo | cria_versao
---------------------+----------------+-------------
                  40 |             41 | f
(1 row)
```

A dimensão de atendente inclui o membro desconhecido. A última consulta altera
apenas o resultado de um CTE (`redemption_count+1`) e aplica a condição de
comparação das `check_cols`; **não executa snapshot nem altera registro**.

Para procurar medidas esquecidas, `baseline.py` inventaria descrições em
`analytics`, `snapshots` e `consumption` com termos de aditividade, soma, total,
quantidade, contagem, pedidos, resgates e eventos. Conferi também os SQLs das
medidas repetidas, o recorte por remessa/pedido de P13/P14 e a restrição de um
cupom por pedido. Em `fact_coupon_redemption`, valores de pedido são somáveis
porque `source_system, order_id` é único; a origem declara índice único por
pedido e o YAML testa a combinação. Não tratei esse transporte de total como
fan-out. Os acumulados das dimensões/snapshots e os três casos da tabela acima
agora explicam suas restrições. Não foi demonstrado outro erro de grão nesse
inventário; isso não equivale a provar toda futura mudança de cardinalidade.

**Governança §5.1 v2.14:** os trechos sobre registro gerado/`--check` e medidas
atuais versus capturadas correspondem à implementação e aos textos atuais.
As promessas de recusa precisam ser lidas com as falhas de R3-01/02/03/05:
ainda não são garantias gerais. O limite YAML está de fato declarado, mas
permanece o passe silencioso de R3-04. A descrição da guarda não deve confundir
“macro apagada não se confere” com ausência total de detecção: remover o
arquivo ou o trecho de uma macro que está no manifest é alcançado pelo teste
de existência/substring; o código não reconcilia o inventário inteiro do
projeto. Não há achado separado apenas para essa imprecisão de redação.

**R3-F — digest e verificações de regressão.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r3-review/digest.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/pytest -q -p no:cacheprovider \
  tests/test_descricao_derivada.py tests/test_classificacao_derivada.py
PYTHONDONTWRITEBYTECODE=1 make check-offline
PYTHONDONTWRITEBYTECODE=1 make secrets-history
```

```text
R2_COLISAO False
R1_MULTILINHA False
SO_CORPO_IGUAL True
...............................                                          [100%]
31 passed in 2.62s
```

`R2_COLISAO` compara `["a\x1fb"]` com `["a", "b"]`; `R1_MULTILINHA` muda o
nome dentro de um campo entre aspas contendo quebra de linha; o controle muda
apenas o corpo. Os dois defeitos anteriores estão corrigidos.

Trechos de `check-offline.txt`, retorno zero:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 664 citações de ADR — nada quebrado
823 passed, 188 deselected in 179.43s (0:02:59)
check-offline: as três etapas passaram
```

O alvo também listou os 188 testes de integração excluídos, por arquivo. Eles
**não foram executados** nesta rodada. O resultado do autor (`PASS=907`,
`1008 passed, 3 skipped`) não foi remedido: `make check` faria build e está fora
da autorização desta revisão.

Última linha de `secrets-history.txt`, retorno zero:

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os testes existentes passam junto com as contraprovas novas; portanto, seus
resultados verdes não encerram os escapes registrados nesta rodada. Permanecem
sem execução alterações reais de dados, abertura de uma segunda versão SCD,
reconstrução do armazém e atualização de comentários físicos. A revisão mediu
os textos de código/catálogo e consultou o grão do armazém como o encontrou.

## Rodada 4 — lote 3

Revisão de `2ab4d4e..afca255`, exclusivamente os cinco commits indicados pelo
Owner, com checkout em `afca255dfe031d007f4cd392fe59ea00dd4da56a`, em
05/11/2026. **Parecer técnico, sem aceite nem poder de aprovação.** Nenhuma
correção implementada. Somente `REVISAO.md` foi editado no checkout; sondas e
cópias ficaram em `/tmp/rvl3-r4-review`. Os dois arquivos não rastreados já
presentes foram preservados. SQL exclusivamente pelo `ro.sh` autorizado, com
`transaction_read_only=on`; nenhum build, carga, troca de ambiente ou
acionamento/pausa de `fluxo_batch`. A memória do legado não foi alterada.

**O lote 3 ainda não pode ser encerrado tecnicamente: um bloqueante e três
ajustes abaixo.** As transições originais com marca, a normalização de `doc()`,
a recusa de tipos desconhecidos e a macro antiga em comentário foram
confirmadas. A revisão encontrou uma maneira de o próprio escritor deixar de
persistir a marca, duas falhas na prova de tipos e uma declaração removida que
a guarda de atualidade ignora. Não foi demonstrada descrição errada adicional
nos dados atuais; os escapes aparecem nas mudanças ordinárias descritas abaixo.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-4-01 | `src/mvp_ed1/models/sensitivity.py:740–746,883–889`; `descriptions.py:281–288` | **O escritor pode gravar texto herdado sem persistir a marca, e o próximo `--check` passa.** `patch_meta` só reconhece a linha exatamente `meta:`. Com `meta: {sensitivity: internal}` ou `meta: # classificação`, insere outro `meta` antes do existente; o carregador conserva o último e perde `description_inherited`. A segunda escrita encontra a primeira chave textual, não muda bytes, e a verificação retorna zero. Na cópia completa, a geração substituiu um texto provisório pelo herdado de `quantity`, mas a marca não ficou; depois `quantity → 100` conservou “Quantidade comprada do SKU.” com `--check=0`. É YAML comum, sem entrada maliciosa. Verificar a marca no YAML efetivamente carregado, preservar metadados e não aceitar chaves duplicadas produzidas pelo escritor. **Regressão da nova proveniência, apoiada numa limitação preexistente do escritor textual.** R4-A/B. | `bloqueante` | **Corrigido.** (a) `patch_meta` reconhece `meta:` com comentário como bloco, e **recusa** `meta: {…}` em linha com erro que diz para escrever em bloco — em vez de inserir um segundo `meta:`. (b) `verify_meta` carrega o arquivo renderizado com um carregador que **recusa chave repetida** e confere cada marca pedida no YAML como ele é lido; roda nos dois modos do `make catalog`, então um escritor que não grava a marca não passa no `--check` só porque os bytes não mudaram. Qualquer recusa sai como "escrita recusada … nenhum arquivo é tocado". Teste `test_o_escritor_nao_perde_a_marca_em_meta_com_comentario_nem_aceita_meta_em_linha` (comentário, em linha, chave duplicada); contraprova com `afca255`: a marca não ficava. |
| RVL3-4-02 | `src/mvp_ed1/models/transport.py:171–204`; Governança §5.1 | **Fora das duas listas de tipos, a união é aceita sem provar preservação.** Uma folha conhecida `BIGINT[]` unida a constante `REAL[]` agora é `Carry`; o PostgreSQL entrega `{16777216}` para `{16777217}`. `2ab4d4e` recusava essa mesma combinação de tipos conhecidos. O caso com dois modelos também herda texto de valor exato, sem problema. Há ainda o limite preexistente `CHAR(4)`: com `TEXT` à esquerda, o servidor resolve `text` e retira os espaços de preenchimento, mas o motor herda. Arrays e códigos de largura fixa são usos normais de SQL, embora não tenham causado perda demonstrada no catálogo atual. Construção bem-sucedida prova compatibilidade dos tipos físicos, não igualdade deles; tipos declarados divergentes não autorizam concluir preservação. Resolver/provar também essas conversões ou recusá-las conservadoramente. **Regressão para arrays conhecidos; o escape `CHAR/TEXT` já existia.** R4-C. | `ajuste` | **Corrigido.** Fora das categorias ordenadas (numérica e data/hora), construir não prova igualdade: aceita-se só o mesmo tipo, `varchar` com `text`, e `uuid`/`json`/`jsonb` com texto (o Airbyte grava texto no lugar deles — a divergência declarado × físico que motivou a regra anterior); `char(n)` com `text` e `array` de tipos diferentes calculam (`union_coercion`), e categoria ordenada misturada com outra também. Seus dois casos (`BIGINT[]` × `REAL[]`, `CHAR(4)` × `TEXT`) entram no teste da união; contraprova com `afca255`: `Carry == union_coercion`. Nenhum texto real mudou. |
| RVL3-4-03 | `src/mvp_ed1/models/transport.py:99–135`; `sensitivity.py:298–304` | **Os novos tipos “conhecidos” podem estar errados e transformar um cast real em transporte.** `materialized_type` não distingue `'true'` de `true`: atribui `BOOLEAN` ao texto. `_declared_type` atribui `TEXT` a qualquer `\|\|`, inclusive concatenação de arrays e bits. Num modelo seguinte, `cast(x as boolean)` do primeiro ou `cast(x as text)` do array é `Carry` e herda respectivamente “Código textual; preserve a grafia original.” e “Lista de identificadores inteiros.”, com zero problemas. PostgreSQL confirma `text → boolean` e `integer[] → text`; `2ab4d4e` classificava ambos como cálculo. Literais e operadores sobrecarregados são expressões comuns, não SQL adversarial. Preservar a espécie do literal e só anotar tipo quando a expressão/operandos o provarem. **Regressão de 5e2f076.** R4-D. | `ajuste` | **Corrigido.** A constante guarda a **espécie** do literal no próprio nó (`Computed.materialized`): `'true'` é `TEXT`, `true` é `BOOLEAN`, `1` é `INTEGER`, `1.5` é `NUMERIC`; o palpite pelo texto da forma saiu. `\|\|` deixou de ser `TEXT` por si: só é texto quando **todo operando prova** ser texto — literal de cadeia, `cast` para tipo textual, ou coluna transportada de tipo textual declarado; `arr \|\| arr` não diz nada. Ao endurecer, `customer_full_name` e `agent_full_name` (texto `\|\|` texto nos dois ramos) foram acusados e voltaram a herdar pela prova dos operandos — não por exceção. Casos no teste da união. |
| RVL3-4-04 | `src/mvp_ed1/models/sensitivity.py:366–368`; Governança §5.1 | **Remover uma declaração inteira do YAML torna-a invisível à guarda.** `_declaracao_atrasada` pula o nó se seu nome não estiver mais no disco. Na cópia, retirar só a entrada `order_status_transitions` de `_seeds.yml`, mantendo o CSV e o manifest anterior, dá `STALE []` e `--check=0`; continuam valendo os quatro níveis antigos. Com as colunas declaradas retiradas também do manifest em memória, a derivação acusa as quatro classificações faltantes. Remoção acidental, renomeação ou reorganização incompleta de uma entrada não é caso adversarial. Ausência deve ser comparada com a declaração anterior, especialmente em seeds, que são insumo obrigatório. **Preexistente; cobertura incompleta de RVL3-3-04/RVL3-2-07, não regressão demonstrada.** R4-E. | `ajuste` | **Corrigido.** `_declaracao_atrasada` trata a entrada que sumiu do disco como declaração vazia: o manifest com níveis declarados (seed, ponte com motivo) contra o disco sem a entrada é atrasado. Seu caso (`order_status_transitions` retirada de `_seeds.yml`) agora recusa. Caso no teste da declaração; contraprova com `afca255`: `[] == ['declaração de sd']`. |

### Conferência das sete respostas pendentes

“Fechado” abaixo refere-se ao achado técnico específico, sem aprovação da
entrega. Os comandos completos e as saídas estão nas evidências desta rodada.

| Achado | Resultado | Comando e saída que sustentam o resultado |
|---|---|---|
| RVL3-3-01 | **Não fechado integralmente.** As transições R3-A/B com marca estão corrigidas; o escritor ainda pode produzir herança sem marca e passar silenciosamente, em RVL3-4-01. | `transitions.py`: renomeações e promoção têm `PROBLEMAS ['… não transporta mais (mul) …']`; `full.py`: `CONSTANTE_COM_MARCA RC 1`, mas `CONSTANTE_APOS_WRITER_INLINE RC 0`. |
| RVL3-3-02 | **Fechado para as grafias levantadas.** Aspas, compactação, espaço antes do parêntese e controle de whitespace convergem; a prova já não depende de uma string em registro externo. | `transitions.py`: as quatro linhas `NORMAL … = '{{ doc("x") }}'` em R4-A. |
| RVL3-3-03 | **Fechado o escape específico de folhas desconhecidas.** A resposta, contudo, introduziu as regressões de tipos de RVL3-4-02/03; não está tecnicamente liberada como conjunto. | `types.py`: `MODELOS R3_ORIGINAL TIPOS [None, 'REAL', None] … union_unproven … TEXTO None PROBLEMAS [] []`; `extra_union.py`: `UNKNOWN_TYPED … union_unproven`. |
| RVL3-3-04 | **Não fechado integralmente.** Alterar o nível da ponte, da seed ou da fonte não espelhada é recusado; retirar a declaração inteira da seed ainda passa. | `full.py`: `PONTE_NIVEL_ALTERADO RC 1`, `SEED_DECLARACAO_REMOVIDA RC 0`; `stale.py`: `SEED_NIVEL ['declaração de brazilian_states']` e `FONTE_NAO_ESPELHADA governance ['declaração da fonte governance.legacy_captures']`. |
| RVL3-3-05 | **Fechado.** A definição antiga em comentário Jinja não encobre a alteração ativa. | `full.py`: `MACRO_ANTIGA_COMENTADA RC 1 … (macro empilhado)`. |
| RVL3-2-01 | **Não fechado integralmente.** Dois saltos, identidade e equivalência de referência estão cobertos; a proveniência ainda pode faltar por ação do escritor. | `transitions.py`: `DOIS_SALTOS` recusado; `full.py`: geração e check do YAML inline retornam zero, `META_INLINE_LIDO {'sensitivity': 'internal'}`, seguido de constante aceita. |
| RVL3-2-07 | **Não fechado integralmente.** As sondas antigas de macro e nível da ponte agora falham corretamente; permanece o passe silencioso de declaração removida. | `full.py`: recusas acima, mas `SEED_REMOVIDA_STALE []` e `SEED_DECLARACAO_REMOVIDA RC 0`. O limite adicional de `dbt_project.yml` continua declarado, não corrigido. |

### Evidências da rodada 4

**R4-A — inventário das marcas, transições e escritores.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/baseline.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/transitions.py
```

`baseline.py` deriva em memória, sem usar/escrever cache no checkout, e
reconstrói o conjunto esperado pelas origens `inherited`, `convention` e
`bridge`. Saída:

```text
STALE []
NOS 199 COLUNAS 2983
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
OBSOLETOS []
MARCAS 1378 ESPERADAS 1378 EXATAS True EXCEDENTES [] FALTANTES []
POR_ORIGEM {('hand', 'inherited'): 1033, ('hand', 'convention'): 55, ('derived', 'inherited'): 266, ('derived', 'convention'): 24}
SEM_MARCA {('hand', 'written'): 327, ('generator', 'generator'): 1137}
DETERMINISTICO True
```

Persistem somente os três avisos conhecidos de `legacy_classifications`
sobre `position`/`name`. A igualdade dos conjuntos confere as 1.378 marcas
atuais, inclusive as 79 convenções; nenhuma origem `written` está marcada.
“Arquivo à mão” não significa que cada descrição nele tenha autoria manual.
As pontes do outro gerador são tratadas à parte em R4-E.

A sonda de dois saltos troca o texto da raiz, mantém no destino o texto antigo
com a marca e muda sua expressão para multiplicação. Renomeia coluna, modelo,
muda o caminho e representa a promoção copiando a entrada marcada. Trechos:

```text
DOIS_SALTOS PROBLEMAS ['b.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`'] ORIGEM written
COLUNA_RENOMEADA PROBLEMAS ['b.v_centenas: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`'] ORIGEM written
MODELO_RENOMEADO PROBLEMAS ['b_novo.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`'] ORIGEM written
GERADO_PROMOVIDO PROBLEMAS ['b.v: não transporta mais (mul) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`'] ORIGEM written
HAND_PARA_DERIVED PROBLEMAS [] ORIGEM None
CONTRADICAO PROBLEMAS ['b.v: `description_inherited` e `description_reason` juntos — o texto é revisto ou herdado; tire a marca'] ORIGEM written
REVISTO PROBLEMAS [] ORIGEM written
NORMAL '{{ doc("x") }}' = '{{ doc("x") }}'
NORMAL "{{doc('x')}}" = '{{ doc("x") }}'
NORMAL '{{ doc ("x") }}' = '{{ doc("x") }}'
NORMAL '{{- doc( "x" ) -}}' = '{{ doc("x") }}'
```

O JSON de R3 não é mais entrada do motor: não há entrada externa a remover ou
registro a recriar no primeiro uso. `REGISTRO_AUSENTE` e
`PRIMEIRO_USO_MARCADO` repetem a recusa de `DOIS_SALTOS` sem registro algum.
Não se simulou a existência de uma proveniência histórica quando a coluna não
tem marca; a primeira escrita sem marca é exercitada por R4-B. No retorno de
um modelo calculado ao gerado, o texto desaparece, em vez de virar raiz falsa.

A escrita de descrição em escalar `>`/`|`, com `meta` normal, preserva a marca.
O problema aparece na localização textual de `meta`:

```text
WRITER '        meta:\n          sensitivity: internal' META_LIDO {'description_inherited': True, 'sensitivity': 'internal'} SEGUNDA_ESCRITA_IGUAL True
WRITER '        meta: {sensitivity: internal}' META_LIDO {'sensitivity': 'internal'} SEGUNDA_ESCRITA_IGUAL True
WRITER '        meta: # classificação\n          sensitivity: internal' META_LIDO {'sensitivity': 'internal'} SEGUNDA_ESCRITA_IGUAL True
BLOCK_PRESERVA {'name': 'x', 'description': 'Novo', 'meta': {'description_inherited': True, 'sensitivity': 'public'}}
```

**R4-B — escritor completo, perda da marca e persistência da recusa.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/full.py
```

Apenas na cópia, `quantity` começa com “Texto provisório escrito à mão.” e
`meta: {sensitivity: internal}`, sem marca. A geração escreve nela o texto
herdado real. Depois a sonda substitui `cast(quantity as integer)` por `100`,
tanto no SQL da cópia quanto em `raw_code` e `compiled_code` do manifest. Isso
faz a expressão nova entrar na derivação; não representa um build executado.
O cache também fica na cópia. Trechos literais, omitidos os avisos conhecidos:

```text
BASE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
PRIMEIRA_GERACAO_META_INLINE RC 0 OUT escrito: dbt/models/staging/_retail__models.yml
classificação e descrição derivadas de 2983 colunas em 199 nós; 1 arquivo(s) escrito(s) ERR trocado: stg_retail__order_items.quantity: texto sem `description_reason`, diferente do herdado, reescrito
CHECK_META_INLINE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
META_INLINE_LIDO {'sensitivity': 'internal'}
CONSTANTE_APOS_WRITER_INLINE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
CONSTANTE_COM_MARCA RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR gerador: stg_retail__order_items.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`
GERACAO_CONSTANTE_COM_MARCA RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) escrito(s) ERR gerador: stg_retail__order_items.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`
RECHECK_CONSTANTE_COM_MARCA RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR gerador: stg_retail__order_items.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`
MODELO_MOVIDO_ENTRE_ARQUIVOS RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
```

Os três controles finais usam o bloco original com marca: nem a geração apaga
a evidência, nem uma segunda verificação deixa de acusá-la. Mover a entrada
marcada de `dim_brand` para outro YAML, sem mudar seu SQL, também preservou o
resultado. O defeito demonstrado é do escritor, não dessas transições.

**R4-C — resolução de união, oráculo PostgreSQL e limites da prova.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/types.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/extra_union.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r4-review/oracle.sql
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r4-review/warehouse.sql
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r4-review/materialized.sql
```

Servidor consultado: `PostgreSQL 16.15`; `transaction_read_only=on`;
`TimeZone=UTC`. Todas as consultas são `SELECT`/`SHOW`. `oracle.sql` termina
com retorno 3 **esperado**, no controle `money ∪ numeric`: `ERROR: UNION could
not convert type numeric to money`. Os demais arquivos SQL retornaram zero.
Isso também impede tratar “mais alto” como algoritmo geral de toda categoria.

| Combinação exercitada | PostgreSQL medido | Motor atual | Avaliação |
|---|---|---|---|
| `smallint ∪ numeric`; `smallint ∪ 1.5` | `numeric`, preserva `123`/`1` e `1.5` | `Carry` | Correto para o ramo transportado. O literal `1.5` **tem** tipo `numeric`; não é `unknown`, embora o motor não o anote em `constant_type`. |
| `numeric(12,2) ∪ numeric(14,4)` | `numeric`, `123.45` e `1.2345` | `Carry` | Não estreita a escala neste caso. |
| `real ∪ double precision` | `double precision`, `0.10000000149011612`; igualdade com o `real` original é `t` | `union_coercion` | Recusa conservadora preexistente: alargar `real` para `double` conserva o valor binário. Não é passe silencioso nem nova descrição falsa. |
| `date ∪ timestamp` | `timestamp without time zone`, meia-noite para a data | `union_coercion` | Correto segundo a regra do projeto de não herdar mudança de data para instante. |
| `interval` com qualificadores; constante convertida para `interval` | `interval`, `1 day` e `2 days 12:00:00` | Literal `INTERVAL` é cálculo; `cast('1 day' as interval)` permite `Carry` com folha `INTERVAL` | Conservador na primeira grafia; sem perda demonstrada. |
| Booleanos | `boolean` | `Carry` | Correto para valores booleanos reais. Strings parecidas são outro caso, em R4-D. |
| `bigint[] ∪ real[]`; `numeric(14,4)[] ∪ real[]` | `real[]`, com arredondamento | `Carry` | Falha de R4-02. |
| `varchar(4) ∪ text` | `character varying` nesta ordem; preserva espaços | `Carry` | Correto neste caso; não prova que todas as conversões de texto sejam idênticas. |
| `NULL::text ∪ char(4)` | `text`, `octet_length=1` para `'a'`; antes era 4 | `Carry` | Perde preenchimento, diferentemente de `varchar`; limite preexistente de R4-02. |
| `date ∪ '2020-01-01'` | `date` | `Carry` | A string sem tipo explícito resolve pelo ramo `date`. |
| `timestamp ∪ NULL::timestamp(6) with time zone` | `timestamp with time zone` | `union_coercion` | Correto pelo caminho SQLGlot, que produz `TIMESTAMPTZ(6)`. |

Trechos literais da contraprova:

```text
ARRAY CANON BIGINT[] ATUAL {'x': Carry(leaves=frozenset({('trusted', 'a', 'x')}))} ANTES {'x': Computed(kind='union_coercion', shape=None, type=None)}
MODELOS R3_ORIGINAL TIPOS [None, 'REAL', None] TRANSPORTE Computed(kind='union_unproven', shape=None, type=None) TEXTO None PROBLEMAS [] []
UNKNOWN_TYPED {'x': Computed(kind='union_unproven', shape=None, type=None)}
R2_NESTED {'x': Computed(kind='union_coercion', shape=None, type=None)}
R2_DEEP {'x': Computed(kind='union_coercion', shape=None, type=None)}
CHAR_REVERSE {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
NUMERIC_ARRAY {'x': Carry(leaves=frozenset({('raw', 'a', 'x')}))}
```

Com dois modelos calculados (`'{16777217}'::bigint[]` e `'{0}'::real[]`),
`derive()` conhece `BIGINT[]` e `REAL[]`; `derive_texts()` devolve
`TEXTO Valor exato de origem. PROBLEMAS [] []` para a união. A comparação
`ANTES` acima carrega o código de `2ab4d4e` via `git show`, com a mesma folha
**de tipo conhecido** e constante tipada; não atribui ao código antigo uma
inferência entre modelos que ele ainda não fazia.

Saída do servidor:

```text
    caso    | pg_typeof |        x
------------+-----------+-----------------
 array_loss | real[]    | {1.6777216e+07}
 array_loss | real[]    | {0}

     caso      | pg_typeof |        x
---------------+-----------+-----------------
 array_decimal | real[]    | {1.6777218e+07}
 array_decimal | real[]    | {0}

     caso     | pg_typeof | octet_length | x
--------------+-----------+--------------+---
 char_reverse | text      |              |
 char_reverse | text      |            1 | a
```

`canonical_type` também apaga o sufixo de array em `numeric(12,2)[]`, devolvendo
`NUMERIC`. A forma longa `timestamp(6) with time zone` vira `TIMESTAMP`, mas
as entradas exercitadas pela derivação passam antes pelo SQLGlot e chegam
como `TIMESTAMPTZ(6)`, corretamente reconhecida. Não registrei esta última
chamada direta como falha independente de produção. `float(24)` também vira
`DOUBLE PRECISION` na função isolada; a matriz exercitou seu caminho SQL.

A alegação de que união construída prova tipos físicos iguais não é válida:
ela prova que o servidor encontrou conversões compatíveis. A concatenação de
arrays em R4-D é inclusive anotada `TEXT` e depois aceita junto a `REAL[]`,
embora seus tipos físicos sejam `BIGINT[]` e `REAL[]` e haja perda. A resolução
é por ordem, categoria e conversões implícitas; a [documentação do PostgreSQL
16](https://www.postgresql.org/docs/16/typeconv-union-case.html) não autoriza
substituir esse algoritmo por igualdade física presumida. A distinção entre
literal numérico e string está na [sintaxe de constantes do PostgreSQL
16](https://www.postgresql.org/docs/16/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS).

**R4-D — anotação incorreta de tipos na fronteira de modelos.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/materialized.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/history.py
```

As sondas montam dois modelos: o primeiro tem texto próprio; o segundo aplica
um cast. Usam `derive()` e `derive_texts()`, não só a função de tipos. Saída:

```text
STRING_BOOL TIPO_A BOOLEAN TRANSPORTE_B Carry(leaves=frozenset({('trusted', 'a', 'x')})) TEXTO_B Código textual; preserve a grafia original. PROBLEMAS [] []
ARRAY_TEXT TIPO_A TEXT TRANSPORTE_B Carry(leaves=frozenset({('trusted', 'a', 'x')})) TEXTO_B Lista de identificadores inteiros. PROBLEMAS [] []
BIT_CONCAT TIPO_A TEXT TRANSPORTE_B Carry(leaves=frozenset({('trusted', 'a', 'x')})) TEXTO_B Máscara de bits. PROBLEMAS [] []
STRING_BOOL 2ab4d4e TIPO_A None TRANSPORTE_B Computed(kind='cast', shape=None, type=None)
STRING_BOOL afca255 TIPO_A BOOLEAN TRANSPORTE_B Carry(leaves=frozenset({('trusted', 'a', 'x')}))
ARRAY_TEXT 2ab4d4e TIPO_A None TRANSPORTE_B Computed(kind='cast', shape=None, type=None)
ARRAY_TEXT afca255 TIPO_A TEXT TRANSPORTE_B Carry(leaves=frozenset({('trusted', 'a', 'x')}))
```

`history.py` carrega os dois módulos antigos com `git show` e repete o mesmo
manifest em memória. O oráculo SQL de R4-C usa CTEs, sem materializar nada:

```text
    caso     | antes | depois  |  x   | x
-------------+-------+---------+------+---
 STRING_BOOL | text  | boolean | true | t

    caso    |   antes   | depois |    x    |    x
------------+-----------+--------+---------+---------
 ARRAY_TEXT | integer[] | text   | {1,2,3} | {1,2,3}

   caso   |    antes    | depois |  x   |  x
----------+-------------+--------+------+------
 BIT_TEXT | bit varying | text   | 1001 | 1001
```

Outros sintomas medidos da mesma inferência: `materialized_type` dá `NUMERIC`
tanto a `1.5` quanto a `'1.5'`, e `INTEGER` a `2147483648` e
`9223372036854775808`; o servidor dá respectivamente `numeric`, `text`,
`bigint` e `numeric`. Esses sintomas não precisam de achados separados: a
causa é perder a espécie/faixa do literal e tratar uma hipótese como prova.

**R4-E — declarações atrasadas, macro e fluxo dos dois geradores.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/full.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/stale.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/flow.py
```

Trechos literais das verificações, sempre na cópia:

```text
PONTE_NIVEL_ALTERADO RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (declaração de legado__brands); rode `make dbt-build` antes — nenhum arquivo é tocado
MACRO_ANTIGA_COMENTADA RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (macro empilhado); rode `make dbt-build` antes — nenhum arquivo é tocado
SEED_NIVEL ['declaração de brazilian_states']
FONTE_NAO_ESPELHADA governance ['declaração da fonte governance.legacy_captures']
SEED_REMOVIDA_STALE []
SEED_DECLARACAO_REMOVIDA RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
```

A remoção afeta só a entrada YAML de `order_status_transitions`; a seed CSV
continua presente. Para conferir o efeito de um manifest correspondente, a
sonda adicional executou `s.derive({'sources': {}, 'nodes': {uid: no}})` com
esse nó e `no['columns'] = {}` em memória. Saída, em
`/tmp/rvl3-r4-review/seed_reparsed.txt`:

```text
SEED_SEM_DECLARACAO_MANIFEST_ATUAL ['seed.mvp_ed1.order_status_transitions: coluna `from_status` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado', 'seed.mvp_ed1.order_status_transitions: coluna `to_status` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado', 'seed.mvp_ed1.order_status_transitions: coluna `is_initial` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado', 'seed.mvp_ed1.order_status_transitions: coluna `description` da seed sem `sensitivity` em dbt/seeds/_seeds.yml — seed é declaração, não derivado']
```

`flow.py` muda **somente em memória** a descrição SQLAlchemy de
`orders.total_amount`. Executa a parte de classificação/descrição do catálogo
na cópia, `legacy.cli.main(['models'])` com diretório corrente na cópia e
novamente a derivação e o check. Não executa o alvo completo `make catalog`
no checkout, nem afirma ter testado exportação do dicionário/linhagem nesse
fluxo. A primeira geração retorna 1 pelos textos da ponte/fonte legada ainda
antigos, como esperado; chega a escrever o staging necessário ao gerador.
A guarda não acusa declaração atrasada em nenhuma das duas etapas:

```text
STALE_1 []
LEGACY_MODELS RC 0 OUT 93 modelos e a declaração de fontes em dbt/models/staging/legacy/
STALE_2 []
CATALOG_2 RC 0 OUT escrito: dbt/models/analytics/_analytics__models.yml
escrito: dbt/models/trusted/_trusted__models.yml
classificação e descrição derivadas de 2983 colunas em 199 nós; 2 arquivo(s) escrito(s) ERR trocado: orders.order_total_amount: texto sem `description_reason`, diferente do herdado, reescrito
trocado: coupon_redemptions.order_total_amount: texto sem `description_reason`, diferente do herdado, reescrito
trocado: fact_coupon_redemption.order_total_amount: texto sem `description_reason`, diferente do herdado, reescrito
CATALOG_CHECK RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
MARCAS_APOS_LEGACY 1378
TEXTOS_PONTE 417 COM_DESCRIPTION_FROM 417 COM_MARCA 0
```

O gerador do legado não retirou nenhuma das 1.378 marcas. As 417 descrições
de ponte não usam `description_inherited`: são escritas pelo outro gerador e
todas têm `description_from`, conferido contra o par. As fontes espelhadas
são declaração SQLAlchemy, não texto promovido a raiz manual. Logo, “todo
texto gerado leva a marca” precisa ser entendido como o texto herdado escrito
pelo motor de `make catalog`, não todo arquivo produzido por qualquer gerador.
Não contei essas exceções deliberadas como 417 falhas de proveniência.

**R4-F — `valid_to`, outras uniões reais e Governança v2.15.**

Além dos SQLs de R4-C, executei:

```sh
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r4-review/physical.sql -t -A > /tmp/rvl3-r4-review/physical.json
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/physical.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r4-review/inventory.py
```

`physical.sql` lê somente nomes/tipos de colunas do catálogo do servidor.
`physical.py` repete a derivação em memória com esses tipos como referência;
não altera a regra do checkout. `inventory.py` conta as uniões na AST:

```text
FISICOS 4254 PROBLEMAS []
UNIONS_AST_NOS 40 OPERACOES 135
TRANSPORTES_HERDADOS_QUE_MUDAM_EM_MODELOS_COM_UNIAO [('stg_retail__inventory_movements', 'quantity_delta', "Computed(kind='cast', shape=None, type='INT')")]
UNIAO_COERCAO_ATUAL [('dim_support_agent', 'valid_to')]
SNAPSHOT_CONFIG [('scd_coupon', 'check', None), ('scd_customer', 'check', None), ('scd_support_agent', 'check', None), ('scd_product', 'check', None)]
```

A diferença de `quantity_delta` é o cast de retorno ao tipo declarado da
origem, permitido expressamente pelo contrato do staging: o Airbyte grava
inteiros mais largos. Ela não demonstra outra união perdendo valor. Não
identifiquei outra herança real indevida por coerção nas uniões inventariadas.
Isso não transforma a sonda em prova de todos os valores futuros.

O texto novo de `dim_support_agent.valid_to` **está correto para o SQL atual**:
o snapshot fornece `timestamp`, e o ramo desconhecido fornece `NULL::timestamptz`.
O servidor confirmou os tipos de todas as dimensões SCD:

```text
 analytics | dim_coupon        | valid_from | timestamp with time zone
 analytics | dim_coupon        | valid_to   | timestamp without time zone
 analytics | dim_customer      | valid_from | timestamp with time zone
 analytics | dim_customer      | valid_to   | timestamp without time zone
 analytics | dim_product       | valid_from | timestamp with time zone
 analytics | dim_product       | valid_to   | timestamp without time zone
 analytics | dim_support_agent | valid_from | timestamp with time zone
 analytics | dim_support_agent | valid_to   | timestamp with time zone
```

Nos quatro snapshots, `dbt_scd_id` é `text`, e `dbt_updated_at`,
`dbt_valid_from`, `dbt_valid_to` são `timestamp without time zone`:
`SNAPSHOT_TYPES` corresponde ao estado observado. Conferi também o adaptador
instalado: `postgres__snapshot_get_time()` faz
`current_timestamp()::timestamp without time zone`. Os quatro usam `check`
sem `updated_at` explícito. Essa tabela fixa de tipos não é prova para outra
estratégia/configuração: `snapshot_check_strategy` aceita `updated_at`, e a
revisão não exercitou uma migração desse contrato.

As outras três dimensões **não** fazem a conversão em `valid_to`; todas as
quatro a fazem em `valid_from`, no `CASE` entre a primeira data já tipada como
`timestamptz` e `dbt_valid_from`. Esses `valid_from` têm texto próprio; não são
um transporte aceito indevidamente. A dependência de fuso é real, mesmo sem
mudar a sessão:

```text
   caso   |          utc           |       sao_paulo
----------+------------------------+------------------------
 timezone | 2020-01-01 12:00:00+00 | 2020-01-01 15:00:00+00

 caso |  modelo  |  n   | encerradas
------+----------+------+------------
 SCD  | customer | 1574 |          0
 SCD  | product  |  622 |          0
 SCD  | coupon   |   19 |          0
 SCD  | agent    |    7 |          0
```

A consulta compara `AT TIME ZONE 'UTC'` e `AT TIME ZONE 'America/Sao_Paulo'`
sobre um literal. Não abriu versão SCD. Hoje todos os `dbt_valid_to` estão
nulos; o efeito em valores encerrados foi provado com literal, não observado
numa segunda versão real.

**Ponto para decisão do Owner, não correção autorizada nesta revisão:** vale
avaliar tornar explícito em SQL o contrato temporal dos snapshots/dimensões.
Trocar somente o nulo do membro desconhecido por `timestamp` alinha o
`valid_to` do atendente aos demais, mas altera o tipo da dimensão e não resolve
a interpretação de `valid_from`. Interpretar o snapshot com um fuso explícito
ou rever seu tipo envolve semântica e histórico; não escolhi uma dessas
alternativas nem alterei ADR, SQL ou pendências. O texto novo documenta o que
acontece; não elimina a dependência da sessão.

Na Governança §5.1 v2.15, a marca na coluna, a contradição com motivo, as
convenções, o fluxo dos dois geradores e a recusa de macro comentada
correspondem ao caminho normal medido. As garantias gerais de proveniência,
preservação de tipo e atualidade precisam das correções de R4-01 a R4-04.
A afirmação sobre “tipo mais alto” cobre a lista numérica/temporal
implementada, não todo o algoritmo PostgreSQL; `real → double` ainda é
recusado apesar de preservar valor. A ressalva de macro apagada continua
imprecisa: a macro já presente no manifest, cujo arquivo/trecho desapareceu,
é detectada; falta reconciliação geral do inventário. Não abri um quinto
achado só para repetir essas imprecisões documentais.

**R4-G — regressão e limites da execução.**

```sh
PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider' make check-offline
PYTHONDONTWRITEBYTECODE=1 make secrets-history
```

Ambos retornaram zero. Trechos literais dos logs
`/tmp/rvl3-r4-review/check-offline.txt` e `secrets-history.txt`:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 665 citações de ADR — nada quebrado
826 passed, 188 deselected in 178.81s (0:02:58)
check-offline: as três etapas passaram
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os 188 testes de integração foram excluídos e listados pelo alvo; não foram
executados. Não remedi o `make check` do autor (`PASS=907`, `1011 passed,
3 skipped`): ele faria build, fora desta autorização. Não executei criação
de segunda versão SCD, rebuild, alteração dos comentários físicos ou carga.
Os checks verdes convivem com as contraprovas acima; não encerram os quatro
achados. Nenhuma decisão de arquitetura ou aprovação da entrega foi tomada.

### Mudança pedida pelo Owner nesta rodada — `valid_to` no SQL

O Owner autorizou corrigir no SQL, e não só no texto, a conversão que a rodada 3 achou em
`dim_support_agent.valid_to` ("se mudar o `valid_to` for melhor, pode mudar; não há usuários reais
desta base"). Medido antes: o armazém roda em UTC (`show timezone` → `UTC`), o snapshot grava
`dbt_valid_*` como `timestamp` sem fuso, e nas **quatro** dimensões SCD o `valid_from` saía
`timestamptz` (convertido implicitamente pelo `case`) e o `valid_to` saía `timestamp` sem fuso — salvo
em `dim_support_agent`, `timestamptz` pela união. As fatos comparam `timestamptz` com `valid_to`, o
que só funcionava porque a sessão era UTC. Feito: `at time zone 'UTC'` explícito no `valid_from` e
no `valid_to` das quatro (`dim_customer`, `dim_coupon`, `dim_product`, `dim_support_agent`), os dois
agora `timestamptz` em todas (medido no armazém depois do build); o teste dbt
`snapshot_grava_em_utc` falha se a sessão do dbt sair de UTC; e os textos de `valid_from`/`valid_to`
dizem a leitura em UTC. Sob UTC os valores são os mesmos — as reconciliações e a fato incremental
passaram no build (`PASS=908`).


## Rodada 5 — lote 3

Revisão exclusiva de `afca255..9cef25b` (os quatro commits indicados), com
HEAD em `9cef25b7cad049cfddd588ded6723f9f0103a00b`, em 05/11/2026.
**Parecer técnico, sem aceite ou poder de aprovação. Nenhuma correção
implementada. O lote 3 continua aberto: dois bloqueantes e um ajuste.**

Somente `REVISAO.md` foi editado no checkout. As sondas e cópias estão em
`/tmp/rvl3-r5-review`; os dois arquivos não rastreados preexistentes foram
preservados. SQL pelo `ro.sh` autorizado, com `transaction_read_only=on`.
Não houve build, carga, alteração de papel/banco, escrita na memória do
legado, acionamento/pausa de `fluxo_batch` ou troca de ambiente. Os `SET LOCAL`
das contraprovas de fuso ficaram em transações somente leitura encerradas
com `ROLLBACK`. `dbt ls` foi executado apenas numa cópia em `/tmp`.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-5-01 | `dbt/tests/snapshot_grava_em_utc.sql:8`; `airflow/dags/fluxo_batch.py:295–338`; Qualidade §4 | **O teste não protege a gravação do snapshot contra mudança de fuso.** Ele não tem pais nem filhos no grafo. A seleção conjunta dos testes das camadas da DAG e de `tag:fronteira` contém 690 testes e **zero** ocorrências dele; a tarefa de snapshots usa `dbt snapshot`, que não executa testes. No build completo ele é selecionado, mas sua falha não bloqueia snapshots sem dependência dele: não há `--fail-fast` obrigatório nem uma validação antes da gravação. Uma mudança ordinária de `TimeZone` do papel/banco pode fazer a DAG inteira gravar horas locais e lê-las como UTC, sem essa catraca. A sonda somente leitura mostra deslocamento de três horas e uma versão escolhida antes de sua abertura real. Os valores atuais em UTC não mudaram (R5-A). Garantir a premissa no caminho que grava, antes da escrita, e ajustar a afirmação “o teste falha antes”. **Regressão/garantia incompleta de 6bd6447: a dependência de fuso já existia, mas a interpretação agora fixa exige UTC no escritor, que o novo teste não assegura.** R5-A/B. | `bloqueante` | **Corrigido no escritor, e o teste saiu.** Você tem razão: o teste não tinha pais nem filhos e o `dbt snapshot` da DAG não roda testes. A premissa foi removida em vez de vigiada: `dbt/macros/snapshot_get_time.sql` sobrepõe a macro do dbt-postgres (`now()::timestamp without time zone`, hora local da sessão) por `(now() at time zone 'UTC')`, nas duas portas — a chamada direta e `postgres__snapshot_get_time`, que a checagem de tipo do snapshot chama por `adapter.dispatch`. O tipo continua `timestamp` sem fuso. Medido: um `dbt snapshot` depois da mudança deixou no `dbt.log` 60 ocorrências de `(now() at time zone 'UTC')` e **zero** de `now()::timestamp without time zone`; antes da segunda porta, a checagem de tipo ainda usava a do adaptador. Assim nenhum modelo do projeto depende do fuso da sessão: o snapshot grava UTC, as dimensões leem UTC, e as fatos reduzem instante a data com `America/Sao_Paulo` explícito (conferido nos modelos). `dbt/tests/snapshot_grava_em_utc.sql` foi removido; `tests/test_vigencia_em_utc.py` confere as duas macros, a leitura nas quatro dimensões e que o manifest as carrega. Qualidade §4 reescrita: a guarda está no escritor. |
| RVL3-5-02 | `src/mvp_ed1/models/sensitivity.py:784–795,902–903`; `descriptions.py:168–177,281–284`; Governança §5.1 | **A marca ainda pode desaparecer na leitura e o catálogo passar silenciosamente.** `verify_meta` só percorre `textos.marks`, que contém marcas **novas**, não todas as entradas lidas nem os gerados. No HEAD sem alterações esse conjunto tem zero arquivos. Uma segunda entrada da mesma coluna sem marca, ou uma segunda chave `meta`, encobre a primeira marcada. Se a expressão passou a calcular, nenhuma marca nova é solicitada; o YAML não passa pelo carregador estrito e o texto antigo vira raiz `written`. Na cópia completa, `quantity = 100` conserva “Quantidade comprada do SKU.” e check → geração → check retornam **0**, tanto com coluna duplicada quanto com `meta` duplicado; sem a duplicidade, retornam 1. `dbt ls` também aceita a coluna duplicada. Além disso, `verify_meta` não recusa nomes de coluna repetidos em sequência, pois os reduz a dicionário. Duplicidade acidental durante edição/merge é mudança ordinária; não exige apagar a marca original. Validar os documentos antes de perder essas ocorrências, incluindo unicidade de nomes, e cobrir a proveniência já existente. **Preexistente; fechamento incompleto de RVL3-4-01/RVL3-3-01/RVL3-2-01, não nova regressão demonstrada.** R5-C. | `bloqueante` | **Corrigido na leitura.** `sensitivity.read_yaml` — o carregador de C com o construtor de mapa que recusa chave repetida — lê **todo** `.yml` do projeto (`descriptions._documents`, `manual_entries`, `generator_entries`, `_declaracoes_no_disco`, `verify_meta`) e recusa coluna listada duas vezes numa entrada; `_documents` recusa também a mesma entrada em dois arquivos. Seus dois casos (coluna duplicada sem a marca, `meta` duplicado) agora param o `make catalog` e o `--check` com "recusado: … nenhum arquivo é tocado", antes de qualquer marca se perder. A conferência deixou de depender de haver marca nova. Teste `test_a_leitura_nao_deixa_uma_segunda_ocorrencia_encobrir_a_marca`; contraprova com `9cef25b`: não recusava. |
| RVL3-5-03 | `src/mvp_ed1/models/transport.py:183–185,317–329` | **Array textual com parâmetro ainda é provado falsamente como texto escalar.** `canonical_type('VARCHAR(8)[]')` apaga tudo a partir do parêntese e devolve `VARCHAR`. Assim, `_e_texto` aceita os operandos de `'{abcdef}'::varchar(8)[] \|\| '{}'::varchar(8)[]`; o primeiro modelo recebe tipo conhecido `TEXT`, e `x::text` no segundo fica `Carry`, herdando a descrição sem problema. PostgreSQL confirma `character varying[] → text`: houve serialização da lista, não transporte intacto. Também ocorre com operandos vindos de colunas tipadas. Arrays parametrizados são SQL normal, embora não haja coluna atual afetada identificada. A prova deve conservar o contêiner array; retirar somente parâmetros não prova escalaridade. **Preexistente em `afca255`; a nova prova cobre arrays sem parâmetro e bits, mas não fecha RVL3-4-03 integralmente.** R5-D. | `ajuste` | **Corrigido.** `canonical_type` tira só os parâmetros (`(8)`, `(12,2)`) e conserva o `[]`: `VARCHAR(8)[]` → `VARCHAR[]`, que não é texto escalar; `_e_texto` e as regras da união o tratam como array. Seu caso `'{…}'::varchar(8)[] \|\| …` não recebe mais tipo `TEXT`. Caso no teste da união; contraprova com `9cef25b`: `'VARCHAR' == 'VARCHAR[]'`. |

### Conferência das respostas e dos itens anteriores ainda encadeados

“Fechado” significa encerramento do achado técnico específico, não aprovação
da entrega. Os comandos abaixo usam `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python`
e os scripts de `/tmp/rvl3-r5-review`; as saídas estão nas subseções seguintes.

| Achado | Resultado nesta rodada | Comando e saída |
|---|---|---|
| RVL3-4-01 | **Não fechado integralmente.** Inline recusado e comentário preservado; a leitura ainda perde proveniência por duplicidade e não é validada em todos os caminhos. | `full.py`: `PRIMEIRA_GERACAO_META_INLINE RC 1`, `CHECK_META_INLINE RC 1`; `yaml_extra.py`: `FULL DUP_COLUMN_SHADOW ['--check'] RC 0` e `FULL DUP_META_SHADOW ['--check'] RC 0`. R5-C. |
| RVL3-4-02 | **Fechado para os escapes levantados.** Arrays de tipos diferentes e `CHAR/TEXT` deixaram de transportar. As combinações adicionais não demonstraram nova coerção com perda aceita pela allowlist. | `types.py`: `ARRAY … union_coercion`, `CHAR_TEXT … union_coercion`; `extra_union.py`: `NUMERIC_ARRAY … union_coercion`, `CHAR_REVERSE … union_coercion`. R5-D. |
| RVL3-4-03 | **Não fechado integralmente.** Espécie da string, arrays simples e bits corrigidos; arrays textuais parametrizados continuam anotados como `TEXT`. | `materialized.py`: `STRING_BOOL TIPO_A TEXT … Computed(kind='cast' …) TEXTO_B None`; `types_extra.py`: `VARCHAR_ARRAY_CONCAT … TIPO_A TEXT B Carry … PROBLEMAS [] []`. R5-D. |
| RVL3-4-04 | **Fechado.** Remoção da entrada inteira recusa o manifest antigo; mover a declaração conservando seu conteúdo não causa falso positivo. | `full.py`: `SEED_REMOVIDA_STALE ['declaração de order_status_transitions']`, `SEED_DECLARACAO_REMOVIDA RC 1`; `stale_extra.py`: `SEED_ENTRY_MOVED []`. R5-E. |
| RVL3-3-01 | **Não fechado integralmente**, pela leitura que esconde a marca em R5-02. Renomeações/promoção com marca continuam recusadas corretamente. | `transitions.py`: `COLUNA_RENOMEADA`, `MODELO_RENOMEADO`, `GERADO_PROMOVIDO` com problema `não transporta mais (mul)`; `yaml_extra.py`: duplicidades com RC 0. |
| RVL3-2-01 | **Não fechado integralmente**, pela mesma perda de proveniência. Dois saltos com marca estão cobertos. | `transitions.py`: `DOIS_SALTOS PROBLEMAS ['b.v: não transporta mais (mul) …']`; contraprova R5-C. |
| RVL3-01 | **Permanece aberto na cadeia da proveniência**, embora o exemplo original simples seja recusado. | `full.py`: `CONSTANTE_COM_MARCA RC 1`; `yaml_extra.py`: `DUP_COLUMN_SHADOW`/`DUP_META_SHADOW` com RC 0. |
| RVL3-3-03 | **Fechado quanto à união de folhas desconhecidas**; a resposta como conjunto ainda depende de R5-03. | `types.py`: `MODELOS R3_ORIGINAL … union_unproven … TEXTO None PROBLEMAS [] []`; `extra_union.py`: `UNKNOWN_TYPED … union_unproven`. |
| RVL3-02 e RVL3-2-02 | **Fechados quanto às coerções de união demonstradas nessas rodadas.** A recusa das subuniões continua funcionando. | `extra_union.py`: `R2_NESTED … union_coercion`, `R2_DEEP … union_coercion`; R5-D para a matriz ampliada. |
| RVL3-3-04 | **Fechado quanto aos metadados lidos do manifest**, inclusive declaração retirada, renomeada ou movida. | `full.py`: ponte alterada e seed retirada com RC 1; `stale_extra.py`: fonte renomeada/removida acusa suas duas tabelas. R5-E. |
| RVL3-2-07 | **Fechado quanto aos escapes concretos de macro e declaração apontados nas rodadas anteriores.** Não virou verificador geral de atualidade: inventário novo e `dbt_project.yml` continuam limites declarados. | `full.py`: `MACRO_ANTIGA_COMENTADA RC 1`, `PONTE_NIVEL_ALTERADO RC 1`, `SEED_DECLARACAO_REMOVIDA RC 1`; `stale.py`: seed e fonte não espelhada alteradas acusadas. |

RVL3-3-02 e RVL3-3-05, já fechados na rodada 4, não reabriram:
`transitions.py` continua normalizando as quatro grafias de `doc()` para
`'{{ doc("x") }}'`; `full.py` continua recusando a macro antiga comentada.
Os demais itens encerrados anteriormente não foram submetidos a uma revisão
nova fora do intervalo solicitado.

### Evidências da rodada 5

**R5-A — SQL anterior e novo, resultados e limites temporais.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/temporal.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r5-review/temporal.sql
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r5-review/temporal_edges.sql
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r5-review/oracle.sql
```

`temporal.py` reconstrói as quatro dimensões anteriores removendo **somente**
os dois `at time zone 'UTC'` de cada SQL compilado; mantém o `CASE` e a união
com o membro desconhecido. Substitui as referências a essas dimensões por
CTEs, recursivamente, nos dez fatos e nas dezesseis views descendentes. Compara
linhas completas e multiplicidades com `EXCEPT ALL` nos dois sentidos, numa
única transação `REPEATABLE READ READ ONLY`, em UTC. São CTEs da consulta, não
objetos persistidos. Nenhum resultado anterior é estimado por contagem apenas.

A primeira passada conserva inclusive a janela incremental compilada de
`fact_inventory_movement`. O resumo abaixo foi produzido por
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/temporal_summary.py`,
que extrai as linhas do log SQL e exige 26 objetos, ausência de erro e o
`ROLLBACK` final:

```text
OBJETOS 26 FATOS 10 VIEWS 16 DIFERENCAS 0
objeto | n_antes | n_depois | diferencas
average_order_value_by_channel_and_segment | 751 | 751 | 0
cart_conversion_rate_by_channel | 96 | 96 | 0
discount_share_by_channel | 387 | 387 | 0
fact_cart_event | 81354 | 81354 | 0
fact_coupon_redemption | 602 | 602 | 0
fact_inventory_movement | 2673 | 2673 | 0
fact_order_status_event | 16432 | 16432 | 0
fact_payment_transaction | 7426 | 7426 | 0
fact_purchase_order_item | 1630 | 1630 | 0
fact_refund | 120 | 120 | 0
fact_sales_order_item | 7738 | 7738 | 0
fact_shipment_item | 7556 | 7556 | 0
fact_support_ticket_event | 1727 | 1727 | 0
gross_margin_by_category | 532 | 532 | 0
inventory_turnover_by_sku_and_warehouse | 919 | 919 | 0
monthly_revenue_by_channel_and_category | 1494 | 1494 | 0
new_and_repeat_customers_by_month | 560 | 560 | 0
on_time_delivery_rate_by_carrier | 1175 | 1175 | 0
order_to_delivery_time_by_region | 1857 | 1857 | 0
payment_approval_rate_by_method | 537 | 537 | 0
refund_rate_by_reason | 105 | 105 | 0
repeat_purchase_rate_after_support | 175 | 175 | 0
revenue_by_delivery_region | 469 | 469 | 0
skus_below_reorder_point | 532 | 532 | 0
support_tickets_per_hundred_orders | 118 | 118 | 0
top_skus_by_revenue | 25 | 25 | 0
```

Para cobrir também o histórico fora da janela, a segunda sonda retira
**simetricamente**, apenas no SQL da consulta, o predicado incremental de
varejo. Reconstrói a fato de estoque inteira e suas três views descendentes;
as demais 22 consultas já não tinham esse recorte:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/temporal_full_inventory.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl3-r5-review/temporal_full_inventory.sql
```

```text
objeto | n_antes | n_depois | diferencas
fact_inventory_movement | 16398 | 16398 | 0
gross_margin_by_category | 542 | 542 | 0
inventory_turnover_by_sku_and_warehouse | 6402 | 6402 | 0
skus_below_reorder_point | 532 | 532 | 0
```

Nenhuma diferença de resultado foi encontrada nos dez fatos e dezesseis views
nesses recortes complementares, incluindo o histórico completo de estoque.

O servidor confirmou `PostgreSQL 16.15`, `transaction_read_only=on`,
`TimeZone=UTC` e os **oito** campos `valid_from`/`valid_to` como
`timestamp with time zone`. O estado SCD continua sem versões encerradas:

```text
    modelo     |  n   | encerradas
---------------+------+------------
 customer      | 1574 |          0
 coupon        |   19 |          0
 product       |  622 |          0
 support_agent |    7 |          0
```

Por isso a prova com dados atuais não exercita `valid_to` não nulo. A sonda
adicional usa somente literais em CTEs para as bordas de uma versão fechada:

```text
               t               | antes | depois
-------------------------------+-------+--------
 2026-11-05 11:59:59.999999+00 | f     | f
 2026-11-05 12:00:00+00        | t     | t
 2026-11-05 12:59:59.999999+00 | t     | t
 2026-11-05 13:00:00+00        | f     | f
```

O adaptador instalado e o `macro_sql` do manifest confirmam:

```jinja
{% macro postgres__snapshot_get_time() -%}
  {{ current_timestamp() }}::timestamp without time zone
{%- endmacro %}
```

Os quatro snapshots usam `check`, sem `updated_at` próprio. Logo,
`AT TIME ZONE 'UTC'` é a leitura correta **se a sessão que capturou estava em
UTC**; PostgreSQL não gravou UTC por propriedade intrínseca de `timestamp`.
O SQL novo remove a dependência do fuso do leitor, mas ainda depende do fuso
do escritor. Em sessão local `America/Sao_Paulo`, a reprodução de uma captura
real às 15:00 UTC mostrou:

```text
      real_capture      |   dbt_valid_from    |         antes          |         depois         | nova_versao_uma_hora_antes
------------------------+---------------------+------------------------+------------------------+----------------------------
 2026-11-05 12:00:00-03 | 2026-11-05 12:00:00 | 2026-11-05 12:00:00-03 | 2026-11-05 09:00:00-03 | t
```

O instante gravado sem fuso é reinterpretado três horas antes. Uma versão
nova pode então receber um evento ocorrido às 14:00 UTC, antes da captura
real. Isso é uma contraprova com literais; não foi aberta versão no warehouse.

Os oito textos novos correspondem às expressões sob a premissa UTC, com a
exceção da primeira versão explicitada no próprio texto. O início desta é
`2024-01-01 00:00-03` (03:00 UTC), não meia-noite UTC. A nota de `dim_product`
sobre escolher `period_start` em vez de infinito continua correta: o
[TIMESTAMP do BigQuery tem intervalo finito](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/data-types#timestamp_type).
Isso não prova execução do SQL PostgreSQL sem adaptação no BigQuery: a grafia
`AT TIME ZONE`, o tipo do snapshot de cada adaptador e a sintaxe já específica
do modelo precisam ser tratados na migração. Nenhum ADR aceito foi alterado.

**R5-B — seleção e alcance real do teste de UTC.**

Na cópia `/tmp/rvl3-r5-review/selection`, com as dependências dbt e os docs
disponíveis somente para leitura, executei (ambiente de conexão carregado do
`.env`, sem imprimi-lo):

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/dbt --quiet ls \
  --project-dir /tmp/rvl3-r5-review/selection/dbt --profiles-dir dbt \
  --select staging trusted quarantine analytics consumption tag:fronteira \
  --resource-type test --output name
PYTHONDONTWRITEBYTECODE=1 .venv/bin/dbt --quiet ls \
  --project-dir /tmp/rvl3-r5-review/selection/dbt --profiles-dir dbt \
  --select snapshot_grava_em_utc --resource-type test --output name
```

A primeira seleção é até mais ampla que a DAG, pois não aplica seus
`--exclude`. Contagem das saídas e leitura do manifest:

```text
UTC_TEST test.mvp_ed1.snapshot_grava_em_utc PARENTS [] CHILDREN []
DAG_SELECTION_TESTS 690 UTC_MATCHES 0
EXPLICIT_SELECTION ['snapshot_grava_em_utc']
```

`dbt snapshot` não executa testes; a tarefa final seleciona apenas
`tag:fronteira`, etiqueta que este teste não tem. No `make dbt-build` completo,
o teste roda, mas não é portão: `dbt/task/runnable.py:631–644` marca para pular
os dependentes do nó que falhou, e este não tem nenhum. A receita não impõe
`--fail-fast`. É o comportamento documentado de
[bloqueio dos descendentes no dbt build](https://docs.getdbt.com/reference/commands/build).
Não executei build defeituoso para provocar escrita: a conclusão sobre o
bloqueio vem do grafo e do executor instalado, não de alteração de dados.

O teste lê a sessão **dele**. `profiles.yml` usa quatro threads; o adaptador
`postgres/connections.py:159–206` abre conexões `psycopg2` sem fixar fuso, e
não há hook de fuso no projeto. No mesmo processo, com configurações estáveis,
as conexões de teste e snapshot herdam os mesmos defaults; não há garantia de
ser a mesma sessão nem de cobrir uma invocação distinta. `PGTZ` muda o default
via [libpq](https://www.postgresql.org/docs/16/libpq-envars.html); mudanças de
papel/banco valem para as conexões que as herdarem. Assim, **quando selecionado
e sob os mesmos defaults**, o teste detecta a mudança; ele não valida
retroativamente a sessão que escreveu nem previne a escrita nesta DAG.

O oráculo executou exatamente seu predicado: em UTC devolveu zero linhas;
com `SET LOCAL TIME ZONE 'America/Sao_Paulo'`, uma linha:

```text
  fuso_da_sessao
-------------------
 America/Sao_Paulo
(1 row)
```

O catálogo `pg_db_role_setting` não contém override de `timezone` no estado
consultado (`0 rows`). Não alterei `PGTZ` de processos do serviço nem defaults
de papel/banco; a propagação desses parâmetros foi conferida por código e
contrato do cliente, não por mutação de configuração. A frase “o teste falha
antes” no teste e na Qualidade §4 v1.16 não é sustentada por esse caminho.

**R5-C — R4-A/B, escrita YAML e proveniência que some na leitura.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/baseline.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/transitions.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/full.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/yaml_extra.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/yaml_validate_loaded.py
```

A derivação em memória do HEAD, sem cache escrito no checkout:

```text
STALE []
NOS 199 COLUNAS 2983
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
OBSOLETOS []
MARCAS 1375 ESPERADAS 1375 EXATAS True EXCEDENTES [] FALTANTES []
DETERMINISTICO True
VERIFY_SCOPE marks_files 0 generated_files 5 generated_marked_columns 290
```

A queda de 1.378 para 1.375 marcas corresponde aos três `valid_to` que saíram
da convenção herdada para texto próprio; o do atendente já tinha texto próprio.
Os três avisos conhecidos de `legacy_classifications` permanecem. A última
linha mede o conjunto que o `main` usa para chamar `verify_meta`: ele não
valida todos os arquivos marcados, e os cinco gerados, com 290 textos, também
não passam por essa função. Não encontrei marca faltante no HEAD atual.

A sonda original `transitions.py` executou as transições e depois terminou
com `ValueError` **esperado** no inline que antes passava; a matriz adicional
captura essas recusas para continuar até os outros formatos:

```text
WRITER NORMAL PASS [{'name': 'x', 'description': 'Novo', 'meta': {'description_inherited': True, 'sensitivity': 'public'}}]
WRITER COMMENT PASS [{'name': 'x', 'description': 'Novo', 'meta': {'description_inherited': True, 'sensitivity': 'public'}}]
WRITER INLINE RECUSA ValueError m.x: `meta` escrito em linha; escreva-o em bloco para o gerador editar
WRITER CRLF PASS [{'name': 'x', 'description': 'Novo', 'meta': {'description_inherited': True, 'sensitivity': 'public'}}]
WRITER FLOW_COLUMNS RECUSA KeyError '`m` sem `columns:` — a sensibilidade é escrita antes da descrição'
WRITER FLOW_MODELS RECUSA KeyError 'entrada `m` não encontrada'
WRITER BLOCK_META PASS [{'name': 'x', 'description': 'Novo', 'meta': {'description_inherited': True, 'sensitivity': 'public'}}]
WRITER ANCHOR RECUSA ValueError m.x: `meta` escrito em linha; escreva-o em bloco para o gerador editar
WRITER ALIAS RECUSA ValueError m.x: `meta` escrito em linha; escreva-o em bloco para o gerador editar
WRITER MERGE RECUSA ConstructorError could not determine a constructor for the tag 'tag:yaml.org,2002:merge'
WRITER DUP_COLUMN RECUSA RuntimeError probe.yml: `m.x` não ficou com {'description_inherited': True}
WRITER DUP_KEY RECUSA RuntimeError probe.yml: chave `meta` repetida (linha 9)
VERIFY_DUPLICATE_COLUMN_WITH_MARK PASS
```

Os erros de flow/merge não são todos convertidos na mensagem amigável de
“escrita recusada”, mas impedem o passe silencioso nos casos exercitados;
não abri achado de conveniência por isso. A primeira duplicidade de coluna
é recusada porque a **marca nova** falta na última ocorrência, não por
unicidade: com marca nas duas, `verify_meta` aceita a duplicidade.

`full.py` reconferiu geração e check reais na cópia completa:

```text
BASE RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
PRIMEIRA_GERACAO_META_INLINE RC 1 OUT  ERR escrita recusada: stg_retail__order_items.quantity: `meta` escrito em linha; escreva-o em bloco para o gerador editar — nenhum arquivo é tocado
CHECK_META_INLINE RC 1 OUT  ERR escrita recusada: stg_retail__order_items.quantity: `meta` escrito em linha; escreva-o em bloco para o gerador editar — nenhum arquivo é tocado
CONSTANTE_COM_MARCA RC 1 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR gerador: stg_retail__order_items.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`
```

A contraprova acrescenta à cópia um modelo isolado `probe_marker`, com SQL
compilado e arquivo concordantes (`select 100 as quantity`), classificação
`internal` e o texto antigo. O controle tem a marca. Nas variantes, a marca
original permanece, mas outra ocorrência da coluna ou de `meta` a esconde:

```yaml
columns:
  - name: quantity
    description: Quantidade comprada do SKU.
    meta:
      description_inherited: true
      sensitivity: internal
  - name: quantity
    description: Quantidade comprada do SKU.
    meta:
      sensitivity: internal
```

Saída literal da execução do `main` nos três modos sucessivos:

```text
FULL MARKED_CONTROL ['--check'] RC 1 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR gerador: probe_marker.quantity: não transporta mais (constant) e guarda o texto de quem lê — escreva o texto do que ela calcula, tire a marca de herdado ou declare `description_reason`
FULL DUP_COLUMN_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR
FULL DUP_COLUMN_SHADOW [] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) escrito(s) ERR
FULL DUP_COLUMN_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR
FULL DUP_META_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR
FULL DUP_META_SHADOW [] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) escrito(s) ERR
FULL DUP_META_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR
```

`dbt --quiet ls --project-dir /tmp/rvl3-r5-review/selection/dbt --profiles-dir
dbt --select probe_marker --output name` também retornou zero e imprimiu
`probe_marker` com a declaração de coluna duplicada. Portanto não cabe supor
que o parser do dbt rejeitará esse caso antes do catálogo.

**R5-D — R4-C/D, allowlist, inferência de tipos e tipos físicos do Airbyte.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/types.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/extra_union.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/materialized.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/types_extra.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/array_columns.py
```

Os controles originais agora mostram:

```text
MODELOS ARRAY TIPOS ['BIGINT[]', 'REAL[]', None] TRANSPORTE Computed(kind='union_coercion', shape=None, type=None, materialized=None) TEXTO None PROBLEMAS [] []
MODELOS R3_ORIGINAL TIPOS [None, 'REAL', None] TRANSPORTE Computed(kind='union_unproven', shape=None, type=None, materialized=None) TEXTO None PROBLEMAS [] []
CHAR_REVERSE {'x': Computed(kind='union_coercion', shape=None, type=None, materialized=None)}
NUMERIC_ARRAY {'x': Computed(kind='union_coercion', shape=None, type=None, materialized=None)}
STRING_BOOL TIPO_A TEXT TRANSPORTE_B Computed(kind='cast', shape=None, type='BOOLEAN', materialized=None) TEXTO_B None PROBLEMAS [] []
ARRAY_TEXT TIPO_A None TRANSPORTE_B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
BIT_CONCAT TIPO_A None TRANSPORTE_B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
```

A nova contraprova usa `derive()` e `derive_texts()` com dois modelos, não
somente uma chamada isolada de `canonical_type`:

```sql
-- a, com descrição própria:
select '{abcdef}'::varchar(8)[] || '{}'::varchar(8)[] as x;
-- b, sobre a:
select x::text as x from wh.trusted.a;
```

```text
VARCHAR_ARRAY_CONCAT A Computed(kind='dpipe', shape=None, type='TEXT', materialized=None) TIPO_A TEXT B Carry(leaves=frozenset({('trusted', 'a', 'x')})) TEXTO_B Valor integral de origem, sem truncamento nem arredondamento. PROBLEMAS [] [] TIPO_ANTES TEXT
```

`TIPO_ANTES` executa `transport.py` de `afca255` obtido por `git show`: o
escape é preexistente. No PostgreSQL, pelo `ro.sh …/oracle.sql`:

```text
         caso         |        antes        | depois |    x     |    x
----------------------+---------------------+--------+----------+----------
 VARCHAR_ARRAY_CONCAT | character varying[] | text   | {abcdef} | {abcdef}
```

A variante com `p.x` tipado como `VARCHAR(8)[]`, `a.x = p.x || p.x` e
`b.x = a.x::text` confirma também o caminho de operandos coluna:

```text
COLUMN_ARRAY_CONCAT TIPO_P VARCHAR(8)[] TIPO_A TEXT B Carry(leaves=frozenset({('trusted', 'a', 'x')})) TEXTO_B Lista de códigos completos de origem. PROBLEMAS [] []
```

A aparência impressa é igual, mas o segundo valor é a serialização escalar,
não uma lista transportada intacta. `varchar[]` **sem** parâmetro não passa
por esse falso reconhecimento; é o apagamento de `(...)[]` que abre o caso.

Matriz adicional (saídas completas em `types_extra.txt` e `oracle.txt`):

| Caso | Resultado observado |
|---|---|
| `VARCHAR[] ∪ TEXT[]`; `VARCHAR(8)[] ∪ TEXT[]` | `_uniao_preserva=False`; recusa conservadora, sem passe indevido demonstrado. |
| `NUMERIC[] ∪ NUMERIC(12,2)[]` | `False`, pois os canônicos são `NUMERIC[]` e `NUMERIC`. Perde informação, mas neste caso produz recusa, não descrição falsa. |
| `NUMERIC(12,2) ∪ NUMERIC(14,4)` | `Carry`, preservação na união; não é cast que estreita escala. |
| `varchar(8)[] → varchar(2)[]`, `numeric(12,4)[] → numeric(12,2)[]` | `Computed(cast)`, sem texto herdado. Oráculo confirma `{abcdef} → {ab}` e `{1.2345} → {1.23}`. O cast compara o tipo completo, não usa `canonical_type`. |
| `varchar(8) → varchar(2)`; `bpchar → char` sem comprimento | Ambos `Computed(cast)`, sem herança; oráculo `abcdef → ab` e `abcd → a`. A distinção de `bpchar` ilimitado e `char(1)` não escapou neste caminho. |
| Domínio `information_schema.sql_identifier`, enum `mood`, `citext`, `name`, `bpchar`, cada um com `TEXT` | Allowlist recusa; casts para texto calculam. O domínio real foi exercitado no servidor. Não há enum/citext instalado neste banco; estes dois foram exercitados apenas na AST/derivação, sem criar tipos/extensão. |
| `'true'`, `true`, `'1.5'`, `1.5` materializados | Respectivamente `TEXT`, `BOOLEAN`, `TEXT`, `NUMERIC`: espécie corrigida. |
| `2147483648`, `9223372036854775808` materializados | O motor ainda diz `INTEGER`; servidor diz `bigint` e `numeric`. Limite preexistente de faixa, já citado em R4-D; não demonstrei herança silenciosa de valor alterado por ele nesta rodada. Cast para inteiro desses valores falharia por faixa, portanto não o inflei em outro achado de perda silenciosa. |

`real → double precision` continua recusado conservadoramente. A allowlist
não é uma implementação geral da [resolução de tipos do PostgreSQL](https://www.postgresql.org/docs/16/typeconv-union-case.html),
mas os casos adicionais de domínio/enum/extensão não demonstraram falso
positivo de herança. A distinção de comprimento em
[`bpchar`/`char`](https://www.postgresql.org/docs/16/datatype-character.html)
foi conferida com o oráculo, não só com nomes canônicos.

Também reexecutei os três oráculos SQL originais de R4-C/D com
`ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh`
sobre `/tmp/rvl3-r4-review/{oracle,warehouse,materialized}.sql`. Os dois
últimos retornaram 0; `oracle.sql` retornou 3 **esperado** no controle final:
`ERROR: UNION could not convert type numeric to money`. Os resultados foram
gravados em `r4_oracle.txt`, `r4_warehouse.txt` e `r4_materialized.txt` nesta
rodada e confirmam as coerções descritas em R4-C/D.

Tipos físicos obtidos novamente com `ro.sh …/physical.sql -t -A`, consultando
`pg_attribute`/`pg_class`/`pg_namespace`, e cruzados com `source_types()` por
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/airbyte.py`:

```text
AIRBYTE ('raw', 'inventory_movements', 'movement_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements', 'correlation_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements', 'causation_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements', 'metadata') JSONB character varying
AIRBYTE ('raw', 'inventory_movements_stream', 'movement_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements_stream', 'correlation_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements_stream', 'causation_id') UUID character varying
AIRBYTE ('raw', 'inventory_movements_stream', 'metadata') JSONB character varying
```

São todas as oito folhas declaradas UUID/JSON/JSONB em `raw` que o motor usa;
não há folha declarada `JSON` nessa lista. A premissa Airbyte da resposta foi
confirmada para elas, inclusive o caminho de streaming em `raw`. Não significa
que toda coluna `raw` seja texto: há `jsonb` físico, inclusive metadados de
transporte. A medição não garante o mesmo mapeamento para um futuro conector.

**R5-E — R4-E e desaparecimento/reorganização das declarações.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/stale.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/stale_extra.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/full.py
```

Trechos literais, sempre na cópia:

```text
SEED_NIVEL ['declaração de brazilian_states']
FONTE_NAO_ESPELHADA governance ['declaração da fonte governance.legacy_captures']
SEED_REMOVIDA_STALE ['declaração de order_status_transitions']
SEED_DECLARACAO_REMOVIDA RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (declaração de order_status_transitions); rode `make dbt-build` antes — nenhum arquivo é tocado
PONTE_NIVEL_ALTERADO RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (declaração de legado__brands); rode `make dbt-build` antes — nenhum arquivo é tocado
MACRO_ANTIGA_COMENTADA RC 1 OUT  ERR manifest atrasado: 1 modelo(s) mudaram no disco depois do último build (macro empilhado); rode `make dbt-build` antes — nenhum arquivo é tocado
SEED_YAML_RENAMED []
SEED_ENTRY_MOVED []
SEED_CSV_RENAMED_STALE []
SEED_CSV_RENAMED_DERIVE FileNotFoundError [Errno 2] No such file or directory: '/tmp/rvl3-r5-review/stale_extra/seeds/order_status_transitions.csv'
SOURCE_RENAMED ['declaração da fonte governance._versions', 'declaração da fonte governance.legacy_captures']
SOURCE_REMOVED ['declaração da fonte governance._versions', 'declaração da fonte governance.legacy_captures']
MODELO_MOVIDO_ENTRE_ARQUIVOS RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
```

Renomear o YAML mantendo a entrada, ou movê-la para outro YAML, conserva a
mesma declaração: `[]` é o resultado correto. Renomear o CSV não é tratado
pela função `stale_nodes`, mas a chave do cache inclui seus caminhos/cabeçalhos
e `derive()` abre o caminho do manifest e falha; não há passe silencioso no
caminho normal. Renomear/remover a fonte `governance` compara as declarações
antigas com vazio e acusa ambas. A fonte espelhada continua sendo gerada a
partir de SQLAlchemy, não uma declaração manual de nível no manifest.

O fluxo dos dois geradores de R4-E também foi reexecutado por
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl3-r5-review/flow.py`, com
mudança da descrição SQLAlchemy **só em memória**, diretório corrente e
escritas na cópia `/tmp/rvl3-r5-review/flow`. A primeira derivação retorna 1
pelos textos da ponte ainda antigos; depois de `legacy.cli.main(['models'])`,
a segunda geração e o check passam. Trechos literais:

```text
STALE_1 []
LEGACY_MODELS RC 0 OUT 93 modelos e a declaração de fontes em dbt/models/staging/legacy/
STALE_2 []
CATALOG_2 RC 0 OUT escrito: dbt/models/analytics/_analytics__models.yml
escrito: dbt/models/trusted/_trusted__models.yml
classificação e descrição derivadas de 2983 colunas em 199 nós; 2 arquivo(s) escrito(s) ERR trocado: orders.order_total_amount: texto sem `description_reason`, diferente do herdado, reescrito
CATALOG_CHECK RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
MARCAS_APOS_LEGACY 1375
TEXTOS_PONTE 417 COM_DESCRIPTION_FROM 417 COM_MARCA 0
```

As 417 descrições da ponte continuam identificadas por `description_from`,
conforme o contrato do outro gerador. Nenhuma das 1.375 marcas foi perdida
nesse fluxo. Como em R4-E, isso exercita a parte de classificação/descrição
e o gerador do legado, não o alvo inteiro de exportação de catálogo.

**R5-F — documentação e regressões.**

Governança §5.1 v2.16 corresponde ao código no tratamento de inline/comentário,
na nova allowlist e na declaração retirada. Sua garantia geral de conferir
proveniência no YAML carregado precisa do alcance de R5-02; “operandos provam
ser texto” precisa de R5-03. O mapeamento Airbyte foi medido acima. A ressalva
sobre “macro apagada” continua excessivamente ampla: a macro já presente no
manifest cujo arquivo desapareceu é acusada por `stale_nodes`; o que não há
é reconciliação geral de inventário novo. É a imprecisão preexistente já
registrada em R4-F, não um quarto defeito independente desta rodada.

Qualidade §4 v1.16 descreve corretamente o tipo e a premissa de UTC, mas a
promessa de falha **antes** da escrita não corresponde à seleção/ordenação
real (R5-01). Os textos das dimensões foram conferidos em R5-A.

```sh
PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider' make check-offline
PYTHONDONTWRITEBYTECODE=1 make secrets-history
```

Ambos retornaram **0**. Saídas de `check-offline.txt` e `secrets-history.txt`:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 665 citações de ADR — nada quebrado
827 passed, 188 deselected in 230.28s (0:03:50)
check-offline: as três etapas passaram
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os 188 testes de integração foram excluídos e listados pelo alvo. Não refiz
`make check` do autor (`PASS=908`, `1012 passed`, `3 skipped`): ele faria build,
fora desta autorização. Não executei DAG, segunda versão SCD real, alteração
de defaults de conexão ou SQL no BigQuery. Os checks verdes e a equivalência
dos resultados atuais não encerram as três contraprovas desta rodada.

## Rodada 6 — lote 3

Revisão de `9cef25b..8e6e400`, **somente os quatro commits** `4a1ee22`,
`8f1dce1`, `4c84339` e `8e6e400`, no checkout `8e6e400`, em 05/11/2026.
**Parecer técnico, sem aceite ou poder de aprovação. Nenhuma correção implementada.
O lote 3 continua aberto: um bloqueante e três ajustes.**

As sondas e suas saídas estão em `/tmp/rvl3-r6-review`. Os scripts de R5 foram
copiados para esse diretório e reexecutados com o código atual; geração, cache e
parsing ficaram nas cópias em `/tmp`, ou em memória. Só este dossiê foi alterado
no repositório. `GEMINI.md` e `NAVEGANDO_GCP/parecer_migracao_gcp.md` já estavam
não rastreados e não foram tocados. Não executei snapshot, build, DAG, concessões,
reset, carga ou sincronização. Nenhuma escrita no warehouse.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL3-6-01 | `src/mvp_ed1/models/descriptions.py:175–176,248–251`; leitores de metadados em `sensitivity.py` | **A proveniência desaparece ao mover `meta` da coluna para `config.meta`, formato aceito pelo dbt instalado.** O leitor combina as duas grafias no nível do modelo, mas a coluna continua sendo consultada apenas por `c.get('meta')`. Em `probe_marker.quantity = 100`, o dbt reconhece `description_inherited: true` em `config.meta`; a derivação mantém “Quantidade comprada do SKU.” como texto escrito. Com a sensibilidade no `meta` direto, check → geração → check dão **0/0/0**. Movendo todo o `meta` para `config`, a geração só repõe `meta.sensitivity`, retorna 0 e o check seguinte também retorna 0, sem revisar o texto. É migração normal de sintaxe, não eliminação deliberada da marca. Normalizar os metadados da coluna conforme o dbt, ou recusar explicitamente a forma que o motor não suporta, antes de consumir a marca. **Preexistente; fechamento incompleto de RVL3-5-02 e da cadeia de proveniência, não regressão de 8f1dce1.** R6-C. | `bloqueante` | **Corrigido na leitura.** `read_yaml` junta o `config.meta` de cada coluna em `meta`, como o dbt as junta, antes de qualquer leitor ver a coluna; a mesma chave nas duas grafias com valores diferentes é recusa. A marca movida para `config.meta` continua sendo vista, e seu `quantity = 100` volta a ser acusado. Teste `test_config_meta_da_coluna_e_lido_como_meta_e_a_fonte_repetida_e_recusada`; contraprova com `8e6e400`: a marca sumia. |
| RVL3-6-02 | `descriptions.py:145–164`; `sensitivity.py:418–423`; Governança §5.1 v2.17 | **A unicidade não cobre a tabela de fonte.** `_documents` verifica só `models/snapshots/seeds`; `read_yaml` verifica colunas dentro de cada tabela, mas não a repetição da tabela. `disk_sources` e `_declaracoes_no_disco` continuam ficando com a última ocorrência. Duplicar `retail.order_items` e deixar uma descrição monetária errada em `quantity` na primeira ocorrência conserva o erro no arquivo: check → geração → check dão **0/0/0**, sem arquivo alterado. A mesma tabela em dois arquivos também é aceita pelo catálogo. O parser dbt recusa a duplicidade, limitando o impacto: não demonstrei que um build completo passe. Ainda é passe silencioso da catraca de catálogo numa edição/merge comum e contradiz a garantia documental. Validar a identidade das fontes/tabelas antes de reduzi-las a mapas. **Preexistente; lacuna da cobertura prometida por 8f1dce1/4c84339.** R6-C. | `ajuste` | **Corrigido.** A tabela de fonte repetida é recusa: no mesmo arquivo, em `read_yaml`; em dois arquivos, em `_documents`, pelo par fonte × tabela. Seu caso de `retail.order_items` duplicada agora para o catálogo. No mesmo teste. |
| RVL3-6-03 | `descriptions.py:143–150`; contrato de promoção em `sensitivity.py:628–633` | **A recusa nova impede a promoção documentada de gerado para manual.** Acrescentar `delivery_events` a um YAML manual, preservando colunas e marcas, deveria fazer a geração retirar a entrada de `_derived.yml` antes do próximo parse. Agora geração e check retornam 1 na duplicidade, antes de reconciliar os arquivos. Usando somente `_documents` de `9cef25b`, a mesma geração retorna 0, remove a entrada gerada e o check passa. Não é a divisão de um modelo manual entre dois arquivos: é a transição explicitamente suportada pelo projeto. Preservar essa transição sem permitir que uma ocorrência esconda outra. **Regressão de 8f1dce1.** Falha fechada, sem descrição falsa demonstrada por este caso; registrada como ajuste de regressão/alarme indevido no fluxo ordinário solicitado para conferência. R6-D. | `ajuste` | **Corrigido** — a regressão era minha. `_documents` aceita a duplicidade só quando uma das ocorrências está num `_derived.yml`: é a promoção documentada, vale a entrada à mão, e a gerada sai da leitura (e de `_declaracoes_no_disco`) até a geração a remover. À mão contra à mão continua recusa. Teste `test_a_promocao_do_gerado_a_mao_continua_valendo`; contraprova com `8e6e400`: recusava. |
| RVL3-6-04 | `dbt/models/trusted/orders.sql:95–103`; `customers.sql:103–116`; resposta a RVL3-5-01 | **“Nenhum modelo depende do fuso da sessão” é falso para a aritmética das janelas.** Somar dias a `timestamptz` usa o calendário do fuso da sessão. Na expressão real de recompra, pedido em `2024-01-01 12:00+00` e recompra em `2024-03-31 11:30+00` dão `true` em UTC e `false` em `America/New_York`, sem mudar nenhum instante de entrada. O snapshot UTC não protege esse cálculo. Nos 3.661 pedidos atuais, 1.641 limites de janela mudam entre esses fusos, mas **zero** indicadores comparados mudaram; a divergência de classificação foi medida com duas linhas sintéticas em CTE. Fuso com horário de verão e compra junto ao limite são casos normais, não SQL adversarial. Delimitar a garantia do escritor e encaminhar ao Owner o fuso/semântica dessas janelas, sem decidir tratamento de negócio na revisão. **Preexistente (os modelos não mudam neste intervalo), não regressão do escritor.** R6-B. | `ajuste` | **Corrigido por decisão do Owner** ("São Paulo, explícito"): toda janela de dias sobre instante passa pela macro nova `dias_no_calendario(instante, dias)`, que soma os dias no calendário de `America/Sao_Paulo` — o das datas das fatos — e não no fuso da sessão: recompra de 90 dias (`orders`, `customers`, P15), cliente ativo e churn (`customers`), cobertura de estoque (P12) e a reprocessada da fato incremental de estoque. E o "hoje" de `customers`, que era `date 'as_of_date'` (meia-noite do fuso da **sessão**), passou a `timestamptz 'as_of_date 00:00-03'`, como nos demais modelos. Medido antes e depois do build: clientes ativos 497 → 497, churn 892 → 892, recompra 243 → 243, janelas fechadas 3307 → 3307; só `days_since_last_order` mudou, +0,125 dia (médio 330,9424 → 331,0677) em 1.389 clientes, porque o "hoje" andou três horas. `tests/test_vigencia_em_utc.py` recusa agora um `± interval 'N days'` novo fora da macro (contraprova com os modelos anteriores: os 11 acusados) e o `date 'as_of'`. Qualidade §4 diz a regra e a mudança medida. |

### Conferência dos encerramentos

“Fechado” encerra o defeito técnico identificado, não aprova a entrega.
Os comandos de sondas abaixo são `.venv/bin/python -P /tmp/rvl3-r6-review/<script>`,
com `PYTHONDONTWRITEBYTECODE=1`; SQL usa o `ro.sh` indicado em R6-A.

| Achado anterior | Resultado nesta rodada | Comando e saída |
|---|---|---|
| RVL3-5-01 | **Fechado quanto ao escritor dos quatro snapshots atuais.** A chamada direta e o dispatch produzem UTC, independentemente da sessão; a afirmação sobre todos os modelos fica corrigida pelo novo R6-04. | `dbt run-operation review_clock` na cópia: `DIRECT=(now() at time zone 'UTC')`, `DISPATCH=(now() at time zone 'UTC')`, `CLOCK=('America/Sao_Paulo', 'timestamp without time zone', True, True)`; `ro.sh clock_oracle.sql`: `writer_preserves_instant=t`, `early=f`. |
| RVL3-5-02 | **Não fechado integralmente.** As duas duplicidades originais agora são recusadas; ainda há proveniência ignorada em `config.meta` e fontes encobertas. | `yaml_extra.py`: `DUP_COLUMN_SHADOW` → `ValueError … mais de uma vez`; `DUP_META_SHADOW` → `ValueError … chave meta repetida`; `config_all.py`: geração e recheck `RC 0`; `source_shadow.py`: `RC 0` nos três modos. |
| RVL3-5-03 | **Fechado.** O array parametrizado não é mais provado como texto escalar, por literal ou por operandos coluna. | `types_extra.py`: `VARCHAR_ARRAY_CONCAT … TIPO_A None … TEXTO_B None`; `array_columns.py`: `COLUMN_ARRAY_CONCAT … TIPO_A None … TEXTO_B None`; `arrays_more.py`: quatro variantes com `Computed(kind='cast')`, sem texto herdado. |
| RVL3-4-01, RVL3-3-01, RVL3-2-01 e RVL3-01 | **Continuam abertos quanto à garantia de proveniência**, agora pelo caso válido de `config.meta` em R6-01. Inline, comentários, renomeação e dois saltos originalmente exercitados continuam recusados/preservados corretamente. | `transitions.py`: renomeações e `DOIS_SALTOS` com problema; `full.py`: `CONSTANTE_COM_MARCA RC 1`; `strict_more.py`: `CONFIG_META_ONLY_MARK`/`GENERATE`/`RECHECK RC 0`. |
| RVL3-4-03 | **Fechado para os escapes demonstrados**, inclusive o array com parâmetro que restava. | `materialized.py`: `STRING_BOOL … Computed(kind='cast') TEXTO_B None`; `types_extra.py` e `array_columns.py` acima. |
| RVL3-3-03 | **Fechado para a união de folhas desconhecidas e para a vigência dos snapshots atuais.** Não se estende a toda aritmética temporal possível. | `types.py`: `R3_ORIGINAL … union_unproven … TEXTO None`; R6-A: duas portas UTC e comparação dos resultados. |
| RVL3-4-02, RVL3-02 e RVL3-2-02 | **Permanecem fechados quanto às coerções apontadas.** | `types.py`: arrays/`CHAR_TEXT` → `union_coercion`; `extra_union.py`: `R2_NESTED`, `R2_DEEP`, `CHAR_REVERSE`, `NUMERIC_ARRAY` → `union_coercion`. |
| RVL3-4-04, RVL3-3-04 e RVL3-2-07 | **Permanecem fechados para os escapes concretos de declaração retirada/alterada e macro antiga.** O problema novo de fonte duplicada está em R6-02; o limite de inventário novo/`dbt_project.yml` não virou garantia geral. | `full.py`: `PONTE_NIVEL_ALTERADO RC 1`, `MACRO_ANTIGA_COMENTADA RC 1`, `SEED_REMOVIDA_STALE ['declaração de order_status_transitions']`, `SEED_DECLARACAO_REMOVIDA RC 1`; `MODELO_MOVIDO_ENTRE_ARQUIVOS RC 0`. |

RVL3-07 fica com a mesma delimitação de atualidade das rodadas anteriores;
RVL3-3-02/05 não reabriram. Os demais itens já encerrados não foram reavaliados
fora do intervalo solicitado. A promoção detectada em R6-03 é diferente da
sonda antiga `GERADO_PROMOVIDO`: aquela já entregava ao motor a entrada promovida,
sem exercer a coexistência transitória dos dois arquivos.

### Evidências da rodada 6

**R6-A — reexecução de R5-A/B e alcance do escritor.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/run_sql.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/snapshot_audit.py
```

`run_sql.py` regenera `temporal.sql` e `temporal_full_inventory.sql` com os scripts
de R5 e executa ambos, `temporal_edges.sql` e `oracle.sql` com:

```sh
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh <arquivo.sql>
```

São CTEs e `EXCEPT ALL`, nas duas direções, em transação `REPEATABLE READ READ ONLY`,
com `ROLLBACK` final. A segunda consulta retira a janela incremental para conferir
todo o estoque e seus descendentes, como em R5. Os quatro comandos SQL retornaram 0.
`temporal_summary.py` exige 26 objetos, ausência de erro e o `ROLLBACK` final:

```text
OBJETOS 26 FATOS 10 VIEWS 16 DIFERENCAS 0
```

Sem a janela incremental, saída literal das quatro comparações:

```text
 fact_inventory_movement |   16398 |    16398 |          0
 gross_margin_by_category |     542 |      542 |          0
 inventory_turnover_by_sku_and_warehouse |    6402 |     6402 |          0
 skus_below_reorder_point |     532 |      532 |          0
ROLLBACK
```

O estado dos snapshots e o oráculo de inclusão/exclusão de limites:

```text
    modelo     |  n   | encerradas
---------------+------+------------
 customer      | 1574 |          0
 coupon        |   19 |          0
 product       |  622 |          0
 support_agent |    7 |          0

               t               | antes | depois
-------------------------------+-------+--------
 2026-11-05 11:59:59.999999+00 | f     | f
 2026-11-05 12:00:00+00        | t     | t
 2026-11-05 12:59:59.999999+00 | t     | t
 2026-11-05 13:00:00+00        | f     | f
```

Não há versões encerradas reais nesse estado: os limites acima são CTEs sintéticos.
`temporal_edges.sql` conserva também a contraprova do **escritor antigo** em sessão
São Paulo, que segue dando `nova_versao_uma_hora_antes=t`; o escritor novo é
contrastado em `clock_oracle.sql` abaixo, onde `early=f`.

Inventário do manifest e dos pacotes instalados:

```text
VERSIONS 1.12.3 1.11.0
SNAPSHOT scd_coupon {'strategy': 'check', 'updated_at': None, 'hard_deletes': None, 'invalidate_hard_deletes': None, 'dbt_valid_to_current': None}
SNAPSHOT scd_customer {'strategy': 'check', 'updated_at': None, 'hard_deletes': None, 'invalidate_hard_deletes': None, 'dbt_valid_to_current': None}
SNAPSHOT scd_support_agent {'strategy': 'check', 'updated_at': None, 'hard_deletes': None, 'invalidate_hard_deletes': None, 'dbt_valid_to_current': None}
SNAPSHOT scd_product {'strategy': 'check', 'updated_at': None, 'hard_deletes': None, 'invalidate_hard_deletes': None, 'dbt_valid_to_current': None}
```

**Nem todo valor temporal escrito por qualquer configuração passa pelas macros.**
A leitura integral de `dbt/include/global_project/macros/materializations/snapshots/`
e das variantes PostgreSQL instaladas encontrou estes caminhos:

| Caminho | Origem do tempo no SQL |
|---|---|
| Novo snapshot, `check` sem `updated_at` | `strategies.sql:148` escolhe `snapshot_get_time()`; `helpers.sql:237–244` usa `strategy.updated_at` nas colunas de vigência. Coberto. |
| Snapshot existente, inserção e fechamento por mudança | `helpers.sql:72–85` usa a mesma expressão da estratégia; `snapshot_merge.sql` copia a vigência do staging. Coberto no `check` atual. |
| Hard delete `invalidate` | `helpers.sql:145–147`: chamadas diretas de `snapshot_get_time()`. Coberto. |
| Hard delete `new_record` | Chamadas diretas para fechamento, abertura da linha de exclusão e componente temporal do novo hash (`helpers.sql:44,145–147,194–195`); a linha nova conserva o `valid_to` da anterior. Relógio coberto; sentinela continua configurada. |
| `timestamp`, ou `check` com `updated_at` | `strategies.sql:56,148` usa a expressão configurada, não o relógio sobrescrito. Tipo/fuso dessa expressão precisa ser coerente com o consumidor. Não é configuração atual. |
| `dbt_valid_to_current` | `helpers.sql:293–296` usa a expressão configurada como sentinela; não a normaliza para UTC. Sem configuração, produz nulo tipado pela estratégia. |
| Checagem de tipo | `get_snapshot_get_time_data_type` chama `adapter.dispatch('snapshot_get_time', 'dbt')`; a segunda macro do projeto cobre essa porta. |

O uso de `updated_at` nas duas estratégias também está no
[contrato oficial do dbt](https://docs.getdbt.com/reference/resource-configs/updated_at).
Não interpretei o override como conversão universal de colunas fornecidas pelo usuário.

A sonda `review_clock`, criada **somente na cópia** `dispatch_copy/dbt/macros`,
loga as duas chamadas e executa apenas um `SELECT` de tipo/igualdade com `now()`.
Ambiente carregado do `.env`, sem imprimir credenciais:

```sh
PGTZ=America/Sao_Paulo PGOPTIONS='-c default_transaction_read_only=on' \
  PYTHONDONTWRITEBYTECODE=1 .venv/bin/dbt run-operation review_clock \
  --project-dir /tmp/rvl3-r6-review/dispatch_copy/dbt --profiles-dir dbt
```

```text
DIRECT=(now() at time zone 'UTC')
DISPATCH=(now() at time zone 'UTC')
CLOCK=('America/Sao_Paulo', 'timestamp without time zone', True, True)
```

Essa execução foi somente leitura, mas o SELECT da sonda usou a conexão do perfil
dbt, em vez de `ro.sh`; fica registrado esse desvio do procedimento exigido para
SQL de superusuário. As demais sondas SQL usaram o wrapper. A confirmação
independente pelo wrapper, `ro.sh clock_oracle.sql`, devolveu:

```text
 zone | legacy_equals_new |         writer_type
------+-------------------+-----------------------------
 UTC  | t                 | timestamp without time zone

       zone        | writer_preserves_instant | old_shift
-------------------+--------------------------+-----------
 America/Sao_Paulo | t                        | -03:00:00

   dbt_valid_from    | preserves | early
---------------------+-----------+-------
 2026-11-05 15:00:00 | t         | f
```

As doze colunas temporais físicas dos quatro snapshots continuam `timestamp
without time zone`. Para linhas escritas na sessão UTC, como informado e medido
nas rodadas anteriores, o escritor antigo e o novo são equivalentes. Um timestamp
sem fuso não permite recuperar o fuso histórico só olhando seu valor; não afirmo
ter reconstruído sessões antigas a partir dessas colunas.

`dbt_readonly.py` reexecutou `dbt --quiet ls --select staging trusted quarantine
analytics consumption tag:fronteira --resource-type test --output name` na cópia:

```text
DAG_SELECTION RC 0 LINES 690 UTC_MATCHES 0
UTC_TEST_PRESENT False
```

A ausência é agora intencional: a guarda está no escritor. O teste Python novo
passou na suíte offline, mas comparar strings e presença no manifest, isoladamente,
não provaria dispatch; a sonda acima fornece essa evidência. O log preexistente
consultado já não continha as 60 ocorrências alegadas pelo autor (`UTC 0 LOCAL 0`);
não tratei essa contagem histórica como uma nova medição desta rodada.

**R6-B — dependência de sessão nos modelos, testes e consumo.**

```sh
rg -in '::\s*date|date_trunc\s*\(|extract\s*\(|to_char\s*\(|now\s*\(|current_date|as\s+date\b' \
  dbt/models dbt/macros dbt/tests -g '*.sql'
```

A busca completa ficou em `timezone-full.txt`. Nos usos encontrados, a redução
de evento `timestamptz` a data usa `America/Sao_Paulo`; `extract(epoch)` opera
sobre diferenças de instantes; `dim_date` opera sobre calendário/data; o legado
converte strings de data, não eventos `timestamptz` implicitamente. `current_date`
aparece em comentários, e `now()` ativo nas duas macros UTC. As definições das
16 views de consumo, obtidas por `pg_views` em `clock_oracle.sql`, também não
introduzem essas conversões implícitas de eventos. Não encontrei outro escape
nessas operações específicas.

Isso **não cobre a soma/subtração de dias**. O PostgreSQL usa o fuso da sessão na
aritmética de dias sobre `timestamptz`, inclusive ajustes de horário de verão.
[Documentação PostgreSQL 16](https://www.postgresql.org/docs/16/functions-datetime.html).
`ro.sh interval_sessions.sql`, com a própria expressão de `orders.sql`, CTEs
sintéticos e dois `SET LOCAL` dentro de transação somente leitura:

```text
 zone |       window_end       | has_post_order_repeat
------+------------------------+-----------------------
 UTC  | 2024-03-31 12:00:00+00 | t

       zone       |       window_end       | has_post_order_repeat
------------------+------------------------+-----------------------
 America/New_York | 2024-03-31 07:00:00-04 | f
```

`ro.sh interval.sql` compara os mesmos limites com os 3.661 pedidos atuais,
conservando os instantes e `next_order_at` armazenados:

```text
  n   | boundary_changed | window_closed_changed | repeat_changed
------+------------------+-----------------------+----------------
 3661 |             1641 |                     0 |              0
```

Portanto **não há medição de classificação atual incorreta** nessa comparação.
O defeito demonstrado é a dependência do cálculo para um caso ordinário de borda.
UTC e São Paulo não atravessam mudança de offset no período desses dados; isso
explica por que conferir apenas esses dois fusos não demonstra o problema.
O mesmo padrão existe nas janelas de atividade/recompra de `customers`, mas não
extrapolei a contagem de `orders` para os clientes nem para indicadores finais.

**R6-C — reexecução de R5-C e leitura estrita adicional.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/baseline.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/run_probes.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/strict_more.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/config_all.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/source_shadow.py
```

O baseline derivou em memória e comparou com o disco; **os 18 YAMLs atuais de
models/snapshots/seeds carregam sem erro**:

```text
STALE []
NOS 199 COLUNAS 2983
PROBLEMAS [] []
ARQUIVOS_DIFERENTES []
OBSOLETOS []
MARCAS 1375 ESPERADAS 1375 EXATAS True EXCEDENTES [] FALTANTES []
DETERMINISTICO True
```

Os três avisos conhecidos de `legacy_classifications` permanecem. No baseline,
`textos.marks` continua vazio, mas isso já não deixa duplicidades de chave/coluna
passarem: o carregador estrito roda antes. Saídas de `yaml_extra.py`:

```text
FULL DUP_COLUMN_SHADOW ['--check'] RC ValueError:/tmp/rvl3-r6-review/yaml_copy/dbt/models/staging/_probe_marker.yml: `probe_marker` lista a(s) coluna(s) ['quantity'] mais de uma vez OUT  ERR
FULL DUP_META_SHADOW ['--check'] RC ValueError:/tmp/rvl3-r6-review/yaml_copy/dbt/models/staging/_probe_marker.yml: chave `meta` repetida (linha 11) OUT  ERR
```

A geração e o segundo check recusaram igualmente os dois casos. A recusa acontece
em `stale_nodes`, antes do `try` do `main`: lança exceção em vez da mensagem
“recusado … nenhum arquivo é tocado” prometida na resposta. **Não é passe
silencioso nem novo bloqueante de usabilidade.** `yaml_validate_loaded.py` agora
termina com a recusa esperada da coluna repetida, mesmo com marca nas duas.
`transitions.py` termina na recusa esperada do inline; suas transições anteriores
continuam exercitadas. O runner captura esses retornos e segue para as demais sondas.

| Formato adicional | Resultado medido |
|---|---|
| `meta` com comentário, CRLF e descrição em bloco | Escritor conserva marca e texto; verificação carregada passa. |
| Âncora/alias de `meta` já marcado | Leitura resolve a marca e recusa cálculo sem revisão (`ANCHOR RC 1`). Escrita que precisa editar o alias é recusada. |
| Alias da mesma coluna duas vezes | `DUP_ALIAS` → `ValueError … ['quantity'] mais de uma vez`. |
| Merge `<<` | `ConstructorError` no carregador, inclusive no merge sem conflito. Limitação conservadora/recusa, não passe silencioso; nenhum arquivo atual usa esse formato. |
| Coluna/marca deslocada para `tests:` | O catálogo não a interpreta como coluna (`TESTS_MARK RC 0`); `dbt ls` retorna 2: `test definition dictionary must have exactly one key`. Não é uma segunda grafia válida de metadado de coluna, ao contrário de `config.meta`. |
| Mesmo modelo manual dividido entre arquivos | Catálogo recusa e `dbt ls` retorna 2: `Resources and their associated columns may only be described a single time`. Não é divisão legítima para o dbt instalado. |
| Entrada movida, removendo a antiga | `MODELO_MOVIDO_ENTRE_ARQUIVOS RC 0`. |
| `config.meta` da coluna | dbt aceita e reconhece a marca; derivação a ignora — R6-01. |
| Mesma tabela de fonte em dois arquivos | `SOURCE_DUPLICATE RC 0`; `disk_sources` devolve só `Segundo texto`; `dbt ls` retorna 2 por duas fontes com o mesmo nome — R6-02. |

Contraprova válida para `config.meta`, sobre `select 100 as quantity`:

```yaml
columns:
  - name: quantity
    description: Quantidade comprada do SKU.
    config:
      meta:
        description_inherited: true
        sensitivity: internal
```

`dbt_readonly.py`/`more_yaml_dbt.py`, com `dbt ls` na cópia:

```text
DBT_CONFIG_META RC 0 OUT probe_marker
DBT_COLUMN_META {'sensitivity': 'internal', 'description_inherited': True}
DBT_CONFIG_ALL RC 0 OUT probe_marker
DBT_CONFIG_ALL_META {'description_inherited': True, 'sensitivity': 'internal'}
```

Essa posição está no [contrato oficial de meta de coluna](https://docs.getdbt.com/reference/resource-configs/meta).
`config_all.py` usa o `main` e o cache reais, sem substituir `load()`:

```text
CONFIG_ALL ['--check'] RC 1 SECONDS 26.098 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 1 arquivo(s) desatualizado(s) ERR desatualizado: dbt/models/staging/_probe_marker.yml
CONFIG_ALL [] RC 0 SECONDS 3.295 OUT escrito: dbt/models/staging/_probe_marker.yml
classificação e descrição derivadas de 2984 colunas em 200 nós; 1 arquivo(s) escrito(s) ERR
CONFIG_ALL ['--check'] RC 0 SECONDS 1.742 OUT classificação e descrição derivadas de 2984 colunas em 200 nós; 0 arquivo(s) desatualizado(s) ERR
```

A única adição foi `meta.sensitivity: internal` diretamente na coluna; descrição
e marca em `config.meta` permaneceram. O primeiro RC 1 acusa **arquivo diferente**,
não proveniência inválida. Com a sensibilidade já no `meta` direto e só a marca
sob `config.meta`, os três modos passam sem alteração. O controle com a marca
no `meta` direto retorna `RC 1 … não transporta mais (constant)`.

`source_shadow.py` duplica uma tabela **existente**, no espelho de `retail`, com
descrição errada na primeira ocorrência e a correta na última. Como só o YAML muda,
reutiliza em memória a derivação do baseline, mantendo o restante do `main` real:

```text
EXISTING_SOURCE_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
EXISTING_SOURCE_SHADOW [] RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) escrito(s) ERR
EXISTING_SOURCE_SHADOW ['--check'] RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
SOURCE_QUANTITY_DESCRIPTIONS ['Valor monetário total do pedido em reais.', 'Quantidade comprada do SKU.']
```

Não se deve confundir a recusa do parser dbt com a recusa que a documentação
promete para ambos os modos do catálogo. Não foi demonstrado build completo
verde com essa fonte duplicada.

**R6-D — promoção e custo da leitura.**

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/promotion.py
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -P /tmp/rvl3-r6-review/check_time.py
```

A promoção copia a declaração inteira de `delivery_events` para `_z_promoted.yml`,
sem editar o gerado. Reutiliza a derivação inalterada do baseline. Com o código
atual, os dois modos retornam 1; substituindo **só `_documents`** pela função de
`9cef25b` carregada em memória:

```text
CURRENT_PROMOTION ['--check'] RC 1 OUT  ERR recusado: `delivery_events` documentado em /tmp/rvl3-r6-review/promotion_copy/dbt/models/trusted/_derived.yml e em /tmp/rvl3-r6-review/promotion_copy/dbt/models/trusted/_z_promoted.yml — nenhum arquivo é tocado
CURRENT_PROMOTION [] RC 1 OUT  ERR recusado: `delivery_events` documentado em /tmp/rvl3-r6-review/promotion_copy/dbt/models/trusted/_derived.yml e em /tmp/rvl3-r6-review/promotion_copy/dbt/models/trusted/_z_promoted.yml — nenhum arquivo é tocado
PREVIOUS_DOCUMENTS [] RC 0 OUT escrito: dbt/models/trusted/_derived.yml
classificação e descrição derivadas de 2983 colunas em 199 nós; 1 arquivo(s) escrito(s) ERR
PREVIOUS_DOCUMENTS ['--check'] RC 0 OUT classificação e descrição derivadas de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s) ERR
```

O `--check` real, com cache aquecido na cópia completa e **sem substituir `load`**:

```text
CHECK 1 RC 0 SECONDS 10.896
CHECK 2 RC 0 SECONDS 10.705
```

São medições durante outras validações concorrentes; não são benchmark isolado.
A sonda `config_all` acima mediu 26,098 s com cache novo e 1,742 s no último check
com cache aquecido. O custo é aceitável para a catraca local nesta medição; não
identifiquei regressão de desempenho que impedisse seu uso. Não estimei tempo de
volume futuro nem atribuí toda diferença de tempo ao carregador C.

**R6-E — reexecução de R5-D e arrays adicionais.**

`run_probes.py` executou `types.py`, `extra_union.py`, `materialized.py`,
`types_extra.py` e `array_columns.py`. A última sonda antiga terminou inicialmente
com `KeyError` porque exigia justamente o tipo/texto indevidos que deixaram de
existir; reexecutei trocando apenas o acesso do diagnóstico por `.get()`.
O resultado é ausência de herança, não falha da derivação:

```text
VARCHAR_ARRAY_CONCAT A Computed(kind='dpipe', shape=None, type=None, materialized=None) TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] [] TIPO_ANTES TEXT
COLUMN_ARRAY_CONCAT TIPO_P VARCHAR(8)[] TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
```

`arrays_more.py` testa dois modelos em sequência, com concatenação no primeiro e
`x::text` no segundo:

```text
CANON 'int[][]' = INTEGER[][]
CANON '_int4' = _INT4
CANON 'character varying(8)[]' = VARCHAR[]
CANON 'character varying(8)[][]' = VARCHAR[][]
CANON 'numeric(12,2)[][]' = NUMERIC[][]
ARRAY int[][] TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
ARRAY _int4 TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
ARRAY character varying(8)[] TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
ARRAY character varying(8)[][] TIPO_A None B Computed(kind='cast', shape=None, type='TEXT', materialized=None) TEXTO_B None PROBLEMAS [] []
```

`ro.sh arrays_oracle.sql` confirma `int[][]` e `_int4` como `integer[]`, e
`character varying(8)[]` como `character varying[]`; `x::text` é `text` nos três
casos. `_int4` e dimensões distintas não são normalizados ao mesmo nome no motor;
é conservador, sem falso texto escalar demonstrado. Casts que estreitam tamanho
ou escala continuam `Computed(cast)`. Arrays de tipos distintos, `CHAR/TEXT` e
subuniões perigosas continuam recusados; o limite preexistente de faixa de
literais inteiros permanece, sem nova perda silenciosa demonstrada nesta rodada.

`ro.sh physical.sql -t -A` renovou `physical.json`; `airbyte.py` reconfirmou as
mesmas oito folhas UUID/JSONB de `inventory_movements` e
`inventory_movements_stream` como `character varying` físico. Não usei o JSON
antigo como evidência atual e não extrapolei para futuros conectores.

**R6-F — documentos e regressões gerais.**

Governança §5.1 v2.17 corresponde ao tratamento do sufixo `[]` e às recusas de
chave/coluna duplicadas. Sua afirmação de que nenhuma ocorrência encobre outra
é excessiva: não inclui tabelas de fonte, e a proveniência em `config.meta` segue
invisível. A recusa indiscriminada de entradas também quebra a promoção que o
código documenta. São os três achados de leitura/fluxo acima, não novos achados
editoriais independentes. “Todo `.yml`” aqui cobre as declarações que o motor lê
em `models/snapshots/seeds`; não é validador universal de configuração dbt.

Qualidade §4 v1.16 e os comentários das quatro dimensões correspondem à escrita
UTC e à leitura `at time zone 'UTC'` **na configuração atual**. As reduções de
instante a data usam o fuso declarado. A frase mais ampla na resposta a R5-01
não se sustenta pelas janelas de dias; os limites das estratégias/sentinelas
foram explicitados em R6-A. Nenhum ADR aceito foi alterado.

```sh
PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider' make check-offline
PYTHONDONTWRITEBYTECODE=1 make secrets-history
```

Ambos retornaram **0**:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 665 citações de ADR — nada quebrado
834 passed, 188 deselected in 420.07s (0:07:00)
check-offline: as três etapas passaram
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os 188 testes de integração foram excluídos/listados pelo alvo. Não refiz o
`make check` informado pelo autor (`PASS=907`, `1019 passed`, `3 skipped`), pois
faria build. Não executei segunda versão SCD real, hard delete real, troca de
estratégia ou de sentinela no warehouse. A cobertura desses caminhos combina
leitura do código instalado, dispatch efetivo e oráculos SQL somente leitura;
não é alegação de integração destrutiva executada. Os checks verdes não encerram
as contraprovas acima. **O lote 3 não pode ser encerrado nesta rodada.**
