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
| | | | `bloqueante` · `ajuste` · `observação` | |

