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

