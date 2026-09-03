---
name: adr
description: Registra uma decisão pendente Dnn como ADR aceito e fecha a transação nos índices — adr/README, pendencias.md, README.md e os documentos que a decisão afeta. Use quando o Owner fechar uma decisão, ou quando uma mudança exigir ADR e o trabalho precisar parar.
---

# Registrar uma decisão em ADR

Um ADR é uma **transação em vários arquivos**. Escrever só o arquivo do ADR deixa os índices e os
contadores divergentes — que é o defeito que o princípio **P8** existe para evitar.

## Antes de tudo: quem decide

O Claude Code **não decide o que exige ADR** (`CLAUDE.md` §5). Se você chegou aqui porque topou
com uma escolha de ferramenta, mudança de camada, alteração de modelagem central ou de tratamento
de dados, o procedimento é o inverso deste: **pare**, registre a questão como pendência `Dnn` em
`docs/adr/README.md` §3 e em `docs/pendencias.md`, e devolva ao Owner. Não implemente.

Só siga adiante quando o Owner tiver dito **qual** opção escolheu.

## 1. Reunir

- Qual `Dnn` está sendo resolvida — pode ser mais de uma no mesmo ADR.
- Qual foi a escolha, nas palavras do Owner.
- O próximo número livre: `ls docs/adr/0*.md | tail -1`.

## 2. Escrever o ADR

`docs/adr/NNNN-titulo-em-kebab-case.md`, a partir de
[`0000-template.md`](../../../docs/adr/0000-template.md). Todas as seções são obrigatórias.

**Portão:** sem **Paridade com o GCP** preenchida com um equivalente real, a decisão não passa
(**P4**). Se não houver equivalente, o problema é a decisão, não o documento.

Três regras de conteúdo que valem a pena:

- O **Contexto** registra o que estava errado ou aberto antes — inclusive citando o vocabulário e as
  propostas que foram substituídas. Isso é o ADR fazendo o seu trabalho, não inconsistência.
- As **Alternativas** registram por que as recusadas foram recusadas. Uma linha "Contra" vazia é
  sinal de que a alternativa foi inventada para preencher a tabela.
- As **Consequências negativas** são o que separa um ADR de um anúncio. Se não houver custo aceito,
  provavelmente não havia decisão.

## 3. Fechar a transação

Na mesma entrega, sem exceção:

| Arquivo | O que muda |
|---|---|
| `docs/adr/README.md` | Linha nova em §2; a linha correspondente **sai** de §3 |
| `docs/pendencias.md` | Contadores do cabeçalho; a decisão sai da seção 2 ou 3; se resolveu um `Qn`, ele sai da seção 4 e é registrado na seção 5 |
| `README.md` | Contadores na linha *Registro de Decisões* e na linha *Pendências*; a decisão entra em *Decisões já tomadas*; *Status* revisto |
| Cada documento da lista **"Documentos a atualizar"** do próprio ADR | O conteúdo, mais `Versão` e `Última revisão` no bloco de metadados |

Os contadores de decisões pendentes aparecem em **três lugares** e precisam mover juntos. É o erro
mais fácil de cometer aqui.

Ao editar documento existente, prefira substituição verificada — que falha se o alvo não for único —
em vez de `sed` solto. Um alvo que casa zero ou duas vezes é defeito silencioso.

## 4. Verificar

```bash
python3 .claude/skills/adr/verificar.py
```

Confere links relativos, ADRs citados, decisões resolvidas que ficaram na tabela de pendentes e a
coerência dos contadores. Um ADR que cita vocabulário substituído no Contexto **não** é problema.

## 5. Commit

Um ADR por assunto, mensagem em português:

```
docs: registra ADR-NNNN — <título>
```

Se a entrega fechou mais de uma decisão do mesmo bloco, o assunto pode ser o bloco
(`docs: fecha as decisões da Etapa 1`). Mensagem que precisa de "e" para se descrever são dois
commits.
