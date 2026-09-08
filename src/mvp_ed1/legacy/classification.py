"""Classificação por ocorrência a partir do catálogo e das relações declaradas.

O SQL não lê manifesto. As chaves, obrigatoriedades e FKs vêm do SQLAlchemy;
o catálogo fornece códigos, ações e motivos. A cascata percorre as referências
até um ponto fixo, incluindo a autorreferência das categorias.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from sqlalchemy import Boolean, UniqueConstraint
import yaml

from mvp_ed1.legacy import schema
from mvp_ed1.legacy.catalogo import Catalogo
from mvp_ed1.models import Base

ROOT = Path("dbt/models")
HEADER = "-- Gerado por make legacy-models; altere legacy/classification.py ou classification.sql.\n"


def sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def json_literal(value: object) -> str:
    return sql_literal(json.dumps(value, ensure_ascii=False, sort_keys=True)) + "::jsonb"


def table_contract(table_name: str) -> dict:
    table = Base.metadata.tables[f"oltp.{table_name}"]
    available = set(schema.colunas(table_name))
    keys = {tuple(column.name for column in table.primary_key.columns)}
    keys.update(tuple(c.name for c in item.columns) for item in table.constraints
                if isinstance(item, UniqueConstraint))
    unique_keys = [{"columns": list(key), "conditions": []} for key in sorted(keys)
                   if key and set(key) <= available]
    for index in sorted(table.indexes, key=lambda i: i.name):
        if not index.unique:
            continue
        conditions = []
        predicate = index.dialect_options["postgresql"].get("where")
        if predicate is not None:
            # A gramática restrita cobre os índices declarados. Índice novo
            # fora dela falha na geração, nunca vira unicidade incondicional.
            for clause in str(predicate).split(" and "):
                match = re.fullmatch(r"([a-z_]+)( is (?:not )?null)?", clause)
                if not match or match[1] not in available:
                    raise ValueError(f"predicado de índice não suportado: {index.name}")
                column, suffix = match.groups()
                if suffix is None and not isinstance(table.c[column].type, Boolean):
                    raise ValueError(f"predicado não booleano: {index.name}.{column}")
                conditions.append({"column": column, "kind": (suffix or " is true").strip().replace(" ", "_")})
        unique_keys.append({"columns": [c.name for c in index.columns], "conditions": conditions})
    return {
        "required": [c.name for c in table.columns if c.name in available and not c.nullable],
        "unique_keys": unique_keys,
        "references": [
            {"column": column.name, "table": fk.column.table.name, "key": fk.column.name}
            for column in table.columns for fk in sorted(column.foreign_keys, key=lambda f: f.target_fullname)
        ],
    }


def records_sql() -> str:
    parts = []
    for table in schema.tabelas():
        payload = ", ".join(f"'{column}', r.\"{column}\"" for column in schema.colunas(table))
        parts.append(f"""select '{table}'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object({payload}) as cleaned_payload,
    r.achados as value_findings, {json_literal(table_contract(table))} as record_contract
from {{{{ ref('stg_legacy__{table}') }}}} r""")
    return HEADER + "\nunion all\n".join(parts) + "\n"


def guarda_de_parametros(parametros: dict[str, str] | None) -> str:
    """Recusa a compilação quando a execução não usa a configuração da impressão.

    Foi o R24. A impressão digital é gravada como **literal** no modelo, no
    instante da geração; `--vars as_of_date=…`, ou uma edição do
    `dbt_project.yml` sem regerar, mudam o tratamento e preservam a impressão.
    Medido: para `placed_at = 2026-09-02`, o corte 01/09 devolve `DATE_FUTURE` e
    o corte 03/09 não devolve achado nenhum — sob o mesmo hash. Dois resultados
    diferentes com a mesma identidade é o que a D34 existe para impedir.

    Vincular a impressão à configuração efetiva exigiria hashear em tempo de
    execução, o que o SQL não faz. A outra saída que o parecer aponta é esta:
    **recusar a divergência**. A guarda é Jinja e roda na compilação, que é onde
    `--vars` já foi resolvido — divergência não vira aviso, vira build recusado,
    antes de qualquer linha ser escrita.

    Fora da geração o marcador continua no lugar: a impressão digital hasheia
    este texto, e ela não pode depender de si mesma.
    """
    if parametros is None:
        return "-- __pendente__ — a guarda de parâmetros é preenchida na geração."
    return f"""{{%- set parametros_da_impressao = {parametros!r} %}}
{{%- for nome, gravado in parametros_da_impressao.items() %}}
{{%- set efetivo = var(nome, '<ausente>') | string %}}
{{%- if efetivo != gravado %}}
{{{{ exceptions.raise_compiler_error(
    "Configuração e artefato divergem: nesta execução " ~ nome ~ " vale " ~ efetivo ~
    ", mas a impressão digital deste modelo foi gerada com " ~ nome ~ "=" ~ gravado ~
    ". Rode `make legacy-models` para regerar, ou retire o --vars. D34: a mesma"
    " identidade de tratamento não pode cobrir dois resultados.") }}}}
{{%- endif %}}
{{%- endfor %}}"""


def classification_sql(
    catalog: Catalogo,
    relation: str = "{{ ref('legacy_records') }}",
    fingerprint: str = "__pendente__",
    parametros: dict[str, str] | None = None,
) -> str:
    rules = ",\n".join(
        f"({sql_literal(f.codigo)}, {sql_literal('correct' if f.converte else 'reject')}, "
        f"{sql_literal(f.conversao if f.converte else f.rejeicao)})"
        for f in catalog.falhas.values()
    )
    template = Path(__file__).with_name("classification.sql").read_text(encoding="utf-8")
    return HEADER + template.replace("__RECORDS__", relation).replace("__RULES__", rules).replace(
        "__VERSION__", str(catalog.versao)
    ).replace("__TOLERANCE__", str(catalog.falhas["TOTAL_MISMATCH"].tolerance)).replace(
        "__FINGERPRINT__", sql_literal(fingerprint)
    ).replace("__PARAMETROS__", guarda_de_parametros(parametros))


def generate(
    catalog: Catalogo,
    root: Path = ROOT,
    fingerprint: str = "__pendente__",
    parametros: dict[str, str] | None = None,
) -> list[Path]:
    outputs = {
        root / "trusted/legacy/legacy_records.sql": records_sql(),
        root / "trusted/legacy/legacy_classifications.sql": classification_sql(
            catalog, fingerprint=fingerprint, parametros=parametros
        ),
    }
    outputs.update(metadata_files(root))
    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return list(outputs)


def metadata_files(root: Path) -> dict[Path, str]:
    """Metadados derivados junto com o SQL; payload misto inclui dados pessoais."""
    def column(name, description, sensitivity="internal", tests=None):
        value = {"name": str(name), "description": description, "meta": {"sensitivity": sensitivity}}
        if tests:
            value["data_tests"] = tests
        return value

    def common_columns():
        return [
            column("source_system", "Sistema que criou o registro; caminho de ingestão não é origem.",
                   tests=["not_null", {"accepted_values": {"arguments": {"values": ["legacy"]}}}]),
            column("snapshot_id", "Identidade da captura no Airbyte.", tests=["not_null"]),
            column("snapshot_at", "Instante de extração da ocorrência, com fuso.", tests=["not_null"]),
            column("legacy_row_id", "Identidade física na tabela e captura.", tests=["not_null"]),
            column("original_payload", "Valores de negócio recebidos, sem alteração; pode conter dados pessoais sintéticos.", "personal"),
        ]

    def classified_columns():
        return common_columns() + [
            column("source_table", "Tabela de origem da ocorrência.", tests=["not_null"]),
            column("catalog_version", "Versão do contrato de tratamento aplicado.", tests=["not_null"]),
            column("treatment_fingerprint",
                   "Identidade do tratamento que produziu esta linha, derivada do SQL gerado (D34).",
                   tests=["not_null"]),
            column("cleaned_payload", "Valores após conversão; inválidos preservados, nunca preenchidos por adivinhação.", "personal"),
            column("classification", "Saída exclusiva da ocorrência, depois de todos os achados.", tests=["not_null", {
                "accepted_values": {"arguments": {"values": ["accepted", "corrected", "rejected"]}}
            }]),
            column("rejection_origin", "Categoria exclusiva: defeito próprio, excedente ou cascata.", tests=[{
                "accepted_values": {"arguments": {"values": ["own_invalid", "duplicate_excess", "parent_rejected"]}}
            }]),
            column("findings", "Todos os achados, ações, motivos, valores e vínculos causais. Pode conter dados pessoais sintéticos.", "personal"),
        ]

    def model(name, description, columns, identity):
        return {"name": name, "description": description,
                "meta": {"domain": "legado", "owner": "data_custodian"}, "columns": columns,
                "data_tests": [{"dbt_utils.unique_combination_of_columns": {
                    "arguments": {"combination_of_columns": identity}}}]}

    staging = []
    for table in schema.tabelas():
        metadata = Base.metadata.tables[f"oltp.{table}"]
        columns = common_columns() + [column(c, metadata.c[c].info["description"], metadata.c[c].info["sensitivity"])
                                       for c in schema.colunas(table)]
        columns.append(column("achados", "Primeiro código de valor detectado por coluna, na ordem do catálogo."))
        staging.append(model(f"stg_legacy__{table}", f"Limpeza por coluna de legacy.{table}; contexto avaliado em trusted.",
                             columns, ["source_system", "snapshot_id", "legacy_row_id"]))
    identity = ["source_system", "snapshot_id", "source_table", "legacy_row_id"]
    trusted = [
        model("legacy_records", "Ocorrências da captura selecionada, com o contrato derivado do SQLAlchemy.",
              common_columns() + [column("source_table", "Tabela de origem."),
                                  column("cleaned_payload", "Valores tratados por coluna.", "personal"),
                                  column("value_findings", "Achados de valor por coluna."),
                                  column("record_contract", "Obrigatoriedade, chaves e FKs derivadas dos modelos.")], identity),
        model("legacy_classifications", "Três saídas exclusivas com falhas de contexto e rejeição em cascata.",
              classified_columns(), identity + ["catalog_version"]),
        model("legacy_eligible_records", "Aceitos e corrigidos da captura selecionada; ainda não empilhados por domínio.",
              classified_columns(), identity + ["catalog_version"]),
    ]
    # A quarentena é a única que guarda mais de uma execução, e por isso a
    # impressão digital entra na sua chave: sob a mesma versão, dois
    # tratamentos diferentes são duas auditorias, não uma sobrescrita (D34).
    quarantine = [model("rejected_legacy_records", "Destino permanente dos rejeitados por captura e versão do catálogo; nunca fonte de negócio.",
                        classified_columns(), identity + ["catalog_version", "treatment_fingerprint"])]
    return {
        root / directory / "_legacy__models.yml": "# Gerado por make legacy-models; metadados em legacy/classification.py e models/.\n"
        + yaml.safe_dump({"version": 2, "models": models}, allow_unicode=True, sort_keys=False, width=100)
        for directory, models in [("staging/legacy", staging), ("trusted/legacy", trusted), ("quarantine", quarantine)]
    }
