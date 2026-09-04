# Imagem do Airflow com o que a DAG precisa importar.
#
# A divisão é deliberada: **a imagem carrega dependência, o volume carrega
# código**. Assim alterar uma DAG ou um modelo dbt não reconstrói imagem, e a
# imagem continua sendo a declaração das versões.
#
# É também a forma que preserva a paridade da Etapa 13: no Cloud Composer as
# dependências entram como pacotes PyPI do ambiente e os DAGs vêm do bucket —
# a mesma separação, com outro mecanismo.

FROM apache/airflow:3.2.2-python3.11

# Versões fixadas nas mesmas do `.venv` do projeto: a DAG que roda no Airflow
# precisa produzir o mesmo resultado que `make dbt-build` produz no terminal.
RUN pip install --no-cache-dir \
        "dbt-core==1.12.3" \
        "dbt-postgres==1.11.0" \
        "SQLAlchemy>=2.0,<3.0" \
        "psycopg[binary]>=3.2,<4.0" \
        "PyYAML>=6.0,<7.0"

# O repositório é montado aqui; `src/` entra no path para que a DAG importe
# `mvp_ed1.airbyte` em vez de reimplementar o cliente.
ENV PYTHONPATH=/opt/mvp_ed1/src \
    DBT_PROFILES_DIR=/opt/mvp_ed1/dbt
