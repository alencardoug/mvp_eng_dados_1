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

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

