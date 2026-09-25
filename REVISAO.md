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

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

