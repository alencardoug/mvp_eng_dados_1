"""Pacote raiz do MVP de engenharia e governança de dados.

Os subpacotes `generator`, `legacy` e `streaming` nascem na Etapa 4, conforme a
organização do repositório fixada no ADR-0012. Tudo é importado a partir daqui,
por caminho absoluto: nenhum executor — Airflow, pytest ou linha de comando —
depende de `PYTHONPATH`.
"""

__version__ = "0.1.0"
