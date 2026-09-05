# D31 — a remessa que nasce sem item

> **Estado:** decisão do Owner tomada ao encaminhar este trabalho. **Premissa desta ordem de
> serviço:** a alternativa escolhida é *"corrigir o gerador e re-medir"*, entre as três que a
> [pendência](../docs/pendencias.md) lista. **Se a leitura estiver errada, pare e devolva ao
> Owner** — as outras duas alternativas não geram trabalho de código.

## 1. O achado

**91 das 3.647 remessas não têm item nenhum.** Caixa vazia é estado que a operação real não produz,
e o dado sintético não deveria tê-lo (princípio **P10**).

Todas as 91 estão em pedidos divididos — 14,3% dos 637. A causa está em
`src/mvp_ed1/generator/domains/logistica.py`:

- a guarda que deveria impedir a divisão nesse caso é `len(itens) >= 1`, que é **sempre verdadeira**
  e portanto não guarda nada;
- `_fatia(quantidade, lote, lotes)` devolve `quantidade // 2` ao lote 0. Quando **todo** item do
  pedido tem quantidade 1, o lote 0 recebe zero unidades em todos eles, nenhuma linha de
  `shipment_items` é criada, e a primeira remessa nasce vazia.

Efeito visível hoje: P13 conta 3.141 entregas e `trusted.shipments` diz 3.221. A diferença **não** é
perda do pipeline — é o grão da fato, que é o item, encontrando remessa sem item.

## 2. O que fazer

### 2.1 Corrigir a divisão

Só divida quando os **dois** lotes receberem alguma unidade. A guarda correta depende da soma das
quantidades do pedido, não da contagem de itens — um pedido com três itens de uma unidade cada
continua produzindo lote 0 vazio com a regra atual.

Duas formas defensáveis, e a escolha entre elas é sua:

- **guardar a divisão** — só `lotes = 2` quando algum item tiver quantidade ≥ 2, de modo que
  `quantidade // 2` seja ≥ 1 em pelo menos um deles;
- **repartir por item** quando não houver quantidade para repartir — metade dos itens em cada caixa,
  que é como uma operação real divide um pedido de três unidades avulsas.

A segunda é mais fiel e preserva melhor a proporção declarada `remessa_dividida: 0.22`; a primeira é
menor. Qualquer uma das duas resolve o defeito. **Escreva no código qual foi escolhida e por quê** —
a proporção efetiva de divisão vai mudar, e o comentário de `geracao.yml` precisa dizer isso.

### 2.2 Tornar a regressão impossível

A regra vira **invariante 13** — *toda remessa contém ao menos um item* — em
[`docs/modelo_de_dados.md`](../docs/modelo_de_dados.md) §4, e o teste
`dbt/tests/remessa_leva_ao_menos_um_item.sql` **deixa de ser `warn` e passa a ser erro**: apague o
bloco `{{ config(severity = 'warn') }}` e reescreva o cabeçalho, que hoje explica a severidade pela
pendência aberta.

### 2.3 Fechar a pendência

D31 sai da tabela de pendentes e vira registro de encerramento. É uma transação em vários arquivos,
descrita em `.claude/skills/adr/SKILL.md` §3 — vale para você também:

- [`docs/adr/README.md`](../docs/adr/README.md) — a linha da D31 sai da §3;
- [`docs/pendencias.md`](../docs/pendencias.md) — o contador do cabeçalho volta a zero, a seção 1
  volta a *"Nada pendente"* e a D31 é registrada como encerrada;
- [`README.md`](../README.md) — o contador *"36 aceitos, 1 pendente"* e a linha de *Pendências*.

Confira com `python3 .claude/skills/adr/verificar.py`. **Isto não é um ADR:** é conserto de defeito,
com precedente escrito no repositório (*"corrigir proporção contra a geração real é previsto, não
improviso"*). Não abra ADR para ele — o próximo número livre continua livre.

## 3. A parte cara: re-medir

Regenerar desloca a sequência de aleatoriedade. **O alcance abaixo foi derivado da leitura do
gerador, não medido** — trate como mapa de onde procurar, não como resultado:

| O que muda | Por quê |
|---|---|
| `shipments` | 91 remessas a menos, e o `_eventos` passa a sortear sobre um conjunto diferente |
| `delivery_events` | Gerado a partir das remessas |
| `inventory_movements` | O movimento `sale_dispatch` sai de `shipment_items` e carrega `shipment_code` e o **momento da remessa** — a contagem deve se manter, os carimbos de tempo não |
| `support_tickets`, `ticket_events` | O chamado nasce de uma remessa (`domains/atendimento.py`) |

Por eles, alcança medições registradas nas Etapas 6 a 9. **Meça antes de reescrever**: número que
não mudou não deve ser tocado.

Onde as medições vivem:

- [`docs/capacidade_e_recuperacao.md`](../docs/capacidade_e_recuperacao.md) §2 — volume, tamanho e a
  tabela de tempos da DAG;
- [`docs/streaming.md`](../docs/streaming.md) §7.1 — o que foi medido na Etapa 7;
- [`docs/plano_de_desenvolvimento.md`](../docs/plano_de_desenvolvimento.md) — os critérios com ✓ das
  Etapas 5 a 9;
- [`README.md`](../README.md) — a seção *Status*;
- [`docs/execucao_local.md`](../docs/execucao_local.md) §6 — números citados nas armadilhas.

**Três ADRs citam medições e não podem ser reescritos** ([`CLAUDE.md`](../CLAUDE.md) §6 e a regra 3
do Registro de Decisões): **ADR-0029** (1,74% da receita, 1.734 itens de carrinho), **ADR-0030** e
**ADR-0031** (1.284 falsas divergências). Se algum desses números mudar, **o ADR fica como está** —
ele registra a medição que motivou a decisão no momento em que ela foi tomada. A atualização vai
para o documento onde o número vive hoje, com uma frase dizendo que a regeração o deslocou.

## 4. Como saber que acabou

```bash
make seed-data FORCE=1
make sync-airbyte RESET=1
make dbt-build RESET=1
make test
make dag-run && make dag-status
```

- [ ] `dbt build` sem erro **e sem aviso** — o `remessa_leva_ao_menos_um_item` passa a valer como
      erro e precisa devolver zero;
- [ ] nenhuma remessa sem item, e a contagem de entregas de P13 volta a bater com
      `trusted.shipments`;
- [ ] `make test` verde;
- [ ] DAG verde de ponta a ponta;
- [ ] `python3 .claude/skills/adr/verificar.py` sem problemas;
- [ ] medições re-verificadas e reescritas **só onde mudaram**;
- [ ] este arquivo apagado no mesmo *commit*.

Mensagem sugerida — um assunto, em português, no formato do [`CLAUDE.md`](../CLAUDE.md) §4:

```
fix: impede a remessa que nasce sem item
```

Se a re-medição virar um segundo assunto grande, ela é um segundo *commit* (`docs:`).
