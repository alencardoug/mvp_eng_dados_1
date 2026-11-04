# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `origin/main..0ce2a23` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
f198736 docs: registra entre os segredos tratados o falso positivo do pgcli em e3c226c
df0781f test: confere os trechos que o catálogo gera a partir dos modelos
b3d2fe5 feat: diz quando a fase de recuperação da captura não tem nada devido
36394e0 docs: registra os resultados da regeneração da v1.1.0 nos documentos donos
0ce2a23 docs: declara o pulo da prova do diário de mutações depois da recarga do legado
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 11 arquivos

- `README.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `docs/segredos_tratados.yml`
- `docs/streaming.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/models/export.py`
- `tests/test_portoes_da_captura.py`
- `tests/test_trechos_gerados.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega:** não há gerador nesta entrega; o que pede revisão integral é:

- `docs/segredos_tratados.yml` — a entrada nova (`e3c226c`, `Makefile`, `PGPASSWORD`) é uma
  declaração de que um achado é falso positivo; se estiver errada, esconde um segredo;
- `export.TRECHOS` em `src/mvp_ed1/models/export.py` — a lista de quais trechos o teste novo
  confere; o que ficar fora dela continua sem conferência;
- **os números dos documentos** (Capacidade §2.13 e §3, *Streaming* §7.3, Pendências D65/D66/D67,
  Plano "Versão de manutenção `v1.1.0`"): são transcrição à mão do diário da 1.6, a fonte da
  verdade — `data/medicoes/diario_v1_1_0.md` e `data/medicoes/v1_1_0/*` (fora do Git, neste
  *checkout*). Conferir por amostragem contra o diário é o melhor uso de esforço aqui.

Contexto: é a etapa 1.9 do [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/3c9ab4e/PLAN.md#62-the-stages)
— os resultados da regeneração nos documentos donos (§8 do roteiro), o §5.6 (o falso positivo) e
três pendências que a 1.6 deixou. **Só a 1.9**, por decisão do Owner; a revisão da v1.1.0 inteira
(`v1.0.0..HEAD`) é outra rodada, depois desta.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
........................................................................ [ 88%]
........................................................................ [ 96%]
..............................                                           [100%]
=========================== short test summary info ============================
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_remocao.py:597: sem mutações no diário: a prova entre capturas ainda não aconteceu
891 passed, 3 skipped in 349.89s (0:05:49)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **Nenhum número dos documentos foi conferido por máquina contra o diário.** Transcrevi as onze
  linhas da Capacidade §2.13 das linhas `| alvo | … |` do diário (cada uma é a saída do `medir`) e
  os cortes do *Streaming* §7.3 das linhas C3, C4, E3–E11. Erro de transcrição passa por todo teste.
- **Interpretações, não medições:** "a folga maior vem do *host*, que começou o ciclo com 7,5 GB
  livres" (Capacidade §2.13, item 1) é leitura minha de P6 (7,47 GiB) contra o B5 (8,0 GB); não há
  medida que separe as causas. O texto marca como não medido só o 0,5 GB das tarefas novas.
- **Unidades:** o `medir` imprime "GB" e o P6 lê `/proc/meminfo` em kB (7.832.536 kB = 7,47 GiB);
  escrevi 7,5 GB sem conferir se o `medir` usa GiB. Os tamanhos do pacote — 38 MB (`du -sh`, MiB) e
  26,6 MB (26.624.372 bytes, decimal) — misturam as duas bases.
- **A D66 com 16 remessas**: do E1 (reconciliação da P13 no dado novo); o total de remessas legadas
  entregues não foi recontado, e o texto diz isso.
- **"306 testes Python a mais que no B5"** = 885 (F1) − 579 (Plano, Etapa 12); não sei quantos são
  da v1.1.0 e quantos de antes dela, e por isso tirei a atribuição.
- **A linha nova da recuperação** só rodou com dublês (`tests/test_portoes_da_captura.py`); nenhum
  `sync-legacy` real rodou depois de `b3d2fe5`. A DAG (`retomar_capturas_do_legado`) **não** ganhou
  linha equivalente, e não conferi o que o *log* dela diz quando nada está devido.
- **Âncoras externas**: o `docs-check` confere links e âncoras do repositório, não as do GitHub. As
  quatro âncoras do `bi-como-codigo` em `3c9ab4e` (`#12-the-decisions`, `#62-the-stages`,
  `#5-part-i--maintenance-release-v110-of-eng_dados`, e `#4-the-cycle` no roteiro) foram escritas
  pela regra de âncora do GitHub e **não abertas**. O `3c9ab4e` está publicado (`ls-remote` =
  `HEAD`, 04/11/2026).
- **`desatualizados()`** exige uma quebra de linha logo depois do marcador inicial e antes do final,
  como `_substituir` escreve; um documento editado à mão sem essas quebras é acusado como
  divergente, e não como malformado — não testei essa forma.
- O `make check` desta entrega não teve o `PASS=` do dbt colado acima (o dossiê guarda o fim da
  saída); "as quatro etapas passaram" inclui a etapa 2.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- Que a varredura do histórico identifica o achado por (commit, caminho, chave) com a chave
  `PGPASSWORD` — confirmado pelo resultado (`make secrets-history` → "nada não tratado (12
  achado(s), todos registrados)", 04/11/2026), não pela leitura do código dela.
- Que a revisão dos arquivos rastreados acusa o texto `PGPASSWORD=` seguido de `$$` em qualquer
  arquivo, inclusive no próprio registro — **confirmado da pior forma**: a primeira versão do motivo
  citava a linha inteira e derrubou o `check-offline`; o motivo agora a descreve sem citá-la.
- Que o diário da 1.6 é fiel ao que rodou: ele foi escrito durante a execução, com as saídas em
  arquivo ao lado de cada linha, mas é um arquivo à mão fora do Git.

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

**Esta revisão não precisa de nada além dos três bancos** — e, para conferir números, dos arquivos
fora do Git: `data/medicoes/diario_v1_1_0.md`, `data/medicoes/v1_1_0/` e
`data/recovery/aprovado/` (o pacote v1.1.0; `make recovery-verify` o confere sem tocar nos bancos).

Estado encontrado em 04/11/2026, no fim desta entrega: os três bancos e o Airflow de pé, a DAG
`fluxo_batch` **despausada** (só disparo externo — não dispare), Airbyte e *streaming* pausados —
o estado que a 1.6 devolveu. O armazém é o da restauração do G7 mais o `dbt build` do `make check`
acima, sem `RESET`. Captura selecionada: 67 (a da restauração).

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Escrever a subseção da v1.1.0 no Plano antes do aceite**, com a revisão, o aceite e a *tag*
  marcados "pendente". A alternativa era esperar o aceite e escrever tudo de uma vez; escolhi agora
  para que esta revisão cubra o texto que vai ficar. O aceite só troca os três "pendente".
- **A D65 e a D67 foram para a §2 das Pendências** (decisões fechadas, uma entrada por decisão), e
  não para a §1.1, que guarda o relato do aceite de cada etapa.
- **O teste dos trechos gerados como pytest *offline***, e não como `export --check` na etapa 3 do
  `make check`, ao lado de `sensitivity --check` e `lineage --check`. O pytest roda no
  `check-offline`, sem banco, e pega o defeito antes do *commit*; o custo é a conferência morar num
  lugar diferente das outras duas.
- **A linha da recuperação só na CLI**, porque o desvio D2 era da CLI; a da DAG não foi tocada (§4).
- **A Capacidade §3 guardou o parágrafo de 25/09** como histórico e ganhou um "Substituído em
  04/11/2026", em vez de reescrever o estado corrente; o §8 do roteiro diz que o histórico não se
  reescreve, e o pacote do B5 continua existindo, fora do *checkout*.
- **A D66 recebeu o número novo (16)** sem reabrir a decisão: ela segue adiada para depois da
  v1.1.0, e o "efeito de não decidir" ficaria falso com o 12.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV19-01 | `docs/capacidade_e_recuperacao.md:557` | A comparação chama a **soma dos três bancos** de tamanho do armazém: 724 MB e 628 MB são os totais arredondados. As saídas finais dão `WAREHOUSE_DB` de 646,4 MB e 553,0 MB, respectivamente. Corrigir o objeto da comparação ou usar os tamanhos do armazém, preservando o histórico do §2.12. Evidência E1. | `bloqueante` | **Corrigido.** Reproduzido: `WAREHOUSE_DB` 646.4 MB (G7) e 553.0 MB (B5), soma 723.8 e 627.9. O item 2 da §2.13 compara agora o `WAREHOUSE_DB` (646,4 MiB × 553,0 MiB) e dá a soma dos três bancos à parte. §2.12 intocado. |
| RV19-02 | `docs/capacidade_e_recuperacao.md:560` | O parágrafo sobre o custo da **restauração G7** atribui 885 testes Python ao `check` dela, mas foram **886**. Os 885 pertencem ao F1, anterior à guarda acrescentada em `6d93d72`. A linha F1 da tabela e a diferença de 306 contra o B5 estão corretas; o erro está na associação dentro deste parágrafo. Evidência E2. | `bloqueante` | **Corrigido.** Reproduzido: G7 linha 4075, `886 passed`. O item 2 diz agora "o `check` do passo 8, que rodou 886 testes Python contra 579". |
| RV19-03 | `docs/capacidade_e_recuperacao.md:518`; `docs/capacidade_e_recuperacao.md:605` | As medições novas usam rótulos GB/MB sem declarar a base: memória e tamanhos dos bancos vêm de divisões por 1024; o pacote de 38 vem de `du -sh` (MiB), enquanto os 26,6 MB do dump vêm de 26.624.372 bytes em base decimal. Não são unidades intercambiáveis. Explicitar a convenção dos utilitários e distinguir MiB/GiB de MB/GB no texto novo, sem reescrever medições históricas. Evidência E3. | `bloqueante` | **Corrigido.** Reproduzido: `formatar`, `medir.sh` e `docker stats` dividem por 1024. A §2.13 declara uma vez que as unidades são binárias e escreve GiB/MiB na tabela e no texto. §3.1: 37,4 MiB (39.214.755 bytes), dos quais 25,4 MiB (26.624.372 bytes); a medida de 25/09 fica como está, com a nota de que a base dela não foi registrada. |
| RV19-04 | `docs/capacidade_e_recuperacao.md:554` | “A folga maior vem do host” afirma uma causa que não foi medida. A P6 registra 7,47 GiB disponíveis no início, contra 8,0 na execução B5; isso não isola a causa da diferença durante a DAG. O próprio dossiê admite que não há medida que separe as causas. Marcar essa explicação como hipótese/não medida, ou retirar a atribuição causal; o rótulo “Não medido” atual só alcança o custo das tarefas novas. Evidência E4; P5 e `CLAUDE.md` §5. | `bloqueante` | **Corrigido.** A atribuição causal saiu. Além de não medida, ela se contradizia: o *host* começou com **menos** memória livre que no B5 (7,47 × 8,0 GiB). O item 1 dá os dois números e marca como não medido por que o mínimo livre durante a DAG foi maior. |
| RV19-05 | `tests/test_trechos_gerados.py:15`; `src/mvp_ed1/models/export.py:254` | A suíte nova passa por vacuidade se a declaração `TRECHOS` ficar vazia: `desatualizados()` devolve `[]`, e as duas contraprovas substituem a declaração por seus próprios exemplos. Reproduzido sem editar arquivos: os três testes passam com `TRECHOS = ()`. Acrescentar uma verificação independente de cobertura da declaração, incluindo lista vazia e omissão de um trecho. **A declaração atual está completa**: três trechos neste módulo; a linhagem tem conferência própria. Evidência E5. | `ajuste` | **Corrigido.** Reproduzido: com `TRECHOS = ()` os três testes passavam. Novo `test_todo_trecho_marcado_esta_declarado_uma_vez`: inventaria os marcadores em `docs/**/*.md` e exige `TRECHOS` ∪ {linhagem do Dicionário, trecho 2} igual ao inventário, sem duplicata e sem a linhagem em `TRECHOS`. Contraprovas em memória: real passa; vazio, sem o diagrama, duplicado e linhagem declarada falham. |
| RV19-06 | `docs/plano_de_desenvolvimento.md:339`; `docs/capacidade_e_recuperacao.md:521` | Resultados foram transcritos em mais de um dono documental: 885 testes no Plano e na Capacidade; o resultado da D65 no Plano e em Pendências; 13.725 eventos na Capacidade e em Streaming. Os números conferem hoje, mas há múltiplas cópias manuais. Manter no Plano os critérios e os vínculos às evidências, e nas demais referências o vínculo ao dono do resultado, conforme `CLAUDE.md` §5 e o roteiro §8. Evidência E6. | `ajuste` | **Corrigido.** Capacidade §2.13: os rótulos de linha não repetem mais `PASS=907`, os 885 testes nem os 13.725 eventos; a linha C3 aponta para o *Streaming* §7.3, dono do evento. Pendências, D65: o resultado no armazém saiu e a entrada aponta para os critérios da versão de manutenção no Plano, que ficam como dono. `rg` dos três números agora: só *Streaming* (13.725) e Plano (885 e o resultado da D65). |

### Rodada 2

Revisão de confirmação em 04/11/2026, restrita a `bd5e3f8..009d743`: `5b7de16`,
`6be1a6a` e `009d743`. `HEAD` conferido: `009d7437b5286a8aed9eb36a1bdc56cdfe13e52c`.
As seis respostas da coluna *Situação* foram reproduzidas independentemente. Este parecer
não constitui aceite do Owner nem revisão da versão inteira.

**Fechados:** **RV19-01** — E1 reexecutado, Capacidade:559–560 (R2-E1); **RV19-02** — `rg -n '^886 passed|8/9|passo 8'` no G7, Capacidade:563–564 (R2-E1); **RV19-03** — E3 reexecutado, sonda de bytes/unidades e comparação com `bd5e3f8`, Capacidade:515–517 e 608–610 (R2-E2); **RV19-04** — diário P6:22 contra Capacidade §2.12:491–493 e texto corrigido:553–558 (R2-E2); **RV19-06** — E6 reexecutado e as duas âncoras conferidas (R2-E4).

**Não fechado: RV19-05.** A declaração real passa, e vazio, omissão simples, duplicação e
inclusão da linhagem falham como informado; permanece a contraprova com marcador malformado.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV19-2-01 | `tests/test_trechos_gerados.py:23–27` | **RV19-05 parcialmente resolvido.** O inventário conta somente pares completos encontrados pela expressão regular; um marcador sem par desaparece dele. Retirando **em memória** o último `FIM` do Modelo de Dados e a entrada do diagrama em `TRECHOS`, restam dois inícios e um fim, mas o inventário passa e `desatualizados()` retorna `[]`; a suíte inteira desse arquivo dá **`4 passed in 0.13s`**. Um início órfão acrescentado ao documento também passa com a declaração real. Validar integridade e ordem dos marcadores independentemente de `TRECHOS`, com contraprova que rejeite esse desaparecimento. Evidência R2-E3. | `ajuste` | **Corrigido.** Reproduzido: `4 passed` com o último `FIM` do Modelo retirado e o diagrama fora de `TRECHOS`. O inventário agora lê os marcadores um a um (`_pares`): a sequência tem de alternar início e fim, começando no início, e um marcador sem par, fora de ordem ou aninhado derruba o teste com o nome do documento. Contraprovas permanentes: `test_pares_conta_trechos_completos` (0, 1, 2 pares) e `test_contraprova_marcador_sem_par_e_acusado` (fim apagado, início órfão, fora de ordem, aninhado, fim a mais). A tua sonda de R2-E3, repetida: sem o último `FIM` + sem diagrama → falha; início órfão no Modelo → falha. |
| RV19-2-02 | `tests/test_trechos_gerados.py:26` | **Limite de cobertura observado em RV19-05:** a busca é explicitamente `(export.ROOT / "docs").rglob("*.md")`. Um par completo não declarado acrescentado **em memória** ao `README.md` fica invisível: `real + par não declarado no README: inventário=PASSA; desatualizados=[]`. Hoje os únicos Markdown rastreados com o marcador são os dois documentos em `docs/`; portanto não há omissão atual comprovada fora desse diretório. A garantia não abrange todo Markdown do repositório; ampliar esse alcance é assunto posterior, não condição adicional para esta correção em `docs/`. Evidência R2-E3. | `observação` | **Tratado agora, por ser barato.** O inventário passou de `docs/**/*.md` para todo Markdown rastreado (`git ls-files '*.md'`). A tua sonda do par não declarado no README, repetida: falha, com `(README.md, 0)` sobrando no inventário. Hoje só os dois documentos de `docs/` têm o marcador (`git ls-files '*.md' \| xargs grep -l`). |

#### R2-E1 — objeto comparado e testes do passo 8

E1 reexecutado literalmente; saída:

```text
4135:WAREHOUSE_DB       646.4 MB
4138:soma dos três bancos: 723.8 MB
4123:WAREHOUSE_DB       553.0 MB
4126:soma dos três bancos: 627.9 MB
```

`rg -n '^886 passed|8/9|passo 8' data/medicoes/v1_1_0/G7_a1_recovery_restore.txt`:

```text
316:── 8/9 reconstruindo sem apagar o que acabou de voltar ──
4075:886 passed, 3 skipped in 365.07s (0:06:05)
4084:  As oito fronteiras e os testes de dados são do `make check` do passo 8.
```

O item 2 corrigido identifica `WAREHOUSE_DB` e distingue a soma (Capacidade:559–560):

> 2. **A restauração custou 19m 51s**, 2m 52s a mais que no B5, sobre um armazém (`WAREHOUSE_DB`) de
>    646,4 MiB contra 553,0 MiB no fim de cada uma — na soma dos três bancos, 723,8 MiB contra 627,9 MiB.

E atribui os testes ao passo certo (Capacidade:563–564):

>    do B5. **Não medido:** quanto do tempo a mais vem dessa memória e quanto do `check` do passo 8,
>    que rodou 886 testes Python contra 579.

#### R2-E2 — unidades, histórico e comparação com B5

E3 reexecutado: `formatar` continua dividindo por 1024 (`report.py:57`); o medidor divide
`MemAvailable` por 1024 (`medir.sh:65`) e novamente por 1024 para exibir GB (`medir.sh:190`).
O tratamento de `docker stats` converte GiB/TiB/KiB para a mesma base (`medir.sh:83–85`).
Comparação das funções com `git show 7b0bea6:<arquivo>` — o commit do pacote B5:

```text
docker/medir.sh:_mem_disponivel igual ao commit do pacote B5: True
docker/medir.sh:_mem_conteineres igual ao commit do pacote B5: True
docker/medir.sh:_gb igual ao commit do pacote B5: True
src/mvp_ed1/generator/report.py:formatar igual ao commit do pacote B5: True
```

Logo, escrever também 8,0 / 6,5 / 1,1 **GiB** nos comparativos novos preserva a base dos
números de B5. Não é conversão de GB decimal. As seções históricas permanecem intactas.

Sonda Python: comparação literal do prefixo anterior a `### 2.13 ` com
`git show bd5e3f8:docs/capacidade_e_recuperacao.md`; busca `\b(?:GB|MB)\b` na §2.13;
`du -sb` para o total, `stat().st_size` para o dump e divisão por `1024**2`:

```text
Antes da §2.13 idêntico: True
GB/MB na §2.13: ['o `docker stats` dividem por 1024, e o que as saídas rotulam "GB" e "MB" é GiB e MiB — é assim que']
Declarações de base binária: 1
pacote: 39214755 bytes = 37.4 MiB
warehouse_memoria.dump: 26624372 bytes = 25.4 MiB
P6: 7832536 / 1024**2 = 7.47 GiB < 8.0 GiB
```

Não sobrou rótulo GB/MB aplicado a medida na seção nova: a única ocorrência é a explicação
dos rótulos antigos. `du -sh` devolveu `38M`; `du -sb`, `39214755`. A §3.1:608–610 conserva
o histórico e apresenta corretamente a medida nova:

> No corte de 25/09/2026: 32 MB, dos quais 20,7 MB são a memória do armazém — a base dessas duas
> medidas não foi registrada. No de 04/11/2026: 37,4 MiB (39.214.755 bytes), dos quais 25,4 MiB
> (26.624.372 bytes) são a memória do armazém.

P6:22 foi relido e confirma os 7.832.536 kB / 7,47 GiB. As saídas originais do B5 também
foram relidas com `rg -n '\| up \|' .../20260925T124819Z_73_l1_up.log` e
`rg -n '6,5 GB|1,1 GB' .../20260925T134425Z_73_l5_dag_run_refeito.log`:

```text
55:| up | nada | 0m 07s | 8,0 GB | 0,1 GB | 2 amostras, uma a cada 2,0 s (pausa de 2 s) | 22.0 MB |
64:| dag-run | Airbyte,Airflow,bancos | 6m 41s | 1,1 GB | 6,5 GB | 95 amostras, uma a cada 4,2 s (pausa de 2 s) | 325.1 MB |
```

**Confirma-se a comparação numérica da resposta:** havia menos memória disponível no início
da regeneração. Isso não prova nem refuta isoladamente uma causa para o mínimo durante a DAG:
P6 é uma leitura inicial, o 8,0 de B5 é o mínimo amostrado no `up`, e a carga restante do
host não foi controlada. A correção resolve RV19-04 porque retirou a causa e declara
(Capacidade:557–558):

> com 7,47 GiB livres, menos que os 8,0 GiB do B5. **Não medido:** por que o mínimo livre durante a
> DAG foi maior, e quanto do 0,5 GiB a mais nos contêineres é das tarefas novas.

#### R2-E3 — contraprovas do inventário, sem editar arquivos

Sonda executada com `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -`, usando `runpy.run_path`
para carregar o teste novo e `unittest.mock.patch` para substituir somente objetos em memória.
Para cada caso, foi chamado o próprio `test_todo_trecho_marcado_esta_declarado_uma_vez` e,
separadamente, `export.desatualizados()`. Saída literal:

```text
TRECHOS real: [('dicionario_de_dados.md', 0, 'dicionario_markdown'), ('modelo_de_dados.md', 0, 'inventario_markdown'), ('modelo_de_dados.md', 1, 'diagrama_markdown')]
inventário real: [('docs/dicionario_de_dados.md', 0), ('docs/dicionario_de_dados.md', 1), ('docs/modelo_de_dados.md', 0), ('docs/modelo_de_dados.md', 1)]
real: inventário=PASSA; desatualizados=[]
vazio: inventário=FALHA; desatualizados=[]
sem diagrama: inventário=FALHA; desatualizados=[]
duplicado: inventário=FALHA; desatualizados=[]
linhagem declarada: inventário=FALHA; desatualizados=['docs/dicionario_de_dados.md (trecho 2)']
modelo sem o último FIM: inícios=2fins=1
sem diagrama + seu marcador final ausente: inventário=PASSA; desatualizados=[]
real + início órfão no Modelo: inventário=PASSA; desatualizados=[]
README virtual: inícios=1fins=1
real + par não declarado no README: inventário=PASSA; desatualizados=[]
```

As cinco declarações usadas foram `real`, `()`, `real[:-1]`, `real + (real[0],)` e
`real + ((export.DICIONARIO, 1, lambda: ''),)`. Nos cenários de marcadores, `Path.read_text`
foi substituído por função que devolvia o texto virtual apenas para o caminho escolhido e
delegava as demais leituras ao método original. O início órfão foi anexado ao Modelo; o par
completo, ao README. Ambos usaram `real` sem modificações.

Reprodução completa da lacuna com a suíte, também executada:

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python - <<'PY'
from pathlib import Path
from unittest.mock import patch
import pytest
from mvp_ed1.models import export
read = Path.read_text
text = read(export.MODELO, encoding='utf-8')
head, tail = text.rsplit(export.FIM, 1)
def altered(path, *args, **kwargs):
    return head + tail if path == export.MODELO else read(path, *args, **kwargs)
with patch.object(Path, 'read_text', altered), patch.object(export, 'TRECHOS', export.TRECHOS[:-1]):
    raise SystemExit(pytest.main(['-q', '-p', 'no:cacheprovider', 'tests/test_trechos_gerados.py']))
PY
```

```text
....                                                                     [100%]
4 passed in 0.13s
```

O defeito é da guarda; os documentos reais continuam com quatro pares completos, conferidos
por `rg -n 'gerado a partir dos modelos|fim do trecho gerado' docs` (E5). A varredura dos
Markdown retornados por `git ls-files '*.md'`, procurando `export.INICIO`, confirmou:

```text
Markdown rastreado com marcador inicial: ['docs/dicionario_de_dados.md', 'docs/modelo_de_dados.md']
```

#### R2-E4 — um dono por resultado e links

E6 reexecutado literalmente; saída:

```text
docs/plano_de_desenvolvimento.md:339:0 vendidos antes do lançamento, de 7.500 do varejo e de 238 do legado
docs/plano_de_desenvolvimento.md:339:885 testes Python
docs/streaming.md:363:13.725 eventos
```

A busca ampliada desses três resultados em todo `docs/` devolveu as mesmas três ocorrências.
O resultado da D65 e os 885 testes estão nos critérios da versão de manutenção do Plano;
os eventos estão em Streaming §7.3. O dado histórico de 3.130 itens na D65 não é o resultado
novo. Conferência dos links extraídos por `docs_check.ler`, verificando arquivo de destino
e presença do fragmento em `Documento.ancoras`:

```text
docs/capacidade_e_recuperacao.md:523 -> streaming.md#73-a-regeneração-da-v110--04112026: True
docs/pendencias.md:213 -> plano_de_desenvolvimento.md#versão-de-manutenção-v110: True
```

#### R2-E5 — regressões e limites da rodada

`git show 5b7de16 --format= -- docs/capacidade_e_recuperacao.md docs/pendencias.md` lido
integralmente. Não foi encontrado número alterado além do pedido: separação armazém/soma,
886 no passo 8, 7,5 arredondado substituído pelo 7,47 da P6, unidades e bytes do pacote,
e retirada das cópias de resultados. Os valores de B5 acrescentados ao comparativo já
constavam da §2.12. A remoção dos rótulos `PASS=907` acompanha a retirada das cópias.

Comparação por Python das colunas de medidas da tabela anterior e posterior, normalizando
somente GB/GiB e MB/MiB:

```text
11 linhas: estado, duração, memória, amostras e bancos inalterados: True
```

Verificações executadas com bytecode e cache do pytest desativados. Saída recortada de
`PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider' make check-offline`, saída 0:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1099 links de arquivo, 188 âncoras, 664 citações de ADR — nada quebrado
713 passed, 182 deselected in 149.86s (0:02:29)
check-offline: as três etapas passaram
```

`PYTHONDONTWRITEBYTECODE=1 make secrets-history`, saída 0; linha final literal:

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Após a inclusão desta rodada, `docs-check` passou novamente e `git diff --check` não
produziu saída. Nenhuma regressão foi observada nas verificações executadas; a lacuna da
guarda reproduzida em R2-E3 permanece como ajuste.

Os 182 testes de integração foram enumerados pelo alvo e não executados. Não houve SQL,
escrita nos bancos, mudança no estado dos serviços, disparo/pausa da DAG, commit ou push.
Somente `REVISAO.md` foi editado; os dois arquivos não rastreados já presentes foram preservados.

### Rodada 3

Confirmação em 04/11/2026, limitada a `31b99d8^^..31b99d8` (`e608146` e `31b99d8`).
`HEAD`: `31b99d83dc3563bf39210389862d2c7b4c5616f3`. Lidos os dois diffs e as duas respostas
da rodada 2. Nenhum achado já fechado nas rodadas anteriores foi reaberto.

- **RV19-2-01 fechado.** As duas sondas de R2-E3 agora falham na asserção de `_pares`, com
  `3 marca(s)` para o último `FIM` ausente mais diagrama omitido e `5 marca(s)` para o início
  órfão. A sequência de marcadores literais é validada antes da contagem (R3-E1).
- **RV19-2-02 fechado.** O par não declarado no README agora derruba a igualdade do inventário.
  `_rastreados()` usa `git ls-files -z '*.md'` com `check=True`; fora do Git produz
  `CalledProcessError, exit=128`, e sem o executável produz `FileNotFoundError` (R3-E1).

**Sem ajustes ou bloqueantes remanescentes: a revisão da etapa 1.9 pode ser encerrada.**
A observação abaixo registra o alcance da guarda e não exige correção nesta entrega.
Este parecer não substitui o aceite do Owner nem a revisão posterior de `v1.0.0..HEAD`.

**Conferido:** as três sondas de R2-E3, marcadores em código/aninhados/quebrados, codificação, ausência de Git/checkout, arquivos com marcadores, oito contraprovas permanentes e `make check-offline` (721 testes).

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV19-3-01 | `tests/test_trechos_gerados.py:38` | **Limite lexical observado ao ampliar a sonda de RV19-2-01.** Se **ambos** os delimitadores do diagrama forem quebrados em duas linhas e sua declaração for removida, o trecho deixa de ter qualquer marcador literal reconhecido: o inventário passa, `desatualizados=[]` e **`12 passed in 0.13s`** na suíte desse arquivo (R3-E3). Um único delimitador quebrado é rejeitado. Classificado como observação porque `_substituir` e `desatualizados()` também usam os literais exatos: aceitar ou identificar variantes de espaço/quebra de linha amplia esse vocabulário, enquanto o achado anterior tratava de marcadores exatos sem par. Os quatro pares atuais continuam íntegros; não há ajuste exigido para encerrar esta rodada. | `observação` | **Aceita como limite e registrada no dono.** Concordo com a leitura: o gerador e a conferência usam os mesmos literais, e um trecho sem nenhum marcador inteiro deixa de ser trecho para os dois. Reconhecer variantes ampliaria o vocabulário dos dois lados sem proteger contra defeito observado. O limite está na docstring de `_pares` (`tests/test_trechos_gerados.py`), com o ID. |

#### R3-E1 — sondas originais, alcance e falhas explícitas

Executado com `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -`, carregando o teste por
`runpy.run_path('tests/test_trechos_gerados.py')`. As sondas de R2-E3 foram repetidas com
`patch.object(Path, 'read_text', ...)` e `patch.object(export, 'TRECHOS', ...)`, sem editar
documentos. Saída literal dos casos de confirmação:

```text
real: PASSA; desatualizados=[]
último FIM ausente + diagrama omitido: FALHA (/home/doug/Projetos/mvp_eng_dados_1/docs/modelo_de_dados.md: marcadores fora de par ou de ordem: 3 marca(s))
início órfão no Modelo: FALHA (/home/doug/Projetos/mvp_eng_dados_1/docs/modelo_de_dados.md: marcadores fora de par ou de ordem: 5 marca(s))
par completo não declarado no README: FALHA ()
```

No README, a mensagem vazia vem da asserção de igualdade do inventário, que não tem mensagem
própria (`tests/test_trechos_gerados.py:65`); não é erro de leitura. A lista retornada por
`_rastreados()` foi lida em UTF-8 e filtrada pela presença de `export.INICIO` ou `export.FIM`:

```text
Markdown com marcador: ['docs/dicionario_de_dados.md', 'docs/modelo_de_dados.md']
```

Chamadas reais de `_rastreados()`, com `export.ROOT = Path('/')` para testar fora do checkout
e, separadamente, `PATH=/__rv19_sem_executaveis__` somente no processo Python da sonda:

```text
fora do Git: CalledProcessError, exit=128
git ausente: FileNotFoundError
```

**Concordo com `check=True`:** sem Git ou sem checkout não há inventário confiável de arquivos
rastreados; interromper a verificação torna essa condição visível. Um arquivo-fonte distribuído
sem `.git` ou um contêiner sem Git não ganha um resultado verde por inventário vazio.

#### R3-E2 — formas adicionais e contraprovas permanentes

Na mesma sonda, um marcador inicial em bloco cercado ou código inline foi anexado ao README;
um par completo foi anexado dentro de bloco cercado; um início foi inserido dentro do último
trecho do Modelo; e o último fim foi quebrado em duas linhas, com o diagrama omitido:

```text
início em bloco cercado no README: FALHA (/home/doug/Projetos/mvp_eng_dados_1/README.md: marcadores fora de par ou de ordem: 1 marca(s))
início em código inline no README: FALHA (/home/doug/Projetos/mvp_eng_dados_1/README.md: marcadores fora de par ou de ordem: 1 marca(s))
par em bloco cercado no README: FALHA ()
início dentro do último trecho: FALHA (/home/doug/Projetos/mvp_eng_dados_1/docs/modelo_de_dados.md: marcadores fora de par ou de ordem: 5 marca(s))
último FIM quebrado em duas linhas: FALHA (/home/doug/Projetos/mvp_eng_dados_1/docs/modelo_de_dados.md: marcadores fora de par ou de ordem: 3 marca(s))
```

O parser lê texto bruto, assim como o gerador: código cercado/inline não oculta marcadores.
Isso também significa que exemplos literais desses marcadores contam no inventário.
Para a codificação, a leitura virtual de um trecho codificado em Latin-1 foi decodificada
com o `encoding='utf-8'` que `_marcados()` exige; também foi testado um BOM antes do início:

```text
Documento Latin-1 lido com encoding=utf-8: UnicodeDecodeError
UTF-8 com BOM: 1 par
```

As oito parametrizações permanentes foram chamadas diretamente. A expansão com os dois
`replace` foi comparada com a sequência obtida caractere a caractere do molde; `sys.settrace`
confirmou que cada caso alcança a asserção de `_pares` na linha 40. Em seguida, somente em
memória, a função foi substituída por uma que devolve a contagem esperada mais um nos casos
válidos, e por uma que retorna zero sem validar nos inválidos. Todos os testes rejeitaram
esses comportamentos incorretos:

```text
I/F ausentes dos dois marcadores: True
'': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (AssertionError)
'I x F': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (AssertionError)
'I x F I y F': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (AssertionError)
'I x F I y': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (Failed)
'I x F I': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (Failed)
'F x I': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (Failed)
'I x I y F F': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (Failed)
'I x F F': expansão correta; assert de _pares alcançado; teste real PASSA; mutante rejeitado (Failed)
```

`Failed` é a falha de `pytest.raises` quando o comportamento substituto não lança a exceção
esperada. As contraprovas não passam por colisão de “I”/“F” nem por uma falha anterior ao parser.

#### R3-E3 — reprodução do limite lexical

Executado sem alterar arquivos:

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python - <<'PY'
from pathlib import Path
from unittest.mock import patch
import pytest
from mvp_ed1.models import export
read = Path.read_text
text = read(export.MODELO, encoding='utf-8')
head, tail = text.rsplit(export.INICIO, 1)
modified = head + export.INICIO.replace('a partir', 'a\npartir') + tail.replace(export.FIM, export.FIM.replace('fim do', 'fim\ndo'), 1)
def altered(path, *args, **kwargs):
    return modified if path == export.MODELO else read(path, *args, **kwargs)
with patch.object(Path, 'read_text', altered), patch.object(export, 'TRECHOS', export.TRECHOS[:-1]):
    raise SystemExit(pytest.main(['-q', '-p', 'no:cacheprovider', 'tests/test_trechos_gerados.py']))
PY
```

```text
............                                                             [100%]
12 passed in 0.13s
```

#### R3-E4 — regressão e preservação do ambiente

`PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider' make check-offline`,
código de saída 0; recorte literal:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1099 links de arquivo, 188 âncoras, 664 citações de ADR — nada quebrado
721 passed, 182 deselected in 146.98s (0:02:26)
check-offline: as três etapas passaram
```

Os 182 testes de integração não foram executados. Após a inclusão da rodada, `docs-check`
passou novamente e `git diff --check` não produziu saída. Somente `REVISAO.md` foi editado;
nenhuma correção implementada, escrita nos bancos, operação de serviço/DAG, commit ou push.
Os dois arquivos não rastreados encontrados no início foram preservados.

### Evidências dos achados

Revisão em 04/11/2026, limitada a `6d93d72..0ce2a23`; dossiê em `bd5e3f8`.
Os comandos abaixo foram executados neste checkout. Saídas recortadas são identificadas como tal.
Os vereditos não constituem aceite do Owner.

#### E1 — tamanho do armazém e soma dos bancos

```bash
rg -n 'WAREHOUSE_DB|soma dos três' data/medicoes/v1_1_0/G7_a1_recovery_restore.txt | tail -2
rg -n 'WAREHOUSE_DB|soma dos três' data/medicoes/b5/20260925T154755Z_73_l9_recovery_restore_refeito.log | tail -2
```

Saída literal:

```text
4135:WAREHOUSE_DB       646.4 MB
4138:soma dos três bancos: 723.8 MB
4123:WAREHOUSE_DB       553.0 MB
4126:soma dos três bancos: 627.9 MB
```

Os rótulos MB acima são os dos utilitários; a base é tratada em RV19-03.

#### E2 — o `check` da restauração

```bash
rg -n '^886 passed' data/medicoes/v1_1_0/G7_a1_recovery_restore.txt
```

Saída literal:

```text
4075:886 passed, 3 skipped in 365.07s (0:06:05)
```

O diário da 1.6, linha 191 (G7), também declara literalmente:

> **"886 passed, 3 skipped"** (o F1 mais a guarda nova; os mesmos três pulos)

#### E3 — bases das unidades

```bash
rg -n -A 10 'def formatar' src/mvp_ed1/generator/report.py
sed -n '65p;190,191p' docker/medir.sh
du -sh data/recovery/aprovado
du -sb data/recovery/aprovado
```

Saída literal, na ordem dos comandos:

```text
53:def formatar(bytes_: float) -> str:
54-    for unidade in ("B", "kB", "MB", "GB"):
55-        if abs(bytes_) < 1000 or unidade == "GB":
56-            return f"{bytes_:.1f} {unidade}"
57-        bytes_ /= 1024
58-    return f"{bytes_:.1f} GB"
	mb=$(LC_ALL=C awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
	gb=$(LC_ALL=C awk -v m="$1" 'BEGIN{printf "%.1f", m/1024}')
	printf '%s GB' "${gb/./,}"
38M	data/recovery/aprovado
39214755	data/recovery/aprovado
```

A sonda Python executada sobre os pacotes incluiu:

```python
p = Path('data/recovery/aprovado')
print('warehouse dump bytes:', (p/'warehouse_memoria.dump').stat().st_size)
```

Saída literal desse trecho:

```text
warehouse dump bytes: 26624372
```

A origem dos rótulos está em código anterior ao intervalo. O achado desta entrega é sua
reprodução nos resultados novos sem distinguir as bases; não propõe alterar os utilitários nem
as seções históricas nesta revisão.

#### E4 — interpretação apresentada como causa medida

O diário `data/medicoes/diario_v1_1_0.md:22`, P6, registra:

> 7,47 GiB livres (7.832.536 kB), sem *swap* em uso; de pé: os três bancos, o Airflow (4 contêineres, ~860 MiB) e `linkedia-engine-postgres-1`, de outro projeto (23 MiB)

Na coluna de desvio da mesma linha:

> não — o B5 começou com 8,0 GB

O dossiê, §4, explicita a limitação da evidência:

> não há medida que separe as causas. O texto marca como não medido só o 0,5 GB das tarefas novas.

Não se conclui que a explicação seja impossível; conclui-se que os dados apresentados não a
estabelecem. A ressalva precisa acompanhar a afirmação no documento permanente.

#### E5 — contraprova da vacuidade

Executado em memória; nenhum arquivo de código ou documento foi alterado pela sonda:

```bash
.venv/bin/python - <<'PY'
import pytest
from mvp_ed1.models import export
print('TRECHOS real:', [(p.name, n, f.__name__) for p,n,f in export.TRECHOS])
print('desatualizados real:', export.desatualizados())
export.TRECHOS = ()
print('TRECHOS vazio:', export.desatualizados())
raise SystemExit(pytest.main(['-q', '-p', 'no:cacheprovider', 'tests/test_trechos_gerados.py']))
PY
```

Saída literal:

```text
TRECHOS real: [('dicionario_de_dados.md', 0, 'dicionario_markdown'), ('modelo_de_dados.md', 0, 'inventario_markdown'), ('modelo_de_dados.md', 1, 'diagrama_markdown')]
desatualizados real: []
TRECHOS vazio: []
...                                                                      [100%]
3 passed in 0.05s
```

Os quatro pares de marcadores existentes foram inventariados com
`rg -n 'gerado a partir dos modelos|fim do trecho gerado' docs`: dois em
`modelo_de_dados.md`, dois em `dicionario_de_dados.md`. O quarto trecho é a linhagem,
conferida por `src/mvp_ed1/models/lineage.py:338` e pelo `lineage --check` do `make check`.

#### E6 — cópias manuais do mesmo resultado

```bash
rg -n -o '885 testes Python|0\*\* de 7\.500 itens do varejo e 0 de 238 do legado vendidos antes do|0 vendidos antes do lançamento, de 7\.500 do varejo e de 238 do legado|13\.725 eventos' docs/capacidade_e_recuperacao.md docs/streaming.md docs/plano_de_desenvolvimento.md docs/pendencias.md
```

Saída literal:

```text
docs/pendencias.md:211:0** de 7.500 itens do varejo e 0 de 238 do legado vendidos antes do
docs/streaming.md:363:13.725 eventos
docs/plano_de_desenvolvimento.md:339:0 vendidos antes do lançamento, de 7.500 do varejo e de 238 do legado
docs/plano_de_desenvolvimento.md:339:885 testes Python
docs/capacidade_e_recuperacao.md:521:13.725 eventos
docs/capacidade_e_recuperacao.md:526:885 testes Python
```

### Cobertura e validações desta revisão

- Diff dos cinco commits lido integralmente, com os dois declarativos novos conferidos.
  `git diff 6d93d72 0ce2a23 -- docs/adr` não produziu saída. Capacidade §§2.1–2.12 e
  Streaming §7.2 não foram reescritos no intervalo.
- As **11 linhas** da tabela de Capacidade §2.13 foram comparadas por Python aos 11 JSONs
  `*_medir.json`: estado inicial, duração, mínimo disponível, máximo dos contêineres,
  amostras e soma dos bancos coincidem em todas. Também conferidos os volumes e resultados
  associados, as recargas B3/B4 e os comparativos de conteúdo: 17 tabelas na origem principal,
  19 no legado real, com as quatro transições de chave declaradas.
- Streaming §7.3 confrontado com B2, C3/C4 e E1–E11: cortes, contagens, somas, cursor,
  produção, duplicatas, alertas e igualdade da P13. D65 e D66 conferidas contra D5 e E1;
  D67 contra o relato F3 do diário. Os números M3, M7–M9 e M17 do Plano coincidem
  com os registros do `bi-como-codigo`; seus resultados novos coincidem com D5/F1/F3.
  Datas, versões e contagem de cinco pendências do README conferidas nos documentos donos.
- Pacote aprovado: SHA-256 do manifesto
  `3b93d594e202a51b8fa9aff4a781a2a7c384e3eacebb03a87c1dc84e1fc5199f` conferido.
  As três cópias externas existem; todos os checksums conferem: 9 no B5, 9 no corte de recuo,
  11 na cópia da v1.1.0. Commits e cortes coincidem com Capacidade §3.
- `git show e3c226c:Makefile` confirma a referência à variável na linha 798, dentro da macro
  `pgcli`, depois de carregar `.env`; não há senha literal na linha denunciada. A identidade
  `(commit, caminho, chave)` foi conferida em `secrets_review.Achado.identidade`.
- A linha “nada devido” foi revisada junto ao retorno e às barreiras de `recover`, e seus dois
  testes passaram na suíte offline. Nenhuma sincronização real foi disparada; comportamento
  real da CLI após a alteração e logs da recuperação da DAG permanecem **não medidos** nesta
  revisão. A declaração do salto em Qualidade §5 coincide com F1/G7 e com os testes citados;
  o ciclo efêmero de integração não foi reexecutado, pois escreve dados.
- Os títulos das quatro âncoras externas foram conferidos no objeto Git local `3c9ab4e` do
  `bi-como-codigo`; não houve verificação HTTP da renderização do GitHub.

Comandos de verificação executados, todos com código de saída 0 ao concluir. Trechos literais:

```text
$ make check-offline
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1097 links de arquivo, 186 âncoras, 664 citações de ADR — nada quebrado
712 passed, 182 deselected in 147.50s (0:02:27)
check-offline: as três etapas passaram

$ make secrets-history
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))

$ make recovery-verify
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_eng_dados_1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_eng_dados_1/data/recovery/aprovado
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
```

A primeira tentativa de `recovery-verify` foi impedida pelo acesso ao Docker no sandbox;
a repetição autorizada fora dele passou. Não houve restauração, escrita nos bancos, disparo ou
pausa da DAG, commit ou push. Somente este dossiê foi editado.

