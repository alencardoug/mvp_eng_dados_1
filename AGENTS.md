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

Ordens de serviço específicas ficam em [`encaminhamentos/`](encaminhamentos/). São **transitórias**:
cada arquivo é apagado no *commit* que entrega o trabalho dele, e por isso não aparecem no mapa de
documentação do README.

### Leitura e avaliação dos planos atuais

Depois de `CLAUDE.md` e do mapa documental, leia
[`encaminhamentos/README.md`](encaminhamentos/README.md). Ele estabelece a ordem de leitura e
execução dos planos da D31 e da Etapa 10. Os detalhes pertencem a cada encaminhamento; não os
copie para este arquivo.

Ao receber um pedido de **avaliação**, confronte o plano com o código, os ADRs e o estado observado.
Entregue um parecer com viabilidade, lacunas, ajustes propostos e validações ainda não executadas.
Avaliar um plano não significa executar seus comandos de reconstrução ou encerrar suas pendências.
Ao receber um pedido de **execução**, use a autorização já existente na conversa, cumpra os
pré-requisitos e avance no trabalho autorizado; não peça novamente uma decisão já registrada.

Para a avaliação destes dois planos, confira especialmente:

- se as premissas rotuladas como medidas continuam válidas no ambiente atual;
- se os procedimentos distinguem ferramentas existentes de rotinas ainda a implementar;
- se há decisão nova sobre tratamento ou modelagem, indicando a evidência e a proposta concreta
  antes de devolver o ponto ao Owner;
- se cada critério de conclusão tem uma verificação executável, inclusive os efeitos sobre os
  cortes anteriores e os dois caminhos do estoque.

**Limite desta entrega de planejamento:** somente `AGENTS.md`, o índice de encaminhamentos e os
dois planos nele listados. Ela não implementa a D31 ou a Etapa 10, nem altera seus estados nos
documentos permanentes. As lacunas levantadas ficam nos planos para avaliação; a eventual
formalização em pendência/ADR segue `CLAUDE.md` §5 quando esse trabalho for encaminhado.

Ao concluir um encaminhamento, remova também sua entrada no índice e ajuste as referências dos
encaminhamentos restantes para o registro permanente da entrega. A exclusão do arquivo, sozinha,
não é evidência de conclusão.
