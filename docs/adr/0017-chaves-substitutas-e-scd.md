# ADR-0017 — Derivar chaves substitutas por hash e historizar com snapshots

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D25 |

## Contexto

O [Modelo de Dados](../modelo_de_dados.md) §3.2 já declara o comportamento temporal de cada uma das
17 dimensões: **sete são SCD tipo 2** — cliente, produto, categoria, fornecedor, armazém, cupom e
agente de atendimento —, as demais são tipo 1, estáticas ou conformadas. O que falta decidir é o
**mecanismo**: como a chave substituta é gerada e como a historização é implementada.

A chave substituta é o que permite a uma fato apontar para a **versão** correta da dimensão no
momento do evento. Sem ela, SCD tipo 2 não existe: a chave natural não distingue versões.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Hash determinístico + `dbt snapshot`** | Não depende de estado: o mesmo dado gera a mesma chave em qualquer execução, máquina ou fase — alinhado à geração determinística do [ADR-0005](0005-geracao-com-faker-orientada-a-configuracao.md); funciona igual no BigQuery; os `snapshots` já resolvem `valid_from`/`valid_to` e os casos de borda | Chave larga (32 caracteres) em toda fato; o `snapshot` é um mecanismo a mais para entender, com schema de destino próprio |
| Hash + SCD-2 escrito à mão | Controle total e visível sobre fechar a versão anterior e abrir a nova | Código delicado, com casos de borda que os `snapshots` já resolvem: duas mudanças no mesmo dia, reprocessamento, registro que volta a existir. Reimplementar isso é assumir o defeito |
| Sequência / `identity` | Inteiros curtos, *joins* mais rápidos, chave legível na depuração; é a receita Kimball clássica | Depende de estado do banco: um *rebuild* do zero produz chaves diferentes das anteriores, quebrando qualquer referência externa. No BigQuery não há equivalente natural — tensão direta com **P4** |
| Chave natural composta, sem substituta | Menos uma camada de indireção | Inviabiliza SCD-2, engorda as fatos com chaves de texto e contraria o modelo dimensional já documentado |

## Decisão

**Chave substituta = hash determinístico** da chave natural, gerado por
`dbt_utils.generate_surrogate_key`. Nas dimensões SCD tipo 2, o hash inclui o identificador da
versão, de modo que cada versão tem chave própria e estável.

**As sete dimensões SCD tipo 2 são materializadas por `dbt snapshot`**, com estratégia de
comparação por colunas declaradas — não `check_cols='all'`, que transforma qualquer alteração
irrelevante em versão nova.

Cada fato carrega a chave substituta **vigente no instante do evento**, resolvida por *join*
temporal contra `valid_from`/`valid_to` — nunca a chave da versão corrente.

## Consequências

- **Positivas:** reprodutibilidade completa (**P2**) — apagar o armazém e reconstruir produz as
  mesmas chaves; a historização usa mecanismo testado em vez de código próprio; a paridade com o
  BigQuery é direta.
- **Negativas:** os `snapshots` exigem schema de destino próprio, possibilidade já antecipada nas
  consequências do [ADR-0008](0008-schemas-do-armazem.md); a chave de 32 caracteres ocupa mais que
  um inteiro em toda fato, custo irrelevante nesta escala e relevante na nuvem; e o *join* temporal
  é mais caro que o *join* por igualdade — é o preço de a fato ser historicamente correta.
- **Paridade com o GCP:** `generate_surrogate_key` e `dbt snapshot` funcionam sobre BigQuery sem
  alteração. O *join* temporal se beneficia de particionamento por data, ajuste da Etapa 13.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md) §3.2 — o mecanismo por
  dimensão; [Arquitetura](../arquitetura.md) §2 — o schema de destino dos `snapshots`;
  [Qualidade de Dados](../qualidade_de_dados.md) — teste de não sobreposição de vigências.
