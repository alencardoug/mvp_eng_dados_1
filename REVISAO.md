# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `a4b04fc..1393b5c` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
96c7a9f feat: make check-offline confere o que não precisa de nada de pé
6802d12 feat: make install instala os pacotes dbt da trava
561edc2 docs: põe a Execução Local em condição de roteiro do B5
01eaede docs: registra D57 e D58, decididas para o roteiro do B5
8ecdcb6 docs: reescreve o B5 do plano como roteiro executável
9f1ce79 docs: corrige o roteiro do B5 pelo ensaio do preparo do clone
c9435d2 feat: make check lista os pulados com motivo
d4ae75b docs: o roteiro do B5 dá o comando de cada oráculo
1393b5c docs: o candidato do B5 é refeito depois da revisão do roteiro
```

**Primeira rodada sobre o B5: o roteiro e o preparo dele, juntos.** A revisão da entrega B0/B1/B4
fechou em `a4b04fc` — seis rodadas, 26 achados; o dossiê das três últimas está em
`git show a001887:REVISAO.md`. Este intervalo traz, na ordem que o Owner aprovou em 24/09/2026:

1. o preparo que o plano já tinha decidido e faltava construir — `make check-offline` (`96c7a9f`) e
   `dbt deps` no `make install` (`6802d12`) —, e um terceiro, achado ao preencher este dossiê: o
   `make check` passa a listar os pulados com motivo (`c9435d2`), como o Termo pede no §7.6;
2. a Execução Local em condição de roteiro (`561edc2`): §2 o preparo, §3 o ciclo na ordem do B5, §4
   os alvos da Etapa 12;
3. o candidato do pacote de recuperação refeito com esse código — fora do Git, em
   `data/recovery/candidato`, com `commit` `561edc2` no manifesto; ele é refeito de novo depois
   desta revisão, com a ponta revisada (P4, `1393b5c`);
4. D57 e D58, decididas pelo Owner para o roteiro (`01eaede`; texto nas Pendências §2);
5. o roteiro — a revisão 8 do §7 do `PLANO_etapa_12.md` (`8ecdcb6`);
6. o ensaio do preparo do clone, sem subir nada, e o que ele corrigiu no roteiro (`9f1ce79`); e o
   comando de cada oráculo que só nomeava uma saída (`d4ae75b`).

**O que se pede desta rodada é o que o diff não mostra: o roteiro é executável como está escrito?**
Cada linha tem diretório, comando e oráculo. A pergunta é se o comando faz o que o oráculo diz, se a
ordem é a certa, se falta passo e se os pontos de parada seguram. O B5 derruba tudo o que existe: um
defeito no §7.1 custa a memória do armazém, e o recuo é o pacote (§7.4). A §8 traz as saídas do
ensaio, e a §9, a sonda da seleção offline, com o código.

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 8 arquivos

- `Makefile`
- `PLANO_etapa_12.md`
- `README.md`
- `docs/execucao_local.md`
- `docs/pendencias.md`
- `tests/test_consumo.py`
- `tests/test_legacy_classification.py`
- `tests/test_makefile.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega.** Não há derivado no intervalo. Pedem revisão integral:

- **`PLANO_etapa_12.md` §7** — o roteiro: 7.0, as pré-condições P1–P7 e o diário; 7.1, o desmonte, no
  *checkout* antigo; 7.2, o clone (D58), com `RECOVERY_DIR` no *shell*; 7.3, o ciclo em nove linhas,
  cada uma sob `make medir`; 7.4, as paradas e o recuo; 7.6, os critérios do Termo mapeados. É a
  declaração principal: o B5 executa o que está escrito ali, e só isso;
- **`Makefile`** — `check-offline` (três etapas; `MVP_TESTE_FATO=0`; `-m "not integracao"`; a
  listagem do que ficou de fora), a linha do `dbt deps` no `install` e o `-rs` do `test`;
- **as marcas `integracao`** — `tests/test_consumo.py` inteiro, por `pytestmark`, e dois testes de
  `tests/test_legacy_classification.py`: são a declaração do que o `check-offline` deixa de fora;
- **`docs/execucao_local.md` §2–§4** — a base que o roteiro cita e não repete;
- **`docs/pendencias.md` §2** — o texto da D57 e da D58.

Os oráculos estão em `tests/test_makefile.py` — `test_check_offline_nao_sobe_nem_consulta_nada`,
`test_o_que_precisa_do_armazem_fica_fora_do_check_offline` (a lista `PRECISAM_DO_ARMAZEM`),
`test_install_traz_os_pacotes_dbt_da_trava` e `test_o_pytest_do_check_lista_os_pulados_com_motivo`
—, e vale conferir se provam o que dizem. O `README.md` muda uma linha de versão.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:227: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:272: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:778: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:794: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
567 passed, 8 skipped in 259.20s (0:04:19)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

### Medições desta entrega, além do `comandos.txt`

O `make check` acima já roda com o `-rs` de `c9435d2` — daí os `SKIPPED` com motivo. O recorte de
12 linhas do dossiê corta o oitavo, que está na lista completa logo abaixo. O ensaio do preparo do
clone e a sonda da seleção offline têm seções próprias, com as saídas literais: §8 e §9.

**O `-rs` do `make test`, vermelho sem o conserto e verde com ele.** O `Makefile` guardado por
`git stash push Makefile`, o teste novo presente:

```
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_makefile.py -k pulados_com_motivo 2>&1 \
    | grep -E 'assert|passed|failed' | tail -3                                  # sem o -rs
>       assert chamadas == ["pytest -q -rs"], chamadas
E       assert ['pytest -q'] == ['pytest -q -rs']
1 failed, 82 deselected in 0.30s
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_makefile.py 2>&1 | tail -1    # com ele
83 passed in 10.53s
```

**Os pulados do `make test`, completos**, na ponta `1393b5c`, logo depois do `make check` acima
(`make test | grep -E '^SKIPPED|passed|failed|error'`):

```
SKIPPED [1] tests/test_carga.py:51: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:227: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:272: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:778: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:794: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
567 passed, 8 skipped in 258.15s (0:04:18)
```

Os seis de `test_legado_deteccao.py` pulam pelo estado do *checkout* antigo, como o motivo diz: a
captura 43 não é o lote do manifesto, e duas tabelas divergem. Os outros dois pedem autorização à
parte, por desenho: `test_carga.py`, o `make test-carga` num banco efêmero; `test_fato_incremental.py`,
o `FATO=1`. O que se espera deles no B5 está na §4.

**Os oráculos que o roteiro passou a citar pelo comando** (`d4ae75b`), medidos no *checkout* antigo.
O `migrate-legacy-status` aparece em duas pontas; o meio são as linhas `INFO` do Alembic:

```
$ make migrate-status
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
Current revision(s) for postgresql+psycopg://mvp_source:***@localhost:5432/source_db:
Rev: deae0e5943e0 (head)
Parent: <base>
$ make migrate-legacy-status
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
Current revision(s) for postgresql+psycopg://mvp_legacy:***@localhost:5433/legacy_db:
Rev: f558a05ce90e (head)
[…]
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.checkconstraint_byname
No new upgrade operations detected.
$ set -a; . ./.env; set +a; timeout 60 .venv/bin/python -m mvp_ed1.governance versoes
0001_legacy_captures
0002_snapshot_id_e_o_job
```

O `make catalog`, sobre o *manifest* do `make check` do primeiro dossiê desta rodada (o de
`9f1ce79`, refeito depois; o código do catálogo não mudou entre os dois):

```
$ git status --short
?? REVISAO.md
$ time (make --no-print-directory catalog 2>&1 | tail -6)
  40 tabelas e 418 campos classificados
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) escrito(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário já em dia

real	0m44,028s
$ git status --short
?? REVISAO.md
```

A porta do `dbt docs serve`, no código instalado, e o que o clone ignora:

```
$ grep -n -B1 -A6 '^port = ' .venv/lib/python3.11/site-packages/dbt/cli/params.py
519:port = _create_option_and_track_env_var(
520-    "--port",
521-    envvar=None,
522-    help="Specify the port number for the docs server",
523-    default=8080,
524-    type=click.INT,
525-)
$ git check-ignore -v data/medicoes/diario_b5.md .env dbt/target/manifest.json dbt/dbt_packages dbt/logs
.gitignore:25:data/	data/medicoes/diario_b5.md
.gitignore:13:.env	.env
.gitignore:51:dbt/target/	dbt/target/manifest.json
.gitignore:52:dbt/dbt_packages/	dbt/dbt_packages
.gitignore:53:dbt/logs/	dbt/logs
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **Nada do §7.1 rodou, e nada do §7.3.** O desmonte é destrutivo por desenho, e o ciclo é o
  próprio B5, que espera a autorização do Owner (P6). Cada comando deles foi lido contra o
  `Makefile` e a Execução Local, não executado nesta entrega — inclusive o `make stream-down
  FORCE=1` removendo os *slots* com o `source_db` antigo de pé (RV12-03), o `make airbyte-down`
  seguido do `mv` do diretório de dados, o `make reset` com a confirmação interativa e o `docker
  network rm mvp_ed1_default`.
- **O inventário da linha 7 do §7.1 não enxerga volume anônimo.** O nó do `kind` monta um volume
  anônimo em `/var` — hoje `7750351f…`, visto por `docker inspect airbyte-abctl-control-plane` —, e
  `docker volume ls` filtrado por nome não o mostra. Que ele sai junto com o nó é premissa (§5).
- **O `git clone` de `origin`.** O ensaio clonou o repositório local: os *commits* do roteiro não
  estavam publicados. O `HEAD` do clone era `8ecdcb6`. O que veio depois não toca as linhas 1–5 do
  §7.2: `9f1ce79`, `d4ae75b` e `1393b5c` são texto do plano, e o `-rs` de `c9435d2` é do `make test`,
  que o `check-offline` não chama — medido à parte (§3).
- **O `check-offline` com nada de pé.** O ensaio rodou com os três bancos antigos e o Airbyte de pé;
  o B5 roda a linha 5 depois do `make reset`. O que ele prova — nenhuma tentativa de conexão, com um
  controle positivo mostrando que haveria rastro (§8.6) — vale nos dois casos. Não se viu a reação
  de um teste a "connection refused" em vez de senha recusada: nenhum teste da seleção tentou.
- **O `recovery-verify` do ensaio listou os dumps no contêiner do armazém antigo** — o nome de
  projeto do clone é o mesmo, `mvp_ed1` (§8.7). No B5, na linha 9, o contêiner já será o do clone. O
  `recovery-verify CONTRA_O_BANCO=1` não rodou no clone.
- **`RESTAURAR=1` pelo ambiente, através do `make medir`.** A linha 9 escreve
  `RESTAURAR=1 make medir ALVO=recovery-restore`: o `medir.sh` chama `make` sem limpar o ambiente, e o
  `make` lê variável de ambiente como `$(RESTAURAR)` — o mesmo mecanismo que o ensaio mediu com
  `RECOVERY_DIR` (§8.1). Não rodou pelo `medir`: passar da guarda é restaurar.
- **Os pulados que o `check` do B5 vai mostrar.** O roteiro pede cada pulado e o motivo nas linhas 4
  e 9, mas não diz quais são aceitáveis. Para a linha 4, a expectativa — os seis de
  `test_legado_deteccao.py` rodando sobre o legado recém-gerado e capturado pela primeira vez — é
  inferência, não medida. Para a linha 9, sobre o legado restaurado, nem expectativa há: depende de o
  conteúdo restaurado ser o lote do manifesto do pacote, do qual a captura 43 de hoje diverge em
  duas tabelas.
- **`make dbt-docs` servindo.** A 8080 é a porta padrão do `dbt docs serve`, lida no código instalado
  (§3); o servidor não subiu nesta entrega. Ele também tenta abrir um navegador, porque `--browser` é
  o padrão.
- **O `make catalog` sem diferença foi medido no *checkout* antigo.** No clone, sobre um armazém
  regerado, o oráculo é o mesmo, e a medida é a do B5.
- **Os números da P7 e o tempo de ~2 h** continuam [planejado] ou derivados, como o roteiro marca; o
  `LIMITE=200` da linha 6 é parâmetro, não medida.
- **B2 e B3** continuam para a revisão final, depois de B6, por decisão do Owner.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **`make airbyte-down` remove o nó do `kind` e o volume anônimo dele.** O `kind` apaga os nós com
  `docker rm -f -v` — pelo código dele, não por medida nesta entrega. E **a rede `kind` fica e é
  reaproveitada** pela instalação nova: a linha 2 do §7.3 confere.
- **Apartar `~/.airbyte/abctl/data` basta para a instalação limpa.** É o remédio documentado da
  armadilha do `PG_VERSION` (Execução Local §6); não foi aplicado nesta entrega.
- **O `make install` de 10 s veio do cache do `uv` desta máquina.** Num cache frio, os 93 pacotes
  baixam. O B5 roda na mesma máquina.
- **O `make tools` baixa de GitHub e da HashiCorp**, por URL com versão fixa: funcionou em 24/09/2026,
  em 5 s.
- **O clone de `origin` traz o mesmo que o clone local.** Credenciais e rede do GitHub são do Owner.
- **O *checkout* antigo continua legível durante todo o B5.** `RECOVERY_DIR` aponta para ele, e só
  depois do `make recovery-promote` o Owner decide arquivá-lo (§7.5).
- **As portas do `.env` novo são as de sempre.** O `make env` gera senhas; o ensaio mostrou o clone
  batendo nos bancos antigos pelas mesmas portas (§8.6).
- **`docker events --since` lê um buffer que roda.** A consulta feita logo ao fim do ensaio viu a
  janela inteira (243 eventos: 27 verificações de saúde por banco, uma a cada ~5 s); a mesma janela,
  consultada de novo um minuto depois, já perdera o começo (§8.5). O oráculo vale feito na hora.

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

**Esta revisão não precisa de nada além do mínimo.** O roteiro se revisa lendo, e as sondas que
dá para fazer sem executar o B5 rodam com o que está de pé. **O estado em que a entrega foi
deixada:**

- **os três bancos de pé**, com o armazém do `make check` deste dossiê. O candidato em
  `data/recovery/candidato` confere contra eles (`make recovery-verify CONTRA_O_BANCO=1`, só
  leitura);
- **Airbyte de pé e ocioso**, contador de *jobs* em 43 (`docker/airbyte_jobs.sh ler`, só leitura);
- **Airflow pausado** — contêineres `Exited`, volumes preservados —; **streaming ausente**, sem
  volume de tópicos nem *slot* de replicação; **a rede `mvp_ed1_default`**, externa;
- **memória:** ~4,8 GB livres (`MemAvailable`) com o Airbyte de pé. **Não force** se o preflight
  recusar (`CLAUDE.md` §5).

**Para ensaiar o §7.2 como a §8 fez:** `git clone` de `origin` para um diretório fora deste
*checkout*, `make env`, `export RECOVERY_DIR=/home/doug/Projetos/mvp_ed1/data/recovery`, `make
install`, `make tools` e `make check-offline`. Com os bancos antigos de pé nas mesmas portas, as
senhas novas do clone fazem qualquer acesso aparecer no *log* deles (§8.6). O clone pesa ~1 GB, com
`.venv` e `.tools`; apague-o ao fim.

**Nunca, nesta revisão:** nada do §7.1 ou do §7.3 — `*-down`, `make reset`, `docker network rm`,
`recovery-restore`, `seed-*` são o B5, que espera a autorização do Owner. **E, num clone, nenhum
alvo que suba contêiner:** o nome de projeto do clone é o mesmo, `mvp_ed1` (§8.7), e ele assumiria os
contêineres e os volumes do *checkout* antigo com as senhas novas. Leituras sem efeito:
`make preflight ALVO=trabalho`, `make recovery-verify` (lista os dumps por `docker exec …
pg_restore --list`), `make migrate-status` e `make migrate-legacy-status`.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **O roteiro no plano, e não na Execução Local.** A Execução Local é o dono permanente de como se
  executa; o §7 do plano é o dono transitório do B5. O roteiro cita a Execução Local e acrescenta só
  o que é do B5 — o desmonte, o clone, os oráculos, as paradas. Pô-lo na Execução Local deixaria num
  documento permanente um procedimento que roda uma vez.
- **`RECOVERY_DIR` no *shell*, e não um `include .env` no `Makefile`.** Mudar como o `Makefile` lê o
  `.env` mexe em todo alvo, a uma revisão do B5, e o `RESTAURAR.md` do próprio pacote já manda
  `export`. O custo é uma linha que o Owner precisa lembrar no *shell* do clone — e todo alvo
  `recovery-*` imprime o valor que viu, que é o oráculo da linha 2 do §7.2.
- **O ensaio rodou `make recovery-verify`, além das linhas 1–5**, para medir esse oráculo com um alvo
  de verdade. Ele entrou no contêiner do armazém antigo por `docker exec`, só para listar os dumps.
- **O ensaio clonou para dentro do `.git/` do *checkout* antigo**, e não para um diretório irmão:
  fica fora do *git* dele e saiu inteiro ao fim. Não é o caminho que o Owner vai usar;
  as ferramentas que olham arquivos (`secrets_review`, `docs_check`) partem de `git ls-files`, e o
  caminho não as afeta.
- **Cinco pulados como oráculo da linha 5**, em vez de tornar os quatro de `test_linhagem.py`
  independentes do *manifest*: eles medem o *manifest* real, pular sem `dbt-build` é o desenho, e
  eles rodam no `make check` da linha 4, quando o *manifest* existe.
- **O `-rs` entrou no `make test`**, e não numa linha só do `check`: o `make test` é o que o `check`
  chama, e um pulado sem motivo esconde o mesmo tanto num e noutro.
- **O candidato não foi refeito agora**, com o `-rs` já depois dele: a revisão pode trazer mais
  código, e refazê-lo duas vezes não acrescenta nada. A P4 manda refazê-lo uma vez, com a ponta
  revisada.
- **A cópia da P5 no `~`**, e não num disco à parte: protege do `make reset` e de um `rm` no
  *checkout*, não da perda do disco. O Owner pode escolher outro lugar.
- **O `docker network rm` do desmonte é à mão (D57, do Owner)**, e não um alvo: nenhum `*-down` remove
  a rede (D55), e um alvo para uma execução única seria código sem segundo uso.

## 8. O ensaio do preparo do clone — 24/09/2026, sem subir nada

As linhas 1–5 do §7.2 e a P5, num clone do `HEAD` local (`8ecdcb6`) em `.git/ensaio-b5`, com os
três bancos antigos e o Airbyte de pé nas mesmas portas. O clone e o `make env` rodaram à mão, às
23:50Z; o resto, pelo roteiro abaixo, de 23:55:31Z a 23:57:51Z. `<tmp>` é o diretório de rascunho da
sessão; `<clone>`, o `.git/ensaio-b5`. O clone e a cópia foram apagados ao fim.

```bash
#!/usr/bin/env bash
# Ensaio da preparação do clone — PLANO_etapa_12.md §7.2 e a P5 do §7.0 —, sem subir nada.
# O clone e o `make env` já rodaram; aqui, do `export RECOVERY_DIR` em diante, no ambiente
# que o roteiro manda: o do shell do clone, com RECOVERY_DIR exportado.
set -u
R=/home/doug/Projetos/mvp_ed1
C=$R/.git/ensaio-b5
O=$R/.git/ensaio-b5-saidas
T=<tmp>
CORTE=20260924T234304Z
export RECOVERY_DIR=$R/data/recovery

marca=$T/marca-inicio
touch "$marca"
inicio=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "$inicio" > "$O/0_inicio.txt"

estado() {
	{
		echo "## contêineres"; docker ps -a --format '{{.Names}}\t{{.Status}}' | sort
		echo "## volumes do projeto e do Airbyte"; docker volume ls --format '{{.Name}}' | grep -E 'mvp_ed1|airbyte' | sort
		echo "## redes"; docker network ls --format '{{.Name}}' | sort
		echo "## git status do checkout antigo"; git -C "$R" status --porcelain; echo "(fim)"
		echo "## memória"; grep MemAvailable /proc/meminfo
	} > "$O/$1" 2>&1
}

cronometrar() {
	local arquivo=$1; shift
	local t0; t0=$(date +%s)
	{ echo "\$ $*"; "$@"; echo "saida=$? duracao=$(( $(date +%s) - t0 ))s"; } > "$O/$arquivo" 2>&1
}

estado 0_estado_antes.txt

# P5 — a cópia fora do repositório, antes de qualquer outra coisa: é também o
# seguro do ensaio, que roda com RECOVERY_DIR apontando para o candidato.
{
	echo "\$ cp -a data/recovery/candidato <tmp>/mvp_ed1-candidato-$CORTE"
	(cd "$R" && cp -a data/recovery/candidato "$T/mvp_ed1-candidato-$CORTE"); echo "saida=$?"
	echo "\$ cd <tmp>/mvp_ed1-candidato-$CORTE && sha256sum -c checksums.sha256"
	(cd "$T/mvp_ed1-candidato-$CORTE" && sha256sum -c checksums.sha256); echo "saida=$?"
	du -sh --apparent-size "$T/mvp_ed1-candidato-$CORTE"
} > "$O/1_p5_copia.txt" 2>&1

cd "$C" || exit 1
cronometrar 3_install.txt make install
cronometrar 4_tools.txt make tools
cronometrar 5_check_offline.txt make check-offline
cronometrar 6_recovery_verify.txt make recovery-verify
fim=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "$fim" > "$O/9_fim.txt"

estado 9_estado_depois.txt

# Os eventos do Docker na janela do ensaio: o que é verificação de saúde fica
# contado à parte; o que não é aparece por linha.
docker events --since "$inicio" --until "$fim" \
	--format '{{.Type}}|{{.Action}}|{{.Actor.Attributes.name}}' > "$T/eventos.txt" 2>&1
{
	echo "janela: $inicio → $fim"
	echo "## eventos de verificação de saúde (pg_isready, health_status), por contêiner"
	grep -E 'pg_isready|health_status' "$T/eventos.txt" | awk -F'|' '{print $3}' | sort | uniq -c
	echo "## exec_die sem comando (o par de cada exec, saúde incluída), por contêiner"
	grep -E '\|exec_die\|' "$T/eventos.txt" | awk -F'|' '{print $3}' | sort | uniq -c
	echo "## todo o resto"
	grep -v -E 'pg_isready|health_status|\|exec_die\|' "$T/eventos.txt" || echo "(nenhum)"
} > "$O/9_eventos.txt"

# Acesso a banco com as credenciais do clone falharia: as senhas são novas.
{
	for banco in source_db legacy_db warehouse_db; do
		echo "## mvp_ed1_$banco desde $inicio"
		linhas=$(docker logs --since "$inicio" "mvp_ed1_$banco" 2>&1 | grep -E 'FATAL|authentication' | sort | uniq -c)
		echo "${linhas:-(nada)}"
	done
} > "$O/9_logs_dos_bancos.txt"

# O candidato continua íntegro e intocado.
{
	echo "\$ cd data/recovery/candidato && sha256sum -c --quiet checksums.sha256"
	(cd "$R/data/recovery/candidato" && sha256sum -c --quiet checksums.sha256); echo "saida=$?"
	echo "\$ find data/recovery -newer <marca do início>"
	find "$R/data/recovery" -newer "$marca" -print; echo "(fim)"
} > "$O/9_candidato.txt" 2>&1

echo "ensaio terminado"
```

### 8.1 O clone, o `make env` e o `RECOVERY_DIR`

```
$ git clone /home/doug/Projetos/mvp_ed1 <clone>
saida=0 HEAD=8ecdcb6 docs: reescreve o B5 do plano como roteiro executável
$ make env
'.env' criado com senhas aleatórias e permissão 600.
saida=0 permissão do .env: 600
$ export RECOVERY_DIR=/home/doug/Projetos/mvp_ed1/data/recovery
valor que o make do clone vê: /home/doug/Projetos/mvp_ed1/data/recovery
```

O valor foi lido por um alvo passado por `--eval`, com `RECOVERY_DIR` no ambiente:
`RECOVERY_DIR=… make -C <clone> --eval 'mostra: ; @echo $(RECOVERY_DIR)' mostra`.

### 8.2 A cópia da P5

```
$ cp -a data/recovery/candidato <tmp>/mvp_ed1-candidato-20260924T234304Z
saida=0
$ cd <tmp>/mvp_ed1-candidato-20260924T234304Z && sha256sum -c checksums.sha256
.stream/producer_state.json: SUCESSO
RESTAURAR.md: SUCESSO
data/legacy/manifesto-3f9e5088c72234045351b251d406ce9e.json: SUCESSO
data/legacy/manifesto-anterior-20260907-sem-hash.json: SUCESSO
data/legacy/manifesto.json: SUCESSO
legacy_db.dump: SUCESSO
manifesto.json: SUCESSO
source_db.dump: SUCESSO
warehouse_memoria.dump: SUCESSO
saida=0
32M	<tmp>/mvp_ed1-candidato-20260924T234304Z
```

### 8.3 `make install` e `make tools`

As 93 linhas `+ pacote==versão` do `uv sync` foram tiradas; a trava é o `uv.lock`.

```
$ make install
uv sync
Using CPython 3.11.15
Creating virtual environment at: .venv
Resolved 93 packages in 1ms
   Building mvp-eng-dados-1 @ file:///home/doug/Projetos/mvp_ed1/.git/ensaio-b5
      Built mvp-eng-dados-1 @ file:///home/doug/Projetos/mvp_ed1/.git/ensaio-b5
Prepared 1 package in 849ms
Installed 93 packages in 431ms
cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt deps
23:55:37  Running with dbt=1.12.3
23:55:39  Installing dbt-labs/dbt_utils
23:55:39  Installed from version 1.4.1
23:55:39  Up to date!
23:55:39  Installing metaplane/dbt_expectations
23:55:40  Installed from version 0.10.10
23:55:40  Up to date!
23:55:40  Installing godatadriven/dbt_date
23:55:40  Installed from version 0.21.0
23:55:40  Up to date!

Ambiente pronto. O 'uv.lock' e o 'dbt/package-lock.yml' são as travas — versione-os.
mvp_ed1 0.1.0 sobre Python 3.11.15
saida=0 duracao=10s
```

```
$ make tools
baixando abctl v0.30.4
baixando Terraform 1.16.1
version: v0.30.4
Terraform v1.16.1
saida=0 duracao=5s
```

### 8.4 `make check-offline`

```
$ make check-offline
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 106 documentos, 981 links de arquivo, 137 âncoras, 588 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
...s.................................................................... [ 16%]
................................................................ssss.... [ 32%]
........................................................................ [ 49%]
........................................................................ [ 65%]
........................................................................ [ 81%]
........................................................................ [ 98%]
........                                                                 [100%]
=========================== short test summary info ============================
SKIPPED [1] tests/test_acesso_macro.py:105: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:120: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:133: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:155: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_linhagem.py:166: sem dbt/target/manifest.json; rode `make dbt-build`
435 passed, 5 skipped, 134 deselected in 112.26s (0:01:52)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
      7 tests/test_acesso.py
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
saida=0 duracao=122s
```

### 8.5 Os eventos do Docker na janela

```
Eventos do Docker na janela do ensaio, em duas consultas.

`docker events --since` lê o buffer de eventos recentes do daemon, que roda: a mesma
janela, consultada de novo um minuto depois, já devolvia 38/36/36 eventos de saúde por
banco em vez de 54/54/54. Por isso, a primeira consulta (a do roteiro, feita logo ao fim)
vale até 23:57:49Z, e a cauda, que ela cortava por arredondar o fim ao segundo, veio de
uma segunda consulta, feita em seguida.

── 1. 2026-09-24T23:55:31Z → 23:57:49Z, consultada ao fim do ensaio (243 eventos) ──
## eventos de verificação de saúde (pg_isready, health_status), por contêiner
     54 mvp_ed1_legacy_db
     54 mvp_ed1_source_db
     54 mvp_ed1_warehouse_db
## exec_die sem comando (o par de cada exec, saúde incluída), por contêiner
     27 mvp_ed1_legacy_db
     27 mvp_ed1_source_db
     27 mvp_ed1_warehouse_db
## todo o resto
(nenhum)

── 2. 23:57:49Z → 23:57:51Z, a cauda (o recovery-verify rodou em 23:57:49.296–.532) ──
      3 container|exec_create: pg_restore --list|mvp_ed1_warehouse_db
      3 container|exec_die|mvp_ed1_warehouse_db
      3 container|exec_start: pg_restore --list|mvp_ed1_warehouse_db
## verificação de saúde na cauda
4
```

A segunda consulta:
`docker events --since 2026-09-24T23:57:49Z --until 2026-09-24T23:57:51Z --format
'{{.Type}}|{{.Action}}|{{.Actor.Attributes.name}}'`.

### 8.6 Os *logs* dos bancos, e o controle positivo

```
## mvp_ed1_source_db desde 2026-09-24T23:55:31Z
(nada)
## mvp_ed1_legacy_db desde 2026-09-24T23:55:31Z
(nada)
## mvp_ed1_warehouse_db desde 2026-09-24T23:55:31Z
(nada)
```

```
Controle positivo do oráculo dos logs: uma conexão do host com a senha do clone (errada
para o banco antigo), pelo psycopg do .venv do clone.
$ psycopg.connect(host="localhost", port=5434, dbname=warehouse_db, user=mvp_warehouse, password=<a do .env do clone>)
recusada: OperationalError - host: 'localhost', port: '5434', hostaddr: '127.0.0.1': connection failed: connection to server at "127.0.0.1", port 5
$ docker logs --since <antes> mvp_ed1_warehouse_db | grep -E 'FATAL|DETAIL'
[23249] FATAL:  password authentication failed for user "mvp_warehouse"
[23249] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha-256"
[23250] FATAL:  password authentication failed for user "mvp_warehouse"
[23250] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha-256"
(o `trust` do pg_hba vale só para 127.0.0.1 de dentro do contêiner; do host, a conexão chega pela ponte e cai no scram-sha-256)
```

O comando do controle, com o `.env` do clone carregado:

```python
psycopg.connect(host="localhost", port=u.get("WAREHOUSE_DB_PORT", "5434"),
                dbname=u["WAREHOUSE_DB_NAME"] if "WAREHOUSE_DB_NAME" in u else "warehouse_db",
                user=u.get("WAREHOUSE_DB_USER", "mvp_warehouse"),
                password=u.get("WAREHOUSE_DB_PASSWORD", ""), connect_timeout=5)
```

E o `pg_hba.conf` dos três bancos, igual nos três (`docker exec … grep -v "^#" "$PGDATA/pg_hba.conf"`):

```
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
host all all all scram-sha-256
```

### 8.7 `make recovery-verify`, o projeto do clone e o candidato

```
$ make recovery-verify
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_ed1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0 duracao=1s
```

```
$ docker/conteineres.sh projeto   # no clone, com o .env dele
mvp_ed1
$ docker/conteineres.sh resolver warehouse_db
mvp_ed1_warehouse_db
```

```
$ cd data/recovery/candidato && sha256sum -c --quiet checksums.sha256
saida=0
$ find data/recovery -newer <marca do início>
(fim)
```

### 8.8 O estado antes e depois

A diferença entre `0_estado_antes.txt` e `9_estado_depois.txt` — contêineres, volumes do projeto e do
Airbyte, redes, `git status` do *checkout* antigo e memória:

```
42c42
< MemAvailable:    4937136 kB
---
> MemAvailable:    4915104 kB
```

## 9. A sonda da seleção offline — 24/09/2026, antes das marcas

A que o §7.2 cita, rodada entre 23:32Z e 23:35Z, antes de `96c7a9f`, quando os quatro testes ainda
não tinham a marca. A preparação, numa *worktree* do `HEAD` de então, `a4b04fc`:

```bash
S=.git/sonda-offline; W=.git/ensaio-offline
git worktree add -q --detach $W HEAD && cp .env $W/.env && ln -s "$PWD/.venv" $W/.venv \
  && ln -s "$PWD/.tools" $W/.tools && ln -s "$PWD/dbt/dbt_packages" $W/dbt/dbt_packages
```

**O `ln -s "$PWD/.venv"` é o defeito que o ensaio achou.** A instalação editável do `.venv` aponta
para o `src/` do *checkout* antigo, e o caminho que `mvp_ed1.models.sensitivity` deriva do próprio
`__file__` (`MANIFEST = DBT / "target" / "manifest.json"`) achava o `dbt/target` de lá. Por isso os
quatro de `test_linhagem.py`, que leem `l.MANIFEST`, rodaram na sonda e pulam no clone; o de
`test_acesso_macro.py` deriva o caminho do arquivo de teste e pulou nos dois. A seleção de acessos
vale — quem acessava foi negado e anotado —; a contagem de pulados, não.

O *plugin*, carregado por `-p sonda_offline` com `PYTHONPATH=$S`:

```python
"""Sonda do check-offline: anota e nega o acesso a banco, dbt, docker real e serviço HTTP."""
import json, os, subprocess, pytest

REGISTRO = os.environ["SONDA_REGISTRO"]
_ATUAL = {"no": "(coleta)"}

def anota(tipo, detalhe):
    with open(REGISTRO, "a", encoding="utf-8") as f:
        f.write(json.dumps({"teste": _ATUAL["no"], "tipo": tipo, "detalhe": detalhe[:160]}) + "\n")

@pytest.hookimpl(tryfirst=True)
def pytest_runtest_protocol(item, nextitem):
    _ATUAL["no"] = item.nodeid

import sqlalchemy.engine.base as _base
def _connect(self, *a, **k):
    anota("sqlalchemy", self.url.render_as_string(hide_password=True))
    raise RuntimeError("sonda offline: conexão negada")
_base.Engine.connect = _connect
_base.Engine.raw_connection = _connect
for _mod in ("psycopg", "psycopg2"):
    try:
        _m = __import__(_mod)
        def _pc(*a, _nome=_mod, **k):
            anota(_nome, "connect")
            raise RuntimeError("sonda offline: conexão negada")
        _m.connect = _pc
    except ImportError:
        pass

_orig_init = subprocess.Popen.__init__
def _init(self, args, *a, **k):
    argv = [str(x) for x in (args if isinstance(args, (list, tuple)) else [args])]
    prog = os.path.basename(argv[0]) if argv else ""
    if prog == "dbt" or (prog.startswith("python") and "dbt" in argv[1:3]):
        anota("dbt", " ".join(argv))
        raise FileNotFoundError("sonda offline: dbt negado")
    return _orig_init(self, args, *a, **k)
subprocess.Popen.__init__ = _init

import urllib.request as _ur
_orig_open = _ur.urlopen
SERVICOS = (":8000", ":8081", ":8083", ":19092", ":5432", ":5433", ":5434")
def _urlopen(url, *a, **k):
    alvo = url if isinstance(url, str) else getattr(url, "full_url", str(url))
    if any(p in alvo for p in SERVICOS):
        anota("http", alvo)
        raise OSError("sonda offline: serviço negado")
    return _orig_open(url, *a, **k)
_ur.urlopen = _urlopen
```

Os executáveis à frente do `PATH` — `docker`, `psql`, `pg_dump`, `pg_restore`, `abctl`, `kubectl` —
anotam e recusam; só o `docker` deixa passar `config` e `version`. O de `docker`:

```bash
#!/usr/bin/env bash
case " $* " in *" config "*|*" version "*) [ "docker" = docker ] && exec "/usr/bin/docker" "$@" ;; esac
printf '%s\n' "{\"teste\": \"(subprocesso)\", \"tipo\": \"docker\", \"detalhe\": \"$*\"}" >> "$SONDA_REGISTRO"
echo "sonda offline: docker negado" >&2; exit 97
```

A execução, na *worktree*:

```bash
set -a; . ./.env; set +a; export SONDA_REGISTRO=$S/registro.jsonl PATH="$S/bin:$PATH" PYTHONPATH="$S"
( time .venv/bin/pytest -p sonda_offline -m "not integracao" -q -rfEs --color=no -p no:cacheprovider -p no:randomly 2>&1 ) > $S/saida.txt 2>&1
```

O registro — três acessos, de que dependem quatro testes (a *fixture* `engine` de `test_consumo.py`
é de módulo e serve dois):

```json
{"teste": "tests/test_consumo.py::test_toda_view_de_consumo_responde", "tipo": "sqlalchemy", "detalhe": "postgresql+psycopg://mvp_warehouse:***@localhost:5434/warehouse_db"}
{"teste": "tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao", "tipo": "dbt", "detalhe": ".venv/bin/dbt --quiet compile --project-dir dbt --profiles-dir dbt --no-partial-parse --select legacy_classifications"}
{"teste": "tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai", "tipo": "sqlalchemy", "detalhe": "postgresql+psycopg://mvp_warehouse:***@localhost:5434/warehouse_db"}
```

O fim da saída:

```
=========================== short test summary info ============================
FAILED tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
FAILED tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai
SKIPPED [1] tests/test_acesso_macro.py:105: sem dbt/target/manifest.json; rode `make dbt-build`
SKIPPED [1] tests/test_consumo.py:59: armazém indisponível: sonda offline: conexão negada
SKIPPED [1] tests/test_consumo.py:94: armazém indisponível: sonda offline: conexão negada
2 failed, 436 passed, 3 skipped, 130 deselected in 136.29s (0:02:16)

real	2m18,690s
user	1m14,330s
sys	0m13,085s
```

---

## 10. Parecer da primeira rodada do B5 — 25/09/2026

**Veredito: o roteiro ainda precisa de correção antes de executar B5.** Um bloqueante e três
ajustes, na tabela ao fim. Conferido o intervalo `a4b04fc..1393b5c`, com o dossiê em `00de1e5`.
O preparo passou nas verificações abaixo; isso não prova o ciclo destrutivo nem elimina as
lacunas do roteiro.

Não executei o desmonte, o ciclo, uma restauração ou uma promoção do pacote real; não usei
`FORCE=1`. As sondas usam diretórios em `/tmp`, executáveis simulados e substituição de chamadas
em processo. A leitura do candidato na §10.2 confere seus arquivos, mas não o altera. B2/B3,
inclusive `bb783f4`, continuam para a revisão final. Não reabri a revisão encerrada de B0/B1/B4:
o código desses blocos foi consultado para conferir as promessas novas do roteiro.

### 10.1 Verificações do preparo

Comandos no *checkout* de trabalho, ambos com código de saída 0:

```text
$ .venv/bin/pytest -q -rs tests/test_makefile.py
83 passed in 11.75s

$ make check-offline
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 981 links de arquivo, 137 âncoras, 588 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
441 passed, 134 deselected in 139.49s (0:02:19)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
      7 tests/test_acesso.py
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
```

As linhas de progresso foram omitidas. Aqui já existe `dbt/target/manifest.json`: os cinco testes
que pulam no clone novo rodaram. Não repeti o ensaio de instalação e ferramentas da §8 nem
executei testes de integração; os resultados acima não substituem a prova do clone do B5.

### 10.2 Recuo antes dos bancos, tamanhos e falha da coleta

Sonda executada da raiz. `_medir` chama o `docker/medir.sh` real com Docker simulado e um Makefile
temporário; `_make` usa uma cópia do Makefile real com seus executáveis simulados. A conferência
do pacote usa o código real, mas a única chamada de subprocesso permitida devolve um inventário
vazio: nenhum comando chega ao Docker. O alvo `sonda` só imprime a variável `RESTAURAR`; não é
uma restauração.

```bash
.venv/bin/python - <<'PY'
import contextlib
import importlib.util
import io
import os
import pathlib
import subprocess
import tempfile
from unittest.mock import patch

root = pathlib.Path.cwd()
tmp = pathlib.Path(tempfile.mkdtemp(prefix='revisao_b5_'))
def helper(name):
    spec = importlib.util.spec_from_file_location(name, root / 'tests' / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

m = helper('test_medicao')
case = tmp / 'medicao'
case.mkdir()
with patch.dict(os.environ, {'RESTAURAR': '1'}):
    result = m._medir(case, 'sonda', makefile='.PHONY: sonda size-report\nsonda:\n\t@echo RESTAURAR=$(RESTAURAR)\nsize-report:\n\t@touch tamanho_coletado\n')
record = m._registro(case)
print('MEDICAO SIMULADA')
print('saida=', result.returncode, sep='')
print(next(line for line in result.stdout.splitlines() if line.startswith('RESTAURAR=')))
print('size-report chamado:', (case / 'trabalho/tamanho_coletado').exists())
print('chaves JSON:', ', '.join(record))

from mvp_ed1.recovery import cli
calls = []
def empty_inventory(args, **kwargs):
    assert args == [str(root / 'docker/conteineres.sh'), 'resolver', 'warehouse_db'], args
    calls.append('resolver warehouse_db -> vazio; saida=0')
    return subprocess.CompletedProcess(args, 0, stdout='', stderr='')
output = io.StringIO()
with patch.object(cli.subprocess, 'run', side_effect=empty_inventory), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
    code = cli.main(['--dir', str(root / 'data/recovery'), 'verify'])
print('\nVERIFY COM INVENTARIO VAZIO SIMULADO')
print(output.getvalue(), end='')
print('saida=', code, sep='')
print('chamadas:', calls)

m = helper('test_makefile')
case = tmp / 'coleta'
case.mkdir()
pytest = m.REGISTRADOR + 'case " $* " in *" --co "*) echo "sonda: coleta recusada" >&2; exit 2;; esac\n'
result, calls = m._make(case, 'check-offline', simulados={'.venv/bin/pytest': pytest})
print('\nCOLETA COM FALHA SIMULADA')
print(result.stdout, end='')
print(result.stderr, end='')
print('saida=', result.returncode, sep='')
print('chamadas:', calls)
print('rascunho:', tmp)
PY
```

Saída (código do processo da sonda: 0; os códigos dos comandos sondados estão discriminados):

```text
MEDICAO SIMULADA
saida=0
RESTAURAR=1
size-report chamado: False
chaves JSON: alvo, ate, inicio, fim, duracao_involucro_s, codigo_de_saida, interrompido, encerramento, parametros, estacao, amostragem, limite

VERIFY COM INVENTARIO VAZIO SIMULADO
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
RECUSADO — não resolvi o contêiner do serviço 'warehouse_db' neste projeto. Rode `make up`.
saida=2
chamadas: ['resolver warehouse_db -> vazio; saida=0']

COLETA COM FALHA SIMULADA
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
── 2/3 pytest sem os testes de integração ──
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
check-offline: as três etapas passaram
sonda: coleta recusada
saida=0
chamadas: ['python -m mvp_ed1.secrets_review', 'python -m mvp_ed1.docs_check', 'pytest -q -rs -m not integracao', 'pytest -q --co -m integracao']
rascunho: /tmp/revisao_b5_a406yy7w
```

A herança de `RESTAURAR=1` pelo medidor funcionou nesta composição isolada; não é um achado.
A recusa sem armazém é o comportamento correto do verificador. O defeito está na promessa de
recuo do §7.4: `recovery-restore` começa por esse verificador e não sobe os bancos. Tampouco
executa `airbyte-config`; o caminho até a restauração precisa considerar uma interrupção antes
de a base e as conexões estarem preparadas.

O medidor não chamou `size-report` nem escreveu tamanho no JSON. Nenhuma das nove linhas do
§7.3 pede essa coleta separadamente, embora C2 exija tamanho por cenário e a Execução Local §3
atribua essa coleta ao `make medir`.

A falha da coleta foi **injetada**, não ocorreu no `check-offline` real da §10.1. Ela demonstra
que o encadeamento `pytest | sed | sort | uniq` perde o erro do pytest: a receita usa o estado do
último comando, sem `pipefail`, e chega à mensagem de sucesso sem produzir o inventário exigido.

### 10.3 Destino depois da promoção

Sonda do `promover` real, exclusivamente com um arquivo fictício em `/tmp`:

```bash
.venv/bin/python - <<'PY'
import pathlib
import tempfile
from mvp_ed1.recovery.pacote import Destino, promover
base = pathlib.Path(tempfile.mkdtemp(prefix='revisao_b5_promocao_'))
old = base / 'antigo/data/recovery'
new = base / 'clone/data/recovery'
(old / 'candidato').mkdir(parents=True)
(old / 'candidato/arquivo-da-sonda').write_text('somente sonda\n')
approved = promover(Destino(old))
print('promovido:', approved.relative_to(base))
print('pacote no checkout antigo:', (old / 'aprovado/arquivo-da-sonda').exists())
print('pacote no clone:', new.exists())
print('rascunho:', base)
PY
```

Saída, código 0:

```text
promovido: antigo/data/recovery/aprovado
pacote no checkout antigo: True
pacote no clone: False
rascunho: /tmp/revisao_b5_promocao_vo35lue7
```

O §7.2 exporta justamente o diretório antigo e `recovery-promote` o passa ao `promover`.
A cópia externa da P5 permanece uma salvaguarda: não se afirma perda de todas as cópias.
Falta, porém, a passagem para um destino que continue acessível depois do arquivamento ou da
exclusão do *checkout* antigo permitidos pelo §7.5. A D58 continua valendo; o ajuste é completar
esse passo de operação e o caminho a registrar no B6.


## 11. Resposta à primeira rodada do B5 — 25/09/2026

Os quatro achados reproduzidos antes de qualquer correção, e os quatro corrigidos. Dois pediram
decisão do Owner, tomada em 25/09/2026 e registrada nas Pendências §2: **D59** (o `make medir`
coleta o tamanho, como o B1 declarou) e **D60** (o pacote aprovado vai para o `data/recovery` do
clone). Medir o recuo da fase 2 achou dois defeitos que a sonda do parecer não alcançava: a
restauração **não passava** num armazém recém-criado — os papéis dele —, e a conferência contra o
banco estourava em *traceback* quando o estado do pacote faltava. Os dois estão corrigidos.

```
28d34c7 fix: check-offline falha quando a coleta dos testes de integração falha
0ffd346 fix: a restauração garante os papéis do armazém antes do primeiro dump
dddc1d1 docs: registra D59 e D60, decididas na resposta à revisão do roteiro do B5
efb8fc1 feat: o medir coleta o tamanho dos bancos depois do intervalo medido
3788f34 docs: o roteiro do B5 recua por fase e leva o pacote aprovado para o clone
25ac22e fix: a conferência contra o banco recusa sem estourar quando falta o estado do pacote
```

**A segunda rodada é completa, por decisão do Owner em 25/09/2026, e revisa `00de1e5..` a
ponta** — este registro incluído. Além de confirmar os quatro achados, pede revisão o que nasceu
da resposta e ninguém além do autor viu: os papéis antes do primeiro dump (`0ffd346`), que mudam
a linha 9 e o recuo; o tamanho no `medir` (`efb8fc1`), que muda toda medição do B5; a recusa da
conferência (`25ac22e`); e o §7.4 e o §7.5 reescritos. O candidato do pacote é de `561edc2` e
**não** foi refeito: o código da restauração mudou, e a P4 manda refazê-lo uma vez, depois da
última rodada, com a ponta revisada.

### 11.1 RVB5-01 — o recuo por fase, e a restauração num destino novo

**Reprodução.** O passo 1 com um projeto sem contêineres, direto pelo Python (pelo `Makefile` o
`.env` seria recarregado, e com ele o projeto de trabalho):

```
$ (set -a; . ./.env; set +a; export COMPOSE_PROJECT_NAME=rvb5_vazio
   .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery verify; echo "saida=$?")
RECUSADO — não resolvi o contêiner do serviço 'warehouse_db' neste projeto. Rode `make up`.
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
saida=2
```

**O que o recuo da fase 2 pede, medido.** Um projeto Compose à parte, `rvb5_ensaio`, nas portas
25432–25434: o `make up` de verdade, com o nome do projeto e as portas no ambiente — a garantia da
rede e o `compose up` os leem antes do `.env` —; depois, os passos que escrevem, **só** por chamada
direta ao Python e ao Alembic, com uma guarda que recusa tudo se algum contêiner ou URL não for do
ensaio; e o derrubar com `-p` explícito, depois de conferir o nome que o Compose resolve, porque um
`down -v` no projeto de trabalho apagaria os volumes dos três bancos. O `mvp_ed1` é conferido pelo
`recovery-verify CONTRA_O_BANCO=1` antes e depois. O roteiro, na forma final (`VARIANTE` escolhe
se as origens são migradas):

```bash
#!/usr/bin/env bash
# RVB5-01 — a restauração num destino recém-criado, o da fase 2 do recuo: `make up`, as migrações das
# duas origens, e os passos 4, 4b e 5 da sequência (restore-dumps, rebase, verify contra o banco),
# com o pacote candidato real. Num projeto Compose à parte, `rvb5_ensaio`, em portas à parte: o
# `mvp_ed1` não é tocado, e o `recovery-verify CONTRA_O_BANCO=1` dele roda antes e depois.
set -u
R=/home/doug/Projetos/mvp_ed1
O=$R/.git/rvb5-saidas/${VARIANTE:?VARIANTE=com_migracoes|sem_migracoes}
P=rvb5_ensaio
cd "$R" || exit 1
mkdir -p "$O"
ISOLADO=(COMPOSE_PROJECT_NAME=$P SOURCE_DB_PORT=25432 LEGACY_DB_PORT=25433 WAREHOUSE_DB_PORT=25434)

# Chamadas diretas, com o .env e, por cima dele, o projeto e as portas do ensaio. **Nunca pelo
# Makefile nos passos que escrevem:** as receitas carregam o .env de novo, e o .env diz o projeto de
# trabalho — o COMPOSE_PROJECT_NAME exportado não sobreviveria.
isolado() { ( set -a; . ./.env; set +a; export "${ISOLADO[@]}"; "$@" ); }

passo() {  # $1 = arquivo; o resto, o comando; registra comando, saída, código e duração
	local arq=$1; shift
	local t0; t0=$(date +%s)
	{ echo "\$ $*"; "$@"; echo "saida=$? duracao=$(( $(date +%s) - t0 ))s"; } > "$O/$arq" 2>&1
	tail -1 "$O/$arq"
}

# Derrubar só o ensaio: `-p` explícito, e antes a conferência do nome que o Compose resolve — um
# `down -v` no projeto de trabalho apagaria os volumes dos três bancos.
derrubar() {
	local arq=$1 nome
	nome=$(isolado docker/conteineres.sh projeto)
	[ "$nome" = "$P" ] || { echo "derrubar recusado: o projeto resolvido é '$nome', não '$P'" > "$O/$arq"; return 1; }
	{ echo "\$ docker compose -p $P … down -v"; isolado docker compose -p "$P" --env-file .env -f docker/docker-compose.yml down -v; echo "saida=$?"
	  docker network rm "${P}_default"; } > "$O/$arq" 2>&1
}

livre=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
echo "MemAvailable: ${livre} MiB" > "$O/0_memoria.txt"
[ "$livre" -ge 1536 ] || { echo "memória livre abaixo de 1,5 GiB — nada foi feito"; exit 1; }

# O de trabalho, antes: o candidato confere contra ele.
passo 0_trabalho_antes.txt make --no-print-directory recovery-verify CONTRA_O_BANCO=1

# 1. O destino recém-criado: `make up`, o alvo de verdade, com o projeto e as portas do ensaio no
#    ambiente. A garantia da rede e o `compose up` leem o ambiente antes do .env.
passo 1_up.txt env "${ISOLADO[@]}" make --no-print-directory up
docker ps --filter "label=com.docker.compose.project=$P" --format '{{.Names}}  {{.Ports}}  {{.Status}}' \
	> "$O/1_conteineres.txt"

# Guarda: os três contêineres e as três URLs são do ensaio, ou nada que escreve roda.
isolado .venv/bin/python - > "$O/2_guarda.txt" 2>&1 <<'PY'
import sys
from mvp_ed1 import db
from mvp_ed1.recovery import cli
nomes = {s: cli._conteineres(s) for s in ("source_db", "legacy_db", "warehouse_db")}
urls = {p: db.database_url(p).split("@", 1)[1] for p in db.BANCOS}
for s, n in nomes.items():
    print(f"contêiner {s}: {n}")
for p, u in urls.items():
    print(f"url {p}: …@{u}")
ok = all(n.startswith("rvb5_ensaio_") for n in nomes.values()) and all(":2543" in u for u in urls.values())
print("guarda:", "ok" if ok else "RECUSADA")
sys.exit(0 if ok else 1)
PY
if [ $? -ne 0 ]; then
	echo "guarda recusada — nada foi escrito; derrubando o ensaio"
	derrubar 9_down.txt
	exit 1
fi

# 2. As migrações das duas origens — a ordem do ciclo, que o airbyte-config pede antes dele.
if [ "$VARIANTE" = com_migracoes ]; then
	passo 3_migrate.txt isolado .venv/bin/alembic upgrade head
	passo 3_migrate_legacy.txt isolado .venv/bin/alembic -n legacy upgrade head
fi

# 3. Os passos 4, 4b e 5 da sequência de restauração, com o candidato real.
passo 4_restore_dumps.txt isolado .venv/bin/python -m mvp_ed1.recovery --dir "$R/data/recovery" restore-dumps
docker stats --no-stream --format '{{.Name}}  {{.MemUsage}}' $(docker ps --filter "label=com.docker.compose.project=$P" -q) \
	> "$O/4_memoria.txt" 2>&1
passo 5_rebase.txt isolado .venv/bin/python -m mvp_ed1.recovery rebase
passo 6_verify_contra_o_banco.txt isolado .venv/bin/python -m mvp_ed1.recovery --dir "$R/data/recovery" verify --contra-o-banco
passo 7_alembic_current.txt isolado bash -c '.venv/bin/alembic current 2>&1 | grep -v "^INFO"; .venv/bin/alembic -n legacy current 2>&1 | grep -v "^INFO"'

# 4. Derrubar o ensaio inteiro: contêineres, volumes e a rede.
derrubar 8_down.txt; tail -3 "$O/8_down.txt"
{
	echo "contêineres: $(docker ps -a --filter "label=com.docker.compose.project=$P" -q | wc -l)"
	echo "volumes: $(docker volume ls --filter "name=$P" -q | wc -l)"
	echo "redes: $(docker network ls --filter "name=$P" -q | wc -l)"
} > "$O/8_sobra.txt"

# O de trabalho, depois.
passo 9_trabalho_depois.txt make --no-print-directory recovery-verify CONTRA_O_BANCO=1
echo "ensaio RVB5-01 terminado"
```

**Primeira execução, antes da correção** (com as migrações). A guarda e a restauração:

```
contêiner source_db: rvb5_ensaio_source_db
contêiner legacy_db: rvb5_ensaio_legacy_db
contêiner warehouse_db: rvb5_ensaio_warehouse_db
url SOURCE_DB: …@localhost:25432/source_db
url LEGACY_DB: …@localhost:25433/legacy_db
url WAREHOUSE_DB: …@localhost:25434/warehouse_db
guarda: ok
$ isolado .venv/bin/alembic upgrade head
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> deae0e5943e0, cria o schema oltp com as 40 tabelas transacionais
saida=0 duracao=3s
$ isolado .venv/bin/alembic -n legacy upgrade head
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> f558a05ce90e, cria o schema legacy com as 40 tabelas frouxas
saida=0 duracao=2s
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery restore-dumps
RECUSADO — pg_restore de warehouse_db falhou (código 1) e a transação foi desfeita — o banco está como estava. Diagnóstico completo:
pg_restore: error: could not execute query: ERROR:  role "ingestor" does not exist
Command was: GRANT ALL ON SCHEMA governance TO ingestor;
GRANT USAGE ON SCHEMA governance TO transformer;
GRANT USAGE ON SCHEMA governance TO auditor;
[recovery] restaurando source_db.dump em destino povoado, numa transação só
[recovery] restaurando legacy_db.dump em destino povoado, numa transação só
[recovery] restaurando warehouse_memoria.dump em destino povoado, numa transação só
saida=2 duracao=22s
```

O dump da memória traz `GRANT … TO ingestor, transformer, auditor`, e esses papéis só o
`governance.garantir()` cria — o `dbt-build` o chama. Na linha 9 do B5 eles já existem; num armazém
recém-criado, não, e o `--single-transaction` desfez a restauração do armazém inteira. O `verify`
seguinte, sobre um armazém sem a memória, estourava em vez de recusar:

```
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery verify --contra-o-banco
Traceback (most recent call last):
  File "/home/doug/Projetos/mvp_ed1/.venv/lib/python3.11/site-packages/sqlalchemy/engine/base.py", line 1969, in _exec_single_context
    self.dialect.do_execute(
  File "/home/doug/Projetos/mvp_ed1/.venv/lib/python3.11/site-packages/sqlalchemy/engine/default.py", line 952, in do_execute
    cursor.execute(statement, parameters)
  File "/home/doug/Projetos/mvp_ed1/.venv/lib/python3.11/site-packages/psycopg/_server_cursor.py", line 98, in execute
    raise ex.with_traceback(None)
psycopg.errors.UndefinedTable: relation "quarantine.rejected_legacy_records" does not exist
LINE 1: ...CLARE "c_735900714ed0_1" CURSOR FOR select * from quarantine...
                                                             ^

[… mais 55 linhas]
```

**A correção dos papéis** (`0ffd346`): `restore-dumps` chama `governance.garantir_papeis` — os papéis,
sem as migrações — antes de tocar em qualquer dump. Papel é do *cluster*, não do dump, e criá-lo
antes não conflita com o `--clean`. O teste novo, vermelho antes e verde depois:

```
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_recovery.py -k garante_os_papeis    # antes
E               AttributeError: module 'mvp_ed1.recovery.cli' has no attribute 'governance'
1 failed, 77 deselected in 0.39s
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_recovery.py                           # depois
78 passed in 0.45s
```

**Depois da correção, com as migrações das origens** — a ordem que o §7.4 prescreve:

```
MemAvailable: 2885 MiB
contêiner source_db: rvb5_ensaio_source_db
contêiner legacy_db: rvb5_ensaio_legacy_db
contêiner warehouse_db: rvb5_ensaio_warehouse_db
url SOURCE_DB: …@localhost:25432/source_db
url LEGACY_DB: …@localhost:25433/legacy_db
url WAREHOUSE_DB: …@localhost:25434/warehouse_db
guarda: ok
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery restore-dumps
[recovery] restaurando source_db.dump, numa transação só
[recovery] restaurando legacy_db.dump, numa transação só
[recovery] restaurando warehouse_memoria.dump, numa transação só
saida=0 duracao=15s
rvb5_ensaio_warehouse_db  125.5MiB / 2GiB
rvb5_ensaio_legacy_db  28.63MiB / 2GiB
rvb5_ensaio_source_db  62.4MiB / 2GiB
$ isolado .venv/bin/python -m mvp_ed1.recovery rebase
[recovery] re-base aplicado a 40 tabela(s); partição conferida antes de confirmar: mesmas classes, mesmo agrupamento, toda linha retida com geração estritamente negativa
saida=0 duracao=13s
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery verify --contra-o-banco
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações re-baseadas na faixa negativa)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0 duracao=16s
$ isolado bash -c .venv/bin/alembic current 2>&1 | grep -v "^INFO"; .venv/bin/alembic -n legacy current 2>&1 | grep -v "^INFO"
deae0e5943e0 (head)
f558a05ce90e (head)
saida=0 duracao=2s
contêineres: 0
volumes: 0
redes: 0
```

**Depois da correção, sem as migrações** — a restauração não precisa delas; o §7.4 as mantém pelo
`airbyte-config`, cujas conexões declaram as tabelas pelo nome:

```
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery restore-dumps
[recovery] restaurando source_db.dump, numa transação só
[recovery] restaurando legacy_db.dump, numa transação só
[recovery] restaurando warehouse_memoria.dump, numa transação só
saida=0 duracao=16s
$ isolado .venv/bin/python -m mvp_ed1.recovery rebase
[recovery] re-base aplicado a 40 tabela(s); partição conferida antes de confirmar: mesmas classes, mesmo agrupamento, toda linha retida com geração estritamente negativa
saida=0 duracao=14s
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery verify --contra-o-banco
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações re-baseadas na faixa negativa)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0 duracao=13s
$ isolado bash -c .venv/bin/alembic current 2>&1 | grep -v "^INFO"; .venv/bin/alembic -n legacy current 2>&1 | grep -v "^INFO"
deae0e5943e0 (head)
f558a05ce90e (head)
saida=0 duracao=2s
contêineres: 0
volumes: 0
redes: 0
```

**O passo 3 num destino novo** — `drop-slots` e `reset-sink`, os dois com `--force`, pelo mesmo
esquema de guarda (o `reset-sink` trunca o livro do *streaming*; o do `mvp_ed1` conferido depois):

```
['rvb5_ensaio_source_db', 'rvb5_ensaio_legacy_db', 'rvb5_ensaio_warehouse_db'] ['localhost:25432/source_db', 'localhost:25433/legacy_db', 'localhost:25434/warehouse_db']
guarda: ok
$ isolado .venv/bin/python -m mvp_ed1.streaming.maintenance drop-slots --force
slot 'mvp_inventory_movements': já ausente
saida=0 duracao=1s
$ isolado .venv/bin/python -m mvp_ed1.streaming.maintenance reset-sink --force
raw.inventory_movements_stream: 0 linhas removidas; destino vazio conferido
saida=0 duracao=0s
sobra: 0 contêineres, 0 volumes, 0 redes
```

```
$ docker exec mvp_ed1_warehouse_db … -tAc "select count(*) from raw.inventory_movements_stream"
13700
```

**O `mvp_ed1`, antes e depois** — o `recovery-verify CONTRA_O_BANCO=1` do projeto de trabalho, em
cada execução:

```
$ make --no-print-directory recovery-verify CONTRA_O_BANCO=1
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_ed1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0 duracao=12s
$ make --no-print-directory recovery-verify CONTRA_O_BANCO=1
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_ed1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0 duracao=12s
```

**A conferência sem o estado do pacote** (`25ac22e`, achado próprio): o `verify` da primeira execução
estourava. Agora recusa com o diagnóstico numa linha, sem apontar o banco — no destino novo medido,
a primeira tabela ausente é da origem. Um projeto à parte, recém-criado, sem restauração nenhuma:

```
$ isolado .venv/bin/python -m mvp_ed1.recovery --dir /home/doug/Projetos/mvp_ed1/data/recovery verify --contra-o-banco
  contagens em source_db: oltp.brands — manifesto 18 × agora None
  contagens em source_db: oltp.campaigns — manifesto 8 × agora None
  contagens em source_db: oltp.carriers — manifesto 8 × agora None
[… 65 linhas: as contagens dos três bancos, o Alembic e as versões do armazém]
  a leitura dos bancos falhou — relation "oltp.inventory_movements" does not exist: eles não têm o estado que o manifesto descreve
recovery-verify: 67 problema(s)
saida=1 duracao=3s
```

O `alembic: … × agora 'INFO …'` que aparece nesse relatório é de `leitura.alembic_current`: sem
revisão nenhuma, ele devolve as linhas `INFO` do Alembic em vez de vazio. A divergência é acusada
do mesmo jeito; é ruído de diagnóstico, anterior a esta entrega, e fica como observação.

**O roteiro** (`3788f34`): o §7.4 passa a ter o recuo por fase — antes do `make reset`; do `make
reset` até a linha 2 do §7.3; e com o ambiente pronto —, cada uma com o que existe e o que o recuo
pede. Os passos 2 e 6–9 num destino novo **não** foram medidos: sobem o *streaming* e o Airbyte, que
não se isolam num segundo projeto, e o 6 escreve no *checkout*. O caminho da fase 1 — o ambiente
antigo de volta, com o Airbyte novo e a D50 — é **[planejado]**.

### 11.2 RVB5-02 — o tamanho (D59)

O plano (§3, B1) já declarava: "ao fim, `make size-report` e o total por banco". O código nunca fez,
e seis rodadas sobre o B1 não viram. O Owner escolheu implementar o declarado (D59), em vez de
mudar a declaração. Os testes — o tamanho fora do intervalo, o relatório que falha como não medido,
a medição interrompida sem coleta —, vermelhos antes e verdes depois:

```
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_medicao.py -k 'tamanho or interrupcao_deixa'   # antes
E       KeyError: 'tamanho'
E       KeyError: 'tamanho'
E       KeyError: 'tamanho'
3 failed, 30 deselected in 3.82s
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_medicao.py                                        # depois
33 passed in 45.02s
```

De verdade, no *checkout* de trabalho, com um alvo só de leitura (as linhas por tabela do relatório
omitidas):

```
$ make medir ALVO=migrate-status
[…]
[medir] tamanho, fora do intervalo medido: make size-report

SOURCE_DB           62.4 MB
  tabela                          linhas       dados     índices       total  bytes/linha
  TOTAL                          252,955                             51.2 MB          212

LEGACY_DB           13.2 MB
  (sem tabelas com dados)

WAREHOUSE_DB       472.1 MB
  (sem tabelas com dados)

soma dos três bancos: 547.7 MB
Tamanho é observação, não limite (ADR-0014).
[medir] registro: /home/doug/Projetos/mvp_ed1/data/medicoes/2026-09-25T041420Z_migrate_status.json
| migrate-status | Airbyte,bancos | 0m 01s | não medido | não medido | 0 amostras (pausa de 2 s) | 547.7 MB |
$ python3 -c "import json; d=json.load(open('…_migrate_status.json')); print(d['tamanho'], d['duracao_involucro_s'])"
{'SOURCE_DB': '62.4 MB', 'LEGACY_DB': '13.2 MB', 'WAREHOUSE_DB': '472.1 MB', 'soma': '547.7 MB'} 1
```

Os "0 amostras" são de um alvo mais curto que uma pausa do amostrador, como antes. **Observação:**
o `size-report` detalha tabela a tabela só o schema `oltp` (`por_tabela(engine, schema="oltp")`), e
nos outros dois bancos o "(sem tabelas com dados)" quer dizer nenhuma tabela do `oltp`. Para C2 o
total por banco basta; a Execução Local passou a dizer isso. Um detalhe por schema no armazém fica
para quem precisar dele.

### 11.3 RVB5-03 — a coleta que falha

`pipefail` na terceira etapa, e uma mensagem que diz o que faltou (`28d34c7`). O teste novo, com a
coleta simulada saindo 2:

```
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_makefile.py -k coleta_dos_de_integracao_falha   # antes
E       AssertionError: ── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
E         ── 2/3 pytest sem os testes de integração ──
E         ── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
E         check-offline: as três etapas passaram
$ .venv/bin/pytest -q -p no:cacheprovider tests/test_makefile.py                                          # depois
84 passed in 11.92s
```

E o caminho nominal, real, no *checkout* de trabalho (com o *manifest*, nada pula):

```
$ make check-offline
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 981 links de arquivo, 137 âncoras, 588 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
442 passed, 134 deselected in 150.86s (0:02:30)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
[as 13 linhas do inventário, iguais às da §10.1]
check-offline: as três etapas passaram
```

### 11.4 RVB5-04 — o pacote depois da promoção (D60)

O §7.5 copia o `aprovado` para o `data/recovery` do clone, tira o `RECOVERY_DIR` do ambiente e
confere; só então o *checkout* antigo é liberado. Ensaiado com cópias do candidato num diretório de
rascunho — `<antigo>` e `<clone>` —, com os alvos de verdade:

```
$ RECOVERY_DIR=<antigo>/data/recovery make recovery-promote
[recovery] RECOVERY_DIR = <antigo>/data/recovery
promovido: <antigo>/data/recovery/aprovado
saida=0
$ mkdir -p <clone>/data/recovery && cp -a <antigo>/data/recovery/aprovado <clone>/data/recovery/
saida=0
$ RECOVERY_DIR=<clone>/data/recovery make recovery-verify   # no clone: unset RECOVERY_DIR dá este mesmo caminho
[recovery] RECOVERY_DIR = <clone>/data/recovery
[recovery] conferindo <clone>/data/recovery/aprovado
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0
<antigo>/data/recovery:
aprovado

<clone>/data/recovery:
aprovado
```

Sem `RECOVERY_DIR` no ambiente, o padrão do `Makefile` é o `data/recovery` do próprio *checkout*
(`RECOVERY_DIR ?= $(abspath data/recovery)`):

```
$ env -u RECOVERY_DIR make --eval 'mostra: ; @echo $(RECOVERY_DIR)' mostra
/home/doug/Projetos/mvp_ed1/data/recovery
```

**A cópia da P5 como `RECOVERY_DIR`.** Ao escrever o recuo apareceu que a cópia da P5 não servia de
`RECOVERY_DIR` — o pacote ficava na raiz dela, e o `RECOVERY_DIR` espera um `candidato/` ou um
`aprovado/` dentro. A P5 passa a copiá-lo para `~/mvp_ed1-recovery-<corte>/candidato`:

```
$ mkdir <tmp>/mvp_ed1-recovery-20260924T234304Z && cp -a data/recovery/candidato <tmp>/mvp_ed1-recovery-20260924T234304Z/
saida=0
$ cd <tmp>/mvp_ed1-recovery-20260924T234304Z/candidato && sha256sum -c --quiet checksums.sha256
saida=0
$ RECOVERY_DIR=<tmp>/mvp_ed1-recovery-20260924T234304Z make recovery-verify
[recovery] RECOVERY_DIR = <tmp>/mvp_ed1-recovery-20260924T234304Z
[recovery] conferindo <tmp>/mvp_ed1-recovery-20260924T234304Z/candidato
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
saida=0
```

### 11.5 O `make check` da ponta

Em `25ac22e`, depois de todas as correções (as linhas do dbt e o progresso do pytest omitidos):

```
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 981 links de arquivo, 137 âncoras, 588 citações de ADR — nada quebrado
── 2/4 dbt build: modelos, testes de dados e reconciliações ──
04:32:43  Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
── 4/4 pytest: código, contratos e integração ──
SKIPPED [1] tests/test_carga.py:51: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:227: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:272: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:778: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:794: a captura 43 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
572 passed, 8 skipped in 259.22s (0:04:19)
check: as quatro etapas passaram
real	6m31,087s
saida=0
```

### 11.6 O que continua sem verificação

- os passos 2 e 6–9 da restauração num destino novo, e a fase 1 do recuo (§11.1);
- o `leitura.alembic_current` que devolve as linhas `INFO` sem revisão nenhuma (§11.1) —
  observação, não corrigida;
- o detalhe por schema do `size-report` fora do `oltp` (§11.2) — observação;
- **os alvos do `Makefile` não se apontam para um segundo projeto pelo ambiente:** toda receita que
  carrega o `.env` troca o `COMPOSE_PROJECT_NAME` exportado pelo do arquivo — por isso as medições
  da §11.1 chamam o Python direto. Não afeta o B5, que tem um projeto só; é premissa de quem quiser
  isolar outro;
- tudo o que a §4 já listava continua como estava.

---

## Achados da revisão

Um achado por linha. A coluna *Situação* fica para a resposta de quem aplicar a revisão.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVB5-01 | `PLANO_etapa_12.md` §7.4, recuo (linhas 1323–1326); `Makefile`, `recovery-restore` | **O recuo anunciado “a qualquer momento” não cobre uma parada antes de preparar o destino.** Depois do desmonte, sem o novo armazém, o primeiro passo da restauração já recusa: `recovery-verify` precisa do contêiner para listar os dumps. A sonda da §10.2 devolveu 2 com inventário vazio. O alvo também não cria os bancos nem configura as conexões do Airbyte. Descrever o recuo por fase, com diretório, pré-requisitos, comandos de preparação e pontos de parada; distinguir a restauração da linha 9, com ambiente pronto, da recuperação de uma interrupção no preparo. | `bloqueante` | **Corrigido** (`3788f34`, `0ffd346`, `25ac22e`). O §7.4 passa a ter o recuo por fase — antes do `make reset`; do `make reset` até a linha 2 do §7.3; com o ambiente pronto —, cada uma com o que existe e o que o recuo pede antes do `recovery-restore`. Medir a fase 2 num destino novo, em projeto Compose à parte, achou que a restauração não passava nele: os `GRANT`s do dump da memória nomeiam papéis que só o `governance.garantir()` cria; o `restore-dumps` passa a criá-los antes do primeiro dump. Com o candidato real, os passos 1, 3, 4, 4b e 5 passam, com e sem migrações. Achado próprio: a conferência contra o banco sem o estado do pacote estourava em *traceback*; agora recusa numa linha. Passos 2 e 6–9 num destino novo não medidos (§11.1). |
| RVB5-02 | `PLANO_etapa_12.md` §7.3; `docs/execucao_local.md` §3, linha 95 | **Falta coletar os tamanhos prometidos para C2.** `make medir` registra tempo e memória; não chama `size-report` e seu JSON não contém tamanhos (§10.2). As nove linhas do ciclo tampouco chamam o relatório. Assim, seguir o roteiro não produz a dimensão “tamanho por cenário” para a Capacidade §2.12. Incluir a coleta e seu registro nos pontos pertinentes do ciclo e corrigir a descrição do medidor na Execução Local. | `ajuste` | **Corrigido pela declaração** (`efb8fc1`; D59, do Owner em 25/09/2026). O plano (§3, B1) já mandava o medidor rodar o `size-report` ao fim e gravar o total por banco, e o código não fazia. Agora faz, depois do intervalo medido: o total de cada banco e a soma no registro e na linha da Capacidade; relatório que falha fica como não medido. A Execução Local diz o que o `size-report` detalha, e o §7.3, que cada `make medir` traz o tamanho. Testes vermelhos antes, verdes depois; medido de verdade (§11.2). |
| RVB5-03 | `Makefile:713`, terceira etapa de `check-offline` | **Falha no inventário de testes excluídos termina como sucesso.** Com `pytest --co` saindo 2, o encadeamento termina em `uniq`, o make sai 0 e imprime “as três etapas passaram” (§10.2). Preservar o erro da coleta e interromper antes dessa mensagem; conferir o caminho de falha além do caminho nominal já coberto. | `ajuste` | **Corrigido** (`28d34c7`): `pipefail` na terceira etapa e uma mensagem que diz o que faltou. O teste novo simula a coleta saindo 2: vermelho antes, verde depois; o caminho nominal real continua passando (§11.3). |
| RVB5-04 | `PLANO_etapa_12.md` §7.5, liberação do checkout antigo (linhas 1331–1333) | **Promover não transfere o pacote para fora do checkout antigo.** Com o `RECOVERY_DIR` prescrito, a promoção só renomeia `antigo/data/recovery/candidato` para `antigo/data/recovery/aprovado` (§10.3). Arquivar ou apagar o diretório logo depois deixa o caminho de recuperação sem destino. A cópia da P5 evita a perda de todas as cópias, mas não é incorporada ao procedimento como novo local do pacote. Antes de liberar o checkout antigo, definir e conferir o destino durável, o `RECOVERY_DIR` correspondente e o caminho que o B6 vai registrar. | `ajuste` | **Corrigido** (`3788f34`; D60, do Owner em 25/09/2026). O §7.5 copia o `aprovado` para o `data/recovery` do clone — o caminho padrão da D46 no *checkout* de trabalho da D58 —, tira o `RECOVERY_DIR` do ambiente e confere com `make recovery-verify` no clone, antes de liberar o antigo; o B6 registra o caminho. A cópia da P5 passa a nascer como `RECOVERY_DIR`. Os dois ensaiados com cópias e os alvos de verdade (§11.4). |
