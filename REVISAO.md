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
| | | | `bloqueante` · `ajuste` · `observação` | |

