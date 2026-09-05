"""Caminho quente do projeto: CDC, transporte e processamento por tempo de evento.

Um domínio só — `inventory_movements` —, por decisão do
[ADR-0006](../../../docs/adr/0006-streaming-de-estoque-com-cdc-e-beam.md). O que
vive aqui é o consumidor e o produtor; a captura é do Debezium e o transporte é
do Redpanda, ambos declarados em `streaming/` na raiz do repositório.
"""
