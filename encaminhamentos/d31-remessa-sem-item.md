# D31 — revisão final da entrega

> **Estado em 05/09/2026:** correção, reconstrução e revalidação técnica executadas.
> Falta registrar a revisão final e o aceite do Owner, exigidos por `CLAUDE.md` §5/§7.
> A escolha de corrigir já foi autorizada; não a pergunte novamente nem repita a reconstrução
> como se este ainda fosse um plano de implementação.

## Entrega disponível para revisão

- `522a8fc`: gerador corrigido, conservação das quantidades e caixas não vazias; testes dirigidos,
  invariante 13 e cobertura de pedido entregue dividido nos fatores padrão e reduzido.
- `04a824a`: remoção de slots com conferência e erro propagado; reset restrito ao destino quente,
  com autorização explícita, sem `CASCADE` e com verificação transacional.
- `e5ff5ca`: teste dbt de remessa sem item bloqueante.

Os resultados não são duplicados aqui. Leia os donos documentais:

| Evidência | Registro |
|---|---|
| Geração anterior/corrigida, volumes, tamanhos e DAG | [Capacidade §2.7](../docs/capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026) |
| Invariantes, P13 e suíte Python | [Qualidade](../docs/qualidade_de_dados.md) |
| Snapshot, eventos ao vivo, payloads, saldo, duplicatas, alertas e incremental/completo | [Streaming §7.2](../docs/streaming.md#72-revalidação-da-d31) |
| Operação reproduzível da reconstrução | [Execução Local §3.2](../docs/execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming) |
| Estado de aceite e processos ao final | [Pendências — D31](../docs/pendencias.md#d31--a-remessa-que-nasce-sem-item) |

Evidência bruta e salvaguarda da origem anterior em `data/validacoes/d31/`, ignorado pelo Git.
Não são o ponto de recuperação da Etapa 12. Nenhum ADR aceito foi alterado.

## O que falta para encerrar formalmente

1. O Owner revisar o declarativo integralmente e o derivado por amostragem, conforme
   [CLAUDE.md](../CLAUDE.md). A autorização para executar não é registrada como revisão concluída.
2. Registrar o aceite em [Pendências](../docs/pendencias.md), retirar D31 da tabela pendente do
   [índice de ADRs](../docs/adr/README.md) e ajustar os contadores do README e de Pendências.
3. Conferir a transação de índices pela [skill local adr, §3](../.claude/skills/adr/SKILL.md) e
   executar `python3 .claude/skills/adr/verificar.py`. Não criar ADR para este conserto.
4. Remover este arquivo **no commit do encerramento**, retirar sua entrada do [índice](README.md)
   e atualizar o [pré-requisito da Etapa 10](etapa-10-origem-legada.md) com o registro permanente
   de aceite e o commit real. Não inventar hash antes de o commit existir.

A Etapa 10 **não foi iniciada**. Seu plano continua com as lacunas de tratamento/modelagem
identificadas; o aceite da D31 não resolve essas decisões por implicação.
