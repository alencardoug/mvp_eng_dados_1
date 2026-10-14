# Plano — os roteiros passo a passo da trilha de estudo (seção 11)

> **O que este arquivo é:** o plano da seção 11 da trilha de estudo da fase local, pedida pelo Owner
> em 12/10/2026, escrito **antes** da execução para o Codex revisar. Segue o formato do
> [plano do material de estudo](PLANO_material_de_estudo.md), de 04/10/2026, e reaproveita as regras,
> os oráculos e as ferramentas de lá.
>
> **O que este arquivo não é:** documento do projeto. Não entra no mapa do README, não decide nada
> sobre o projeto e não altera código, configuração ou camada nenhuma. A trilha que ele planeja também
> não é documento do projeto.

| Campo | Informação |
|---|---|
| Revisão | 5 — responde à segunda rodada do Codex (coluna *Situação* e resposta do autor na §16.8); a 4 deu o escopo dela (§16), a 3 registrou a execução (§15), e a 2 respondeu à primeira rodada (§13 e §14) |
| Data | 12/10/2026 |
| Base | `main` em `c531b87`, publicada; árvore limpa antes deste arquivo |
| Situação | **Executado** entre 12/10/2026 21:03Z e 13/10/2026 00:17Z, com o complemento do PC-2, sem segunda rodada do Codex por decisão do Owner (§14); resultado, desvios e achados na §15. Depois da entrega, o Owner pediu uma segunda rodada curta (§16), respondida em 13/10/2026 |
| Destino | `CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html`, seção 11 nova; cópia privada em https://claude.ai/artifact/SigkpJDk5jtpS1W3DUPCWS |

---

## 1. O pedido

Lendo a Parada 1 da jornada, o Owner perguntou se o bloco abaixo funcionaria digitado na raiz do
repositório:

```text
make psql-source
select id, order_number, customer_id, status, placed_at, total_amount, updated_at
from oltp.orders where order_number = 'ORD-0000037';
```

Como está, não: a primeira linha é do terminal e as outras duas são do `psql`, que ainda nem abriu
quando o terminal lê a segunda. Depois, nas palavras dele:

> "Prefiro a execução passo a passo. Inclua também o teste para verificar se o banco está de pé. Se
> não estiver, como fazer ficar de pé, testar, confirmar e seguir. E então, execução do sql e sair
> via \q. Quero no documento as etapas de execução detalhadas, executáveis. Não quero linhas única
> humanamente não replicáveis. Preciso de passo a passo humano. Verifique se há outros locais também
> a reescrever neste curso […]"

> "[…] mantenha a escrita como está como um resumo. É bom pois fica uma trilha enxuta. E então, quero
> uma sessão 11 que aí sim faça o passo a passo bem detalhado para cada bloco que for necessário,
> linkável entre o enxuto e o passo a passo."

## 2. As escolhas do Owner

| # | Escolha |
|---|---|
| R1 | As seções 0 a 10 continuam como estão, **como resumo** |
| R2 | Uma **seção 11** com o passo a passo detalhado de cada bloco que precisar |
| R3 | **Links nos dois sentidos**: do resumo para o roteiro e do roteiro de volta |
| R4 | O passo a passo é **humano**: conferir se o ambiente está de pé, subir se não estiver, confirmar, executar e sair (no `psql`, com `\q`) |
| R5 | **Nada de linha única que ninguém replica**: sem comandos encadeados, funções ou atalhos de *shell* |
| R6 | **Plano revisado pelo Codex antes de executar** |

Na conversa propus quatro refinamentos: procedimentos comuns escritos uma vez, resumo que só ganha o
link, marca visual própria e cada roteiro rodado de verdade. O Owner pediu o plano sem decidir sobre
eles, então eles estão na §3 como **proposta**.

## 3. O desenho proposto

### 3.1 O que muda nas seções 0 a 10

Só isto:

1. **Um link por bloco que ganha roteiro**: `▶ passo a passo · Rnn`, logo depois do bloco, com um
   `id` no ponto de retorno. O texto do resumo não muda por causa do link.
2. **Uma linha nas Convenções da seção 0** explicando o `▶` e as etiquetas de "onde" (§3.7).
3. **Uma entrada no sumário lateral**: "11 · Roteiros passo a passo", com os grupos.
4. **Três instruções erradas do resumo**, corrigidas por decisão do Owner (O4). Linhas do arquivo em
   `c531b87`:
   - **linha 430**: "Cada parada traz a consulta (que você pode repetir)". As Paradas 3 a 6 trazem só
     a saída. Proposta: "cada parada traz a saída real; a consulta está no roteiro".
   - **linha 971** (saída da branch `estudo` no L4) e **linhas 1082 e 1272** (a DAG de estudo no L5b
     e a saída dela no L5c): o resumo manda criar os arquivos de estudo e depois `git switch main`,
     sem *commit* na branch. Arquivo novo não rastreado **acompanha** o `git switch`: o teste de
     estudo continuaria em `dbt/tests/` na `main` — e a própria caixa da linha 970 avisa que ele
     derruba o `dbt build` de `staging` —, e a DAG continuaria na pasta montada no Airflow. Assim, o
     `is_stale` da linha 1273 nunca chegaria a `"True"`. A validação de 04/10 fez *commit* na
     branch (plano anterior, §5.3, primeira linha da tabela), mas o resumo não diz isso. Proposta:
     uma frase em cada ponto, "faça *commit* na branch antes de voltar à `main`".

### 3.2 A seção 11

Um `<h2 id="roteiros">11 · Roteiros passo a passo</h2>` depois da seção 10, com:

- **11.0 Antes de qualquer roteiro**: os procedimentos comuns PC-1 a PC-9 (§3.5), escritos uma vez e
  citados pelos roteiros;
- **11.1 a 11.11**: os roteiros R01 a R50 (§3.6), na ordem em que os blocos aparecem no resumo, nos
  mesmos grupos: Fundamentos, Jornada do dado, L0, L1, L2, L3, L4, L5, L6, L7 e L8.

### 3.3 Anatomia de um roteiro

**Cabeçalho:** identificador e título; "aparece em", com link para o ponto do resumo; o que precisa
estar de pé; o que muda de estado; tempo (medido ou estimado, sempre rotulado); os PCs que vêm antes.

**Passos numerados**, cada um com:

- **onde** se digita: `terminal · raiz do projeto`, `segundo terminal`, `psql · source_db=#`,
  `contêiner · scheduler`, `navegador · localhost:8081`;
- **o comando**, um por passo, com o botão *copiar* que a trilha já tem;
- **o que deve aparecer**: saída real, com data, cortada só com `…` e o rótulo "(cortada)";
- **se não aparecer**: uma linha, apontando para o PC ou para a [Execução Local §6](../docs/execucao_local.md#6-solução-de-problemas).

**Fim:** a saída do ambiente (`\q`, `exit`, Ctrl-C), a devolução do estado quando o roteiro subiu
algo (PC-9) e um "↩ Voltar" para cada ponto do resumo que aponta para o roteiro.

Exemplo, o R02. As saídas aqui são as de 04/10; na execução entram as do dia, e o texto de erro
só entra literal se tiver sido observado (regra E8):

> **R02 · Parada 1: o pedido na origem**
> Aparece em: Parada 1 · Precisa de pé: os três bancos · Muda estado: nada · Antes: PC-1, PC-2
>
> 1. *terminal · raiz do projeto* — `make psql-source`
>    Deve aparecer: `psql (16.15)`, `Type "help" for help.` e o *prompt* `source_db=#`.
>    Se o comando disser que o serviço não está rodando: os bancos caíram; volte ao PC-2.
> 2. *psql · source_db=#* — `select id, order_number, customer_id, status, placed_at, total_amount, updated_at from oltp.orders where order_number = 'ORD-0000037';`
>    Deve aparecer: uma linha, `37 | ORD-0000037 | 1279 | delivered | …`.
>    Se o *prompt* virar `source_db-#`: faltou o `;`. Digite `;` e Enter.
> 3. *psql · source_db=#* — `select id, order_id, product_variant_id, quantity, unit_price, total_amount from oltp.order_items where order_id = 37 order by id;`
>    Deve aparecer: três linhas, 92, 93 e 94.
> 4. *psql · source_db=#* — `\q`
>    Deve aparecer: o *prompt* do terminal de novo.
>
> ↩ Voltar para a Parada 1

### 3.4 Regras de escrita

| # | Regra |
|---|---|
| E1 | **Um comando de terminal por passo.** No terminal, proibidos os operadores que encadeiam comandos (`;`, `&&`, `\|\|`), `$(…)`, função de *shell*, variável-atalho e laço. Dentro do `psql` valem o `;` que termina a consulta e os operadores do SQL, inclusive `\|\|` (RT-06) |
| E2 | **No máximo um *pipe***, e só para filtrar ou formatar a tela (`head -40`, `grep is_stale`, `jq`), com a explicação no próprio passo. O terminal interativo do Owner não tem `pipefail`, e a validação também não; um `grep` sem resultado tem o significado escrito no passo (H6, 13.1/H6) |
| E3 | **Comando de terminal longo** é quebrado em linhas com `\` no fim, e cada opção é explicada logo abaixo. No `psql` não há `\`: a consulta ocupa quantas linhas quiser e termina no `;` (RT-06) |
| E4 | **Valor que muda** (`run_id`, *offset*, corte) aparece como `<run_id>`, sempre com "troque pelo valor que apareceu no passo N" |
| E5 | **Cada passo diz onde se digita**, e trocar de ambiente é um passo próprio (`make psql-…`, `docker exec -it … bash`, `\q`, `exit`) |
| E6 | **Segredo nunca aparece**: senha lida na tela aparece como `<senha omitida>`; nunca se copia senha para arquivo; nunca se digita senha numa linha de comando, porque ela fica no histórico do *shell* |
| E7 | Nada de `make -n`, `FORCE=1`, alvo destrutivo ou `RESTAURAR=1` |
| E8 | **Saída mostrada é saída real, com data.** Mensagem de erro só aparece literal se foi observada; as demais são descritas, sem aspas (P5) |
| E9 | **O roteiro não repete o porquê**: o resumo explica, o roteiro executa e aponta para o resumo |
| E10 | **Cada roteiro depende só dos PCs**, salvo as sequências da §14.3, que dizem onde cada uma continua, quem mantém a sessão aberta e quem a encerra (RT-07) |

### 3.5 Os procedimentos comuns (11.0)

| PC | O que resolve | Passos | Dono documental |
|---|---|---|---|
| PC-1 | Terminal na raiz | `cd ~/Projetos/mvp_eng_dados_1` → `pwd` → `ls` mostra o `Makefile` | — |
| PC-2 | Os três bancos de pé | `make ps` → três linhas `(healthy)`. Faltou alguma: `make up` → `make ps` de novo. Banco de pé não é banco com dados: se faltar uma tabela que o roteiro lê, o roteiro para, e o PC não autoriza semear nada (13.1/H1) | [Execução Local §3 e §5](../docs/execucao_local.md#5-executando-por-partes) |
| PC-3 | Abrir e fechar o `psql` | `make psql-source`, `psql-legacy` ou `psql-warehouse` → *prompt* `<banco>=#`. Dentro: `;` termina a consulta; `<banco>-#` é continuação; `\x` liga e desliga a saída expandida; tela parada em `(END)` ou `:` é o paginador, e `q` sai dele; `\q` fecha | — |
| PC-4 | Airbyte de pé | `make preflight ALVO=airbyte` (só consulta) → `make airbyte-up` → "pronta"; `docker ps` mostra `airbyte-abctl-control-plane`. Termina com a interface aberta e o *login* feito, porque `/health` respondendo não prova autenticação (13.1/H1). Senha: `make airbyte-credentials` | Execução Local §5 |
| PC-5 | Airflow de pé | `make preflight ALVO=airflow` → `make airflow-up` → `Healthy`. Senha: `docker exec mvp_ed1-airflow_apiserver-1 cat /opt/airflow/simple_auth_manager_passwords.json.generated`, o comando que o próprio `airflow-up` imprime; navegador em `localhost:8081` | Execução Local §5 |
| PC-6 | *Streaming* de pé | `make preflight ALVO=streaming` → `make stream-up`, que pausa o Airbyte se ele estiver ocioso → `make stream-status` → `RUNNING` | Execução Local §5 |
| PC-7 | Sessão do dbt | Numa aba nova do terminal, primeiro o PC-1; depois `cd dbt` → `set -a` → `source ../.env` → `set +a` → `export DBT_PROFILES_DIR=.` → `source ../.venv/bin/activate`, e o *prompt* ganha `(mvp-eng-dados-1)` → `dbt --version`, que mostra o executável resolvido. Os passos seguintes são `terminal · pasta dbt`; os comandos `make` continuam na raiz, na outra aba. Ao terminar, `exit` fecha a aba e leva junto as variáveis do `.env` (RT-06) | A variável `DBT` do `Makefile` (linha 39) faz o mesmo |
| PC-8 | Sessão no contêiner do *scheduler* | `docker ps` → o nome do *scheduler* na última coluna (`mvp_ed1-airflow_scheduler-1`) → `docker exec -it <nome> bash` → o *prompt* muda → os comandos `airflow …` → `exit`. Só no *scheduler*, que tem `bash`; nos outros contêineres o roteiro usa um `docker exec <nome> <comando>` por passo. O `run_id` é lido e copiado explicitamente, nunca a "última execução" implícita (13.1/H3) | — |
| PC-9 | Devolver o estado | `make preflight ALVO=trabalho` → "janela parada"; pausar o que se subiu (`make airflow-pause`, `make stream-pause`) ou retomar o que se pausou (`make airbyte-resume`); comparar com o começo serviço a serviço — nome, estado e saúde, não *uptime* — e conferir que não sobrou processo no *host* (`stream-run`, `dbt docs serve`). Vale **ao fim de cada grupo** da §14.3; o roteiro usado sozinho diz no próprio fim o que devolver (RT-07, RT-09) | Execução Local §5 |

Os PCs dizem **como** conferir e subir. **O que** subir em cada cenário continua na tabela da
Execução Local §5, por link, sem cópia (H1).

### 3.6 O inventário

**Como foi feito.** (1) Uma varredura dos blocos `pre.cmd` e `pre.arquivo` do HTML em `c531b87`
atrás de terminal misturado com SQL, `;`, `&&`, `$(`, `docker exec` e linhas com mais de 110
caracteres; (2) uma varredura dos rótulos "saída real" sem comando nas oito linhas anteriores;
(3) a leitura das seções 2 a 8 inteiras e dos 21 exercícios. As linhas citadas são as do arquivo
em `c531b87`.

As fases (A a D) são as da §4. "Muda estado" segue a tabela da §4.2.

| R | Roteiro | Origem no resumo | De pé | Muda estado | Fase |
|---|---|---|---|---|---|
| R01 | Entrar no armazém e listar as camadas (`\dn`, contagem) | Fundamentos, SQL (414); exercício f-1 (418) | bancos | nada | A |
| R02 | Parada 1: o pedido e os itens na origem | 437 | bancos | nada | A |
| R03 | Parada 2: `raw.orders` e a conferência dos 57 da fronteira | 453; caixa 461–463 | bancos | nada | A |
| R04 | Parada 3: `staging`, só as colunas mostradas | 465–475 | bancos | nada | A |
| R05 | Parada 4: `trusted`, com `\x`; e a consulta da pergunta [\*4] | 477–489; [\*4] (1736) | bancos | nada | A |
| R06 | Parada 5: a fato e a dimensão, com as chaves cortadas | 492–503 | bancos | nada | A |
| R07 | Parada 6: o pedido na view de consumo | 506–521 | bancos | nada | A |
| R08 | Escolher outro pedido e repetir R02–R07 | exercício j-1 (524) | bancos | nada | A |
| R09 | Quente 1: o movimento na origem | 538–546 | bancos | nada | A |
| R10 | Quente 2: o envelope no tópico, pelo *offset* 29603 | 548–559 | *streaming* | nada | C |
| R11 | Quente 3: o destino quente | 561–568 | bancos | nada | A |
| R12 | Quente 4: os dois caminhos se encontram | 570–577 | bancos | nada | A |
| R13 | A parcela quente da view `skus_below_reorder_point`, hoje "não capturado" | caixa 580–581 | *streaming*, entre R42 e o próximo `dbt-build` | nada | C |
| R14 | SCD: a linha do tempo do cliente 18 | 583–589 | bancos | nada | A |
| R15 | O que está de pé e o que cabe | Convenções (221–222); 600–630; exercício l0-1 (680) | o atual | nada | A |
| R16 | Composições, rede e volumes | 699 | o atual | nada | A |
| R17 | Os *pods* do Airbyte | 714 | Airbyte | nada | A |
| R18 | Onde roda cada peça, e o log de um banco | exercício l1-1 (731) | o atual | nada | A |
| R19 | Migrações e os planos do gerador | 749, 754, 763; exercício l2-1 (787) | bancos | nada | A |
| R20 | `\d` e `EXPLAIN` na origem e no armazém | 771–776 | bancos | nada | A |
| R21 | Entrar na interface do Airbyte | 815 | Airbyte | nada | A |
| R22 | Sincronizar e ver o dado chegar | 832; exercícios l3-1 (860) e l3-2 (870) | Airbyte | **sim** | D, com R46 |
| R23 | Ver um agendamento sem aplicá-lo (X) | 844–859 | Airbyte | branch `estudo`, desfeita | A (H7) |
| R24 | Sessão do dbt e o SQL compilado | 896, 903 | bancos | `dbt/target/` | A |
| R25 | Consultar sem materializar | 916 | bancos | `dbt/target/` | A |
| R26 | Seletores | 923, 931 | bancos | `dbt/target/` | A |
| R27 | Construir e testar tudo | 934 | bancos | reconstrói | A |
| R28 | O catálogo e a linhagem | 943 | bancos | `dbt/target/`; servidor :8080 | A |
| R29 | Modelo e teste na branch `estudo` | 950–971; exercícios l4-1 (973) e l4-2 (983) | bancos | branch `estudo`, desfeita | A |
| R30 | Subir o Airflow e entrar na interface | 1018–1025 | Airflow | liga o Airflow | B |
| R31 | Disparar e acompanhar a `fluxo_batch` | 1026–1028; exercício l5a-1 (1061) | Airbyte e Airflow | **sim** | B, com portão e vigia (§4.1) |
| R32 | A CLI do Airflow, de dentro do contêiner | 1060 | Airflow | nada | B |
| R33 | Criar e registrar a DAG de estudo | 1082–1145 | Airflow | branch e metadados, desfeitos em R39 | B |
| R34 | Liberar o sensor e ver o *retry* | 1147–1159 | Airflow | idem | B |
| R35 | A falha mascarada pela *trigger rule* | 1161–1169; exercício l5b-1 (1206) | Airflow | idem | B |
| R36 | Reexecução parcial na DAG real, pela interface | 1179–1191; exercício l5b-2 (1216) | Airflow | três tarefas da execução de R31 vão à tentativa 2 | B |
| R37 | Interromper uma execução em curso, pela interface | 1193–1205 | Airflow | uma execução de estudo `failed`, desfeita em R39 | B |
| R38 | Agendamento, *catchup* e *backfill* | 1233–1255; exercício l5c-1 (1282) | Airflow | idem | B |
| R39 | Sair da branch de estudo sem deixar rastro | 1269–1281 | Airflow | desfaz R33–R38 | B |
| R40 | Subir e conferir o *streaming*, com os limites do log | a saída do `stream-up` no L0 (632–636); 1302–1328 | *streaming* | pausa o Airbyte | C |
| R41 | Produzir e medir com `make medir` | 1335 | *streaming* | **sim** | C |
| R42 | Operar à mão, em dois terminais | 1349 | *streaming* | **sim** | C |
| R43 | Seguir um evento novo pela posição no log | exercício l6-1 (1384) | *streaming* | nada | C |
| R44 | Idempotência com duplicatas | 1352; exercício l6-2 (1394) | *streaming* | +250 mensagens no tópico | C |
| R45 | Os alertas | 1361 | *streaming* | nada | C |
| R46 | Voltar ao lote e reconciliar | 1376 | Airbyte | **sim** | D, com R22 |
| R47 | Acesso por papel | 1432; exercício l7-1 (1497) | bancos | nada | A |
| R48 | A quarentena e o certificado das capturas | 1461, 1476 | bancos | nada | A |
| R49 | A verificação completa | 1485; exercício l7-2 (1506) | bancos e Airbyte | reconstrói | D |
| R50 | Conferir o ponto de recuperação (§14.4) | 1539; exercício l8-1 (1565) | bancos, `.env`, `.venv` e o pacote em `data/recovery/` | nada (só lê) | A |

Os 18 exercícios fora do desafio final estão todos cobertos. **O que fica sem roteiro**, e por quê:

| Bloco | Motivo |
|---|---|
| Os comandos de uma linha dos Fundamentos (380–416) e o `make help`/`make ps`/`make preflight` soltos do L0 | Já são um comando por linha; entram como exemplo nos PCs e no R15 |
| O laboratório opcional de SCD no varejo (591) | `UPDATE` na origem, com marca permanente nela e nos *snapshots*; continua "não validado", como decidido em 04/10 (H1 daquele plano) |
| `make recovery-pack` e `RESTAURAR=1 make recovery-restore` (1540–1541) | Exigem janela parada e árvore limpa, ou destroem; o L8 foi escrito do registro do B5 por escolha do Owner (E5 de 04/10), e o roteiro de verdade é a [Execução Local §3](../docs/execucao_local.md#3-ciclo-completo) |
| Variables e Connections (1263–1267) | Bloqueadas pela chave Fernet inválida (D64) |
| "E se a `fluxo_batch` fosse agendada?" (1260) | Explicado e não aplicado, de propósito |
| O desafio final (1578–1594) | Sem receita por desenho (§13.1 do plano anterior); quem o faz pode usar os PCs |
| Os `grep` da pergunta [\*2] | Um comando por linha, já executáveis |
| O diagnóstico do `KeyError` (1171–1177) | Saída histórica de 04/10 que virou o desafio d-3, sem receita (RT-05) |
| Os blocos `arquivo` | São código para ler. **Exceções:** o modelo e o teste de estudo (951–959) e a DAG de estudo (1083–1142), que R29 e R33 copiam para arquivos e executam (RT-05) |

### 3.7 Navegação e aparência

- **Marca no resumo:** o link `▶ passo a passo · Rnn`, numa classe nova, visualmente distinta da nota
  `[*n]` da seção 10.
- **Identificadores:** `rnn` no roteiro e `ref-rnn-<ponto>` no resumo. Roteiro que serve a mais de um
  ponto tem um "↩" para cada, como a [\*1].
- **Etiquetas de "onde"**, como pílulas com texto e cor por ambiente (terminal, psql, contêiner,
  navegador); a cor nunca é a única pista.
- **Blocos:** comando de terminal continua `pre.cmd`, com o `$`. Comando de `psql` e de contêiner usa
  `pre.cmd.sem-prompt` com a etiqueta acima, para o `$` não sugerir terminal. O botão *copiar* já
  copia sem o `$`.
- **Tema claro e escuro:** as cores novas entram como *tokens* nos três blocos de tema que já existem.

## 4. A validação na máquina

**Regras**, as de 04/10 (plano anterior, §5): alvos guardados; nenhum `FORCE`, `make -n` ou alvo
destrutivo; recusa do *preflight* para a validação e volta ao Owner; saída com segredo redigida antes
de ser gravada. E mais duas:

- **Cada roteiro é executado como está escrito**, passo a passo, inclusive as sessões interativas. O
  terminal, o `psql` e o `bash` do *scheduler* rodam num pseudoterminal de 1000 colunas (§15, desvio 3) conduzido pelo
  `sessao.py` (§14.2): cada comando só é enviado depois do *prompt* esperado, cada passo tem o próprio
  oráculo, e a gravação é o que apareceria na tela, já redigida (RT-03, RT-13). A sonda da §9 mostra
  que o pseudoterminal reproduz a tela.
- **Tudo roda ao vivo** (O1). Passo que não puder rodar — portão de memória não atingido, recusa
  do *preflight*, extensão do Chrome desconectada — **para a fase e volta ao Owner** (§4.5). Se o
  Owner mandar seguir sem ele, o passo fica rotulado no roteiro com a data e a evidência de 04/10, e
  nunca como validado agora.

**Registro:** `data/medicoes/material_estudo/<data>_roteiros_fase_{a,b,c,d}/`, fora do Git. Cada pasta
tem o `indice.tsv` (início, fim, código de saída real, comando e arquivo), a transcrição **já redigida**
de cada sessão e um `LEIAME.md`. Nada é gravado antes da redação, nem em arquivo temporário; as
ferramentas da revisão 2 estão na §14.2 (RT-03).

| Fase | De pé | O que roda | Tempo estimado |
|---|---|---|---|
| A | bancos + Airbyte, o estado atual | Antes, as provas das ferramentas e a linha de base (§14.3). R01–R09, R11, R12, R14–R21, R23–R29, R47, R48, R50. R27 reconstrói; R23 e R29 abrem e fecham a branch `estudo`, cada um com a própria saída | ~90 min |
| B | bancos + Airbyte + Airflow | R30, R32, R33, R34, R35, R38, R37; a **prova do `vigia_dag.py`**; o portão; R31 com o `vigia_dag.py` em interrupção e o `vigia_job.py` em registro; R36 sobre a execução de R31; R39; `make airflow-pause` (§14.3) | ~75 min |
| C | *streaming* (o `stream-up` pausa o Airbyte) | R40, com os limites do log; R10, se o *offset* 29603 estiver no log; a linha de base dos alertas; R41; R42, que deixa o Beam de pé; R43; R10 pelo caminho alternativo, se preciso; R13, R44, R45; Ctrl-C no Beam; `make stream-pause` (§14.3) | ~45 min |
| D | bancos + Airbyte | `make airbyte-up` (retoma); o portão; R22 e R46 juntos, numa sincronização só, com o `vigia_job.py` em interrupção; R49; PC-9 (§14.3) | ~25 min |

Os tempos são **estimativa**, não medição. Na fase B o Airbyte fica de pé, porque a `fluxo_batch`
(R31) sincroniza as duas origens. Os passos de navegador das fases A e B (R21, R30, R31, R36, R37)
usam a extensão do Chrome (O3), conectada às 20:25Z (§9). Cada sessão de navegador abre o seu grupo
de abas e o fecha no fim.

**Estado a devolver:** o encontrado no início da execução. Se for o de hoje (§9): os três bancos e o
Airbyte de pé, Airflow e *streaming* parados.

### 4.1 Memória

Medido hoje (§9), sempre com o Airbyte de pé: 3,0 GB livres às 20:00Z; **5,0 GB** às 20:18Z, depois
de o Owner fechar os aplicativos; **4,5 GB** às 20:25Z, com o Chrome aberto para a extensão (O3). Em
04/10 eram 4,7 GB. Por fase:

- **A** (bancos + Airbyte): 4,5 GB livres; o `dbt build` não pesou em 04/10.
- **B** (+ Airflow): com 5,0 GB, o *preflight* estimou **3,7 GB livres depois do `airflow-up`**
  (custo de ~1,4 GB). Com os 4,5 GB do Chrome aberto, a mesma conta dá ~3,1 GB; na sonda do Codex,
  3,2 GB (13.2). Nenhum dos dois é medição com o Airflow de pé. A `fluxo_batch` (R31) usa o
  **portão**: pelo menos **3000 MiB** de `MemAvailable` (o valor de `/proc/meminfo` dividido por
  1024) em três leituras seguidas, com o Airbyte e o Airflow de pé e nada rodando, medidos logo antes
  do disparo; abaixo disso ela não começa, e a decisão volta ao Owner. **A folga é pequena**: cada
  aba a mais no Chrome conta. Durante a execução, o **`vigia_dag.py`** (§14.2) acompanha a execução
  remota até o estado terminal, e não um processo local; três leituras seguidas abaixo de **1000 MiB**
  disparam a interrupção. Em 04/10 ela foi de 3,1 GB a 1,9 GB. O portão não prova que a interrupção
  cabe na memória que sobra; ele só diminui a chance de precisar dela (RT-01).
- **C** (*streaming*, Airbyte pausado): o cenário medido de 04/10 teve **6,6 GB livres no mínimo**.
- **D** (Airbyte + sincronização): o mesmo portão de 3000 MiB antes da sincronização. Durante, o
  **`vigia_job.py`** (§14.2) identifica o *job* desta sincronização pela API, acompanha o estado dele,
  `pending` incluído, até o terminal e, no gatilho, cancela esse *job* e confere o cancelamento. A
  identificação e o acompanhamento são provados antes, em modo de registro, nos dois *jobs* da
  `fluxo_batch` de R31. O cancelamento real continua não exercido: em 04/10 só a rota foi sondada, e
  respondeu 409 para um *job* inexistente (RT-02, §14.6).

Se o Owner reabrir aplicativos, os números mudam. Quem decide é o portão, medido na hora, e não esta
tabela.

### 4.2 Mudanças de estado

| Ação | Efeito | Reversível? |
|---|---|---|
| R23, R29 e R33 (branch `estudo`) | Branch local com *commits* de estudo, feitos por caminho explícito, nunca `git add .`; compilados em `dbt/target/` | Pelo próprio roteiro: `git switch main`, apagar os compilados `estudo`, `git branch -D estudo`. Oráculo: `git status --porcelain` igual à linha de base tirada antes da branch, que inclui este plano não rastreado; `git diff --stat` vazio em `airflow`, `dbt` e `airbyte`; `git branch` sem `estudo`; nenhum objeto `estudo*` no armazém (RT-09) |
| R27 e R49 (`dbt build`) | Camadas reconstruídas | Idempotente |
| R28 (`make dbt-docs`) | Catálogo regerado em `dbt/target/`; servidor em :8080 até o Ctrl-C; a trilha diz que ele abre o navegador, então uma aba pode abrir na tela do Owner (§10) | `dbt/target/` é ignorado pelo Git |
| A pausa do Airbyte pelo `stream-up` (fase C) e a retomada pelo `airbyte-up` (fase D) | Uma queda do Postgres interno do Airbyte por pausa (D56, documentada na Execução Local §5) | Retomadas medidas em 23 e 24/09 sem perda |
| R33–R38 (DAG de estudo) | Registro, execuções, *backfill* e XCom no banco de metadados; arquivo-sinal no contêiner | R39, com o oráculo: `dags list` sem ela depois de pelo menos 60 s, nenhum *backfill*, arquivo-sinal ausente. Os arquivos de log no volume `mvp_ed1_airflow_logs` não foram conferidos (§10) |
| R31 (uma execução da `fluxo_batch`) | **+1 captura do legado certificada e retida** em `raw_legacy` (~7 MB por captura, estimativa de 04/10: 213 MB em 29), +1 fatia de quarentena, +2 *jobs* do Airbyte, `raw` atualizado, camadas reconstruídas, histórico no Airflow | Só por restauração. É o que toda execução da DAG faz, por desenho (ADR-0037, ADR-0044) |
| R36 (limpar `dbt_consumption` e as seguintes na execução de R31) | `dbt_consumption`, `dbt_fronteiras` e `dbt_docs` vão à tentativa 2; o histórico guarda | Não se desfaz; é o que o exercício l5b-2 pede |
| R41 (`make medir CENARIO=streaming LIMITE=2200`) | **+2.200 eventos, aproximadamente, para sempre no livro da origem** (em 04/10 foram 2.201); `.stream/producer_state.json` avança; o tópico cresce | Só por `seed-data FORCE=1` ou restauração. É a simulação desenhada |
| R42 (`stream-produce LIMITE=50`) | **+50 ou +51 eventos para sempre no livro da origem** — a transferência sai em par, e o lote pode passar o teto em um. O número é o previsto; o realizado é medido | Idem |
| R41 e R42 (o produtor) | Além dos eventos: `oltp.inventory_balances` atualizada, `updated_at` incluído, e talvez um par armazém/SKU novo, como destino de transferência (`producer.py`, `_mover_saldo`) | Idem |
| R41 a R45 (o Beam) | Linhas novas em `raw.inventory_movements_stream`, *offsets* do grupo `mvp_ed1_beam` avançados e mensagens no tópico de alertas | É a ingestão desenhada; os *offsets* são o estado do consumidor |
| Artefatos locais | `dbt/target/` e `dbt/logs/` (R24–R29, R49) e `airbyte/.terraform/` (o `init` de R23), todos ignorados pelo Git | Regenerados a cada uso |
| O pacote aprovado de 25/09 | Fica mais distante do estado atual: mais uma captura e mais eventos | Um pacote novo, só por decisão do Owner, fora deste plano |
| R44 (`stream-duplicate QUANTAS=250`) | +250 mensagens repetidas no tópico; o destino fica igual, e é isso que se prova | Ficam no tópico até a retenção |
| R22 e R46 (`sync-airbyte`, fase D) | `raw` atualizado com os eventos de R41 e R42; +1 *job*; as 8 views de `staging` caem até o `dbt-build` do próprio roteiro; os 57 pedidos da fronteira ganham o `sync_id` novo | Operação normal; o roteiro termina no `dbt-build` |
| PC-7 (sessão do dbt) | Variáveis do `.env` carregadas na aba do terminal | `exit` fecha a aba |

### 4.3 Oráculos

- **Consulta de leitura da fase A que já rodou em 04/10** (as Paradas, a jornada quente, o SCD, os
  papéis, a quarentena, o certificado, o `EXPLAIN`): os valores das mesmas colunas têm de ser
  **iguais** aos de `data/medicoes/material_estudo/20261004_fase_*`, salvo as duas diferenças
  conferidas hoje (§9): os 57 pedidos da fronteira com `sync_id` 53, o *job* da fase D de 04/10, e a
  quarentena mais recente na captura 52, com a mesma linha 48. **Essas exceções valem só para a fase
  A.** Depois das mutações de B, C e D, cada roteiro tem o seu oráculo, na §14.5 (RT-10). Qualquer
  outra diferença para a fase e vira achado. Para tempos e para o `EXPLAIN`, vale o plano, não o
  número.
- **Passo de sessão:** o oráculo do próprio passo no `sessao.py` — o *prompt* esperado, o texto
  esperado, o código de saída do terminal e, quando o erro é o que se ensina (a falha de R29, as
  quatro recusas de R47), o erro esperado (RT-13).
- **Branch `estudo` e DAG de estudo:** os oráculos de saída da tabela 5.3 do plano de 04/10, com a
  linha de base de Git da §4.2 (RT-09).
- **R44:** o *offset* confirmado alcança o *high watermark*, e os *digests* ficam iguais. Isso
  certifica o destino, não o ramo de alertas (RT-12).
- **Final:** `make check` verde (R49) e o PC-9 da fase D: serviço a serviço igual à linha de base,
  sem processo do projeto no *host* (RT-09).

### 4.4 Segredos

- As saídas de `make airbyte-credentials` e do arquivo de senha do Airflow são redigidas **antes de
  qualquer escrita**: o passo que mostra senha é marcado `segredo` no `sessao.py`, que mascara a saída
  inteira dele, seja qual for o texto do comando (RT-03). No HTML aparece só `<senha omitida>`.
- Os *logins* pelo Chrome (R21, R30) digitam a senha local que o próprio ambiente gerou, num
  formulário de `localhost`. Ela não vai para evidência, captura de tela nem conversa.
- Nenhuma tela nova entra no HTML, salvo decisão contrária (O3). As capturas de navegador, se houver,
  ficam nas evidências e passam pela inspeção visual de 04/10.
- O HTML local, a variante gerada e as pastas de evidência passam pelo `varrer_segredos.py` antes de
  qualquer publicação (RT-04). Os controles positivos usam valores fictícios, nunca credenciais reais
  (RT-03).

### 4.5 Quando a execução para e volta ao Owner

- Recusa do *preflight* que a troca não resolve.
- Portão de memória não atingido (fases B e D), ou vigia disparado.
- Extensão do Chrome desconectada num passo de navegador.
- Oráculo divergente: o de 04/10, fora das diferenças explicadas, ou o do próprio roteiro (§14.5).
- Erro inesperado num passo, prazo vencido, saída ilegível, ou falha da gravação ou da redação
  (RT-13).
- Estado indeterminado: um vigia que não consegue ler a execução ou o *job*.
- Qualquer passo que exigiria `FORCE`, alvo destrutivo ou algo fora deste plano.

**Parar não cancela trabalho já disparado.** Uma `fluxo_batch` ou uma sincronização em curso segue com
o seu vigia até o estado terminal; só então, e com "janela parada" no `preflight ALVO=trabalho`,
algum serviço é pausado (RT-13).

## 5. Entrega

1. Editar o HTML local: nas seções 0 a 10 e no sumário, só os links e as correções aceitas em O4; a
   seção 11 nova.
2. Conferir a navegação com o `conferir_navegacao.py` (§14.2): IDs únicos; todo `href="#…"`
   resolvido; cada ponto de origem do inventário com o seu `▶`; em cada roteiro, um "↩" para **cada**
   ponto que aponta para ele, inclusive [\*4] e as ocorrências repetidas (RT-15).
3. Gerar a variante com o `publicavel.py` e repetir nela a conferência da navegação (RT-15).
4. Varrer segredos no HTML local, na variante e nas evidências, e inspecionar as telas novas, se
   houver (RT-04).
5. Conferir no Chrome, nos dois temas, a página e a cópia de um comando com continuação de linha
   (RT-15).
6. Só então republicar no mesmo Artifact.
7. `make check-offline` com o HTML e este plano adicionados, e *commit* só com código 0. Dois
   *commits*, um por assunto: o plano, com a revisão e a execução; e a seção 11. *Push* só com
   pedido do Owner.

## 6. Mapa de revisão — onde gastar esforço

- **Declaração, para revisar inteira:** as regras (§3.4), os procedimentos comuns (§3.5), o
  inventário com o que fica de fora (§3.6), as fases, as mudanças de estado, os oráculos e as paradas
  (§4) e as consequências das decisões já tomadas pelo Owner (§8).
- **Derivado, para revisar por amostragem depois:** o HTML da seção 11, escrito a partir da
  declaração e das saídas gravadas.
- **Conferível contra a fonte:** o inventário contra o HTML em `c531b87` — cada bloco `pre.cmd`, cada
  "saída real" sem comando e cada "Execute" de exercício.

## 7. Onde hesitei

**H1 — Duplicação com a Execução Local.** Os PCs 2, 4, 5, 6 e 9 contam como subir e devolver
ambientes, assunto cujo dono é a Execução Local §5. Proposta: os PCs dão só os passos humanos de
conferir, subir e confirmar, e apontam para a §5 para "o que subir em cada cenário", sem repetir a
tabela. Alternativa: os PCs só com links. Isso deixaria o roteiro dependente de um documento que não
é passo a passo.

**H2 — O dbt sem a função `dbt_`.** A função (linha 896) é exatamente o que o Owner não quer. Proposta:
a sessão do PC-7, seis passos que fazem o mesmo que a variável `DBT` do `Makefile`. Alternativa: um
alvo novo, como `make dbt ARGS="…"`. Seria mudança no projeto, que este plano não faz, e decisão do
Owner.

**H3 — A CLI do Airflow sem o atalho `$A`.** Proposta: a sessão interativa do PC-8, `docker exec -it
mvp_ed1-airflow_scheduler-1 bash`, e os comandos `airflow …` digitados lá dentro, como no `psql`.
A receita `dag-status` usa `docker compose … exec -T airflow_scheduler`, que entra no mesmo contêiner.
Alternativa: escrever a forma longa a cada passo, que tem 90 caracteres antes do comando.

**H4 — O que 04/10 fez pela API, com um auxiliar fora do Git.** O estado das tarefas, o XCom, a
reexecução parcial e a interrupção saíram do `airflow_api.py`. Decidido em O2:
- o estado das tarefas, pela CLI, com `airflow tasks states-for-dag-run <dag> <run_id>`, o mesmo da
  receita `dag-status`, ou pelo Grid da interface;
- o XCom, a reexecução parcial e a interrupção, **pela interface do Airflow**. É o caminho humano, e
  a própria trilha mostra as telas.

A reexecução pela interface está marcada "não validado" no resumo (linha 1191), e esta validação
cobre esse buraco.

**H5 — Passos com marca permanente ou que pedem memória.** Decidido em O1: tudo ao vivo. O que ainda
pede revisão é a folha de memória da fase B (§4.1).

**H6 — *Pipes*.** A regra E2 permite um, só para filtrar ou formatar a tela. Sem ela, R39 precisaria
ler um JSON inteiro atrás de `is_stale`, e R43 um envelope Debezium de uma linha só. Alternativa: zero
*pipes*, e o roteiro diz o que procurar na saída inteira.

**H7 — O `terraform plan` do R23.** O `make airbyte-config` aplica. Em 04/10, o plano saiu de um
*script* de validação, fora do Git, que monta dez variáveis e as credenciais pelo `abctl`. Isso não é
passo a passo humano. Três caminhos:
- o roteiro chama o *script*, que está nesta máquina, explicando o que ele faz (proposta);
- `make airbyte-config` respondendo "no" à confirmação. **Descartado**: com `-input=false`, sem plano
  salvo e sem `-auto-approve`, não há pergunta de aprovação (13.1/H7, pela documentação do
  Terraform);
- retirar o roteiro, e o experimento fica só para ler.

**H8 — Largura da saída gravada.** O pseudoterminal quebra linha onde o terminal do Owner talvez não
quebre. Na sonda da §9, a 80 colunas, `rolname=current_user` virou `rolname =current_user`. Proposta:
gravar a 120 colunas e dizer no 11.0 que a quebra de linha pode variar.

**H9 — Mexer no resumo.** Corrigir as três instruções erradas contraria R1 ao pé da letra; não
corrigir deixaria a trilha ensinando um passo que quebra a `main` (o teste de estudo) ou que nunca
termina (a DAG de estudo que não fica `is_stale`). Decidido em O4: corrigir. O que pede revisão é se
as três são mesmo erros (§3.1, item 4).

**H10 — Tamanho.** São 50 roteiros e 9 PCs. Estimativa, não medida: +120 KB de HTML num arquivo de
1,47 MB, quase todo imagem. Alternativa: um roteiro por laboratório, mais longo. Preferi um por bloco,
porque o link do resumo deve cair no passo que importa.

**H11 — O desafio final sem roteiro.** Mantido por desenho. Quem o faz tem os PCs.

**H12 — R10 depende da retenção do tópico.** Se o *offset* 29603 já tiver saído do log, R10 usa o
evento produzido em R42, e a jornada quente continua mostrando a saída de 04/10, rotulada.

**H13 — Rótulos misturados num mesmo roteiro.** Superada: com O1, R31 e R41 rodam ao vivo. Só volta
se um portão barrar um passo e o Owner mandar seguir sem ele (§4).

## 8. Decisões do Owner, em 12/10/2026

**O1 — Passos que deixam marca permanente ou pedem memória** (R22/R46, R31, R41, R42): **tudo ao
vivo.** Nas palavras do Owner: *"Se há valor em executar, vale executar, o foco é o aprendizado."*
Ele fechou os aplicativos para liberar memória (§4.1 e §9). As marcas aceitas estão na §4.2:
+1 captura do legado retida, cerca de +2.250 eventos no livro da origem, +3 *jobs* do Airbyte, o
histórico no Airflow e mensagens no tópico. Nenhuma delas muda o que o `make check` confere: em
04/10 ele passou depois de +2.401 eventos e da captura 52. Os seis testes do legado continuam pulados
pelo mesmo motivo de hoje, porque a captura corrente não é o lote do manifesto.

**O2 — XCom, reexecução parcial e interrupção: pela interface do Airflow.** Nas palavras do Owner,
*"vamos via airflow"*, lidas como a interface do próprio Airflow em vez de `curl` com *token*. O
estado das tarefas pode vir também da CLI, dentro do contêiner (H4).

**O3 — Passos de navegador: padronizados no Chrome**, pela extensão. Conectada às 20:25Z (§9).

**O4 — As três instruções erradas do resumo** (§3.1, item 4): **corrigir**, uma frase em cada ponto.

## 9. O que já foi executado, com a saída

Sondas só de leitura, em 12/10/2026, a partir das 20:00Z, sobre `c531b87`. Nada subiu, pausou ou
sincronizou.

O estado, só as linhas do projeto, e a memória:

```text
$ date -u +%FT%TZ
2026-10-12T20:00:53Z
$ docker ps -a --format 'table {{.Names}}\t{{.Status}}'
mvp_ed1-airflow_scheduler-1                  Exited (1) 8 days ago
mvp_ed1-airflow_apiserver-1                  Exited (0) 8 days ago
mvp_ed1-airflow_dag_processor-1              Exited (1) 8 days ago
mvp_ed1-airflow_init-1                       Exited (0) 8 days ago
mvp_ed1_kafka_connect                        Exited (137) 8 days ago
mvp_ed1_redpanda                             Exited (0) 8 days ago
mvp_ed1-airflow_db-1                         Exited (0) 8 days ago
airbyte-abctl-control-plane                  Up 34 minutes
mvp_ed1_source_db                            Up 34 minutes (healthy)
mvp_ed1_legacy_db                            Up 34 minutes (healthy)
mvp_ed1_warehouse_db                         Up 34 minutes (healthy)
$ grep MemAvailable /proc/meminfo
MemAvailable:    3170824 kB
```

O *preflight*, só consulta, e a API do Airbyte:

```text
$ make preflight ALVO=airflow
[preflight] RAM disponível agora: 3,0 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 1,6 GB
[preflight] OK
$ make preflight ALVO=streaming
…
  Pause primeiro:
    make airbyte-pause                     (pausa Airbyte; retomar com make airbyte-resume)
…
make: *** [Makefile:286: preflight] Erro 1
$ make preflight ALVO=trabalho
[preflight] nenhum trabalho em andamento — janela parada.
$ curl -s -o /dev/null -w 'airbyte health HTTP %{http_code}\n' --max-time 10 http://localhost:8000/api/v1/health
airbyte health HTTP 200
```

A recusa do *streaming* é a esperada: *batch* e *streaming* não sobem juntos, e o `stream-up` pausaria
o Airbyte.

**O método de gravar sessão interativa** — `make psql-source` num pseudoterminal, recebendo o que o
Owner digitaria. Gravação limpa dos códigos de terminal:

```text
$ printf 'select current_user, current_database();\n\\q\n' | script -qec "make psql-source" /dev/null
psql (16.15)
Type "help" for help.

source_db=# select current_user, current_database();
 current_user | current_database
--------------+------------------
 mvp_source   | source_db
(1 row)

source_db=# \q
```

O mesmo no armazém. A quebra de linha a 80 colunas é a da H8:

```text
warehouse_db=# select current_user, (select rolsuper from pg_roles where rolname =current_user) superusuario;
 current_user  | superusuario
---------------+--------------
 mvp_warehouse | t
(1 row)

warehouse_db=# \q
```

**O código não mudou desde `v1.0.0`**: só documentos entraram depois.

```text
$ git diff --stat v1.0.0..HEAD -- . ':!CONVERSAS_COM_CHAT' ':!docs' ':!README.md'
$ git log --oneline v1.0.0..HEAD
c531b87 docs: acrescenta a seção de perguntas e respostas à trilha de estudo
a373b53 docs: registra o texto do portfólio para os dois projetos de dados
2cd3c64 docs: reorganiza o README para quem chega de fora
bb6e239 docs: registra os achados da validação do material de estudo como pendências
07ac3c6 docs: entrega a trilha de estudo da fase local
3ae4ba2 docs: registra o plano do material de estudo, a revisão do Codex e a execução
```

**As duas diferenças esperadas nos oráculos** (§4.3), conferidas no armazém:

```text
 sync_id | count
---------+-------
 48      |  3443
 53      |    57

 max
-----
  52

 snapshot_id | source_table | legacy_row_id | rejection_origin
-------------+--------------+---------------+------------------
          52 | customers    |            48 | own_invalid

 table_type | count
------------+-------
 BASE TABLE |    41
 VIEW       |    36
```

As 36 views de `staging` estão de pé: é o "antes" do exercício l3-2.

**Depois de o Owner fechar os aplicativos**, e depois de ele abrir o Chrome para a extensão:

```text
$ date -u +%FT%TZ ; grep MemAvailable /proc/meminfo     (três leituras, a cada 2 s)
2026-10-12T20:18:37Z
MemAvailable:    5250028 kB
MemAvailable:    5250320 kB
MemAvailable:    5249904 kB
$ free -m
               total       usada       livre    compart.  buff/cache  disponível
Mem.:          11740        5493        2628         288        3618        5126
Swap:          15835         773       15062
$ make preflight ALVO=airflow
[preflight] RAM disponível agora: 5,0 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 3,7 GB
[preflight] OK
$ docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}'      (linhas do projeto)
airbyte-abctl-control-plane   3.547GiB / 11.46GiB
mvp_ed1_source_db             26.99MiB / 2GiB
mvp_ed1_legacy_db             25.95MiB / 2GiB
mvp_ed1_warehouse_db          29.73MiB / 2GiB
$ df -h /
/dev/sdb5        29G   20G  7,8G  72% /

2026-10-12T20:25:00Z, com o Chrome aberto
MemAvailable:    4760540 kB
MemAvailable:    4769444 kB
MemAvailable:    4769784 kB
```

A extensão do Chrome, às 20:23Z não conectada e às 20:25Z conectada:

```text
list_connected_browsers → []
tabs_context_mcp        → "Browser extension is not connected. […]"

list_connected_browsers → [{"name":"Browser 1","osPlatform":"Linux","isLocal":true,"inUse":true, …}]
tabs_context_mcp        → "This session has no tab group of its own. […]"
```

A memória de 04/10 por cenário, na tabela que o `make medir` imprime (colunas: alvo, de pé, duração,
**livre no mínimo**, contêineres no máximo, amostras, bancos):

```text
| dag-run | Airbyte,Airflow,bancos | 6m 56s | 1,9 GB | 7,1 GB | 99 amostras, uma a cada 4,2 s (pausa de 2 s) | 642.2 MB |
| cenario:streaming | streaming,bancos | 1m 20s | 6,6 GB | 1,7 GB | 20 amostras, uma a cada 4,1 s (pausa de 2 s) | 645.3 MB |
```

**Os nomes para os PCs:** o prompt do ambiente virtual vem de `.venv/bin/activate`
(`VIRTUAL_ENV_PROMPT="mvp-eng-dados-1"`); o `.env` tem 22 atribuições simples e nenhuma linha
`export`; a variável `DBT` do `Makefile` (linha 39) é
`set -a; . ./.env; set +a; cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt`; a receita `dag-status`
(linhas 493–497) usa `airflow tasks states-for-dag-run`.

**A variante publicada:** `data/medicoes/material_estudo/publicavel.py`, salvo hoje a partir da sessão
que publicou as perguntas [\*1] a [\*6], gera do HTML local um arquivo idêntico, por `cmp`, ao que foi
publicado na versão 9 do Artifact.

## 10. Não verificado

- Se o *offset* 29603 ainda está no tópico (H12).
- Se `docker exec -it mvp_ed1-airflow_scheduler-1 bash` abre uma sessão, e qual é o *prompt* lá
  dentro. O Airflow está parado.
- Os nomes dos botões e das abas da interface do Airflow 3.2.2: as telas de 04/10 estão em português
  ("Agendado", "Modelos Renderizados"). Entram na trilha os que aparecerem na validação.
- Se a extensão do Chrome continua conectada no dia da execução, e se ela consegue o que os roteiros
  pedem: *login*, clicar em "limpar" e "marcar como falha", ler a aba XCom. Às 20:25Z ela só listou o
  navegador.
- Se `make dbt-docs` abre mesmo uma aba no navegador do Owner, como a trilha diz.
- Como `make logs SERVICE=warehouse_db` se comporta com Ctrl-C.
- O que `make recovery-verify` exige (o pacote em `RECOVERY_DIR`). Nunca rodou na trilha.
- Se a fase B passa no portão de 3,0 GB: a estimativa com o Chrome aberto é de ~3,1 GB (§4.1). O
  portão mede na hora, e o vigia existe para o resto. O cancelamento real de um *job* nunca foi
  exercido.
- Se `airflow dags delete` remove os arquivos de log da DAG de estudo no volume `mvp_ed1_airflow_logs`.
- Se o código da DAG de estudo, copiado do HTML como está, registra sem erro. Em 04/10 rodou o
  arquivo; agora rodará o texto da trilha.
- As mensagens de erro do PC-2 e do PC-3 (serviço parado, `-#`). Não serão provocadas: E8 manda
  descrevê-las quando não forem observadas.
- Como o paginador do `psql` aparece nas saídas longas (`\d oltp.orders`, a rejeição inteira) dentro
  do pseudoterminal. O PC-3 ensina o `q`; a gravação precisa enviar o mesmo `q`.
- Os tempos da §4: estimativa.
- O comportamento das ferramentas novas da §14.2, até cada uma passar na própria prova.

## 11. Premissas

- Código inalterado desde `v1.0.0` (medido, §9) e imagens fixadas por *digest*: os comandos de 04/10
  se comportam igual hoje.
- O Owner usa `bash`, tem um navegador e um editor de texto. Os roteiros dizem "no seu editor", sem
  escolher um.
- Durante a execução o Owner mantém os aplicativos fechados e o Chrome com poucas abas. Se não, os
  portões decidem.
- A máquina foi reiniciada há pouco (contêineres de pé há 34 min). A API do Airbyte responde 200, mas
  o 401 depois de reiniciar (Execução Local §6) só aparece com credencial e não foi testado.
- Os contêineres do Airflow e do *streaming*, parados há 8 dias e com `Exited (1)` no *scheduler*,
  voltam por `make airflow-up` e `make stream-up`, como voltaram em 04/10 do mesmo estado.

## 12. Ambiente para a revisão

A revisão é de **plano**: nada precisa estar de pé além do que já está — os três bancos e o Airbyte;
Airflow e *streaming* parados. Sondas só de leitura são bem-vindas: consultas no `psql`, `make
preflight ALVO=…`, `make ps`, `docker ps`, `git`. **Nenhum alvo que suba, pause, retome, sincronize,
produza ou reconstrua**, nenhuma troca de branch e nada no repositório além da §13 deste arquivo
enquanto a revisão corre.

## 13. Achados da revisão

**Parecer do Codex — 12/10/2026, primeira rodada.** Base conferida: `main`, `HEAD` e `origin/main` em `c531b87cc602b51227277a04c7cecb774f1f03ea`; somente este plano estava não rastreado. Li o plano inteiro, a trilha nessa base sem as imagens em base64, `CLAUDE.md`, o mapa do README, as pendências pertinentes e o ADR-0046; confrontei as seções indicadas do plano anterior, `consultas.sql`, `sql/`, os quatro `indice.tsv` e os auxiliares solicitados com o Makefile, `docker/airflow_cli.sh`, `docker/preflight.sh`, a composição do Airflow e a Execução Local §5–§6, aprofundando a leitura do produtor, do destino do streaming e da verificação de recuperação. Apliquei a regra de evidência da [skill local `revisao`](../.claude/skills/revisao/SKILL.md). Fiz somente inspeções e sondas de leitura: Git, inventário do HTML, estado dos contêineres, memória, `make ps`, três consultas de `preflight` e consultas ao armazém com a sessão forçada a somente leitura; as saídas que fundamentam os achados estão abaixo. **O desenho didático é viável, mas a declaração ainda não está pronta para execução:** os bloqueantes tratam da interrupção efetiva e dos segredos; os demais achados fecham cobertura, dependências e critérios de prova. As fases respeitam R11, PC-7 e PC-8 são equivalentes para os usos propostos por inspeção, e os erros abrangidos por O4 são reais. O1–O4 permanecem decisões tomadas. Nenhum laboratório, troca de ambiente, troca de branch, correção, commit ou publicação foi executado; evidência de 04/10 é histórica, e comportamento não exercitado nesta revisão permanece **não medido**.

| ID | Veredito | Localização | Achado e recomendação | Reprodução | Saída observada | Situação |
|---|---|---|---|---|---|---|
| RT-01 | bloqueante | §4, fase B; §4.1; `vigia.sh:10–22`, `interromper.sh:9–35` | **O mecanismo herdado não sustenta sozinho a garantia de interrupção.** O vigia acompanha a vida de um PID local, não a execução remota; perder o cliente de espera pode deixá-lo encerrado com a DAG ainda ativa. Não propaga a falha de `interromper.sh`; nesse auxiliar, erro ao listar/cancelar jobs pode virar “nenhum job ativo”, e o prazo de 300 s começa somente depois das primeiras ações, com a pausa da DAG sem prazo externo. Declarar supervisão até estado terminal, identificação da execução atual, tratamento de falha do próprio vigia e prazos de todas as ações. A fase B também põe R31 **antes** de R33/R37, invertendo a prova prévia exigida pela §5.2.5 anterior: colocar as provas aplicáveis antes da carga pesada. O portão continua necessário, mas não demonstra que a interrupção cabe na memória restante. | Ler `nl -ba data/medicoes/material_estudo/vigia.sh` e `nl -ba data/medicoes/material_estudo/interromper.sh`; confrontar a ordem da fase B com o plano anterior §5.2.5. | Inspeção: `while kill -0 "$pid"`; chamada de `interromper.sh` sem verificação do retorno; alternativa `eco "nenhum job ativo"` também no cancelamento malsucedido; `fim=$((SECONDS + 300))` só no passo 4. As provas históricas cobrem o gatilho em modo `registrar` e um `PATCH` separado; não houve ensaio da interrupção completa sob pressão nesta revisão. | **Aceito; reproduzido.** `vigia.sh:10` segue o PID local; `:18` não confere o retorno do `interromper.sh`; `interromper.sh:11–12` escreve "nenhum job ativo" também quando a lista ou o cancelamento falham; o prazo só começa no passo 4. Na fase B, o vigia de 04/10 sai e entra o `vigia_dag.py` (§14.2): acompanha a execução remota até o terminal, conta o prazo global de 300 s a partir do gatilho e dá prazo a cada ação; falha de lista ou de cancelamento é FALHA, e exceção do próprio vigia sai com código 3. A prova vem antes da carga: o vigia em interrupção, com limiar artificial, numa execução de estudo, antes de R31 (§14.3). A §4.1 diz que o portão não prova que a interrupção cabe na memória. |
| RT-02 | bloqueante | §4.1, fase D; §4.3; `airbyte_jobs_api.py:27` | **O “mesmo vigia” não tem a ação específica prometida para a fase D.** Sua única ação efetiva chama o auxiliar que exige DAG/run, consulta o Airflow e executa `captura.retomar`; D tem Airflow parado e somente a sincronização principal. Falta declarar como ligar o vigia ao job dessa sincronização, acompanhar seu estado terminal e abortar sem depender de um `ultimo_run_id` da fase B. A listagem atual filtra somente `running`, e o preflight verifica pods de replicação: “janela parada” não substitui consultar o estado do job identificado, inclusive enquanto ele aguarda execução. Prever esse caminho de validação antes de D, com falha explícita quando não for possível conhecer o estado. | Ler `vigia.sh`, `interromper.sh`, `airbyte_jobs_api.py` e `_trabalho_ativo` em `docker/preflight.sh`. | Inspeção: `dag=${5:-fluxo_batch}` e `arq_run=${6:-data/medicoes/ultimo_run_id}`; `GET /jobs?status=running&limit=100`; preflight procura pods `replication-job`/`orchestrator-repl`. A resposta histórica `HTTP 409` foi para job inexistente, não prova cancelamento real; saída colada em 13.2. | **Aceito; reproduzido.** `airbyte_jobs_api.py:27` só lista `running`, e o *preflight* procura *pods* de replicação. Entra o `vigia_job.py` (§14.2): identifica pela API o *job* da conexão, acompanha o estado dele, `pending` incluído, até o terminal e cancela esse *job* no gatilho; sem identificação em 120 s, falha explícita, com código 3. Identificação e acompanhamento são provados antes de D, em modo de registro, nos dois *jobs* de R31. O cancelamento real continua não exercido (§14.6). |
| RT-03 | bloqueante | E6; §4, Registro; §4.4; `registrar.sh:18–29`; `redigir.py:18` | **O registrador grava a saída sem redação antes de redigi-la.** `mktemp` seguido do redirecionamento para o arquivo bruto contradiz “antes de serem gravadas”, mesmo sendo temporário e fora do Git. A promessa de conservar gravações cruas de sessões também precisa excluir conteúdo secreto. Além disso, a máscara da senha do Airflow depende de o nome do arquivo estar nos argumentos do redator; um `cat` digitado dentro de uma sessão genérica não garante esse contexto. Declarar redação antes de qualquer escrita, inclusive temporários e transcrições, e como reconhecer esse comando dentro da sessão. Exercitar com conteúdo fictício; não usar credenciais reais como controle positivo. | Ler `sed -n '18,29p' data/medicoes/material_estudo/registrar.sh` e `sed -n '14,20p' data/medicoes/material_estudo/redigir.py`. | Inspeção: `bruto=$(mktemp)`; `bash -o pipefail -c "$comando" >"$bruto" 2>&1`; só depois aparece `redigir.py`. A máscara JSON é condicional a `"simple_auth_manager_passwords" in " ".join(sys.argv[1:])`. Nenhum comando de credencial foi executado nesta revisão. | **Aceito; reproduzido.** `registrar.sh:18–19` grava o bruto num `mktemp`, e `redigir.py:18` depende do texto do comando. O `registrar.sh` revisto manda a saída direto ao `redigir.py`, sem arquivo intermediário; o `sessao.py` só escreve transcrição redigida, e o passo que mostra senha é marcado `segredo`, com a saída mascarada inteira. As gravações cruas saíram do plano (§4). Os controles positivos usam valores fictícios (§14.2). |
| RT-04 | bloqueante | §5, itens 3 e 4; §4.4 | **A publicação antecede a varredura de segredos.** O item 3 já republica o Artifact e o item 4 só então verifica. Separar geração de publicação: verificar o HTML local, a variante efetivamente gerada e as evidências pertinentes, com controle positivo e inspeção das imagens, antes de republicar. É ajuste de ordem dentro da entrega proposta, sem reabrir O3. | Ler a sequência numerada da §5 e as entradas/saídas de `publicavel.py`. | Inspeção: item 3, “Gerar a variante publicada […] e republicar”; item 4, “Varredura de segredos”. Nenhuma publicação foi feita pelo revisor. | **Aceito.** A §5 foi reordenada: gerar o HTML local e a variante, conferir a navegação nos dois, varrer segredos no local, na variante e nas evidências, inspecionar as telas, conferir no Chrome, e só então republicar. |
| RT-05 | ajuste | §3.6; trilha, linhas 221–222, 632–636, 1171–1177 e 1734–1747 | **O inventário não fecha todos os pontos de origem.** Os 18 exercícios fora do desafio têm entrada, mas a nova saída da pergunta `[*4]` não tem consulta, vínculo com R05 nem exclusão. O diagnóstico histórico de `KeyError` fica entre as faixas de R35 e R36 e também não está excluído expressamente. Dar destino explícito à segunda ocorrência da saída de `stream-up` no L0 (R40 pode atendê-la) e ao exemplo das Convenções (PC-2/R15). Refinar “blocos `arquivo` são código para ler”: os modelos/teste de R29 e a DAG de R33 precisam ser copiados para arquivos e executados, portanto são exceções dessa exclusão. | Inventário mecânico em 13.2; comparar suas linhas com “Origem no resumo” e a tabela de exclusões. | `pre.cmd: 54`; `Rótulos de saída: 53`; `Exercícios: 21`; `Fora do desafio final: 18`. Os rótulos 632, 1173 e 1736 estão transcritos em 13.2. A consulta nova de `[*4]` foi reproduzida somente para leitura, com as duas linhas esperadas. | **Aceito; conferido no HTML.** R05 ganha a consulta da [\*4] (1736) como segundo ponto de entrada; R15, as Convenções (221–222); R40, a saída do `stream-up` no L0 (632–636). O diagnóstico do `KeyError` (1171–1177) entra nas exclusões, porque virou o desafio d-3. A exclusão dos blocos `arquivo` ganhou as exceções de R29 e R33 (§3.6). |
| RT-06 | ajuste | E1, E3 e E5; PC-3 e PC-7 | **As regras precisam distinguir sintaxe do shell de sintaxe dos outros ambientes.** A proibição literal de `;` em E1 contradiz o terminador SQL ensinado em PC-3 e usado no próprio exemplo R02; `\|\|` também pode ser concatenação SQL. Restringir a proibição aos operadores que encadeiam comandos do shell, preservar terminadores e operadores dentro de SQL e aplicar a continuação `\` de E3 ao shell, não indistintamente ao psql. Rotular a sessão PC-7 como terminal na pasta `dbt`, com PC-1 na aba nova antes de `cd dbt`; comandos `make` continuam na raiz. | Comparar E1 com PC-3 e os passos SQL de R02; ler `Makefile:39`. | Inspeção: E1 contém “Proibidos: `;`”; PC-3 contém “`;` termina a consulta”; PC-7 muda o diretório com `cd dbt`. A equivalência do ambiente dbt é detalhada em 13.1/H2. | **Aceito.** E1 restringe a proibição aos operadores do *shell* e preserva o `;` e o `\|\|` do SQL; E3 aplica o `\` só ao terminal; o PC-7 começa pelo PC-1 na aba nova e rotula os passos como `terminal · pasta dbt` (§3.4, §3.5). |
| RT-07 | ajuste | E10; §3.3, Fim; PC-9; §3.6 e ordem das fases | **As dependências e a devolução do ambiente não formam uma sequência coerente ainda.** R08 remete a R02–R07; R36 depende de R31, embora E10 o inclua na sequência de R33 e a fase B o execute antes de R33. R44 precisa de Beam consumindo, mas PC-6 só prepara transporte e conector; R42 pode já tê-lo encerrado pelo fim obrigatório do roteiro. Definir também se PC-9 fecha cada roteiro isolado ou o grupo encadeado: devolver o estado ao fim de R40 desfaz a preparação dos seguintes. Cada sequência deve dizer onde continua, quem mantém a sessão e quem a encerra, sem impor nova produção de eventos para conseguir retomar. | Comparar E10 e §3.3 com R08/R36/R40/R42/R44; ler `Makefile:500–526`. | Inspeção: fase B põe `R36` antes de `R33`; `stream-up` termina informando “O pipeline é processo em primeiro plano: 'make stream-run'”; PC-6 termina em `stream-status`. Não foi iniciado consumidor nesta revisão. | **Aceito.** As sequências estão na §14.3, cada uma dizendo onde continua, quem mantém a sessão e quem a encerra. Na fase B, R36 vem depois de R31, e as provas vêm antes da carga. Na fase C, o Beam de R42 fica de pé até R45, e o grupo fecha com Ctrl-C e `stream-pause`. O PC-9 vale por grupo; o roteiro usado sozinho diz o que devolver (E10, PC-9). |
| RT-08 | ajuste | H12; R10; E10; fase C | **A alternativa ao offset vencido não está integrada à ordem nem ao oráculo.** R10 vem antes de R42, mas H12 depende de um evento de R42 se 29603 não existir mais. Declarar primeiro a consulta aos limites do log; no caminho alternativo, adiar R10 até haver o evento, carregar a partição/offset realmente observados e conferir o `movement_id` do envelope. Sucesso do comando de consumo, sozinho, não comprova que se leu o evento histórico. Manter a saída de 04/10 identificada separadamente e permitir a diferença no oráculo. | Comparar a fase C com H12 e a consulta da trilha: `rpk topic consume … -o 29603 -n 1`. | Inspeção: ordem `R40, R10, R41, R42`; H12 diz “R10 usa o evento produzido em R42”. A presença atual do offset **não foi medida**, pois o streaming permaneceu parado. | **Aceito.** R40 lê o início do log. Com o 29603 dentro dele, R10 roda logo e confere o `movement_id` `19a5f610…` no envelope. Fora dele, R10 vai para depois de R43, com a partição e o *offset* observados ali; a saída de 04/10 fica rotulada à parte, e o oráculo permite a diferença (§14.3, §14.5). |
| RT-09 | ajuste | §4.2, saída de R23/R29; §4.3, saída de estudo e estado final; PC-9 | **“Git limpo” e saídas de contêineres “iguais” precisam de uma linha de base definida.** Este plano permanece não rastreado e o HTML pode estar em edição até os commits da §5: `git status` vazio não é um oráculo alcançável sem decidir quando esses trabalhos são preservados. Em 04/10 o log de saída também tinha um plano não rastreado. Conferir ausência de diferenças adicionais nos caminhos de estudo, preservar o trabalho documental e usar adição explícita dos arquivos de estudo nos commits, sem `git add .`. Para ambientes, comparar identidade, estado e saúde dos serviços, não uptime, IDs recriados ou texto completo do `docker ps`; conferir também processos no host e servidores de documentação. | `git status --porcelain=v1`; ler `20261004_fase_a/20261004T045227Z_estudo_saida_sessao1.log`; comparar o oráculo com o formato de `make ps`. | Agora: `?? CONVERSAS_COM_CHAT/PLANO_roteiros_passo_a_passo.md`. Histórico de 04/10: `?? CONVERSAS_COM_CHAT/PLANO_material_de_estudo.md`, apesar da saída da branch concluída. Isso não é sujeira de estudo a apagar. | **Aceito; reproduzido**: o plano está não rastreado agora, como esteve o de 04/10. A saída da branch compara com uma linha de base de `git status` tirada antes dela e confere `git diff` vazio nos caminhos de estudo; os *commits* de estudo usam caminhos explícitos. O estado final compara serviço, estado e saúde, mais processos no *host* e servidores de documentação (§4.2, §4.3, PC-9). |
| RT-10 | ajuste | §4.3; R08/R12/R22/R31/R36/R46/R48 | **As duas exceções fixas não bastam para uma validação que muda os dados.** A igualdade histórica funciona para consultas de negócio estáveis antes das mutações, não para novos jobs, capturas, carimbos, eventos ou o pedido sorteado em R08. Definir por roteiro a referência histórica e o resultado que deve permanecer invariável: R22/R46 ligam os 57 pedidos ao job recém-observado e verificam views antes/sync/depois do build; R31 liga XCom, argumento renderizado e certificado ao mesmo job novo; R36 compara tentativas e ingestões antes/depois da mesma execução. R08 também precisa substituir IDs, mês e canal derivados do pedido escolhido, não apenas seu número. As duas diferenças atuais foram confirmadas, mas não devem ser congeladas para depois de B/D. | Consultas de 13.2; comparar §4.3 com as mutações declaradas em §4.2 e `consultas.sql`, bloco `jornada_4`. | Leitura atual: `sync_id 48 → 3443`, `53 → 57`; captura `52 complete` em 40 tabelas; `staging` com 36 views; rejeição `customers/48` na captura 52. `jornada_4` fixa `2025-07` e `Loja online`, valores que não acompanham automaticamente outro pedido. Novos resultados de B/D não foram medidos. | **Aceito.** As duas exceções da §4.3 valem só para a fase A. Os oráculos por roteiro estão na §14.5: R08 deriva IDs, mês e canal do pedido sorteado; R22/R46 ligam os 57 pedidos ao *job* observado e contam as views antes, depois da sincronização e depois do *build*; R31 liga XCom, argumento renderizado e certificado ao mesmo *job* novo; R36 compara tentativas e ingestões antes e depois, na mesma execução. |
| RT-11 | ajuste | §4.2; §8/O1; R23/R24–R29/R41/R42/R44 | **A tabela de estado omite efeitos existentes e fixa um volume que não é garantido.** O produtor também atualiza `oltp.inventory_balances`, inclusive `updated_at`, e pode inserir um par novo; Beam grava `raw.inventory_movements_stream` e avança offsets, além das mensagens de alerta. `LIMITE=50` pode terminar com 51 eventos quando o último sorteio é uma transferência de dois movimentos: tratar o número como previsto e medir o realizado, como R41 já faz. Incluir os artefatos locais pertinentes (`dbt/logs`, compilados e inicialização Terraform), a distância adicional do pacote aprovado e o limite conhecido da limpeza dos logs da DAG. Corrigir a referência da pausa do Airbyte para C e retomada em D, não B/D. São consequências de O1, sem pedir nova decisão sobre executá-lo. | Ler `src/mvp_ed1/streaming/producer.py`, `_gravar`, `_mover_saldo` e `executar`; `sink.py`, `_descarregar`; `terraform_plan.sh`; confrontar com a tabela das fases. | Inspeção: `self._mover_saldo(c, evento)`; `update oltp.inventory_balances … updated_at = now()`; `lote.extend(self._sortear())`, cujo resultado pode ter dois elementos; o auxiliar Terraform chama `init`. Nenhuma produção nova foi feita, portanto 50/51 é análise do limite, não volume medido nesta revisão. | **Aceito; reproduzido.** `producer.py:347–380` atualiza `inventory_balances` e pode inserir um par; `:391` estende o lote com o par da transferência. A tabela da §4.2 ganhou os saldos da origem, o destino e os *offsets* do Beam, os alertas, os artefatos locais e a distância do pacote aprovado; `LIMITE=50` virou "previsto 50, realizado medido"; a pausa do Airbyte foi corrigida para C, e a retomada para D. O limite da limpeza dos *logs* da DAG de estudo está na §14.6. |
| RT-12 | ajuste | §4.3; R13 e R41–R45; D62/D63 | **Faltam oráculos explícitos para a parcela quente e para os alertas desta execução.** Para R13, relacionar os eventos novos ausentes da fato às parcelas da view antes do build; a view filtra saldo disponível abaixo do ponto de reposição, logo um evento escolhido pode não aparecer e deltas podem se compensar. Prever seleção entre os eventos já produzidos e resultado inconclusivo, sem acrescentar produção fora do plano. Para R45, registrar a linha de base e os alertas do intervalo; preservar a distinção entre destino alcançado e ramo de alertas drenado, dada D63, e não exigir saldos corretos enquanto D62 está aberta. **R44 tem um bom oráculo para o destino** — offset alcançado e conteúdo/saldos iguais —, mas isso não certifica o ramo de alerta nem substitui os demais critérios. | Ler `dbt/models/consumption/skus_below_reorder_point.sql`, `20261004_fase_c/sql/digests.sql`, `sink.py` e plano anterior §5.4/§15; consulta de 13.2. | Agora: `linhas_na_view = 540`, `com_parcela_quente = 0`. Inspeção: a view exige saldo disponível menor que `reorder_point_units`; o destino confirma offsets após a transação e só encaminha eventos novos. A prova histórica das duplicatas está colada em 13.2; alertas e parcela quente novos não foram medidos. | **Aceito.** Na §14.5, R13 escolhe, entre os eventos novos ausentes da fato, um par que esteja na view e confere a soma dos deltas contra `quantity_from_stream`; sem par na view, o resultado é inconclusivo e registrado, sem produção a mais. R45 tira a linha de base antes de R41, conta os alertas do intervalo, espera a drenagem com prazo e não exige saldo correto enquanto a D62 estiver aberta. R44 certifica o destino, não o ramo de alertas. |
| RT-13 | ajuste | §4, gravação interativa; §4.3 e §4.5; R29/R34/R35/R36/R47 | **O código final da sessão não comprova o sucesso de cada passo, e as paradas precisam distinguir erros previstos.** Uma sessão pode terminar normalmente depois de SQL ou comandos internos falharem; o registro anterior já contém esse caso. Definir saída/estado esperado por passo, inclusive a falha didática de R29 e as recusas de R47; conferir os prompts antes de enviar o passo seguinte. Parar em erro inesperado, prazo vencido, saída ilegível, falha da gravação/redação ou estado indeterminado. A interrupção da validação por navegador desconectado não cancela trabalho já disparado: declarar como preservá-lo, acompanhá-lo até terminal e verificar coerência antes de pausar serviços. Para R36, obter tentativas na interface: o `dag-status` histórico mostra estados e horários, não `try_number`. | Ler os logs históricos `20261004T044809Z_quarentena_estrutura.log`, `20261004T044808Z_acesso_analyst.log` e `20261004T053114Z_dag_status.log`; confrontar com §4.5. | Histórico: código `0` e `Did not find any relation named "quarantine.legacy_rejections".` no primeiro log; código `0` e quatro `ERROR: permission denied` esperados no segundo. Cabeçalho de `dag-status`: `dag_id logical_date task_id state start_date end_date`. Trechos completos pertinentes em 13.2. | **Aceito; reproduzido** nos dois *logs* citados: código 0 com a relação inexistente e com as quatro recusas. O `sessao.py` confere o *prompt* antes de cada envio e o oráculo de cada passo, com os erros esperados declarados (R29, R47); para em erro inesperado, prazo, saída ilegível ou falha de gravação ou de redação. Parar não cancela trabalho em curso, que segue com o vigia até o terminal (§4.5). As tentativas de R36 vêm da interface. |
| RT-14 | ajuste | R50; §4.3; §10, `recovery-verify` | **R50 depende do pacote, não somente de bancos saudáveis, e sua prova tem alcance limitado.** Declarar diretório e pacote selecionado, `.env`/ambiente Python e contêiner do armazém disponível para `pg_restore --list`. O caminho padrão escolhe `candidato/` se existir, antes de `aprovado/`: isso deve aparecer na conferência. Sem pacote, parar com pré-requisito ausente; não disparar `recovery-pack`. O alvo padrão confere checksums, formato do manifesto e se os dumps podem ser listados; não compara o banco atual nem prova restauração. Explicitar esse resultado esperado no roteiro. | Ler `Makefile:561–563` e `src/mvp_ed1/recovery/cli.py:238–276,873–876`; inspeção de existência registrada em 13.2. | Inspeção: `return destino.candidato if destino.candidato.exists() else destino.aprovado`; a comparação com o banco só ocorre em `if args.contra_o_banco`. `data/recovery/aprovado` existe; seu conteúdo e o resultado de `recovery-verify` **não foram verificados**, conforme a proibição desta revisão. | **Aceito; conferido.** `recovery/cli.py`, em `_pasta_do_pacote`, escolhe `candidato/` antes de `aprovado/`, e hoje só existe `aprovado/`. R50 declara os pré-requisitos, mostra qual pacote foi lido, para sem pacote (sem `recovery-pack`) e diz o alcance: *checksums*, manifesto e *dumps* listáveis, sem comparar com o banco nem provar restauração (§14.4). |
| RT-15 | ajuste | §3.1/R3; §3.7; §5, verificação do HTML | **O teste de navegação proposto é mais fraco que o contrato de ida e volta.** “Pelo menos um ↩” aceita um roteiro com vários pontos de entrada e retorno para apenas um. Verificar IDs únicos, cobertura do inventário por ponto de origem e um retorno para cada ponto que aponta ao roteiro, incluindo `[*4]` e ocorrências repetidas. Repetir a conferência na variante gerada por `publicavel.py`; sua reprodução byte a byte hoje não prova a variante futura. Na validação visual, conferir também a cópia dos comandos com continuação de linha nos dois temas. | Comparar §3.3/Fim e §3.7 com §5.2; ler a transformação de links em `publicavel.py`. | Inspeção: contrato “um ‘↩ Voltar’ para cada ponto”; teste apenas “todo roteiro tem pelo menos um ‘↩’”. Não existe HTML novo a validar nesta rodada. | **Aceito.** O `conferir_navegacao.py` (§14.2) confere IDs únicos, cada ponto de origem com o seu `▶` e um "↩" por ponto, na trilha local e na variante; a conferência no Chrome, nos dois temas, inclui copiar um comando com continuação de linha (§5). |

### 13.1 Parecer sobre H1–H13

| Hesitação | Parecer e recomendação |
|---|---|
| H1 | **Manter os PCs com passos concretos e links aos donos documentais.** É a adaptação didática necessária; só links não atendem ao pedido. Distinguir serviço saudável de dados já carregados: PC-2 não autoriza semeadura quando uma relação falta. PC-4 deve levar até acesso funcional à interface, pois `/health` não prova autenticação. PC-9 deve ter a unidade de devolução definida em RT-07/RT-09 e respeitar o estado inicial também quando um roteiro for usado isoladamente. |
| H2 | **Manter PC-7, com equivalência por inspeção nesta base.** O `.env` atual tem atribuições simples, sem dependência de diretório; carregá-lo de `dbt` via `../.env` exporta os mesmos valores. A ativação põe a `.venv/bin` do projeto no início do `PATH`, e `DBT_PROFILES_DIR=.` resolve o mesmo perfil com o diretório em `dbt`. A sessão dura até `exit`, enquanto o Makefile isola isso no processo da receita. Conferir a raiz na aba nova e o executável resolvido durante a futura validação; não há necessidade de criar alvo novo. O prompt e o funcionamento interativo não foram medidos agora. |
| H3 | **Manter PC-8 para o scheduler.** `docker exec -it <scheduler> bash` e o `docker compose … exec -T airflow_scheduler` entram no mesmo contêiner e usam seu ambiente existente; o próprio `airflow_cli.sh` já usa `docker exec … airflow`. Não é necessário carregar `.env` dentro dele. Restringir o exemplo ao serviço resolvido, sem tratar qualquer contêiner como se tivesse `bash`. As diferenças de TTY, prompt e ruído de saída devem ser observadas na execução; elas não invalidam a equivalência funcional. Ler os `run_id` explicitamente, sem reproduzir a seleção implícita de “última execução” do `dag-status`. |
| H4 | **Cumprir O2 pela interface.** Validar os cliques e as evidências da execução específica, sobretudo as tentativas antes/depois em R36, o mesmo XCom no argumento renderizado e a tarefa realmente encerrada em R37. O ensaio de 04/10 reexecutou só `dbt_docs` pela API; não comprova as três tarefas nem o caminho de interface proposto. Manter separado o uso programático da API pelo vigia, cujo contrato precisa ser fechado em RT-01/RT-02; a tela não substitui essa automação de interrupção. |
| H5 | **Manter O1 e o portão medido imediatamente antes do disparo.** A projeção de aproximadamente 3,1 GB com Chrome deixa pouca folga sobre o portão, mas não demonstra recusa nem segurança: o Airflow ainda precisa estar de pé para a leitura válida. A sonda desta revisão projetou 3,2 GB; não é medição da fase B. O histórico sustenta o portão como precaução, sem garantir o tempo de reação do cancelamento. Explicitar as unidades e os limiares operacionais herdados (3000/1000 na escala de `/proc/meminfo` dividida por 1024), provar o encadeamento antes da carga e respeitar qualquer recusa; RT-01/RT-02 impedem tratar o vigia atual como suficiente. |
| H6 | **Aceitar um pipe explicado, conforme E2.** Preferir filtros que consumam toda a saída quando se precisa preservar o código do produtor. `head -40` pode encerrar a leitura cedo e produzir falha sob `pipefail`; para esses passos, usar uma apresentação que não confunda truncamento com falha real. Um `grep` sem correspondência também precisa ter significado declarado. Não voltar a laços, funções e variáveis-atalho nos passos do aluno. |
| H7 | **Preferir o auxiliar existente, com escopo local e pré-requisito explícito.** Ele está ignorado pelo Git; o roteiro precisa apontar o caminho, explicar as variáveis/credenciais e prever “auxiliar ausente”, sem sugerir que um clone o contém. Mostrar primeiro o plano na `main`, depois somente as duas mudanças esperadas e o estado Terraform preservado; contabilizar o `init` nos artefatos locais. Descartar a alternativa de responder “no”: com `-input=false`, sem plano salvo e sem `-auto-approve`, não há pergunta de aprovação e uma aplicação que dependeria dela falha, conforme a [documentação oficial do Terraform](https://developer.hashicorp.com/terraform/cli/commands/apply). Esse comportamento foi conferido documentalmente, não executado nesta revisão. |
| H8 | **Aceitar 120 colunas como convenção de captura.** Registrar o tamanho efetivo e distinguir quebra visual de alteração no texto copiado. Validar prompts, paginação e retorno ao ambiente anterior; largura sozinha não garante que a sessão recebeu cada comando no momento certo. A sonda anterior em `psql` não valida automaticamente `bash`, `dbt docs serve`, `make logs -f` nem Ctrl-C. RT-13 cobre a prova por passo. |
| H9 | **Os erros são reais; aplicar O4.** A linha 430 promete consultas que faltam nas Paradas 3–6. Em L4 e na DAG de estudo, criar arquivos novos e trocar de branch sem rastreá-los não os retira do checkout; o teste e o arquivo montado continuariam presentes. Acrescentar o commit resolve esse mecanismo, desde que R23/R29/R33 detalhem a adição dos caminhos corretos e R39 mantenha pausa, resolução de execuções, retirada do arquivo e limpeza de metadados. A reprodução por troca de branch foi deliberadamente excluída desta revisão; a conclusão vem das instruções e do procedimento histórico. |
| H10 | **Manter um roteiro por bloco e procedimentos comuns.** Os links precisam cair no passo procurado, com um índice compacto por grupo. O tamanho adicional continua estimativa; não há HTML novo para medi-lo. As lacunas do inventário podem ser atendidas por mais pontos de entrada em roteiros existentes, sem multiplicar roteiros desnecessariamente. Conferir a navegação nos termos de RT-15. |
| H11 | **Manter o desafio final sem receita.** É coerente com a competência de repetir sozinho. Preservar acesso aos PCs e à saída segura da branch/DAG; essa preparação não deve revelar a solução do desafio. A exclusão dos três exercícios finais está justificada. |
| H12 | **Aceitar o evento novo como alternativa, com RT-08.** Não depender silenciosamente de um offset histórico, não produzir eventos extras só para resgatar R10 e não comparar a nova identidade com a saída antiga como se fossem o mesmo evento. A retenção atual permanece não medida. |
| H13 | **O1 resolve a escolha de executar, mas a rotulagem continua necessária.** Separar saída histórica de 04/10, observação nova e passo não concluído; isso já importa no caminho alternativo de R10 e em uma eventual ausência de parcela quente/alertas novos. Se um portão bloquear, conservar o estado e voltar ao Owner como previsto, sem inferir autorização para pular. Só rotular “validado agora” depois de cumprir o oráculo próprio daquele passo. |

### 13.2 Evidências e limites desta rodada

As transcrições abaixo são sondas de leitura desta revisão, salvo onde consta **histórico**. Trechos
cortados estão identificados. As primeiras tentativas de `make ps` e `preflight` não alcançaram o
socket do Docker no sandbox; foram repetidas com a permissão da ferramenta, sem acrescentar ações.
Essa recusa de acesso não foi tratada como falta de memória do projeto.

**Base e escopo.**

```text
$ git rev-parse HEAD
c531b87cc602b51227277a04c7cecb774f1f03ea
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse origin/main
c531b87cc602b51227277a04c7cecb774f1f03ea
$ git status --porcelain=v1
?? CONVERSAS_COM_CHAT/PLANO_roteiros_passo_a_passo.md
$ git diff --stat c531b87
(sem saída)
$ git diff --stat v1.0.0..HEAD -- . ':!CONVERSAS_COM_CHAT' ':!docs' ':!README.md'
(sem saída)
$ git check-ignore data/medicoes/material_estudo/terraform_plan.sh
data/medicoes/material_estudo/terraform_plan.sh
```

**Estado e memória, antes da interrupção da conversa.** Saída de contêineres cortada para mostrar
somente o projeto. Os valores projetados pelo preflight não são medição de Airflow em execução.

```text
$ docker ps -a --format 'table {{.Names}}\t{{.State}}\t{{.Status}}'
NAMES                                        STATE     STATUS
mvp_ed1-airflow_scheduler-1                  exited    Exited (1) 8 days ago
mvp_ed1-airflow_apiserver-1                  exited    Exited (0) 8 days ago
mvp_ed1-airflow_dag_processor-1              exited    Exited (1) 8 days ago
mvp_ed1-airflow_init-1                       exited    Exited (0) 8 days ago
mvp_ed1_kafka_connect                        exited    Exited (137) 8 days ago
mvp_ed1_redpanda                             exited    Exited (0) 8 days ago
mvp_ed1-airflow_db-1                         exited    Exited (0) 8 days ago
airbyte-abctl-control-plane                  running   Up About an hour
mvp_ed1_source_db                            running   Up About an hour (healthy)
mvp_ed1_legacy_db                            running   Up About an hour (healthy)
mvp_ed1_warehouse_db                         running   Up About an hour (healthy)
… (cortada)
$ date -u +%FT%TZ && awk '/^MemAvailable:/ {printf "MemAvailable: %s kB = %.1f MiB\n", $2, $2/1024}' /proc/meminfo
2026-10-12T20:31:46Z
MemAvailable: 4814620 kB = 4701.8 MiB
$ make preflight ALVO=airflow
[preflight] RAM disponível agora: 4.6 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1.4 GB — sobraria 3.2 GB
[preflight] OK
$ make preflight ALVO=streaming
[preflight] RAM disponível agora: 4.6 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'streaming' custa ~0.5 GB — sobraria 4.1 GB

RECUSADO — batch e streaming não sobem juntos (R11; a validação é por partes, ADR-0046).
… (cortada; código de saída do make: 2)
$ make preflight ALVO=trabalho
[preflight] nenhum trabalho em andamento — janela parada.
```

**Conferência do HTML na base, sem imagens.** O contador inclui o rótulo de convenção e o de
registro B5; não significa 53 consultas diferentes.

```python
import re, subprocess
s = subprocess.check_output(
    ['git', 'show', 'c531b87:CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html'], text=True)
print('pre.cmd:', len(re.findall(r'<pre\b[^>]*class="cmd(?:\s|\")', s)))
print('Rótulos de saída:', len(re.findall(r'class="rotulo-saida"', s)))
ex = re.findall(r'<div class="exercicio" data-ex="([^"]+)"', s)
print('Exercícios:', len(ex))
print('Fora do desafio final:', sum(not x.startswith('d-') for x in ex))
for n in (632, 1173, 1736):
    print(f'{n}: {s.splitlines()[n-1]}')
```

Executado com `python3` pela entrada padrão; saída:

```text
pre.cmd: 54
Rótulos de saída: 53
Exercícios: 21
Fora do desafio final: 18
632: <span class="rotulo-saida">saída real · 04/10/2026 · início do <code>make stream-up</code></span>
1173: <span class="rotulo-saida">saída real · 04/10/2026 · <code>attempt=1.log</code> (cortado)</span>
1736: <span class="rotulo-saida">saída real · 12/10/2026</span>
```

**Consultas ao armazém.** Sessão não interativa, somente leitura, sem ensaio dos roteiros:

```bash
docker exec -e PGOPTIONS='-c default_transaction_read_only=on' -i mvp_ed1_warehouse_db psql -U mvp_warehouse -d warehouse_db -X -P pager=off -v ON_ERROR_STOP=1 <<'SQL'
select _airbyte_meta->>'sync_id' as sync_id, count(*) from raw.orders group by 1 order by 1;
select table_type,count(*) from information_schema.tables where table_schema='staging' group by 1 order by 1;
select snapshot_id, status, count(*) as tabelas from governance.legacy_captures group by 1,2 order by 1 desc nulls last limit 4;
select snapshot_id,source_table,legacy_row_id,rejection_origin from quarantine.rejected_legacy_records where snapshot_id=(select max(snapshot_id) from quarantine.rejected_legacy_records) and source_table='customers' and legacy_row_id=48;
select source_system,placed_at,next_order_at,days_to_next_order,is_repeat_window_closed,has_post_order_repeat from trusted.orders where order_number='ORD-0000037' order by source_system desc;
select count(*) as linhas_na_view, count(*) filter(where quantity_from_stream<>0) as com_parcela_quente from consumption.skus_below_reorder_point;
SQL
```

Saída, código 0:

```text
 sync_id | count
---------+-------
 48      |  3443
 53      |    57
(2 rows)

 table_type | count
------------+-------
 BASE TABLE |    41
 VIEW       |    36
(2 rows)

 snapshot_id |  status  | tabelas
-------------+----------+---------
          52 | complete |      40
          49 | complete |      40
          43 | complete |      40
          39 | complete |      40
(4 rows)

 snapshot_id | source_table | legacy_row_id | rejection_origin
-------------+--------------+---------------+------------------
          52 | customers    |            48 | own_invalid
(1 row)

 source_system |       placed_at        |     next_order_at      | days_to_next_order | is_repeat_window_closed | has_post_order_repeat
---------------+------------------------+------------------------+--------------------+-------------------------+-----------------------
 retail        | 2025-07-01 17:58:53+00 |                        |                    | t                       | f
 legacy        | 2024-12-09 10:05:04+00 | 2025-11-04 00:17:36+00 |           329.5920 | t                       | f
(2 rows)

 linhas_na_view | com_parcela_quente
----------------+--------------------
            540 |                  0
(1 row)
```

**Estrutura do `.env` e presença do pacote, sem exibir valores secretos.** Trecho executado com
`python3` pela entrada padrão:

```python
from pathlib import Path
import re
s = Path('.env').read_text()
lines = [l for l in s.splitlines() if l.strip() and not l.lstrip().startswith('#')]
print('Atribuições no .env:', len(lines))
print('Todas simples:', all(re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*=[A-Za-z0-9_.:/+@-]*', l) for l in lines))
print('Com substituição de comando:', any('$(' in l or '`' in l for l in lines))
print('Pacote aprovado existe:', Path('data/recovery/aprovado').exists())
```

```text
Atribuições no .env: 22
Todas simples: True
Com substituição de comando: False
Pacote aprovado existe: True
```

**Histórico de 04/10 — limites das provas herdadas.** Os comandos abaixo apenas leem os registros;
os comandos registrados dentro deles não foram reexecutados. Saídas cortadas:

```text
$ cat data/medicoes/material_estudo/20261004_fase_b/20261004T050039Z_sonda_cancelamento_airbyte.log
… (cortada)
# início: 2026-10-04T05:00:39Z · fim: 2026-10-04T05:00:39Z · código de saída: 1
… (cortada)
DELETE /jobs/999999999 → HTTP 409: {"status":409,"type":"https://reference.airbyte.com/reference/errors#409-state-conflict","title":"state-conflict","detail":"State conflict","documentationUrl":null,"data":{"message":"Job is not currently running"}}
$ cat data/medicoes/material_estudo/20261004_fase_b/20261004T050957Z_prova_vigia_limiar_alto.log
… (cortada)
# vigia: limiar 999999 MB, ação registrar, pid 264255, início 2026-10-04T05:09:57Z
05:09:57 2758
05:09:59 2759
05:10:01 2713
05:10:01 GATILHO: três leituras abaixo de 999999 MB — ação registrar
… (cortada)
$ cat data/medicoes/material_estudo/20261004_fase_b/20261004T050832Z_prova_patch_falhar.log
… (cortada)
PATCH → HTTP 200: failed
$ cat data/medicoes/material_estudo/20261004_fase_b/20261004T050929Z_prova_patch_sem_sleep.log
… (cortada)
processos sleep 300 vivos no scheduler: 0
$ tail -4 data/medicoes/material_estudo/20261004_fase_b/vigia_fluxo_batch.log
05:30:49 3614
05:30:51 3609
05:30:53 3599
# vigia: fim 2026-10-04T05:30:55Z, mínimo 1938 MB, gatilho disparado: 0
$ cat data/medicoes/material_estudo/20261004_fase_a/20261004T044809Z_quarentena_estrutura.log
… (cortada)
# início: 2026-10-04T04:48:09Z · fim: 2026-10-04T04:48:09Z · código de saída: 0
… (cortada)
Did not find any relation named "quarantine.legacy_rejections".
$ sed -n '1,95p' data/medicoes/material_estudo/20261004_fase_a/20261004T044808Z_acesso_analyst.log
… (cortada)
# início: 2026-10-04T04:48:08Z · fim: 2026-10-04T04:48:08Z · código de saída: 0
… (cortada)
ERROR:  permission denied for schema raw
… (cortada)
ERROR:  permission denied for schema staging
… (cortada)
ERROR:  permission denied for schema trusted
… (cortada)
ERROR:  permission denied for schema analytics
… (cortada)
RESET
$ sed -n '1,32p' data/medicoes/material_estudo/20261004_fase_b/20261004T053114Z_dag_status.log
# comando: make --no-print-directory dag-status
# início: 2026-10-04T05:31:14Z · fim: 2026-10-04T05:31:22Z · código de saída: 0
… (cortada)
dag_id       logical_date    task_id                             state    start_date                        end_date
… (cortada)
$ cat data/medicoes/material_estudo/20261004_fase_b/20261004T053146Z_reexecucao_parcial.log
… (cortada)
# início: 2026-10-04T05:31:46Z · fim: 2026-10-04T05:32:13Z · código de saída: 0
… (cortada)
HTTP 200 (executado): dbt_docs
HTTP 200: success
  sincronizar_oltp_para_raw    success            tentativa 1
  dbt_fronteiras               success            tentativa 1
  dbt_docs                     success            tentativa 2
```

**Histórico de 04/10 — idempotência do destino.** Leitura dos registros de antes/depois, cortada:

```text
$ sed -n '1,28p' data/medicoes/material_estudo/20261004_fase_c/20261004T054418Z_duplicatas_antes.log
… (cortada)
mvp.oltp.inventory_movements  0          29801           13700             29801           0
 linhas | soma_quantidade |          digest_eventos
--------+-----------------+----------------------------------
  16101 |          702701 | 09b0f0e26020475297c0f97851f830f8
(1 row)

          digest_saldos           | pares
----------------------------------+-------
 e44e52316f12af93fe3518e533590237 |  2914
(1 row)
$ cat data/medicoes/material_estudo/20261004_fase_c/20261004T054426Z_duplicatas_consumidas.log
… (cortada)
offset confirmado alcançou 30051 depois de 0 s
TOPIC                         PARTITION  CURRENT-OFFSET  LOG-START-OFFSET  LOG-END-OFFSET  LAG   MEMBER-ID  CLIENT-ID  HOST
mvp.oltp.inventory_movements  0          30051           13700             30051           0
 linhas | soma_quantidade |          digest_eventos
--------+-----------------+----------------------------------
  16101 |          702701 | 09b0f0e26020475297c0f97851f830f8
(1 row)

          digest_saldos           | pares
----------------------------------+-------
 e44e52316f12af93fe3518e533590237 |  2914
(1 row)
```

Não foram medidos nesta rodada: pico de memória após `airflow-up`, cancelamento real de job,
sessões interativas PC-7/PC-8, passos pela extensão do Chrome, Ctrl-C dos servidores/seguidores de
logs, retenção do tópico, parcela quente após nova produção, novos alertas, `recovery-verify`,
qualquer reconstrução/check ou o HTML futuro. A revisão não encerra pendências nem constitui
aceite de implementação.

## 14. Resposta à primeira rodada — revisão 2

**Não há segunda rodada, por decisão do Owner** (12/10/2026): *"Verifique se consegue montar o plano e
executar do seu lado, sem retornar ao codex. os creditos de lá estão baixos."* Os quinze achados foram
reproduzidos no código ou no HTML antes de serem aceitos — a coluna *Situação* da §13 diz o que
mudou e onde —, e as recomendações da §13.1 entraram nos PCs e nas regras. Sem a segunda rodada,
ninguém revisa estas respostas antes da execução. Por isso cada ferramenta nova é provada antes de
ser usada, com o resultado gravado (§14.2), e o que não puder ser provado fica declarado na §14.6.

### 14.1 O que mudou, por seção

| Seção | Mudança | Achado |
|---|---|---|
| §3.4 | E1 e E3 separam a sintaxe do *shell* da do `psql`; E2 diz que não há `pipefail`; E10 aponta para as sequências da §14.3 | RT-06, RT-07, 13.1/H6 |
| §3.5 | PC-2 não autoriza semear; PC-4 termina no *login*; PC-7 começa pelo PC-1 e roda na pasta `dbt`; PC-8 só no *scheduler*, com `run_id` explícito; PC-9 por grupo, comparando serviço, estado e saúde | 13.1/H1, 13.1/H3, RT-06, RT-07, RT-09 |
| §3.6 | R05, R15 e R40 ganham pontos de entrada; o `KeyError` entra nas exclusões; os blocos `arquivo` de R29 e R33 viram exceção | RT-05 |
| §4 | Registro sem gravação crua; fases na ordem da §14.3 | RT-01, RT-03, RT-07, RT-08 |
| §4.1 | Unidades e limiares explícitos; `vigia_dag.py` e `vigia_job.py` no lugar do vigia de 04/10 | RT-01, RT-02, 13.1/H5 |
| §4.2 | Os efeitos que faltavam; volume previsto e realizado; a pausa do Airbyte em C e a retomada em D | RT-09, RT-11 |
| §4.3 | As exceções valem só para a fase A; oráculos por roteiro na §14.5 | RT-10, RT-12, RT-13 |
| §4.4 | Redação antes de qualquer escrita; *login* pelo Chrome; varredura antes de publicar | RT-03, RT-04 |
| §4.5 | Paradas por erro inesperado, prazo, saída ilegível e estado indeterminado; trabalho em curso preservado | RT-13 |
| §5 | Navegação conferida no local e na variante, varredura e conferência no Chrome antes de republicar | RT-04, RT-15 |
| §7, H7 | A resposta "no" ao `terraform apply` descartada | 13.1/H7 |

### 14.2 As ferramentas da validação, revisão 2

Todas ficam em `data/medicoes/material_estudo/`, fora do Git, como as de 04/10. São ferramentas da
validação, não componentes do projeto, e nenhuma é usada antes de passar na prova da última coluna.

| Ferramenta | O que faz | Prova antes do uso |
|---|---|---|
| `redacao.py` e `redigir.py` | A redação vira função (`redacao.py`), e o `redigir.py` passa a ser só a linha de comando dela. Ganha `--segredo`, que mascara todo valor de JSON e de `chave: valor` da saída, seja qual for o texto do comando, e `REDIGIR_ENV`, que aponta para outro `.env`, só para o teste | Controle positivo fictício: um `.env` temporário com uma senha inventada e um JSON de senha inventado têm de sair mascarados. Controle negativo: o mesmo JSON sem `--segredo` aparece, o que prova que é a opção que mascara |
| `registrar.sh`, revisto | A saída do comando vai direto ao `redigir.py`; não existe arquivo intermediário. O código gravado é o do comando (`PIPESTATUS`) | Um comando que imprime o segredo fictício sai mascarado no *log*; um `false` fica registrado com código 1 |
| `sessao.py` | Conduz um pseudoterminal de 1000 colunas por 200 linhas (120 na revisão 2; §15, desvio 3), para o paginador do `psql` não abrir (o PC-3 continua ensinando o `q`). Roda um `bash` interativo com um *prompt* marcado que carrega o `$?`; envia cada passo só depois do *prompt* esperado (`bash`, `psql`, *scheduler*); confere o oráculo do passo — texto, erro e código esperados; mascara inteiro o passo marcado `segredo`; escreve só a transcrição redigida, passo a passo; para com código 2 na primeira violação | Uma sessão com os passos de R02; e um passo cujo texto esperado não aparece, que tem de parar a sessão com código 2 |
| `vigia_dag.py` | Acompanha a execução da DAG **pela API do Airflow** até o estado terminal, com *token* renovado, e lê `MemAvailable` a cada 2 s (MiB = kB/1024). Três leituras seguidas abaixo do limiar disparam a interrupção, com **prazo global de 300 s contado do gatilho** e prazo de 30 s por ação: pausar a DAG e conferir `is_paused`; listar os *jobs* do Airbyte não terminais criados desde o início da execução (erro na lista é FALHA, nunca "nenhum job"); cancelar cada um e conferir o terminal; `PATCH` da execução para `failed` e conferir; esperar "janela parada" no `preflight ALVO=trabalho`; na `fluxo_batch`, `captura.retomar` e nenhuma tentativa `pending`. Sai 0 só com tudo conferido, 2 com qualquer ação falha e 3 em exceção do próprio vigia. API ilegível por 60 s vira "estado indeterminado" no *log*, e a memória continua vigiada | **Antes de R31**, em interrupção, com limiar artificial de 999999 MiB, numa execução da DAG de estudo com `dormir_segundos=300`: a sequência inteira tem de rodar e ser conferida, e nenhum `sleep 300` pode sobrar no *scheduler* |
| `vigia_job.py` | Identifica pela API os *jobs* das conexões dadas criados depois de um instante, acompanha cada um até o terminal (os `CONCLUIDOS` do projeto) e, no gatilho, cancela, confere o cancelamento e espera "janela parada". Sem identificação em 120 s, sai com código 3: estado desconhecido, e o Owner é chamado | **Em R31**, em modo de registro, nos dois *jobs* da DAG (`oltp_para_raw` e `legacy_para_raw_legacy`): tem de identificá-los e segui-los até `succeeded` |
| `conferir_navegacao.py` | IDs únicos; todo `href="#…"` resolvido; cada ponto de origem do inventário com o seu `▶`; em cada roteiro, um "↩" para cada ponto que aponta para ele | Numa cópia com um "↩" removido, tem de falhar |

O `airflow_api.py`, o `airbyte_jobs_api.py`, o `vigia.sh` e o `interromper.sh` de 04/10 ficam como
estão, sem uso nesta execução.

### 14.3 Ordem e sequências

**Antes da fase A:** as provas das ferramentas que não dependem de serviço (redação, registrador,
sessão, navegação) e a linha de base: `git status --porcelain=v1`, os serviços com nome, estado e
saúde, e os processos do projeto no *host*.

**Fase A** — roteiros independentes; cada um fecha a própria sessão (`\q`, `exit`, Ctrl-C no
`dbt docs serve` de R28). R23 e R29 abrem e fecham a branch `estudo`, cada um com a sua saída e o seu
oráculo de Git.

**Fase B** — uma sequência só, dona da branch `estudo` e da sessão no *scheduler*:

1. R30: `airflow-up` (o *preflight* decide) e *login* pelo Chrome;
2. R32: a CLI dentro do *scheduler*;
3. R33: branch `estudo`, a DAG copiada do HTML, *commit* por caminho explícito, registro e
   despausa. A branch fica aberta até o passo 10;
4. R34, R35 e R38: *retry*, falha mascarada, agendamento e *backfill*;
5. R37: interromper pela interface uma execução de estudo com `dormir_segundos=300`;
6. a **prova do `vigia_dag.py`**, numa segunda execução de estudo com 300 s (§14.2);
7. o **portão**: três leituras de pelo menos 3000 MiB, com o Airbyte e o Airflow de pé e nada
   rodando;
8. R31: `make dag-run`, o `run_id` copiado da saída, o `vigia_dag.py` em interrupção e o
   `vigia_job.py` em registro, `make dag-wait`, `make dag-status`, o XCom e o renderizado pela
   interface, e o certificado no armazém;
9. R36: limpar `dbt_consumption` com as seguintes, pela interface, na execução de R31;
10. R39: a saída da branch e da DAG de estudo;
11. fim do grupo: `make airflow-pause` e o PC-9. O Airbyte continua de pé.

**Fase C** — uma sequência só, dona do terminal 1 (o Beam):

1. R40: `stream-up`, que pausa o Airbyte; `stream-status`; o `curl` do conector; `rpk topic list`;
   `rpk group describe`; e `rpk topic describe mvp.oltp.inventory_movements -p`, com o início do log;
2. R10, se o *offset* 29603 estiver dentro do log;
3. a linha de base dos alertas: `make stream-alerts` (N₀) e o *high watermark* do tópico de alertas;
4. R41: `make medir CENARIO=streaming LIMITE=2200`, que sobe e encerra o próprio Beam;
5. R42: no terminal 1, `make stream-run`, que **fica de pé até o passo 9**; no terminal 2,
   `stream-corte`, `stream-produce LIMITE=50`, `stream-corte` e `stream-wait`;
6. R43, sobre um evento de R42;
7. R10 pelo caminho alternativo, se o passo 2 não rodou, com a partição e o *offset* observados em
   R43;
8. R13: a parcela quente, antes de qualquer `dbt-build`; e R44: as duplicatas, com o Beam do passo 5;
9. R45: N₁, os alertas do intervalo e a espera de drenagem, de até 300 s; depois, Ctrl-C no
   terminal 1;
10. fim do grupo: `make stream-pause` e o PC-9, sem processo do Beam no *host*.

**Fase D** — uma sequência só:

1. `make airbyte-up`, que retoma o Airbyte;
2. o portão;
3. R22 e R46: as views de `staging` antes; `make sync-airbyte`, com o `vigia_job.py` em interrupção;
   as views depois; o `sync_id` dos 57; `make dbt-build`; as views de novo; e os eventos de C com os
   dois caminhos em `staging`;
4. R49: `make check`;
5. fim: o PC-9, contra a linha de base de antes da fase A.

### 14.4 R50 — o que ele confere, e o que não

Pré-requisitos: `.env`, `.venv` e o contêiner do armazém de pé, porque o `pg_restore --list` roda
nele. O alvo usa `RECOVERY_DIR` (`data/recovery`) e escolhe `candidato/` se existir, senão
`aprovado/` (`recovery/cli.py`, `_pasta_do_pacote`). Hoje só existe `aprovado/`; o roteiro mostra a
linha `RECOVERY_DIR` que o alvo imprime e diz qual pacote foi lido. Sem pacote, o roteiro para, e
`recovery-pack` não entra.

O que o `verify` prova: *checksums* que conferem, manifesto completo no formato atual e *dumps* que o
`pg_restore` lista. **Não** compara com o banco atual — isso é `CONTRA_O_BANCO=1`, fora do roteiro —
e não prova restauração.

### 14.5 Oráculos por roteiro

Para os roteiros cujo resultado muda com a execução, ou que têm critério próprio. Os demais seguem a
§4.3.

| R | Oráculo |
|---|---|
| R03 | Fase A: `sync_id` 48 com 3.443 pedidos e 53 com 57; o pedido 37 no 48; na origem, `max(updated_at)` = `2026-09-01 03:00:00+00`, com 57 pedidos (`cursor_57.sql`) |
| R08 | Do pedido sorteado saem o `order_id`, o mês, o canal e as categorias; a soma de `net_revenue_amount` dos itens dele está contida na linha da view daquele mês, canal e categoria; em `trusted.orders`, uma ou duas linhas, conforme o mesmo `order_id` exista no legado |
| R10 | Caminho histórico: o envelope do *offset* 29603 traz o `movement_id` `19a5f610…`, `op` `c` e `lsn` 256676784. Caminho alternativo: o envelope do *offset* observado em R43 traz o `movement_id` escolhido ali; a saída de 04/10 fica rotulada à parte |
| R13 | Entre os eventos de R41 e R42 ausentes da fato, um par que esteja na view: `quantity_from_stream` igual à soma dos deltas desse par que só existem no caminho quente. Sem par na view, o resultado é **inconclusivo**, registrado, e nenhum evento é produzido a mais |
| R22/R46 | Views de `staging`: 36 antes, 28 depois da sincronização, 36 depois do `dbt-build`; os 57 pedidos da fronteira com o `sync_id` do *job* observado; os eventos de R41 e R42 com `arrived_by_stream` e `arrived_by_batch` verdadeiros; `caminhos_de_ingestao_reconciliam` passa no *build* |
| R29 | `dbt show` com as contagens por status; `dbt test --select estudo_falha_proposital` sai com código 1, e o "Got N results" é igual ao número de pedidos `delivered` contado no mesmo dia; depois, a saída da branch pelo oráculo de Git da §4.2 |
| R31 | `make dag-wait` termina em `success`, com as 13 tarefas `success`; o XCom de `concluir_captura_do_legado`, o `snapshot_id` novo, o *job* da conexão legada registrado pelo `vigia_job.py` e o número nos Modelos Renderizados de `dbt_staging` são o mesmo; a linha nova de `governance.legacy_captures` tem 40 tabelas `complete`; o vigia termina sem gatilho, ou com a interrupção inteira conferida |
| R36 | Na interface, antes: as 13 tarefas na tentativa 1. Depois: `dbt_consumption`, `dbt_fronteiras` e `dbt_docs` na 2, as outras na 1. Nenhum *job* novo no Airbyte e nenhuma captura nova, contados antes e depois |
| R37 | A execução de estudo em `failed`, `dormir` em `failed` e `resumo` em `skipped`; nenhum `sleep 300` vivo no *scheduler*; "janela parada" |
| R41 | O relatório do produtor (emitidos, ≈2.200), o corte lido depois dele, "livro alcançou a sequência", o Beam encerrado limpo e a linha do medidor. Alertas não são exigidos aqui (D63) |
| R42 | Emitidos realizados (50 ou 51), medidos; o `stream-wait` alcança o corte; o destino cresce exatamente o realizado |
| R43 | O `movement_id` mais recente do destino quente aparece na origem e no envelope do *offset* gravado com ele |
| R44 | O *offset* confirmado alcança o *high watermark* depois das duplicatas, e os quatro valores dos *digests* ficam iguais. Certifica o destino, não o ramo de alertas |
| R45 | N₁ − N₀, os alertas do intervalo, com espera de drenagem de até 300 s; zero é resultado registrado; o saldo dentro do alerta não é exigido correto, porque a D62 está aberta |
| R47 | A view lida como `analyst`; as quatro recusas `permission denied` esperadas, nos schemas `raw`, `staging`, `trusted` e `analytics`; `top_skus_by_revenue` lida e `trusted.orders` recusada (exercício l7-1) |
| R48 | Fase A: a rejeição `customers/48` da captura 52, `own_invalid`, com `NULL_DISGUISED` e `NULL_REQUIRED`; a captura 52 `complete` em 40 tabelas |
| R50 | A linha `RECOVERY_DIR`, o pacote lido (`aprovado/`) e a frase final do `verify`, sem `--contra-o-banco` (§14.4) |

### 14.6 O que continua não verificado, ou é risco aceito

- **O cancelamento real de um *job* do Airbyte** pelo `vigia_job.py`. A identificação e o
  acompanhamento são provados em R31; o `DELETE` sobre um *job* vivo, não. Ensaiá-lo custaria uma
  sincronização cancelada no `raw` de trabalho, como já se decidiu em 04/10.
- **O tempo de reação dos vigias sob pressão real de memória.** A prova é com limiar artificial.
- **Os rótulos da interface do Airflow e do Airbyte**, e o que a extensão do Chrome consegue clicar.
  Entram como aparecerem; passo de navegador que não funcionar para a fase (§4.5).
- **Se `airflow dags delete` remove os *logs* das tarefas** no volume `mvp_ed1_airflow_logs`. Será
  observado e registrado, sem limpeza à mão.
- **Os tempos da §4**, ainda estimativa.

## 15. Execução — 12 e 13/10/2026

Rodou na ordem da §14.3, sem a segunda rodada do Codex (§14), entre 21:03Z de 12/10 e 00:01Z de
13/10. Houve uma interrupção de 22:06Z a 23:42Z (desvio 6) e, às 00:15Z, o complemento do PC-2
(§15.4). As evidências ficam em `data/medicoes/material_estudo/20261012_roteiros_*/`, fora do Git:
por sessão, a declaração (`.json`), a transcrição redigida (`.txt`) e o resumo com os códigos
(`.resumo.json`); por pasta, o `indice.tsv`. Nada bruto tocou o disco (RT-03). Toda sessão terminou
com código 0, salvo as duas paradas do desvio 1 e a prova negativa da sessão, que tinha de parar.

### 15.1 O que rodou

| Etapa | Janela (UTC) | O que rodou | Pasta |
|---|---|---|---|
| Provas | 21:03–21:07 | Redação, positiva e negativa, com valores fictícios; registrador (segredo fictício mascarado, `false` com código 1); sessão (R02 com código 0, negativa com código 2); navegação, positiva e negativa | `preparo` |
| Fase A | 21:08–21:25 | Linha de base; PC-1 e PC-2; R01–R09, R11, R12, R14–R21, R23–R29, R47, R48 e R50 — 29 roteiros, o R21 e o R28 com o Chrome | `fase_a` |
| Fase B | 21:27–22:01 | R30, R32–R35, R38, R37 pela interface, a prova do `vigia_dag.py`, o portão, R31 com os dois vigias, R36 pela interface, R39 e o PC-9 — 10 roteiros | `fase_b` |
| Fase C | 22:01–22:06 e 23:42–23:47 | R40, a base dos alertas, R41, R42 e R43, que serviu também de R10; depois da interrupção, R13, R44, R45 e o PC-9 — 8 roteiros | `fase_c` |
| Fase D | 23:47–00:01 | `airbyte-up`, o portão, R22 e R46 com o `vigia_job.py` em interrupção, R49 e o estado final — 3 roteiros | `fase_d` |
| Complemento | 00:15–00:17 | O PC-2 com o banco legado parado de propósito, e o estado de novo | `complemento` |

Os procedimentos PC-3 a PC-9 rodaram dentro dos roteiros que os usam: PC-3 no R02 e no R04; PC-4 no
R15, no R21 e no começo da fase D; PC-5 no R30; PC-6 no R40; PC-7 no R24–R26; PC-8 no R32; PC-9 no
fim das fases B e C. Cada passo deles, na página, traz a saída dessas sessões.

No fim, o estado bateu com a linha de base serviço a serviço — nome, estado e saúde —, sem processo
do projeto no *host*, na `main`, sem a branch `estudo` e com o mesmo `git status`
(`fase_d/20261013T000048Z_estado_final.log`). Depois do complemento, os serviços bateram de novo.

### 15.2 Os oráculos da §14.5, medidos

Os roteiros da fase A sem oráculo próprio bateram com as saídas de 04/10, salvo o que a §4.3 previa
mudar: os 57 pedidos com `sync_id` 53 e a captura 52 na quarentena.

| R | Medido |
|---|---|
| R03 | `sync_id` 48 com 3.443 pedidos e 53 com 57; o pedido 37 no 48; na origem, `max(updated_at)` = `2026-09-01 03:00:00+00`, com 57 pedidos |
| R08 | Sorteado o pedido 1148 (`ORD-0001148`, entregue em outubro de 2025, canal Aplicativo). Os dois itens na fato, 3.208,37 (Estantes) e 10.371,76 (Caixas de som), cabem nas linhas da view do mês, canal e categoria: 31.032,40 e 35.086,68. Em `trusted.orders`, uma linha, do varejo: o legado não tem um pedido 1148 |
| R10 | O caminho histórico não existe mais (desvio 5). Pelo alternativo, o envelope do *offset* 32300 traz o `movement_id` `25fe38b8…` do R43, `op` `c` |
| R13 | Antes de qualquer `dbt-build`, 214 das 474 linhas da view com parcela quente. CD Recife / SKU-0000062: `quantity_from_stream` 14 em 5 movimentos, igual à soma por fora (14, em 5 eventos) |
| R22/R46 | Views de `staging`: 36 antes, 28 depois da sincronização, 36 depois do `dbt-build`. O *job* 56, com 30.136 linhas, e os 57 pedidos com `sync_id` 56. `caminhos_de_ingestao_reconciliam` passou no *build* (PASS=905), e os 2.250 eventos acima da sequência 16101 chegaram pelos dois caminhos |
| R23 | O *hash* do `terraform.tfstate` (`2030494d…`) igual antes e depois; o plano sem mudanças na `main` e com "0 to add, 2 to change, 0 to destroy" na branch; a branch apagada |
| R29 | `delivered` com 2.573 pedidos no `dbt show --limit 10`; o `dbt test` saiu com código 1 e "Got 2573 results", o mesmo número da contagem em `staging`; a branch saiu sem rastro |
| R31 | `dag-wait` em `success` depois de 402 s, as 13 tarefas `success`. O XCom de `concluir_captura_do_legado` (55), o argumento renderizado de `dbt_staging` (`'{legacy_snapshot_id: 55}'`), o *job* 55 da conexão legada (12.744 linhas, seguido pelo `vigia_job.py`) e a captura 55, com 40 tabelas `complete`: o mesmo número. Nenhum vigia disparou |
| R36 | Antes, as 13 tarefas na tentativa 1; depois, `dbt_consumption`, `dbt_fronteiras` e `dbt_docs` na 2, e a execução de volta a "Sucesso" em 53 s. O último *job* continuou 55, e as capturas, 15 |
| R37 | A execução de estudo marcada como falha pela interface; `dormir` `failed` e `resumo` `skipped`; nenhum `sleep 300` vivo no *scheduler*; janela parada |
| R41 | 2.200 eventos emitidos em 45,9 s; corte 18301, lido depois do produtor; "livro alcançou a sequência 18301"; o Beam encerrou limpo em 2 s; o medidor registrou 1 min 02 s |
| R42 | 50 emitidos; corte 18351, alcançado pelo `stream-wait`; o destino foi de 16.101 a 18.351 linhas, exatamente os 2.200 do R41 e os 50 |
| R43 | O evento mais novo do destino, `25fe38b8-2957-4c74-beba-12436ac4920c` (sequência 18351, *offset* 32300), está na origem e no envelope daquele *offset* |
| R44 | 250 mensagens republicadas; *high watermark* 32551, alcançado pelo grupo (`LAG` 0); os quatro valores iguais antes e depois — 18.351 linhas, soma 700.501, `5bda9359…`, e `aa6fea90…` com 2.919 pares. O Beam registrou "lote de 250: 0 gravados, 250 já existiam" |
| R45 | N₀ = 0: o log de alertas começava e terminava em 14. N₁ = 12 (14 → 26), já na primeira leitura: 8 aberturas e 4 normalizações, com 1 correção de evento atrasado |
| R47 | Os cinco papéis sem *login*; como `analyst`, a view lida e as quatro recusas `permission denied` (`raw`, `staging`, `trusted`, `analytics`); no l7-1, `top_skus_by_revenue` lida e `trusted.orders` recusada |
| R48 | A rejeição `customers`/48 da captura 52, `own_invalid`, com `NULL_DISGUISED` e `NULL_REQUIRED`; a captura 52 `complete` nas 40 tabelas |
| R50 | `RECOVERY_DIR` = `data/recovery`, lido `aprovado/`: *checksums*, manifesto e os três *dumps* listáveis, com a frase de que listar não é restaurar |

### 15.3 Desvios

1. **Dois oráculos meus estavam errados; os roteiros, não.** No R24, esperei
   `caminhos_de_ingestao_reconciliam` na saída do `dbt ls --select tag:fronteira`, e ele não leva a
   marca `fronteira`: a sessão parou com código 2 (21:16Z) e passou com o oráculo corrigido (21:19Z).
   No R29, o `dbt show` mostra 5 linhas por padrão, e `delivered` não estava entre elas: parada com
   código 2 (21:20Z); o roteiro ganhou um passo com `--limit 10` e passou (21:21Z).
2. **O `sessao.py` em uso.** O resumo da sessão era gravado por cima da declaração do roteiro, e
   passou para `<nome>.resumo.json`. A prova negativa deixou dois `psql` vivos no contêiner da origem,
   encerrados um a um pelo PID (21:05Z); o `fechar()` passou a sair como o Owner sairia — Ctrl-C,
   `\q` e `exit` — antes de encerrar o pseudoterminal.
3. **A largura do pseudoterminal.** A 120 colunas, o eco das consultas longas quebrava, e a
   transcrição deixava de casar com o passo; a 250, ainda quebrava nas mais longas. Com 1000, não. As
   13 sessões da fase A gravadas a 120 foram repetidas a 1000 (21:11Z–21:13Z), por cima das
   primeiras.
4. **O nome da conexão legada** é `legacy_para_raw_legacy`; o plano dizia `legado_para_raw_legacy`
   (corrigido na §14.2).
5. **A retenção do Redpanda.** O log de `mvp.oltp.inventory_movements` começava em 30051, igual ao
   *high watermark*: nada de 04/10 continuava retido. O de alertas começava e terminava em 14. O
   *offset* 29603 não existia mais, e o R10 seguiu pelo caminho alternativo (§14.3, passo 7), com o
   *offset* 32300 do R43; a base dos alertas foi N₀ = 0.
6. **Interrupção por limite de uso do assistente**, às 22:05Z, logo depois do R43. Antes de parar,
   o estado foi devolvido: o Beam do R42 saiu com Ctrl-C (22:05:57Z), e vieram `stream-pause`,
   `airbyte-resume`, `make ps` e `git status`. Essa devolução não passou pelo registrador: a saída
   está só na transcrição da sessão do assistente. Na volta, às 23:42Z, o R13 veio primeiro, porque
   precisa de eventos que nenhum `dbt-build` absorveu — e as 214 linhas com parcela quente confirmam
   que nenhum rodou no intervalo. Depois, `stream-up` de novo, que pausou o Airbyte, e um segundo
   Beam, que retomou do *offset* 32301. O R44 e o R45 rodaram com ele, e não com o Beam do R42, como
   pedia a §14.3, passo 5. Na página, o R44 ganhou dois passos condicionais que fazem o mesmo.
7. **Segredos na página e nas evidências.** O `<omitido>` da redação, escapado em HTML, parecia
   valor de verdade à revisão de segredos do projeto; na página, todo valor redigido virou `***`, com
   um espaço antes do `</pre>`. O `file_token` do Airflow — o *token* assinado com que a interface lê
   o código da DAG — saiu na transcrição do R39: foi mascarado na transcrição já gravada, o redator
   ganhou a regra `FILE_TOKEN`, e o gerador da página mascara de novo.
8. **A folga de memória foi menor que a de 04/10.** O mínimo de `MemAvailable` na `fluxo_batch`
   foi 1370 MiB pelo `vigia_job.py` e 1402 MiB pelo `vigia_dag.py`, contra 1938 MB em 04/10: 370 MiB
   acima do limiar de interrupção de 1000 MiB. O portão tinha aberto com 3482 MiB. Na fase D, só com
   o Airbyte, o mínimo foi 3836 MiB.
9. **O registrador e o redator de 04/10** foram sobrescritos pela revisão 2 antes de serem
   guardados, e foram recriados com o texto de 04/10 como `registrar_rev1.sh` e `redigir_rev1.py`.
10. **A ordem da §5 mudou.** Foram três *commits*, não dois — as três instruções de branch da O4
    ficaram num *commit* próprio —, e a republicação veio depois deles, para que a página publicada
    seja a do *commit*. Este plano entra por último.
11. **Os índices.** Três linhas dos `indice.tsv` estavam erradas — o início do R28 sem a data, o do
    segundo Beam como "-" e a sessão do Beam do R42 ausente — e foram corrigidas pelos
    `.resumo.json`; os índices das fases B a D ganharam o cabeçalho.

### 15.4 A revisão final da página

Na releitura antes dos *commits*, quatro pontos da seção 11 mostravam como esperado o que só valia
na validação, ou escondiam o que aparece na tela. Foram corrigidos na declaração (`spec.py`,
`spec_b.py` e `spec_c.py`) e regenerados:

- **PC-2.** Só tinha rodado com os três bancos de pé, e a página afirmava, sem medir, o que o
  `make up` mostra ao subir um banco parado. Ensaio às 00:15Z: `docker stop mvp_ed1_legacy_db` e o
  PC-2 inteiro — o `make ps` com duas linhas, o `make up` com o legado `Healthy` em 5,7 s e o
  `make ps` com as três `(healthy)` —, com a janela parada antes e o estado igual depois. A página
  mostra esse ensaio, rotulado "apareceu".
- **O `git status` das linhas de base** (R23, R29, R33 e R39) mostrava, como "deve aparecer", este
  plano ainda não versionado. O rótulo virou "apareceu", com a explicação, e a caixa "Como ler um
  roteiro" diz quando o rótulo é esse.
- **R44**: os dois passos condicionais do desvio 6 e a linha do Beam com "0 gravados, 250 já
  existiam".
- **R45**: o Ctrl-C mostrava só a última linha. Agora mostra o fim real da saída, com os
  *tracebacks* do gRPC explicados.

### 15.5 Entrega

- **Gerador**, fora do Git, em `data/medicoes/material_estudo/secao11/`. `spec.py`, `spec_b.py` e
  `spec_c.py` declaram o texto de cada passo e de onde vem a saída. `transcricoes.py` e `gerar.py`
  tiram a saída da transcrição, pelo comando que abriu o passo. `aplicar.py` aplica à trilha o CSS,
  o sumário, a capa, as Convenções, as correções do resumo (a O4 e a data lógica da §15.6), a
  procedência, os 70 links ▶ e a seção. Escritos à mão, só as telas do navegador (rotuladas "tela
  real") e os arquivos que o roteiro manda criar.
- **Resultado**: 9 procedimentos, 50 roteiros e 70 pontos de origem.
- **Conferências sobre a página final** (`entrega/`):
  - navegação OK na trilha local e na variante, e as negativas acusando 1 problema (um ponto sem
    volta) e 3 (o R22 sem nenhuma);
  - varredura sem achados em 278 arquivos: página, variante, plano, evidências e gerador;
  - as duas senhas digitadas, a do Airbyte e a do Airflow, em nenhum arquivo;
  - as partes revistas conferidas no Chrome, nos dois temas.
- **Commits**, cada um depois do `make check-offline` com código 0: a O4, a seção 11, este plano e,
  depois, a correção da data lógica (§15.6). Sem *push*.
- **Artifact**: republicado a partir da trilha commitada, com o conteúdo igual ao da variante local,
  salvo o invólucro que a publicação acrescenta.

### 15.6 Achados para o Owner

1. **"Execução manual não tem data lógica" vale só para a CLI.** O resumo dizia isso em quatro
   lugares: o diagnóstico da falha no L5b, a reexecução parcial na DAG real, o desafio final e o
   glossário. Medido em 12/10:
   - a execução manual pela CLI (`airflow dags trigger`, a mesma do `make dag-run`) ficou com
     `logical_date` nula (R35);
   - a execução manual pela interface teve `2026-10-12T21:36:57+00:00` (R37): o formulário
     "Acionar Dag" preenche uma.

   O desafio final mandava "disparar uma manual" sem dizer como; pela interface, a falha esperada
   pode não acontecer — isso não foi testado. **Decidido pelo Owner em 12/10/2026: corrigir** ("Se
   há correções a fazer, faça"). As quatro passagens dizem agora que a falta de data lógica é da
   execução disparada pela CLI, e o desafio pede o disparo pela CLI. As trocas estão no
   `aplicar.py`, junto com as da O4.
2. **Os *logs* da DAG de estudo ficam no volume** depois do `airflow dags delete`: 18 pastas em
   `/opt/airflow/logs/dag_id=estudo_didatica`. O R39 diz isso e não manda limpar.
3. **A retenção do Redpanda apagou o *offset* 29603** que o passo 2 do caminho quente mostra. O
   resumo continua certo como registro de 04/10, e o R10 ensina a achar um *offset* vivo.
4. **A folga de memória na `fluxo_batch`** foi de 370 MiB sobre o limiar (desvio 8). Não pede
   decisão; é o dado mais recente sobre o R11.

## 16. Segunda rodada, curta — escopo e dossiê

**Pedido do Owner em 12/10/2026**, depois do *push* de `bc31027`: a opção 2, uma rodada curta e com
escopo fechado, para conferir o que a execução não prova — o texto. Os comandos dos roteiros não
estão em jogo: rodaram na máquina com oráculo por passo (§15). Esta seção é o dossiê da rodada, no
formato da [skill `revisao`](../.claude/skills/revisao/SKILL.md), e a §16.8 recebe o parecer.

### 16.1 Escopo

Três blocos, nada além deles:

- **A. Afirmações do resumo sobre o comportamento das ferramentas.** As 30 frases do manifesto da
  §16.2, nas seções 0 a 10 da trilha, sobre Airflow 3, Airbyte e o *streaming* (Debezium, Kafka
  Connect, Redpanda e Beam). Cada uma recebe um veredito: **confirmada**, com o arquivo ou a sonda
  que a prova; **errada ou imprecisa**, com a frase proposta; ou **não verificável** sem mudar
  estado. As 11 marcadas com ★ dependem de versão ou levantaram suspeita minha, e vêm primeiro. O
  manifesto é uma seleção minha: frase vizinha errada que aparecer na leitura também entra.
- **B. As oito trocas já feitas no resumo.** São os pares `O4` (três) e `DATA_LOGICA` (cinco) de
  `data/medicoes/material_estudo/secao11/aplicar.py`, nos *commits* `b601f03` e `bc31027`. Conferir
  se cada troca está certa, se o mesmo erro sobrou em outro lugar da trilha e se a seção 11 continua
  coerente com elas.
- **C. Cinco roteiros da seção 11, por amostra:** PC-2, R33, R39, R44 e R45 — os que mais mudam
  estado ou foram reescritos depois da execução (§15.4). Em cada um, conferir:
  - o texto contra a transcrição de onde vem a saída — a declaração (`secao11/spec.py` para o PC-2,
    `spec_b.py` para R33 e R39, `spec_c.py` para R44 e R45) diz o arquivo e o passo;
  - as linhas *De pé*, *Muda estado* e *Antes* contra o que os comandos fazem;
  - cada saída de lugar (`\q`, `exit`, Ctrl-C) e a devolução do estado.

**Fora do escopo:** os outros 45 roteiros e os 8 procedimentos restantes, as ferramentas da
validação, o código do projeto e as §13 a §15, salvo como contexto.

### 16.2 O manifesto do bloco A

As linhas são as do HTML em `bc31027`, que esta rodada não altera.

| ID | Linha | Afirmação, literal | Como conferir | Nota |
|---|---|---|---|---|
| AF-01 | 1056 | O Airflow 3.2.2 deste projeto tem quatro processos: o api-server (interface e API REST, porta 8081), o scheduler (decide o que roda e, com o LocalExecutor, executa as tarefas), o dag-processor (lê os arquivos de DAG) e o banco de metadados (airflow_db). | `docker/docker-compose.airflow.yml` |  |
| AF-02 | 1056 | A pasta airflow/ do repositório é montada só leitura dentro dos contêineres: editar o arquivo no host muda a DAG. | os volumes da mesma composição |  |
| AF-03 | 778 | Cinco: airflow_db, airflow_init (roda uma vez e sai), apiserver, scheduler e dag_processor. | a mesma composição |  |
| AF-04 | 1102 | O make dag-run despausa a DAG antes de disparar. | `Makefile` (`dag-run`) e `docker/airflow_cli.sh` |  |
| AF-05 ★ | 1203 | Defina um atalho para a CLI e registre a DAG sem esperar o ciclo de 5 minutos do dag-processor: | a configuração do 3.2.2 (`[dag_processor] refresh_interval`); o código instalado se lê do contêiner parado com `docker cp` |  |
| AF-06 ★ | 1309, 1360, 1724 | No Airflow 2, uma execução cron das 05:00 tinha data lógica igual ao início do intervalo anterior (04:50) e cobria 04:50–05:00. … No Airflow 3, com o padrão desta instalação, a data lógica é o próprio momento do disparo, e o "intervalo" tem largura zero. … A das 14:00, com data lógica 14:00 (semântica do Airflow 3; no 2 … | o padrão do 3.2.2 para cron (`create_cron_data_intervals`) e o XCom de 04/10 que a própria trilha mostra |  |
| AF-07 ★ | 1322 | O --max-active-runs do backfill é um limite próprio, independente do max_active_runs da DAG. | o código ou a documentação do *backfill* no 3.2.2 |  |
| AF-08 ★ | 1322 | A CLI do 3.2.2 só tem backfill create: cancelar ou pausar um backfill é pela interface (botões na faixa "Backfill em progresso") ou pela API. | a definição da CLI no código do 3.2.2, lida do contêiner parado |  |
| AF-09 ★ | 1332, 1728 | Uma Variable é um valor de configuração guardado no Airflow; uma Connection guarda host, porta, usuário e senha de um sistema externo, cifrados com a chave Fernet. … Esquema de criptografia simétrica que o Airflow usa para guardar senhas de Connections e Variables. | o modelo `Connection` do 3.2.2: quais campos são cifrados | Suspeita do autor: só a senha e o `extra` são cifrados; *host*, porta e usuário, não. |
| AF-10 | 1338 | Voltar à main não basta: o registro, as execuções e o backfill ficam no banco de metadados. … A ordem importa, porque apagar a DAG com o arquivo ainda presente faz o Airflow registrá-la de novo: | o R39 de 12/10 (`fase_b/R39.txt`) |  |
| AF-11 | 1046 | Falha de teste de dados não se resolve repetindo: repetir só atrasaria a notícia. Por isso retries: 0 na fluxo_batch (comentário no código da DAG, e Qualidade de Dados §1). | `airflow/dags/fluxo_batch.py` |  |
| AB-01 | 473 | Cópia fiel, com quatro colunas a mais que o Airbyte acrescenta: um identificador da linha, o instante da extração, a geração e um JSON com o job (sync_id) que a trouxe. | as colunas de `raw.orders`, por consulta de leitura |  |
| AB-02 ★ | 1808 | Entre uma sincronização e outra, o Airbyte guarda só o maior valor de updated_at que já viu. | o estado da conexão pela API do Airbyte, só leitura e sem imprimir credenciais | Suspeita do autor: versões novas da fonte PostgreSQL guardam também a contagem de linhas no valor do cursor (`cursor_record_count`). |
| AB-03 | 1813 | Em orders, o modo é incremental com deduplicação: o Airbyte sobrescreve pela chave primária. | `airbyte/streams.yml` |  |
| AB-04 ★ | 763 | Cada pod é um serviço do Airbyte: server (API e interface), worker e workload-launcher (disparam as sincronizações, que nascem como pods próprios de replicação), temporal (o motor de fluxos), airbyte-db-0 (o PostgreSQL interno, onde ficam o contador de jobs e os cursores). | `kubectl get pods` no cluster do `abctl`, como no R17, só leitura |  |
| AB-05 | 860 | Frequência "Manual": quem decide quando sincronizar é o Airflow, não o Airbyte. | `airbyte/main.tf` |  |
| AB-06 | 926 | fonte PostgreSQL em modo CDC (o projeto usa o modo Standard e deixou o CDC para o Debezium). | `airbyte/main.tf` (método de replicação da fonte) |  |
| AB-07 | 1879 | O Airbyte faz carga completa deste livro, só para reconciliar com o CDC (airbyte/streams.yml), e por isso traria o −30. | `airbyte/streams.yml` |  |
| ST-01 | 1369 | O PostgreSQL da origem roda com wal_level=logical: cada transação gravada no log (WAL) pode ser lida por um consumidor através de um slot de replicação. | `show wal_level` no `source_db`, só leitura |  |
| ST-02 | 1369 | O Debezium, um conector do Kafka Connect, lê as inserções em inventory_movements e publica cada uma como mensagem no tópico mvp.oltp.inventory_movements do Redpanda. | `streaming/connectors/inventory_movements.yml` |  |
| ST-03 | 1369, 1483 | O Beam consome o tópico como parte de um grupo de consumo (mvp_ed1_beam), grava cada evento uma única vez no destino (on conflict do nothing) e só então confirma o offset. … A entrega é at-least-once com escrita idempotente, e provei com duplicatas injetadas e conferência de offset. | `src/mvp_ed1/streaming/sink.py` e `transport.py` |  |
| ST-04 | 1399 | Os tópicos _mvp_connect_* são onde o Kafka Connect guarda a própria configuração, os offsets do conector (a posição no WAL) e o status. | `docker/docker-compose.streaming.yml` |  |
| ST-05 | 1399 | O tópico de alertas ainda não existia; ele nasce no primeiro alerta, porque o Redpanda cria tópicos sozinho (auto_create_topics_enabled = true). | a mesma composição (configuração do Redpanda) |  |
| ST-06 ★ | 1401 | O grupo do Beam apontava para o offset 6009, mas o log começa em 13700: o estado ficou assim depois da restauração de 25/09. … Ao subir, o Beam pediu o 6009, o consumidor caiu para o mais antigo disponível (auto.offset.reset: earliest) e releu 13.700 mensagens antigas. | a evidência de 04/10 (`20261004_fase_c/`) e a configuração do consumidor em `transport.py` | Suspeita do autor: a conta "releu 13.700 mensagens" depende do fim do log naquele dia, que a frase não mostra. |
| ST-07 ★ | 1419 | No encerramento, o Beam imprime um traceback de gRPC ("Failed to read inputs in the data plane"), um ruído conhecido do executor local depois do SIGINT, já registrado no ciclo de 25/09. | as transcrições de 12/10 (`fase_c/R42_terminal1.txt` e `R44_terminal1.txt`) | O passo do Ctrl-C no R45 diz o mesmo com outras palavras. |
| ST-08 | 1446 | O make medir encerra o Beam quando o destino alcança o corte, mas os alertas saem de outro ramo, que só recebe painéis quando o watermark fecha as janelas. | `src/mvp_ed1/streaming/pipeline.py` |  |
| ST-09 ★ | 1469 | "c" é uma inserção ("r" seria leitura do snapshot inicial); lsn é a posição da transação no WAL; snapshot: | a documentação do Debezium 3.6 para `source.lsn` | Suspeita do autor: o `lsn` é a posição do evento no WAL, não a da transação. |
| ST-10 ★ | 1484 | "O que acontece com o slot de replicação se o conector morrer?" O PostgreSQL segura WAL para ele até o disco acabar; por isso make stream-down FORCE=1 remove o slot (a pegadinha clássica de CDC, comentada no Makefile). | `show max_slot_wal_keep_size` no `source_db` (só leitura) e o alvo `stream-down` do `Makefile` | A ajuda do alvo (`Makefile`, linha 537) fala em apagar tópicos, não o *slot*. |
| ST-11 | 1884 | O contrato está no Modelo de Dados §5, e quem o fiscaliza é o consumidor: se o Debezium capturar um UPDATE, DELETE ou TRUNCATE no livro, o Beam para com ContratoViolado ("defeito na origem, não evento de negócio", src/mvp_ed1/streaming/envelope.py). | `src/mvp_ed1/streaming/envelope.py` |  |
| ST-12 | 1619 | A ordem importa num ponto: o snapshot do streaming vem antes do primeiro dbt-build, porque o staging do estoque lê a tabela que só o Beam cria. | a criação da tabela em `sink.py` e o modelo de *staging* do estoque |  |

### 16.3 O que já foi verificado, com a saída

A execução inteira está na §15. Depois dela, só documentação mudou:

```text
$ git log --oneline c531b87..bc31027
bc31027 docs: corrige na trilha a afirmação de que execução manual não tem data lógica
22ddb87 docs: registra o plano dos roteiros passo a passo, a revisão do Codex e a execução
f8f9105 docs: acrescenta à trilha a seção 11, com os roteiros passo a passo
b601f03 docs: corrige na trilha a saída das branches de estudo, que deixava arquivo novo na main
$ git diff --stat c531b87 bc31027
 CONVERSAS_COM_CHAT/PLANO_roteiros_passo_a_passo.md | 1325 ++++++++
 .../trilha_de_estudo_fase_local.html               | 3458 +++++++++++++++++++-
 2 files changed, 4773 insertions(+), 10 deletions(-)
```

O `make check-offline` antes de `bc31027`:

```text
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 109 documentos, 1020 links de arquivo, 152 âncoras, 635 citações de ADR — nada quebrado
511 passed, 134 deselected in 146.81s (0:02:26)
check-offline: as três etapas passaram
```

O `make check` completo não rodou de novo: o último foi o do R49 (§15.2), e de `c531b87` para cá
nenhum código mudou. Regenerar a trilha a partir de `c531b87` com o `aplicar.py` dá o mesmo arquivo
de `bc31027` — o `cmp` não acusou diferença. A navegação e a varredura da variante publicada estão
em `data/medicoes/material_estudo/20261012_roteiros_entrega/`.

### 16.4 Não verificado

- **As 30 afirmações do manifesto.** Nenhuma foi conferida de novo em 12/10; as que um roteiro
  mediu, com saída na trilha, ficaram de fora do manifesto.
- **A falha do desafio final com o disparo pela interface:** não rodou. A frase nova afirma só que o
  formulário preenche a data lógica, o que o R37 mediu.
- **Os ramos "senão, pule" dos passos condicionais do R44:** rodou o caminho de subir de novo; o de
  pular, não.
- **A explicação dos *tracebacks* do Ctrl-C no R45** ("o executor local do Beam sendo derrubado") é
  interpretação minha, não conferida no código do Beam.
- **O PC-2 com um banco de pé, mas sem `(healthy)`:** só o banco parado foi ensaiado.
- **Os roteiros a partir de outro estado inicial da máquina**, como o Airflow já de pé no R30 ou o
  *streaming* já de pé no R40.
- **A conferência visual de `bc31027` no Chrome:** o navegador estava fechado.

### 16.5 Premissas

- As versões das ferramentas são as da Procedência da trilha: Airflow 3.2.2, `abctl` v0.30.4 com o
  *chart* do Airbyte 2.3.0, Debezium 3.6.2, Redpanda v25.2.4, PostgreSQL 16.15 e Beam 2.76. Em 12/10,
  só o `psql` 16.15 e o Beam 2.76.0 apareceram nas transcrições; as outras não foram reconferidas.
- As evidências em `data/medicoes/material_estudo/` são o registro das execuções de 04/10 e 12/10.
  Ficam fora do Git e se leem no disco.

### 16.6 Ambiente e regras da rodada

A máquina está assim, e assim deve ficar:

```text
$ make preflight ALVO=trabalho
[preflight] nenhum trabalho em andamento — janela parada.
$ docker ps -a --filter name=mvp_ed1 --filter name=airbyte --format '{{.Names}} {{.State}} {{.Status}}'
airbyte-abctl-control-plane running Up
mvp_ed1-airflow_apiserver-1 exited Exited
mvp_ed1-airflow_dag_processor-1 exited Exited
mvp_ed1-airflow_db-1 exited Exited
mvp_ed1-airflow_init-1 exited Exited
mvp_ed1-airflow_scheduler-1 exited Exited
mvp_ed1_kafka_connect exited Exited
mvp_ed1_legacy_db running Up(healthy)
mvp_ed1_redpanda exited Exited
mvp_ed1_source_db running Up(healthy)
mvp_ed1_warehouse_db running Up(healthy)
```

(A saída do `docker ps` passou pelo mesmo `sed` da §15, que tira o tempo de *uptime*.)

- **Sondas permitidas, todas de leitura:**
  - arquivos e Git;
  - SQL nos bancos, com a sessão em somente leitura;
  - GET na API do Airbyte pelos auxiliares do projeto, sem imprimir credencial;
  - o código do Airflow 3.2.2, lido dos contêineres parados com `docker cp`;
  - o pacote do Beam no `.venv`.
- **Proibido:** subir o Airflow ou o *streaming* (R11), mudar estado, trocar de branch, fazer
  *commit* ou publicar. Sonda que precise de algo disso vira "não verificável sem subir",
  registrada, e a rodada segue.
- O parecer entra na §16.8, sem *commit*.

### 16.7 Onde hesitei

- **O rótulo "apareceu".** O critério é a saída depender do estado da máquina de quem roda — um
  `git status`, um banco parado de propósito. Horários e contadores também variam, e a caixa "Como
  ler um roteiro" avisa isso sem trocar o rótulo.
- **As correções do resumo como pares no `aplicar.py`**, fora do Git, em vez de edição direta do
  HTML. Assim a seção 11 continua regenerável, mas o gerador não é versionado; versioná-lo seria
  decisão do Owner.
- **Os passos condicionais do R44** saíram da interrupção da execução (desvio 6). A alternativa era
  tirá-los e deixar o R44 supor o Beam do R42 de pé.
- **O Ctrl-C do R45** mostra as sete últimas linhas, com "…". A alternativa era a saída inteira, com
  cerca de 90 linhas de *traceback*.
- **A seleção do manifesto** é minha. Suspeitei de cinco frases — AF-09, AB-02, ST-06, ST-09 e
  ST-10 — e anotei o motivo na coluna Nota, sem conferir.

### 16.8 Achados da segunda rodada

**Parecer do Codex — segunda rodada, base 6e1b7e40934a322360fd0e3a8c716470b11c4f16, main inicialmente limpa.** Li CLAUDE.md, a skill revisao, a §16 e o contexto da §15; conferi os trechos do manifesto pelas linhas do HTML, os oito pares do aplicar.py e as declarações/transcrições de PC-2, R33, R39, R44 e R45. Priorizei os itens ★, lendo o código do Airflow copiado do scheduler parado e o pacote Beam instalado; consultei também a documentação oficial do Debezium 3.6. As sondas novas foram Git, leitura de arquivos, enumeração dos pods, SQL com transaction_read_only=on e GETs do Airbyte pelo auxiliar do projeto, sem exibir credenciais. **O texto precisa dos ajustes abaixo antes de encerrar a revisão; R33 tem uma pré-condição bloqueante para preservar trabalho já preparado no Git.** As oito substituições corrigem os erros originais, e as saídas da amostra correspondem às transcrições, ressalvadas as interpretações apontadas. AB-02 não pôde ser confirmado pelo GET permitido; ST-05 depende de configuração efetiva não declarada no arquivo citado. Não iniciei serviços nem reexecutei roteiros. Evidências históricas estão identificadas; leitura de código não foi apresentada como ensaio de execução.

**Vereditos do manifesto**

Nos caminhos de código do Airflow abaixo, a raiz é /tmp/rt2_airflow_6e1b7e4, a cópia obtida em E2. “Trilha” significa CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html nesta base. E1–E7 estão ao fim desta seção.

| ID | Veredito | Evidência (arquivo/comando e trecho decisivo) |
|---|---|---|
| AF-01 | imprecisa | docker/docker-compose.airflow.yml:83–139 declara quatro serviços permanentes e um inicializador, não quatro processos do sistema operacional. Proposta: “O Airflow deste projeto tem quatro serviços permanentes: api-server, scheduler com LocalExecutor, dag-processor e banco de metadados; airflow_init executa a migração e termina.” RT2-11. |
| AF-02 | confirmada | docker/docker-compose.airflow.yml:68: - ../airflow:/opt/mvp_ed1/airflow:ro. A alteração no host fica visível à próxima leitura/processamento da DAG; não exige reconstruir a imagem. |
| AF-03 | confirmada | docker/docker-compose.airflow.yml:83,103,108,120,130: airflow_db, airflow_init, airflow_apiserver, airflow_scheduler, airflow_dag_processor; o inicializador usa command: db migrate e restart: "no". |
| AF-04 | confirmada | Makefile:477–485 chama airflow_cli.sh disparar; docker/airflow_cli.sh:112–124 executa dags unpause, confere a DAG despausada e só depois dags trigger. |
| AF-05 ★ | confirmada | config_templates/config.yml:2828–2834: refresh_interval procura arquivos novos e tem default: "300"; o compose não sobrescreve esse parâmetro. É a descoberta do arquivo novo deste exemplo, não todo reprocessamento: min_file_process_interval tem default: "30" em 2864–2872. |
| AF-06 ★ | imprecisa | config_templates/config.yml:2607–2627 distingue CronTriggerTimetable de CronDataIntervalTimetable, com create_cron_data_intervals default: "False". Trilha:1302–1308 mostra 05:00 mesmo com unpause às 05:04. Data lógica é o horário **agendado**, não o instante efetivo de disparo; a configuração, disponível desde 2.9, também impede generalizar por versão. Proposta em RT2-02. |
| AF-07 ★ | confirmada | jobs/scheduler_job_runner.py:2309–2337 conta por (dag_id, backfill_id); usa backfill.max_active_runs no ramo de backfill e elif dag_run.max_active_runs no outro. São limites separados. |
| AF-08 ★ | confirmada | cli/cli_config.py:1076–1094: BACKFILL_COMMANDS contém somente name="create". api_fastapi/core_api/routes/public/backfills.py:114,141,167 expõe /pause, /unpause e /cancel. Confirmação da CLI e da alternativa API por código; os botões da interface não foram reexercitados. |
| AF-09 ★ | errada | models/connection.py:131–138,369–407 cifra _password e _extra; host, login e port são colunas comuns. models/variable.py:99–105 cifra o valor da Variable. O glossário também chama esse valor de “senha”. Propostas em RT2-03. |
| AF-10 | confirmada | R39.txt registra a troca de branch antes de is_stale=True, Deleting Dag e Removed 76 record(s), seguida de dags list só com fluxo_batch. api/common/delete_dag.py:55–93 confirma a remoção de metadados; limites em RT2-07. Evidência histórica em E7, sem nova exclusão. |
| AF-11 | confirmada | airflow/dags/fluxo_batch.py:41–46: comentário “falha de teste de dados não se resolve repetindo” e default_args com "retries": 0. |
| AB-01 | confirmada | SQL somente leitura em E3: _airbyte_raw_id, _airbyte_extracted_at, _airbyte_meta, _airbyte_generation_id; o JSON contém changes e sync_id. Confirma a estrutura descrita para raw.orders; não é nova comparação integral de todas as linhas da réplica. |
| AB-02 ★ | não verificável | E4: `GET /connections/<id>` devolveu HTTP 200 sem estado do cursor; `GET /connections/<id>/state` devolveu 403. Não consultei endpoints POST de estado nem alterei permissões. “Só o maior updated_at”, inclusive a ausência de cursor_record_count, permanece **não medido** nesta rodada; o 403 não prova que o campo inexiste. |
| AB-03 | confirmada | airbyte/streams.yml:134–137: orders, modo: dedup_history, cursor: updated_at, chave: [id]; airbyte/main.tf:22–25 traduz para incremental_deduped_history. |
| AB-04 ★ | imprecisa | E5 mostra serviços em Running e bootloader em Completed: nem todo pod é um serviço permanente. Proposta: “Os pods incluem serviços do Airbyte e tarefas temporárias: server atende API/interface; worker e workload-launcher participam da execução; temporal coordena fluxos; airbyte-db-0 mantém metadados; bootloader termina após a inicialização e as sincronizações usam pods próprios.” A listagem confirma identidades/estados, não inspeciona o conteúdo do banco interno. RT2-11. |
| AB-05 | confirmada | airbyte/main.tf:158–160: comentário sobre disparo pelo Airflow e schedule = { schedule_type = "manual" }. É a política do projeto; o modo não impede disparo humano pela interface ou CLI. |
| AB-06 | confirmada | airbyte/main.tf:94–97: replication_method = { method = "Standard" }; streaming/connectors/inventory_movements.yml:14 declara PostgresConnector para o CDC. |
| AB-07 | confirmada | airbyte/streams.yml:95–107: inventory_movements usa full_refresh para reconciliação; airbyte/main.tf:22 o traduz para full_refresh_overwrite. Trazer o valor alterado é conclusão condicional ao cenário hipotético, não atualização executada nesta revisão. |
| ST-01 | confirmada | E3: show wal_level → logical, com transaction_read_only → on. streaming/connectors/inventory_movements.yml:30–33 declara pgoutput, slot e publicação. |
| ST-02 | confirmada | streaming/connectors/inventory_movements.yml:14,41–43: PostgresConnector, table.include.list: oltp.inventory_movements, topic.prefix: mvp; o tópico correspondente aparece no registro de R44. |
| ST-03 | confirmada | src/mvp_ed1/streaming/transport.py:40–57 desliga auto commit; src/mvp_ed1/streaming/sink.py:187–195 faz on_conflict_do_nothing, sai da transação e depois chama _confirmar_offsets. R44.txt registra consumo até 32551 e conteúdo/saldos iguais antes/depois; E7 traz a comparação e o lote duplicado. group.id para offsets não implica participação no protocolo de membros (RT2-06). |
| ST-04 | confirmada | docker/docker-compose.streaming.yml:67–69: CONFIG_STORAGE_TOPIC, OFFSET_STORAGE_TOPIC e STATUS_STORAGE_TOPIC apontam para os três tópicos _mvp_connect_*. |
| ST-05 | não verificável | docker/docker-compose.streaming.yml:17–49 não fixa auto_create_topics_enabled. O registro 20261004T053607Z_rpk_topicos.log mostra ausência do tópico; registros posteriores mostram alertas, mas isso não mede o parâmetro efetivo nem o instante de criação. **Não verificável sem subir** o Redpanda nesta rodada; não o iniciei. |
| ST-06 ★ | confirmada | E6 soma os lotes de 04/10: 15901 processados, 2201 gravados, 13700 já existentes, com reset explícito 6009 → 13700. A suspeita numérica não se confirmou. É evidência histórica, não releitura nova. |
| ST-07 ★ | imprecisa | E7 situa o traceback depois de ^C e da destruição do Prism. Porém apache_beam/runners/worker/data_plane.py:762–775 registra a mesma mensagem para uma exceção geral de leitura. A última linha do projeto vem apenas de except KeyboardInterrupt em streaming/cli.py:209–213. Proposta delimitada ao caso observado em RT2-05. |
| ST-08 | confirmada | src/mvp_ed1/streaming/pipeline.py:272–301 separa GravarDeltas do ramo com WindowInto, AfterWatermark e CombinePerKey; painéis atrasados usam AfterCount(1). O corte do destino não certifica drenagem desse ramo. |
| ST-09 ★ | imprecisa | A [documentação do Debezium 3.6](https://debezium.io/documentation/reference/3.6/connectors/postgresql.html#postgresql-create-events) distingue txId de “Offset of the operation in the database log”. c/r estão corretos; source.lsn localiza a operação/evento, não identifica a transação inteira. Proposta em RT2-04. |
| ST-10 ★ | confirmada | E3: max_slot_wal_keep_size → -1. Makefile:537–544 chama maintenance drop-slots --force, além de down -v; maintenance.py:33–50 chama pg_drop_replication_slot e confere ausência, recusando slot ativo/de outro banco. A ajuda abreviada não invalida a frase. Remoção não executada. |
| ST-11 | confirmada | src/mvp_ed1/streaming/envelope.py:24–27,73–82 aceita c/r e levanta ContratoViolado para u/d/t; o conector declara skipped.operations: none. |
| ST-12 | confirmada | src/mvp_ed1/streaming/sink.py:100–151 cria a tabela em garantir_tabela/setup; dbt/models/staging/stg_retail__inventory_movements.sql:50 lê inventory_movements_stream. No ciclo do zero, o caminho quente precisa ser preparado antes do primeiro build; não implica refazer snapshot antes de todo build. |

**Conferência das oito substituições (bloco B).** O4-1 (linha 1024), O4-2 (1142) e O4-3 (1340) corrigem o arquivo novo que sobrevivia à troca de branch; R29 e R33 registram os arquivos por caminho e R39 parte desse commit. DATA_LOGICA-1 (1240), -2 (1243), -3 (1678), -4 (1679) e -5 (1737) restringem corretamente a afirmação ao disparo CLI sem --logical-date, à execução do make dag-run e ao desafio pela CLI. O código instalado passa args.logical_date sem preenchê-lo e só inclui a chave no contexto quando há valor (cli/commands/dag_command.py:83–90; api/common/trigger_dag.py:76–92; sdk/execution_time/task_runner.py:274–292). Evidência histórica de CLI/interface em E7. A busca dos pares, em E6, encontrou cada novo trecho uma vez e nenhum antigo; a leitura complementar das passagens de data lógica e saída de branch não encontrou outra repetição desses dois erros originais. Isso não dispensa RT2-01. O desafio com a interface não foi ensaiado.

**Conferência da amostra (bloco C).** PC-2 corresponde ao ensaio PC2_parado.txt: banco parado e espera --wait sustentados pelo registro e por Makefile:197–201; banco já ativo sem healthy não foi reensaiado. make up aplica a composição: “com os três já de pé, ele só confere” vale para a composição inalterada do ensaio, não como garantia de operação exclusivamente de leitura. R33b.txt contém o commit, registro, unpause e exit apresentados. R39.txt contém as três saídas por exit, a remoção do sinal e o retorno à main; não devolve por si só o estado ligado/desligado do Airflow. R44.txt contém as duas saídas por \q e a prova de idempotência; o Beam continua até o Ctrl-C de R45, registrado em R44_terminal1.txt. R45 usa alertas_N0.txt, R45.txt e PC9_fase_c.txt; retomar o Airbyte fica delegado ao PC-9. Os ramos de pular em R44 e a execução da amostra em outro estado inicial são **não verificáveis sem subir** nesta revisão. Não reavaliei os outros roteiros nem as ferramentas de validação.

**Achados**

As reproduções por inspeção não pedem executar as ações mutantes citadas. Ajustes no derivado devem nascer da declaração correspondente; nenhum foi aplicado pelo revisor.

| ID | Veredito | Localização | Achado e recomendação | Reprodução | Saída observada | Situação |
|---|---|---|---|---|---|---|
| RT2-01 | bloqueante | R33:4045–4069; R39:4458–4465; spec_b.py:173–177,243–244 | **Anotar pendências não protege o índice do Git.** git commit -m inclui tudo que já estiver preparado, mesmo que o git add nomeie só a DAG. R39 apaga a branch antes de comparar o status; trabalho preparado antes do estudo pode acabar nesse commit e sair da main junto da DAG. Acrescentar às pré-condições: partir da main, branch estudo ausente e índice sem alterações preparadas; caso contrário, parar e preservar o trabalho. Conferir os caminhos do commit e a linha de base antes de excluir a branch. O4 continua válida. | Inspecionar spec_b.py:173–177,243–244 e R33a.txt/R33b.txt. Não criar branch nesta rodada. | Declaração: “anote o que aparece”; git add airflow/dags/estudo_didatica.py seguido de git commit -m "estudo: DAG de estudo"; em R39, git branch -D estudo precede git status. O registro cobre pendência não rastreada, não índice previamente ocupado. Cenário adverso não executado. | **Aceito; reproduzido** num repositório descartável (`20261013_roteiros_revisao2/20261013T044757Z_rt2_01_indice.log`): `A  b.txt`, preparado antes do estudo, entrou no `git commit -m` e sumiu da `main` com o `git branch -D`. Vale também para o R29. R29 e R33 ganharam, na linha de base, a regra do índice limpo (letra na primeira coluna do `git status --porcelain=v1`: pare); R23, R29 e R33, o passo `git branch --show-current` e o aviso de branch já existente; R29 e R39, o `git log --oneline --stat main..estudo` antes de apagar a branch. Os passos novos rodaram num ensaio num clone descartável (`ensaio_git_clone.txt`), e o rótulo diz isso. `9e6f3ac`. |
| RT2-02 | ajuste | AF-06; trilha:1309,1360,1364,1724; repetição em 4331 | **Data lógica de cron não é a hora real do disparo nem regra universal da versão 3.** Proposta: “Nesta instalação, create_cron_data_intervals=False usa CronTriggerTimetable: a data lógica é o horário previsto no cron e o intervalo tem largura zero, mesmo que a execução comece depois. Com CronDataIntervalTimetable, ela é o início do intervalo coberto.” No exercício: “Às 14:07, a execução mais recente corresponde às 14:00 nesta configuração.” Ajustar a generalização da seção 11. | Ler config_templates/config.yml:2607–2627 e comparar trilha:1301–1308; E7 também traz R33. | Código distingue os timetables. Histórico R33: logical_date 21:20:00, start_date 21:29:49.387342. Os horários são diferentes; nenhuma nova execução foi disparada. | **Aceito; conferido** no código do 3.2.2 (`create_cron_data_intervals`, *default* `False`, `version_added: 2.9.0`; com `CronTriggerTimetable`, a data lógica é o horário que a execução tenta agendar) e no R33b (data lógica 21:20, início 21:29:49). Trocadas as quatro passagens do resumo — L5c, conferência do l5c-1, "Como falar disso" e glossário — e o passo do XCom no R38. `324cfae`, `9e6f3ac`. |
| RT2-03 | ajuste | AF-09; trilha:1332,1728 | **Fernet não cifra host, porta e login da Connection.** Proposta: “Uma Connection guarda parâmetros de acesso; com chave Fernet válida, o Airflow cifra a senha e extra, enquanto host, porta e login ficam sem essa cifra. Uma Variable guarda um valor de configuração, também cifrado com Fernet.” No glossário, usar “senha e extra das Connections e valores das Variables”. Não altera a pendência da chave inválida. | Ler models/connection.py:131–138,369–407 e models/variable.py:99–105 na cópia E2. | Inspeção: fernet.encrypt aplicado a self._password, self._extra e self._val; host/login/port têm mapped_column comum. | **Aceito; conferido** em `models/connection.py` e `models/variable.py` do 3.2.2: `fernet.encrypt` só em `_password`, `_extra` e `_val`. Trocadas a frase do L5c e a do glossário. `324cfae`. |
| RT2-04 | ajuste | ST-09; trilha:1469 | **LSN do evento foi chamado de posição da transação.** Proposta: “op: c indica inserção e r indica leitura de snapshot; source.lsn é a posição da operação no WAL, enquanto source.txId identifica a transação; snapshot: false indica captura ao vivo.” | Conferir a tabela source/op na documentação do Debezium 3.6 vinculada no manifesto. | Texto documental distingue “ID of the transaction” de “Offset of the operation in the database log”. Sem produzir evento. | **Aceito; conferido** na documentação do Debezium 3.6: `lsn` é "Offset of the operation in the database log", e `txId`, "ID of the transaction in which the operation was performed". O glossário repetia o erro na definição de LSN e foi corrigido também. `324cfae`. |
| RT2-05 | ajuste | ST-07:1419; R45:4913; spec_c.py:71 | **“Não uma falha; importa a última linha” excede a evidência.** Proposta: “Neste encerramento, os tracebacks apareceram após Ctrl-C, junto da parada do Prism, compatíveis com o fechamento dos canais. A mesma mensagem durante o processamento exige investigação. Antes de encerrar, confira corte/offset e resultados esperados; depois, ausência de trabalho antes de pausar.” Manter o trecho real sem classificá-lo genericamente como inofensivo. | E7; apache_beam/runners/worker/data_plane.py:762–775; src/mvp_ed1/streaming/cli.py:209–213. | Histórico: ^C, Really destroying service e erros de canal. Código: except Exception registra Failed to read inputs in the data plane.; pipeline interrompido vem de except KeyboardInterrupt, sem validar integridade. | **Aceito; conferido** em `apache_beam/runners/worker/data_plane.py` (a mensagem sai de qualquer exceção de leitura) e em `streaming/cli.py` (a última linha só vem de `KeyboardInterrupt`). O Ctrl-C do R45 pede conferir corte e alertas antes, descreve os *tracebacks* como observados neste encerramento e diz que a mesma mensagem durante o processamento pede investigação; o L6 do resumo, idem. `324cfae`, `9e6f3ac`. |
| RT2-06 | ajuste | Vizinha de ST-04/ST-06:1395; repetição em 4545; contraste com R44:4815–4826 | **STATE Empty não prova ausência de Beam.** O consumidor usa assign explícito, não subscribe/coordenação de membros. Proposta: “Empty indica ausência de membros registrados no protocolo do grupo; neste consumidor com atribuição manual, confira o processo/terminal do Beam para saber se ele está rodando.” | Comparar R44.txt e R44_terminal1.txt (E7) com src/mvp_ed1/streaming/transport.py:185–188, leitor.assign. | R44: STATE Empty, MEMBERS 0 e CURRENT-OFFSET 32551; no primeiro terminal, lote de 250 consumido e pipeline is running antes de ^C. Contraexemplo histórico. | **Aceito; conferido** em `transport.py` (`leitor.assign`) e no R44 (`STATE Empty` e `MEMBERS 0` com o segundo Beam rodando). Corrigidos a anotação da saída de 04/10 no L6, com uma frase sobre o `assign`, e o passo do R40. `324cfae`, `9e6f3ac`. |
| RT2-07 | ajuste | R39:4411–4490; spec_b.py:233–249 | **A limpeza supõe DAG ociosa sem declarar esse requisito.** Pausar não encerra tarefas; delete_dag recusa tarefa running. Exigir sequência de estudo concluída e conferir execuções/tarefas terminais antes de retirar o arquivo. Delimitar “desfaz R33 ao R38”: limpa a DAG de estudo, não R36 em fluxo_batch nem todos os rastros; ficam logs e auditoria. Retirar a garantia de “um ciclo” em sleep 65: descoberta de arquivos tem padrão de 300 s. Indicar PC-9 para devolver os serviços após o grupo. | R39.txt; api/common/delete_dag.py:44–93; config_templates/config.yml:2828–2834. Sem excluir DAG com tarefa ativa. | Registro começa com No unpaused DAGs were found. Código: raise AirflowException("TaskInstances still running"); keep_records_in_log=True preserva Log. Esperar 65 s observa ausência naquele instante, não um ciclo de 300 s. | **Aceito; conferido** em `api/common/delete_dag.py` (`TaskInstances still running`; `keep_records_in_log=True`) e no `refresh_interval` de 300 s. O R39 ganhou a pré-condição na introdução (sequência terminada, nada `running` ou `queued`, conferido na interface), o alcance exato em *Muda estado* (ficam os *logs*, a auditoria e o R36), o `sleep 65` sem a promessa de um ciclo e a remissão ao PC-9. A conferência das execuções ficou como instrução, não como comando: gravar a saída dela exigiria refazer R33–R38. `9e6f3ac`. |
| RT2-08 | ajuste | Metadados de R33:4045 e R44:4736; spec_b.py:171; spec_c.py:49–51 | **Pré-requisitos e efeitos estão incompletos.** R33 despausa DAG que consulta consumption.monthly_revenue_by_channel_and_category: requer armazém com a view, além do Airflow, e cria execuções/logs. R44 consulta o armazém, pode pausar Airbyte e subir transporte/Beam, e avança offsets. Explicitar em De pé/Antes/Muda estado, mantendo a devolução no fim da sequência. | Ler a DAG na trilha:1177–1181, os passos de R44 e R44_subir.txt. | Inspeção: consulta à view; make stream-up, make stream-run, make psql-warehouse e stream-duplicate. A saída publicada do próprio R44 inclui “Airbyte está de pé e ocioso — pausando.” | **Aceito; conferido** na DAG de estudo (conta `consumption.monthly_revenue_by_channel_and_category`) e nos passos do R44. R33: *De pé* com o armazém e as views, *Antes* com o PC-2, *Muda estado* com execuções e *logs*. R44: *De pé* com o armazém, *Antes* com o PC-2, *Muda estado* com o *offset* do grupo e a pausa do Airbyte, se o passo 1 rodar. `9e6f3ac`. |
| RT2-09 | ajuste | R44:4770; spec_c.py:53 | **O digest não cobre todas as colunas da tabela.** Exclui _stream_partition, _stream_offset, _stream_lsn, _stream_from_snapshot e _stream_extracted_at. Proposta: “Contagem, soma e digest das colunas de negócio de todos os eventos; os metadados de entrega _stream_* não entram neste digest.” A prova continua útil, com alcance delimitado. | Comparar DIGEST_EVENTOS em spec_c.py:9–12 com COLUNAS_DO_EVENTO e tabela em sink.py:43–95. | Inspeção: SELECT termina em schema_version, metadata::text; a tabela acrescenta as cinco colunas _stream_*. | **Aceito; conferido**: `DIGEST_EVENTOS` cobre as 17 colunas do evento, e a tabela tem mais cinco `_stream_*` (`sink.py`). O passo do R44 diz o alcance. `9e6f3ac`. |
| RT2-10 | ajuste | R45:4864–4926; spec_c.py:65–72 | **R45 ocupa dois momentos da sequência e muda estado, apesar de declarar “nada”.** A base vem antes de R41, quando o Beam de R42 ainda não existe; a entrada pede esse Beam. Depois há Ctrl-C e stream-pause. Separar a entrada antes de R41 da conclusão após R44, com remissão no início da sequência; declarar o encerramento e condicionar a pausa ao que o grupo iniciou. Manter PC-9 para a retomada. Diferença entre contagens do tópico só representa alertas novos sem perda por retenção no intervalo: registrar seus limites de offset. | Confrontar metadados/ordem com alertas_N0.txt, R45.txt e PC9_fase_c.txt (E7). | Histórico: limites 14/14 antes e 14/26 depois sustentam doze alertas. Ao fim: “streaming pausado — 2 contêineres parados. Retomar: make stream-resume”, incompatível com “Muda estado: nada”. Serviços inicialmente ligados não foram ensaiados. | **Aceito.** A linha de base dos alertas foi para o fim do R40, com a mesma saída de 12/10. O R45 ficou com a conclusão: declara que encerra o Beam e pausa o *streaming*, condiciona a pausa a quem o subiu e diz que a diferença só vale com o início do log igual nas duas leituras (14 nas duas). `9e6f3ac`. |
| RT2-11 | observação | AF-01 e AB-04; trilha:1056,763 | **Distinguir componente de processo e pod de serviço permanente.** Adotar as frases do manifesto: “quatro serviços permanentes” no Airflow e “pods de serviços e tarefas temporárias” no Airbyte. Preserva a explicação didática sem ensinar equivalências falsas. | Ler serviços no compose e a enumeração E5. | Compose inclui inicializador db migrate; a listagem contém airbyte-abctl-bootloader em Completed, ao lado dos serviços em Running. | **Aceito.** As duas frases adotadas, com o `airflow_init` e o `bootloader` nomeados — a lista de 04/10 na própria trilha já mostra o `bootloader` em `Completed`. `324cfae`. |
| RT2-12 (do autor) | ajuste | Seção 11: onze passos em PC-2 a R39 | **Passos marcados "não aparece nada" imprimiam algo**: o `exit` do contêiner e da aba do dbt (`exit`), o `make psql-warehouse` do R08 e do R36 (o cabeçalho do `psql`) e o `airflow dags pause` do R39 (`No unpaused DAGs were found` — um passo da própria validação já tinha pausado a DAG). Achado ao reler o R39 a partir da E7. | `secao11/conferir_sem_saida.py`, nova, contra todas as transcrições | Antes: "34 passos sem saída conferidos; 11 imprimem algo"; depois: "23 passos sem saída conferidos; 0 imprimem algo" (`20261013_roteiros_revisao2/*_sem_saida_*.log`) | **Corrigido**: os onze mostram a saída real da transcrição; o do R39, com o rótulo "apareceu" e a explicação. `9e6f3ac`. |

**Evidências literais e limites**

E1 — base e estado inicial. Ausência de saída indicada explicitamente.

~~~text
$ git rev-parse HEAD
6e1b7e40934a322360fd0e3a8c716470b11c4f16
$ git rev-parse --abbrev-ref HEAD
main
$ git status --short
(sem saída)
$ git diff --stat
(sem saída)
~~~

E2 — cópia do código sem iniciar o contêiner. A primeira tentativa encontrou bloqueio do socket no sandbox; a repetição com permissão da ferramenta concluiu. Versões lidas de arquivos, não de serviços em execução. Saída do rg no __init__.py cortada.

~~~text
$ docker cp mvp_ed1-airflow_scheduler-1:/home/airflow/.local/lib/python3.11/site-packages/airflow /tmp/rt2_airflow_6e1b7e4
(sem saída; código 0)
$ rg -n '__version__' /tmp/rt2_airflow_6e1b7e4/__init__.py
28:__version__ = "3.2.2"
67:    "__version__",
… (cortada)
$ rg -n 'version =|__version__|version:' /tmp/rt2_airflow_6e1b7e4/version.py .venv/lib/python3.11/site-packages/apache_beam/version.py
/tmp/rt2_airflow_6e1b7e4/version.py:21:from airflow import __version__ as version
.venv/lib/python3.11/site-packages/apache_beam/version.py:20:__version__ = '2.76.0'
~~~

E3 — SQL novo, somente leitura; saída literal das duas sessões.

~~~text
$ docker exec -e PGOPTIONS='-c default_transaction_read_only=on' -i mvp_ed1_source_db psql -U mvp_source -d source_db -X -P pager=off -v ON_ERROR_STOP=1 -c 'show transaction_read_only' -c 'show wal_level' -c 'show max_slot_wal_keep_size'
 transaction_read_only 
-----------------------
 on
(1 row)

 wal_level 
-----------
 logical
(1 row)

 max_slot_wal_keep_size 
------------------------
 -1
(1 row)

$ docker exec -e PGOPTIONS='-c default_transaction_read_only=on' -i mvp_ed1_warehouse_db psql -U mvp_warehouse -d warehouse_db -X -P pager=off -v ON_ERROR_STOP=1 -c 'show transaction_read_only' -c "select column_name,data_type from information_schema.columns where table_schema='raw' and table_name='orders' and column_name like '\_airbyte\_%' order by ordinal_position" -c "select distinct _airbyte_meta from raw.orders order by 1 limit 4"
 transaction_read_only 
-----------------------
 on
(1 row)

      column_name       |        data_type         
------------------------+--------------------------
 _airbyte_raw_id        | character varying
 _airbyte_extracted_at  | timestamp with time zone
 _airbyte_meta          | jsonb
 _airbyte_generation_id | bigint
(4 rows)

         _airbyte_meta          
--------------------------------
 {"changes": [], "sync_id": 48}
 {"changes": [], "sync_id": 56}
(2 rows)
~~~

E4 — GETs pela API pública. Autenticação por airbyte.token(), como no auxiliar; nenhum token/segredo impresso. A tentativa no sandbox não obteve credenciais; abaixo está a repetição que alcançou a API. O identificador foi ocultado pelo próprio comando.

~~~bash
PYTHONDONTWRITEBYTECODE=1 data/medicoes/material_estudo/com_credenciais.sh .venv/bin/python - <<'PY'
import json
from mvp_ed1 import airbyte
jwt=airbyte.token()
cid=airbyte.conexao('oltp_para_raw',jwt)
for suffix in ('', '/state'):
    path=f'/connections/{cid}{suffix}'
    try:
        data=airbyte._chamar(path,jwt)
    except airbyte.AirbyteIndisponivel as e:
        print('GET /connections/<id>'+suffix+': '+str(e).split(' em ',1)[0])
        continue
    print('GET /connections/<id>'+suffix+': HTTP 200')
    print('chaves:', ', '.join(sorted(data)))
    def show(x):
        if isinstance(x,dict):
            fields={k:v for k,v in x.items() if k in ('stream_name','stream_namespace','cursor_field','cursor','cursor_record_count')}
            if fields: print(json.dumps(fields,ensure_ascii=False,sort_keys=True))
            for v in x.values(): show(v)
        elif isinstance(x,list):
            for v in x: show(v)
    if suffix: show(data)
PY
~~~

~~~text
GET /connections/<id>: HTTP 200
chaves: configurations, connectionId, createdAt, destinationId, name, namespaceDefinition, nonBreakingSchemaUpdatesBehavior, prefix, schedule, sourceId, status, tags, workspaceId
GET /connections/<id>/state: 403
~~~

E5 — enumeração atual dos pods, somente leitura.

~~~text
$ docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl
NAME                                                 READY   STATUS      RESTARTS        AGE
airbyte-abctl-bootloader                             0/1     Completed   0               17d
airbyte-abctl-cron-866f8d8f9-n9dg8                   1/1     Running     12 (125m ago)   17d
airbyte-abctl-manifest-server-9fbfb7ffc-sb884        1/1     Running     13 (125m ago)   17d
airbyte-abctl-server-844886cb59-rf7t9                1/1     Running     24 (125m ago)   17d
airbyte-abctl-temporal-69495f7b87-xnncq              1/1     Running     12 (125m ago)   17d
airbyte-abctl-worker-77fcb9c6dd-58c7w                1/1     Running     17 (125m ago)   17d
airbyte-abctl-workload-api-server-7fccbb9d7c-hzw2q   1/1     Running     17 (125m ago)   17d
airbyte-abctl-workload-launcher-d7f56c5d6-866hp      1/1     Running     30 (124m ago)   17d
airbyte-db-0                                         1/1     Running     12 (125m ago)   17d
~~~

E6 — leitura dos pares e soma dos lotes históricos, sem importar/executar aplicar.py.

~~~bash
python3 - <<'PY'
from pathlib import Path
import ast
s=Path('CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html').read_text()
for node in ast.parse(Path('data/medicoes/material_estudo/secao11/aplicar.py').read_text()).body:
 if isinstance(node,ast.Assign) and isinstance(node.targets[0],ast.Name) and node.targets[0].id in ('O4','DATA_LOGICA'):
  for i,(old,new) in enumerate(ast.literal_eval(node.value),1):
   print(f'{node.targets[0].id}-{i}: antigo={s.count(old)} novo={s.count(new)} linha={s[:s.index(new)].count(chr(10))+1}')
PY
~~~

~~~text
O4-1: antigo=0 novo=1 linha=1024
O4-2: antigo=0 novo=1 linha=1142
O4-3: antigo=0 novo=1 linha=1340
DATA_LOGICA-1: antigo=0 novo=1 linha=1240
DATA_LOGICA-2: antigo=0 novo=1 linha=1243
DATA_LOGICA-3: antigo=0 novo=1 linha=1678
DATA_LOGICA-4: antigo=0 novo=1 linha=1679
DATA_LOGICA-5: antigo=0 novo=1 linha=1737
~~~

~~~bash
python3 - <<'PY'
from pathlib import Path
import re
p=Path('data/medicoes/material_estudo/20261004_fase_c/20261004T053708Z_producao_medida.log')
s=p.read_text()
a=[tuple(map(int,m)) for m in re.findall(r'lote de (\d+): (\d+) gravados, (\d+) já existiam',s)]
print(p.name)
print('Lotes:',len(a))
print('Total processado:',sum(t[0] for t in a))
print('Gravados:',sum(t[1] for t in a))
print('Já existiam:',sum(t[2] for t in a))
for l in s.splitlines():
 if 'offset reset' in l or 'retomando do offset' in l: print(l)
PY
~~~

~~~text
20261004T053708Z_producao_medida.log
Lotes: 33
Total processado: 15901
Gravados: 2201
Já existiam: 13700
2026-10-04 02:37:12,818 INFO mvp_ed1.streaming.transport: partição 0: retomando do offset 6009
%4|1791092232.840|OFFSET|rdkafka#consumer-3| [thrd:main]: mvp.oltp.inventory_movements [0]: offset reset (at offset 6009 (leader epoch -1), broker 0) to cached BEGINNING offset offset 13700 (leader epoch -1): fetch failed due to requested offset not available on the broker: Broker: Offset out of range
~~~

E7 — **histórico de 12/10**, lido nesta revisão. Comandos dentro dos registros não foram reexecutados. Cortes marcados.

~~~text
$ sed -n '1,145p' data/medicoes/material_estudo/20261012_roteiros_fase_b/R33b.txt
… (cortada)
dag_id           run_id                                state    run_after                  logical_date               start_date                        end_date
estudo_didatica  scheduled__2026-10-12T21:20:00+00:00  running  2026-10-12T21:20:00+00:00  2026-10-12T21:20:00+00:00  2026-10-12T21:29:49.387342+00:00
default@e2739e45aef5:/opt/airflow$ exit
exit
$ 
$ sed -n '1,35p' data/medicoes/material_estudo/20261012_roteiros_fase_b/R35a.txt
… (cortada)
default@e2739e45aef5:/opt/airflow$ airflow dags trigger estudo_didatica --conf '{"falhar": true}'
… (cortada)
2026-10-12T21:32:53.864136Z [info     ] creating dag run               [airflow.serialization.definitions.dag] loc=dag.py:526 logical_date=None partition_key=None run_after=datetime.datetime(2026, 10, 12, 21, 32, 53, 844246, tzinfo=Timezone('UTC')) run_id=manual__2026-10-12T21:32:53.844246+00:00
… (cortada)
$ sed -n '1,22p' data/medicoes/material_estudo/20261012_roteiros_fase_b/R37.txt
… (cortada)
default@e2739e45aef5:/opt/airflow$ airflow tasks states-for-dag-run estudo_didatica manual__2026-10-12T21:37:14.553953+00:00 -o plain
… (cortada)
dag_id           logical_date               task_id                state    start_date                        end_date
estudo_didatica  2026-10-12T21:36:57+00:00  talvez_falhar          success  2026-10-12T21:37:15.636268+00:00  2026-10-12T21:37:16.414203+00:00
… (cortada)
$ cat data/medicoes/material_estudo/20261012_roteiros_fase_b/R39.txt
… (cortada)
No unpaused DAGs were found
… (cortada)
2026-10-12T21:58:50.801067Z [info     ] Deleting Dag: estudo_didatica  [airflow.api.common.delete_dag] loc=delete_dag.py:55
Removed 76 record(s)
… (cortada)
dag_id      | fileloc                                  | owners         | is_paused | bundle_name | bundle_version
============+==========================================+================+===========+=============+===============
fluxo_batch | /opt/mvp_ed1/airflow/dags/fluxo_batch.py | data_custodian | False     | dags-folder | None
… (cortada)
$ cat data/medicoes/material_estudo/20261012_roteiros_fase_c/R44.txt
… (cortada)
 linhas | soma_quantidade |          digest_eventos
--------+-----------------+----------------------------------
  18351 |          700501 | 5bda93595e16231e55031992cbdd1597
(1 row)
… (cortada)
          digest_saldos           | pares
----------------------------------+-------
 aa6fea90ef9d77f22b5708075477fe24 |  2919
(1 row)
… (cortada)
GROUP                  mvp_ed1_beam
COORDINATOR-NODE       0
COORDINATOR-PARTITION  __consumer_offsets/2
STATE                  Empty
BALANCER
MEMBERS                0
TOTAL-LAG              0

TOPIC                         PARTITION  CURRENT-OFFSET  LOG-START-OFFSET  LOG-END-OFFSET  LAG   MEMBER-ID  CLIENT-ID  HOST
mvp.oltp.inventory_movements  0          32551           30051             32551           0
… (cortada)
 linhas | soma_quantidade |          digest_eventos
--------+-----------------+----------------------------------
  18351 |          700501 | 5bda93595e16231e55031992cbdd1597
(1 row)
… (cortada)
          digest_saldos           | pares
----------------------------------+-------
 aa6fea90ef9d77f22b5708075477fe24 |  2919
(1 row)
… (cortada)
$ sed -n '73,79p' data/medicoes/material_estudo/20261012_roteiros_fase_c/R44_terminal1.txt
2026-10-12 20:43:41,514 INFO root: running job-001[job]
2026-10-12 20:43:41,521 INFO apache_beam.runners.portability.portable_runner: Job state changed to RUNNING
2026-10-12 20:43:41,553 INFO mvp_ed1.streaming.transport: partição 0: retomando do offset 32301
2026-10-12 20:44:00,942 INFO mvp_ed1.streaming.sink: lote de 250: 0 gravados, 250 já existiam
2026-10-12 20:44:41,502 INFO PrismRunner: pipeline is running (job='job-001[job]')
^CException in thread wait_until_finish_read:
2026-10-12 20:44:55,577 WARNING apache_beam.utils.subprocess_server: Really destroying service at localhost:60883 with cmd: ('/home/doug/.apache_beam/cache/prism/bin/apache_beam-v2.76.0-prism-linux-amd64', '--job_port', '60883', '--log_level', 'info', '--log_kind', 'json', '--serve_http=false')
$ sed -n '5,12p' data/medicoes/material_estudo/20261012_roteiros_fase_c/alertas_N0.txt
tópico mvp.alerts.inventory_low_stock: 0 alertas
  aberturas (cruzaram o limiar de 25 para baixo): 0
  normalizações (voltaram acima): 0
  correções de evento atrasado: 0
$ docker exec mvp_ed1_redpanda rpk topic describe mvp.alerts.inventory_low_stock -p
PARTITION  LEADER  EPOCH  REPLICAS  LOG-START-OFFSET  HIGH-WATERMARK
0          0       2      [0]       14                14
$ 
$ sed -n '5,8p' data/medicoes/material_estudo/20261012_roteiros_fase_c/R45.txt
tópico mvp.alerts.inventory_low_stock: 12 alertas
  aberturas (cruzaram o limiar de 25 para baixo): 8
  normalizações (voltaram acima): 4
  correções de evento atrasado: 1
$ sed -n '19,21p' data/medicoes/material_estudo/20261012_roteiros_fase_c/R45.txt
$ docker exec mvp_ed1_redpanda rpk topic describe mvp.alerts.inventory_low_stock -p
PARTITION  LEADER  EPOCH  REPLICAS  LOG-START-OFFSET  HIGH-WATERMARK
0          0       3      [0]       14                26
$ sed -n '1,7p' data/medicoes/material_estudo/20261012_roteiros_fase_c/PC9_fase_c.txt
$ cd ~/Projetos/mvp_eng_dados_1
$ make preflight ALVO=trabalho
[preflight] nenhum trabalho em andamento — janela parada.
$ make stream-pause
streaming pausado — 2 contêineres parados. Retomar: make stream-resume
$ make ps
NAME                   STATUS                 PORTS
~~~

Não foram medidos novamente: temporização do Airflow, botões da interface, cancelamento/backfill, criação automática de tópico, ramos condicionais não executados anteriormente, encerramento do Beam ou devolução dos ambientes. O estado do cursor do Airbyte não foi obtido. As sondas de leitura não substituem esses ensaios nem encerram pendências do Owner.

**Resposta do autor — 13/10/2026.** Cada achado foi reproduzido antes de entrar; a coluna *Situação*
diz como e onde. As evidências da resposta ficam em
`data/medicoes/material_estudo/20261013_roteiros_revisao2/`, fora do Git. Lá estão a reprodução do
RT2-01, as leituras do código do Airflow 3.2.2 (copiado do contêiner parado) e do Beam, o ensaio dos
passos de Git num clone descartável e a conferência dos passos "sem saída". O RT2-04 foi conferido na
documentação do Debezium 3.6.

Os dois itens do manifesto que ficaram não verificáveis nesta rodada foram conferidos pelo autor, só
com leitura, e as duas frases estão certas.

AB-02, o estado do cursor, pelo endpoint de leitura da API interna (`POST /api/v1/state/get`):

```text
$ PYTHONDONTWRITEBYTECODE=1 data/medicoes/material_estudo/com_credenciais.sh .venv/bin/python data/medicoes/material_estudo/20261013_roteiros_revisao2/ler_estado_cursor.py
stateType: stream
stream: {'name': 'orders', 'namespace': 'oltp'}
{"cursors": {"updated_at": "2026-09-01T03:00:00.000000Z"}, "state_type": "cursor_based", "stream_name": "", "stream_namespace": "", "version": 3}
```

Só o maior valor do cursor, sem `cursor_record_count`; a minha suspeita não se confirmou.

ST-05, a configuração do Redpanda, lida do contêiner parado:

```text
$ docker cp mvp_ed1_redpanda:/etc/redpanda/redpanda.yaml - | tar -xO | grep -n -E 'developer_mode|auto_create_topics_enabled'
28:    developer_mode: true
29:    auto_create_topics_enabled: true
--- a composição do projeto define o parâmetro?
não (0 ocorrências)
--- o projeto cria tópico em algum lugar?
não
```

Três *commits*, cada um depois do `make check-offline` com código 0: `324cfae` (as trocas no resumo),
`9e6f3ac` (os roteiros) e o que registra esta resposta. Regenerar a trilha a partir de `c531b87`
dá `9e6f3ac` byte a byte. A varredura de segredos achou zero em 28 arquivos, e as duas senhas
digitadas não aparecem em nenhum deles. O Artifact foi republicado na versão 12.

**Não verificado nesta resposta:**
- a conferência visual no Chrome, porque a extensão estava desconectada;
- a conferência das execuções no R39, que ficou como instrução, sem saída gravada;
- os ramos de pular do R44 e o desafio com o disparo pela interface, que continuam como na §16.4.

## 17. Parecer complementar — compreensão do caminho quente (14/10/2026)

**Pedido do Owner:** registrar nesta troca de revisão as sugestões de melhoria da trilha, para
que ele peça ao Claude Code que atue. O pedido nasceu de uma dificuldade concreta: primeiro não
ficou claro o objetivo do passo 2; depois, o Owner esclareceu que precisava compreender **a proposta
do caminho quente inteiro e a função de cada ferramenta**.

**Parecer do Codex:** recomendo os ajustes abaixo. O material tem evidências e roteiros úteis, mas
o percurso consultado exige que o leitor já conecte conceitos que ele está tentando aprender.
A melhoria principal é explicitar a relação **problema de negócio → responsabilidade da ferramenta
→ transformação do dado → evidência observável**. Há também um problema concreto de continuidade
no R10: o retrato do tópico está vazio e a mensagem do passo seguinte vem de outro momento e de
outro movimento. Isso merece tratamento antes dos refinamentos de apresentação.

Esta rodada segue o formato de achados e resposta da
[skill `revisao`](../.claude/skills/revisao/SKILL.md). **É um parecer, não a implementação dos
ajustes, nem aceite do material pelo Owner.** Os pareceres e as respostas das rodadas anteriores
permanecem como histórico. Não foi aberto um `REVISAO.md` concorrente: a troca deste material já
vive neste plano, conforme a §16.

### 17.1 Base, escopo e mapa de revisão

- **Base lida:** `main`, `e3c226c44291b1bdca89ab9d085797ac1aa21f22`.
- **Estado inicial do trabalho:** a única alteração indicada pelo Git era o arquivo novo, ainda
  não rastreado, `CONVERSAS_COM_CHAT/caminho_quente_por_dentro.html`, produzido pelo Codex na conversa
  imediatamente anterior. Esta rodada acrescenta apenas o parecer ao plano.
- **Escopo efetivamente lido:** a jornada quente, R09–R13, trechos do mapa, L6, pergunta 1 e
  glossário; os arquivos de streaming e os modelos SQL necessários para interpretar esse percurso;
  D62/D63; o mecanismo de serviço e injeção do relógio da trilha. **Não é uma revisão integral dos
  50 roteiros, nem uma nova auditoria do pipeline.**
- **Declaração e derivado:** o R10 e o R13 têm declaração em
  `data/medicoes/material_estudo/secao11/spec.py`; o L6/R45 envolve `spec_c.py`; as substituições do
  resumo e sua aplicação estão em `aplicar.py`, no mesmo diretório. Esses auxiliares foram lidos
  nesta máquina e ficam fora do Git. O autor deve atualizar a declaração correspondente e regerar
  o resultado, preservando a cadeia existente; não corrigir apenas o HTML derivado. Sua presença
  em outro clone não é pressuposta.
- **Complemento didático:** a página [Caminho quente por dentro](caminho_quente_por_dentro.html)
  contém um mapa, explicações e simulações que podem ser aproveitados por link. **É uma proposta
  de apoio, também sujeita à revisão do Claude Code**, não uma segunda fonte normativa nem uma
  aprovação da própria entrega pelo Codex. A incorporação à trilha continua sendo uma possibilidade
  mencionada pelo Owner, não uma publicação já efetuada.

As localizações numéricas abaixo se referem à base desta rodada; os IDs HTML são os pontos de
referência preferíveis depois da edição. As fontes normativas continuam sendo os documentos do
projeto, os ADRs e a configuração; não se propõe reescrever ADR aceito nem mudar a arquitetura.

### 17.2 Achados para resposta do Claude Code

`ajuste` indica uma correção ou melhoria recomendada no escopo lido. `observação` indica uma
possibilidade adicional ou uma condição de integração. A coluna *Situação* deve registrar o que
foi aplicado, ou a justificativa para não aplicar, conforme a skill.

| ID | Veredito | Onde | Achado e proposta | Critério de conferência | Situação |
|---|---|---|---|---|---|
| CQ-01 | ajuste | `#jornada-quente`, linhas 657–658; ligação com R09–R13 | **Abrir o percurso com sua pergunta de negócio e seu objetivo de estudo.** A seção passa do livro imutável/CDC diretamente à saída na origem. Antes do primeiro comando, explicar por que o saldo precisa incorporar uma novidade antes do próximo lote, por que o lote continua existindo e o que se pretende demonstrar acompanhando um movimento. Uma analogia curta de avisos durante o dia e livro completo para conferência ajuda a ligar as etapas. | Sem executar comandos, o leitor consegue dizer para que o fluxo existe, qual domínio cobre e por que existem duas chegadas do mesmo movimento. Um link para o complemento pode fornecer a explicação longa; o propósito deve continuar visível na trilha. | Proposto; aguardando resposta do autor. |
| CQ-02 | ajuste | Mapa, tabela de ferramentas e `#l6` | **Explicar responsabilidades e relações entre produtos.** A tabela atual já descreve funções; falta conectá-las à viagem antes de exigir operação. Distinguir PostgreSQL na origem e no destino, Debezium como captura, Kafka Connect como executor/gestor do conector, Redpanda como transporte e retenção, Beam como lógica e DirectRunner/Prism como execução local. Situar produtor, Airbyte, dbt, Airflow, Docker e Make em relação ao fluxo. Para cada peça, bastam entrada, saída, motivo e evidência. | O mapa não apresenta Debezium e Connect como duas capturas consecutivas; não confunde Airflow com o consumidor contínuo; mostra o papel do lote e os destinos de movimento e alerta. O aluno consegue explicar quem captura, transporta, grava, consolida e consulta. | Proposto; aguardando resposta do autor. |
| CQ-03 | ajuste | `#r10`, linhas 2874–2890; `spec.py`, declaração de R10 | **Tornar explícitas as condições de leitura e a troca de exemplo.** O primeiro retrato mostra `LOG-START-OFFSET = HIGH-WATERMARK = 30051`; o passo seguinte pede uma mensagem em `32300`, retirada de um momento posterior. Além disso, R09/R11 seguem o movimento terminado em `b222`, enquanto o JSON do R10 termina em `920c`. Explicar: log vazio não oferece mensagem retida para selecionar; offset expirado exige outro exemplo; inspeção do formato pode usar outro movimento, mas rastreamento ponta a ponta exige a mesma identidade. Separar os caminhos “ler exemplo histórico” e “seguir evento disponível”, com saída clara quando não houver mensagem, sem transformar automaticamente o roteiro de leitura em produção de dados. | Com tópico vazio ou com o evento original expirado, o leitor sabe por que não pode repetir o offset impresso e como encerrar/seguir o roteiro adequado. Não precisa adivinhar que houve produção entre os retratos. Na variante de rastreamento, o mesmo ID aparece na origem, mensagem e destino. Alterações operacionais novas recebem ensaio próprio ou rótulo de não ensaiadas. | Proposto; priorizar antes dos ajustes de apresentação. |
| CQ-04 | ajuste | Quatro paradas de `#jornada-quente`; R09–R12 | **Declarar o que cada parada comprova.** Acrescentar uma frase de objetivo e uma de limite: origem prova registro; tópico prova publicação; raw quente prova gravação; fato e marcas de chegada permitem conferir consolidação e caminhos. Explicar perto do envelope que `op=c` é inserção no banco, `sale_dispatch` é o fato de negócio, `after` é a linha depois da operação, e o comando de inspeção não aciona o Beam nem apaga a mensagem. Distinguir identidade (`movement_id`), sequência do livro (`event_sequence`), posição no WAL (LSN) e posição na partição (offset). | O leitor não conclui “alerta emitido” ao encontrar uma linha no destino, nem “duas vendas” ao ver duas entregas da mesma identidade. Consegue relacionar `_stream_offset` e `_stream_lsn` à mensagem, sem tratá-los como chaves de negócio intercambiáveis. | Proposto; aguardando resposta do autor. |
| CQ-05 | ajuste | Caixa da view, linha 707; `#r12`, `#r13`; SQL da view | **Mostrar a conservação do saldo e os dois pontos de encontro.** Acrescentar exemplo explicitamente didático: fato 100 + complemento −38 = 62; depois da incorporação pelo dbt, fato 62 + complemento 0 = 62. Mostrar que a sincronização do Airbyte não reconstrói sozinha a fato; o dbt também pode absorver o raw quente antes da carga de reconciliação. A linha quente permanece armazenada. Explicar que `quantity_from_batch` significa “já absorvido pela fato”, inclusive se chegou inicialmente pelo streaming, e que a anti-junção compara identidade e origem. | O leitor explica a diferença entre união no staging e complemento na view, sem somar duas vezes nem imaginar exclusão do raw. R13 distingue saldo quente não nulo de existência de eventos quentes: deltas podem se cancelar, e a view filtra os pares abaixo do ponto de reposição. Não interpretar zero nessa consulta como prova automática de ausência de streaming. | Proposto; aguardando resposta do autor. |
| CQ-06 | ajuste | `#l6`, `#g-watermark`, pergunta `#p1`; controles de offset em R10/R44 | **Separar os relógios e os dois usos de “watermark”.** Explicar tempo de evento, registro e processamento com um evento atrasado. Distinguir o `HIGH-WATERMARK` do tópico, uma posição no log, do watermark do Beam, uma estimativa de progresso no tempo de evento. Mostrar a escrita antes do ramo de janelas; a janela de 60 s não é espera obrigatória para gravar cada movimento. Relacionar os 1.200 s à tolerância após o fim da janela no eixo do watermark, não a uma promessa de aceitar qualquer atraso. | O leitor distingue um offset inteiro de um instante, explica por que o dado pode estar gravado antes do alerta e reconhece que a expiração da tolerância do ramo de janelas não apaga o movimento já persistido. Manter hipótese original e configuração vigente com suas procedências, sem alterar o ADR aceito. | Proposto; aguardando resposta do autor. |
| CQ-07 | ajuste | Pergunta `#p1`, L6 e ligação com `#r45` | **Explicar o alerta pela unidade que o código avalia.** O pipeline soma deltas por janela e mantém saldo entre janelas; a travessia é avaliada ao processar painéis, não necessariamente em cada oscilação de cada evento. Explicar abertura/normalização, supressão de painéis apenas de snapshot e marca de correção tardia. Diferenciar o saldo do acumulador e a consulta que incorpora reservas. Os achados D62/D63 já estão no material: aproximar a referência dos pontos em que se descreve o comportamento pretendido, sem apresentá-los como resolvidos. | Uma oscilação compensada dentro do mesmo painel não é prometida como alerta individual. “Destino alcançou o corte” não vira prova de drenagem do alerta. O leitor sabe que não há consumidor automático de reposição no MVP e onde estão as pendências conhecidas. | Proposto; aguardando resposta do autor. |
| CQ-08 | ajuste | `#jornada-quente`, título e caixa da view; `#r13` | **Conectar os retratos de validação sem reescrever sua história.** “~7 segundos” descreve um evento de 04/10 até o carimbo no destino, não uma garantia do fluxo inteiro. A caixa da view diz “não capturado nesta validação”, sobre 04/10, enquanto R13 mostra em 12/10 `474` linhas e `214` com parcela quente não nula. Preservar o registro antigo e acrescentar referência explícita à evidência posterior. Rotular expectativa estrutural separadamente dos números históricos de “deve aparecer”. | As duas datas continuam visíveis; o leitor encontra o R13 como observação posterior e não entende que a parcela quente nunca foi observada. Outra execução pode mudar contagens sem, por isso, falhar. Os 7 s não são apresentados como SLA, média ou latência de alerta. | Proposto; aguardando resposta do autor. |
| CQ-09 | observação | Possível link para `caminho_quente_por_dentro.html`; `estudo/study_clock.py` | **Conferir a integração real antes de anunciar o complemento como parte da trilha.** Preferir link de ida e volta, mantendo a explicação longa em um lugar. O coletor serve apenas caminhos de `git ls-files`, com a lista carregada na inicialização; o HTML novo ainda não rastreado não entra nessa lista. Além disso, o relógio só é injetado quando `relative == TRAIL`, e o complemento não contém o script. Não presumir que linkar passa a contar o tempo de leitura. Se o Owner quiser essa contagem, tratar a extensão explicitamente; não ampliar silenciosamente a auditoria. Conferir também a estratégia dos links na cópia privada do Artifact. | Se incorporado, o destino abre pelo modo de uso escolhido, retorna à seção de origem e respeita o filtro de arquivos do coletor. A página pode continuar independente e sem relógio, desde que isso seja dito. Caso se inclua medição, conferir as seções registradas e o comportamento do contador. Validar a apresentação no navegador: essa inspeção ficou pendente na entrega do complemento. | Condicional à incorporação; decisão e resposta do autor pendentes. |
| CQ-10 | observação | Padrão didático para outras jornadas e laboratórios | **Reaproveitar a estrutura “objetivo → previsão → ação → evidência → explicação”.** O aprendizado não termina ao reproduzir uma saída. Perguntas curtas ajudam: “o que mudou?”, “o que esta saída prova?”, “o que ainda não foi verificado?” e “o que mudaria se a mensagem chegasse outra vez?”. A trilha já tem autoavaliações; fortalecer a ligação delas com o objetivo do bloco. Esta é uma sugestão de padrão, não um diagnóstico de que todos os demais laboratórios estejam deficientes. | Aplicar primeiro ao caminho quente. Uma expansão posterior para outros capítulos deve ser delimitada e revisada, preservando os três níveis de aprendizado e as evidências existentes. | Sugestão para avaliação do autor. |

### 17.3 Evidências desta rodada e sua natureza

**Leitura de arquivos e Git, sem executar roteiros.** As saídas abaixo foram obtidas nesta rodada.
Os valores extraídos do HTML são **evidência histórica publicada**, não novas medições de bancos,
retenção, latência ou alertas.

```text
$ git rev-parse HEAD
e3c226c44291b1bdca89ab9d085797ac1aa21f22
$ git status --short
?? CONVERSAS_COM_CHAT/caminho_quente_por_dentro.html
```

A extração abaixo isola as seções, evitando as imagens embutidas e os dados extensos do diagrama:

```python
from pathlib import Path
import re

s = Path('CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html').read_text()
for name, start, end in [
    ('Jornada', '<h3 id="jornada-quente">', '<h3 id="jornada-scd">'),
    ('R10', '<section class="roteiro" id="r10">', '<section class="roteiro" id="r11">'),
    ('R13', '<section class="roteiro" id="r13">', '<section class="roteiro" id="r14">'),
]:
    block = s[s.index(start):s.index(end)]
    ids = list(dict.fromkeys(re.findall(r'"movement_id":\s*"([0-9a-f-]+)"', block)))
    print(name, 'movement_id no JSON:', ', '.join(ids) or '(não há JSON de movimento)')
    for needle in ['30051             30051', '-o 29603', '-o 32300',
                   '474 |                214', 'não capturado nesta validação']:
        if needle in block:
            print('  trecho presente:', needle)
new = Path('CONVERSAS_COM_CHAT/caminho_quente_por_dentro.html').read_text()
print('Complemento contém script do relógio:',
      'study_clock.js' in new or '/estudo/relogio.js' in new)
```

Executado com `python3` por entrada padrão. Saída literal:

```text
Jornada movement_id no JSON: 19a5f610-86c3-4ca6-bb8a-433c4514b222
  trecho presente: -o 29603
  trecho presente: não capturado nesta validação
R10 movement_id no JSON: 25fe38b8-2957-4c74-beba-12436ac4920c
  trecho presente: 30051             30051
  trecho presente: -o 32300
R13 movement_id no JSON: (não há JSON de movimento)
  trecho presente: 474 |                214
Complemento contém script do relógio: False
```

```text
$ rg -n 'git.*ls-files|relative not in self.allowed|relative == TRAIL|Collector.allowed = tracked_files' CONVERSAS_COM_CHAT/estudo/study_clock.py
417:    out = subprocess.run(["git", "ls-files", "-z"], cwd=REPO, capture_output=True, check=True).stdout
456:        if relative not in self.allowed:  # só arquivo versionado: o .env e o data/ nunca saem daqui
460:        if relative == TRAIL:
497:    Collector.allowed = tracked_files()
```

**Confronto estático adicional, não ensaio do comportamento:**

- `spec.py:203–209` associa a descrição do tópico do R10 a `R40.txt` e a leitura da mensagem a
  `R43b.txt`. São fontes distintas para os dois passos exibidos juntos.
- `spec.py:224–233` contém as consultas e explicações do R13; o próprio roteiro já esclarece,
  adiante, que só aparecem na view pares abaixo do ponto de reposição. CQ-05 propõe antecipar e
  completar essa interpretação, não afirmar ausência total dessa informação.
- `dbt/models/consumption/skus_below_reorder_point.sql:30–74` separa fato e complemento, com
  `NOT EXISTS` por origem e movimento; os cálculos seguintes expõem soma e contagem de eventos
  separadamente. Deltas não nulos e presença de eventos não são a mesma condição.
- `src/mvp_ed1/streaming/pipeline.py:272–305` coloca `GravarDeltas` antes de `JanelaDeEvento`,
  combina deltas por chave e passa o resultado ao acumulador. Os comentários distinguem saldo
  global de estado por janela.
- `streaming/fluxo.yml:32–72` declara janela, tolerância, folga e limiar; os comentários registram
  a procedência da configuração. Nenhum desses valores foi medido de novo nesta rodada.
- `docs/pendencias.md`, D62/D63, registra problemas no saldo e na espera pelo ramo de alertas.
  O parecer usa esse estado documentado; não verificou se mudanças ainda não registradas o alteram.

### 17.4 Limites, premissas e ambiente

**Não verificado:**

- Estado atual dos bancos, conector, tópicos, retenção efetiva, offsets ou pipeline Beam.
- Execução dos casos alternativos sugeridos para o R10; produção de eventos; reconciliação e
  resultados atuais da view ou dos alertas.
- Geração de nova trilha, reprodução byte a byte após os ajustes, variante publicável, publicação
  no Artifact, cópia de comandos ou navegação no navegador.
- Funcionamento do complemento pelo coletor, contagem de tempo fora da trilha principal,
  apresentação responsiva, impressão e uso com leitor de tela. A entrega anterior do complemento
  informou a indisponibilidade da integração de navegador; esta rodada não remove esse limite.
- Compreensão do Owner após a mudança. O relato da dificuldade é real; a eficácia das soluções
  didáticas propostas ainda precisa ser observada no estudo.

**Premissas e escolhas:** a trilha continua como percurso principal, os documentos continuam como
fontes de autoridade e o complemento pode aprofundar sem repetir integralmente suas explicações
dentro dela. A intenção de incorporar por link não foi convertida em publicação ou em autorização
para alterar o método de medição. A generalização de CQ-10 é opcional; os achados se apoiam no
caminho quente lido, não em uma avaliação completa dos outros capítulos.

**Ambiente desta revisão:** leitura de arquivos locais e Git. Não foi necessário iniciar serviço,
subir banco, trocar ambiente ou usar credenciais. Não foi executado `dossie.py --desde`, pois esta
é uma nova rodada no dossiê existente; o `comandos.txt` da skill executaria `make check`, com
reconstrução do dbt, o que não corresponde a este pedido de parecer. Não houve testes do pipeline.

**Onde hesitei:** apenas adicionar um link ao complemento é a alteração mais curta, mas deixa o
R10 com sua descontinuidade operacional. Recomendo corrigir CQ-03 na declaração, manter na trilha
um enquadramento breve e os limites das evidências, e usar o complemento para a explicação longa.
Isso preserva a distinção entre resumo, roteiro executável e aprofundamento conceitual.

### 17.5 Encaminhamento ao autor

Ao atuar a pedido do Owner, responder na coluna *Situação* da §17.2. Priorizar CQ-03 e, em seguida,
o enquadramento e a conexão entre ferramentas e resultados (CQ-01, CQ-02, CQ-04 e CQ-05). CQ-06 a
CQ-08 completam a interpretação de tempo, alerta e evidência. CQ-09 depende de como o Owner quiser
usar o complemento; CQ-10 não amplia por si só o escopo para toda a trilha.

Para alterações na seção gerada, atualizar os declarativos, regerar e conferir os links de ida e
volta e a variante de publicação. Para mudanças só de explicação, conferir contra as fontes
citadas. Novos ramos operacionais exigem validação proporcional ao que mudou; os ramos não
executados permanecem identificados como tais. Não é necessário repetir os 50 roteiros apenas
para acrescentar uma explicação ou um link.

**Resposta do Claude Code:** aguardando atuação solicitada pelo Owner. Nenhum item desta rodada
foi marcado como aplicado, nenhuma pendência do projeto foi encerrada e a trilha não foi alterada
por este parecer.
