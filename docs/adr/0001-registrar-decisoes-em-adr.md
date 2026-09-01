# ADR-0001 — Registrar decisões de arquitetura em ADR

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — |

## Contexto

O [Termo de Abertura](../../Abertura_de_projeto.md) já exige, na seção *Gestão de Mudanças*, que
toda mudança relevante seja acompanhada de um ADR, e inclui "decisões relevantes registradas em
ADR" entre os critérios de sucesso de governança. Faltava, porém, definir o formato, a numeração e
o ciclo de vida desses registros.

O projeto tem uma característica que torna isso mais importante do que o habitual: a fase local
será **replicada no GCP**. Sem o registro do *porquê* de cada escolha, a replicação vira
reinterpretação — e o princípio **P4** (paridade local ↔ GCP) se perde.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| ADRs em arquivos versionados no repositório | Vivem junto do código; revisáveis por *diff*; formato consagrado | Exige disciplina de manutenção |
| Seção de decisões dentro do Termo de Abertura | Um documento a menos | Faz o Termo crescer indefinidamente e mistura governança com técnica |
| Registro em ferramenta externa (issues, wiki) | Menor atrito para escrever | Fora do versionamento; quebra o princípio **P8** (documentação como fonte de verdade) |

## Decisão

As decisões relevantes do projeto são registradas como arquivos Markdown em `docs/adr/`, um
arquivo por decisão, numerados sequencialmente a partir de `0001`, criados a partir de
[`0000-template.md`](0000-template.md) e indexados em [`README.md`](README.md).

Enquanto uma escolha não está fechada, ela figura como **decisão pendente** (`Dnn`) na tabela de
decisões pendentes do índice — nunca como um ADR vazio.

## Consequências

- **Positivas:** existe um único lugar para "por que decidimos assim"; a arquitetura pode
  descrever apenas o estado atual, sem carregar histórico; decisões pendentes ficam visíveis em
  vez de espalhadas como "a avaliar" pelos documentos.
- **Negativas:** toda decisão relevante passa a exigir um arquivo — atrito deliberado, para que
  escolhas estruturais não sejam feitas por inércia.
- **Paridade com o GCP:** o mesmo registro serve às duas fases; cada ADR declara explicitamente o
  seu equivalente na nuvem.
- **Documentos a atualizar:** nenhum além deste registro e do seu índice.
