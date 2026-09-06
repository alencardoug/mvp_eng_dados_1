# Instruções para agentes neste repositório

As convenções deste projeto — idioma, nomenclatura, formato de *commit*, o que exige ADR e a
definição de pronto — estão em **[`CLAUDE.md`](CLAUDE.md)**, e valem para qualquer agente, não só
para o Claude Code. **Leia-o antes de escrever a primeira linha.** Elas não são repetidas aqui: a
regra do projeto é que cada assunto tem um dono documental, e duplicar é defeito.

O mapa dos documentos está no [README](README.md). O que está parado esperando o Owner está em
[`docs/pendencias.md`](docs/pendencias.md).

## Três coisas que costumam ser descobertas tarde

1. **Você não decide o que exige ADR** (`CLAUDE.md` §5). Escolha de ferramenta, mudança de camada,
   alteração de modelagem central ou de tratamento de dados são do Owner. Na dúvida, registre como
   pendência e devolva — não implemente.
2. **Não invente número.** Métrica, volume ou resultado que não foi medido é marcado como pendente
   (princípio **P5**). "Planejado" e "medido" são rótulos diferentes e nunca se misturam.
3. **ADR aceito nunca é reescrito.** Se uma medição citada dentro de um ADR mudar, o ADR fica como
   está e a mudança é registrada onde o número vive hoje.

## Trabalho encaminhado

Ordens de serviço específicas, **quando houver**, ficam em `encaminhamentos/`. São transitórias:
cada arquivo é apagado no *commit* que entrega o trabalho dele, e o diretório deixa de existir
quando nada está encaminhado — que é o estado atual. Por isso não aparecem no mapa de documentação
do README.

### Passagem entre agentes

Este projeto é trabalhado por **dois** agentes com orçamentos de esforço
diferentes: um gera, outro revisa. A passagem entre eles não depende da memória
de nenhum dos dois — ela tem skill própria, `revisao`.

Quem **entrega** roda `python3 .claude/skills/revisao/dossie.py --desde <ref>`,
preenche as seções que só o autor sabe e confere com `--conferir`. Quem
**revisa** lê o `REVISAO.md` na raiz e escreve os achados na tabela ao fim dele,
com veredito por linha.

Duas coisas que a skill impõe, e que valem repetir aqui:

* **afirmação de medição precisa de saída de comando colada.** O que não tem
  saída não é medição, e vai para a seção das suposições;
* a seção **"o que não foi verificado"** não sai vazia. Nenhuma entrega
  verifica tudo, e um dossiê que afirma o contrário está errado.

### Quando um encaminhamento existir

Ao receber um pedido de **avaliação**, confronte o plano com o código, os ADRs e o estado
observado. Entregue um parecer com viabilidade, lacunas, ajustes propostos e validações ainda não
executadas. Avaliar um plano não significa executar seus comandos nem encerrar suas pendências.

Ao receber um pedido de **execução**, use a autorização já existente na conversa, cumpra os
pré-requisitos e avance; não peça de novo uma decisão já registrada. Uma autorização para executar
também não é aceite da implementação: distinga validação técnica, revisão do declarativo e
encerramento formal, conforme `CLAUDE.md` §5 e §7.

Ao concluir um encaminhamento, remova o arquivo **e** a sua entrada no índice, e aponte as
referências restantes para o registro permanente da entrega. A exclusão do arquivo, sozinha, não é
evidência de conclusão.
