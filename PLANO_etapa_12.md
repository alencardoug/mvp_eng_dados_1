# Plano — Etapa 12: fechamento da fase local (M5)

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item, como o plano de fechamento da Etapa 10 saiu. Escrito em 18/09/2026
> sobre `179b80a` (`main`, Etapa 11 aceita), para ser **revisado antes de qualquer código** —
> primeiro por você (§10 tem o que só você decide), depois pelo outro agente (§12 diz o que
> pedir a ele).
>
> Regime de leitura: **[medido]** tem saída de comando por trás; **[planejado]** é intenção. Os
> dois não se misturam (P5).
>
> **Revisão 2 — 18/09/2026, mesma data.** As quatro decisões que a primeira versão deixava ao
> Owner (§10) foram tomadas antes de o plano ir à revisão: D45 (c), D46 `data/recovery/`, D47
> `v1.0.0`, D48 conforme recomendado. Onde a primeira versão dizia "recomendo", esta diz
> "decidido". O que o revisor recebe é o plano que vai ser executado.

---

## 0. Onde estamos **[medido]**

- Etapas 0–11 aceitas; **M0–M4** concluídos. `main` em `179b80a`, 158 *commits*, publicado.
- `make check` verde em 18/09/2026: `dbt build` `PASS=905`, classificação 2.983/2.983 colunas em
  199 nós, linhagem em dia, `pytest` **291 passed, 8 skipped** (3 min 52 s só o pytest; o
  `check` inteiro entre 4 min 27 s e 6 min 34 s conforme a carga da máquina).
- DAG `fluxo_batch`: 13 tarefas `success` em **7 min 58 s** (18/09, 06:34–06:42 UTC), captura
  **43** certificada e selecionada; os três estados da origem regenerada reconciliados
  (13.700 movimentos nos dois caminhos).
- Máquina: 11,5 GB de RAM, 4 CPUs; ambiente de trabalho consome ~4 GB
  ([Capacidade §2.8](docs/capacidade_e_recuperacao.md)). Neste momento, com Airbyte, Airflow e
  os três bancos de pé: 3 GB disponíveis.
- **Nenhuma *tag* no Git.** Nenhum pacote de recuperação jamais montado
  ([Capacidade §3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação) descreve o
  conteúdo; a tabela de situação diz "Recuperação da Etapa 12 ainda não entregue").
- `secrets_review` varre **os arquivos rastreados** e o índice; não varre o histórico.
- Links e âncoras dos documentos são conferidos a olho (dossiê da Etapa 11, §4).
- `airbyte/terraform.tfstate` existe no disco com 4 ocorrências de `password` e está
  **ignorado** pelo Git (`.gitignore:60`) — conferido; `data/` também é ignorado.

---

## 1. O que a etapa exige, e o que falta

Os critérios de conclusão do [plano](docs/plano_de_desenvolvimento.md#etapa-12--fechamento-da-fase-local--m5),
um a um, contra o que existe:

| # | Critério | O que existe | O que falta |
|---|---|---|---|
| C1 | Todos os critérios de sucesso do Termo verificados **em ambiente limpo** | Tudo roda nesta máquina, sobre volumes que existem desde a Etapa 2 | "Limpo" definido (**D45**): executar o ciclo da [Execução Local §3](docs/execucao_local.md#3-ciclo-completo) do zero, mapeando cada critério do Termo a um comando e uma saída |
| C2 | Cada cenário da [§5](docs/execucao_local.md#5-executando-por-partes) executado no seu subconjunto, com **tamanho, tempo e pico de memória** medidos | Tempo e tamanho já são medidos caso a caso; pico de memória só em episódios (§2.7–§2.9) | Um instrumento que meça os três **por alvo**, do mesmo jeito para todos, e uma tabela única na Capacidade |
| C3 | Cobertura integral conferida | `tests/test_cobertura.py` (40 tabelas, enumerações, pisos, proporções) e o manifesto do legado (74/74, 12.747 vereditos) | Rodar em ambiente limpo e citar; nada novo a construir |
| C4 | Restauração do ponto de recuperação testada, incluindo o *re-snapshot* do CDC | A especificação (§3.1–§3.3) e o procedimento de *re-snapshot* (§3.2 da Execução Local) | O pacote inteiro: montar, verificar, restaurar — e o teste de que restaurar + *re-snapshot* devolve o mesmo livro |
| C5 | Documentação coerente com o código | Revisão a olho a cada entrega | Um verificador de links e âncoras em `make check`, e a leitura da Execução Local **executando** cada linha na ordem |
| C6 | Nenhum segredo no repositório **nem no histórico** | `secrets_review` sobre o rastreado | O mesmo padrão sobre todo *blob* de todo *commit* |
| — | Artefato: versão marcada no Git | Nenhuma *tag* | `v1.0.0` (D47) no *commit* que fecha M5 |

Tudo o que falta é **instrumento** (C2, C5, C6), **produto** (C4) ou **execução** (C1, C3). Nada
é modelagem, nada é componente novo: **nenhum ADR novo previsto**, salvo o que as decisões da §10
exigirem.

---

## 2. Ordem, e por quê

```
B1 medição ─┐
B2 segredos ├─► B4 pacote de recuperação ─► B5 ambiente limpo (o ciclo, medido) ─► B6 fechamento
B3 docs ────┘        (do estado ATUAL,            (destrói volumes: só depois
                      antes de destruir)            de o pacote existir)
```

1. **B1, B2, B3 primeiro e em qualquer ordem** — são código local, sem ambiente pesado, e cada um
   é usado pelos blocos seguintes: B1 mede B4 e B5; B2 e B3 entram no `make check` que B5 roda.
2. **B4 antes de B5**, obrigatoriamente: o pacote é montado sobre o estado **atual** (origem
   `seed 20260904`, legado com as falhas do catálogo, 43 capturas certificadas no armazém), e B5
   começa com `make reset`, que apaga os volumes. Montar o pacote depois seria empacotar o que a
   reconstrução acabou de produzir — prova nada.
3. **B5 é o bloco caro** (troca de ambientes, ~2 h de relógio) e o único que produz os números
   de C1–C3.
4. **B6 por último**, porque documenta estado, e estado se documenta depois de medido — o mesmo
   motivo do R14 na Etapa 10.

---

## 3. B1 — o instrumento de medição

**O que existe [medido].** `docker/preflight.sh` lê `MemAvailable` de `/proc/meminfo`;
`make size-report` dá tamanho por banco/tabela; os tempos vêm de `time` à mão ou do Airflow.

**O que muda [planejado].** Um alvo `make medir ALVO=<alvo>` (ou `docker/medir.sh`) que:

- executa o alvo pedido e grava **início, fim, duração**;
- em paralelo, a cada 2 s, amostra `MemAvailable` do *host* e a soma de `docker stats
  --no-stream` (memória dos contêineres) — e guarda o **mínimo disponível** e o **máximo dos
  contêineres**, mais o instante de cada um;
- registra o estado da estação no início (`MemAvailable`, o que está de pé segundo o preflight),
  porque o número do §2.8 depende disso e a leitura sem ele engana;
- ao fim, chama `make size-report` e anota o total por banco;
- escreve uma linha em `data/medicoes/<data>_<alvo>.json` (ignorado pelo Git) e imprime a linha
  da tabela pronta para colar na Capacidade.

Não mede CPU (a §2.5 já disse que a restrição é memória; carga média fica como observação, via
`/proc/loadavg`, sem virar critério). Não mede o pico **dentro** de um *pod* do Airbyte — o que
importa é o que a máquina sente.

**Prova.** `tests/test_medicao.py`: o amostrador acha o mínimo numa série sintética; a linha
gerada é a mesma da tabela; `ALVO` inexistente falha antes de amostrar. Sem banco.

**Oráculo do bloco:** a medição de `make dbt-build` bate com o tempo que o `run_results.json`
diz (±5 s) — é o número que já conhecemos.

---

## 4. B2 — segredos no histórico

**O que existe [medido].** `mvp_ed1.secrets_review`: padrões (`PRIVATE KEY`, `AKIA…`, `ghp_…`,
`xox…`, `private_key_id`) e chaves com valor (`PASSWORD=…`) nos arquivos rastreados; acusa `.env`
no índice.

**O que muda [planejado].** `python -m mvp_ed1.secrets_review --historico`:

- percorre `git rev-list --all --objects`, lê cada *blob* uma vez (`git cat-file --batch`), aplica
  **os mesmos padrões** — uma declaração, dois alcances;
- ignora *blobs* binários e os maiores que 5 MB (declarado, não silencioso: imprime quantos);
- confere que `.env` nunca foi rastreado em *commit* nenhum (`git log --all --diff-filter=A -- .env`
  vazio);
- imprime achados com `commit`, caminho e linha; sai com 1 se houver.

Não entra no `make check` (o histórico só cresce, e varrê-lo a cada `check` é minuto gasto para
achar o que já foi achado); entra na **definição de pronto** desta etapa e no dossiê, com saída
colada.

**Se achar algo (D48, decidida).** Senha de contêiner local: regenerar, registrar, não reescrever
histórico. Chave de nuvem ou token externo: revogar **e** reescrever, só pela mão do Owner.

**Prova.** `tests/test_secrets_review.py` ganha um caso com um repositório Git temporário: um
*commit* com segredo, depois removido — o modo rastreado passa, o histórico acusa.

---

## 5. B3 — coerência dos documentos, por ferramenta

**O que existe [medido].** ~20 documentos em `docs/` e na raiz, ligados por caminho relativo e
âncora de título; conferidos a olho. O dossiê da Etapa 11 listou isso como não verificado.

**O que muda [planejado].** `python -m mvp_ed1.docs_check` (e `make docs-check`, chamado na
etapa 1 do `make check`, logo depois dos segredos — custa menos de um segundo):

- todo link relativo em `*.md` rastreado aponta para arquivo existente;
- toda âncora `#…` aponta para um título existente no arquivo alvo, com a regra de *slug* do
  GitHub (minúsculas, espaços → `-`, pontuação removida, acentos mantidos);
- todo ADR citado como `ADR-00nn` tem arquivo em `docs/adr/`;
- os blocos gerados (`<!-- gerado -->` do Dicionário, inventário, diagrama) não são tocados —
  isso já é do `--check` de cada gerador.

Não verifica prosa. "Coerente com o código" continua sendo o que B5 prova executando a Execução
Local linha a linha; a ferramenta só garante que os *caminhos* que a prosa cita existem.

**Prova.** Teste sem banco com um par de arquivos temporários: link bom, link quebrado, âncora
com acento. E a primeira execução sobre o repositório real vale como medição — o número de links
conferidos entra no dossiê, e o que ela achar se corrige antes de B5.

---

## 6. B4 — o ponto único de recuperação

**O que existe [medido].** A especificação em [Capacidade §3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação):
dois *dumps* (`pg_dump -Fc`), *checksums*, `seed`/`as_of_date`/versão das migrações, último
`event_sequence`, *commit*, manifesto com contagens, instruções testadas. O `warehouse_db` fora.
O cursor do CDC fora, com o motivo (§3.2). Restauração só por decisão explícita (§3.3).

**O que muda [planejado].** Quatro alvos, um módulo (`mvp_ed1.recovery`), um diretório (D46: `data/recovery/`, `RECOVERY_DIR` sobrescreve):

| Alvo | O que faz | Guarda |
|---|---|---|
| `make recovery-pack` | `pg_dump -Fc` de `source_db` e `legacy_db` pelos contêineres; `sha256sum`; manifesto JSON com `seed`, `as_of_date`, `alembic current` dos dois bancos, `max(event_sequence)` do livro, `git rev-parse HEAD` (e recusa se a árvore estiver suja — pacote de código não aprovado não é *last known good*), contagens e tamanhos por tabela; `RESTAURAR.md` gerado com os comandos exatos | `<dir>/candidato/` |
| `make recovery-verify` | Confere *checksums*, lê o manifesto, `pg_restore --list` nos dois *dumps* (sem restaurar), compara contagens do manifesto com o banco vivo — o oráculo é o próprio manifesto | — |
| `make recovery-restore FORCE=1` | Recusa sem `FORCE=1` (regra §3.3). `pg_restore` nos dois bancos, **depois** o procedimento da [Execução Local §3.2](docs/execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming) — destino quente esvaziado com consumidores parados, estado do conector descartado, *re-snapshot* — e a reconstrução do armazém (`sync-airbyte RESET=1`, `sync-legacy`, `dbt-build RESET=1`) | — |
| `make recovery-promote` | Move `candidato/` para `aprovado/` — só depois de `recovery-verify` **e** de uma restauração validada; o anterior é apagado (§3.3: um só) | `<dir>/aprovado/` |

**A prova de C4, por extenso [planejado]:** montar o pacote do estado atual → `verify` → em B5,
depois do ciclo do zero, `restore FORCE=1` sobre os bancos recém-construídos → `sync`/`build` →
`make check` verde **e** os oráculos batem: contagens de `oltp` e `legacy` iguais ao manifesto,
`caminhos_de_ingestao_reconciliam` passando com o livro do *re-snapshot* (o mesmo 13.700 dos
dois lados), captura certificada. Só então `promote`.

**Prova sem banco.** `tests/test_recovery.py`: manifesto gerado e lido de volta; *checksum*
alterado é acusado; árvore suja é recusada; `restore` sem `FORCE` é recusado antes de tocar em
banco.

---

## 7. B5 — o ciclo do zero, medido

**Pré-condição:** B1–B4 entregues, pacote candidato montado e verificado.

**O que é "do zero" [decidido, D45 (c)]:** clone novo em outro diretório (`git clone` de
`origin/main`), `.env` novo por `make env` (senhas novas — prova que nada depende das antigas),
`make install`, **`make airbyte-down`** (o cluster `kind` cai; a armadilha do `PG_VERSION` da §6 é
reproduzida e o remédio documentado, conferido) e **`make reset`** nos volumes desta máquina antes
de `make up`. O que **não** é zerado, e fica registrado como contrapartida da fase seguinte:
imagens Docker já baixadas, `abctl` e Terraform em `.tools/`, os pré-requisitos da §1 — "máquina
que nunca viu o projeto" é a prova de portabilidade da VM (§4.1 da conversa de custos), depois
da Etapa 13.

**O roteiro é a [Execução Local §3](docs/execucao_local.md#3-ciclo-completo), na ordem, cada
linha sob `make medir`:**

| Cenário (§5) | Alvos, na ordem | Sobe | Mede |
|---|---|---|---|
| Base | `up` → `migrate` → `seed-data` → `migrate-legacy` → `seed-legacy` | bancos | tamanho dos dois bancos, tempo, pico |
| Carga | `airbyte-up` → `airbyte-config` → `sync-airbyte` → `sync-legacy` | + Airbyte | tempo por conexão, pico (o maior da etapa, §2.9), `raw` e `raw_legacy` |
| Transformação | `dbt-build` → `check` | bancos (Airbyte pode ficar) | tempo, pico, `PASS=` |
| Orquestração | `airflow-up` → `dag-run` → `dag-status` | + Airflow (Airbyte de pé — é o par permitido) | tempo da DAG, pico com os dois |
| Streaming | `stream-up` → `stream-run` (segundo terminal) → `stream-produce` → `stream-alerts` | + streaming (Airbyte e Airflow **pausados** pelo preflight) | tempo até o *snapshot* fechar, pico, linhas no livro |
| Reconciliação dos caminhos | `airbyte-up` (pausa o streaming) → `sync-airbyte` → `dbt-build` | + Airbyte | `caminhos_de_ingestao_reconciliam`, tempo |
| Catálogo | `dbt-docs` → `catalog` | bancos | tempo; `--check` dos geradores sem diferença |
| Recuperação | `recovery-restore FORCE=1` → o procedimento §3.2 → `sync`/`build` → `check` | conforme cada passo | C4 inteira |

Cada linha produz uma linha da tabela nova da Capacidade (**§2.12 — Medido na Etapa 12**), com
o estado da estação anotado. **R11** vale o tempo todo: nunca *batch* e *streaming* de pé juntos
([ADR-0046](docs/adr/0046-validar-a-fase-local-por-partes.md)); se o preflight recusar, a recusa
é registrada, não contornada.

**Os critérios do Termo, mapeados [planejado]:**

| Termo §6 | Comando que prova | Saída que vale |
|---|---|---|
| Produto: subir bancos, gerar dados, pipeline completo, consultar views, catálogo e linhagem | as linhas Base → Carga → Transformação → Orquestração → Catálogo | `dag-status` 13 `success`; `select` nas 16 views (`tests/test_consumo.py`); `dbt docs` servindo |
| Técnico: reproduzível de ponta a ponta | o ciclo inteiro do clone novo, sem intervenção fora da Execução Local | o diário de execução: cada comando, hora, saída resumida |
| Técnico: migrações do zero | `migrate`, `migrate-legacy` em volumes novos; `governance.garantir()` no `dbt-build` | `alembic current` nos três |
| Técnico: testes passando | `make check` | `PASS=…`, `N passed` |
| Técnico: reconciliação entre camadas | dentro do `check` (oito fronteiras) | os 22 testes de reconciliação `pass` |
| Técnico: ausência de segredos | `secrets_review` + `--historico` | "nada encontrado", nas duas |
| Técnico: documentação coerente | `docs-check` + a execução linha a linha | 0 links quebrados; 0 desvios do roteiro (ou os desvios corrigidos no documento **antes** de fechar) |
| Governança: campo sensível classificado, linhagem, ADRs, nomenclatura | `sensitivity --check`, `lineage --check`, `test_classificacao.py` pisos em 100 | já cobertos pelo `check`; citados |

---

## 8. B6 — fechamento

1. **Capacidade §2.12** com a tabela medida e §3 com "entregue em …" e o caminho do pacote
   aprovado; a tabela de situação do documento atualizada.
2. **Execução Local** corrigida onde B5 divergiu; a §3 ganha a linha `make medir` e as linhas
   `recovery-*`; a §4 (alvos auxiliares) idem.
3. **README** (status, mapa), **plano** (Etapa 12 com ✓ só onde há medição; M5), **pendências**
   (o que sobrou para o aceite), **riscos** (R6, R7, R10, R11 com o estado).
4. **Definição de pronto** do `CLAUDE.md` §7 aplicada e registrada.
5. ***Tag* `v1.0.0`** anotada no *commit* de fechamento (D47), com a mensagem apontando para o pacote
   e para a tabela de medições.
6. **Dossiê** (`REVISAO.md` pela skill) para o outro agente — com a seção "não verificado"
   honesta: o que a máquina não permitiu medir (o que o ADR-0046 já disse) e o que ficou por
   amostragem.

**Sai deste plano:** este arquivo, no último *commit*.

---

## 9. O que **não** entra

- *Batch* e *streaming* simultâneos — ADR-0046, medido na Etapa 13.
- VM na nuvem como "ambiente limpo" — é o §4.1 da conversa de custos, depois da Etapa 13
  (D45 (c): fica como contrapartida registrada).
- Teste de carga acima de `SCALE=1` — o dimensionamento é por cobertura
  ([ADR-0014](docs/adr/0014-volume-por-proporcoes-e-fator-de-escala.md)); `make test-carga`
  continua sendo a única carga, em banco isolado.
- Qualquer mudança de modelagem, tratamento ou componente. Se B5 revelar defeito, ele é
  corrigido **onde nasce** (declaração) e vira linha no dossiê — não vira reescrita.
- D43 (guarda de identidade como função no armazém) — adiada para a fase GCP por decisão sua.

---

## 10. As decisões do Owner — tomadas em 18/09/2026

As quatro foram decididas pelo Owner no mesmo dia, sobre as alternativas abaixo (mantidas para
o revisor ver o que foi descartado e por quê). Nenhum ADR novo: nenhuma troca ferramenta, camada
ou modelagem. O registro de encerramento está em [Pendências §2](docs/pendencias.md#2-decisões-já-fechadas).

### D45 — o que é "ambiente limpo"

| Opção | A favor | Contra |
|---|---|---|
| (a) Clone novo + `.env` novo + `make reset` nesta máquina | Custo zero; é literalmente o que o Termo pede ("a partir do repositório"); imagens Docker em cache e `.tools/` não são estado do projeto — são o equivalente de ter o Docker instalado | Não prova que o repositório sobe numa máquina que nunca o viu (pré-requisitos da §1 da Execução Local, versão do Docker, do `kind`) |
| (b) VM na nuvem, um dia (~US$ 3) | Prova a portabilidade de verdade; é o §4.1 que você já quer fazer | Antecipa um passo que você colocou **depois** da Etapa 13; e mistura "fechar a fase local" com "provar portabilidade" |
| **(c) (a) agora, (b) como critério da fase seguinte** — **decidida** | O que (a) não prova fica registrado como contrapartida, como o ADR-0046 fez com a simultaneidade | Nenhum, além de escrever a frase |

**Decidido: (c)** — na prática (a), com a lacuna registrada como contrapartida da fase seguinte.
Sub-decisão dentro de (a), **decidida junto**: o cluster `kind` do Airbyte é **derrubado**
(`airbyte-down`, que cai na armadilha do `PG_VERSION` da §6) e não só pausado — "do zero" inclui
o Airbyte, e a armadilha documentada é reproduzida uma vez para valer como documentação.

### D46 — onde vive o pacote de recuperação — decidido: `data/recovery/`, com `RECOVERY_DIR`

| Opção | A favor | Contra |
|---|---|---|
| **`data/recovery/`** (já ignorado pelo Git), com `RECOVERY_DIR` sobrescrevível no `.env` — **decidida** | Zero configuração; a regra "não versionado" vale por construção; o caminho é o mesmo em toda máquina | Um `rm -rf data/` (que ninguém deveria fazer, mas o `.gitignore` convida) leva o pacote junto |
| Fora do repositório (`~/mvp_ed1_recovery/`) | Sobrevive ao repositório | Caminho por máquina; mais uma variável obrigatória |

### D47 — o nome da versão — decidido: `v1.0.0`

| Opção | A favor | Contra |
|---|---|---|
| **`v1.0.0`** no *commit* que fecha M5 — **decidida** | A fase local é um produto completo pelo Termo (E1–E11); a fase GCP é `v2.0.0` (E12 muda a plataforma, é *major*) | "1.0" sem nuvem pode parecer prematuro a quem lê o repositório sem o Termo |
| `v0.12.0` | Uma versão por etapa, cabe no histórico | Sugere que nada está pronto até a nuvem, o que contradiz o Termo |
| `v1.0.0-local` | Diz a fase no nome | Pré-release no semver significa "instável", que não é o caso |

### D48 — se `--historico` achar segredo — decidido: as duas linhas abaixo, cada uma no seu caso

| Opção | A favor | Contra |
|---|---|---|
| **Senha de contêiner local:** regenerar (`make env`), registrar o achado no dossiê, **não** reescrever histórico — **decidida** | Uma senha de PostgreSQL em `localhost` que já foi trocada não dá acesso a nada; reescrever histórico num repositório público quebra clones e apaga a prova de que o processo funcionou | O texto continua no histórico, e um leitor pode não saber que foi rotacionada |
| Chave de nuvem ou token de serviço externo: revogar **e** reescrever (`git filter-repo`), *force push* | Única resposta que o valor da chave admite | Reescrever `main` publicada; só com a sua mão |

Hoje **[medido]** não há chave de nuvem em lugar nenhum do projeto — a fase GCP ainda não
começou. A segunda linha é para o caso de a varredura surpreender.

---

## 11. Riscos deste plano

- **`make reset` é destrutivo** e o pacote de B4 é a única volta. Por isso B4 antes; por isso
  `recovery-verify` antes do `reset`; por isso o `reset` continua pedindo confirmação.
- **Tempo de relógio de B5**: ~2 h de trocas de ambiente, mais a sincronização do Airbyte
  (3–4 min por conexão) e o *snapshot* do Beam; não cabe num fim de tarde com o ambiente de
  trabalho aberto. A medição do pico é mais fiel com menos coisa aberta — o estado da estação é
  anotado, não controlado.
- **Divergência entre Execução Local e realidade** é o achado esperado de B5, não uma surpresa:
  cada uma vira correção no documento **antes** do fechamento, e a lista entra no dossiê.
- **R11**: o preflight decide; `FORCE=1` só com a sua autorização, como sempre.

---

## 12. O que pedir ao outro agente

Duas revisões, nos dois momentos em que ele rende mais:

1. **Deste plano, antes do código.** O que perguntar a ele: (i) algum critério do plano ou do
   Termo ficou sem comando que o prove? (ii) a ordem B4 → B5 tem furo — algo que o `reset`
   destrói e o pacote não guarda? (iii) o instrumento de B1 mede o que o §2.8 disse que faltava
   medir, ou mede outra coisa? (iv) B2 e B3 têm falso-negativo óbvio (padrão que não pega, âncora
   que o GitHub resolve e a ferramenta não)? (v) as decisões da §10, já tomadas, têm consequência que não vi?
   O parecer entra neste arquivo, como na Etapa 10, e o plano é reescrito antes de B1 começar.
2. **Da entrega, com o dossiê** (`REVISAO.md`), como na Etapa 11: onde gastar esforço é o
   declarativo novo — `medir.sh`, `recovery.py`, `docs_check.py`, o modo `--historico` — e as
   tabelas medidas da Capacidade; o derivado é o diário de B5.
