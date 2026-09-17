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
    #: Coluna JSON com a linha inteira: a linhagem por coluna não vê o que ela
    #: carrega, e a regra é classificar no nível mais alto — `personal` — em toda
    #: tabela, mesmo naquelas cujas colunas não chegam a isso. A justificativa
    #: fica no `.yml` (`sensitivity_reason`), que é o que `models/sensitivity.py`
    #: exige de toda declaração à mão mais estrita que a derivada.
    PAYLOAD = "linha inteira em JSON: classificada como pessoal por regra, em toda tabela, porque a linhagem por coluna não vê o que um payload carrega"

    def column(name, description, sensitivity="internal", tests=None):
        value = {"name": str(name), "description": description, "meta": {"sensitivity": sensitivity}}
        if sensitivity == "personal" and str(name).endswith(("payload", "payloads", "findings")):
            value["meta"]["sensitivity_reason"] = PAYLOAD
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
    # Exclusão física (ADR-0045): presença por captura, intervalo e memória.
    # Só a presença lê as 40 fontes; os outros dois leem dela — é o que torna
    # os unit tests abaixo viáveis com três entradas simuladas.
    presenca = [column("source_table", "Tabela de origem.", tests=["not_null"]),
                column("snapshot_id", "Captura certificada (ou a selecionada).", tests=["not_null"]),
                column("business_key", "PK declarada, canonizada pelo tipo; nulo é linha sem identidade.")]
    trusted += [
        model("legacy_presence_by_capture", "Linhas físicas por captura certificada, tabela e chave canônica, com os payloads brutos.",
              presenca + [column("n", "Linhas físicas com esta chave nesta captura.", tests=["not_null"]),
                          column("payloads", "Payloads brutos das linhas, em ordem física. Pode conter dados pessoais sintéticos.", "personal")],
              ["source_table", "snapshot_id", "business_key"]),
        model("legacy_capture_transitions", "Intervalo entre a certificada anterior mais recente e a selecionada, por chave e com multiplicidade.",
              [column("previous_snapshot_id", "Certificada anterior mais recente.", tests=["not_null"]),
               column("selected_snapshot_id", "Captura selecionada.", tests=["not_null"]),
               column("source_table", "Tabela de origem.", tests=["not_null"]),
               column("business_key", "PK canonizada; nulo agrupa as linhas sem identidade."),
               column("rows_before", "Linhas físicas na anterior.", tests=["not_null"]),
               column("rows_after", "Linhas físicas na selecionada.", tests=["not_null"]),
               column("transition", "removida, adicionada, reduzida, aumentada, mantida ou sem_identidade.", tests=["not_null", {
                   "accepted_values": {"arguments": {"values": ["removida", "adicionada", "reduzida", "aumentada", "mantida", "sem_identidade"]}}}])],
              ["source_table", "business_key"]),
        model("legacy_removed_records", "Memória da ausência: chaves vistas em certificada anterior e ausentes na selecionada; auditoria, fora de equação.",
              [column("source_table", "Tabela de origem.", tests=["not_null"]),
               column("business_key", "PK canonizada.", tests=["not_null"]),
               column("last_seen_snapshot_id", "Maior captura certificada em que a chave esteve.", tests=["not_null"]),
               column("removed_in_snapshot_id", "Menor certificada posterior ao last_seen — onde faltou pela primeira vez.", tests=["not_null"]),
               column("observed_in_snapshot_id", "Captura selecionada em que a ausência foi observada.", tests=["not_null"]),
               column("rows_last_seen", "Linhas físicas com a chave na última captura em que existiu."),
               column("last_payload", "Payloads brutos da última captura em que a chave existiu — não tratados. Pode conter dados pessoais sintéticos.", "personal")],
              ["source_table", "business_key"]),
    ]
    # A quarentena é a única que guarda mais de uma execução, e por isso a
    # impressão digital entra na sua chave: sob a mesma versão, dois
    # tratamentos diferentes são duas auditorias, não uma sobrescrita (D34).
    quarantine = [model("rejected_legacy_records", "Destino permanente dos rejeitados por captura e versão do catálogo; nunca fonte de negócio.",
                        classified_columns(), identity + ["catalog_version", "treatment_fingerprint"])]
    saidas = {}
    for directory, models in [("staging/legacy", staging), ("trusted/legacy", trusted), ("quarantine", quarantine)]:
        documento = {"version": 2, "models": models}
        if directory == "trusted/legacy":
            documento["unit_tests"] = unit_tests_remocao()
        saidas[root / directory / "_legacy__models.yml"] = (
            "# Gerado por make legacy-models; metadados em legacy/classification.py e models/.\n"
            + yaml.safe_dump(documento, allow_unicode=True, sort_keys=False, width=100)
        )
    return saidas


def unit_tests_remocao() -> list[dict]:
    """Unit tests do dbt para intervalo e memória da exclusão física (ADR-0045).

    Capturas fictícias, certificadas por 40 linhas `complete` cada — a mesma
    regra do modelo real —, e os casos que a revisão do plano exigiu: remoção,
    inclusão, redução de multiplicidade (`[7,7] → [7]`), sem identidade, C sem
    mudança, reaparecimento seguido de nova exclusão, anterior `incomplete`
    ignorada, e chaves `08`/`8` e UUID já canonizadas na presença.
    """
    def certificados(*snapshots, incompleta=()):
        linhas = []
        for snapshot in snapshots:
            for tabela in schema.tabelas():
                status = "incomplete" if snapshot in incompleta and tabela == "brands" else "complete"
                linhas.append({"snapshot_id": snapshot, "source_table": str(tabela), "status": status})
        return linhas

    def presenca(snapshot, tabela, chave, n=1):
        return {"snapshot_id": snapshot, "source_table": tabela, "business_key": chave, "n": n,
                "payloads": '[{"id": "%s"}]' % chave}

    transicoes_dado = [
        presenca(1, "brands", "1"), presenca(2, "brands", "1"),            # mantida
        presenca(1, "brands", "2"),                                         # removida
        presenca(2, "brands", "3"),                                         # adicionada
        presenca(1, "brands", "7", 2), presenca(2, "brands", "7", 1),       # reduzida
        presenca(1, "brands", None, 1), presenca(2, "brands", None, 2),     # sem identidade
        presenca(1, "warehouses", "8"), presenca(2, "warehouses", "8"),     # já canônica: `08` virou `8` na presença
    ]
    transicoes_esperado = [
        {"source_table": "brands", "business_key": "1", "rows_before": 1, "rows_after": 1, "transition": "mantida"},
        {"source_table": "brands", "business_key": "2", "rows_before": 1, "rows_after": 0, "transition": "removida"},
        {"source_table": "brands", "business_key": "3", "rows_before": 0, "rows_after": 1, "transition": "adicionada"},
        {"source_table": "brands", "business_key": "7", "rows_before": 2, "rows_after": 1, "transition": "reduzida"},
        {"source_table": "brands", "business_key": None, "rows_before": 1, "rows_after": 2, "transition": "sem_identidade"},
        {"source_table": "warehouses", "business_key": "8", "rows_before": 1, "rows_after": 1, "transition": "mantida"},
    ]
    memoria_dado = [
        presenca(1, "brands", "A"), presenca(2, "brands", "A"),            # some em 3: last_seen 2, removed_in 3
        presenca(1, "brands", "B"),                                         # some em 2: last_seen 1, removed_in 2
        presenca(1, "brands", "C"), presenca(3, "brands", "C"),            # reapareceu: fora da lista
        presenca(1, "brands", "D"), presenca(3, "brands", "D"),            # reaparece em 3 e some em 5: last_seen 3, removed_in 5
        presenca(1, "brands", "E"), presenca(2, "brands", "E"), presenca(3, "brands", "E"),  # presente: fora
    ]
    return [
        {
            "name": "transicoes_por_chave_com_multiplicidade",
            "description": "Removida, adicionada, reduzida, mantida e sem identidade entre a anterior certificada e a selecionada.",
            "model": "legacy_capture_transitions",
            "given": [
                {"input": "ref('legacy_presence_by_capture')", "rows": transicoes_dado},
                {"input": "ref('legacy_selected_capture')", "rows": [{"snapshot_id": 2}]},
                {"input": "source('governance', 'legacy_captures')", "rows": certificados(1, 2)},
            ],
            "expect": {"rows": [{"previous_snapshot_id": 1, "selected_snapshot_id": 2, **linha} for linha in transicoes_esperado]},
        },
        {
            "name": "anterior_incompleta_e_ignorada_e_sem_anterior_nao_ha_intervalo",
            "description": "A anterior é a certificada mais recente: a captura 2 incompleta é pulada e o intervalo é 1 → 3.",
            "model": "legacy_capture_transitions",
            "given": [
                {"input": "ref('legacy_presence_by_capture')", "rows": [presenca(1, "brands", "1"), presenca(2, "brands", "1"), presenca(3, "brands", "2")]},
                {"input": "ref('legacy_selected_capture')", "rows": [{"snapshot_id": 3}]},
                {"input": "source('governance', 'legacy_captures')", "rows": certificados(1, 2, 3, incompleta=(2,))},
            ],
            "expect": {"rows": [
                {"previous_snapshot_id": 1, "selected_snapshot_id": 3, "source_table": "brands", "business_key": "1", "rows_before": 1, "rows_after": 0, "transition": "removida"},
                {"previous_snapshot_id": 1, "selected_snapshot_id": 3, "source_table": "brands", "business_key": "2", "rows_before": 0, "rows_after": 1, "transition": "adicionada"},
            ]},
        },
        {
            "name": "sem_anterior_certificada_o_intervalo_e_vazio",
            "model": "legacy_capture_transitions",
            "given": [
                {"input": "ref('legacy_presence_by_capture')", "rows": [presenca(1, "brands", "1")]},
                {"input": "ref('legacy_selected_capture')", "rows": [{"snapshot_id": 1}]},
                {"input": "source('governance', 'legacy_captures')", "rows": certificados(1)},
            ],
            "expect": {"rows": []},
        },
        {
            "name": "memoria_da_ausencia_persiste_e_reaparecimento_sai",
            "description": "Selecionada 3: A sumiu em 3, B em 2, C reapareceu, E está presente.",
            "model": "legacy_removed_records",
            "given": [
                {"input": "ref('legacy_presence_by_capture')", "rows": memoria_dado},
                {"input": "ref('legacy_selected_capture')", "rows": [{"snapshot_id": 3}]},
                {"input": "source('governance', 'legacy_captures')", "rows": certificados(1, 2, 3)},
            ],
            "expect": {"rows": [
                {"source_table": "brands", "business_key": "A", "last_seen_snapshot_id": 2, "removed_in_snapshot_id": 3, "observed_in_snapshot_id": 3},
                {"source_table": "brands", "business_key": "B", "last_seen_snapshot_id": 1, "removed_in_snapshot_id": 2, "observed_in_snapshot_id": 3},
            ]},
        },
        {
            "name": "memoria_em_c_sem_mudanca_e_reexclusao_depois_de_reaparecer",
            "description": "Selecionada 5 (4 sem mudança): A e B continuam com os mesmos valores; D reapareceu em 3 e sumiu em 4.",
            "model": "legacy_removed_records",
            "given": [
                {"input": "ref('legacy_presence_by_capture')", "rows": memoria_dado + [presenca(4, "brands", "E"), presenca(5, "brands", "E"), presenca(4, "brands", "C"), presenca(5, "brands", "C")]},
                {"input": "ref('legacy_selected_capture')", "rows": [{"snapshot_id": 5}]},
                {"input": "source('governance', 'legacy_captures')", "rows": certificados(1, 2, 3, 4, 5)},
            ],
            "expect": {"rows": [
                {"source_table": "brands", "business_key": "A", "last_seen_snapshot_id": 2, "removed_in_snapshot_id": 3, "observed_in_snapshot_id": 5},
                {"source_table": "brands", "business_key": "B", "last_seen_snapshot_id": 1, "removed_in_snapshot_id": 2, "observed_in_snapshot_id": 5},
                {"source_table": "brands", "business_key": "D", "last_seen_snapshot_id": 3, "removed_in_snapshot_id": 4, "observed_in_snapshot_id": 5},
            ]},
        },
    ]
