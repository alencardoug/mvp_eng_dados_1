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

