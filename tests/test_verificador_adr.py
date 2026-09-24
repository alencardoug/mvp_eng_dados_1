"""O verificador da skill de ADR (`.claude/skills/adr/verificar.py`) contra repositórios de mentira.

Ele confere que as decisões pendentes estão contadas igual em todo lugar. Até 24/09/2026 só conhecia
um conjunto — as da tabela da §3 do Registro de Decisões — e só com o código em negrito
(`| **D36** |`): a linha `| D43 |` virava zero pendentes, o cabeçalho `1 (D43, …)` das Pendências
não casava com a forma `1 — D36`, e ele acusava contadores certos. E as decisões de operação, que
fecham nas Pendências sem ADR, ficavam fora da conta: com a D53 e a D54 abertas, o README dizia 1
pendente enquanto as Pendências diziam 3, sem acusação nenhuma.

Cada cenário monta um repositório mínimo com o verificador real, os três documentos e dois ADRs, e
roda o script como a skill roda.
"""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

import pytest

RAIZ = pathlib.Path(__file__).resolve().parents[1]
VERIFICADOR = RAIZ / ".claude" / "skills" / "adr" / "verificar.py"

REGISTRO = """# Registro de Decisões (ADR)

## 1. Como funciona

A numeração não é densa: **D19** nunca existiu.

## 2. Decisões registradas

| ADR | Título | Estado | Resolve |
|---|---|---|---|
| [0001](0001-registrar-decisoes.md) | Registrar decisões | Aceita | — |
| [0002](0002-outra.md) | Outra | Aceita | D33 |

---

## 3. Decisões pendentes

| # | Decisão | Levantada em | Efeito de não decidir |
|---|---|---|---|
{linhas}

Texto depois da tabela.
"""

PENDENCIAS = """# Pendências do Owner

| Campo | Informação |
|---|---|
| Decisões pendentes | {cabecalho} |

---

## 1. Esperando você

{esperando}

---

## 1.1 Decididas e implementadas

Nada aqui.

## 2. Decisões já fechadas

{fechadas}
"""

README = """# Projeto

| Documento | Conteúdo | Situação |
|---|---|---|
| [Pendências do Owner](docs/pendencias.md) | O que espera decisão | {pendencias} |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e pendentes | {registro} |
"""

#: O estado de hoje: a D43 adiada, nas duas tabelas, sem negrito.
ATUAL = {
    "linhas": "| D43 | A guarda de identidade — adiada | 16/09/2026 | Nenhum na fase local |",
    "cabecalho": "1 (D43, adiada de propósito para a fase GCP)",
    "esperando": "### D43 — a guarda de identidade (adiada em 16/09/2026)\n\nTexto.",
    "fechadas": "### D53 e D54 — decididas e implementadas em 24/09/2026\n\nTexto.",
    "pendencias": "1 pendente em 24/09/2026: a D43 (adiada para a fase GCP)",
    "registro": "2 aceitos, 1 pendente (D43, adiada)",
}


def _verificar(tmp_path: pathlib.Path, **trocas: str) -> subprocess.CompletedProcess[str]:
    campos = ATUAL | trocas
    raiz = tmp_path / "repo"
    (raiz / ".claude" / "skills" / "adr").mkdir(parents=True)
    shutil.copy(VERIFICADOR, raiz / ".claude" / "skills" / "adr" / "verificar.py")
    adr = raiz / "docs" / "adr"
    adr.mkdir(parents=True)
    for nome in ("0000-template.md", "0001-registrar-decisoes.md", "0002-outra.md"):
        (adr / nome).write_text(f"# {nome}\n", encoding="utf-8")
    (adr / "README.md").write_text(REGISTRO.format(linhas=campos["linhas"]), encoding="utf-8")
    (raiz / "docs" / "pendencias.md").write_text(
        PENDENCIAS.format(cabecalho=campos["cabecalho"], esperando=campos["esperando"], fechadas=campos["fechadas"]),
        encoding="utf-8",
    )
    (raiz / "README.md").write_text(
        README.format(pendencias=campos["pendencias"], registro=campos["registro"]), encoding="utf-8"
    )
    return subprocess.run(
        [sys.executable, str(raiz / ".claude" / "skills" / "adr" / "verificar.py")],
        capture_output=True, text=True, timeout=60,
    )


# ── Contadores certos, em cada forma que os documentos já tiveram ────────────


@pytest.mark.parametrize(
    "trocas",
    [
        pytest.param({}, id="hoje-sem-negrito"),
        pytest.param(
            {
                "linhas": "| **D36** | O dimensionamento da Etapa 12 | 07/09/2026 | A Etapa 12 não cabe |",
                "cabecalho": "1 — D36",
                "esperando": "### D36 — o dimensionamento da Etapa 12\n\nTexto.",
                "fechadas": "### D33 — decidida em 07/09/2026\n\nTexto.",
                "pendencias": "**D36** — o dimensionamento da Etapa 12",
                "registro": "2 aceitos, 1 pendente",
            },
            id="08-09-em-negrito",
        ),
        pytest.param(
            {
                "linhas": "",
                "cabecalho": "0",
                "esperando": "Nada esperando você.",
                "fechadas": "### D43 — decidida\n\nTexto.",
                "pendencias": "Nenhuma decisão pendente em 15/09/2026",
                "registro": "2 aceitos, 0 pendentes",
            },
            id="nada-pendente",
        ),
        pytest.param(
            {
                "linhas": "| D43 | A guarda | 16/09/2026 | Nenhum |",
                "cabecalho": "2 (D43, adiada; D55, de operação)",
                "esperando": "### D43 — a guarda\n\nTexto.\n\n### D55 — a rede do projeto\n\nTexto.",
                "pendencias": "2 pendentes em 24/09/2026: a D43 e a D55",
            },
            id="uma-de-operacao-so-nas-pendencias",
        ),
    ],
)
def test_contadores_certos_passam(tmp_path, trocas):
    """A linha `| D43 |`, sem negrito, é a que o verificador anterior contava como zero."""
    r = _verificar(tmp_path, **trocas)

    assert r.returncode == 0, r.stdout + r.stderr
    assert "Integridade conferida" in r.stdout


# ── E os contadores errados são acusados, cada um pelo que está errado ──────


@pytest.mark.parametrize(
    "trocas, acusacao",
    [
        pytest.param(
            {
                "cabecalho": "3 (D43, adiada; D53 e D54, levantadas em 23/09/2026)",
                "esperando": "### D43 — a guarda\n\nTexto.\n\n### D53 — o preflight\n\nTexto.\n\n### D54 — a retomada\n\nTexto.",
                "fechadas": "",
                "pendencias": "1 pendente em 18/09/2026: a D43 (adiada para a fase GCP)",
            },
            "Pendências do Owner",
            id="readme-dizia-1-com-3-esperando",
        ),
        pytest.param(
            {"esperando": "### D43 — a guarda\n\nTexto.\n\n### D57 — nova\n\nTexto."},
            "o cabeçalho deveria dizer 2",
            id="cabecalho-atrasado",
        ),
        pytest.param(
            {"linhas": "| D43 | A guarda | 16/09/2026 | Nenhum |\n| D57 | Nova | 24/09/2026 | Algum |"},
            "D57",
            id="pendente-do-registro-fora-das-pendencias",
        ),
        pytest.param(
            {
                "esperando": "### D43 — a guarda\n\nTexto.\n\n### D53 — o preflight\n\nTexto.",
                "cabecalho": "2 (D43 e D53)",
                "pendencias": "2 pendentes: a D43 e a D53",
            },
            "fechada ainda esperando o Owner nas Pendências: D53",
            id="fechada-ainda-esperando",
        ),
        pytest.param(
            {"linhas": "| D43 | A guarda | 16/09/2026 | Nenhum |\n| D33 | Já resolvida | 07/09/2026 | — |"},
            "resolvida ainda listada como pendente no Registro: D33",
            id="resolvida-ainda-no-registro",
        ),
        pytest.param(
            {"registro": "2 aceitos, 0 pendentes"},
            "Registro de Decisões",
            id="readme-do-registro-atrasado",
        ),
    ],
)
def test_contadores_errados_sao_acusados(tmp_path, trocas, acusacao):
    r = _verificar(tmp_path, **trocas)

    assert r.returncode == 1, r.stdout + r.stderr
    assert acusacao in r.stdout, r.stdout
