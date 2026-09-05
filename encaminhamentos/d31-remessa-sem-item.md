# D31 — plano de resolução da remessa sem item

> **Este arquivo é ordem de execução, não pedido de parecer.** O parecer está logo abaixo e foi
> conferido contra o repositório e o ambiente em 05/09/2026 — refazê-lo em vez de trabalhar é a
> falha mais provável desta passagem de bastão. A decisão do Owner já está registrada: **corrigir o
> gerador e re-medir**; não pergunte de novo.
>
> **Estado em 05/09/2026:** correção e reconstrução ainda não executadas.
>
> **Parecer:** tecnicamente viável com a arquitetura atual. A correção é localizada, mas a entrega
> inclui reconstruir o estado dependente, inclusive o streaming, e conferir as medições.
> Este conserto não abre ADR; escolhas novas fora desse escopo seguem `CLAUDE.md` §5.

## 1. Base para a avaliação

Leia [Geração de Dados](../docs/geracao_de_dados.md),
[Modelo de Dados §4](../docs/modelo_de_dados.md#4-invariantes-de-negócio),
[Execução Local](../docs/execucao_local.md),
[Streaming](../docs/streaming.md) e
[Capacidade e Recuperação §3.2](../docs/capacidade_e_recuperacao.md#32-o-cursor-de-cdc-não-está-no-pacote--e-por-quê).
O registro da questão permanece em [Pendências](../docs/pendencias.md) até a entrega validada.

A avaliação de 05/09/2026 fez consultas somente de leitura e geração em memória. São observações
de referência, a conferir novamente antes da execução:

| Verificação | Resultado observado |
|---|---|
| Origem, `oltp.shipments` | 3.647 remessas; 91 sem item |
| Consumo contra `trusted`, mesmo universo de entregues | P13: 3.141; `trusted.shipments where is_delivered`: 3.221 |
| Geração padrão em memória | Reproduziu as 91 vazias: 40 pedidos com uma unidade, 46 com duas e 5 com três |
| Testes Python sem integração | 61 passaram; 3 testes de integração não executados nessa avaliação |
| Livro de estoque | 13.746 movimentos no gerador em memória; 15.946 na origem em operação e em cada caminho de ingestão |

O último contraste importa: regerar a origem não reproduz automaticamente os eventos acrescentados
ao vivo. Não compare uma geração inicial com um cenário de streaming como se fossem a mesma carga.

### Causa confirmada no código

Em [logistica.py](../src/mvp_ed1/generator/domains/logistica.py), a guarda `len(itens) >= 1` é sempre
verdadeira depois do `continue` para pedidos sem itens. A função `_fatia` manda
`quantity // 2` para o primeiro lote; se todas as quantidades forem 1, esse lote recebe zero.

Há dependências além de `shipments`: `shipment_items`, `delivery_events`, movimentos, saldos,
reservas e atendimento. A ordem está em
[pipeline.py](../src/mvp_ed1/generator/pipeline.py). Sorteios de armazém, estado, prazo e ajustes
de estoque também podem mudar. **Não assumir “91 remessas a menos”, contagem de movimentos
constante ou apenas mudança de datas.** O efeito depende da solução e deve ser medido.

## 2. Correção proposta e proteção contra regressão

**Recomendação para avaliação:** manter a divisão por quantidade quando algum item tiver
`quantity >= 2`; quando todos tiverem uma unidade, dividir os itens entre os dois lotes, em ordem
estável. Pedido com uma única unidade fica em uma remessa. Sortear a divisão conforme a
probabilidade declarada e só criar dois lotes quando ambos receberem unidades.

A alternativa menor, já permitida pelo encaminhamento anterior, é dividir somente quando algum
item tiver quantidade pelo menos 2. Se o executor a escolher, registre a justificativa e meça a
proporção efetiva. A preferência deste plano é repartir por item, por fidelidade à operação.

Trabalho de código, na futura execução:

1. Corrigir o construtor de remessas e seu repartidor. Documentar no código a alternativa escolhida.
   Usar identificadores novos em inglês, conforme `CLAUDE.md`.
2. Ajustar o comentário de `remessa_dividida` em
   [geracao.yml](../src/mvp_ed1/generator/geracao.yml): 0,22 é probabilidade configurada, não
   promessa de frequência realizada. Não ajustar o parâmetro ou a tolerância para esconder
   regressão de cobertura.
3. Acrescentar a **invariante 13: toda remessa contém ao menos um item**, no dono documental
   [Modelo de Dados §4](../docs/modelo_de_dados.md#4-invariantes-de-negócio).
4. Tornar [remessa_leva_ao_menos_um_item.sql](../dbt/tests/remessa_leva_ao_menos_um_item.sql)
   bloqueante: remover `config(severity = 'warn')` e atualizar seu cabeçalho.
5. Acrescentar teste da invariante em memória e casos dirigidos que forcem as duas decisões do
   sorteio, sem depender de uma semente “sortuda”.

| Caso de teste dirigido | Garantia esperada na solução recomendada |
|---|---|
| Um item de uma unidade | Uma remessa com uma unidade |
| Dois ou três itens de uma unidade | Duas remessas não vazias quando a divisão for sorteada |
| Um item com quantidade 2 ou 3 | Parcelas positivas cuja soma é a quantidade vendida |
| Itens com quantidades mistas | Nenhuma caixa vazia; soma por item exatamente preservada |
| Divisão não sorteada | Uma remessa com todos os itens e quantidades |
| Mesmo conjunto de parâmetros, nova execução | Conteúdo gravável determinístico |
| Fator padrão e fator reduzido já usado nos testes | Cobertura e invariantes continuam válidas |

**O pedido dividido é premissa de um teste, não só um caso de borda.**
`dbt/tests/pedido_dividido_fecha_na_ultima_remessa.sql` separa os dois conceitos do
[ADR-0033](../docs/adr/0033-entrega-medida-em-dois-graos.md) — entrega no prazo na remessa, ciclo de
entrega no pedido — e ele **passa vazio** se não houver pedido dividido no dado. Hoje há 637.

A alternativa que só divide quando algum item tem quantidade ≥ 2 reduz esse número, e a redução não
foi medida. Meça-a: se a cobertura cair a ponto de o teste ficar sem o que exercitar, o gerador tem
idioma próprio para isso — `min_rows` com `motivo` escrito, usado em sete tabelas de
[`geracao.yml`](../src/mvp_ed1/generator/geracao.yml). Ajustar a probabilidade para maquiar o número
não vale; garantir um piso de cobertura com motivo declarado, sim.

O teste deve comparar o resultado com essas propriedades, sem calcular a expectativa chamando o
próprio repartidor. Executar a suíte existente, incluindo conservação de estoque, causalidade,
quantidades vendidas/enviadas e determinismo.

## 3. Preparação da reconstrução

Antes de alterar o banco:

- registrar revisão Git, configuração, semente, data de corte e contagens/impressões digitais por
  tabela; comparar geração anterior e corrigida em memória com os mesmos parâmetros;
- guardar saídas de medições e logs sem segredos em diretório local ignorado, por exemplo
  `data/validacoes/d31/`; os resultados finais serão publicados nos donos documentais;
- medir separadamente a carga inicial e o cenário com eventos ao vivo; registrar os parâmetros
  do produtor usados na nova validação, sem prometer reproduzir instantes ou UUIDs anteriores;
- identificar os processos e recursos do projeto, verificar serviços, ausência de jobs ativos,
  estado do conector, slot, tópicos e tabela de destino; contêiner saudável não prova ingestão
  completa;
- definir como recuperar a origem anterior se a carga falhar. Se for necessário preservar seu
  estado exato, preparar salvaguarda local identificada antes do truncamento; não substituir nem
  declarar entregue o ponto de recuperação da Etapa 12.

O `writer` atual confirma o truncamento antes de iniciar a transação de carga. Uma falha de
`COPY` não devolve a carga antiga: os testes em memória devem passar antes dessa operação.
`make test CARGA=1` também trunca e carrega um fator reduzido; só o execute em banco de teste
isolado, nunca sobre a base que será usada nas medições finais.

## 4. Reconstruir os dois caminhos, na ordem correta

### Por que a sequência antiga é insuficiente

O [decodificador](../src/mvp_ed1/streaming/envelope.py) rejeita `TRUNCATE`, o
[destino](../src/mvp_ed1/streaming/sink.py) usa `on conflict (movement_id) do nothing`, e o
[staging de estoque](../dbt/models/staging/stg_retail__inventory_movements.sql) prefere o payload
do streaming no encontro com o lote. Uma nova geração pode reutilizar uma chave com outro
conteúdo, ou deixar eventos antigos sem correspondente novo.

`make sync-airbyte RESET=1` não limpa `raw.inventory_movements_stream`.
`make stream-down FORCE=1` remove o transporte e tenta remover o slot, mas **não** limpa essa
tabela nem encerra o Beam/Prism que roda no host.

**E o alvo mente.** A remoção do slot roda com `>/dev/null 2>&1` e o `echo "slot de replicação
removido"` vem depois, incondicional: a mensagem aparece mesmo quando a remoção falha. Num CDC isso
é a pior classe de defeito — o slot que ficou para trás segura WAL indefinidamente, que é
exatamente o desastre descrito no comentário logo acima da linha. **Conserte o alvo** para que ele
só afirme o que aconteceu, e confirme por consulta a `pg_replication_slots`. É `fix:` próprio, e
não precisa esperar o resto da D31.

### Sequência proposta para a execução

Os passos manuais de coordenação devem virar operação reproduzível em código versionado. A rotina
para esvaziar somente o destino do streaming **ainda não existe**; implementá-la no pacote/Makefile,
com alvo exato, confirmação explícita de destruição de estado e verificação posterior. Não
inventar aqui um comando já disponível nem usar SQL avulso como correção definitiva de camada.

1. Impedir execução concorrente da DAG e dos produtores; aguardar jobs já iniciados e encerrar os
   processos Beam/Prism identificados. Guardar o estado operacional a restabelecer ao final.
2. Executar `make stream-down FORCE=1` e conferir que o slot declarado no conector foi removido
   e que o estado anterior de tópicos, offsets e grupos não será retomado.
3. Esvaziar **somente** `raw.inventory_movements_stream` pela rotina versionada. Não atingir
   `legacy_db`, `raw_legacy`, os volumes dos bancos ou outros projetos.
4. Executar `make seed-data FORCE=1` com a configuração validada. Conferir carga, invariantes,
   remessas vazias e medições da origem antes de prosseguir.
5. Executar `make sync-airbyte RESET=1`, esperar sucesso; executar `make stream-up` e
   `make stream-run` em processo acompanhado para refazer o snapshot inicial.
6. Esperar o snapshot terminar e comparar os **conjuntos de chaves e os payloads de negócio**
   da origem, do lote e do streaming. Excluir dessa comparação só metadados próprios do
   transporte. Igualdade de contagens ou flags de chegada não prova igualdade de conteúdo.
7. Executar `make dbt-build RESET=1`: reconstrução conjunta dos snapshots SCD e da fato
   incremental. Guardar o resultado deste build antes que outra tarefa sobrescreva seus artefatos.
8. Reexercitar eventos ao vivo, duplicatas no transporte e alertas com os alvos existentes
   `make stream-produce`, `make stream-duplicate` e `make stream-alerts`. Após cessar a produção,
   esperar o CDC alcançar a origem, sincronizar o Airbyte e reconstruir o dbt para o corte final.
9. Executar `make test` e `make dag-run`; acompanhar a execução disparada até estado terminal,
   conferindo todas as tarefas. `make dag-status` isolado não espera a DAG terminar.
10. Medir tamanhos e tempos, conferir catálogo e restabelecer o estado operacional combinado.
    Se houver falha, preservar a evidência, corrigir e retomar do passo que restabeleça coerência;
    não reabrir o fluxo de consumo sobre uma reconstrução incompleta.

O cenário ao vivo comprova idempotência e funcionamento do alerta; seus resultados não precisam
repetir os números da Etapa 7. Nenhum teste ou controle de imutabilidade deve ser enfraquecido para
permitir a regeração de desenvolvimento.

## 5. Validação e atualização documental

### Evidência necessária para fechar

- [ ] Nenhuma remessa sem item na origem ou em `trusted`; quantidades por item preservadas.
- [ ] Soma de `delivered_count` em P13 igual a `count(*)` de `trusted.shipments where is_delivered`,
      com o mesmo corte e universo; não comparar P13 com todas as remessas.
- [ ] `dbt build` sem erros e sem avisos; invariante 13 retorna zero violações.
- [ ] Origem, lote e streaming com o mesmo conjunto de movimentos e conteúdo de negócio.
- [ ] Saldo reconstruído confere no corte comum; duplicatas não alteram contagem nem saldo;
      alertas exercitados e incremento da fato reconciliado com reconstrução completa.
- [ ] Suíte Python passa, com testes pulados identificados; DAG disparada termina em sucesso.
- [ ] Medições anterior/posterior identificadas e documentação coerente; revisão do declarativo
      e definição de pronto de `CLAUDE.md` satisfeitas.

### Donos dos resultados, na entrega de implementação

| Artefato | O que conferir/atualizar |
|---|---|
| [Capacidade e Recuperação](../docs/capacidade_e_recuperacao.md) §2 | Volume, tamanhos e tempos; distinguir a nova medição das históricas de cada etapa |
| [Streaming](../docs/streaming.md) §7.1 | Cenário medido, reconciliação dos caminhos, duplicatas, saldo e alertas |
| [Qualidade de Dados](../docs/qualidade_de_dados.md) | Referências às invariantes, cobertura e resultados atingidos |
| [Plano de Desenvolvimento](../docs/plano_de_desenvolvimento.md) | Evidências dos cortes afetados, sem converter reconstrução atual em execução histórica |
| [Execução Local](../docs/execucao_local.md) | Procedimento completo de regeração com streaming e armadilhas realmente confirmadas |
| [README](../README.md) | Resumo do estado resultante e referências aos donos dos números |

Não substituir em massa números históricos. Medição que não mudou permanece; a nova que divergir
é registrada com seu contexto. Conferir inconsistências que já existiam antes da D31 para não
atribuir à correção um efeito antigo. Atualizar catálogo/dicionário/linhagem quando afetados, a
partir de suas declarações, sem editar trechos gerados à mão.

**ADRs aceitos permanecem intactos**, inclusive ADR-0029, ADR-0030 e ADR-0031. Se uma medição citada
por eles mudar, registrar o valor vigente e a razão no documento responsável, preservando a
medição que motivou a decisão histórica.

## 6. Encerramento e passagem à Etapa 10

Somente depois dos critérios acima:

1. Retirar D31 das pendentes em [docs/adr/README.md](../docs/adr/README.md).
2. Registrar seu encerramento e ajustar os contadores em
   [docs/pendencias.md](../docs/pendencias.md) e no [README](../README.md). Se surgirem outras
   pendências durante a execução, refletir o total real; não escrever “Nada pendente” por padrão.
3. Conferir o procedimento de índices de
   [adr/SKILL.md](../.claude/skills/adr/SKILL.md) §3, aplicando apenas o fechamento pertinente ao
   conserto, e executar `python3 .claude/skills/adr/verificar.py`.
4. Remover este encaminhamento no commit de entrega, atualizar o [índice](README.md) e trocar o
   link de pré-requisito no [plano da Etapa 10](etapa-10-origem-legada.md) pelo registro permanente.
   Conferir novamente os links após essa remoção.

Mensagem sugerida: `fix: impede a remessa que nasce sem item`. Se a documentação exigir commit
próprio, a D31 só é considerada entregue quando todo o conjunto estiver completo. A Etapa 10
parte dessa base identificada e validada, nunca apenas do teste unitário verde.
