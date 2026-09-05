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
