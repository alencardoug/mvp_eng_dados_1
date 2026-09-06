# ADR-0040 — Rejeitar nulo em campo obrigatório após a limpeza

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 06/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D32 |
| Substitui / é substituída por | Complementa o ADR-0022; não o substitui |

## Contexto

`NULL_DISGUISED` converte um marcador textual em nulo, mas reconhecer a ausência não torna a
ocorrência válida. Na captura 7 do legado, seis das sete injeções desse código atingiram campos
obrigatórios nos modelos SQLAlchemy: `shipments.shipment_code`, `inventory_movements.movement_type`,
`suppliers.is_active`, `products.product_code`, `customers.created_at` e
`customer_contacts.updated_at`. A sétima, `product_variants.color`, era opcional.

A conversão foi confirmada nos sete casos. Faltava declarar a rejeição da ocorrência que continua
inválida depois dela, sem eliminar o achado da conversão nem inventar um valor de negócio.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Rejeitar nulo obrigatório após a limpeza** | Preserva o domínio e a evidência; campo opcional continua corrigível | Amplia o catálogo, os testes e o oráculo; pode ampliar a cascata de rejeições |
| Admitir nulo no destino legado | Preserva mais ocorrências para análise | Relaxa contratos de dimensões e fatos, com consequências por campo nas perguntas de negócio |

Restringir apenas o injetor aos campos opcionais não trataria as capturas já retidas. Usar um
valor padrão inventaria uma equivalência que a conversão atual não declara.

## Decisão

Acrescentar **`NULL_REQUIRED`** ao catálogo para rejeitar a ocorrência cujo campo obrigatório
permaneça nulo após a limpeza. A obrigatoriedade vem dos modelos SQLAlchemy, sem lista duplicada.

Preservar **`NULL_DISGUISED`** como achado de conversão, quando existir, junto do original e do
nulo tratado. A mesma coluna pode ter o achado de valor e o achado posterior de obrigatoriedade.
A ocorrência é contada uma só vez como `rejected`, e seus filhos seguem a cascata do ADR-0038.
Campo opcional continua corrigível; nulo já recebido em campo obrigatório também é inválido,
mesmo sem marcador textual.

O código é derivado da ausência após a limpeza, não uma nova injeção. Não autoriza preencher
valores padrão, enfraquecer `NOT NULL` nem regenerar as origens.

## Consequências

- **Positivas:** conversão e validade da ocorrência deixam de ser confundidas; auditoria conserva
  os dois achados e a reconciliação mantém as três saídas exclusivas.
- **Negativas:** o catálogo passa de 22 para 23 códigos; os testes precisam conferir achados
  derivados e a cascata separadamente das falhas injetadas. O total de rejeitados só será conhecido
  depois da execução, não é inferido das seis ocorrências observadas.
- **Paridade com o GCP:** a mesma verificação `IS NULL` sobre a coluna tratada, com a
  obrigatoriedade gerada da mesma declaração, é executável no BigQuery. Sem componente novo.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md),
  [Qualidade de Dados](../qualidade_de_dados.md), catálogo YAML, oráculo, modelos e metadados de
  auditoria, além dos índices de decisões e pendências.
