---
name: revisao
description: Prepara a passagem de uma entrega para revisão por outro agente, ou aplica os achados de uma revisão recebida. Use ao terminar um trabalho que outro agente vai revisar, ao receber achados de revisão, ou quando o Owner pedir para passar/fechar uma revisão.
---

# Passar uma entrega para revisão

> Dúvidas de operação do Owner — o que roda sozinho, como reverter, como levar para outro
> projeto — estão em [`como_usar_skill_revisao.md`](como_usar_skill_revisao.md).

Este projeto usa dois agentes: um **gera** e outro **revisa**, com orçamentos de
esforço diferentes. Esta skill existe para que a passagem entre os dois não
dependa da memória de nenhum deles.

## A regra que sustenta tudo

**Afirmação de medição precisa de saída de comando colada.** O que não tem
saída não é medição — é suposição, e vai para a seção das suposições. Isso não
é rigor por gosto: os defeitos mais caros desta base não estavam no código,
estavam em premissas sobre ferramentas — `to_date` do PostgreSQL 16 estourando
onde se supunha leniência, o Airbyte entregando string vazia como nulo, um alvo
do Makefile imprimindo "removido" quando a remoção falhava. Nenhum era
encontrável lendo diff.

## O que o revisor precisa, e o que ele não precisa

**Não precisa** que você redescreva o diff. O `git` já o dá, e uma segunda
descrição diverge do código na primeira alteração.

**Precisa** de quatro coisas que o `git` não dá:

1. onde gastar esforço — o que é declaração e o que é derivado;
2. o que foi de fato executado, com a saída literal;
3. **o que não foi verificado**;
4. que premissas sobre o ambiente você assumiu sem confirmar.

A terceira é a mais valiosa e a que você tem menos vontade de escrever. Se ela
sair vazia, o dossiê está errado — nenhuma entrega verifica tudo.

## Passar

```bash
python3 .claude/skills/revisao/dossie.py --desde origin/main
```

Quando a entrega a revisar **não** for a ponta — porque trabalho posterior já
entrou e não pertence ao escopo —, fixe o topo:

```bash
python3 .claude/skills/revisao/dossie.py --desde <base> --ate <sha da entrega>
```

Ele coleta o que é mecânico — commits, arquivos, e a saída dos comandos
declarados em `comandos.txt` — e deixa marcado com `<<PREENCHER>>` o que só
você sabe. Preencha as quatro marcas:

| Seção | O que entra |
|---|---|
| Mapa de revisão | Quais arquivos são a **declaração** de que os demais nascem |
| Não verificado | Todo caminho que você não exercitou, e todo número que você não mediu |
| Premissas | O que assumiu sobre ferramenta, banco ou serviço sem confirmar nesta entrega |
| Onde hesitei | Decisões que poderiam ter ido para o outro lado, e por que foram para esta |

Depois:

```bash
python3 .claude/skills/revisao/dossie.py --conferir
```

Ele recusa o dossiê com marca pendente ou com verificação falhando. Um comando
que falhou e é esperado falhar precisa de explicação escrita, não de omissão.

**Prefira oráculo a argumento.** Onde der para entregar um número em vez de uma
explicação, entregue o número. O que mais rendeu nesta base foi um manifesto que
permitiu ao teste dizer "encontrou 74 de 74" — ele achou cinco defeitos antes de
existir qualquer modelo. Um revisor confere um oráculo em segundos e discute um
argumento por horas.

## Receber

Os achados voltam na tabela ao fim do `REVISAO.md`, com veredito por linha:
`bloqueante`, `ajuste` ou `observação`.

- **Bloqueante** para antes de qualquer outra coisa.
- **Ajuste** entra na entrega.
- **Observação** vira nota no dono documental do assunto, ou pendência se
  exigir decisão do Owner (`CLAUDE.md` §5).

Preencha a coluna *Situação* de cada achado: o que foi feito, ou por que não.
Achado recusado precisa de motivo — silêncio não conta como resposta.

**Erro em arquivo gerado corrige-se na declaração**, nunca no arquivo. Se o
revisor apontou o derivado, o conserto é a montante e a regeração propaga.

## Fechar

Apague o `REVISAO.md` no *commit* que entrega o que a revisão pediu, e diga na
mensagem o que veio dela. O arquivo é transitório: ele não entra no mapa de
documentação do README, e o histórico dele já está no `git`.

## Em outro projeto

Só `comandos.txt` é específico. Na primeira vez em que a skill rodar num projeto
novo, ela cria o arquivo vazio e avisa — declare ali os comandos de verificação
daquele projeto, um por linha. Sem eles, nada é medido, e o dossiê diz isso em
vez de fingir o contrário.
