"""Gerador de dados sintéticos da origem transacional (Etapa 4).

O desenho em uma frase: **a declaração diz quanto e de que forma, os modelos
dizem o que existe, e os construtores de domínio dizem o que faz sentido.**

    geracao.yml   proporção, fator, piso e provedor por coluna (ADR-0027)
    models/       colunas, tipos, chaves e enumerações (ADR-0009)
    domains/      causalidade de negócio — as doze invariantes como regra
    engine.py     junta os três e preenche cada linha
    writer.py     escreve por `COPY`, e deixa o banco reprovar o que estiver errado

Uso: `make seed-data` — o contrato completo está em `docs/execucao_local.md`.
"""
