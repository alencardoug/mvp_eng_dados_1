# ADR-0015 — Fixar o critério de sincronização e o tratamento de exclusões

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D20, D21 |

## Contexto

O Airbyte precisa de um modo de sincronização por tabela, e as 40 tabelas transacionais não têm a
mesma natureza: há tabelas de evento que só crescem, tabelas mutáveis com `updated_at`, e tabelas
de domínio praticamente estáticas.

As duas decisões andam juntas porque **exclusão e modo de sincronização se condicionam**: com carga
completa, um registro apagado na origem simplesmente não aparece no próximo *snapshot* e pode ser
detectado; com carga incremental, ele não aparece porque não mudou — e some sem deixar rastro. A
regra 4 do [`CLAUDE.md`](../../CLAUDE.md) proíbe descarte silencioso, e a reconciliação de contagens
entre camadas é critério de sucesso técnico do [Termo](../../Abertura_de_projeto.md) §6.

O [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md) retirou a pressão de volume: carga
completa em tudo seria viável localmente. A escolha, portanto, não é de desempenho — é de qual
padrão o projeto exercita (**P10**).

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Critério declarado por tabela** | Uma regra escrita uma vez e aplicada às 40; exercita incremental e carga completa no mesmo pipeline; o critério cabe numa tabela revisável e continua válido quando o volume crescer no GCP | Duas classes de tabela para manter, e a classificação de cada uma precisa ser conferida |
| Carga completa em tudo | Elimina uma classe inteira de defeito — cursor atrasado, registro perdido, atualização tardia; máxima robustez com o volume atual | Não exercita cursor nem *dedup + history*, e a passagem para a nuvem — onde carga completa não escala — vira trabalho novo em vez de replicação, contra **P4** |
| Incremental sempre que houver `updated_at` | Cobertura máxima do padrão que a nuvem exigirá | *Overhead* conceitual em tabela de três linhas; e um cursor mal configurado passa despercebido em volume baixo, que é exatamente o defeito que só aparece em produção |
| Incremental só nas tabelas de evento | Concentra o padrão onde ele é naturalmente correto — *append-only*, sem `UPDATE` | Deixa de fora o caso instrutivo e difícil, que é incremental com atualização (*dedup + history*) |

| Exclusões | A favor | Contra |
|---|---|---|
| **Soft delete na origem transacional, hard delete na legada** | Cada mecanismo fica onde é verossímil: o sistema bem-comportado marca `deleted_at` e o incremental propaga; o legado apaga de verdade, e a reconciliação o pega. Exercita os dois tratamentos | Duas rotinas de tratamento e um teste a mais por camada |
| Soft delete em ambas | Determinístico e simples; não depende de detectar ausência | Some com o cenário mais comum em sistemas legados reais, que é apagar sem avisar |
| Hard delete em ambas, com anti-*join* | Realista em toda parte | Só funciona com carga completa, o que amarraria **D20** à opção que ela recusou |
| *Append-only*, sem tratar exclusão | O mais barato; defensável em fato transacional, onde venda não some — vira estorno | Quebra a reconciliação de contagens, que é critério de sucesso do Termo |

## Decisão

**Sincronização por critério declarado.** Cada tabela recebe um modo em arquivo de configuração
versionado, segundo a regra:

| Condição da tabela | Modo |
|---|---|
| Tabela de evento (*append-only*) | Incremental, `append` |
| Tem `updated_at` confiável e sofre `UPDATE` | Incremental, `dedup + history` |
| Estável, pequena, sem cursor confiável | Carga completa |

**Exclusões, por origem.** A origem transacional pratica *soft delete*: nada é apagado
fisicamente, `deleted_at` é preenchido e o incremental o propaga até o datamart. A
[origem legada](../origem_legada.md) pratica *hard delete*, e a ausência é detectada por
reconciliação contra o *snapshot* anterior — que é possível porque o `raw_legacy` é imutável e
retido ([ADR-0008](0008-schemas-do-armazem.md)).

Em ambos os casos vale a regra 4 do `CLAUDE.md`: registro que desaparece sem explicação é
divergência de reconciliação, não resultado.

## Consequências

- **Positivas:** o critério é um artefato declarativo, revisável de uma vez, e não 40 decisões
  individuais; os dois padrões de exclusão ficam exercitados e testados; a reconciliação passa a ter
  o que verificar em vez de ser formalidade.
- **Negativas:** a origem transacional passa a carregar `deleted_at` em toda tabela mutável, e todo
  modelo de `staging` precisa filtrá-la — uma coluna e um filtro que existem apenas por causa desta
  decisão. Esquecer o filtro em um modelo produz erro silencioso, o que exige teste estrutural.
- **Paridade com o GCP:** o Datastream oferece os mesmos dois modos e propaga exclusão como coluna
  de metadado; o critério por tabela é reexpresso, mas não repensado.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §3 (ingestão);
  [Modelo de Dados](../modelo_de_dados.md) §2 — `deleted_at` nas tabelas mutáveis;
  [Qualidade de Dados](../qualidade_de_dados.md) — testes de reconciliação de exclusão;
  [Origem Legada](../origem_legada.md) §4.
