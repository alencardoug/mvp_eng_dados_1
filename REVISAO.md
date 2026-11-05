# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `26b58b3..1e197ac` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
9c9ff9c fix: conta e agrupa por identificador com a origem nas views de consumo
7f97d62 docs: registra ADR-0049 — separar a classificação da exposição do dado sintético
38c1bea feat: entrega a linhagem por coluna em JSON a quem consome de fora
1e197ac feat: cria o login só de leitura do armazém, membro de analyst
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 25 arquivos

- `.env.example`
- `Makefile`
- `README.md`
- `dbt/models/consumption/average_order_value_by_channel_and_segment.sql`
- `dbt/models/consumption/discount_share_by_channel.sql`
- `dbt/models/consumption/monthly_revenue_by_channel_and_category.sql`
- `dbt/models/consumption/on_time_delivery_rate_by_carrier.sql`
- `dbt/models/consumption/order_to_delivery_time_by_region.sql`
- `dbt/models/consumption/revenue_by_delivery_region.sql`
- `dbt/models/consumption/support_tickets_per_hundred_orders.sql`
- `dbt/models/consumption/top_skus_by_revenue.sql`
- `docs/adr/0049-separar-a-classificacao-da-exposicao.md`
- `docs/adr/README.md`
- `docs/dicionario_de_dados.md`
- `docs/execucao_local.md`
- `docs/governanca_de_dados.md`
- `docs/pendencias.md`
- `docs/qualidade_de_dados.md`
- `src/mvp_ed1/db.py`
- `src/mvp_ed1/governance.py`
- `src/mvp_ed1/models/lineage.py`
- `tests/test_acesso.py`
- `tests/test_identidade_no_consumo.py`
- `tests/test_leitor.py`
- `tests/test_linhagem.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega:** `docs/adr/0049-separar-a-classificacao-da-exposicao.md` (decisão do Owner: classificar não é
expor) e `src/mvp_ed1/governance.py` (`_garantir_leitor`, `leitor_do_ambiente`, `_verificador_scram`:
é a declaração do login, aplicada a cada `dbt-build`). As oito views de `consumption` são
declaração do que se mede (P01–P16) e pedem revisão integral, linha a linha. A guarda
`tests/test_identidade_no_consumo.py` é a declaração da regra "identidade = origem + identificador"
sobre o SQL. Derivados: `docs/dicionario_de_dados.md` (§1/§2 por `make catalog`, §3 por `lineage.py`),
os trechos do README e de Execução Local. Não há arquivo gerado no intervalo além do Dicionário.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
........................................................................ [ 84%]
........................................................................ [ 92%]
....................................................................     [100%]
=========================== short test summary info ============================
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_remocao.py:643: sem mutações no diário: a prova entre capturas ainda não aconteceu
929 passed, 3 skipped in 368.64s (0:06:08)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **O efeito numérico de 9c9ff9c não tem evidência guardada.** A mensagem diz "mudam só P05
  (20 → 21) e P06 (11 → 12)", medido nas 16 views antes e depois do build em 23/10. Não há arquivo
  em `data/medicoes/`. A regeneração da v1.1.0 (etapa 1.6, 04/11) mudou os dados depois disso, e o
  antes não se reproduz mais sobre o armazém atual — só pela guarda estática e por consulta
  própria contra o estado de agora.
- **A guarda de identidade é estática** (`sqlglot` sobre o SQL dos modelos). Forma de reduzir por
  identificador que ela não reconhece — janela (`row_number() over (partition by order_id)`),
  `exists` não correlato, `union` sem a origem, CTE que já perdeu `source_system` — passa calada.
  Não se fez varredura por essas formas nas 16 views.
- **O JSON da linhagem não tem consumidor real ainda.** O `bi-como-codigo` só o cita no plano e
  no runbook; nada lê `--json` hoje. O contrato (`format: 1`) foi provado por teste só pelo
  percurso das 14 arestas de P01. `manifest_generated_at` muda a cada compile — "o mesmo texto"
  vale para `relations`, não para o documento inteiro.
- **O login de leitura não foi provado contra restauração.** `garantir_papeis` (o que a
  restauração chama antes do `pg_restore`) não cria o leitor; ele nasce no `dbt-build` seguinte.
  Não se mediu o intervalo em que um armazém restaurado existe sem ele, nem o que o `pg_restore`
  faz com `revoke temporary … from public` — não se conferiu se o ACL do banco entra no dump.
- **`revoke temporary on database … from public` alcança todo login não superusuário.** Hoje os
  únicos logins são o superusuário do `.env` (Airbyte, dbt, Beam e o certificado usam ele —
  Governança §7) e o leitor. Não se procurou outro login criado fora do `governance.py`.
- **`default_transaction_read_only` é padrão de sessão, não garantia**: o leitor pode pedir
  `read write`. A garantia é de privilégio, e `test_o_login_de_leitura_nao_escreve` pede `read
  write` antes de tentar; não se testou função `security definer` em `consumption` (não há
  nenhuma hoje, não se confirmou que não pode haver).
- **Concorrência de dois `garantir()`** (dois `dbt-build` juntos) não exercitada: o `create role`
  está guardado por `if not exists`, mas sem lock.
- **O `make check` da seção 3 rodou sobre `28044c7` (HEAD), não sobre `1e197ac`.** Cinco commits
  posteriores mexeram em arquivos deste lote (`ff868a9`, `68e84bc`, `aaa3538`, `7cea1ee`,
  `94e0d09`, em `dbt/models/consumption/` e afins); eles são do lote 3. O que aparece no HEAD e
  não no intervalo não é deste lote.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- PostgreSQL 16 do armazém aceita o verificador `SCRAM-SHA-256$4096:…` enviado pronto em
  `alter role … password`, e `password_encryption` não o reprocessa. Confirmado só indiretamente:
  o teste de acesso conecta com a senha do `.env`.
- `grant analyst to <leitor>` no PG16 dá `inherit true, set true` por padrão; o leitor herda as
  permissões sem `set role`. `revoke admin option` sobre membership inexistente não falha.
- `pg_auth_members` lista só membership direta; uma cadeia indireta (analyst membro de outro
  papel) passaria. Confia-se em `_garantir_papeis`, que declara os papéis sem cadeia.
- O `sqlglot` instalado lê todas as 16 views no dialeto `postgres` sem erro silencioso — uma
  view que não parse viraria zero achados. `test_ha_views_para_ler` só conta arquivos.
- A senha restrita a `[A-Za-z0-9]{24,}` torna o `'…'` do `alter role` seguro sem escape, e o
  nome restrito por `_NOME` torna os f-strings de DDL seguros. Não há parametrização em DDL.

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

Os três bancos de pé, e o armazém **construído**: o `make check` da seção 3 rodou o
`dbt-build`, então o login `consumption_reader` existe com a senha do `.env` e as 16 views estão
materializadas sobre os dados da regeneração. Para conectar como leitor:
`WAREHOUSE_READER_USER`/`WAREHOUSE_READER_PASSWORD` do `.env`, mesma porta do armazém. Para
SQL como superusuário, só leitura: `~/Projetos/bi-como-codigo/evidence/20261022/ro.sh`.
`dbt/target/manifest.json` é o do último build — é o que `lineage --json` lê. Airbyte e
*streaming* pausados; Airflow pode estar no ar com `fluxo_batch` despausado e disparo só
externo: **não disparar nem pausar**. Nada deste lote exige Airbyte ou *streaming*.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Revogar `temporary` de `PUBLIC` no banco inteiro**, em vez de só não dar ao leitor. Não há
  como tirar de um papel o que vem de `PUBLIC`; a alternativa era aceitar "não escreve, exceto
  tabela temporária". Fui pelo banco inteiro porque hoje todo outro login é superusuário — se a
  Etapa 13 trouxer logins por papel (Governança §7), eles também ficam sem temporária, e isso
  pode morder um job que dependa dela.
- **Repor a senha a cada `dbt-build`** em vez de só criar: o `.env` é a verdade, e uma senha
  trocada à mão no banco volta sozinha. Custo: toda execução gera verificador novo (sal novo), e
  um consumidor com sessão aberta não cai, mas a próxima conexão usa a senha do `.env`.
- **O leitor nasce no `dbt-build`, não em `garantir_papeis`** (restauração). Pus junto das
  migrações porque precisa do `.env` e do papel `analyst`; a restauração deixa um intervalo sem
  ele, que ninguém usa hoje.
- **Guarda estática para a identidade**, e não um teste de dados por view. Um teste de dados só
  vê a divergência se houver colisão real nos dados do dia — P01/P02 escapavam por acaso; a
  guarda vê a forma. O preço é o que a forma não pega (seção 4).
- **ADR-0049 sem mudar classificação nenhuma:** as 28 colunas `confidential` lidas pelo analyst
  seguem classificadas; mudou a regra da Governança §4, não os dados. A alternativa — rebaixar
  a classificação do sintético — perderia a base das *policy tags* da Etapa 13.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-01 | `governance.py::_garantir_leitor`; `tests/test_acesso.py` | O leitor cria e escreve large objects depois de pedir `read write`. A garantia de login só de leitura é falsa. | `bloqueante` | Corrigido em `3f6ea1b`. Reproduzido antes do fix (`lo_create`, `lo_creat`, `lo_from_bytea` devolveram OIDs, com rollback). **Achado a mais na reprodução:** o leitor também tomava *advisory locks* (`pg_advisory_lock(1)` passou), e eles são os da captura do legado (`captura.bloqueio_da_tentativa`, abertura em `captura.py:236`) — segurar o de uma tentativa a deixaria pendente para sempre, sem escrever nada. `governance.FECHADAS_A_PUBLIC` declara as funções que criam/escrevem *large object* e as que tomam lock; `_fechar_a_public` tira o `EXECUTE` de toda assinatura delas de `PUBLIC`, junto do `temporary`, e falha se o `pg_catalog` não tiver um nome da lista. Ler LO e soltar lock ficam. Testes: as seis tentativas em `test_o_login_de_leitura_nao_escreve` e `test_nenhuma_assinatura_fechada_a_public_executa_pelo_leitor` (catálogo, toda assinatura); com as funções devolvidas a `PUBLIC`, os dois falham (`2 failed`), e o `garantir()` seguinte os passa (`13 passed`); a sonda dá `permission denied` em todas. Governança §7 v2.10 em `00ce350`. `make check`: PASS=907, 943 passed, 3 skipped. |
| RVL2-02 | `governance.py::_garantir_leitor` | Nomes de memberships e do banco entram em DDL entre aspas duplas sem escape. Um nome de papel com aspas encerra o identificador e injeta comandos na sessão privilegiada. | `ajuste` | Corrigido em `3f6ea1b`. As memberships e o banco se compõem no servidor, num bloco `do` com `format('%I')` sobre o catálogo — o valor nunca passa por texto Python; as assinaturas de função por `regprocedure` com `%s`. `_NOME`/`_SENHA` com `fullmatch`: `reader\n` e senha com `\n` final recusados. Contraprovas: com a `governance.py` de `1e197ac` em memória, os três testes novos de `test_leitor.py` falham (`3 failed`); `test_membro_com_nome_que_fecharia_o_identificador_sai_sem_injetar` cria em banco real o papel com o nome da sonda, concede ao leitor, roda `garantir()` e confere que saiu e que `analyst` segue sem `rolsuper` — o papel é apagado no `finally`. Contra o código antigo esse teste não chega a rodar (o import de `FECHADAS_A_PUBLIC` falha), e de propósito não o adaptei: com um papel `x` existente, o código antigo executaria a injeção no armazém real. A contraprova do código antigo é a offline, no dublê. |
| RVL2-03 | `tests/test_identidade_no_consumo.py::violacoes` | A guarda aceita `DISTINCT ON (order_id)` com origem apenas na projeção e junção cuja origem não correlaciona os lados; não apenas as janelas já ressalvadas. | `ajuste` | Corrigido em `4304376`. A guarda lê a chave do `distinct on`, exige que a origem iguale **as mesmas duas tabelas** da igualdade de identificadores (ou esteja fixada por literal) e acusa janela `partition by` identificador sem a origem. Oito contraprovas novas; as quatro acusações dão 0 achados na guarda antiga. As 16 views passam (38 passed). O limite que fica está declarado na descrição do teste: o fluxo entre cláusulas (CTE que perdeu a origem, `union` que deduplica), com a leitura das 16 views desta revisão como referência. |
| RVL2-04 | `garantir_papeis`, restauração e ACL do banco | O dump atual não transporta o login nem a revogação de TEMP; restauração em cluster novo depende do próximo build para estabelecer o acesso do leitor. Não há outro login operacional não superusuário hoje. | `observação` | Declarado em `00ce350`, Governança §7: o login e as revogações de `PUBLIC` não vêm do *dump* por schema; num cluster novo quem os estabelece é o `dbt-rebuild` da sequência de recuperação (`Makefile:704`, dentro de `recovery-restore`), e até ele o leitor não existe. Nenhuma mudança no ADR aceito. |
| RVL2-05 | Oito views alteradas por `9c9ff9c` | Medição atual confirma diferença em P05 e P06, mas P06 agora é 13 → 14. Não recupera nem valida o número histórico 11 → 12. | `observação` | Aceito. O 11 → 12 de P06 só existe na mensagem de `9c9ff9c`, nenhum documento o cita (grep em `docs/`, README e `dbt/`); a medição atual do Codex (P05 20 → 21, P06 13 → 14) é a evidência vigente do efeito, sobre os dados da regeneração. O histórico não se corrige; esta linha o registra. |
| RVL2-06 | `lineage --json`, formato 1 | Travessias além de P01 funcionam; contagens podem terminar em `generated`, sem caminho até raw. O consumidor precisa respeitar a semântica de linhagem de valor. | `observação` | Aceito, sem mudança no formato 1. O sentido de *gerada* está no Dicionário §3 ("coluna que não vem do valor de coluna nenhuma"). A obrigação do consumidor — não tratar `generated` como linhagem quebrada — vai para a Parte II do plano do `bi-como-codigo`, onde o exportador nasce. |
| RVL2-07 | Regressões e premissas do dossiê | `check-offline` histórico passou com 547 testes e seis skips por falta de manifest; o total esperado de 749 não caracteriza este checkout. Histórico de segredos passou em HEAD. | `observação` | Sem ação. O 749 do prompt era o total no HEAD, não em `1e197ac`; os 547 do *snapshot* e os seis pulos por falta de *manifest* são coerentes com ele. Medição do autor depois das correções, no HEAD `00ce350`: `make check` PASS=907, 943 passed, 3 skipped. |

### Evidências e limites da revisão — 04/11/2026

Revisão sem poder de aprovação e sem correções. Código e documentos lidos em `1e197ac`,
extraídos com `git archive` para `/tmp/revisao_lote2_1e197ac`, com índice Git daquele commit.
O checkout de trabalho permaneceu em `d1f45a2`. Warehouse e manifest são os atuais (HEAD),
não uma reconstrução de `1e197ac`. `git diff 1e197ac HEAD -- src/mvp_ed1/governance.py`
devolveu saída vazia. Os cinco commits posteriores indicados pelo Owner não foram atribuídos
ao lote 2. `.venv` existente foi reutilizado e `PYTHONPATH` apontou para o `src` histórico.

As consultas de superusuário usaram exclusivamente:

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh
```

O sandbox bloqueou inicialmente Docker e conexão TCP; as repetições receberam autorização
de execução fora dele. Nenhum build, disparo/pausa de DAG, reset, seed, sync ou restauração
foi executado. Nenhuma escrita em `data/memoria_do_legado/`. Todas as sondagens do leitor
foram seguidas de `rollback`, inclusive as que passaram. Nenhum papel ou objeto de sonda
permaneceu; nenhum dado de negócio foi modificado. Não houve commit nem push.

### RVL2-01 — large objects escapam aos grants de tabelas

Reprodução mínima: carregar `.env` sem imprimir valores e executar com `.venv/bin/python`:

```python
import os, psycopg
c = psycopg.connect(host='127.0.0.1', port=os.environ['WAREHOUSE_DB_PORT'],
    dbname=os.environ['WAREHOUSE_DB_NAME'], user=os.environ['WAREHOUSE_READER_USER'],
    password=os.environ['WAREHOUSE_READER_PASSWORD'])
for q in ['select lo_create(0)', "select lo_from_bytea(0,decode('4142','hex'))"]:
    try:
        c.execute('set transaction read write')
        print(q, '=>', c.execute(q).fetchall())
    finally:
        c.rollback()
c.close()
```

Saída literal dessas duas operações na bateria executada:

```text
select lo_create(0) => [(309471,)]
select lo_from_bytea(0,decode('4142','hex')) => [(309472,)]
Todas as transações revertidas; conexão fechada.
```

A mesma bateria abriu transação `read write` para cada comando abaixo, capturou
`sqlstate` e `diag.message_primary`, e reverteu em `finally`. Saída literal:

```text
show default_transaction_read_only => [('on',)]
select count(*) from consumption.monthly_revenue_by_channel_and_category => [(1494,)]
create table public.__rvl2(x int) => 42501 permission denied for schema public
create table consumption.__rvl2(x int) => 42501 permission denied for schema consumption
create temp table __rvl2(x int) => 42501 permission denied to create temporary tables in database "warehouse_db"
create schema __rvl2 => 42501 permission denied for database warehouse_db
create function public.__rvl2() returns int language sql as $$select 1$$ => 42501 permission denied for schema public
create sequence public.__rvl2 => 42501 permission denied for schema public
insert into raw.orders select * from raw.orders where false => 42501 permission denied for schema raw
delete from consumption.monthly_revenue_by_channel_and_category where false => 55000 cannot delete from view "monthly_revenue_by_channel_and_category"
set role analyst => OK
set role transformer => 42501 permission denied to set role "transformer"
set role mvp_warehouse => 42501 permission denied to set role "mvp_warehouse"
set session authorization mvp_warehouse => 42501 permission denied to set session authorization "mvp_warehouse"
alter role consumption_reader createrole => 42501 permission denied to alter role
alter role consumption_reader set default_transaction_read_only=off => OK
grant analyst to auditor => 42501 permission denied to grant role "analyst"
create role __rvl2 => 42501 permission denied to create role
copy (select 1) to program 'true' => 42501 permission denied to COPY to or from an external program
```

O erro `55000` da view agregada não é prova de ACL. O inventário de privilégios abaixo
complementa essa tentativa. Alterar o próprio padrão de sessão é permitido e também foi
revertido; não é escalada, mas confirma que o padrão não protege contra escrita.

Comandos via `ro.sh` e resultados literais relevantes:

```sql
select count(*) as probe_large_objects_remaining from pg_largeobject_metadata
where oid in (309471,309472);
select p.proname,has_function_privilege('consumption_reader',p.oid,'execute') reader_exec,
       has_function_privilege('analyst',p.oid,'execute') analyst_exec
from pg_proc p where p.proname in ('lo_create','lo_from_bytea','lo_put','lo_unlink');
select rolpassword like 'SCRAM-SHA-256$4096:%' as scram4096
from pg_authid where rolname='consumption_reader';
```

```text
 probe_large_objects_remaining
-------------------------------
                             0
(1 row)

    proname    | reader_exec | analyst_exec
---------------+-------------+--------------
 lo_create     | t           | t
 lo_from_bytea | t           | t
 lo_put        | t           | t
 lo_unlink     | t           | t
(4 rows)

 scram4096
-----------
 t
(1 row)
```

```sql
select n.nspname,c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
where case when c.relkind='S'
then has_sequence_privilege('consumption_reader',c.oid,'usage,update') else false end;
select n.nspname,c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname not in ('pg_catalog','information_schema') and c.relkind in ('r','v','m')
and has_table_privilege('consumption_reader',c.oid,'insert,update,delete,truncate');
select count(*) from pg_class where relname='__rvl2';
```

```text
 nspname | relname
---------+---------
(0 rows)

 nspname | relname
---------+---------
(0 rows)

 count
-------
     0
(1 row)
```

A primeira versão da consulta de sequências usava `AND` e falhou ao avaliar a função
sobre um objeto não sequência; a versão com `CASE` acima completou. Não foi usado
`nextval`, cujos efeitos não são revertidos como DDL transacional.

Ajuste proposto: fechar os caminhos de escrita por large objects, incluindo os herdados
ao assumir `analyst`, e acrescentar contraprovas reais com rollback. A escolha de como
restringir funções disponíveis a PUBLIC precisa considerar os demais consumidores.

### RVL2-02 — identificadores do catálogo não são escapados

As restrições do nome/senha do `.env` não cobrem `papel` vindo de `pg_auth_members`
nem `banco` vindo de `current_database()`. Captura do DDL do código de `1e197ac`, sem
executá-lo no servidor:

```python
from mvp_ed1 import governance as g
name = 'x" from consumption_reader; ALTER ROLE analyst SUPERUSER; --'
print('bytes_do_nome=', len(name.encode()))
class C:
    def execute(self, s, p=None):
        if str(s).startswith('revoke "'): print(str(s))
        return self
    def scalars(self): return self
    def all(self):
        return [name]
    def scalar_one(self): return 'warehouse_db'
    def exec_driver_sql(self, s): pass
g._garantir_leitor(C(), 'consumption_reader', 'A' * 24)
print('SQL capturado em double; nada enviado ao servidor.')
```

```text
bytes_do_nome= 60
revoke "x" from consumption_reader; ALTER ROLE analyst SUPERUSER; --" from consumption_reader
SQL capturado em double; nada enviado ao servidor.
```

É uma falha de composição de DDL, não uma escalada demonstrada pelo leitor atual:
ele não cria papéis nem concede memberships. Uma preparação desse nome/membership por
outro administrador ou ferramenta seria pré-requisito, bem como a existência do papel `x`
para o primeiro comando não falhar; a execução da cadeia no servidor
não foi feita. Nomes legítimos com aspas também podem interromper o build.
Proposta: composição/escape de identificadores nos dois pontos.

Com `leitor_do_ambiente({LEITOR_USUARIO: nome, LEITOR_SENHA: 'A'*24,
'WAREHOUSE_DB_USER': 'mvp_warehouse'})`, imprimindo apenas nome e aceitação:

```text
'analyst' recusado
'ingestor' recusado
'mvp_warehouse' recusado
'x;select 1' recusado
'reader\n' aceito
```

O newline final passa por `$` com `match`; sozinho não demonstrou injeção.
Os caracteres do verificador SCRAM gerado não introduzem aspas; o DDL envia o
verificador, não a senha. O teste de autenticação real e o prefixo no catálogo
confirmam funcionamento em PostgreSQL 16.15; não foi provocado erro real de rotação
nem habilitado log do servidor para inspecionar vazamentos.

### RVL2-03 — contraprovas da guarda

Importado `tests/test_identidade_no_consumo.py` de `1e197ac` por
`importlib.util.spec_from_file_location`; executado `print(sql, '=>', violacoes(sql))`:

```text
select distinct on (order_id) source_system, order_id from f => []
select * from a join b on a.order_id=b.order_id and a.source_system=a.source_system => []
select row_number() over(partition by order_id) from f => []
```

O primeiro caso funde identidades apesar da projeção conter a origem. O segundo
tem o nome da coluna na cláusula, mas não restringe a correspondência entre origens.
Proposta: analisar a chave efetiva de `DISTINCT ON` e a correlação de aliases,
com contraprovas para esses casos; delimitar explicitamente as formas não cobertas.

Leitura integral das 16 views em `1e197ac`: não identifiquei uma redução incorreta
dessas formas no SQL entregue. P04 preserva origem em `DISTINCT ON`, recompra e junção;
P16 pode abandonar a origem na projeção final da CTE porque já resolveu os matches
e usa `UNION ALL` e `count(*)`, sem nova deduplicação. P12 fixa `retail` no anti-join
do caminho quente e carrega origem no agrupamento. As junções de categoria por chave
natural em P08/P11 incluem origem. As janelas de ranking em P03 não particionam por ID.
P07/P09/P10 somam contagens já materializadas nas fatos; não fazem redução por ID.
Essa leitura não é prova da correção de todas as métricas de negócio do lote 3.

### RVL2-04 — TEMP e restauração

Inventário atual via `ro.sh`:

```sql
select rolname,rolsuper,rolcreaterole,rolcreatedb,rolreplication,rolbypassrls,rolconfig
from pg_roles where rolcanlogin or rolname='analyst';
select r.rolname as granted,u.rolname as member,admin_option,inherit_option,set_option
from pg_auth_members m join pg_roles r on r.oid=m.roleid
join pg_roles u on u.oid=m.member order by 1,2;
select datname,datacl from pg_database where datname=current_database();
select n.nspname,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where p.prosecdef;
```

```text
      rolname       | rolsuper | rolcreaterole | rolcreatedb | rolreplication | rolbypassrls |             rolconfig
--------------------+----------+---------------+-------------+----------------+--------------+------------------------------------
 mvp_warehouse      | t        | t             | t           | t              | t            |
 analyst            | f        | f             | f           | f              | f            |
 consumption_reader | f        | f             | f           | f              | f            | {default_transaction_read_only=on}
(3 rows)

       granted        |       member       | admin_option | inherit_option | set_option
----------------------+--------------------+--------------+----------------+------------
 analyst              | consumption_reader | f            | t              | t
 pg_read_all_settings | pg_monitor         | f            | t              | t
 pg_read_all_stats    | pg_monitor         | f            | t              | t
 pg_stat_scan_tables  | pg_monitor         | f            | t              | t
(4 rows)

   datname    |                       datacl
--------------+----------------------------------------------------
 warehouse_db | {=c/mvp_warehouse,mvp_warehouse=CTc/mvp_warehouse}
(1 row)

 nspname | proname
---------+---------
(0 rows)
```

O inventário completo de memberships exclui cadeia indireta a partir de `analyst`
no estado observado. Não existem funções `SECURITY DEFINER` hoje. Airbyte, dbt, Beam,
Airflow e certificado continuam dependentes do login superusuário conforme configuração
e Governança §7; não há outro login operacional não superusuário afetado hoje.
Não foi necessário subir esses ambientes para identificar os logins.

Listagem somente leitura do dump existente, sem executar restauração:

```bash
docker exec -i mvp_ed1_warehouse_db pg_restore --list \
  < data/recovery/aprovado/warehouse_memoria.dump |
python3 -c 'import sys; s=sys.stdin.read(); print("entradas_DATABASE=",sum(" DATABASE " in l for l in s.splitlines())); print("mencoes_consumption_reader=",s.count("consumption_reader")); print("\n".join(s.splitlines()[:12]))'
```

```text
entradas_DATABASE= 0
mencoes_consumption_reader= 0
;
; Archive created at 2026-11-04 14:21:08 UTC
;     dbname: warehouse_db
;     TOC Entries: 327
;     Compression: gzip
;     Dump Version: 1.15-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 16.15
;     Dumped by pg_dump version: 16.15
;
```

O código histórico de `recovery/cli.py` chama `garantir_papeis` e restaura schemas de
memória com `--clean --if-exists --no-owner --single-transaction`, sem `--create`.
Inferência de código + TOC: no banco existente, o ACL do banco permanece; em cluster
novo, esse dump não estabelece a revogação nem cria o leitor. Não é evidência de um
ensaio de restauração. Proposta: explicitar esse pré-requisito no procedimento e tratar
TEMP quando surgirem logins operacionais próprios; não alterar ADR aceito.

### RVL2-05 — comparação sobre os dados de hoje

Foram avaliadas as oito definições alteradas, antes (`26b58b3`) e depois (`1e197ac`),
sobre as mesmas tabelas atuais. `ref` foi resolvido pelo nome/schema do manifest atual;
as variáveis vieram de `dbt_project.yml` histórico. Não se usou a definição da view de HEAD
como se fosse a do lote 2. O comparador executou por `ro.sh -At`, para cada par:

```sql
with old as (/* SQL de 26b58b3 com refs resolvidos */),
new as (/* SQL de 1e197ac com refs resolvidos */), delta as (
 (select 'old' lado,to_jsonb(o) linha from old o
  except all select 'old',to_jsonb(n) from new n)
 union all
 (select 'new',to_jsonb(n) from new n
  except all select 'new',to_jsonb(o) from old o)
) select coalesce(jsonb_agg(to_jsonb(delta)),'[]') from delta;
```

Saída literal (cada linha imprime nome, retorno do wrapper e seu stdout):

```text
average_order_value_by_channel_and_segment exit 0 []
discount_share_by_channel exit 0 [{"lado": "old", "linha": {"year_month": "2025-06", "order_count": 13, "year_number": 2025, "channel_type": "web", "month_number": 6, "discount_amount": 3472.86, "discount_share_pct": 5.97, "net_revenue_amount": 54690.64, "root_category_name": "Eletrônicos", "sales_channel_name": "Loja online", "gross_revenue_amount": 58163.50}}, {"lado": "new", "linha": {"year_month": "2025-06", "order_count": 14, "year_number": 2025, "channel_type": "web", "month_number": 6, "discount_amount": 3472.86, "discount_share_pct": 5.97, "net_revenue_amount": 54690.64, "root_category_name": "Eletrônicos", "sales_channel_name": "Loja online", "gross_revenue_amount": 58163.50}}]
monthly_revenue_by_channel_and_category exit 0 []
on_time_delivery_rate_by_carrier exit 0 []
order_to_delivery_time_by_region exit 0 []
revenue_by_delivery_region exit 0 [{"lado": "old", "linha": {"region": "Sudeste", "state_code": "SP", "state_name": "São Paulo", "unit_count": 84, "order_count": 20, "year_number": 2024, "year_quarter": "2024-T4", "quarter_number": 4, "net_revenue_amount": 66113.08, "sales_channel_name": "Aplicativo", "customer_version_count": 19}}, {"lado": "new", "linha": {"region": "Sudeste", "state_code": "SP", "state_name": "São Paulo", "unit_count": 84, "order_count": 21, "year_number": 2024, "year_quarter": "2024-T4", "quarter_number": 4, "net_revenue_amount": 66113.08, "sales_channel_name": "Aplicativo", "customer_version_count": 19}}]
support_tickets_per_hundred_orders exit 0 []
top_skus_by_revenue exit 0 []
```

### RVL2-06 — contrato JSON

Código do exportador de `1e197ac`, manifest do último build de HEAD. Comandos Python:
`a = lineage.build(manifest); j = lineage.to_json(a, manifest)`, repetidos para comparar
`json.dumps`, e enumeração dos tipos e de folhas não-fonte sem entrada em `relations`.
Saída literal:

```text
problems= [] relations= 199
same_manifest_same_text= True
kinds= ['generated', 'seed', 'source']
missing_non_source_leaves= []
```

Travessia feita somente sobre o JSON serializável: fila iniciada na coluna, consulta de
`relations[relação]['columns'][coluna]['leaves']`, conjunto de visitados e arestas,
folha sem sucessor como terminal. Saída literal:

```text
consumption.top_skus_by_revenue.net_revenue_amount edges= 14 terminals= ['raw.order_items.discount_amount', 'raw.order_items.quantity', 'raw.order_items.unit_price', 'raw_legacy.order_items.discount_amount', 'raw_legacy.order_items.quantity', 'raw_legacy.order_items.unit_price']
consumption.order_to_delivery_time_by_region.avg_order_to_delivery_days edges= 20 terminals= ['raw.delivery_events.event_type', 'raw.delivery_events.occurred_at', 'raw.orders.placed_at', 'raw_legacy.delivery_events.event_type', 'raw_legacy.delivery_events.occurred_at', 'raw_legacy.orders.placed_at']
consumption.skus_below_reorder_point.quantity_on_hand edges= 8 terminals= ['raw.inventory_movements.quantity_delta', 'raw.inventory_movements_stream.quantity_delta', 'raw_legacy.inventory_movements.quantity_delta']
consumption.support_tickets_per_hundred_orders.ticket_count edges= 0 terminals= ['consumption.support_tickets_per_hundred_orders.ticket_count']
```

`ticket_count` tem `kind: generated`: ausência de caminho a raw é intencional na
linhagem de valor e não prova falta de dados de origem. Não foi encontrada necessidade
de mudar o formato 1 para as travessias acima. Não há consumidor real validado.

Recusa de manifest sem compilação: importado `_manifest({})` do teste histórico,
removido `compiled_code` do nó e substituído `lineage.MANIFEST` por objeto em memória
com `exists() == True` e `read_text()` devolvendo esse JSON; chamada `main(['--json'])`
com stdout/stderr capturados. Saída literal:

```text
exit= 1 stdout= ''
linhagem: model.t.m: sem SQL compilado no manifest; rode `make dbt-build`
linhagem incompleta (1 problema(s)): nada é escrito; rode `make dbt-build` (ou `dbt compile`) antes
```

Uma primeira fixture artificial sem o campo obrigatório `database` causou `KeyError`
antes da validação; também não emitiu JSON, mas não foi contada como prova de diagnóstico
amigável. A estabilidade textual foi medida para o mesmo manifest; as listas são ordenadas,
mas as chaves de coluna seguem a ordem das projeções. Não se exige igualdade textual entre
manifests semanticamente equivalentes que reordenem colunas. `manifest_generated_at`
acompanha o manifest e não foi tratado como constante entre builds.

### Documentação

ADR-0049 foi confrontado com Governança §4/§5.2/§7 e Dicionário histórico. Não encontrei
regra vigente nesses trechos exigindo remover `confidential` ou mascarar `personal`
no consumo sintético. A classificação permanece; grants decidem acesso por camada.
O Dicionário remete a política à Governança, sem assumir outro dono para a regra.
As referências à regra anterior no ADR são contexto histórico, não regra vigente.

`git show 1e197ac:docs/pendencias.md` contém literalmente:

```text
### D64 — a chave Fernet do Airflow gerada pelo projeto é inválida
```

D64 trata Fernet, não a exposição sintética; o lote apenas retirou números de linha
voláteis dessa pendência. Nenhuma decisão foi reaberta nem pendência encerrada.

### Contraprovas adicionais de identidade — P04 e P16

Estas duas views já preservavam origem antes do lote 2. A comparação abaixo remove
origem das chaves, projeções e correlações em uma variante sintética, sem alterar o
banco. Mede sensibilidade a essa regressão, não defeito do lote. Os grupos listados
diferem em ao menos uma coluna; não se deve confundir linhas do `EXCEPT ALL` com grupos.

Comando executado no checkout de trabalho:

```bash
.venv/bin/python - <<'PY'
import pathlib,re,json,os,subprocess,yaml,sqlglot
from sqlglot import exp
p=pathlib.Path('/tmp/revisao_lote2_1e197ac');m=json.loads(pathlib.Path('dbt/target/manifest.json').read_text());refs={n['name']:n['schema']+'.'+n['name'] for n in m['nodes'].values() if n['resource_type']=='model'};vs=yaml.safe_load((p/'dbt/dbt_project.yml').read_text())['vars']
for name in ['new_and_repeat_customers_by_month','repeat_purchase_rate_after_support']:
 s=(p/f'dbt/models/consumption/{name}.sql').read_text();s=re.sub(r"\{\{ ref\('([^']+)'\) \}\}",lambda x:refs[x[1]],s);s=re.sub(r'''\{\{ var\(["']([^"']+)["']\) \}\}''',lambda x:str(vs[x[1]]),s)
 a=sqlglot.parse_one(s,read='postgres')
 for n in list(a.find_all(exp.Select,exp.Group,exp.Order,exp.Tuple)):
  n.set('expressions',[x for x in n.expressions if not any(c.name=='source_system' for c in x.find_all(exp.Column))])
 for n in list(a.find_all(exp.EQ)):
  if any(c.name=='source_system' for c in n.find_all(exp.Column)):n.replace(exp.true())
 old=a.sql(dialect='postgres');sql=f"with old as ({old}), new as ({s}), delta as ((select to_jsonb(o) linha from old o except all select to_jsonb(n) from new n) union all (select to_jsonb(n) from new n except all select to_jsonb(o) from old o)) select coalesce(jsonb_agg(linha),'[]') from delta;"
 r=subprocess.run(['/home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh','/dev/stdin','-At'],input=sql,text=True,capture_output=True,env={**os.environ,'ENG_DADOS_DIR':str(pathlib.Path.cwd())});r.check_returncode()
 rows=json.loads(r.stdout);keys=['year_month','sales_channel_name','customer_segment_name'] if name.startswith('new_') else ['year_month','sales_channel_name','has_support_ticket','support_category_name']
 groups=sorted({tuple(str(x[k]) for k in keys) for x in rows})
 print(name,':',len(rows),'linhas no EXCEPT ALL;',len(groups),'grupos')
 for group in groups:print(' / '.join(group))
PY
```

Saída literal:

```text
new_and_repeat_customers_by_month : 129 linhas no EXCEPT ALL; 73 grupos
2024-01 / Loja online / Consumidor final
2024-03 / Aplicativo / Consumidor final
2024-03 / Loja online / Atacado
2024-03 / Loja online / Consumidor final
2024-04 / Aplicativo / Institucional
2024-04 / Loja online / Institucional
2024-05 / Loja física / Assinante
2024-05 / Loja física / Consumidor final
2024-05 / Loja online / Inativo
2024-05 / Loja online / Institucional
2024-06 / Aplicativo / Assinante
2024-06 / Loja física / Institucional
2024-07 / Aplicativo / Assinante
2024-07 / Aplicativo / Revenda
2024-07 / Loja online / Assinante
2024-07 / Loja online / Atacado
2024-08 / Aplicativo / Atacado
2024-09 / Aplicativo / Consumidor final
2024-09 / Aplicativo / Corporativo
2024-09 / Loja física / Inativo
2024-09 / Loja online / Inativo
2024-09 / Loja online / Institucional
2024-09 / Loja online / Pequeno varejo
2024-10 / Aplicativo / Assinante
2024-10 / Loja física / Revenda
2024-11 / Loja física / Assinante
2024-11 / Loja online / Corporativo
2024-11 / Loja online / Institucional
2024-11 / Loja online / Pequeno varejo
2024-12 / Aplicativo / Atacado
2024-12 / Aplicativo / Consumidor final
2024-12 / Loja física / Consumidor final
2025-01 / Loja física / Pequeno varejo
2025-03 / Aplicativo / Consumidor final
2025-03 / Aplicativo / Institucional
2025-03 / Loja física / Institucional
2025-03 / Loja física / Pequeno varejo
2025-03 / Loja física / Revenda
2025-03 / Loja online / Corporativo
2025-03 / Loja online / Institucional
2025-04 / Loja online / Inativo
2025-05 / Aplicativo / Atacado
2025-05 / Loja física / Assinante
2025-05 / Loja física / Inativo
2025-05 / Loja física / Institucional
2025-05 / Loja online / Consumidor final
2025-06 / Aplicativo / Revenda
2025-06 / Loja física / Assinante
2025-06 / Loja física / Atacado
2025-06 / Loja online / Revenda
2025-07 / Aplicativo / Inativo
2025-08 / Aplicativo / Pequeno varejo
2025-08 / Loja física / Corporativo
2025-09 / Loja física / Consumidor final
2025-10 / Loja online / Atacado
2025-11 / Loja física / Consumidor final
2025-11 / Loja online / Inativo
2025-12 / Aplicativo / Assinante
2025-12 / Loja física / Atacado
2025-12 / Loja física / Pequeno varejo
2025-12 / Loja online / Atacado
2025-12 / Loja online / Consumidor final
2025-12 / Loja online / Pequeno varejo
2026-02 / Loja online / Pequeno varejo
2026-03 / Loja online / Assinante
2026-04 / Loja física / Atacado
2026-04 / Loja física / Consumidor final
2026-04 / Loja física / Inativo
2026-05 / Aplicativo / Atacado
2026-06 / Loja física / Inativo
2026-07 / Aplicativo / Atacado
2026-07 / Loja física / Pequeno varejo
2026-08 / Loja física / Atacado
repeat_purchase_rate_after_support : 31 linhas no EXCEPT ALL; 20 grupos
2024-01 / Aplicativo / False / Sem chamado
2024-01 / Aplicativo / True / Pagamento
2024-08 / Aplicativo / False / Sem chamado
2024-08 / Aplicativo / True / Entrega
2025-01 / Loja física / False / Sem chamado
2025-01 / Loja física / True / Devolução
2025-01 / Loja física / True / Produto
2025-01 / Loja online / False / Sem chamado
2025-01 / Loja online / True / Entrega
2025-05 / Aplicativo / False / Sem chamado
2025-05 / Aplicativo / True / Entrega
2025-09 / Loja física / False / Sem chamado
2025-09 / Loja física / True / Entrega
2025-11 / Aplicativo / False / Sem chamado
2025-11 / Aplicativo / True / Produto
2025-11 / Loja online / False / Sem chamado
2025-11 / Loja online / True / Devolução
2025-11 / Loja online / True / Produto
2026-01 / Loja online / False / Sem chamado
2026-01 / Loja online / True / Pagamento
```

### RVL2-07 — regressões executadas

Comando no snapshot de `1e197ac`:

```bash
PYTHONPATH=/tmp/revisao_lote2_1e197ac/src \
  make -C /tmp/revisao_lote2_1e197ac check-offline
```

A primeira execução parou antes de pytest porque o arquivo ignorado de evidência
`data/medicoes/diario_b5.md` não acompanha `git archive`:

```text
CONVERSAS_COM_CHAT/PLANO_material_de_estudo.md:524: ../data/medicoes/diario_b5.md — arquivo não existe

docs-check: 1 quebrado(s) de 112 documentos, 1055 links de arquivo, 158 âncoras, 643 citações de ADR
```

Uma tentativa de disponibilizá-lo por symlink foi recusada pelo verificador por apontar
para fora do snapshot. Depois foi copiado o arquivo existente para o diretório temporário,
sem modificar seu original. Isso é um insumo local adicional, não arquivo de `1e197ac`.
Não se introduziu correção de código para fazer o alvo passar. Saída final, omitidas
apenas as linhas de pontos do progresso:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 112 documentos, 1055 links de arquivo, 158 âncoras, 643 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
=========================== short test summary info ============================
SKIPPED [1] tests/test_acesso_macro.py:105: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:120: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:133: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:155: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:166: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:213: sem dbt/target/manifest.json; rode `make dbt-build`
547 passed, 6 skipped, 138 deselected in 128.77s (0:02:08)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
     11 tests/test_acesso.py
     13 tests/test_captura_legado.py
      3 tests/test_carga.py
      3 tests/test_classificacao.py
      2 tests/test_consumo.py
      1 tests/test_fato_incremental.py
     12 tests/test_legacy_classification.py
      7 tests/test_legado_contraprovas.py
     22 tests/test_legado_deteccao.py
     55 tests/test_legado_remocao.py
      4 tests/test_migracao_legado.py
      3 tests/test_reconciliacao_raw.py
      2 tests/test_retencao.py
check-offline: as três etapas passaram
make: Leaving directory '/tmp/revisao_lote2_1e197ac'
```

Esses seis testes não foram declarados aprovados. As sondagens manuais de linhagem
acima usaram separadamente o manifest atual. O resultado não reproduz o total esperado
de 749, nem substitui os 929 da execução do autor em outro commit.

`make secrets-history`, no checkout de trabalho `d1f45a2`, retornou zero. Última linha
literal (as 12 linhas anteriores descrevem achados já tratados, com valores mascarados):

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

`git diff --check` não apontou problemas. Apenas `REVISAO.md` foi alterado no checkout;
os arquivos não rastreados `GEMINI.md` e `NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam
e não foram tocados. Os artefatos temporários da revisão ficaram em `/tmp`.

### O que esta revisão não verificou

- Não reproduziu a medição histórica perdida de 23/10 nem reconstruiu o warehouse em
  `1e197ac`. As comparações históricas de SQL usam dados e schemas do warehouse atual.
- Não executou restauração em cluster novo; a conclusão sobre login/ACL resulta da leitura
  do código e do TOC do dump atual. Não mediu tempo até o próximo build.
- Não executou a cadeia de injeção contra o servidor, nem alterou memberships/atributos
  como superusuário para provar autorreparo. A evidência é o DDL emitido por um double.
- Não provocou falha real de rotação de senha nem examinou logs completos de servidor;
  a análise de não envio de senha em texto abrange `_garantir_leitor`, com autenticação
  real e confirmação do prefixo SCRAM no catálogo, sem alterar sua senha.
- Não exercitou concorrência de dois `garantir()`, funções `SECURITY DEFINER` futuras,
  logins operacionais futuros ou necessidade de TEMP após migração desses componentes.
- Não fez teste de integração com consumidor externo do JSON, nem compilou manifest
  histórico. Não verificou determinismo entre processos com diferentes hash seeds;
  comparou duas derivações do mesmo manifest e inspecionou a ordenação do serializador.
- Não rodou `make check`, os 138 testes de integração desmarcados nem os seis testes
  pulados no snapshot. Não reavaliou métricas de negócio dos commits do lote 3.



## Rodada 2 — lote 2

Revisão em `15ab79d`, limitada a `git log d1f45a2..15ab79d`: `3f6ea1b`,
`4304376`, `00ce350` e `15ab79d`. Sem poder de aprovação e sem implementar
correções. **O lote 2 ainda não pode ser encerrado:** resta um bloqueante no
contrato do leitor e dois ajustes na guarda. As observações abaixo não ampliam
este lote para o lote 3.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-2-01 | `src/mvp_ed1/governance.py:78`, `FECHADAS_A_PUBLIC`; Governança §7 | A lista fecha os large objects e os advisory locks, mas deixa `pg_logical_emit_message(boolean,text,text)` e `(boolean,text,bytea)` executáveis por `PUBLIC` e pelo leitor. Ambas escreveram mensagens no WAL e devolveram LSN na conexão real do leitor. O contrato de impedir escrita por função continua incompleto; os testes só conferem a lista declarada, sem este caminho. Incluir as duas assinaturas no fechamento e na contraprova é o ajuste proposto, sem implementação nesta revisão. Evidência A. | `bloqueante` | **Corrigido.** Reproduzido: como o leitor, `pg_logical_emit_message(true, …)` devolveu LSN `4/A69E93B0`. `pg_logical_emit_message` entrou em `FECHADAS_A_PUBLIC` (todas as assinaturas). E, como o achado mostra que lista é argumento, o oráculo agora é o que **sobra**: `test_o_que_fica_aberto_ao_leitor_e_o_classificado` exige que toda função volátil executável pelo leitor (fora `internal`/gatilho/*handler*) esteja em `ABERTAS_AO_LEITOR`, com o motivo, e que nenhuma função volátil de fora do `pg_catalog` lhe seja executável; `test_o_servidor_recusa_o_que_verifica_por_dentro` chama pelo leitor uma de cada família que o servidor recusa por dentro (slots de replicação, `binary_upgrade_*`, `pg_nextoid`, `*_old` do adminpack, `pg_extension_config_dump`, sinal a sessão do superusuário, `session_replication_role`), confere o SQLSTATE e que nenhum slot ficou; BRIN/GIN e sequência são zero no armazém, e o teste obriga a sondá-los se aparecerem. Contraprova: antes do `garantir()`, os três testes que tocam a função acusaram; depois, `86 passed` em `test_acesso` + `test_leitor` + guarda. Governança §7 v2.11. |
| RVL2-2-02 | `tests/test_identidade_no_consumo.py:93`, `_origem_correlaciona` | A origem ainda pode não correlacionar os lados: um literal em **qualquer** igualdade basta, inclusive de terceiro alias/subconsulta; igualdade sob `OR` ou `NOT` também basta. `a.order_id=b.order_id AND b.source_system='retail'` aceita `a=legacy, b=retail`, demonstrado com `VALUES`. São lacunas da correção de RVL2-03 dentro da própria cláusula, além do limite declarado. Proposta: exigir restrição efetiva dos dois lados, sem tomar uma ocorrência da coluna como prova; preservar P12 por sua premissa explícita de origem única. Evidência C. | `ajuste` | **Corrigido** na guarda: só conta termo ligado por `and` no topo da condição (nada sob `or`/`not` nem em subconsulta de terceiro), e a origem tem de restringir **os dois lados** — igualada entre eles, ou fixada em cada um com o mesmo valor, por literal ou por ler `source('retail'\|'legacy', …)`, que é como P12 passa sem mudar a view. O caso antigo `exists (… b.source_system = 'retail' and b.movement_id = a.movement_id)`, que esperava 0, passou a esperar 1: era exatamente a lacuna. Contraprova com a guarda de `15ab79d` em memória: as sete formas novas deram 0 antes e 1 agora; as 16 views, `[]`. |
| RVL2-2-03 | `tests/test_identidade_no_consumo.py:96`, reconhecimento exclusivo de `exp.EQ` | Regressão de falso positivo: origem ligada por `a.source_system IS NOT DISTINCT FROM b.source_system`, com `a.order_id=b.order_id`, passa na guarda anterior e é acusada agora. O mesmo ocorre com origem transportada sob alias de coluna de CTE. Não há esses casos nas 16 views atuais. Proposta: reconhecer a igualdade válida no primeiro caso; para aliases de CTE, resolver a procedência ou declarar expressamente a forma não suportada, sem prometer que todo diagnóstico prova junção inválida. Evidência C. | `ajuste` | **Corrigido / declarado.** `is not distinct from` conta como igualdade, da origem e do identificador (antes 1, agora 0 no caso válido). A origem renomeada por CTE continua acusada, agora como **limite declarado** no docstring e com caso de teste: a guarda não resolve procedência, acusa por cautela, e a regra é manter o nome `source_system`. |
| RVL2-2-04 | Limites da guarda, preexistentes ao intervalo | `USING(order_id)`, igualdade de identificador com `IS NOT DISTINCT FROM` e `IN (SELECT order_id …)` sem origem continuam sem achado; igualdade de identificadores na projeção provoca `AttributeError`. Comparação com `d1f45a2` confirma que não nasceram nestes quatro commits. São observação para a evolução da guarda; a descrição atual do limite, restrita a fluxo entre cláusulas, é estreita demais. Evidência C. | `observação` | **Corrigido além do pedido**, por ser barato: `join … using (…)` sem a origem, `in`/`not in (select …)` com identificador sem a origem e `is not distinct from` entre identificadores agora acusam (0 → 1 cada); a igualdade na projeção não quebra mais (`AttributeError` → 0, não junta nem reduz). O docstring reescreve o limite: lê sintaxe, não escopo nem fluxo — qualificador como escrito, origem renomeada acusada, CTE que perdeu a origem e `union` sem `all` passam. |
| RVL2-2-05 | Alcance da promessa “não interfere”; funções e locks ainda permitidos | `pg_notify`/`LISTEN`, alteração dos próprios timeouts, cancelamento/encerramento de outra sessão do mesmo leitor e `ACCESS SHARE` na view continuam possíveis. Não demonstram escalada nem escrita nas tabelas, mas impedem prometer ausência absoluta de interferência: leitura longa pode atrasar DDL. Não foi encontrada aplicação atual de `LISTEN`/`NOTIFY`, nem outro login operacional não superusuário. O limite de disponibilidade deve ser tratado pelo dono da política; não proponho bloquear indiscriminadamente funções de sessão. Evidências A e D. | `observação` | **Declarado** na Governança §7 v2.11, no dono da política: "não interfere" ganhou alcance explícito — não escreve, não toma lock da captura, não sinaliza sessão de outro login; ainda pode `notify`/`listen`, alongar os próprios *timeouts*, sinalizar sessão do próprio login e segurar `access share` que atrasa DDL concorrente. Acrescentado o que a sua bateria A mostrou de passagem: `alter role consumption_reader set default_transaction_read_only=off` passou — o padrão de leitura é conveniência, a garantia é o privilégio, e o `garantir()` seguinte o repõe. Nada disso foi bloqueado: os quatro casos estão na classe "interferência declarada" ou "própria sessão" do oráculo. |

### Fechamento de cada resposta da rodada 1

“Fechado” abaixo é conclusão técnica desta revisão, não aceite do Owner.

| Resposta | Conclusão nesta rodada | Comando e evidência |
|---|---|---|
| RVL2-01 | **Parcialmente fechado.** O defeito original de large objects está fechado; a garantia mais ampla de só leitura permanece aberta por RVL2-2-01. | Bateria A: nove entradas de LO negadas com `42501`; inventário sem privilégio de escrita em relações; `65 passed` na suíte direcionada. |
| Inclusão dos advisory locks | **Fechada.** As 16 assinaturas de tomada, com uma/duas chaves, compartilhadas/exclusivas, de sessão/transação, inclusive `try`, foram chamadas e negadas. | Bateria A: 16 respostas `42501`; catálogo `reader_exec=f`, `public_exec=f`; nenhum lock residual. Não chamei as chaves reais da captura. |
| RVL2-02 | **Fechado.** Nomes do catálogo são compostos no servidor; newline recusado; `%I`/`%s` chegam corretamente; o papel hostil é removido inclusive se `garantir()` falha. | Dublê B; chamada real de `format` em A; teste real no conjunto `65 passed`; falha controlada B seguida de inventário sem papel/membership residual. |
| RVL2-03 | **Parcialmente fechado.** As três contraprovas originais agora falham como devem. Restam RVL2-2-02 e RVL2-2-03, sem defeito dessas formas identificado nas views atuais. | Matriz C: originais `0 → 1`; literais/`OR`/`NOT` ainda `0`; dois casos válidos `0 → 1`; 16 views com `[]`. |
| RVL2-04 | **Fechado como documentação do procedimento.** A sequência contém o build que cria o leitor e estabelece os ACLs em cluster novo. Não é prova de restauração executada nesta rodada. | Leitura de `recovery/cli.py`, `governance.garantir_papeis` e `nl -ba Makefile`: linha 704 chama `dbt-rebuild`; este chama `governance garantir` antes do dbt. Evidência D. |
| RVL2-05 | **Fechado como ressalva de medição.** A evidência anterior de P05 `20 → 21` e P06 `13 → 14` vale para os dados regenerados; não valida o `11 → 12` histórico. Nada nestes quatro commits muda essas views ou reescreve um ADR. | Busca nos arquivos rastreados de `docs/`, README e `dbt/`: `documentos_com_11_para_12= []`; diff do intervalo sem views. Evidência D. Não repeti a medição de negócio. |
| RVL2-06 | **Fechado no escopo do produtor, com obrigação do consumidor diferida.** O Dicionário já explica contagem de linhas como `generated`; a Parte II do `bi-como-codigo` é o dono adequado da interpretação pelo exportador. | Leitura do Dicionário §3.2/§3.3 e `bi-como-codigo/PLAN.md` §3.5/etapa 2.4. Evidência D. O plano ainda não contém regra específica para aceitar terminal `generated`: não declaro essa tarefa executada. |
| RVL2-07 | **Fechado.** Totais de commits/ambientes distintos não são intercambiáveis. O HEAD desta rodada tem 761 testes offline, não 749 nem os 547 do snapshot histórico. | `make check-offline`: `761 passed, 185 deselected`; `make secrets-history`: nenhum achado não tratado. Evidência E. O `make check` do autor não foi repetido. |

### A — conexão real do leitor e funções ainda abertas

Comando executado, carregando credenciais sem imprimi-las:

```bash
set -a; . ./.env; set +a
.venv/bin/python /tmp/rvl2-round2-reader.py
```

O script temporário abriu `psycopg.connect` com `WAREHOUSE_READER_USER` e
`WAREHOUSE_READER_PASSWORD`, no host `127.0.0.1`, porta/banco do armazém,
`application_name=rvl2_round2_reader`, `statement_timeout=2000` e
`lock_timeout=500` para limitar as sondagens. Para **cada** SQL impresso abaixo:

```python
try:
    c.execute('set transaction read write')
    r = c.execute(q)
    print(q, '=>', r.fetchall() if r.description else 'OK')
except psycopg.Error as e:
    print(q, '=>', e.sqlstate, e.diag.message_primary)
finally:
    c.rollback()
```

Os dois sinais atingiram exclusivamente outras conexões descartáveis criadas
pelo script como o mesmo leitor, ociosas e já com rollback; nenhum PID operacional
foi sinalizado. `ROLLBACK` não desfaz um sinal: a sessão terminada era da própria
sonda. As conexões foram fechadas em `finally`. Saída literal:

```text
show default_transaction_read_only => [('on',)]
select count(*) from consumption.monthly_revenue_by_channel_and_category => [(1494,)]
create table public.__rvl2(x int) => 42501 permission denied for schema public
create table consumption.__rvl2(x int) => 42501 permission denied for schema consumption
create temp table __rvl2(x int) => 42501 permission denied to create temporary tables in database "warehouse_db"
create schema __rvl2 => 42501 permission denied for database warehouse_db
create function public.__rvl2() returns int language sql as $$select 1$$ => 42501 permission denied for schema public
create sequence public.__rvl2 => 42501 permission denied for schema public
insert into raw.orders select * from raw.orders where false => 42501 permission denied for schema raw
delete from consumption.monthly_revenue_by_channel_and_category where false => 55000 cannot delete from view "monthly_revenue_by_channel_and_category"
set role analyst => OK
set role transformer => 42501 permission denied to set role "transformer"
set role mvp_warehouse => 42501 permission denied to set role "mvp_warehouse"
set session authorization mvp_warehouse => 42501 permission denied to set session authorization "mvp_warehouse"
alter role consumption_reader createrole => 42501 permission denied to alter role
alter role consumption_reader set default_transaction_read_only=off => OK
grant analyst to auditor => 42501 permission denied to grant role "analyst"
create role __rvl2 => 42501 permission denied to create role
copy (select 1) to program 'true' => 42501 permission denied to COPY to or from an external program
select lo_create(0) => 42501 permission denied for function lo_create
select lo_creat(-1) => 42501 permission denied for function lo_creat
select lo_from_bytea(0,decode('4142','hex')) => 42501 permission denied for function lo_from_bytea
select lo_open(0,262144) => 42501 permission denied for function lo_open
select lo_put(0,0,decode('41','hex')) => 42501 permission denied for function lo_put
select lowrite(0,decode('41','hex')) => 42501 permission denied for function lowrite
select lo_truncate(0,0) => 42501 permission denied for function lo_truncate
select lo_truncate64(0,0) => 42501 permission denied for function lo_truncate64
select lo_unlink(0) => 42501 permission denied for function lo_unlink
select lo_get(0) => 42704 large object 0 does not exist
select lo_get(0,0,1) => 42704 large object 0 does not exist
select loread(0,1) => 42704 invalid large-object descriptor: 0
select lo_import('/__rvl2_missing__') => 42501 permission denied for function lo_import
select lo_export(0,'/__rvl2_missing__') => 42501 permission denied for function lo_export
select pg_notify('__rvl2_round2','probe aborted') => [('',)]
listen __rvl2_round2 => OK
select set_config('statement_timeout','1h',true) => [('1h',)]
select set_config('lock_timeout','0',true) => [('0',)]
select set_config('session_replication_role','replica',true) => 42501 permission denied to set parameter "session_replication_role"
select set_config('role','transformer',true) => 42501 permission denied to set role "transformer"
select nextval('raw.inventory_movements_stream_event_sequence_seq') => 42501 permission denied for schema raw
lock table consumption.monthly_revenue_by_channel_and_category in access share mode => OK
lock table consumption.monthly_revenue_by_channel_and_category in access exclusive mode => 42501 permission denied for view monthly_revenue_by_channel_and_category
select pg_logical_emit_message(true,'__rvl2_round2','aborted probe') => [('4/A6989F38',)]
select pg_logical_emit_message(true,'__rvl2_round2',decode('41','hex')) => [('4/A6989FA8',)]
select pg_advisory_lock(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_lock
select pg_advisory_lock(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_lock
select pg_advisory_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_lock_shared
select pg_advisory_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_lock_shared
select pg_advisory_xact_lock(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_xact_lock
select pg_advisory_xact_lock(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_xact_lock
select pg_advisory_xact_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_xact_lock_shared
select pg_advisory_xact_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_xact_lock_shared
select pg_try_advisory_lock(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_lock
select pg_try_advisory_lock(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_lock
select pg_try_advisory_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_lock_shared
select pg_try_advisory_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_lock_shared
select pg_try_advisory_xact_lock(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_xact_lock
select pg_try_advisory_xact_lock(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_xact_lock
select pg_try_advisory_xact_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_xact_lock_shared
select pg_try_advisory_xact_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_xact_lock_shared
select pg_cancel_backend(118909) => [(True,)]
select pg_terminate_backend(118910) => [(True,)]
sqlalchemy_format => ('revoke "x""; --" from consumption_reader', 'revoke execute on function lo_create(oid) from public')
Todas as transações revertidas; conexões fechadas.
```

A mensagem `55000` da view agregada não prova ACL. `nextval` foi barrado no schema
antes de resolver a sequência: não prova privilégio no objeto. O inventário
complementar encontrou **zero sequências** no warehouse e zero relações de usuário
com `INSERT/UPDATE/DELETE/TRUNCATE` concedidos ao leitor; nenhum contador foi avançado.

As duas chamadas a `pg_logical_emit_message` acima usaram `transactional=true` e
rollback: não publicaram transação confirmada, mas o retorno LSN evidencia a escrita
no WAL. A variante `false` **não foi executada**; sua emissão independente de commit
é comportamento documentado pelo PostgreSQL, não uma medição desta revisão.
[PostgreSQL 16 — mensagens de decodificação lógica](https://www.postgresql.org/docs/16/functions-admin.html#FUNCTIONS-REPLICATION)
explica que a função envia conteúdo ao WAL e distingue os dois modos. Não se criou
slot nem se consumiu stream lógico. As sondagens, como qualquer transação de teste,
não prometem desfazer WAL físico ou estatísticas do servidor.

Inventário feito **antes e depois** pelo wrapper obrigatório, com o mesmo SQL:

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl2-round2-inventory.sql
```

Para cada assinatura, consultados `has_function_privilege('consumption_reader',
p.oid,'execute')` e `aclexplode(coalesce(p.proacl,acldefault('f',p.proowner)))`,
com `grantee=0` para PUBLIC. Trecho literal:

```text
                     signature                     | reader_exec | public_exec
 pg_logical_emit_message(boolean,text,text)        | t           | t
 pg_logical_emit_message(boolean,text,bytea)       | t           | t
 lo_get(oid)                                       | t           | t
 lo_get(oid,bigint,integer)                        | t           | t
 loread(integer,integer)                           | t           | t
 lo_import(text)                                   | f           | f
 lo_import(text,oid)                               | f           | f
 lo_export(oid,text)                               | f           | f
```

As 25 assinaturas da lista (nove LO e 16 advisory) tinham ambos os campos `f`.
Isso cobre tanto `pg_advisory_lock(ns, hashtext(tentativa))` de
`bloqueio_da_tentativa` quanto `pg_advisory_xact_lock(ns, chave)` da abertura
em `legacy/captura.py:236`: são as mesmas assinaturas de dois inteiros negadas em A.
O dublê também confirmou que a ausência de nomes no catálogo gera erro, sem pulo.
Somente `plpgsql` está instalado: não há `dblink`, outra extensão ou função de
usuário/`SECURITY DEFINER` nos schemas de aplicação. `lo_compat_privileges=off` e
`pg_largeobject_metadata` vazio: **não foi possível exercitar leitura de LO de outro
dono sem criar uma fixture privilegiada**, o que não fiz. `lo_get(0)` acusar objeto
inexistente não prova proteção de um objeto real. A proteção por ACL do LO é
[documentada pelo PostgreSQL](https://www.postgresql.org/docs/16/lo-implementation.html).
`loread` exige descritor; `lo_open` agora é negado também para leitura. A justificativa
“sem criar, não há o que ler” vale para o inventário atual, não como regra universal
sobre LOs futuros de outro dono concedidos ao leitor.

`set_config` não contornou parâmetros privilegiados nem `SET ROLE`; os timeouts são
configuração da própria sessão. A sonda aceitou `statement_timeout=1h` e
`lock_timeout=0`, sem esperar uma hora nem bloquear trabalho externo. `ACCESS SHARE`
na view passou e foi liberado imediatamente; não provoquei concorrência com DDL.
`pg_notify` e `LISTEN` passaram, mas foram revertidos. Notificações só são entregues
com commit e seus canais não isolam usuários, conforme
[PostgreSQL 16 — NOTIFY](https://www.postgresql.org/docs/16/sql-notify.html).
Nenhum canal operacional foi ouvido. Retirar apenas `pg_notify` não retiraria o
comando SQL `NOTIFY`.

### B — injeção, percentuais e limpeza do teste real

Reexecução do dublê da rodada 1 adaptado **somente** para devolver também os nomes
agora consultados por `_fechar_a_public`, sem executar DDL. O valor hostil foi
`x" from consumption_reader; ALTER ROLE analyst SUPERUSER; --`; o nome fictício do
banco continha aspas e `;`. Comando `.venv/bin/python /tmp/rvl2-round2-double.py`:

```text
hostile_catalog_value_in_SQL= False
membership_uses_format_I= True
database_uses_format_I= True
signatures_use_regprocedure_and_format_s= True
newline rejected: user
newline rejected: password
missing_catalog_names => funções a fechar que o pg_catalog não tem: ['lo_creat', 'lo_create', 'lo_from_bytea', 'lo_open', 'lo_put', 'lo_truncate', 'lo_truncate64', 'lo_unlink', 'lowrite', 'pg_advisory_lock', 'pg_advisory_lock_shared', 'pg_advisory_xact_lock', 'pg_advisory_xact_lock_shared', 'pg_try_advisory_lock', 'pg_try_advisory_lock_shared', 'pg_try_advisory_xact_lock', 'pg_try_advisory_xact_lock_shared']
```

Os blocos `DO` de membership e fechamento não interpolam texto de catálogo em
Python: `r.rolname` e `current_database()` passam por `%I`; a assinatura é
`p.oid::regprocedure` e passa por `%s`, representação SQL produzida pelo servidor.
Os nomes da lista são constantes versionadas. O bloco de criação e os literais de
usuário usam o valor restrito por `fullmatch` no caminho `leitor_do_ambiente` →
`garantir`; `_garantir_leitor` não é uma API que valide argumentos arbitrários por
conta própria. O verificador SCRAM não contém aspas e vai por `exec_driver_sql`.
Não identifiquei entrada de catálogo ou `.env` não escapada nesses caminhos.

O dublê sozinho **não prova o transporte dos percentuais**. A suíte real executa o
`DO` com membership hostil e os revokes; a chamada adicional abaixo usa o mesmo
`Connection.execute(text(...))`, SQLAlchemy e psycopg, como leitor, com rollback:

```sql
select format('revoke %I from %I', 'x"; --', current_user),
       format('revoke execute on function %s from public', 'lo_create(oid)'::regprocedure)
```

O resultado `sqlalchemy_format` está colado em A: aspas internas dobradas e assinatura
expandida. Portanto não chegaram `%%I`/`%%s` literais ao `format` do servidor; eventual
escape interno do driver é consumido no transporte. Não criei um banco de nome hostil;
essa variante é coberta pela composição e pelo `format` real, não por criação de banco.

**Executei `tests/test_acesso.py`**, conforme autorização do pedido, junto dos dois
arquivos offline:

```bash
set -a; . ./.env; set +a
.venv/bin/pytest -q -rs tests/test_acesso.py tests/test_leitor.py \
  tests/test_identidade_no_consumo.py
```

```text
.................................................................        [100%]
65 passed in 3.77s
```

Isso inclui os 13 testes de acesso, o papel hostil real, a retirada da membership e
`analyst.rolsuper=False`. Não invoquei `governance garantir` como comando: sua chamada
interna ao teste autorizado é a exceção exercitada. Ela repõe o verificador SCRAM com
sal novo, como o código declara; senha efetiva, atributos e privilégios ficam iguais.

Para a limpeza **quando `garantir()` lança erro**, o mesmo teste foi executado com
plugin temporário de pytest que substitui `governance.garantir` por uma função que
lança `RuntimeError` imediatamente, antes de qualquer ação dela. Nenhum arquivo do
repositório foi alterado para isso:

```bash
set -a; . ./.env; set +a
PYTHONPATH=/tmp:$PWD/src .venv/bin/pytest -q -p rvl2_round2_fail_cleanup \
  tests/test_acesso.py::test_membro_com_nome_que_fecharia_o_identificador_sai_sem_injetar
```

Saída relevante (argumentos sensíveis do traceback omitidos do registro):

```text
E       RuntimeError: RVL2_ROUND2_FALHA_CONTROLADA_ANTES_DE_GARANTIR
FAILED tests/test_acesso.py::test_membro_com_nome_que_fecharia_o_identificador_sai_sem_injetar
1 failed in 0.22s
```

Falha **esperada**, não regressão da suíte. O inventário posterior mostrou zero papéis
com o nome de sonda e nenhum desvio de ACL/atributos; `DROP ROLE` elimina memberships
automaticamente, como confirma
[PostgreSQL 16 — DROP ROLE](https://www.postgresql.org/docs/16/sql-droprole.html).
A criação e o grant iniciais estão numa única transação; se falharem antes do `try`,
são revertidos. Se `garantir()` falhar dentro de `engine.begin`, sua transação também
é revertida, e o `finally` abre outra para apagar o papel sem objetos próprios. Essa
limpeza é adequada ao cenário do teste. Não foi simulado servidor indisponível no
`finally`, morte do processo nem outra sessão usando o papel de teste.

### C — guarda, contraprovas e 16 views

Comando `.venv/bin/python /tmp/rvl2-round2-identity.py`: importação por
`importlib.util.spec_from_file_location` do arquivo de testes do HEAD e chamada a
`violacoes(sql)` para cada SQL literal abaixo. Depois, `violacoes(_sql(p))` para todos
os `MODELOS`. Saída literal:

```text
round1_distinct 'select distinct on (order_id) source_system, order_id from f' => ['distinct on sem a origem: order_id']
round1_self 'select * from a join b on a.order_id=b.order_id and a.source_system=a.source_system' => ['junção sem a origem: a.order_id = b.order_id AND a.source_system = a.source_system']
round1_window 'select row_number() over(partition by order_id) from f' => ['janela particionada sem a origem: order_id']
literal_one_side "select * from a join b on a.order_id=b.order_id and b.source_system='retail'" => []
literal_third_table "select * from a join b on a.order_id=b.order_id and exists (select 1 from c where c.source_system='retail')" => []
or_origin 'select * from a join b on a.order_id=b.order_id or a.source_system=b.source_system' => []
not_origin 'select * from a join b on a.order_id=b.order_id and not (a.source_system=b.source_system)' => []
unqualified_valid 'select * from a where exists (select 1 from b where order_id=a.order_id and source_system=a.source_system)' => []
unqualified_self 'select * from a where exists (select 1 from b where order_id=a.order_id and source_system=source_system)' => ['junção sem a origem: order_id = a.order_id AND source_system = source_system']
aliases 'select * from a x join b y on x.order_id=y.order_id and x.source_system=y.source_system' => []
names 'select * from a join b on a.order_id=b.order_id and a.source_system=b.source_system' => []
cte_alias 'with x as (select source_system as origin, order_id from a) select * from x join b on x.order_id=b.order_id and x.origin=b.source_system' => ['junção sem a origem: x.order_id = b.order_id AND x.origin = b.source_system']
using_valid 'select * from a join b using (source_system,order_id)' => []
using_bad 'select * from a join b using (order_id)' => []
nullsafe_valid 'select * from a join b on a.order_id=b.order_id and a.source_system is not distinct from b.source_system' => ['junção sem a origem: a.order_id = b.order_id AND a.source_system IS NOT DISTINCT FROM b.source_system']
nullsafe_bad 'select * from a join b on a.order_id is not distinct from b.order_id' => []
in_valid 'select * from a where (source_system,order_id) in (select source_system,order_id from b)' => []
in_bad 'select * from a where order_id in (select order_id from b)' => []
select_equality 'select a.order_id=b.order_id from a cross join b' => AttributeError 'NoneType' object has no attribute 'args'
views= 16
average_order_value_by_channel_and_segment.sql => []
cart_conversion_rate_by_channel.sql => []
discount_share_by_channel.sql => []
gross_margin_by_category.sql => []
inventory_turnover_by_sku_and_warehouse.sql => []
monthly_revenue_by_channel_and_category.sql => []
new_and_repeat_customers_by_month.sql => []
on_time_delivery_rate_by_carrier.sql => []
order_to_delivery_time_by_region.sql => []
payment_approval_rate_by_method.sql => []
refund_rate_by_reason.sql => []
repeat_purchase_rate_after_support.sql => []
revenue_by_delivery_region.sql => []
skus_below_reorder_point.sql => []
support_tickets_per_hundred_orders.sql => []
top_skus_by_revenue.sql => []
```

Repeti a mesma matriz carregando o texto de
`git show d1f45a2:tests/test_identidade_no_consumo.py` em memória. Recorte comparativo
(número de violações, não resultado SQL):

```text
round1_distinct antes= 0 agora= 1
round1_self antes= 0 agora= 1
round1_window antes= 0 agora= 1
literal_one_side antes= 0 agora= 0
literal_third_table antes= 0 agora= 0
or_origin antes= 0 agora= 0
not_origin antes= 0 agora= 0
unqualified_valid antes= 0 agora= 0
unqualified_self antes= 0 agora= 1
aliases antes= 0 agora= 0
names antes= 0 agora= 0
cte_alias antes= 0 agora= 1
using_valid antes= 0 agora= 0
using_bad antes= 0 agora= 0
nullsafe_valid antes= 0 agora= 1
nullsafe_bad antes= 0 agora= 0
in_valid antes= 0 agora= 0
in_bad antes= 0 agora= 0
select_equality antes= AttributeError agora= AttributeError
```

A origem em literal de só um lado não restringe o outro. Prova SQL somente leitura,
executada via `ro.sh /tmp/rvl2-round2-extra.sql`:

```sql
with a(source_system,order_id) as (values ('legacy',37)),
     b(source_system,order_id) as (values ('retail',37))
select 'literal_one_side' as variant, a.source_system a_origin,b.source_system b_origin
from a join b on a.order_id=b.order_id and b.source_system='retail';

with a(source_system,order_id) as (values ('legacy',37)),
     b(source_system,order_id) as (values ('retail',37))
select 'or_origin' as variant, a.source_system a_origin,b.source_system b_origin
from a join b on a.order_id=b.order_id or a.source_system=b.source_system;
```

```text
     variant      | a_origin | b_origin
------------------+----------+----------
 literal_one_side | legacy   | retail
(1 row)

  variant  | a_origin | b_origin
-----------+----------+----------
 or_origin | legacy   | retail
(1 row)
```

A análise lê qualificadores sintáticos, não resolve aliases ou escopos como o
PostgreSQL. Aliases de tabela usados consistentemente e nomes sem alias passaram;
coluna não qualificada no correlato testado também passou. Origem renomeada por CTE
não é reconhecida. `USING` válido passar não prova cobertura: a variante sem origem
também passa. A igualdade nula-segura da origem é válida com os mesmos dois lados,
mas não é `exp.EQ`. Igualdade na projeção não tem ancestral `Where`/`Join`: o erro
existe desde antes, e não foi apresentado como regressão introduzida pelo fix.

Li as 16 views do HEAD e não identifiquei falso positivo nem caso real de fusão de
identidades escondido por esses falsos negativos. A revisão aqui é da guarda; não
reabre as métricas do lote 3. P04 conserva origem na chave de `DISTINCT ON` e nas
junções; P09 conserva origem na partição da janela e na junção; P12 só lê `retail`
no quente e compara com `f.source_system='retail'`, premissa específica que torna seu
anti-join correto; P16 correlaciona as origens antes de abandonar a coluna e usa
`UNION ALL`. Nas demais reduções por identificador, origem acompanha a chave; joins
por chaves substitutas não exigem coluna de origem adicional. Os casos novos de
RVL2-2-02/03 são contraprovas sintéticas, não defeitos afirmados dessas views.

### D — Governança, restauração e donos documentais

Inventário inicial e final, saída literal:

```text
      rolname       | rolsuper | rolcanlogin |             rolconfig
--------------------+----------+-------------+------------------------------------
 mvp_warehouse      | t        | t           |
 consumption_reader | f        | t           | {default_transaction_read_only=on}
(2 rows)
```

O warehouse respondeu PostgreSQL **16.15**. Caminhos conferidos por leitura:
`dbt/profiles.yml:14` usa `WAREHOUSE_DB_USER`; `airbyte/main.tf:117` usa
`var.warehouse_db_user`, alimentado pelo `.env` em `Makefile:494`; captura recebe o
engine de `database_url(WAREHOUSE)` em `airbyte.py:227`; Beam usa o mesmo em
`streaming/sink.py:97`. Não há `SET ROLE` operacional nesses caminhos. Nenhum caminho
não superusuário existente que precise de `lo_open` ou advisory lock foi encontrado;
fechar `lo_open` bloqueia também a leitura via descritor, mas não quebra consumo
atual. Não rodei Airbyte, captura, dbt ou Beam para afirmar isso: código e inventário
sustentam a conclusão; não é teste de pipeline. Não consultei a configuração remota
do Airbyte, mas o cluster só tem o superusuário e o leitor como logins.

Governança §7 v2.10 corresponde ao código para os nomes de catálogo, revogação de
TEMP, LO/advisory e conexão real de leitor. A enumeração não garante fechamento de
toda função que escreve/interfere: RVL2-2-01 e RVL2-2-05 delimitam a conclusão.
A necessidade de declarar permissões quando os componentes ganharem logins próprios
está corretamente atribuída ao futuro; não foi criado grant operacional nesta revisão.

A frase de restauração está correta para a sequência completa em cluster novo.
`_pg_dump` usa `-n` nos schemas `raw_legacy`, `governance`, `snapshots`, `quarantine`;
o restore chama apenas `garantir_papeis` antes de `pg_restore`. Os papéis de grupo
não incluem o leitor. Comando de inspeção `nl -ba Makefile | sed -n '699,706p'`:

```text
   703        @$(MAKE) --no-print-directory sync-legacy JOB_EM="$(RECOVERY_JOB)"
   704        @$(MAKE) --no-print-directory dbt-rebuild
   705        @$(MAKE) --no-print-directory check
```

`dbt-rebuild` garante as chaves do leitor no ambiente e chama `governance garantir`
antes do build. A linha 704 está correta no HEAD. Num cluster já existente, login e
ACLs podem continuar presentes; o parágrafo fala explicitamente de cluster novo.
Não executei esses alvos, não restaurei cluster nem fiz novo dump; a evidência do TOC
na rodada 1 permanece como evidência anterior.

RVL2-05 não pede reescrita de mensagem de commit nem ADR aceito. Busca com expressão
`\b11\s*(?:→|->)\s*12\b` sobre arquivos rastreados de `docs/`, README e `dbt/`:

```text
documentos_com_11_para_12= []
```

A medição anterior nesta revisão continua rotulada pelos dados sobre os quais foi
feita. Não a promovi a número histórico nem a repliquei na Governança. Para evidência
permanente, a entrega conserva este registro no histórico Git, como prevê a skill de
revisão; o plano da v1.1.0 mantém seu próprio critério atual de zero divergências.

Para RVL2-06, `sed -n '810,815p' docs/dicionario_de_dados.md` confirma:

```text
Toda coluna de todo modelo fecha numa origem: uma coluna de **fonte** (`raw`, `raw_legacy`,
`governance`), uma coluna de **seed** (declarada no Git) ou uma coluna **gerada** (calendário,
numeração, literal, chave técnica, contagem de linhas), que não vem do valor de coluna nenhuma.
```

O `bi-como-codigo/PLAN.md` §3.5 declara consumo por `lineage --json`, e a Parte II,
etapa 2.4, entrega os exportadores e metadados. Portanto a obrigação do consumidor
está encaminhada ao dono certo e continua **diferida**, conforme o pedido do Owner.
A busca por `generated`/`lineage` ali não encontrou regra específica que já cumpra a
obrigação. Não alterei esse projeto nem declarei consumidor real validado.

### E — regressões, estado final e limites

`make check-offline`, no HEAD `15ab79d`, exit 0. Saída literal sem o progresso em pontos
nem a repetição do inventário dos 185 testes desmarcados:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
761 passed, 185 deselected in 151.13s (0:02:31)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram
```

Nenhum skip nesse gate. `make secrets-history`, exit 0, última linha literal:

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os 547 testes/seis skips da rodada 1 eram de outro snapshot sem manifest; os 749 eram
outro HEAD. O resultado atual não substitui o `make check` do autor em `00ce350`
(`PASS=907`, `943 passed`, `3 skipped`), que não reproduzi. Dos testes de integração,
executei apenas o arquivo de acesso autorizado; o restante ficou fora desta rodada.

Comparação do inventário antes/depois:

```bash
diff -u /tmp/rvl2-round2-inventory-before.log /tmp/rvl2-round2-inventory-after.log
```

Saída vazia, exit 0. Em ambos, `large_objects=0`, `probe_objects=0`, `probe_roles=0`,
`advisory_locks=0`; mesmos privilégios inventariados, mesmos atributos/configurações
dos logins e somente a sessão do próprio `ro.sh` no inventário de conexões. Não se
comparou byte a byte o verificador SCRAM renovado pelo teste nem contadores internos.

As primeiras tentativas de Docker/TCP foram bloqueadas pelo sandbox e repetidas com
escalonamento autorizado. Superusuário foi usado pelo `ro.sh` e, excepcionalmente,
pelo próprio `tests/test_acesso.py` autorizado. Nenhum build, reset, seed, sync,
restauração, ledger ou comando de DAG foi executado; `data/memoria_do_legado/` ficou
intocado. Só `REVISAO.md` foi editado entre os arquivos versionados; scripts/logs da
revisão ficaram em `/tmp`. Os não rastreados `GEMINI.md` e
`NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam. Nenhum commit ou push.

Não houve fixture de LO de outro dono, teste de banco com nome hostil, decoder lógico,
concorrência com DDL real, indisponibilidade durante cleanup, pipeline operacional ou
restauração nova. Não afirmo completude absoluta da superfície de funções do PostgreSQL:
o caminho concreto ainda aberto basta para impedir o encerramento do contrato de
leitor nesta rodada. **Lote 2 permanece aberto para RVL2-2-01 a RVL2-2-03.**


## Rodada 3 — lote 2

Revisão em **05/11/2026**, no HEAD `d7df2cdb6fcced899e2e990a72cd428a82b2b38f`,
restrita a `git log 15ab79d..d7df2cd`: `33a4187`, `2002adc`, `e4351d4` e
`d7df2cd`. Parecer técnico, sem poder de aprovação e sem implementar correções.
**O lote 2 permanece aberto:** o fechamento das duas assinaturas de mensagem no WAL
foi confirmado, mas há cinco ajustes na entrega e duas observações preexistentes.
Nos blocos de saída, foram retirados apenas espaços de fim de linha.
Não encontrei novo caminho de escrita de dados do armazém pelo leitor nas sondas
executadas; isso não transforma o inventário de nomes em prova universal de segurança.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-3-01 | `tests/test_acesso.py:411`, `:470–483` | A primeira sonda pede slot físico **persistente** (`temporary=false`). Se apenas a criação perder a checagem, o rollback e o fechamento da conexão não apagam o slot; o `drop` subsequente continua recusado. Não há limpeza em `finally`, e `assert aceitas == []` falha antes da asserção final sobre o slot. Tampouco há verificação final de `__probe_do_leitor_b`. Simulação do próprio teste: `AssertionError`, slot sobrevivente, zero SQL real. Proposta: tornar os recursos de sonda descartáveis e garantir limpeza em todos os caminhos de falha, sem depender da mesma permissão cuja ausência está sendo testada. Evidência B. | `ajuste` | **Corrigido.** Todo slot pedido pela sonda é temporário (`pg_create_physical_replication_slot(…, false, true)`, cópia com `temporary=true`) e some com a sessão do leitor; e a limpeza foi para um `finally`, feita pelo superusuário — não pela permissão em teste —, apagando qualquer `__probe_do_leitor*` (inclusive `_b`) antes das asserções, que conferem `aceitas == []` e `sobras == []`. |
| RVL2-3-02 | `tests/test_identidade_no_consumo.py:118–142` | **Regressão:** `_origem_fixa_por_fonte` busca o qualificador na árvore inteira. Uma CTE não relacionada contendo `retail.orders x` e `retail.order_items y` faz o join externo `a x join b y on x.order_id=y.order_id` passar sem origem: base `1`, HEAD `0`. O limite “não resolve escopo” descreve a causa, mas não justifica inferir origem de outra relação e enfraquecer uma recusa existente. Proposta: vincular a fonte ao lado efetivo da igualdade; quando não resolver, não conceder a exceção de fonte única. Preservar P12. Evidência C. | `ajuste` | **Corrigido.** `_relacao_do_lado` resolve o qualificador no `from`/`join` do `select` mais próximo que o declara, subindo pelas subconsultas correlatas, e para em fronteira de CTE: CTE vizinha não empresta origem, nem a CTE vê a consulta de fora. Contraprova com a guarda de `d7df2cd` em memória: `shadow_both`, `shadow_source` e `shadow_source_cte` 0 → 1; P12 continua 0; 16 views `[]`. |
| RVL2-3-03 | `tests/test_identidade_no_consumo.py:213–219`; docstring | O novo ramo de `IN` só lê `pertence.this`. Aceita `(source_system,order_id) in (select 'retail',order_id from b)` e `(a.source_system,a.order_id) in (select a.source_system,b.order_id from b)`, mesmo quando `b` é `legacy`. Ambos retornam linha no PostgreSQL e `[]` na guarda. A implementação nova não cumpre sua declaração de origem restringindo **os dois lados**. Proposta: verificar a correspondência dos elementos e a procedência em ambos os lados, inclusive `NOT IN`, ou limitar explicitamente a cobertura sem chamar estes casos de validados. Evidência C. | `ajuste` | **Corrigido.** `_pertence_correlaciona`: a origem de fora casa, **na mesma posição**, com a coluna de origem da subconsulta, cujo qualificador é dela (ou vazio), e a de fora não é da subconsulta. Literal à direita, coluna de fora repetida dentro, posições trocadas e `not in` trocado acusam (0 → 1 cada); a forma correlata válida passa. |
| RVL2-3-04 | `tests/test_identidade_no_consumo.py:136` | **Regressão de falso positivo:** join com `a.source_system='retail'::text` e `b.source_system='retail'` restringe ambas as origens, mas passa de `0` na base a `1` no HEAD. Só `exp.Literal` direto é reconhecido. Proposta: reconhecer o cast de texto comprovadamente inócuo ou declarar expressamente esse limite, como foi feito com alias de CTE em RVL2-2-03. Não remover casts indiscriminadamente. Evidência C. | `ajuste` | **Corrigido.** `_texto_literal` aceita o *cast* para `text` ou `varchar` **sem parâmetro**; `varchar(3)` truncaria e continua não contando (caso de teste). `cast_one` 1 → 0 e `cast_literals` 1 → 0. |
| RVL2-3-05 | `tests/test_acesso.py:343–350`, `:430–455`; Governança §7 v2.11 | A promessa “uma função nova numa versão do PostgreSQL falha o teste” excede a implementação: compara **nomes**, exclui tipos e só cobre `VOLATILE`; nova sobrecarga de nome existente não altera o conjunto. E a classe “leitura ou efeito na própria sessão” inclui `query_to_xml`/`ts_stat`, que executaram `pg_notify` dentro do SELECT, com o privilégio do chamador. `pg_export_snapshot` também cria arquivo transitório; `pg_current_xact_id`/`txid_current` são STABLE e alocam XID. Nenhum desses exemplos demonstrou escalada ou escrita de dado de negócio, mas impedem tratar a classificação como prova de ausência de qualquer efeito. Proposta: delimitar a promessa ao recorte efetivamente conferido e explicitar os executores de SQL e efeitos internos; se a intenção é detectar toda assinatura nova, inventariar assinaturas. Evidência A. | `ajuste` | **Corrigido na promessa e na classificação.** O recorte está declarado no comentário de `ABERTAS_AO_LEITOR`, em `governance.py` e na Governança §7 v2.12: por nome (sobrecarga nova de nome classificado passa), só voláteis (`txid_current`/`pg_current_xact_id` são estáveis e alocam XID), e o motivo diz por que fica aberta, não que não tenha efeito. `query_to_xml*`, `cursor_to_xml*`, `ts_stat` e `ts_rewrite` foram para a classe própria "executam SQL de quem chama" (alcançam o que o leitor alcança direto, inclusive `pg_notify`); `pg_export_snapshot` para "efeito interno, sem dado". Não passei a inventariar assinaturas: o objetivo do oráculo é pegar a família nova, e a sobrecarga de um nome já classificado herda o motivo dele — isso fica declarado como limite, não prometido. |
| RVL2-3-06 | `tests/test_identidade_no_consumo.py:195–202` | **Preexistente, fora da correção efetivamente demonstrada:** igualdade na projeção de uma subconsulta usada em `JOIN … USING` ainda encontra o `Join` externo, cujo `on` é `None`, e quebra com `AttributeError`. O caso de projeção simples de RVL2-2-04 foi fechado; “ignora igualdade na projeção” não vale para todos os escopos. Comparação: `AttributeError` antes e agora. Evidência C. | `observação` | **Corrigido**, embora preexistente: a cláusula mais próxima é procurada entre `where`, `join` **e `select`** — se o `select` vem antes, a igualdade está numa projeção, em qualquer nível, e não junta; `join … using` sem `on` também não quebra mais. `using_subquery_eq`: `AttributeError` → 0. |
| RVL2-3-07 | `src/mvp_ed1/governance.py:233` (preexistente); alcance da frase nova da Governança §7 | A reposição vale para o padrão **global do papel**. O próprio leitor também consegue `ALTER ROLE … IN DATABASE warehouse_db SET default_transaction_read_only=off`; o `ALTER ROLE … SET …=on` usado por `_garantir_leitor` não remove essa configuração, que tem precedência. Sonda revertida deixou visíveis simultaneamente `database=off` e `global=on`. A frase é correta para o comando global que cita, mas não deve ser estendida a qualquer forma de retirar o padrão. Não é escalada: a garantia continua sendo ACL. Evidência D. | `observação` | **Corrigido**, não só declarado: `_garantir_leitor` agora faz `alter role … in database … reset all` para todo banco em que o leitor tenha padrão (laço com `format('%I')` no servidor) e `alter role … reset all` no global, e só então repõe `default_transaction_read_only = on`. Teste real `test_padrao_que_o_leitor_tira_de_si_volta_no_garantir`: o leitor grava, com *commit*, `in database … set default_transaction_read_only = off` e `statement_timeout = '1h'` global; nova sessão dele mostra `off`; depois do `garantir()`, `on`, `statement_timeout` `0`, e `pg_db_role_setting` só com `(*, {default_transaction_read_only=on})`; `finally` repõe como superusuário. Contraprova com `governance.py` de `d7df2cd` em memória: `assert 'off' == 'on'`; o estado ficou reposto. A frase da Governança §7 v2.12 cobre as duas formas. |

### Fechamento de cada resposta da rodada 2

“Fechado” abaixo é conclusão do revisor sobre o achado, não aceite do Owner.

| Achado anterior | Conclusão desta rodada | Comando e saída que a sustentam |
|---|---|---|
| RVL2-2-01 | **Fechado quanto ao defeito original:** as duas assinaturas de `pg_logical_emit_message` estão revogadas e recusadas. A resposta acrescentou testes e promessa de cobertura que exigem os ajustes RVL2-3-01/05. | Bateria A: `.venv/bin/python /tmp/rvl2-round2-reader.py`, no ambiente carregado, devolveu `42501 permission denied for function pg_logical_emit_message` nas duas chamadas com `true`. Inventário por `ro.sh`: `reader_exec=f`, `public_exec=f` nas duas assinaturas. Suíte direcionada: `72 passed in 4.89s`. |
| RVL2-2-02 | **Parcialmente fechado.** Literal só de um lado, literal de terceiro, `OR` e `NOT` agora acusam. A exceção de fonte única ainda pode aceitar origem de outro escopo e introduziu a regressão RVL2-3-02. | `.venv/bin/python /tmp/rvl2-round2-identity.py`: os quatro casos dão uma violação cada. `.venv/bin/python /tmp/rvl2-round3-compare.py`: `shadow_both antes=1 agora=0`; P12 continua `0`. |
| RVL2-2-03 | **Fechado nos dois pontos pedidos.** Igualdade nula-segura válida passa; alias de origem em CTE continua acusado e está declarado como limite. O cast de RVL2-3-04 é outro caso. | Matriz C: `nullsafe_valid … => []`; `cte_alias … => ['junção sem a origem: …']`. `sed -n '33,42p' tests/test_identidade_no_consumo.py` contém a declaração expressa de que origem renomeada não é reconhecida. |
| RVL2-2-04 | **Fechado nos exemplos originais, parcialmente fechado na generalização da resposta.** `USING`, `IN` simples e igualdade nula-segura de identificadores sem origem acusam; projeção simples não quebra. Restam a cobertura unilateral de `IN` adicionada agora (RVL2-3-03) e a projeção aninhada preexistente (RVL2-3-06). | Matriz C: `using_bad`, `nullsafe_bad` e `in_bad` dão uma violação; `select_equality => []`. Matriz adicional: `in_literal_right => []`, `in_wrong_alias => []`, `using_subquery_eq => AttributeError`. |
| RVL2-2-05 | **Fechado quanto à delimitação solicitada.** §7 documenta `NOTIFY`/`LISTEN`, timeouts, sinais ao próprio login e lock de leitura; a bateria confirma essas permissões. A reposição global está no código; não medi um ciclo de alteração persistida seguido de `garantir()`. RVL2-3-05/07 explicitam limites adicionais. | Bateria A: `pg_notify => [('',)]`, `listen => OK`, timeouts `1h`/`0`, ambos os sinais ao leitor `True`, `ACCESS SHARE => OK`, `alter role … set …=off => OK`, todos em transações revertidas. `src/mvp_ed1/governance.py:233`: `alter role {usuario} set default_transaction_read_only = on`. |

### A — leitor real, oráculo e funções excluídas

Ambiente PostgreSQL **16.15**, confirmado por `ro.sh`. A bateria da rodada 2 foi
reexecutada **sem alterar seu script**, contra o HEAD atual:

```bash
set -a; . ./.env; set +a
.venv/bin/python /tmp/rvl2-round2-reader.py
```

O script conecta como `WAREHOUSE_READER_USER`, pede `SET TRANSACTION READ WRITE`,
executa cada sonda e faz `rollback()` em `finally`; os sinais só alcançam duas
conexões descartáveis do próprio leitor. Não houve chamada de
`pg_logical_emit_message` com `transactional=false`. Saída literal:

```text
show default_transaction_read_only => [('on',)]
select count(*) from consumption.monthly_revenue_by_channel_and_category => [(1494,)]
create table public.__rvl2(x int) => 42501 permission denied for schema public
create table consumption.__rvl2(x int) => 42501 permission denied for schema consumption
create temp table __rvl2(x int) => 42501 permission denied to create temporary tables in database "warehouse_db"
create schema __rvl2 => 42501 permission denied for database warehouse_db
create function public.__rvl2() returns int language sql as $$select 1$$ => 42501 permission denied for schema public
create sequence public.__rvl2 => 42501 permission denied for schema public
insert into raw.orders select * from raw.orders where false => 42501 permission denied for schema raw
delete from consumption.monthly_revenue_by_channel_and_category where false => 55000 cannot delete from view "monthly_revenue_by_channel_and_category"
set role analyst => OK
set role transformer => 42501 permission denied to set role "transformer"
set role mvp_warehouse => 42501 permission denied to set role "mvp_warehouse"
set session authorization mvp_warehouse => 42501 permission denied to set session authorization "mvp_warehouse"
alter role consumption_reader createrole => 42501 permission denied to alter role
alter role consumption_reader set default_transaction_read_only=off => OK
grant analyst to auditor => 42501 permission denied to grant role "analyst"
create role __rvl2 => 42501 permission denied to create role
copy (select 1) to program 'true' => 42501 permission denied to COPY to or from an external program
select lo_create(0) => 42501 permission denied for function lo_create
select lo_creat(-1) => 42501 permission denied for function lo_creat
select lo_from_bytea(0,decode('4142','hex')) => 42501 permission denied for function lo_from_bytea
select lo_open(0,262144) => 42501 permission denied for function lo_open
select lo_put(0,0,decode('41','hex')) => 42501 permission denied for function lo_put
select lowrite(0,decode('41','hex')) => 42501 permission denied for function lowrite
select lo_truncate(0,0) => 42501 permission denied for function lo_truncate
select lo_truncate64(0,0) => 42501 permission denied for function lo_truncate64
select lo_unlink(0) => 42501 permission denied for function lo_unlink
select lo_get(0) => 42704 large object 0 does not exist
select lo_get(0,0,1) => 42704 large object 0 does not exist
select loread(0,1) => 42704 invalid large-object descriptor: 0
select lo_import('/__rvl2_missing__') => 42501 permission denied for function lo_import
select lo_export(0,'/__rvl2_missing__') => 42501 permission denied for function lo_export
select pg_notify('__rvl2_round2','probe aborted') => [('',)]
listen __rvl2_round2 => OK
select set_config('statement_timeout','1h',true) => [('1h',)]
select set_config('lock_timeout','0',true) => [('0',)]
select set_config('session_replication_role','replica',true) => 42501 permission denied to set parameter "session_replication_role"
select set_config('role','transformer',true) => 42501 permission denied to set role "transformer"
select nextval('raw.inventory_movements_stream_event_sequence_seq') => 42501 permission denied for schema raw
lock table consumption.monthly_revenue_by_channel_and_category in access share mode => OK
lock table consumption.monthly_revenue_by_channel_and_category in access exclusive mode => 42501 permission denied for view monthly_revenue_by_channel_and_category
select pg_logical_emit_message(true,'__rvl2_round2','aborted probe') => 42501 permission denied for function pg_logical_emit_message
select pg_logical_emit_message(true,'__rvl2_round2',decode('41','hex')) => 42501 permission denied for function pg_logical_emit_message
select pg_advisory_lock(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_lock
select pg_advisory_lock(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_lock
select pg_advisory_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_lock_shared
select pg_advisory_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_lock_shared
select pg_advisory_xact_lock(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_xact_lock
select pg_advisory_xact_lock(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_xact_lock
select pg_advisory_xact_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_advisory_xact_lock_shared
select pg_advisory_xact_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_advisory_xact_lock_shared
select pg_try_advisory_lock(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_lock
select pg_try_advisory_lock(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_lock
select pg_try_advisory_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_lock_shared
select pg_try_advisory_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_lock_shared
select pg_try_advisory_xact_lock(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_xact_lock
select pg_try_advisory_xact_lock(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_xact_lock
select pg_try_advisory_xact_lock_shared(1907766123456789::bigint) => 42501 permission denied for function pg_try_advisory_xact_lock_shared
select pg_try_advisory_xact_lock_shared(1907766::int,123456::int) => 42501 permission denied for function pg_try_advisory_xact_lock_shared
select pg_cancel_backend(148501) => [(True,)]
select pg_terminate_backend(148502) => [(True,)]
sqlalchemy_format => ('revoke "x""; --" from consumption_reader', 'revoke execute on function lo_create(oid) from public')
Todas as transações revertidas; conexões fechadas.
```

O `55000` no DELETE é recusa pela forma da view, **não** prova de ACL. O inventário
independente encontrou zero relações de aplicação com privilégio de escrita do leitor.

Inventário completo em `/tmp/rvl2-round3-catalog.sql`, executado com
`ENG_DADOS_DIR="$PWD" /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh`.
Consulta a `pg_proc`, agrupada por `prokind, provolatile`, sem o filtro do oráculo:

```text
                                         version
------------------------------------------------------------------------------------------
 PostgreSQL 16.15 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
(1 row)

 prokind | provolatile | count
---------+-------------+-------
 a       | i           |   149
 a       | s           |     8
 f       | i           |  2222
 f       | s           |   633
 f       | v           |   259
 w       | i           |    15
(6 rows)
```

São 157 agregados (`149 i + 8 s`) e 15 funções de janela, nenhum procedimento.
Revisei o inventário das STABLE/IMMUTABLE e dos agregados; não identifiquei entre os
built-ins instalados outra função que permita ao leitor gravar dados ou tomar o
advisory lock da captura. Isso é resultado desta inspeção, não prova automática
para versões/extensões futuras. `_CHAMAVEIS` não filtra `prokind`: um procedimento
volátil futuro de nome novo seria visto, mas os agregados atuais ficam fora por
volatilidade. O inventário também deu **zero funções fora de pg_catalog e
information_schema**, independentemente de volatilidade.

**O recorte por volatilidade não significa ausência de efeitos internos.**
`pg_current_xact_id()` e `txid_current()` são STABLE, executáveis e alocaram XID.
O PostgreSQL trata a volatilidade como contrato com o otimizador, não como ACL;
funções C controlam seu próprio comportamento. Não apresento a alocação de XID,
o arquivo de snapshot ou a atualização de estatísticas como bypass da revogação
de mensagem lógica no WAL. São limites da leitura literal de “não escreve”.
Fontes: [volatilidade no PG16](https://www.postgresql.org/docs/16/xfunc-volatility.html)
e [implementação dos XIDs](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/xid8funcs.c).

**Exclusões por tipo.** O inventário encontrou 29 entradas voláteis executáveis
excluídas por `internal`/retorno especial: gatilhos de integridade e atualização de
tsvector, handlers de linguagens/métodos de acesso/amostragem e Snowball. Não
identifiquei chamada SQL direta que executasse efeito útil fora de seu contexto.
O literal `NULL` não permite fabricar `internal`; gatilhos validam o contexto de
chamada. `plpgsql_call_handler()` chega à validação e falha — portanto “não se
chamam de SQL” é uma abreviação, não descrição literal do parser. Sondas seguras:

```text
select pg_typeof(pg_catalog.bthandler(null::internal)) => 42846 cannot cast type unknown to internal
select pg_catalog.bthandler(null::internal) is not null => 42846 cannot cast type unknown to internal
select pg_catalog.heap_tableam_handler(null::internal) is not null => 42846 cannot cast type unknown to internal
select plpgsql_call_handler() => 0A000 PL/pgSQL functions cannot return type language_handler
select "RI_FKey_cascade_del"() => 39P01 function "RI_FKey_cascade_del" was not called by trigger manager
select suppress_redundant_updates_trigger() => 39P01 suppress_redundant_updates_trigger: must be called as trigger
```

Comandos: `.venv/bin/python /tmp/rvl2-round3-safe-handlers.py` e
`.venv/bin/python /tmp/rvl2-round3-reader-extra.py`, ambiente carregado, conexão real
do leitor e rollback por sonda. Não chamei funções C com ponteiros fabricados.
A restrição de `internal` consta dos
[pseudotipos do PG16](https://www.postgresql.org/docs/16/datatype-pseudo.html).

**Classificação dos nomes.** Li os 132 nomes declarados: 78 de leitura/sessão,
10 de LO/unlock, 32 verificados pelo servidor, 9 pelo objeto e 3 de interferência.
Entre os 78, relógio/aleatoriedade, catálogo, tamanhos, estatísticas e diagnóstico
não deram evidência de escrita de dados de aplicação. Os casos que exigem precisão:

- `pg_export_snapshot`: exporta estado da transação para arquivo em `pg_snapshots`,
  retém snapshot e o remove no fim; não é só leitura de memória. Pode prolongar a
  retenção de versões, como outras transações longas. Código consultado:
  [ExportSnapshot e limpeza](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/time/snapmgr.c).
- `query_to_xml`, variantes de XML, `ts_stat` e `ts_rewrite` executam SQL/cursor em
  modo de leitura pelo SPI, com os privilégios do chamador. Isso recusa `ALTER ROLE`
  embutido, mas **não impede SELECT chamar função volátil permitida**. `pg_notify`
  passou dentro de `query_to_xml` e `ts_stat`; a mensagem lógica revogada falhou
  com `42501` em ambos. Classificá-las como executores de consulta evita confundir
  privilégio preservado com efeito limitado à sessão. Fontes:
  [XML](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/xml.c)
  e [ts_stat](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/tsvector_op.c).
- `plpgsql_validator`: valida linguagem/USAGE/EXECUTE antes de compilar; não executa
  indiscriminadamente o corpo de função fornecida. Não há funções PL/pgSQL de usuário
  neste banco. Fonte:
  [CheckFunctionValidatorAccess](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/fmgr/fmgr.c).
- `currtid2`: confere SELECT no objeto; para view depende de CTID válido e percorre
  a relação de base, também com checagem. A view sondada não expõe CTID; `raw` foi
  recusado pelo schema. Fonte:
  [currtid_internal](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/tid.c).
- `pg_stat_clear_snapshot` limpa o cache de estatísticas da sessão;
  `pg_stat_force_next_flush` solicita publicação das estatísticas do próprio backend,
  não apaga contadores alheios. O segundo tem efeito na estatística compartilhada,
  sem ser `pg_stat_reset`. Fonte:
  [pgstatfuncs](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/pgstatfuncs.c).
- `set_config` pode mudar parâmetros USERSET e tentar mudar papel; os parâmetros
  privilegiados e o papel `transformer` continuaram recusados. Não vi escalada.
- `lo_get` exige privilégio no LO; hoje há zero LOs. As demais operações de leitura,
  seek, tell e close precisam de descritor, cuja abertura está revogada. Unlock só
  solta locks da própria sessão. A ausência de LO explica o estado atual, não a
  segurança para LO futuro; esta depende de ACL. Não criei fixture de LO alheio.

Recorte literal das sondas adicionais (arquivo citado acima):

```text
select pg_current_xact_id_if_assigned() => [(None,)]
select pg_current_xact_id() => [('36272',)]
select txid_current() => [(36273,)]
select pg_export_snapshot() => [('00000003-000121CE-1',)]
select pg_stat_clear_snapshot() => [('',)]
select pg_stat_force_next_flush() => [('',)]
select query_to_xml('select 1 as n',false,false,'') => [('<table xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n\n<row>\n  <n>1</n>\n</row>\n\n</table>\n',)]
select query_to_xml($$select pg_notify('__rvl2_round3','aborted')$$,false,false,'') => [('<table xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n\n<row>\n  <pg_notify></pg_notify>\n</row>\n\n</table>\n',)]
select query_to_xml($$select pg_logical_emit_message(true,'__rvl2_round3','aborted')$$,false,false,'') => 42501 permission denied for function pg_logical_emit_message
select query_to_xml($$alter role consumption_reader set default_transaction_read_only=off; select 1$$,false,false,'') => 0A000 ALTER ROLE is not allowed in a non-volatile function
select * from ts_stat($$select to_tsvector('simple','one two')$$) => [('two', 1, 1), ('one', 1, 1)]
select * from ts_stat($$select to_tsvector('simple',pg_notify('__rvl2_round3','aborted')::text)$$) => []
select * from ts_stat($$select to_tsvector('simple',pg_logical_emit_message(true,'__rvl2_round3','aborted')::text)$$) => 42501 permission denied for function pg_logical_emit_message
select plpgsql_validator('pg_catalog.pg_notify(text,text)'::regprocedure) => 42501 language validation function 13665 called for language 12 instead of 2246
select currtid2('consumption.monthly_revenue_by_channel_and_category','(0,1)') => XX000 currtid cannot handle views with no CTID
select currtid2('raw.orders','(0,1)') => 42501 permission denied for schema raw
select nextval('consumption.monthly_revenue_by_channel_and_category'::regclass) => 42809 "monthly_revenue_by_channel_and_category" is not a sequence
select setval('consumption.monthly_revenue_by_channel_and_category'::regclass,1) => 42809 "monthly_revenue_by_channel_and_category" is not a sequence
select brin_summarize_new_values('consumption.monthly_revenue_by_channel_and_category'::regclass) => 42809 "monthly_revenue_by_channel_and_category" is not an index
select gin_clean_pending_list('consumption.monthly_revenue_by_channel_and_category'::regclass) => 42809 "monthly_revenue_by_channel_and_category" is not an index
select lo_close(0) => 42704 invalid large-object descriptor: 0
select lo_lseek(0,0,0) => 42704 invalid large-object descriptor: 0
select lo_tell(0) => 42704 invalid large-object descriptor: 0
select pg_advisory_unlock(1907766123456789::bigint) => [(False,)]
select pg_advisory_unlock_all() => [('',)]
alter role consumption_reader in database warehouse_db set default_transaction_read_only=off => OK
Todas as transações revertidas; conexões fechadas.
```

**Verificadas no objeto.** Zero sequências e zero índices BRIN/GIN são uma catraca
conservadora adequada para a ausência atual de alvos de escrita dessas funções.
Conferi também índices particionados (`relkind='I'`), além de `i`; o banco tem
somente 473 índices btree. Passar a view via `regclass` não transforma sua natureza:
`nextval`/`setval` deram `42809` e BRIN/GIN também recusaram o tipo. O código de
[sequências](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/commands/sequence.c)
confere `RELKIND_SEQUENCE`; os mantenedores de BRIN/GIN exigem tipo de índice e dono.
Esses `42809` provam recusa do tipo, não privilégio negado em sequência/índice real.
Se aparecer um desses objetos, é correto o teste parar e exigir sonda apropriada;
esta rodada não provou sua ACL futura. A ausência desses objetos tampouco promete
que toda tentativa de acesso deixará de adquirir qualquer lock interno transitório.

`ro.sh /tmp/rvl2-round3-oracle-summary.sql`, com `ENG_DADOS_DIR` apontado ao checkout:

```text
                  signature                  | provolatile | reader_exec
---------------------------------------------+-------------+-------------
 txid_current()                              | s           | t
 pg_logical_emit_message(boolean,text,text)  | v           | f
 pg_logical_emit_message(boolean,text,bytea) | v           | f
 pg_current_xact_id()                        | s           | t
(4 rows)

 procedures
------------
          0
(1 row)

 user_functions
----------------
              0
(1 row)

 sequences
-----------
         0
(1 row)

 brin_gin
----------
        0
(1 row)

 slots
-------
     0
(1 row)

 exports
---------
       0
(1 row)

 scope  |             setconfig
--------+------------------------------------
 global | {default_transaction_read_only=on}
(1 row)
```

**Precisão do oráculo:** ele confere o conjunto de 132 **nomes** no recorte declarado,
com contraprovas de famílias. Não inspeciona todos os corpos de função, não identifica
sobrecarga nova de nome classificado e não valida dinamicamente a razão atribuída a
cada assinatura. O teste passou; RVL2-3-05 pede que documentação e classificação
não prometam mais do que isso. Não foi criada função/sobrecarga para falsificar o
catálogo do armazém nesta revisão.

### B — teste de recusa e segurança da falha

**Executei `tests/test_acesso.py`**, conforme a autorização específica do Owner.
Comando exato, junto da guarda offline:

```bash
set -a; . ./.env; set +a
.venv/bin/pytest -q -rs tests/test_acesso.py tests/test_identidade_no_consumo.py
```

```text
........................................................................ [100%]
72 passed in 4.89s
```

Nenhum skip. Isso inclui as 17 sondas de `RECUSADAS_POR_DENTRO`, com os SQLSTATEs
assertados: `42501` para slots, funções administrativas e sinais; `55P02` para as
duas funções de upgrade; `0A000` para `pg_extension_config_dump` fora de script de
extensão. Esses códigos são evidência adequada das **chamadas concretas**: não se
aceitou “objeto inexistente” como permissão negada. `55P02` prova recusa pelo modo,
não por ACL; `0A000` prova contexto não suportado. A checagem por família não prova
que toda assinatura futura herda a mesma guarda. O teste do nome hostil chama
`garantir()` internamente: foi executado como parte do arquivo expressamente
autorizado; não invoquei `governance garantir` por fora da suíte.

O alvo dos sinais é uma conexão ociosa do próprio teste e fecha via contexto. Se
um sinal passasse, `aceitas` acusaria; o teste não aponta para sessão operacional.
Os dois `binary_upgrade_*` escolhidos só alterariam estado do backend descartável,
sem DDL posterior nessa conexão, se a checagem faltasse. A fonte mostra a guarda de
modo antes das atribuições:
[pg_upgrade_support.c](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/utils/adt/pg_upgrade_support.c).
Não removi checagens reais do servidor. Para funções administrativas com efeito
externo, rollback não é garantia universal: a segurança desta execução se apoiou
nas recusas efetivamente observadas.

**O slot físico é diferente.** A chamada usa `(nome, false, false)`: não reserva WAL
imediatamente, mas pede persistência. O slot lógico usa `temporary=true`. O código
[slotfuncs.c](https://raw.githubusercontent.com/postgres/postgres/REL_16_STABLE/src/backend/replication/slotfuncs.c)
escolhe `RS_PERSISTENT` para o físico; esse recurso não é eliminado por rollback.
Sem checagem só na criação, o `drop` do leitor ainda pode devolver `42501`, e uma
falha intermediária interrompe o laço antes da inspeção final. Nome fixo também
não é prova de que o recurso encontrado pertença à execução atual.

Para verificar o fluxo sem criar slot real, importei o teste e forneci engines
falsos: apenas `pg_create_physical_replication_slot` foi aceito, os demais comandos
receberam seus SQLSTATEs esperados, e o estado de slot persistente sobreviveu a
`rollback()` como no servidor. `.venv/bin/python /tmp/rvl2-round3-cleanup-sim.py`:

```text
resultado=AssertionError (esperado nesta simulação)
slots_apos_falha= ['__probe_do_leitor']
tentativas_drop= ["select pg_drop_replication_slot('__probe_do_leitor')"]
cleanup_privilegiado=nenhum; só houve o drop do leitor, simulado como 42501
SQL real executado=0
```

Esta é **simulação de falha do teste**, não medição de criação real de slot pelo
leitor. O armazém tinha zero slots antes e continuou com zero. Não forcei uma
permissão maior para produzir o problema.

### C — matriz da guarda, contraprovas e 16 views

Reexecução literal da matriz da rodada 2, importando o arquivo do HEAD:
`.venv/bin/python /tmp/rvl2-round2-identity.py`:

```text
round1_distinct 'select distinct on (order_id) source_system, order_id from f' => ['distinct on sem a origem: order_id']
round1_self 'select * from a join b on a.order_id=b.order_id and a.source_system=a.source_system' => ['junção sem a origem: a.order_id = b.order_id AND a.source_system = a.source_system']
round1_window 'select row_number() over(partition by order_id) from f' => ['janela particionada sem a origem: order_id']
literal_one_side "select * from a join b on a.order_id=b.order_id and b.source_system='retail'" => ["junção sem a origem: a.order_id = b.order_id AND b.source_system = 'retail'"]
literal_third_table "select * from a join b on a.order_id=b.order_id and exists (select 1 from c where c.source_system='retail')" => ["junção sem a origem: a.order_id = b.order_id AND EXISTS(SELECT 1 FROM c WHERE c.source_system = 'retail')"]
or_origin 'select * from a join b on a.order_id=b.order_id or a.source_system=b.source_system' => ['junção sem a origem: a.order_id = b.order_id OR a.source_system = b.source_system']
not_origin 'select * from a join b on a.order_id=b.order_id and not (a.source_system=b.source_system)' => ['junção sem a origem: a.order_id = b.order_id AND NOT (a.source_system = b.source_system)']
unqualified_valid 'select * from a where exists (select 1 from b where order_id=a.order_id and source_system=a.source_system)' => []
unqualified_self 'select * from a where exists (select 1 from b where order_id=a.order_id and source_system=source_system)' => ['junção sem a origem: order_id = a.order_id AND source_system = source_system']
aliases 'select * from a x join b y on x.order_id=y.order_id and x.source_system=y.source_system' => []
names 'select * from a join b on a.order_id=b.order_id and a.source_system=b.source_system' => []
cte_alias 'with x as (select source_system as origin, order_id from a) select * from x join b on x.order_id=b.order_id and x.origin=b.source_system' => ['junção sem a origem: x.order_id = b.order_id AND x.origin = b.source_system']
using_valid 'select * from a join b using (source_system,order_id)' => []
using_bad 'select * from a join b using (order_id)' => ['junção using sem a origem: order_id']
nullsafe_valid 'select * from a join b on a.order_id=b.order_id and a.source_system is not distinct from b.source_system' => []
nullsafe_bad 'select * from a join b on a.order_id is not distinct from b.order_id' => ['junção sem a origem: a.order_id IS NOT DISTINCT FROM b.order_id']
in_valid 'select * from a where (source_system,order_id) in (select source_system,order_id from b)' => []
in_bad 'select * from a where order_id in (select order_id from b)' => ['in (subconsulta) sem a origem: order_id']
select_equality 'select a.order_id=b.order_id from a cross join b' => []
views= 16
average_order_value_by_channel_and_segment.sql => []
cart_conversion_rate_by_channel.sql => []
discount_share_by_channel.sql => []
gross_margin_by_category.sql => []
inventory_turnover_by_sku_and_warehouse.sql => []
monthly_revenue_by_channel_and_category.sql => []
new_and_repeat_customers_by_month.sql => []
on_time_delivery_rate_by_carrier.sql => []
order_to_delivery_time_by_region.sql => []
payment_approval_rate_by_method.sql => []
refund_rate_by_reason.sql => []
repeat_purchase_rate_after_support.sql => []
revenue_by_delivery_region.sql => []
skus_below_reorder_point.sql => []
support_tickets_per_hundred_orders.sql => []
top_skus_by_revenue.sql => []
```

Matriz ampliada, mesma função `violacoes(sql)`:
`.venv/bin/python /tmp/rvl2-round3-identity-extra.py`:

```text
shadow_both 'with unrelated as (select * from retail.orders x cross join retail.order_items y) select * from a x join b y on x.order_id=y.order_id' => []
cast_one "select * from a join b on a.order_id=b.order_id and a.source_system='retail'::text and b.source_system='retail'" => ["junção sem a origem: a.order_id = b.order_id AND a.source_system = CAST('retail' AS TEXT) AND b.source_system = 'retail'"]
shadow_source "select * from a s join b f on s.order_id=f.order_id and f.source_system='retail' where exists(select 1 from retail.orders s)" => []
shadow_source_cte "with unrelated as (select * from retail.orders s) select * from a s join b f on s.order_id=f.order_id and f.source_system='retail'" => []
unqualified_one 'select * from a where exists(select 1 from b where order_id=a.order_id and source_system=a.source_system)' => []
cast_literals "select * from a join b on a.order_id=b.order_id and a.source_system='retail'::text and b.source_system='retail'::text" => ["junção sem a origem: a.order_id = b.order_id AND a.source_system = CAST('retail' AS TEXT) AND b.source_system = CAST('retail' AS TEXT)"]
outer_where "select * from a join b on a.order_id=b.order_id where a.source_system='retail' and b.source_system='retail'" => ['junção sem a origem: a.order_id = b.order_id']
using_then_on 'select * from a join b using(source_system,order_id) join c on b.order_id=c.order_id and b.source_system=c.source_system' => []
using_and_on_same 'select * from a join b using(source_system,order_id) on a.order_id=b.order_id' => ParseError Invalid expression / Unexpected token. Line 1, Col: 55.
  select * from a join b using(source_system,order_id) on a.order_id=b.order_id
in_literal_right "select * from a where (source_system,order_id) in (select 'retail',order_id from b)" => []
in_literal_left "select * from a where ('retail',order_id) in (select source_system,order_id from b)" => ['in (subconsulta) sem a origem: order_id']
in_swapped 'select * from a where (source_system,order_id) in (select order_id,source_system from b)' => []
in_wrong_alias 'select * from a where (a.source_system,a.order_id) in (select a.source_system,b.order_id from b)' => []
using_subquery_eq 'select * from a join (select order_id=other_id as flag,source_system,order_id from b) b using(source_system,order_id)' => AttributeError 'NoneType' object has no attribute 'sql'
same_alias_id 'select * from a s where exists(select 1 from b s where s.order_id=s.order_id and s.source_system=s.source_system)' => []
p12 "select * from retail.stream s where not exists(select 1 from f where f.source_system='retail' and f.movement_id=s.movement_id)" => []
```

Comparação carregando `git show 15ab79d:tests/test_identidade_no_consumo.py` em memória,
sem checkout nem edição do código: `.venv/bin/python /tmp/rvl2-round3-compare.py`:

```text
shadow_both antes=1 agora=0
cast_one antes=0 agora=1
shadow_source antes=0 agora=0
shadow_source_cte antes=0 agora=0
unqualified_one antes=0 agora=0
cast_literals antes=1 agora=1
outer_where antes=1 agora=1
using_then_on antes=0 agora=0
using_and_on_same antes=ParseError agora=ParseError
in_literal_right antes=0 agora=0
in_literal_left antes=0 agora=1
in_swapped antes=0 agora=0
in_wrong_alias antes=0 agora=0
using_subquery_eq antes=AttributeError agora=AttributeError
same_alias_id antes=0 agora=0
p12 antes=0 agora=0
```

O falso negativo `shadow_both` é regressão demonstrada (`1 → 0`), não apenas um
caso antigo que a guarda ainda não entende. A CTE pode nem ser usada; o scan global
ainda fornece as duas origens ao join externo. O SQL abaixo usa as relações físicas
`raw` onde a guarda recebe o nome lógico de fonte dbt `retail`; a CTE é não utilizada:

```sql
with unrelated as (select * from raw.orders x cross join raw.order_items y),
a(source_system,order_id) as (values ('legacy',37)),
b(source_system,order_id) as (values ('retail',37))
select x.source_system as a_origin,y.source_system as b_origin
from a x join b y on x.order_id=y.order_id;
```

`ENG_DADOS_DIR="$PWD" …/ro.sh /tmp/rvl2-round3-shadow.sql`, saída literal:

```text
 a_origin | b_origin
----------+----------
 legacy   | retail
(1 row)
```

As outras contraprovas SQL são `VALUES`, sem tabela criada. Para `IN`, `a` contém
`('retail',37)` e `b` contém `('legacy',37)`; apliquei exatamente os predicados
`in_literal_right` e `in_wrong_alias` da matriz. Para projeção aninhada, `a` e `b`
são ambos `retail` e o SQL é válido. Comando
`ENG_DADOS_DIR="$PWD" …/ro.sh /tmp/rvl2-round3-guard-proof.sql`, saída literal:

```text
 variant | a_origin | b_origin
---------+----------+----------
 shadow  | legacy   | retail
(1 row)

     variant      | source_system | order_id
------------------+---------------+----------
 in_literal_right | retail        |       37
(1 row)

    variant     | source_system | order_id
----------------+---------------+----------
 in_wrong_alias | retail        |       37
(1 row)

     variant      | source_system | order_id | flag
------------------+---------------+----------+------
 projection_using | retail        |       37 | t
(1 row)
```

A origem não qualificada no correlato pedido passou corretamente. Reutilizar o
mesmo alias em escopos distintos também pode mascarar tautologia, caso preexistente
(`same_alias_id`); a guarda continua sem resolver vinculação de colunas.
`USING (source_system,order_id)` seguido de **outro** join com `ON` válido passou.
`USING` e `ON` no **mesmo** join são sintaxe inválida; o `ParseError` não é defeito.

O cast em apenas um literal é falso positivo novo; com casts nos dois lados a
recusa já existia. Fixar as duas origens no `WHERE` externo de um INNER JOIN também
é válido e continua acusado, coerente com o limite declarado de não acompanhar
fluxo entre cláusulas. Não extrapolo isso para OUTER JOIN. O caso `in_literal_left`
com fonte genérica não prova falso positivo: pôr literal à esquerda sem restringir
sua relação tampouco garante a identidade.

**Limite reescrito:** explica melhor escopos, alias e fluxo; é correto para alias de
CTE e `WHERE` externo. Ainda omite o cast e a exceção de projeção aninhada, e a
promessa de dois lados para `IN` não corresponde ao ramo novo. Declarar ausência de
resolução de escopo não torna segura a inferência positiva sobre fonte de outro
escopo; a regra de fonte única precisa de evidência sobre o lado em questão.

Li as 16 views integralmente, além de executar a guarda. Não encontrei nelas essas
contraprovas nem novo falso positivo/negativo concreto de identidade. P04 preserva
origem no `DISTINCT ON`, P09 na janela e no join, P16 correlaciona antes de projetar
sem origem e usa `UNION ALL`. P12 lê `source('retail','inventory_movements_stream') s`
e restringe `f.source_system='retail'` no anti-join; continua aceita pela premissa
correta de fonte única. As outras reduções por identificador conservam origem;
as chaves substitutas e agregações posteriores em grãos de negócio não exigem
origem indiscriminadamente. Não executei build nem reabri números de métricas do
lote 3.

### D — Governança §7 e reposição do padrão de leitura

A descrição das revogações de WAL corresponde ao catálogo e às chamadas reais.
O alcance de disponibilidade de RVL2-2-05 agora está explícito; as permissões que
restam foram confirmadas pela bateria A. O teste confirmou recusa dos sinais à
sessão do superusuário que ele mesmo abriu. A permissão para o papel alterar seu
padrão global também foi repetida e revertida. A documentação do
[ALTER ROLE no PG16](https://www.postgresql.org/docs/16/sql-alterrole.html)
confirma a mudança das configurações do próprio papel e a precedência das
configurações por papel/banco.

`_garantir_leitor` contém o `ALTER ROLE … SET …=on` global; `garantir(engine, leitor)`
o chama quando recebe o leitor. Logo, a afirmação de repor **esse** padrão global
é sustentada por leitura de código. Não foi medida nesta rodada a sequência de
persistir `off`, rodar `garantir` e abrir nova conexão; não a apresento como ensaio
feito. Tampouco a reposição muda retroativamente sessões já abertas.

A observação sobre `IN DATABASE` é adicional e preexistente. Como leitor, numa
única transação revertida, o script `/tmp/rvl2-round3-role-setting.py` executou:

```sql
set transaction read write;
alter role consumption_reader in database warehouse_db set default_transaction_read_only=off;
alter role consumption_reader set default_transaction_read_only=on;
select case when setdatabase=0 then 'global' else 'database' end, setconfig
from pg_db_role_setting where setrole=current_user::regrole order by 1;
rollback;
```

Saída de `.venv/bin/python /tmp/rvl2-round3-role-setting.py`:

```text
[('database', ['default_transaction_read_only=off']), ('global', ['default_transaction_read_only=on'])]
ROLLBACK; nenhuma configuração persistida
```

O segundo ALTER é o mesmo ajuste global que o código usa; **não** executei a função
`garantir()` nesse experimento. Inferência apoiada na precedência documentada: se
`database=off` fosse persistido, o ajuste global sozinho não restauraria o padrão
efetivo do próximo login nesse banco. Não persistimos essa configuração.

Nenhuma afirmação histórica de medição foi substituída por estimativa. Os `86 passed`
na resposta do autor incluem `test_leitor`, ausente da execução direcionada desta
rodada; nossos `72 passed` não contradizem aquela contagem. O novo texto do oráculo
é uma promessa de cobertura mais larga que o teste (RVL2-3-05), não uma medição que
esta revisão conseguiu confirmar em todas as assinaturas possíveis. Não medi um
consumidor real de LISTEN/NOTIFY nem auditei aplicações externas nesta rodada.

### E — gates, preservação do estado e limites

`make check-offline`, exit 0, sobre `d7df2cd`. Saída literal, sem os pontos de progresso
e sem repetir a lista de arquivos de integração desmarcados:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
780 passed, 187 deselected in 146.13s (0:02:26)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram
```

`make secrets-history`, exit 0, última linha literal:

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os gates reproduziram a contagem offline do autor; nenhum skip nesse gate. Não
executei o `make check` completo, outros testes de integração ou pipeline.

Inventários anterior/posterior executados por `ro.sh` com o mesmo SQL da rodada 2:

```bash
diff -u /tmp/rvl2-round3-inventory-before.log /tmp/rvl2-round3-inventory-after.log
```

**Saída vazia, exit 0.** Mesmas ACLs inventariadas, mesmos atributos/configurações de
login; `large_objects=0`, `probe_objects=0`, `probe_roles=0`, `advisory_locks=0`;
somente a sessão do próprio `ro.sh` no inventário de conexões. O inventário adicional
mostrou `slots=0`, `exports=0` e só `global={default_transaction_read_only=on}` no
papel. Não comparei contadores internos, XIDs, WAL físico de manutenção nem o hash
SCRAM renovado pela chamada interna do teste autorizado. Preservação aqui é do
conteúdo e configuração inventariados, não de todo byte interno do PostgreSQL.

Não executei `dbt-build`, `dbt-rebuild`, comando externo de `governance garantir`,
reset, seed, sync, DAG, ledger, restauração ou troca de ambientes. Não disparei nem
pausei `fluxo_batch`; `data/memoria_do_legado/` ficou intocado. Não criei slot real,
função extra, índice ou sequência para contraprova. As sondas do leitor tiveram
rollback; efeitos de sinal foram restritos às conexões descartáveis da revisão.

Só `REVISAO.md` foi editado no trabalho do repositório. Scripts, consultas, fontes
consultadas e logs de apoio ficaram em `/tmp/rvl2-round3-*`. Os não rastreados
`GEMINI.md` e `NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam e não foram tocados.
Não houve commit nem push. A indisponibilidade durante limpeza, a criação real de
slot após remover a checagem, a ACL de LO/BRIN/GIN/sequência novos e o ciclo completo
de recuperação continuam **não medidos**.

**Conclusão técnica: o lote 2 ainda não pode ser encerrado pelos ajustes
RVL2-3-01 a RVL2-3-05.** As observações RVL2-3-06/07 não ampliam o escopo de execução.

## Rodada 4 — lote 2

Revisão em **05/11/2026**, no HEAD `36acc2d53d90d4b5c52d9f589f0162407498e777`,
restrita a `git log d7df2cd..36acc2d`: `978e371`, `0e0e6cb`, `7578379` e
`36acc2d`. Parecer técnico, sem poder de aprovação e sem implementar correções.
**O lote 2 permanece aberto:** há três ajustes na guarda. Não encontrei essas
formas nas 16 views atuais, nem defeito novo na reposição dos padrões pelo código
de produção. A ressalva sobre o estado inicial do teste novo é uma observação.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-4-01 | `tests/test_identidade_no_consumo.py:121–138` | **RVL2-3-02 parcialmente fechado.** `_fontes_diretas` não enxerga as relações de um join entre parênteses sem alias. `_relacao_do_lado` então sobe e atribui ao `s` interno a fonte `retail.orders s` externa. `parenthesized_join_shadow` continua com `[]`, embora o `s` do join possa ser `legacy`. A docstring promete resolver o escopo do lado e esse caso contradiz a promessa. Proposta: reconhecer os qualificadores visíveis do grupo de joins, respeitando aliases que os ocultem; quando não resolver, não conceder a exceção de fonte única. Evidência C1. | `ajuste` | **Corrigido**, de modo conservador: a exceção da fonte de origem única só vale quando o qualificador nomeia **uma relação só na consulta inteira** (`_ligacoes` conta tabelas, subconsultas e CTEs). Alias repetido — o join entre parênteses de C1, ou qualquer outro reaproveitamento — é escopo que a guarda não resolve, e ela não concede a exceção. `parenthesized_join_shadow` 0 → 1; P12 continua 0 (`s` é ligado uma vez só). |
| RVL2-4-02 | `tests/test_identidade_no_consumo.py:182–197` | **RVL2-3-03 parcialmente fechado.** A condição `not direita.table` aceita como própria toda origem não qualificada. Quando a relação interna não tem `source_system`, o PostgreSQL resolve essa coluna no lado externo: a mesma contraprova de origem externa repetida ainda passa, agora sem qualificador. Também basta que a origem venha de qualquer relação interna, mesmo que o identificador venha de outra, sem correlação entre elas. Proposta: comprovar a procedência da origem e seu vínculo ao identificador em ambos os lados, ou recusar conservadoramente o que não consegue resolver; não chamar esses casos de correlacionados. Evidência C2. | `ajuste` | **Corrigido.** `_pertence_correlaciona` aceita uma forma só: os de dentro, origem e identificadores, **todos qualificados por uma única relação** declarada no `from` da própria subconsulta. Origem sem qualificador dentro, origem de uma relação com identificador de outra, e subconsulta sem `from` acusam (0 → 1 cada). Consequência deliberada: `(source_system, order_id) in (select source_system, order_id from b)`, que a rodada 2 aceitava, agora acusa — é exatamente a forma que a guarda não consegue provar; o caso qualificado passa. |
| RVL2-4-03 | `tests/test_identidade_no_consumo.py:186–196`; docstring | **Regressão de falso positivo.** A guarda recusa identidade completa em `a x … IN (SELECT x.source_system,x.order_id FROM b x)`: compara o nome do alias externo com os aliases internos, embora sejam escopos diferentes. Tuplas aninhadas completas e `SELECT *` com as duas colunas também passam de `[]` a uma acusação. Proposta: resolver cada referência em seu escopo; reconhecer as formas seguras ou declarar expressamente as formas não suportadas, sobretudo a expansão de `*`, sem prometer cobertura geral de `IN`. Evidência C3. | `ajuste` | **Declarado** como forma não suportada, não reconhecido: alias igual nos dois escopos, tupla aninhada e `select *` acusam, com caso de teste cada e com o motivo no docstring de `_pertence_correlaciona`; aliases distintos com alias de coluna passam. O docstring do módulo agora fixa o princípio que fecha esta série de rodadas: **a guarda aceita o que consegue provar e acusa o resto** — falso positivo custa reescrever a view na forma reconhecida, falso negativo é o pedido 37 fundido. Nenhuma das 16 views usa `in (select …)`. |
| RVL2-4-04 | `tests/test_acesso.py:510–543` | O `finally` novo recompõe o **estado canônico**, não o estado anterior. Com `garantir()` lançando erro, a simulação preserva a configuração canônica, mas apaga um `statement_timeout=5s` preexistente. Nenhuma configuração anterior é capturada; no sucesso, `garantir()` também remove padrões em outros bancos. O warehouse observado está canônico, portanto não houve perda real nesta rodada. Proposta: explicitar essa pré-condição do teste ou preservar o inventário anterior se ele precisar ser executável sobre estado arbitrário. Evidência A. | `observação` | **Declarado** no docstring do teste como pré-condição: o leitor no estado canônico, o que todo `dbt-build` deixa; o `finally` repõe esse estado, não o anterior, e um padrão posto à mão no leitor se perderia no `garantir()` seguinte de qualquer modo, porque ele apaga o não declarado. Não passei a capturar o inventário anterior: preservar estado fora da declaração contraria o próprio `garantir()`. |

### Fechamento de cada resposta da rodada 3

“Fechado” é conclusão técnica sobre o achado, não aceite do Owner. Os comandos
abaixo rodaram neste HEAD; os scripts de apoio estão em `/tmp/rvl2-round4-*`.

| Achado anterior | Conclusão desta rodada | Comando e saída que a sustentam |
|---|---|---|
| RVL2-3-01 | **Fechado quanto ao vazamento original.** Os slots pedidos são temporários; `NullPool` fecha a conexão física antes do `finally`; a limpeza privilegiada alcança também `_b`. A falha da própria limpeza tem o limite descrito em B. | `.venv/bin/python /tmp/rvl2-round4-reader.py`, com `.env` carregado: as seis sondas de slot retornaram `42501 permission denied to use replication slots`. `.venv/bin/python /tmp/rvl2-round4-cleanup-sim.py`: `temporario erro= AssertionError  slots= [] cleanup= []`; sobra inativa `_b` removida. Sem criação real de slot. |
| RVL2-3-02 | **Parcialmente fechado.** Fechados os três exemplos originais de origem emprestada por CTE/subconsulta vizinha; resta RVL2-4-01 na resolução introduzida para corrigi-los. | `.venv/bin/python /tmp/rvl2-round3-identity-extra.py`: `shadow_both`, `shadow_source`, `shadow_source_cte` dão uma acusação cada; `p12 => []`. `.venv/bin/python /tmp/rvl2-round4-matrix.py`: `parenthesized_join_shadow`, base e HEAD `[]`. |
| RVL2-3-03 | **Parcialmente fechado.** Literal à direita, origem externa qualificada e posições trocadas agora acusam. A prova de procedência ainda é insuficiente; há também falsos positivos novos (RVL2-4-02/03). | Mesma matriz anterior: `in_literal_right`, `in_wrong_alias`, `in_swapped` dão uma acusação. Matriz nova: `in_unqualified_correlated` e `in_wrong_table_origin`, base e HEAD `[]`; `in_shadow_alias_valid`, base `[]`, HEAD `['in (subconsulta) sem a origem: order_id']`. PostgreSQL confirma os casos em C. |
| RVL2-3-04 | **Fechado.** `text` e `varchar` sem comprimento são reconhecidos; não há retirada indiscriminada de cast. | `.venv/bin/python /tmp/rvl2-round3-identity-extra.py`: `cast_one => []`, `cast_literals => []`. Matriz nova: `varchar_unbounded`, base uma acusação, HEAD `[]`; `varchar_length`, uma acusação nas duas versões. |
| RVL2-3-05 | **Fechado no recorte e na classificação declarados.** Os três textos delimitam nomes voláteis; os executores de SQL e o snapshot foram separados. Não surgiu classe nova incorretamente rotulada no exame feito. | `git diff d7df2cd 36acc2d -- tests/test_acesso.py src/mvp_ed1/governance.py docs/governanca_de_dados.md`; oráculo consultado via `ro.sh` por `.venv/bin/python /tmp/rvl2-round4-oracle.py`: `nomes_catalogo= 132 classificados= 132 fora_catalogo= 0`, diferenças vazias. Evidência D. |
| RVL2-3-06 | **Fechado.** A projeção aninhada não busca mais o `JOIN`/`WHERE` externo; o `USING` continua sendo conferido separadamente. | `.venv/bin/python /tmp/rvl2-round3-identity-extra.py`: `using_subquery_eq => []`, sem `AttributeError`. Matriz nova: `projection_subquery_where`, base uma acusação, HEAD `[]`. Suíte de identidade/leitor: `83 passed in 0.34s`. |
| RVL2-3-07 | **Fechado por inspeção do código e das regras do PG16**, com a ressalva de teste RVL2-4-04. Não repeti o ciclo real que persiste configuração e chama `garantir()`. O laço cobre todo padrão vinculado ao papel, por banco; depois limpa o global e repõe leitura. | `.venv/bin/python /tmp/rvl2-round4-loop.py`: comandos 2/3/4 são o laço com `%I`, `alter role consumption_reader reset all` e `alter role consumption_reader set default_transaction_read_only = on`, nessa ordem, em dublê. Inventário por `ro.sh`: só `global={default_transaction_read_only=on}`. Sonda revertida do leitor confirma que o ajuste por banco continua possível; simulação de falha confirma a recomposição canônica pelo `finally`. Evidência A. |

### A — reposição dos padrões, precedência e teste de falha

O laço de `_garantir_leitor` consulta `pg_db_role_setting` filtrando o OID do
papel já criado. O join com `pg_database` seleciona os ajustes por banco; a linha
global, cujo `setdatabase=0`, fica para o `RESET ALL` seguinte. O par papel/banco
é único no catálogo. Excluir essas configurações durante a iteração do resultado
não exige conexão a cada banco. Ambos os identificadores da DDL dinâmica passam
por `format('%I')`; o nome interpolado em `'{usuario}'::regrole` vem da validação
restritiva existente. Não encontrei interpolação nova de nome de banco no laço.

`RESET ALL` remove também `search_path`, timeouts, fuso e outros padrões que
alguém tenha colocado **nesse papel**. Isso corresponde à declaração nova de
“nenhum outro padrão” e ao comportamento documentado na §7; não encontrei padrão
adicional que o contrato do leitor mande preservar. Não remove atributos,
privilégios ou configurações de outros papéis. A chamada de produção permanece
na transação de `garantir()`, de modo que uma exceção desfaz suas alterações.

Comando `.venv/bin/python /tmp/rvl2-round4-loop.py`, executando a função real com
conexão dublê e sem enviar DDL, saída relevante literal:

```text
comando 2 : do $$
        declare r record;
        begin
            for r in select d.datname from pg_db_role_setting s join pg_database d on d.oid = s.setdatabase
                     where s.setrole = 'consumption_reader'::regrole loop
                execute format('alter role %I in database %I reset all', 'consumption_reader', r.datname);
            end loop;
        end
        $$
comando 3 : alter role consumption_reader reset all
comando 4 : alter role consumption_reader set default_transaction_read_only = on
SQL real executado=0
```

O [ALTER ROLE do PG16](https://www.postgresql.org/docs/16/sql-alterrole.html)
distingue ajustes globais do papel e ajustes por papel/banco. `ALTER ROLE ALL IN
DATABASE` equivale ao padrão do banco: permanece fora desse laço, mas tem
precedência **menor** que o `on` global do leitor. A ordem papel+banco, papel,
banco e global está em
[`process_settings` do PG16](https://github.com/postgres/postgres/blob/REL_16_STABLE/src/backend/utils/init/postinit.c#L1230).
O inventário completo de `pg_db_role_setting` nesta rodada tinha uma única linha:

```text
        role        | database |             setconfig
--------------------+----------+------------------------------------
 consumption_reader | *        | {default_transaction_read_only=on}
(1 row)
```

Já `options` da conexão e `PGOPTIONS` podem sobrepor o padrão no login. Isso não
é outro ajuste persistente **do papel** que o laço esqueceu; é opção da sessão,
compatível com a afirmação já documentada de que leitura é conveniência e ACL é
a garantia. [PGOPTIONS](https://www.postgresql.org/docs/16/libpq-envars.html)
corresponde ao parâmetro
[`options`](https://www.postgresql.org/docs/16/libpq-connect.html#LIBPQ-CONNECT-OPTIONS).
As opções de [`pg_hba.conf`](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html)
são de autenticação; ele não fornece um campo genérico para esses GUCs de sessão.
Não alterei HBA, configurações do banco nem configuração global do servidor.

Sonda real, com `.env` carregado sem imprimir credenciais:

```bash
.venv/bin/python /tmp/rvl2-round4-reader.py
```

Saída literal das três conexões descartáveis e da alteração **revertida**:

```text
normal ('on', 'on')
options ('off', 'off')
PGOPTIONS ('off', 'off')
ajustes na transacao [(False, ['default_transaction_read_only=off']), (True, ['default_transaction_read_only=on', 'statement_timeout=1h'])]
ROLLBACK; nenhuma configuracao persistida
```

As duas colunas das primeiras linhas são `default_transaction_read_only` e
`transaction_read_only`. Nenhuma dessas conexões gravou configuração ou dado.

**Não executei a suíte `tests/test_acesso.py` contra o banco nesta rodada.** Em
particular, o teste novo faz `commit` como leitor e chama `garantir()`. Adotei a
restrição explícita desta rodada — não persistir configurações do leitor e usar
`ro.sh` para SQL de superusuário — e examinei seu caminho de falha por simulação.
Isso não substitui nem reconfirma a medição real que o autor registrou.

`.venv/bin/python /tmp/rvl2-round4-cleanup-sim.py` executou o corpo real do teste
novo com dublês e `garantir()` lançando `RuntimeError`. Saída literal:

```text
canonico antes= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 0} depois= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 1} erro= garantir falhou
ajuste_preexistente antes= {'global': {'default_transaction_read_only': 'on', 'statement_timeout': '5s'}, 'db': {}, 'commits': 0} depois= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 1} erro= garantir falhou
SQL real executado=0; commits acima sao contadores do duble
```

Portanto, se `garantir()` falha e o banco continua acessível, o `finally` remove
os dois ajustes introduzidos pelo teste e recompõe o estado canônico observado.
Ele não depende de a transação interna de `garantir()` ter concluído. Não é um
restaurador de configurações arbitrárias anteriores (RVL2-4-04). Indisponibilidade
da conexão de limpeza não foi induzida; nessa situação ele também pode falhar.
O teste pressupõe ainda o nome usual do banco: suas duas interpolações locais de
`banco` não escapam aspas duplas; não são o laço seguro do código de produção.
Não criei outro banco para testar esse limite.

### B — slots temporários e a falha da própria limpeza

A [documentação das funções de replicação do PG16](https://www.postgresql.org/docs/16/functions-admin.html#FUNCTIONS-REPLICATION)
confirma o argumento `temporary` e a liberação em erro. A limpeza de slots da
sessão está também em
[`slot.c`](https://github.com/postgres/postgres/blob/REL_16_STABLE/src/backend/replication/slot.c).
No teste, a fixture `leitor` usa `NullPool`: sair de `with leitor.connect()` fecha
a conexão física, não a devolve a um pool aberto. Assim, no caso que motivou
RVL2-3-01 — criação indevidamente aceita — o slot temporário não sobrevive à
conexão. O rollback sozinho não é a justificativa da limpeza.

As seis primeiras sondas de `RECUSADAS_POR_DENTRO`, executadas pelo script do
leitor, com rollback e fechamento em `finally`, deram:

```text
select pg_create_physical_replication_slot('__probe_do_leitor', false, true) => 42501 permission denied to use replication slots
select pg_create_logical_replication_slot('__probe_do_leitor', 'test_decoding', true, false) => 42501 permission denied to use replication slots
select pg_drop_replication_slot('__probe_do_leitor') => 42501 permission denied to use replication slots
select pg_replication_slot_advance('__probe_do_leitor', '0/0') => 42501 permission denied to use replication slots
select pg_copy_logical_replication_slot('__probe_do_leitor', '__probe_do_leitor_b', true) => 42501 permission denied to use replication slots
select * from pg_logical_slot_get_changes('__probe_do_leitor', null, null) => 42501 permission denied to use replication slots
```

A limpeza extra tem parâmetro para o nome do slot e escapa os sublinhados do
prefixo no `LIKE`. Ela acontece antes das asserções, inclusive se outra sonda
falhar. **Pode falhar**, porém: superusuário não pode apagar slot ativo de outra
sessão. O uso de um prefixo compartilhado também não isola execuções concorrentes.
Simulação do próprio corpo do teste, no script de A:

```text
temporario erro= AssertionError  slots= [] cleanup= []
sobra_inativa erro= AssertionError  slots= [] cleanup= ['__probe_do_leitor_b']
sobra_ativa erro= RuntimeError 55006: replication slot is active slots= ['__probe_do_leitor_b'] cleanup= ['__probe_do_leitor_b']
```

No terceiro cenário, a falha de limpeza impede chegar a `assert aceitas == []`,
portanto oculta a mensagem específica de criação aceita. Se já houver exceção
em propagação, Python a conserva como contexto, embora o erro final seja o da
limpeza. Não é caminho normal do slot temporário recém-criado por este teste,
cuja sessão já fechou; é limite da defesa adicional sobre sobras/concorrência.
Não criei slot real, não removi checagem de permissão e não induzi falha de rede.

### C — guarda, contraprovas e as 16 views

Reexecutei as matrizes preservadas da rodada anterior sobre a guarda atual:

```bash
.venv/bin/python /tmp/rvl2-round2-identity.py
.venv/bin/python /tmp/rvl2-round3-identity-extra.py
.venv/bin/python /tmp/rvl2-round4-matrix.py
.venv/bin/pytest -q tests/test_identidade_no_consumo.py tests/test_leitor.py
```

A última matriz compara `d7df2cd` carregado em memória com o HEAD. A suíte deu:

```text
83 passed in 0.34s
```

As contraprovas originais `shadow_both`, `shadow_source`, `shadow_source_cte`,
`in_literal_right`, `in_wrong_alias` e `in_swapped` agora produzem uma acusação
cada. `cast_one`, `cast_literals`, `using_subquery_eq` e P12 dão `[]`. O caso
`using_and_on_same` continua dando `ParseError`: a consulta mistura `USING` e
`ON` na mesma junção e não é SQL válido; não é defeito da correção.

#### C1 — escopo de join entre parênteses

Entrada literal da matriz:

```sql
select * from retail.orders s
where exists (
  select 1 from (a x join b s
    on x.order_id=s.order_id and x.source_system='retail')
)
```

Saída:

```text
base []
HEAD []
```

Inspeção direta das funções novas sobre a igualdade interna:

```text
relacao_resolvida_para_s= retail.orders AS s
fontes_do_select_interno= {'': "(a AS x JOIN b AS s ON x.order_id = s.order_id AND x.source_system = 'retail')"}
```

O `s` interno é `b`, não `retail.orders`. Não é perda de origem entre CTEs; é
resolução incorreta dentro da própria cláusula que a função promete resolver.
Para confirmar a semântica sem criar objetos, o SQL de prova substituiu somente
a fonte externa por uma linha `retail` em `VALUES`, e definiu `a` como
`('retail',37)` e `b` como `('legacy',37)`. Por `ro.sh`, o `EXISTS` retornou:

```text
JOIN parentetizado: s interno e legacy, nao a fonte retail externa
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)
```

O script `/tmp/rvl2-round4-proofs.sql` contém o SQL completo, só com CTEs/VALUES.
A substituição é apenas para executar a prova: `retail.orders` é o marcador de
fonte produzido pelo pré-processamento da guarda, não uma tabela criada nesta
revisão. O falso negativo já existia na base, mas persiste precisamente na
resolução de escopo adicionada para fechar RVL2-3-02.

Os demais casos novos de escopo deram o esperado dentro do limite de não analisar
fluxo: `lateral_valid` passa; `derived_shadows`, `cte_boundary` e o segundo ramo
de `union_branches` são acusados. `cte_chain` e `qualifier_cte_name` continuam
acusados conservadoramente, pois uma referência a CTE não é tratada como uma
fonte dbt direta de origem única. Nenhum desses caminhos lançou exceção.

#### C2 — origem não qualificada ainda pode ser externa

Este SQL é aceito pela guarda (`base []`, `HEAD []`) e roda integralmente no PG16:

```sql
with a(source_system,order_id) as (values ('retail',37)),
     b(origin,order_id) as (values ('legacy',37))
select * from a
where (a.source_system,a.order_id) in (select source_system,b.order_id from b);
```

Saída de `ro.sh /tmp/rvl2-round4-proofs.sql`:

```text
IN com origem nao qualificada resolvida no escopo externo
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)
```

A ausência de `b.source_system` faz a coluna não qualificada apontar para
`a.source_system`. É a origem externa repetida, que a docstring afirma recusar.
O caso `in_no_from`, `IN (SELECT source_system,37)`, também é aceito sem haver
qualquer fonte própria na subconsulta.

Outro caso da matriz (`in_wrong_table_origin`, `[]` nas duas versões):

```sql
select * from a
where (a.source_system,a.order_id) in
  (select b.source_system,c.order_id from b cross join c);
```

Com `a=('retail',37)`, `b=('retail',99)` e `c=('legacy',37)`, definidos em CTEs,
a execução por `ro.sh` também devolveu `retail | 37` e `(1 row)`. Ter origem em
alguma relação interna não garante a origem do identificador comparado.

#### C3 — falsos positivos introduzidos pelo reconhecimento de IN

As três formas abaixo têm identidade completa nos exemplos de prova:

```sql
select * from a x where (x.source_system,x.order_id) in
  (select x.source_system,x.order_id from b x);

select * from a where ((a.source_system,a.order_id),a.customer_id) in
  (select (b.source_system,b.order_id),b.customer_id from b);

select * from a where (a.source_system,a.order_id) in (select * from b);
```

Saídas literais, na ordem (`b` tem exatamente `source_system,order_id` no último):

```text
base []
HEAD ['in (subconsulta) sem a origem: order_id']
base []
HEAD ['in (subconsulta) sem a origem: customer_id, order_id']
base []
HEAD ['in (subconsulta) sem a origem: order_id']
```

As três executaram no PostgreSQL e retornaram a linha `retail | 37` (também
`customer_id=1` na segunda), conforme `/tmp/rvl2-round4-proofs.log`. Alias
repetido não é alias compartilhado entre escopos; tupla aninhada não perde a
igualdade do componente de origem. A expansão de `*` pode exigir conhecimento
das colunas e merece limite explícito se não for suportada. A projeção com alias
`SELECT b.source_system AS source_system,b.order_id AS order_id` já passa.

A docstring acerta os limites de fluxo entre CTEs, `UNION` e origem renomeada.
Exagera ao afirmar que o escopo da fonte única está resolvido e que `IN` exige
origem própria na mesma posição: C1/C2 mostram exceções. Não documenta as novas
recusas de C3. O ajuste de projeção aninhada de RVL2-3-06, por sua vez, fechou o
exemplo e passou a ignorar também a igualdade projetada sob um `EXISTS` externo.

Li novamente o SQL das **16 views**, e a execução individual de `violacoes`
devolveu `[]` para todas. `git diff --name-only d7df2cd 36acc2d --
dbt/models/consumption` não produziu saída: nenhuma view mudou neste intervalo.
Não encontrei nas views o falso negativo nem os falsos positivos novos. P12
mantém a fonte direta `retail` no anti-join e `f.source_system='retail'`; P04,
P09 e P16 preservam os usos de identidade descritos na rodada 3. Não executei
build, não recalculei métricas do lote 3 e não atribuí ao lote 2 alterações externas.

### D — recorte do oráculo e classificação

O comentário em `tests/test_acesso.py`, o de `FECHADAS_A_PUBLIC` em
`governance.py` e a Governança §7 v2.12 agora dizem **nome volátil novo**. O
primeiro explicita também a exclusão de tipos internos/handlers; a §7 declara
que sobrecarga nova de nome conhecido passa e que funções estáveis podem ter
efeito interno. `governance.py` remete ao recorte do teste. Nenhum dos três
continua prometendo inventário universal de assinaturas ou ausência de todo efeito.

A classificação por nome também explica por que nem toda sobrecarga de uma
família precisa executar SQL: por exemplo, `ts_rewrite` possui forma que recebe
`tsquery`. A família tem uma forma que executa o SQL fornecido; o motivo cobre
sua abertura com os privilégios do chamador. `cursor_to_xml*` opera o cursor do
chamador. Não identifiquei escalada nova nem classe restante que contradiga o
motivo no catálogo observado. Isso não transforma o recorte em prova de toda
função futura ou de toda composição possível.

Com `ENG_DADOS_DIR` apontando para este checkout,
`.venv/bin/python /tmp/rvl2-round4-oracle.py` reproduziu o predicado `_CHAMAVEIS`
e comparou o catálogo via `ro.sh` com a declaração Python:

```text
nomes_catalogo= 132 classificados= 132 fora_catalogo= 0
sem_classificacao= [] classificados_nao_abertos= []
duplicados= 0 intersecao_fechadas= []
executam SQL de quem chama = ('cursor_to_xml', 'cursor_to_xmlschema', 'query_to_xml', 'query_to_xml_and_xmlschema', 'query_to_xmlschema', 'ts_rewrite', 'ts_stat')
efeito interno, sem dado = ('pg_export_snapshot',)
```

Consulta adicional confirmou `txid_current()` e `pg_current_xact_id()` com
`provolatile=s` e execução permitida; as duas assinaturas de
`pg_logical_emit_message` continuam com execução negada. Não repeti nesta rodada
a prova de `NOTIFY` dentro das funções de SQL nem a exportação real de snapshot.

### E — gates, preservação do estado e limites

Comandos executados sobre `36acc2d` antes de acrescentar este parecer:

```bash
make check-offline > /tmp/rvl2-round4-check-offline.log 2>&1
make secrets-history > /tmp/rvl2-round4-secrets-history.log 2>&1
```

Saída literal relevante do primeiro, omitidos os pontos de progresso e a lista
de arquivos de integração desmarcados:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
792 passed, 188 deselected in 144.34s (0:02:24)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram
```

Última linha literal de `make secrets-history`:

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

A contagem offline do autor foi reproduzida, sem skips. `tests/test_acesso.py`
aparece com seus 16 testes entre os 188 desmarcados; não consta dos 83 testes
direcionados executados separadamente.

Todo SQL de superusuário desta rodada passou exclusivamente por:

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh
```

Versão observada: `PostgreSQL 16.15`. O inventário da rodada 2 foi reexecutado
antes e depois das sondas, e comparado:

```bash
diff -u /tmp/rvl2-round4-inventory-before.log /tmp/rvl2-round4-inventory-after.log
```

**Saída vazia, exit 0.** Mesmas ACLs e configurações inventariadas; nenhum large
object, objeto/papel de sonda ou advisory lock. O inventário adicional terminou
com `slots=0`, `exports=0` e só `global={default_transaction_read_only=on}` para
o leitor. Nenhum ajuste por banco ficou persistido. Não comparei contadores
internos, XIDs ou bytes de WAL; a preservação afirmada é do estado inventariado.

Não executei `garantir()` real, `dbt-build`, `dbt-rebuild`, reset, seed, sync,
DAG, ledger ou recuperação. Não disparei nem pausei `fluxo_batch`. Nenhuma escrita
em `data/memoria_do_legado/`. As sondas reais do leitor terminaram em rollback;
os commits da simulação são apenas contadores em memória. Não concedi permissão,
não criei slot real nem alterei a configuração para testar falhas.

Só `REVISAO.md` foi editado como entrega; scripts e logs de apoio ficaram em
`/tmp/rvl2-round4-*`. Os não rastreados `GEMINI.md` e
`NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam e não foram tocados. Não houve
commit nem push. Permanecem não medidos nesta rodada o ciclo real de reposição,
a falha real da conexão de limpeza e o descarte de um slot realmente criado
após retirada da checagem de permissão.

**Conclusão técnica: o lote 2 ainda não pode ser encerrado pelos ajustes
RVL2-4-01 a RVL2-4-03.** Cinco achados da rodada 3 estão fechados; RVL2-3-02/03
estão parcialmente fechados, com os exemplos originais corrigidos e os limites
acima ainda abertos. O aceite formal continua sendo do Owner.

## Rodada 5 — lote 2

Revisão em **05/11/2026**, no HEAD `1dbb2c5217dd55cb4e1d88a967a823b499e4856f`,
restrita a `git log 36acc2d..1dbb2c5`: `71ec732`, `6d44f38` e `1dbb2c5`.
Parecer técnico, sem poder de aprovação e sem implementar correções.
**O lote 2 permanece aberto:** os exemplos originais de C1/C2 foram corrigidos,
mas a exceção de fonte única e a prova de correlação de `IN` ainda aceitam casos
sem origem restringindo os dois lados. As 16 views passam; os dois gates passam.
As recusas de C3 são limites deliberados, agora documentados, e não novos achados.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-5-01 | `tests/test_identidade_no_consumo.py:148–163` | **RVL2-4-01 parcialmente fechado.** `_ligacoes` só conta `Table`, `Subquery` e `CTE`. Aliases de `Values`, `Lateral` e `Unnest` ficam fora. Dentro de um join entre parênteses, essas relações podem ocultar o `s` externo; `_relacao_do_lado` continua subindo, e `_origem_fixa_por_fonte` concede `retail` ao `s` interno de origem `legacy`. As três variantes retornam `[]`. Contradiz também a promessa de só conceder a exceção quando há uma relação na consulta inteira. Proposta: contar as demais declarações de qualificador ou recusar conservadoramente o escopo não resolvido antes de conceder a exceção. Evidência B. | `ajuste` | **Corrigido.** `_ligacoes` conta agora todo `TableAlias` com o nome do qualificador — o sqlglot dá esse nó ao alias de tabela, subconsulta, CTE, `values`, `lateral` e `unnest` (conferido nos seis) — mais a tabela sem alias pelo próprio nome. Contar o alias, e não uma lista de tipos de relação, é o que não deixa a próxima forma de fora. `values_shadow`, `lateral_shadow` e `unnest_shadow` 0 → 1; P12 continua 0. |
| RVL2-5-02 | `tests/test_identidade_no_consumo.py:221–226` | **RVL2-4-02 parcialmente fechado no lado externo.** `de_fora={''}` satisfaz a condição de qualificador único. `(source_system,order_id)` pode então tomar a origem de `a` e o identificador de `c`, enquanto o lado interno usa corretamente `b.source_system,b.order_id`. A guarda dá `[]` e o PostgreSQL casa o identificador `legacy` com o `retail`. Proposta: exigir qualificador externo não vazio ou provar que as referências não qualificadas pertencem à mesma relação; ausência de qualificador não prova procedência comum. Evidência C. | `ajuste` | **Corrigido.** O qualificador de fora tem de ser único **e não vazio**: coluna de fora sem qualificador pode ser de qualquer relação de fora. `(source_system, order_id) in (select b.source_system, b.order_id from b)`, com e sem `cross join c`, 0 → 1; a forma qualificada passa. |
| RVL2-5-03 | `tests/test_identidade_no_consumo.py:203–210,219–226` | **RVL2-4-02 parcialmente fechado na abrangência dos pares.** `pares` filtra somente pelo nome da coluna externa. Em `(a.source_system,a.tag,a.order_id) IN (SELECT b.source_system,c.customer_id,b.order_id …)`, o par `a.tag/c.customer_id` desaparece da prova, que retorna `True`; `violacoes` retorna `[]`, embora `c` possa ser `legacy`. Até uma coluna comum `c.tag` passa, contrariando o docstring novo de que os de dentro são todos qualificados por uma relação só. Proposta: verificar toda a tupla plana declarada como suportada, incluindo identificadores do lado interno, sem descartar posições antes de provar a procedência. Evidência D. | `ajuste` | **Corrigido.** A prova cobre **todas as posições** da tupla, dos dois lados — nenhuma é descartada pelo nome antes de provar a procedência: `c.customer_id` e até `c.tag` numa posição interna acusam (0 → 1); a mesma tupla toda de `b` passa. Docstring de `_pertence_correlaciona` alinhado ao código. |

### A — fechamento das quatro respostas e matriz C1–C3

“Fechado” abaixo é conclusão técnica sobre o achado, não aceite do Owner.
Os scripts e logs desta rodada estão em `/tmp/rvl2-round5-*`.

| Achado anterior | Conclusão desta rodada | Comando e saída que a sustentam |
|---|---|---|
| RVL2-4-01 | **Parcialmente fechado.** O C1 original foi corrigido; a restrição de unicidade não cobre todas as relações que declaram alias. Resta RVL2-5-01. | `.venv/bin/python /tmp/rvl2-round5-c1-c3.py`: `parenthesized_join_shadow` retorna uma acusação. `.venv/bin/python /tmp/rvl2-round5-extra.py`: `values_shadow`, `lateral_shadow` e `unnest_shadow` retornam `HEAD []`, `ligacoes(s)= ['retail.orders AS s']` e `origem(s)= {'retail'}`. |
| RVL2-4-02 | **Parcialmente fechado.** Os três casos de C2 agora acusam, mas ainda falta provar a origem externa e todos os pares internos. Restam RVL2-5-02/03. | Mesmo comando C1–C3: `in_unqualified_correlated`, `in_no_from` e `in_wrong_table_origin` retornam uma acusação cada. Script `extra`: `outer_unqualified` e `inner_extra_id` retornam `HEAD []` e `pertence_correlaciona= True`; as consultas de C/D retornam uma linha cada. |
| RVL2-4-03 | **Fechado pela declaração dos limites.** Alias igual nos dois escopos, tupla aninhada e `SELECT *` continuam recusados, como o docstring promete. Não são falsos positivos nas 16 views; nenhuma usa `IN` com subconsulta. | Comando C1–C3: uma acusação para cada uma das três formas; `in_alias_projection => []`; `views_com_IN_subconsulta= 0`. Suíte direcionada: `92 passed in 0.52s`. |
| RVL2-4-04 | **Fechado por documentação e conferência do corpo do teste.** A pré-condição canônica está explícita; não se promete restaurar configuração arbitrária anterior. Não executei o ciclo real de reposição. | `git diff 36acc2d..1dbb2c5 -- tests/test_acesso.py` mostra somente o acréscimo ao docstring. `.venv/bin/python /tmp/rvl2-round4-cleanup-sim.py > /tmp/rvl2-round5-cleanup-sim.log` confirma o comportamento do corpo atual em dublês: saída colada em F. |

Comandos da matriz anterior, executada integralmente, e do extrato C1–C3:

```bash
.venv/bin/python /tmp/rvl2-round4-matrix.py > /tmp/rvl2-round5-round4-matrix.log
.venv/bin/python /tmp/rvl2-round5-c1-c3.py > /tmp/rvl2-round5-c1-c3.log
```

O script original ainda chama `d7df2cd` de `base`; suas linhas `HEAD` usam a
função atual de `1dbb2c5`. O extrato reutiliza os SQLs daquele script, sem
alterá-los. Saída literal:

```text
parenthesized_join_shadow => ["junção sem a origem: x.order_id = s.order_id AND x.source_system = 'retail'"]
in_unqualified_correlated => ['in (subconsulta) sem a origem: order_id']
in_no_from => ['in (subconsulta) sem a origem: order_id']
in_wrong_table_origin => ['in (subconsulta) sem a origem: order_id']
in_shadow_alias_valid => ['in (subconsulta) sem a origem: order_id']
in_nested_valid => ['in (subconsulta) sem a origem: customer_id, order_id']
in_star => ['in (subconsulta) sem a origem: order_id']
in_alias_projection => []
views_com_IN_subconsulta= 0
```

Os demais casos da matriz terminaram sem exceção. `lateral_valid`,
`varchar_unbounded` e `projection_subquery_where` passam; `derived_shadows`,
`cte_chain`, `cte_boundary`, `qualifier_cte_name` e `varchar_length` acusam.
`union_branches` acusa agora os dois ramos: o alias repetido faz a exceção
conservadora recuar também no ramo seguro. Isso é comportamento esperado fora
das 16 views, não um achado desta rodada.

### B — fonte única: aliases que a contagem não vê

Entrada de `values_shadow` em `.venv/bin/python /tmp/rvl2-round5-extra.py`:

```sql
select * from retail.orders s
where exists (
  select 1 from (a x join (values ('legacy',37)) s(source_system,order_id)
    on x.order_id=s.order_id and x.source_system='retail')
)
```

Saída literal, comparando a base desta rodada com o HEAD:

```text
36acc2d []
HEAD []
ligacoes(s)= ['retail.orders AS s']
relacao(s)= retail.orders AS s
origem(s)= {'retail'}
```

O alias interno está no nó `Values`, não em um dos três tipos enumerados por
`_ligacoes`. Duas substituições apenas desse lado interno produziram as mesmas
cinco linhas de saída:

```sql
lateral (select 'legacy' as source_system,37 as order_id) s
unnest(array['legacy'],array[37]) s(source_system,order_id)
```

São os casos `lateral_shadow` e `unnest_shadow`. O `Lateral` carrega o alias,
não a `Subquery` que ele envolve; `Unnest` também não entra na contagem.
O controle `values_direct_control`, retirando os parênteses do grupo de join,
retorna uma acusação nas duas versões. Portanto, o problema é a combinação
entre declaração de alias omitida e subida indevida para o escopo externo.

Confirmei os três casos no PostgreSQL, sem criar objetos. Para executar o
marcador sintático `retail.orders`, substituí **apenas a fonte externa** por
`(values ('retail',37)) s(source_system,order_id)` e declarei
`a(source_system,order_id) as (values ('retail',37))`. A igualdade interna
continua comparando o `37` de `x` (`retail`) com o `37` de `s` (`legacy`).
O arquivo de prova contém as três consultas completas:

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl2-round5-proofs.sql > /tmp/rvl2-round5-proofs.log
```

Saída literal de cada variante, respectivamente:

```text
VALUES: o s interno e legacy; o EXISTS ainda aceita retail
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)

LATERAL: mesma colissao
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)

UNNEST: mesma colissao
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)
```

### C — qualificador externo vazio não identifica uma relação

SQL integral analisado pela guarda e executado por `ro.sh`, no mesmo arquivo:

```sql
with a(source_system) as (values ('retail')),
     c(origin,order_id) as (values ('legacy',37)),
     b(source_system,order_id) as (values ('retail',37))
select * from a cross join c
where (source_system,order_id) in (select b.source_system,b.order_id from b);
```

Saída literal de `extra.py`, caso `outer_unqualified`:

```text
36acc2d []
HEAD []
pertence_correlaciona= True
```

Saída de `ro.sh`:

```text
IN externo sem qualificador: origem retail emprestada ao id legacy
 source_system | origin | order_id
---------------+--------+----------
 retail        | legacy |       37
(1 row)
```

As duas colunas externas têm `Column.table == ''`, mas pertencem a relações
diferentes. A verificação proíbe `''` em `de_dentro`, não em `de_fora`. Ao escrever
explicitamente `(a.source_system,c.order_id)`, a guarda passa a acusar
(`qualified_outer_control`). No controle SQL que compara
`(c.origin,c.order_id)` com a mesma subconsulta, `ro.sh` devolve `(0 rows)`:
a origem efetiva do identificador impede o casamento.

### D — posições descartadas antes da prova de procedência

Outro SQL integral, também em `extra.py` e no arquivo executado por `ro.sh`:

```sql
with a(source_system,tag,order_id) as (values ('retail',37,99)),
     b(source_system,order_id) as (values ('retail',99)),
     c(source_system,customer_id) as (values ('legacy',37))
select * from a
where (a.source_system,a.tag,a.order_id) in
  (select b.source_system,c.customer_id,b.order_id from b cross join c);
```

Saída literal da guarda, caso `inner_extra_id`:

```text
36acc2d []
HEAD []
pertence_correlaciona= True
```

Saída do PostgreSQL:

```text
IN com identificador interno ignorado por pares
 source_system | tag | order_id
---------------+-----+----------
 retail        |  37 |       99
(1 row)
```

O predicado casa `c.customer_id` sem restringir `c.source_system`. O filtro de
`pares` olha apenas `f.name`; por isso ignora a posição de `a.tag`, mesmo com um
identificador interno reconhecível. O controle SQL acrescenta uma quarta posição,
`a.source_system` comparado com `c.source_system`, e retorna `(0 rows)`.
O controle sintático que chama a coluna externa de `a.customer_id` faz a guarda
acusar (`qualified_inner_control`), mostrando a dependência do filtro pelo nome
externo.

Há uma contradição documental independente de interpretar `tag` como chave:

```sql
select * from a
where (a.source_system,a.order_id,a.tag) in
  (select b.source_system,b.order_id,c.tag from b cross join c)
```

O caso `inner_extra_non_id` também dá `HEAD []` e
`pertence_correlaciona= True`. A tupla é plana, mas os de dentro não são todos
qualificados por uma relação só, como afirma o novo docstring. A solução
conservadora declarada permite recusar essa forma, sem precisar implementar
análise geral de fluxo.

Os falsos negativos de B/C/D já retornavam `[]` em `36acc2d`. Não atribuo sua
introdução a `71ec732`: são lacunas persistentes nos caminhos corrigidos e nas
novas promessas de prova. Não encontrei essas formas nas 16 views.

### E — as 16 views e a exceção de P12

`.venv/bin/python /tmp/rvl2-round5-extra.py` chama `violacoes(_sql(modelo))`
individualmente. Saída literal:

```text
average_order_value_by_channel_and_segment => []
cart_conversion_rate_by_channel => []
discount_share_by_channel => []
gross_margin_by_category => []
inventory_turnover_by_sku_and_warehouse => []
monthly_revenue_by_channel_and_category => []
new_and_repeat_customers_by_month => []
on_time_delivery_rate_by_carrier => []
order_to_delivery_time_by_region => []
payment_approval_rate_by_method => []
refund_rate_by_reason => []
repeat_purchase_rate_after_support => []
revenue_by_delivery_region => []
skus_below_reorder_point => []
support_tickets_per_hundred_orders => []
top_skus_by_revenue => []
P12= skus_below_reorder_point.sql
P12 ligacoes(s)= ['retail.inventory_movements_stream AS s']
P12 sem excecao= ["junção sem a origem: f.source_system = 'retail' AND f.movement_id = s.movement_id"]
```

A última linha é um controle **só em memória**, substituindo temporariamente
`_origem_fixa_por_fonte` por uma função que retorna `set()`. Confirma que P12
passa pela exceção da fonte única, não por falta de exame do anti-join.
Nenhum arquivo de código foi alterado. O comando
`git diff --name-only 36acc2d..1dbb2c5 -- dbt/models/consumption` teve saída vazia.
Não executei as consultas das views contra o armazém nem recalculei suas métricas;
a execução pedida aqui é a da guarda sobre os 16 SQLs.

### F — docstrings e pré-condição do leitor

O docstring do módulo e o de `_origem_fixa_por_fonte` descrevem a política
conservadora, mas a promessa de unicidade de relação falha em B. O de
`_pertence_correlaciona` descreve corretamente as recusas de C3 e a exigência de
origem na mesma posição; passa também o controle com ordem invertida
`(a.order_id,a.source_system) IN (SELECT b.order_id,b.source_system FROM b)`.
As promessas de qualificador externo comum e de todos os internos na mesma
relação não são satisfeitas em C/D. São contradições da implementação com o
contrato escrito, não pedidos para aceitar formas declaradas não suportadas.

No teste do leitor, `6d44f38` muda somente a documentação. Li o `try/finally`:
a limpeza continua fazendo `RESET ALL` no papel/banco corrente e no global,
seguido do padrão global `on`. Sob a pré-condição canônica, isso repõe o estado
esperado mesmo quando `garantir()` falha; não captura o inventário anterior.
A nova ressalva documenta precisamente essa escolha. A limpeza de outros bancos
no caminho de sucesso pertence ao `garantir()`, não a esse `finally`.

Reexecução do corpo real com dublês e `garantir()` lançando erro, sem SQL real:

```bash
.venv/bin/python /tmp/rvl2-round4-cleanup-sim.py > /tmp/rvl2-round5-cleanup-sim.log
```

Trecho literal pertinente a RVL2-4-04:

```text
canonico antes= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 0} depois= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 1} erro= garantir falhou
ajuste_preexistente antes= {'global': {'default_transaction_read_only': 'on', 'statement_timeout': '5s'}, 'db': {}, 'commits': 0} depois= {'global': {'default_transaction_read_only': 'on'}, 'db': {}, 'commits': 1} erro= garantir falhou
SQL real executado=0; commits acima sao contadores do duble
```

Não executei o teste de integração real, que persiste configuração e chama
`garantir()`. Não afirmo ter medido o estado atual do leitor nesta rodada.

### G — regressões, preservação do ambiente e conclusão

Comandos executados no HEAD acima, antes de acrescentar este parecer:

```bash
.venv/bin/pytest -q tests/test_identidade_no_consumo.py tests/test_leitor.py > /tmp/rvl2-round5-targeted.log
make check-offline > /tmp/rvl2-round5-check-offline.log 2>&1
make secrets-history > /tmp/rvl2-round5-secrets-history.log 2>&1
```

Saídas literais relevantes, com progresso e inventário dos testes de integração
omitidos; os três comandos terminaram com código 0:

```text
92 passed in 0.52s

── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
801 passed, 188 deselected in 145.06s (0:02:25)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram

revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Reproduzida a contagem do gate do autor. `tests/test_acesso.py` consta com seus
16 testes entre os 188 desmarcados. A passagem do gate não cobre os falsos
negativos adicionais de B/C/D, cujas contraprovas foram executadas separadamente.

Todo SQL real desta rodada passou por `ro.sh`, com `ENG_DADOS_DIR` apontando
para este checkout, e usou apenas `SELECT` com CTEs/`VALUES` ou funções de
construção de linhas. Não houve DDL, DML, alteração de configuração, chamada real
de `garantir()`, build, reset, seed, sync, DAG, ledger ou recuperação. Não
disparei nem pausei `fluxo_batch`; não escrevi em `data/memoria_do_legado/`.
Não realizei inventário antes/depois: a preservação se apoia no conteúdo das
sondas e na sessão somente de leitura, sem alegar comparação de estado não feita.

Somente `REVISAO.md` foi editado no repositório. Os arquivos não rastreados
`GEMINI.md` e `NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam e foram
preservados. Scripts e logs de apoio ficaram em `/tmp`. Sem commit ou push.

**Conclusão técnica: o lote 2 ainda não pode ser encerrado.** RVL2-4-03 e
RVL2-4-04 estão fechados; RVL2-4-01 e RVL2-4-02 estão parcialmente fechados,
com os exemplos originais corrigidos e três ajustes restantes nesta tabela.
O aceite formal continua sendo do Owner.

## Rodada 6 — lote 2

Revisão em **05/11/2026**, no HEAD `6b06205bdea4de86a5235a9db488c0833a4edff4`,
restrita a `git log 1dbb2c5..6b06205`: `54f81e6` e `6b06205`.
Parecer técnico, sem poder de aprovação e sem implementar correções.
**O lote 2 permanece aberto.** Os exemplos B/C/D da rodada 5 foram corrigidos,
mas persistem três falsos negativos nos caminhos revisados e uma divergência
entre a recusa documentada de `*` e a implementação. As 16 views e os dois gates
passam. Os casos adicionais também passam indevidamente em `1dbb2c5`: não atribuo
sua introdução aos dois commits desta rodada. Não identifiquei regressão nova
introduzida pelo diff nas sondas executadas.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-6-01 | `tests/test_identidade_no_consumo.py:148–169` | **RVL2-5-01 parcialmente fechado: comparação textual de nomes perde aliases equivalentes.** Um alias interno `S` sem aspas oculta o `s` externo no PostgreSQL, mas `_ligacoes(..., 's')` não o conta. A exceção concede `retail` ao identificador interno `legacy`; `violacoes` retorna `[]`. Também ocorre com referência externa escrita `"s"`. Proposta: comparar identificadores pela semântica do dialeto, preservando a distinção dos nomes entre aspas, ou recusar a forma não resolvida. Evidência B. | `ajuste` | **Corrigido.** A árvore passa por `normalize_identifiers(…, dialect="postgres")` antes de tudo: sem aspas vira minúscula, entre aspas fica como está — `S` e `s` são o mesmo alias, `"S"` é outro, como no PostgreSQL. O caso de B 0 → 1. |
| RVL2-6-02 | `tests/test_identidade_no_consumo.py:148–169` | **RVL2-5-01 parcialmente fechado: função no `FROM` tem nome implícito que não entra na contagem.** `json_to_record(…) AS (source_system text, order_id int)` declara colunas, mas não um alias de relação explícito; no PostgreSQL, `json_to_record.order_id` aponta para essa função. No AST, `TableAlias.name` e `Table.name` são vazios. A guarda só conta o alias externo homônimo e empresta sua origem. Proposta: reconhecer o nome implícito ou impedir a exceção diante dessa relação não resolvida. Evidência C. | `ajuste` | **Corrigido**, de modo conservador: `_relacao_sem_nome` — um `TableAlias` ou `Table` sem nome legível, como `json_to_record(…) as (…)` — retira a exceção da fonte única da consulta inteira. O caso de C 0 → 1. |
| RVL2-6-03 | `tests/test_identidade_no_consumo.py:228–234` | **`Column.table` não identifica sozinho a procedência.** `orders.source_system` e `trusted.orders.order_id` têm o mesmo `.table`, mas podem apontar para uma relação local e outra externa. `_pertence_correlaciona` retorna `True` tanto quando a mistura está na tupla externa quanto na projeção interna; `violacoes` retorna `[]`, e o PostgreSQL casa `legacy/37` com `retail/37`. Proposta: considerar a qualificação completa e o escopo ou recusar conservadoramente colunas com schema/catalog antes de conceder a prova. Evidência D. | `ajuste` | **Corrigido**, de modo conservador: `_qualificacao_longa` — coluna com schema ou catálogo — não entra em prova nenhuma, nem na correlação de junção nem no `in`. O caso de D 0 → 1. |
| RVL2-6-04 | `tests/test_identidade_no_consumo.py:210–226` | **A recusa documentada de expansão `*` não cobre `a.*`/`b.*`.** O sqlglot representa o asterisco qualificado como `Column(Star)`, que passa no teste de `exp.Column`. A consulta válida de E recebe `True` e `[]`, embora a prova prometa tupla plana de colunas e recusa de `select *`. Este caso é divergência documental, não uma colisão de origem demonstrada. Proposta: recusar também a expansão qualificada ou delimitar explicitamente e justificar o suporte no contrato. | `ajuste` | **Corrigido.** `Column(Star)` (`b.*`) é recusado na prova do `in`, como expansão. `(a.source_system, a.order_id) in (select b.source_system, b.* from b)`: `[]` em `6b06205`, uma acusação agora. |
| RVL2-6-05 | `tests/test_identidade_no_consumo.py::_e_identificador` e `violacoes` — fora do diff | Identificadores não delimitados em maiúsculas, como `a.ORDER_ID=b.ORDER_ID`, não são reconhecidos pelo regex sensível a caixa. A sonda casa `retail/37` com `legacy/37` e retorna `[]`. É lacuna preexistente da detecção, distinta da contagem de aliases de RVL2-6-01; fica como observação por estar fora do escopo dos dois commits. Evidência F. | `observação` | **Corrigido** pela mesma normalização de RVL2-6-01: `a.ORDER_ID = b.ORDER_ID` vira `order_id` e acusa (0 → 1). Identificador entre aspas em maiúsculas continua sendo, como no PostgreSQL, outro nome. |
| RVL2-6-06 | `tests/test_identidade_no_consumo.py::violacoes`, chamada de `_pertence_correlaciona` — fora do diff | Se o único identificador está no lado interno do `IN`, a chamada à prova é omitida: o filtro examina somente os nomes externos. Na sonda de F, `_pertence_correlaciona` corretamente retorna `False`, mas `violacoes` retorna `[]`. A alteração de todas as posições dentro da prova está correta; o chamador não alterado continua com essa lacuna. | `observação` | **Corrigido.** O chamador junta os nomes dos dois lados antes de decidir chamar a prova: `a.tag in (select b.order_id from b)` 0 → 1. Com a origem casada, `(a.source_system, a.tag) in (select b.source_system, b.order_id from b)` passa — é o caso de teste que mostra que a prova, não o filtro, decide. |

### A — respostas da rodada 5 e reexecução da matriz B/C/D

“Fechado” abaixo é conclusão técnica sobre o achado específico, não aceite do
Owner nem declaração de completude da guarda.

| Achado anterior | Conclusão desta rodada | Comando e saída que a sustentam |
|---|---|---|
| RVL2-5-01 | **Parcialmente fechado.** Os três exemplos originais e a enumeração de aliases explícitos foram corrigidos. A garantia de contar toda relação nomeada ainda falha por caixa e nome implícito: RVL2-6-01/02. | `.venv/bin/python /tmp/rvl2-round6-matrix.py`: `values_shadow`, `lateral_shadow`, `unnest_shadow`: `1dbb2c5= 0 HEAD= 1`. O script original da rodada 5 agora mostra duas ligações e `origem(s)= set()` nos três. |
| RVL2-5-02 | **Fechado quanto ao qualificador externo vazio.** O código exige `"" not in de_fora`, e o exemplo com origem/identificador não qualificados acusa. A confusão de qualificação completa tem registro próprio em RVL2-6-03. | Mesmo comando: `outer_unqualified 1dbb2c5= 0 HEAD= 1`; `.venv/bin/python /tmp/rvl2-round5-extra.py`: `HEAD ['in (subconsulta) sem a origem: order_id']`, `pertence_correlaciona= False`. |
| RVL2-5-03 | **Fechado quanto às posições descartadas dentro da prova.** Todos os elementos externos e internos participam dos conjuntos; não há mais filtro por nome antes da comparação. Tanto `c.customer_id` quanto `c.tag` acusam. O filtro anterior à chamada, fora do diff, é a observação RVL2-6-06. | `.venv/bin/python /tmp/rvl2-round6-matrix.py`: `inner_extra_id` e `inner_extra_non_id`: `1dbb2c5= 0 HEAD= 1`; script original: `pertence_correlaciona= False` nos dois. |

Comandos executados, com código 0:

```bash
.venv/bin/python /tmp/rvl2-round5-extra.py > /tmp/rvl2-round6-round5-extra.log
.venv/bin/python /tmp/rvl2-round6-matrix.py > /tmp/rvl2-round6-matrix.log
.venv/bin/python /tmp/rvl2-round5-c1-c3.py
```

O primeiro reutiliza **sem alteração** todas as entradas B/C/D e os controles da
rodada 5; seu rótulo antigo `36acc2d` continua sendo aquela base, e `HEAD` lê o
arquivo atual. O segundo reutiliza essas mesmas entradas e compara com a base
correta desta rodada, `1dbb2c5`. Saída literal dessa comparação:

```text
values_shadow 1dbb2c5= 0 HEAD= 1
lateral_shadow 1dbb2c5= 0 HEAD= 1
unnest_shadow 1dbb2c5= 0 HEAD= 1
outer_unqualified 1dbb2c5= 0 HEAD= 1
inner_extra_id 1dbb2c5= 0 HEAD= 1
inner_extra_non_id 1dbb2c5= 0 HEAD= 1
qualified_star 1dbb2c5= 0 HEAD= 0
qualified_outer_control 1dbb2c5= 1 HEAD= 1
qualified_inner_control 1dbb2c5= 1 HEAD= 1
values_direct_control 1dbb2c5= 1 HEAD= 1
valid_tuple 1dbb2c5= 0 HEAD= 0
valid_tuple_reversed 1dbb2c5= 0 HEAD= 0
```

No extrato C1–C3, cada um de `parenthesized_join_shadow`,
`in_unqualified_correlated`, `in_no_from`, `in_wrong_table_origin`,
`in_shadow_alias_valid`, `in_nested_valid` e `in_star` retorna uma acusação;
`in_alias_projection => []` e `views_com_IN_subconsulta= 0`.
As recusas conservadoras dessas formas não são achados.

Também conferi a representação dos aliases explícitos. Saída literal de `matrix.py`:

```text
alias table TableAlias= [('Table', 's')] ligacoes= 1
alias subquery TableAlias= [('Subquery', 's')] ligacoes= 1
alias cte TableAlias= [('CTE', 's')] ligacoes= 2
alias values TableAlias= [('Values', 's')] ligacoes= 1
alias lateral TableAlias= [('Lateral', 's')] ligacoes= 1
alias unnest TableAlias= [('Unnest', 's')] ligacoes= 1
alias function_explicit TableAlias= [('Table', 's')] ligacoes= 1
alias rows_from TableAlias= [('Table', 's')] ligacoes= 1
alias xmltable TableAlias= [('Table', 's')] ligacoes= 1
alias unaliased TableAlias= [] ligacoes= 1
```

Na CTE, as duas ligações são a declaração e a referência `FROM s`; essa
supercontagem conservadora não é um achado. O problema é deixar passar uma
ligação real, como nas próximas duas evidências.

### B — alias sem aspas com caixa diferente ainda oculta o externo

Comandos comuns às sondas adicionais de B–F:

```bash
.venv/bin/python /tmp/rvl2-round6-probes.py > /tmp/rvl2-round6-probes.log
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl2-round6-proofs.sql > /tmp/rvl2-round6-proofs.log
```

Ambos terminaram com código 0. O script compara a guarda de `1dbb2c5` com a
atual, imprime a prova e gera o SQL de leitura. Entrada `case_shadow`:

```sql
select * from retail.orders s
where exists (
  select 1 from (a x join (values ('legacy',37)) S(source_system,order_id)
    on x.order_id=s.order_id and x.source_system='retail')
)
```

Saída literal:

```text
1dbb2c5 []
HEAD []
ligacoes= ['retail.orders AS s']
origem= ['retail']
aliases= [('Table', 's'), ('Table', 'x'), ('Values', 'S')]
```

O parser preserva `S`; a comparação de strings não o considera igual a `s`.
No PostgreSQL, o `S` **sem aspas** nomeia `s`, e o identificador do `ON` é do
`VALUES` interno, de origem `legacy`. Para a prova SQL, como na rodada 5,
substituí apenas a fonte externa `retail.orders s` por
`(values ('retail',37)) s(source_system,order_id)` e declarei
`a(source_system,order_id) as (values ('retail',37))`. Não alterei o join interno.
O controle acrescenta `and x.source_system=s.source_system` ao `ON`.
Saída literal do PostgreSQL:

```text
case_shadow
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)

case_shadow_origin_control
 source_system | order_id
---------------+----------
(0 rows)
```

`case_quoted_reference`, com alias externo e referência escritos `"s"`, também
retorna `HEAD []`, uma linha SQL e zero no controle de origem. Já
`quoted_exact_shadow`, com `"S"` nos dois escopos, é corretamente acusado no
HEAD; `quoted_distinct_control`, com `s` externo e `"S"` interno, passa
corretamente: esses dois nomes são distintos, e a referência `s.order_id` é
externa. Não se propõe simplesmente converter todo nome para minúsculas.

### C — função sem alias explícito declara um qualificador implícito

Entrada `function_implicit`:

```sql
select * from retail.orders json_to_record
where exists (
  select 1 from (a x join
    json_to_record('{"source_system":"legacy","order_id":37}')
      as (source_system text,order_id int)
    on x.order_id=json_to_record.order_id and x.source_system='retail')
)
```

Saída literal da guarda:

```text
1dbb2c5 []
HEAD []
ligacoes= ['retail.orders AS json_to_record']
origem= ['retail']
aliases= [('Table', 'json_to_record'), ('Table', 'x'), ('Table', '')]
```

O alias de colunas existe no AST, mas seu nome de relação é vazio; o `Table`
que envolve a função também tem `.name == ''`. O PostgreSQL resolve
`json_to_record.order_id` para a função interna, não para a fonte externa.
A mesma substituição da fonte externa por `VALUES` e a mesma declaração de `a`
de B permitem executar a prova sem criar objetos. Controle: acrescentar
`and x.source_system=json_to_record.source_system`.

```text
function_implicit
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)

function_implicit_origin_control
 source_system | order_id
---------------+----------
(0 rows)
```

Ao escrever explicitamente `AS json_to_record(source_system text, order_id int)`,
o SQL ainda casa as mesmas linhas, mas a guarda corretamente acusa:

```text
HEAD ["junção sem a origem: x.order_id = json_to_record.order_id AND x.source_system = 'retail'"]
origem= []
```

Portanto, contar `TableAlias` resolve as seis formas explícitas descritas na
resposta, mas não sustenta a promessa de que nenhuma relação nomeada fica fora.

### D — qualificação de schema ignorada nos dois lados do IN

A consulta seguinte é **a mesma** passada à guarda e ao PostgreSQL. Lê somente
o pedido sintético existente `trusted.orders.order_id=37`, de origem `legacy`:

```sql
with a(source_system,order_id) as (values ('retail',37))
select trusted.orders.source_system as actual_origin,
       trusted.orders.order_id, a.source_system as borrowed_origin
from trusted.orders cross join a
where trusted.orders.source_system='legacy' and trusted.orders.order_id=37
  and (a.source_system,a.order_id) in (
    select orders.source_system,trusted.orders.order_id
    from (values ('retail',999)) orders(source_system,order_id)
  );
```

Saída literal de `inner_schema`:

```text
1dbb2c5 []
HEAD []
pertence_correlaciona= True
colunas= [('a.source_system', 'a', ''), ('a.order_id', 'a', ''), ('orders.source_system', 'orders', ''), ('trusted.orders.order_id', 'orders', 'trusted')]
```

A coluna de origem vem do `VALUES` interno; o identificador vem da tabela
externa. A prova vê apenas `de_dentro={'orders'}` e encontra esse nome no
`FROM` interno. O `999` interno nem participa do casamento. O controle troca
`orders.source_system` por `trusted.orders.source_system` na projeção interna.
Saída literal do PostgreSQL:

```text
inner_schema
 actual_origin | order_id | borrowed_origin
---------------+----------+-----------------
 legacy        |       37 | retail
(1 row)

inner_schema_control
 actual_origin | order_id | borrowed_origin
---------------+----------+-----------------
(0 rows)
```

A mistura também passa na tupla **externa**, caso `outer_schema`:

```sql
with a(source_system,order_id) as (values ('retail',37))
select * from a where exists (
  select 1 from trusted.orders
  where trusted.orders.source_system='legacy' and trusted.orders.order_id=37
    and exists (
      select 1 from (values ('retail',999)) orders(source_system,order_id)
      where (orders.source_system,trusted.orders.order_id) in
        (select a.source_system,a.order_id from a)
    )
);
```

```text
1dbb2c5 []
HEAD []
pertence_correlaciona= True
colunas= [('orders.source_system', 'orders', ''), ('trusted.orders.order_id', 'orders', 'trusted'), ('a.source_system', 'a', ''), ('a.order_id', 'a', '')]
```

O PostgreSQL devolve `retail | 37`, `(1 row)`. Substituir a primeira posição por
`trusted.orders.source_system` devolve `(0 rows)`. O problema não é uma recusa
excessiva de sintaxe desconhecida: são dois falsos negativos com referência
qualificada válida, aceitos como prova de procedência comum.

### E — docstrings e expansão qualificada

Os requisitos de qualificador externo não vazio e de participação de todas as
posições estão implementados. Permanecem falsas a garantia de unicidade de
ligação (B/C) e a de que os campos internos vêm de uma relação declarada na
subconsulta (D). A recusa de `SELECT *` simples, tupla aninhada e alias idêntico
nos exemplos C1–C3 continua funcionando e não foi tratada como defeito.

Há, porém, uma expansão **qualificada** válida que a prova aceita:

```sql
with a(source_system,order_id) as (values ('retail',37)),
     b(source_system,order_id) as (values ('retail',37))
select * from a
where (a.source_system,a.order_id,a.*) in
  (select b.source_system,b.order_id,b.* from b);
```

Saída literal do caso `qualified_star` de `probes.py`:

```text
1dbb2c5 []
HEAD []
pertence_correlaciona= True
colunas= [('a.source_system', 'a', ''), ('a.order_id', 'a', ''), ('a.*', 'a', ''), ('b.source_system', 'b', ''), ('b.order_id', 'b', ''), ('b.*', 'b', '')]
```

PostgreSQL:

```text
qualified_star
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)
```

O SQL é válido porque expande os dois lados. A guarda compara três nós por
lado, mas o banco compara quatro campos. Não demonstrei colisão de origem
nesta consulta; o achado é a aceitação de expansão que a descrição da prova
promete recusar. A entrada `qualified_star` antiga da matriz B/C/D tem outra
aridade; este exemplo com expansão nos dois lados elimina essa dúvida.

### F — observações fora do diff

As duas sondas abaixo estão no mesmo `probes.py` e foram executadas por `ro.sh`.
Não atribuo sua correção aos dois commits desta rodada.

```sql
-- uppercase_identifier_outside_scope
with a(source_system,order_id) as (values ('retail',37)),
     b(source_system,order_id) as (values ('legacy',37))
select * from a join b on a.ORDER_ID=b.ORDER_ID;

-- inner_identifier_only_outside_scope
with a(source_system,tag) as (values ('retail',37)),
     b(source_system,order_id) as (values ('legacy',37)),
     c(source_system) as (values ('retail'))
select * from a
where (a.source_system,a.tag) in
  (select c.source_system,b.order_id from b cross join c);
```

Saída literal da guarda para a primeira:

```text
1dbb2c5 []
HEAD []
```

Para a segunda:

```text
1dbb2c5 []
HEAD []
pertence_correlaciona= False
```

Saída literal do PostgreSQL:

```text
uppercase_identifier_outside_scope
 source_system | order_id | source_system | order_id
---------------+----------+---------------+----------
 retail        |       37 | legacy        |       37
(1 row)

inner_identifier_only_outside_scope
 source_system | tag
---------------+-----
 retail        |  37
(1 row)
```

Na segunda, a prova atual rejeitaria a procedência de `c.source_system` e
`b.order_id`; é o filtro de identificadores somente externos que a impede de
ser chamada. Isso distingue essa observação do defeito corrigido em RVL2-5-03.

### G — as 16 views, P12 e regressões

Saída literal de `.venv/bin/python /tmp/rvl2-round5-extra.py` no HEAD desta rodada:

```text
average_order_value_by_channel_and_segment => []
cart_conversion_rate_by_channel => []
discount_share_by_channel => []
gross_margin_by_category => []
inventory_turnover_by_sku_and_warehouse => []
monthly_revenue_by_channel_and_category => []
new_and_repeat_customers_by_month => []
on_time_delivery_rate_by_carrier => []
order_to_delivery_time_by_region => []
payment_approval_rate_by_method => []
refund_rate_by_reason => []
repeat_purchase_rate_after_support => []
revenue_by_delivery_region => []
skus_below_reorder_point => []
support_tickets_per_hundred_orders => []
top_skus_by_revenue => []
P12= skus_below_reorder_point.sql
P12 ligacoes(s)= ['retail.inventory_movements_stream AS s']
P12 sem excecao= ["junção sem a origem: f.source_system = 'retail' AND f.movement_id = s.movement_id"]
```

O controle de P12 substitui `_origem_fixa_por_fonte` apenas em memória por uma
função que retorna `set()`. Confirma que a passagem depende da fonte única.
Não executei as 16 views no banco nem recalculei métricas; conferi a guarda
sobre cada SQL, que é o objeto desta rodada.

Gates executados antes de acrescentar o parecer, ambos com código 0:

```bash
make check-offline > /tmp/rvl2-round6-check-offline.log 2>&1
make secrets-history > /tmp/rvl2-round6-secrets-history.log 2>&1
```

Saídas literais pertinentes, omitindo progresso e inventário de integração:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
809 passed, 188 deselected in 144.65s (0:02:24)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram

revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Reproduzida a contagem do autor, `809 passed, 188 deselected`. O gate não cobre
os escapes adicionais: sua evidência vem das sondas separadas acima.

### H — preservação do ambiente e conclusão

Todo SQL real passou por `ro.sh` com `ENG_DADOS_DIR` neste checkout. Foram
somente consultas de metadados, `SELECT` com `VALUES`/CTEs/função de construção
de registro e leitura de `trusted.orders`. Nenhum DDL, DML, build, alteração de
configuração, chamada a `garantir()`, reset, seed, sync, DAG, ledger ou operação
de recuperação. Não disparei nem pausei `fluxo_batch`, não subi nem pausei
serviços e não escrevi em `data/memoria_do_legado/`. Não fiz inventário completo
antes/depois; a preservação se apoia no conteúdo das sondas e na sessão de leitura.

Somente `REVISAO.md` foi editado como entrega no repositório. Scripts e logs
ficaram em `/tmp/rvl2-round6-*`. Os não rastreados `GEMINI.md` e
`NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam e não foram tocados.
Sem commit ou push; nenhuma correção implementada.

**Conclusão técnica: o lote 2 ainda não pode ser encerrado.** RVL2-5-02 e
RVL2-5-03 estão fechados nos pontos que descreviam; RVL2-5-01 está parcialmente
fechado. Restam os ajustes RVL2-6-01 a RVL2-6-04; RVL2-6-05/06 são observações
fora do diff. O aceite formal continua sendo do Owner.

## Rodada 7 — lote 2

Revisão em **05/11/2026**, no HEAD `e1f7c9ce442323a8cddfbce24c3f443a255515ad`,
restrita a `git log 6b06205..e1f7c9c`: `d43b998` e `e1f7c9c`.
Rodada final de regressão, pelas quatro categorias delimitadas pelo Owner.
Parecer técnico, sem poder de aprovação, sem correções, commit ou push.

**As seis sondas originais da rodada 6 estão corrigidas. Não encontrei regressão
introduzida por `d43b998` nas verificações executadas.** As 16 views retornam
`[]`, P12 continua passando pela exceção de fonte única, e os dois gates passam.
Resta **um ajuste documental, da categoria 4**: a nova promessa de recusar a
exceção diante de qualquer relação sem nome legível excede a implementação.
O falso negativo usado para demonstrá-lo já existia na base; não é apresentado
como regressão nem como nova exigência de ampliar a análise sintática.
**O lote 2 ainda não pode ser encerrado pelo critério desta rodada**, pois essa
divergência de docstring permanece aberta.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL2-7-01 | `tests/test_identidade_no_consumo.py:47–48,163–168` | **A docstring promete mais do que `_relacao_sem_nome` verifica.** A exceção ainda vale diante de `unnest` sem alias: seu nó é `Unnest`, sem nome e sem `TableAlias`, e não entra nas duas buscas por `TableAlias`/`Table`. A sonda de C retorna `_relacao_sem_nome=False`, uma ligação e origem `retail`, embora o qualificador interno seja da função. A frase nova «nenhuma relação ficou sem nome legível» e a descrição geral de função sem alias não são honradas. O SQL já retorna `[]` em `6b06205`: o achado é **documental, categoria 4**, não uma regressão funcional. Ajuste proposto: delimitar a promessa aos nós efetivamente inspecionados e declarar o limite de funções implícitas representadas por outros nós; alternativamente, cobrir a forma. | `ajuste` | **Corrigido, coberta a forma em vez de só delimitar a promessa.** `_relacao_sem_nome` inspeciona agora todo item de `from`/`join` de todo `select` que não seja tabela nomeada nem tenha alias, e todo `unnest` sem alias em qualquer ponto, além dos `TableAlias`/`Table` de nome vazio; o docstring lista exatamente esses nós, e o limite do módulo aponta para ele. O SQL de "Limites remanescentes" passou de `[]` (em `e1f7c9c`) a uma acusação, com caso de teste próprio; as 16 views continuam `[]` e P12 passa pela fonte única. Com isso, a lista de limites remanescentes desta rodada fica vazia. |

### A — fechamento das seis respostas e matriz B–F

Reutilizei as entradas de `/tmp/rvl2-round6-probes.py`, substituindo a base
`1dbb2c5` por `6b06205`. A inspeção dos auxiliares no HEAD agora recebe a árvore
normalizada, tal como o caminho real de `violacoes`; a guarda da base permanece
intacta. Retirei a geração do arquivo SQL da rodada anterior. Os comandos abaixo
terminaram com código 0; o segundo imprime o número de acusações de cada caso:

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl2-round7-probes.py > /tmp/rvl2-round7-probes.log
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl2-round7-summary.py > /tmp/rvl2-round7-summary.log
```

Saída literal do segundo comando, com os mesmos SQLs de B–F da rodada 6:

```text
case_shadow 6b06205= 0 HEAD= 1
case_quoted_reference 6b06205= 0 HEAD= 1
quoted_exact_shadow 6b06205= 1 HEAD= 1
quoted_distinct_control 6b06205= 0 HEAD= 0
function_implicit 6b06205= 0 HEAD= 1
function_explicit_control 6b06205= 1 HEAD= 1
inner_schema 6b06205= 0 HEAD= 1
outer_schema 6b06205= 0 HEAD= 1
qualified_star 6b06205= 0 HEAD= 1
uppercase_identifier_outside_scope 6b06205= 0 HEAD= 1
inner_identifier_only_outside_scope 6b06205= 0 HEAD= 1
inner_schema_control 6b06205= 0 HEAD= 1
outer_schema_control 6b06205= 0 HEAD= 1
```

| Resposta | Fechamento técnico | Comando e saída que sustentam o fechamento |
|---|---|---|
| RVL2-6-01 | **Fechado.** `S` sem aspas e `s` passam a ser contados juntos, inclusive diante da referência `"s"`; `"S"` continua distinto de `s`. | `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl2-round7-summary.py`: `case_shadow` e `case_quoted_reference`, `0 → 1`; `quoted_exact_shadow`, `1 → 1`; `quoted_distinct_control`, `0 → 0`. |
| RVL2-6-02 | **Fechado quanto ao achado C da rodada 6:** `json_to_record(…) AS (…)` retira a exceção. A generalização documental da solução tem a ressalva própria RVL2-7-01. | Mesmo comando: `function_implicit 6b06205= 0 HEAD= 1`; `function_explicit_control 6b06205= 1 HEAD= 1`. O log detalhado imprime `origem= []` nos dois casos. |
| RVL2-6-03 | **Fechado.** A qualificação longa impede a prova nos dois lados do `IN`. | Mesmo comando: `inner_schema` e `outer_schema`, `0 → 1`; no log detalhado, ambos dão `HEAD ['in (subconsulta) sem a origem: order_id']` e `pertence_correlaciona= False`. |
| RVL2-6-04 | **Fechado.** A expansão qualificada válida nos dois lados é recusada. | Mesmo comando: `qualified_star 6b06205= 0 HEAD= 1`; log detalhado: `HEAD ['in (subconsulta) sem a origem: order_id']`, `pertence_correlaciona= False`. |
| RVL2-6-05 | **Fechado.** `ORDER_ID` sem aspas é reconhecido como identificador. | Mesmo comando: `uppercase_identifier_outside_scope 6b06205= 0 HEAD= 1`; log detalhado: `HEAD ['junção sem a origem: a.order_id = b.order_id']`. |
| RVL2-6-06 | **Fechado.** O identificador apenas na projeção interna da sonda F agora chama a prova. | Mesmo comando: `inner_identifier_only_outside_scope 6b06205= 0 HEAD= 1`; log detalhado: `HEAD ['in (subconsulta) sem a origem: order_id']`, `pertence_correlaciona= False`. |

Os controles `inner_schema_control` e `outer_schema_control` também passam de
zero para uma acusação. É a recusa conservadora explícita de schema, inclusive
quando a origem está correta. Não é achado pela categoria 1: nenhuma das 16
views foi rejeitada. A expansão qualificada de E tem o mesmo enquadramento;
sua recusa fecha o contrato pedido na rodada anterior.

### B — regressões, 16 views, P12 e normalização

Comandos, todos com código 0:

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl2-round7-views-controls.py > /tmp/rvl2-round7-views-controls.log
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rvl2-round7-extra.py > /tmp/rvl2-round7-extra.log
```

O primeiro reutiliza os controles da rodada 5 com base `6b06205`: sombras por
`values`, `lateral` e `unnest` **com alias**, qualificadores externos vazios e
posições internas de outra relação continuam acusados. As duas tuplas válidas,
inclusive com posições invertidas, continuam aceitas. O segundo extrai por AST
as 69 contraprovas declaradas em `6b06205` e compara as duas guardas com o
resultado esperado de cada uma. Não houve divergência nem exceção de execução.
Trecho literal de sua saída:

```text
VERSAO sqlglot= 30.18.0
CONTRAPROVAS_BASE total= 69 divergencias= []
VIEW average_order_value_by_channel_and_segment 6b06205= [] HEAD= []
VIEW cart_conversion_rate_by_channel 6b06205= [] HEAD= []
VIEW discount_share_by_channel 6b06205= [] HEAD= []
VIEW gross_margin_by_category 6b06205= [] HEAD= []
VIEW inventory_turnover_by_sku_and_warehouse 6b06205= [] HEAD= []
VIEW monthly_revenue_by_channel_and_category 6b06205= [] HEAD= []
VIEW new_and_repeat_customers_by_month 6b06205= [] HEAD= []
VIEW on_time_delivery_rate_by_carrier 6b06205= [] HEAD= []
VIEW order_to_delivery_time_by_region 6b06205= [] HEAD= []
VIEW payment_approval_rate_by_method 6b06205= [] HEAD= []
VIEW refund_rate_by_reason 6b06205= [] HEAD= []
VIEW repeat_purchase_rate_after_support 6b06205= [] HEAD= []
VIEW revenue_by_delivery_region 6b06205= [] HEAD= []
VIEW skus_below_reorder_point 6b06205= [] HEAD= []
VIEW support_tickets_per_hundred_orders 6b06205= [] HEAD= []
VIEW top_skus_by_revenue 6b06205= [] HEAD= []
```

O controle de P12 substitui `_origem_fixa_por_fonte` somente em memória por uma
função que retorna `set()`. Saída literal do primeiro comando:

```text
P12= skus_below_reorder_point.sql
P12 ligacoes(s)= ['retail.inventory_movements_stream AS s']
P12 sem excecao= ["junção sem a origem: f.source_system = 'retail' AND f.movement_id = s.movement_id"]
```

Li a implementação instalada de `normalize_identifiers` e de
`Dialect.normalize_identifier`: o percurso normaliza nós `Identifier`; no
dialeto escolhido, preserva os delimitados por aspas. A sonda compara os valores
dos nós antes/depois, com asserts sobre todos os literais e identificadores do
exemplo abaixo:

```sql
select A.ORDER_ID, "A"."ORDER_ID", A.SOURCE_SYSTEM,
       "source_system", "SOURCE_SYSTEM", 'Retail', 'retail',
       'LEGACY', 'legacy', 'SOURCE_SYSTEM', 37, 'retail'::text
from RETAIL.ORDERS A
```

Saída literal pertinente:

```text
NORMALIZE identifiers_before= [('ORDER_ID', False), ('A', False), ('ORDER_ID', True), ('A', True), ('SOURCE_SYSTEM', False), ('A', False), ('source_system', True), ('SOURCE_SYSTEM', True), ('ORDERS', False), ('RETAIL', False), ('A', False)]
NORMALIZE identifiers_after= [('order_id', False), ('a', False), ('ORDER_ID', True), ('A', True), ('source_system', False), ('a', False), ('source_system', True), ('SOURCE_SYSTEM', True), ('orders', False), ('retail', False), ('a', False)]
NORMALIZE literals_before=after= [('Retail', True), ('retail', True), ('LEGACY', True), ('legacy', True), ('SOURCE_SYSTEM', True), ('37', False), ('retail', True)]
P12 source db before= [('retail', 'inventory_movements_stream', 's')] after= [('retail', 'inventory_movements_stream', 's')]
```

Os controles de comportamento no mesmo script confirmam: `Retail` e `retail`
como **literais** continuam distintos, assim como `legacy` e `retail`;
`'retail'::text` continua aceito. A coluna `SOURCE_SYSTEM` sem aspas passa a ser
reconhecida, mas `"SOURCE_SYSTEM"` não ganha o significado de `source_system`.
O schema `RETAIL` sem aspas normaliza para `retail`, enquanto `"RETAIL"` continua
fora de `_ORIGENS`; `"retail"` continua aceito. O literal `'RETAIL'` não passa a
casar com a fonte `retail`. A substituição de `source('retail', …)` preserva o
`Table.db` de P12. Essas diferenças removem falsos positivos anteriores, sem
apagar um alerta correto nos casos verificados.

Outros trechos literais do mesmo comando:

```text
CONTROL join_schema 6b06205= [] HEAD= ['junção sem a origem: trusted.orders.order_id = a.order_id AND trusted.orders.source_system = a.source_system']
CONTROL in_catalog 6b06205= [] HEAD= ['in (subconsulta) sem a origem: order_id']
CONTROL in_inner_id_safe 6b06205= [] HEAD= []
CONTROL in_inner_id_scalar 6b06205= [] HEAD= ['in (subconsulta) sem a origem: order_id']
```

### C — docstrings: limite da recusa de relações sem nome

Confrontei as docstrings com o fluxo: qualificação longa é recusada nas provas
de igualdade e `IN`; todas as posições da tupla participam da prova; expansão
qualificada é recusada; nomes delimitados são preservados. A divergência
encontrada é a generalização de `_relacao_sem_nome`, também incorporada ao
limite declarado no início do módulo. SQL passado às duas guardas:

```sql
select * from retail.orders unnest where exists (
  select 1 from (a x join unnest(array[json_populate_record(
    null::trusted.orders, '{"source_system":"legacy","order_id":37}')])
  on x.order_id=unnest.order_id and x.source_system='retail')
)
```

Saída literal de `/tmp/rvl2-round7-extra.py`:

```text
UNNEST 6b06205= [] HEAD= []
UNNEST ast= [('Table', 'orders', 'unnest'), ('TableAlias', 'unnest', ''), ('Table', 'a', 'x'), ('TableAlias', 'x', ''), ('Unnest', '', '')]
UNNEST relacao_sem_nome= False
UNNEST ligacoes= ['retail.orders AS unnest']
UNNEST origem= ['retail']
```

`Unnest` não é `Table` e não tem `TableAlias` neste caso. Seu nome implícito no
PostgreSQL oculta o alias externo, mas a guarda empresta a origem externa. Para
validar a resolução, usei o mesmo procedimento de B/C da rodada 6: substituí
somente `retail.orders unnest` por
`(values ('retail',37)) unnest(source_system,order_id)` e antepus
`with a(source_system,order_id) as (values ('retail',37))`. A função constrói um
registro sintético usando o tipo composto já existente de `trusted.orders`;
não cria tipo, tabela ou dado. O controle acrescenta
`and x.source_system=unnest.source_system` ao `ON`.

Comando com código 0:

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 \
  /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh \
  /tmp/rvl2-round7-unnest.sql > /tmp/rvl2-round7-unnest.log 2>&1
```

Saída pertinente, preservando valores e contagens:

```text
 default_transaction_read_only
-------------------------------
 on
(1 row)

unnest_implicit
 source_system | order_id
---------------+----------
 retail        |       37
(1 row)

unnest_origin_control
 source_system | order_id
---------------+----------
(0 rows)
```

O caso original `json_to_record` está corrigido. O que não se sustenta é a nova
promessa geral: «nenhuma relação ficou sem nome legível» e «a função no `from`
sem alias […] a exceção não vale para a consulta». Pelo escopo fixado pelo Owner,
é suficiente corrigir essa descrição e registrar o limite preexistente; este
parecer não exige implementar resolução geral de funções ou de escopos.

### D — gates, preservação e alcance do parecer

Executados antes de acrescentar este parecer, ambos com código 0:

```bash
PYTHONDONTWRITEBYTECODE=1 make check-offline > /tmp/rvl2-round7-check-offline.log 2>&1
PYTHONDONTWRITEBYTECODE=1 make secrets-history > /tmp/rvl2-round7-secrets-history.log 2>&1
```

Saídas literais pertinentes, omitindo progresso e inventário de integração:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
816 passed, 188 deselected in 145.52s (0:02:25)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram

revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Reproduzida a contagem do autor. A execução das 16 views nesta rodada significa
a aplicação da **guarda ao SQL de cada modelo**, não execução das views no
armazém ou recálculo de métricas. Não executei integração, build, rebuild,
`governance garantir`, reset, seed, sync, DAG, ledger ou recuperação. Não subi
nem pausei serviços ou `fluxo_batch`. A única sonda de banco foi a leitura de C,
com `default_transaction_read_only=on`; não escrevi no armazém nem em
`data/memoria_do_legado/`. Não fiz inventário completo de estado antes/depois.

Somente `REVISAO.md` foi editado como entrega no repositório. Scripts e logs
ficaram em `/tmp/rvl2-round7-*`. Os não rastreados `GEMINI.md` e
`NAVEGANDO_GCP/parecer_migracao_gcp.md` já existiam e não foram tocados.
As verificações não constituem prova exaustiva de todas as construções SQL;
o único ponto aberto nas quatro categorias desta rodada é RVL2-7-01.

### Limites remanescentes da abordagem sintática

- Nome implícito de `unnest` sem alias não participa da contagem de ligações nem da recusa global de relação sem nome (`6b06205=[]`, `HEAD=[]`): `select * from retail.orders unnest where exists (select 1 from (a x join unnest(array[json_populate_record(null::trusted.orders, '{"source_system":"legacy","order_id":37}')]) on x.order_id=unnest.order_id and x.source_system='retail'))`.
