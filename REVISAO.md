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
