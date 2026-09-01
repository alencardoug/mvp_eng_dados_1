# Geração de Dados Sintéticos

> **O que vive aqui:** como os dados nascem — motor de geração, perfis de volume, parâmetros,
> ordem de geração, realismo e o produtor de eventos de estoque.
>
> **O que não vive aqui:** quais tabelas existem e o que significam (ver
> [Modelo de Dados](modelo_de_dados.md)); a origem legada defeituosa (ver
> [Origem Legada](origem_legada.md)); o limite de armazenamento (ver
> [Capacidade e Recuperação](capacidade_e_recuperacao.md)); as regras de privacidade (ver
> [Política de Governança de Dados](governanca_de_dados.md)).

| Campo | Informação |
|---|---|
| Ferramenta | Python + `Faker` ([ADR-0005](adr/0005-geracao-com-faker-orientada-a-configuracao.md)) |
| Perfil de referência | `demo_4gb` |
| Versão | 1.0 |
| Última revisão | 01/09/2026 |

---

## 1. Motor orientado a configuração

O gerador **não** é um conjunto de scripts por tabela. São 40 tabelas na origem principal e mais 40
na legada: escrever e manter 80 geradores manuais seria caro e frágil.

O desenho é o inverso:

1. Um **motor genérico** em Python lê um arquivo de configuração declarativo (JSON ou YAML) que
   descreve a modelagem: tabelas, colunas, tipos, chaves estrangeiras, cardinalidades e regras de
   distribuição.
2. O motor usa o `Faker` dinamicamente conforme o tipo declarado, respeitando a ordem de
   dependência entre tabelas.
3. Regras que o `Faker` não representa — sazonalidade, afinidade produto/categoria/preço,
   disponibilidade de estoque no momento da venda — são implementadas como **provedores próprios**
   registrados no motor.

**Consequência prática:** mudar uma regra de negócio ou acrescentar um domínio é editar
configuração, não milhares de linhas de Python. É também o que torna a revisão humana viável — o
Owner revisa um arquivo declarativo, não código gerado em massa.

---

## 2. Princípios de geração

- Usar `Faker("pt_BR")` onde houver suporte adequado ao cenário brasileiro.
- Aceitar uma `seed` explícita e registrar a semente usada em cada execução.
- Registrar `as_of_date`: a mesma combinação de `seed` e `as_of_date` recria exatamente os mesmos
  dados.
- Separar geração de **entidades**, **eventos** e **estados derivados**.
- Não depender da ordem não determinística de estruturas como conjuntos ou consultas sem
  `ORDER BY`.
- Permitir que o banco seja recriado integralmente a partir das migrações e da configuração.
- Emitir mudanças temporais em lotes reproduzíveis, para que cargas incrementais construam
  históricos SCD sem *snapshot* integral.
- Validar a contagem prevista **antes** de inserir, usar inserção em lotes e interromper expansões
  opcionais quando o limite de armazenamento estiver em risco.

---

## 3. Ordem de geração

A ordem respeita as dependências referenciais e a causalidade dos eventos:

1. **Dados de referência** — canais, categorias, marcas, meios de pagamento e moedas.
2. **Entidades mestres** — clientes, produtos, SKUs, fornecedores, armazéns, transportadoras e
   agentes.
3. **Preços, campanhas e cupons**, com intervalos de vigência.
4. **Ordens de compra, recebimentos e formação do estoque inicial.**
5. **Carrinhos, pedidos e itens.**
6. **Reservas, pagamentos, movimentações de estoque e remessas.**
7. **Eventos de entrega, cancelamentos, devoluções e reembolsos.**
8. **Chamados de atendimento**, vinculados a eventos já existentes.
9. **Mudanças históricas** para cenários SCD, sem *snapshot* integral do banco principal.

---

## 4. Parâmetros e perfis

O gerador é totalmente parametrizado. Perfis previstos: `smoke` (mínimo, para testes rápidos),
`demo` / `demo_4gb` (portfólio) e `scale` (estresse, fora do orçamento local).

Parâmetros gerais:

- `seed`;
- período inicial e final;
- quantidade por entidade principal;
- distribuição de pedidos por cliente e canal;
- probabilidades de abandono, falha, cancelamento, devolução e atraso;
- proporção de alterações cadastrais para SCD;
- moeda e localidade;
- perfil de volume;
- opção de geração de casos inválidos em ambiente isolado de teste.

### 4.1 Perfil `demo_4gb`

Valores iniciais — **limites planejados**, a confrontar com a medição real:

| Parâmetro | Valor inicial |
|---|---:|
| `as_of_date` | `2026-09-01` na versão atual; explícita a cada execução |
| `period_start` | `2024-01-01` |
| `period_end` | `as_of_date` |
| `customer_count` | 15.000 |
| `product_count` | 3.000 |
| `product_variant_count` | 6.000 |
| `supplier_count` | 300 |
| `purchase_order_count` | 4.000 |
| `cart_count` | 400.000 |
| `cart_item_count` | 1.100.000 |
| `cart_item_min_count` | 1.000.001 |
| `order_count` | 35.000 |
| `warehouse_count` | 5 |
| `inventory_movement_seed_count` | 120.000 |
| `inventory_movement_stream_max_count` | 50.000 |
| `stream_events_per_second` | Configurável |
| `stream_seed` | Explícita e independente da `seed` principal |
| `legacy_faulty_row_count` | Aproximadamente 100 |
| `max_persisted_size_bytes` | 4.000.000.000 |
| `size_warning_threshold_bytes` | 3.700.000.000 |

As demais tabelas são dimensionadas por **proporções configuráveis** derivadas dessas entidades
principais — as metas por tabela estão no [Modelo de Dados](modelo_de_dados.md).

Volumes, percentuais e orçamento de bytes devem ser recalibrados após a medição de tempo, largura
real das linhas, índices e capacidade do ambiente local. A documentação sempre distingue **valores
planejados** de **resultados observados** (princípio **P5**).

---

## 5. Realismo e coerência

O `Faker` responde por valores sintáticos — nomes, cidades, textos. A **lógica do domínio** é
responsabilidade da aplicação geradora, que controla:

- sazonalidade e distribuição temporal dos eventos;
- afinidade entre produto, categoria, preço e fornecedor;
- recorrência de clientes e abandono de carrinhos;
- consistência entre endereço, cidade, estado e código postal sintético;
- disponibilidade de estoque no momento da venda;
- divisão de pedidos em mais de uma remessa;
- pagamentos com tentativas e resultados coerentes;
- chamados originados por atraso, falha, cancelamento ou devolução;
- histórico de atributos suficiente para validar dimensões SCD.

O período iniciado em 01/01/2024 se aplica **aos eventos**, não por multiplicação uniforme de todas
as tabelas: cadastros e referências podem atravessar todo o intervalo, enquanto pedidos,
pagamentos, movimentos, entregas e chamados têm distribuição temporal coerente, incluindo
sazonalidade.

Todas as [invariantes de negócio](modelo_de_dados.md#4-invariantes-de-negócio) valem para os dados
gerados: elas são simultaneamente regra de geração e critério de teste.

---

## 6. Produtor de eventos de estoque

O seed principal cria 120.000 movimentos históricos coerentes entre `period_start` e `as_of_date`.
Um **produtor Python separado** acrescenta até 50.000 eventos, alimentando o
[fluxo de streaming](streaming.md).

O produtor:

- gera somente eventos compatíveis com SKU, armazém, compra, venda, devolução ou ajuste existentes;
- mantém uma `stream_seed` própria, para repetibilidade do cenário;
- produz rajadas, intervalos ociosos e taxas configuráveis;
- cria uma quantidade pequena e configurável de **eventos atrasados**, com
  `occurred_at < recorded_at`;
- gera transferências como dois movimentos correlacionados e balanceados;
- usa chaves de idempotência determinísticas;
- persiste cursor e contagem emitida, para permitir retomada;
- respeita um relógio simulado que nunca gera `occurred_at` no futuro;
- encerra de forma controlada ao alcançar 50.000 novos eventos ou o limite de armazenamento — o que
  ocorrer primeiro.

**Duplicatas são simuladas no transporte ou no consumidor**, reutilizando a mesma
`idempotency_key` — nunca por registros duplicados na tabela de origem. Assim a fonte permanece
íntegra enquanto o pipeline demonstra deduplicação e reprocessamento.

### 6.1 Convivência entre carga histórica e streaming

A carga histórica inicial ocorre **antes** da ativação do streaming. O processo registra o último
`event_sequence` e o cursor de CDC, e o consumidor inicia a partir do próximo evento.

Sobreposições entre *backfill* e streaming são toleradas por deduplicação de `movement_id` e
`idempotency_key` — mas nunca podem criar duas linhas na fato para o mesmo movimento.

Com o streaming ativo, o Airbyte **não** grava os mesmos movimentos novamente no destino de
consumo. Pode executar reconciliação periódica em área separada para identificar lacunas,
permanecendo o streaming como caminho oficial de ingestão incremental dessa tabela.

---

## 7. Privacidade dos dados sintéticos

Mesmo sintéticos, campos que representam nome, endereço, telefone e e-mail são classificados
conforme a sua natureza, para demonstrar governança por desenho. As regras de classificação estão
na [Política de Governança de Dados](governanca_de_dados.md); os controles que cabem ao gerador
são:

- usar domínios reservados, como `example.com`, nos e-mails;
- não gerar números de cartão, contas ou credenciais utilizáveis;
- usar tokens opacos e claramente sintéticos em integrações simuladas;
- evitar documentos nacionais válidos que possam coincidir com pessoas reais;
- não copiar amostras de bases externas;
- incluir metadados de execução que comprovem a origem sintética;
- manter segredos e configurações locais fora do versionamento.
