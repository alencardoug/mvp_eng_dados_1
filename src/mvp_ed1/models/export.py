"""Gera o catálogo a partir dos modelos: dicionário, inventário e diagrama ER.

Nada aqui é escrito à mão em dois lugares. Os modelos são a fonte de verdade do
schema (ADR-0009) e a configuração do gerador é a fonte de verdade do volume
(ADR-0014); dicionário, inventário e diagrama são derivados dos dois. Se
divergirem, é porque alguém editou o derivado — e o comando reescreve por cima.

Uso: ``python -m mvp_ed1.models.export`` (ou ``make catalog``).
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

from sqlalchemy import Table
from sqlalchemy.dialects import postgresql

from mvp_ed1.generator.config import padrao as configuracao_do_gerador
from mvp_ed1.models import DOMAINS, Base, validate_metadata

_PG = postgresql.dialect()

INICIO = "<!-- gerado a partir dos modelos; não editar à mão -->"
FIM = "<!-- fim do trecho gerado -->"

ROOT = Path(__file__).resolve().parents[3]
DICIONARIO = ROOT / "docs/dicionario_de_dados.md"
MODELO = ROOT / "docs/modelo_de_dados.md"

#: Ordinal de cada domínio na seção 2 do Modelo de Dados.
_TITULOS = {
    "clientes": "Clientes", "catalogo": "Catálogo e preços", "compras": "Fornecedores e compras",
    "vendas": "Vendas", "pagamentos": "Pagamentos", "estoque": "Estoque",
    "logistica": "Logística", "marketing": "Marketing", "atendimento": "Atendimento",
}


def _numero(valor: int) -> str:
    """Milhar com ponto, como o resto do documento escreve."""
    return f"{valor:,}".replace(",", ".")


def _por_dominio() -> dict[str, list[Table]]:
    agrupado: dict[str, list[Table]] = defaultdict(list)
    for table in Base.metadata.sorted_tables:
        agrupado[table.info["domain"]].append(table)
    return agrupado


def _tipo(column) -> str:
    """Tipo como o PostgreSQL o cria — não o nome genérico do SQLAlchemy.

    Sem compilar contra o dialeto, `Uuid` sairia como `char(32)`, que é o que
    ele vira em bancos sem tipo nativo — e não é o que este projeto cria.
    """
    return column.type.compile(dialect=_PG).lower().replace(" ", "")


def _tipo_mermaid(column) -> str:
    """O mesmo tipo, sem parênteses.

    O parser de `erDiagram` do Mermaid não aceita `varchar(32)`: o diagrama
    inteiro deixa de renderizar, silenciosamente, na página do GitHub.
    """
    return re.sub(r"[^a-z0-9_]+", "_", _tipo(column)).strip("_")


def _chave(table: Table, column) -> str:
    marcas = []
    if column.primary_key:
        marcas.append("PK")
    if column.foreign_keys:
        marcas.append("FK")
    if any(column.name in uc.columns and len(uc.columns) == 1 for uc in table.constraints
           if uc.__class__.__name__ == "UniqueConstraint"):
        marcas.append("UK")
    return " ".join(marcas)


def dicionario_markdown() -> str:
    agrupado = _por_dominio()
    linhas: list[str] = [
        "",
        "As tabelas abaixo são **geradas** a partir dos modelos SQLAlchemy — a coluna",
        "*Classificação* vem do metadado declarado em cada campo, e é ela que vira",
        "*policy tag* no BigQuery na fase GCP.",
        "",
    ]

    total_colunas = sum(len(t.columns) for t in Base.metadata.tables.values())
    linhas += [
        "| Métrica | Valor |",
        "|---|---:|",
        f"| Tabelas no schema `oltp` | {len(Base.metadata.tables)} |",
        f"| Campos classificados | {total_colunas} |",
        "",
    ]

    for dominio in DOMAINS:
        tabelas = agrupado.get(dominio, [])
        if not tabelas:
            continue
        linhas.append(f"### Domínio `{dominio}` — {len(tabelas)} tabelas")
        linhas.append("")
        for table in tabelas:
            linhas.append(f"#### `{table.name}`")
            linhas.append("")
            linhas.append(f"{table.info['description']}")
            linhas.append("")
            linhas.append("| Campo | Tipo | Obrigatório | Chave | Classificação | Descrição |")
            linhas.append("|---|---|:---:|:---:|---|---|")
            for column in table.columns:
                obrigatorio = "sim" if not column.nullable else "não"
                linhas.append(
                    f"| `{column.name}` | `{_tipo(column)}` | {obrigatorio} | "
                    f"{_chave(table, column) or '—'} | `{column.info['sensitivity']}` | "
                    f"{column.info['description']} |"
                )
            linhas.append("")
    return "\n".join(linhas)


def inventario_markdown() -> str:
    """Seção 2 do Modelo de Dados, a partir dos modelos e da configuração.

    A finalidade de cada tabela vem do metadado do modelo e a contagem, da
    proporção declarada no gerador. Escrever as duas à mão aqui manteria três
    cópias do mesmo fato — e é o gerador, não o documento, que decide volume.
    """
    config = configuracao_do_gerador()
    agrupado = _por_dominio()
    linhas: list[str] = [""]
    total = 0

    for indice, dominio in enumerate(DOMAINS, start=1):
        tabelas = agrupado.get(dominio, [])
        if not tabelas:
            continue
        linhas.append(f"### 2.{indice} {_TITULOS[dominio]} — {len(tabelas)} tabelas")
        linhas.append("")
        linhas.append("| Tabela | Linhas | Finalidade |")
        linhas.append("|---|---:|---|")
        for table in sorted(tabelas, key=lambda t: config.tabelas[t.name].referencia, reverse=True):
            referencia = config.tabelas[table.name].referencia
            total += referencia
            destaque = "**" if referencia >= 1_000_000 else ""
            linhas.append(
                f"| `{table.name}` | {destaque}{_numero(referencia)}{destaque} | "
                f"{table.info['description']} |"
            )
        linhas.append("")

    fator_um = sum(config.plano().values())
    linhas += [
        f"**Total na proporção de referência:** {_numero(total)} linhas — "
        f"{_numero(fator_um)} no fator `dev`, que é o padrão local.",
        "",
    ]
    return "\n".join(linhas)


def diagrama_markdown() -> str:
    agrupado = _por_dominio()
    linhas: list[str] = [
        "",
        "Um diagrama por domínio, **gerado** a partir dos modelos. Cada entidade mostra",
        "apenas as chaves: a lista completa de campos vive no",
        "[Dicionário de Dados](dicionario_de_dados.md), que é o dono desse conteúdo.",
        "",
        "Relações que cruzam domínios aparecem no diagrama do domínio que **contém a",
        "chave estrangeira**, com a tabela referenciada em cinza.",
        "",
    ]
    dominio_de = {t.name: t.info["domain"] for t in Base.metadata.tables.values()}

    for dominio in DOMAINS:
        tabelas = agrupado.get(dominio, [])
        if not tabelas:
            continue
        nomes = {t.name for t in tabelas}
        linhas.append(f"#### `{dominio}`")
        linhas.append("")
        linhas.append("```mermaid")
        linhas.append("erDiagram")
        externas: set[str] = set()
        for table in tabelas:
            for fk in sorted(table.foreign_keys, key=lambda f: f.parent.name):
                alvo = fk.column.table.name
                if alvo not in nomes:
                    externas.add(alvo)
                obrigatoria = not fk.parent.nullable
                traco = "||--o{" if obrigatoria else "||..o{"
                linhas.append(f'    {alvo} {traco} {table.name} : "{fk.parent.name}"')
        for table in tabelas:
            chaves = [c for c in table.columns if c.primary_key or c.foreign_keys or c.unique]
            linhas.append(f"    {table.name} {{")
            for column in chaves:
                marca = _chave(table, column).split(" ")[0] or ""
                linhas.append(f"        {_tipo_mermaid(column)} {column.name} {marca}".rstrip())
            linhas.append("    }")
        for nome in sorted(externas):
            linhas.append(f"    {nome} {{")
            linhas.append(f'        bigint id PK "domínio {dominio_de.get(nome, "?")}"')
            linhas.append("    }")
        linhas.append("```")
        linhas.append("")
    return "\n".join(linhas)


def _substituir(caminho: Path, conteudo: str, ocorrencia: int = 0) -> None:
    """Reescreve o n-ésimo trecho entre marcadores do arquivo.

    Um documento pode ter mais de um trecho gerado — o Modelo de Dados tem dois,
    o inventário e o diagrama —, e trocar a ordem deles aqui trocaria o conteúdo
    de lugar sem que nada reclamasse.
    """
    texto = caminho.read_text(encoding="utf-8")
    padrao = re.compile(re.escape(INICIO) + r".*?" + re.escape(FIM), re.DOTALL)
    trechos = list(padrao.finditer(texto))
    if len(trechos) <= ocorrencia:
        raise SystemExit(
            f"{caminho.name}: esperado ao menos {ocorrencia + 1} trecho(s) entre "
            f"{INICIO} … {FIM}, encontrado(s) {len(trechos)}"
        )
    trecho = trechos[ocorrencia]
    atualizado = texto[: trecho.start()] + f"{INICIO}\n{conteudo}\n{FIM}" + texto[trecho.end():]
    caminho.write_text(atualizado, encoding="utf-8")
    print(f"  {caminho.relative_to(ROOT)} atualizado (trecho {ocorrencia + 1})")


def main() -> int:
    problemas = validate_metadata()
    if problemas:
        print("METADADOS INCOMPLETOS — nada foi gerado:", file=sys.stderr)
        for p in problemas:
            print(f"  - {p}", file=sys.stderr)
        return 1
    _substituir(DICIONARIO, dicionario_markdown())
    _substituir(MODELO, inventario_markdown(), ocorrencia=0)
    _substituir(MODELO, diagrama_markdown(), ocorrencia=1)
    print(
        f"  {len(Base.metadata.tables)} tabelas e "
        f"{sum(len(t.columns) for t in Base.metadata.tables.values())} campos classificados"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
