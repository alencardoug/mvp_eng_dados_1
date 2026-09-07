"""O SQL derivado deve refletir o gerador, inclusive sem banco disponível."""

from mvp_ed1.legacy import dbt, schema
from mvp_ed1.legacy.catalogo import carregar


def test_generated_legacy_models_are_current() -> None:
    catalog = carregar()
    limits = schema.limites(catalog.limite_de_texto, catalog.colunas_estreitadas)
    for table in schema.tabelas():
        path = dbt.DESTINO / f"stg_legacy__{table}.sql"
        assert path.read_text(encoding="utf-8") == dbt.modelo(
            catalog, table, catalog.promessas, limits
        ), f"{path}: regenere com make legacy-models"


def test_cleaning_preserves_catalog_order_including_rejections() -> None:
    """Uma regra que rejeita não pode desaparecer do `case` de conversão."""
    catalog = carregar()
    limits = schema.limites(catalog.limite_de_texto, catalog.colunas_estreitadas)
    for table in schema.tabelas():
        for column in schema.colunas(table):
            rules = dbt._aplicaveis(catalog, table, column, catalog.promessas, limits)
            sql = dbt._limpo(column, rules)
            value = dbt._referencia(column)
            cursor = 0
            for rule in rules:
                result = rule.conversao.format(v=value) if rule.conversao is not None else value
                branch = f"when {rule.deteccao.format(v=value)} then {result}"
                position = sql.find(branch, cursor)
                assert position >= cursor, f"{table}.{column}: ramo {rule.codigo} ausente/fora de ordem"
                cursor = position + len(branch)

