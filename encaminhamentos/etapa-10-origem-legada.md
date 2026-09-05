# Etapa 10 — Corte 6: origem legada

> **Pré-requisito duro: a [D31](d31-remessa-sem-item.md) entregue.** Ela regenera os dados
> sintéticos, e esta etapa é medida contra eles. Construir na ordem inversa obriga a re-medir a
> Etapa 10 inteira depois — inclusive a reconciliação, que é o critério central dela.

## 1. Onde a especificação está

**Não está aqui.** O dono documental desta etapa é
[`docs/origem_legada.md`](../docs/origem_legada.md), e ele já descreve estrutura, catálogo de falhas,
manifesto, *snapshot*, limpeza, empilhamento e reconciliação. Leia-o inteiro antes de começar; este
arquivo só diz o que fazer com ele.

O que também já está decidido, e **não** deve ser reaberto:

| Assunto | Onde |
|---|---|
| Procedência em coluna própria no empilhamento | [ADR-0021](../docs/adr/0021-procedencia-no-empilhamento.md) |
| Catálogo de falhas declarativo como fonte única | [ADR-0022](../docs/adr/0022-catalogo-declarativo-de-falhas-do-legado.md) |
| Modo de sincronização e tratamento de exclusões | [ADR-0015](../docs/adr/0015-sincronizacao-e-exclusoes.md) |
| Escopo do schema `quarantine` | [ADR-0008](../docs/adr/0008-schemas-do-armazem.md) |
| Objetivo, artefatos e critérios da etapa | [Plano](../docs/plano_de_desenvolvimento.md), Etapa 10 |

## 2. O que construir

Os artefatos estão listados no Plano. Em ordem de dependência:

1. **`src/legacy/`** — gerador com *seed* própria, e o **manifesto** que declara o erro esperado de
   cada registro. O catálogo de falhas do ADR-0022 é a fonte: o injetor sai dele, e as regras de
   limpeza e os testes também. Injetar e tratar não podem divergir porque são o mesmo arquivo.
2. **`legacy_db`** — o terceiro banco, com a tipagem frouxa que
   [`docs/origem_legada.md`](../docs/origem_legada.md) §2 descreve. Coluna tipada rejeitaria o dado
   defeituoso antes da limpeza, que é justamente o que se quer exercitar.
3. **Ingestão para `raw_legacy`** — carga `full_refresh` com `snapshot_id`, `snapshot_at` e
   `source_system`. Declare o *stream* em [`airbyte/streams.yml`](../airbyte/streams.yml), que é a
   declaração única do ADR-0015.
4. **Limpeza e classificação** — cada registro sai como `accepted`, `corrected` ou `rejected`, em
   exatamente uma dessas saídas.
5. **Quarentena** — `rejected` vai para `quarantine` com código e motivo. O schema já tem morador
   desde a Etapa 8 (`rejected_shipment_deliveries`), e o padrão de código de rejeição —
   `UPPER_SNAKE`, estável, nunca reaproveitado — já está em uso.
6. **Empilhamento em `trusted`** — só `accepted` e `corrected`, com `source_system` explícito e a
   chave substituta derivada do *hash* de (`source_system`, chave natural), conforme o ADR-0021.

## 3. O que o repositório já resolveu, e você deve reusar

Padrões estabelecidos nas Etapas 8 e 9. Segui-los é mais barato que reinventá-los, e a revisão
espera encontrá-los:

- **Regra em artefato declarativo, nunca em `case` dentro de modelo.** Três *seeds* já fazem isso
  (`order_status_transitions`, `support_categories`, `brazilian_states`), e cada uma tem um `pytest`
  que a confronta com quem produz o dado. O catálogo de falhas do legado é o próximo caso natural.
- **Membro desconhecido contra chave nula.** A macro `chave_desconhecida()` e o critério que separa
  os dois casos estão em [`docs/modelo_de_dados.md`](../docs/modelo_de_dados.md) §3.2: nulo quando a
  ausência é **fato**, membro desconhecido quando é junção que falhou.
- **Camada nova exige tarefa nova na DAG.** [`airflow/dags/fluxo_batch.py`](../airflow/dags/fluxo_batch.py)
  seleciona por camada (`--select <camada>`), não por domínio. A `quarantine` precisou de tarefa
  própria na Etapa 8; `raw_legacy` e a limpeza precisarão do mesmo cuidado.
- **Livro contra projeção.** Onde a origem tiver a mesma informação em coluna corrente e em rastro,
  o rastro é a fonte e a coluna é conferência — ADR-0030 e
  [ADR-0034](../docs/adr/0034-entrega-do-livro-de-eventos.md).

## 4. As duas armadilhas previsíveis

**O manifesto é oráculo, não entrada.** A transformação nunca o consulta para descobrir a resposta.
Se consultar, o teste passa a medir a si mesmo e a etapa inteira perde o sentido. O manifesto entra
**só** no teste, e o teste compara resultado contra ele.

**A reconciliação precisa fechar exatamente**, não aproximadamente:

```text
extracted_rows = accepted_rows + corrected_rows + rejected_rows
stacked_rows   = accepted_rows + corrected_rows
```

E reprocessar o mesmo `snapshot_id` não pode duplicar. Idempotência aqui é a mesma propriedade que o
[ADR-0019](../docs/adr/0019-saldo-em-deltas-com-entrega-idempotente.md) exigiu do *streaming*, e o
projeto já tem um teste do gênero em `dbt/tests/` para copiar a forma.

## 5. Quando parar e devolver ao Owner

[`CLAUDE.md`](../CLAUDE.md) §5 — você não decide o que exige ADR. Casos prováveis nesta etapa:

- uma regra de correção que possa ser lida de mais de um jeito — a orientação escrita é **bloquear o
  empilhamento**, não escolher;
- a origem legada precisar de tabela, coluna ou camada que o ADR-0008 não previu;
- o catálogo de falhas se mostrar incompleto ou contraditório na construção — foi o que aconteceu na
  Etapa 7 com três documentos aceitos que se contradiziam, e a resposta certa foi devolver, não
  escolher em silêncio qual valia.

Registre como pendência `Dnn` em [`docs/adr/README.md`](../docs/adr/README.md) §3 e em
[`docs/pendencias.md`](../docs/pendencias.md), e pare. **A D31 é a numeração mais alta usada.**

## 6. Como saber que acabou

Os critérios são os do [Plano](../docs/plano_de_desenvolvimento.md), e cada um precisa de **número
medido** ao lado do ✓ — é assim que as Etapas 5 a 9 foram fechadas:

- [ ] `extraídos = aceitos + corrigidos + rejeitados` fecha exatamente;
- [ ] o resultado confere com o manifesto, **sem** que a transformação o consulte;
- [ ] `raw_legacy` intacto após a limpeza;
- [ ] rejeitados preservados em quarentena, com código e motivo;
- [ ] reprocessar o mesmo `snapshot_id` não duplica;
- [ ] nenhuma correção silenciosa — toda correção registra origem, resultado e regra aplicada.

E a definição de pronto do [`CLAUDE.md`](../CLAUDE.md) §7 inteira, com atenção a três itens que
costumam ficar para trás: catálogo e dicionário atualizados **na mesma entrega**, campos novos
classificados quanto à sensibilidade, e documentação sem duplicar o que já existe em outro artefato.

Feche a etapa como as anteriores: `docs/plano_de_desenvolvimento.md` (etapa concluída, etapa atual
passa à 11), `README.md` (*Status*), `docs/pendencias.md` (etapa atual) e
`docs/capacidade_e_recuperacao.md` (coluna nova na tabela de tempos da DAG, se ela mudar).

Apague este arquivo no *commit* que entrega a etapa.
