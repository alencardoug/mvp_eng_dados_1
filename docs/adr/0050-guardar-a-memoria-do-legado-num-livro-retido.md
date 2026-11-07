# ADR-0050 — Guardar a memória do legado num livro retido, com recuperação registrada

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/11/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — ; decidida de 23/10 a 28/10/2026 como N29 a N35 do [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/c82391a/PLAN.md#12-the-decisions), sobre o [runbook da regeneração](https://github.com/alencardoug/bi-como-codigo/blob/c82391a/docs/regeneration_runbook.md#32-what-stage-15-hands-over) (H6 a H8, T4); o registro em ADR, em 04/11/2026 |
| Substitui / é substituída por | — ; complementa o [ADR-0044](0044-certificar-cada-captura-do-legado-por-conteudo.md): a certificação não muda, mudam os itens 4 (recuperação) e 5 (idempotência da fase 1) |

> **Nota — 07/11/2026.** Na janela da Etapa 13, o *bucket* do livro tem retenção **sem trava**
> (D70, [Pendências §2](../pendencias.md#d69-a-d74--decididas-em-07112026-na-revisão-do-plano-da-etapa-13)):
> travar é irreversível e põe um *lien* que impede apagar o projeto antes do fim da avaliação
> gratuita. A escrita condicionada (`ifGenerationMatch=0`) é exercitada; a retenção travada do mapa
> fica como contrapartida de produção, **não medida**.

## Contexto

A versão de manutenção `v1.1.0` regenera as duas origens e **mantém a memória do armazém**: as
capturas retidas em `raw_legacy`, o certificado de cada uma em `governance.legacy_captures`, a
quarentena e a memória de exclusões. Provar que a memória ficou contida exige compará-la com
registros tirados **antes**, e nenhum existia:

- **o pacote de recuperação não os tem.** O manifesto do formato 2 guarda partição e contagens, não
  o conteúdo do bruto nem as linhas do certificado (RR-06 da revisão do runbook). Contagem igual
  não prova conteúdo igual ([Capacidade e Recuperação §2.7](../capacidade_e_recuperacao.md));
- **a DAG captura e constrói numa execução só.** Um registro tirado depois dela adotaria o que
  mudasse a captura no meio-tempo (RR-22); só a própria DAG põe o registro antes do primeiro
  *build*;
- **a fase 1 finalizava em silêncio.** O item 4 do ADR-0044 manda a próxima execução concluir ou
  abandonar as pendentes antes de abrir a sua, e `captura.iniciar` o fazia chamando `retomar`: a
  transição de uma tentativa anterior acontecia sem registro, antes de a nova existir, e o registro
  só vinha depois do *job* novo (RR-28);
- **uma barreira parcial deixava escapar.** Ler só o que estava devido, ou só o que o registro já
  tinha, deixava passar a tentativa que mudou de estado no meio ou que nunca foi registrada
  (RR-32); uma barreira passada antes da abertura deixava um segundo chamador abrir enquanto o
  registro do primeiro estava devido (RR-37); e um lock só na abertura não impedia um chamador
  atrasado de criar o *job* de uma tentativa já abandonada (RR-39);
- **uma restauração substitui a memória por desenho**, e o registro do estado substituído pararia
  a captura da própria restauração (RR-34).

Por isso o item 5 do ADR-0044 — "as duas fases são *upserts*" — também deixa de valer para a fase 1:
com o id sorteado pelo chamador para tomar o lock antes do *insert*, um id repetido seria um campo
imutável sobrescrito.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Livro em arquivos fora do banco, em épocas, com portões, fase de recuperação e locks** | O registro sobrevive ao que ele audita — restauração, *build*, erro de escrita no armazém; publicação que falha se o nome existe; a decisão de abrir é a barreira, sob lock | Um diretório a montar no Airflow; código de protocolo a manter; a garantia só vale com um chamador vivo por vez |
| Registros numa tabela do schema `governance` | Um lugar só, transacional com o certificado | A restauração troca o armazém inteiro, e o registro iria junto; um *build* ou um erro que escreve em `governance` mudaria o que devia provar que nada mudou |
| Registros só no pacote de recuperação | Já existe, com conferência própria | Não guarda conteúdo do bruto nem linhas do certificado (RR-06), e o ciclo precisa de registros entre dois pacotes |
| Registro tirado pelo operador depois da execução da DAG | Nenhum código na DAG | Adota o que mudou entre a captura e o registro (RR-22) — recusada na N29 |
| Portão só a pedido, ou um *pool* fechado do Airflow com a lacuna declarada | Menos código | O registro deixa de preceder o *build* por construção — recusadas na N29 |
| A recuperação como gancho dentro de `iniciar` | Um ponto de chamada só | Esconde o ponto de controle na função e é mais difícil de provar em todo caminho — recusada na N30 |
| Seguir endurecendo o protocolo contra chamadores simultâneos | Fecharia a limitação | Três rodadas de revisão acharam só agendas concorrentes, cada correção abrindo a seguinte, a um custo de código que o Owner pediu para evitar — recusada na N35 |
| Mover o diretório à mão a cada restauração | Nenhum conceito novo | Divide o alvo da restauração e reconfigura o Airflow a cada vez — recusada na N33, que escolheu as épocas |

## Decisão

A memória do legado é registrada num **livro retido** — um diretório fora do banco e do Git,
nomeado por `LEGACY_LEDGER_DIR`, dividido em **épocas** abertas por uma linha de base —, onde toda
tentativa de captura termina registrada **pelo próprio chamador** antes de qualquer *build*, e
**nenhuma tentativa é finalizada fora de uma fase de recuperação** que registra cada transição e só
deixa abrir a tentativa nova se uma **barreira**, rodada de novo dentro do lock de abertura, achar
o inventário inteiro desde a linha de base registrado e reivindicado.

Os mecanismos, como estão em `mvp_ed1.recovery.ledger` e `mvp_ed1.recovery.capture_recovery`:

1. **Épocas** (N33). A corrente é a mais nova com linha de base válida; as anteriores nunca são
   editadas. Sem época corrente, nenhuma captura começa. `make ledger-baseline` abre a seguinte.
2. **Publicação sem substituição.** Temporário, `fsync`, `link` para o nome final — que falha se ele
   existe —, `fsync` do diretório.
3. **Os portões** (N29, N31). A DAG ganha `registrar_captura_do_legado` entre a conclusão e
   `dbt_seed`, rodando seja qual for o desfecho da conclusão; a CLI registra antes de voltar.
   Repetir só o portão é proibido: fora da primeira tentativa da tarefa ele falha sem escrever.
4. **A fase de recuperação** (N30, N32, N34). Época gravável; as pendentes lidas uma vez e
   registradas; `retomar` restrito a elas, com o registro de transição na hora; a barreira. Uma
   transição cujo registro falhou para o ciclo — a decisão volta ao Owner.
5. **Os locks.** O de abertura, numa chave só, tomado na transação do *insert*; o de cada tentativa,
   de sessão, que morre com o processo: lock tomado é chamador vivo. Antes do `POST` que cria o
   *job*, a tentativa ainda precisa estar `pending` sem *job*.
6. **Um chamador de captura vivo por vez** (N35). Dois juntos são limitação declarada; os locks são
   defesa além dela.

## Consequências

- **Positivas:** a regeneração da `v1.1.0` passa a ter contra o que conferir a memória — o
  certificado por inteiro e, por captura, o conteúdo do bruto em todas as colunas —; nenhum *build*
  corre sobre captura sem registro; uma tentativa interrompida em qualquer ponto é resolvida com
  registro, ou para o ciclo com o motivo; um *job* ou um `sync_id` que nenhuma tentativa explica
  para a captura seguinte em vez de passar.
- **Negativas:** `make sync-legacy` e a DAG **recusam capturar** sem época corrente, e o Airflow não
  sobe sem o diretório montado — uma instalação nova precisa de `make ledger-baseline`, que pede o
  Airbyte de pé e a janela parada. Toda captura relê os `sync_id` das 40 tabelas do bruto, duas
  vezes (na fase e na abertura); a linha de base medida em 04/11/2026 levou 24 s e 677 MB sobre 31
  capturas. A DAG passa de 13 a 15 tarefas. Dois chamadores vivos ao mesmo tempo ficam fora da
  garantia. O livro é estado fora do banco que o pacote de recuperação não leva; quem o perde
  perde a prova, não o dado.
- **Paridade com o GCP:** o livro vira um *bucket* do Cloud Storage, com cada registro criado por
  escrita condicionada a "o objeto não existe" (`ifGenerationMatch=0`) e política de retenção
  travada — o `link` que falha e o "nunca substituído". Os *advisory locks* não têm equivalente no
  BigQuery, onde o certificado vai morar (ADR-0044): ficam no Cloud SQL for PostgreSQL que a fase
  GCP já tem, com a mesma semântica de sessão, e o lock de abertura só é solto depois de o *insert*
  no BigQuery confirmar. **Pendente da Etapa 13**, como o caminho BigQuery do certificado: os
  caminhos GCS e Cloud SQL do módulo nascem com ela.
- **Documentos a atualizar:** [Arquitetura §5](../arquitetura.md#5-mapa-de-paridade-local--gcp)
  (o mapa de paridade); [Origem Legada §4.3](../origem_legada.md#43-o-livro-retido-da-memória-v110)
  (a referência a este ADR); [Execução Local](../execucao_local.md) (metadados; os alvos
  `ledger-baseline` e `ledger-attempt` já entraram com o código).
