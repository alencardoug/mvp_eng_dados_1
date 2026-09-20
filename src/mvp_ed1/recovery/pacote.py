"""O pacote de recuperação: o que ele guarda, e por quê.

[Capacidade §3](../../docs/capacidade_e_recuperacao.md) foi escrita antes dos
ADRs 0037, 0044 e 0045, e dizia "o `warehouse_db` **não** entra". Depois deles
o armazém virou guardião de memória que **nenhuma reconstrução reproduz**, e
o pacote passou a guardar as fontes **e** a memória (D49, ampliada por D51):

| Conteúdo | Por que não se reconstrói |
|---|---|
| `source_db` e `legacy_db` | são as fontes |
| `raw_legacy` | as capturas retidas, de onde a memória de exclusões renasce (ADR-0045) |
| `governance` | os certificados de cada captura (ADR-0037/0044) |
| `snapshots` | o histórico SCD; `dbt_project.yml` os declara não reconstruíveis |
| `quarantine` | 60.595 das 63.802 linhas nenhum rebuild da captura corrente recalcula |
| `data/legacy/manifesto.json` e o diário | os oráculos do dump do legado; sem eles os testes pulam ou usam o manifesto de outra geração |
| `.stream/producer_state.json` | o cursor do produtor que corresponde ao livro |

**Fora do pacote, por construção:** `raw` (o Airbyte refaz do `source_db`
restaurado, e a reconciliação dos dois caminhos prova), `staging`, `trusted`,
`analytics`, `consumption` (o dbt refaz), o cursor do CDC, o estado do Airbyte
e do Airflow. Uma restauração devolve **as fontes e a memória**; o resto é
reconstruído e provado igual — e o que ela não leva está escrito aqui, não
descoberto depois.

**O corte é estável porque a janela está parada.** `pack` recusa com
sincronização, DAG, Beam ou produtor no ar, como o preflight; cada `pg_dump` é
consistente por si (é um *snapshot* de transação) e as contagens do manifesto
saem numa transação `repeatable read` por banco, no mesmo instante.
"""

from __future__ import annotations

import hashlib
import json
import os
import pathlib
import shutil
import subprocess
from dataclasses import dataclass, field
from typing import Any

#: Os schemas do armazém que são memória. O resto do armazém se reconstrói.
SCHEMAS_DE_MEMORIA = ("raw_legacy", "governance", "snapshots", "quarantine")

#: Arquivos de trabalho, fora do Git, que os oráculos usam — por **padrão**, e
#: não por nome fixo. `data/legacy/` guarda o manifesto corrente e os de
#: gerações anteriores (`manifesto-<hash>.json`), e nomear só um deixaria os
#: outros para trás. Medido ao montar o primeiro pacote: a lista fixa citava um
#: `diario.json` que não existe e ignorava dois manifestos que existem.
ARTEFATOS = ("data/legacy/*.json", ".stream/producer_state.json")

NOME_DO_MANIFESTO = "manifesto.json"
NOME_DOS_CHECKSUMS = "checksums.sha256"
NOME_DO_ROTEIRO = "RESTAURAR.md"


class PacoteRecusado(Exception):
    """O pacote não foi montado, e o motivo é dito por extenso."""


@dataclass
class Destino:
    """Onde o pacote vive. **Absoluto**, sempre (RV12-09).

    Um `RECOVERY_DIR` relativo num alvo composto resolve contra o diretório de
    quem chama, e em B5 quem chama é o clone: o pacote do *checkout* antigo
    seria procurado dentro do clone novo, onde ele não está.
    """

    raiz: pathlib.Path

    def __post_init__(self) -> None:
        if not self.raiz.is_absolute():
            raise PacoteRecusado(
                f"RECOVERY_DIR precisa ser absoluto, e é {self.raiz!r}. "
                "Num alvo composto o relativo resolve contra quem chama, e em B5 "
                "quem chama é o clone — o pacote do checkout antigo não está lá dentro."
            )

    @property
    def candidato(self) -> pathlib.Path:
        return self.raiz / "candidato"

    @property
    def aprovado(self) -> pathlib.Path:
        return self.raiz / "aprovado"


def sha256(caminho: pathlib.Path) -> str:
    acumulador = hashlib.sha256()
    with caminho.open("rb") as arquivo:
        for bloco in iter(lambda: arquivo.read(1024 * 1024), b""):
            acumulador.update(bloco)
    return acumulador.hexdigest()


def escrever_checksums(pasta: pathlib.Path) -> pathlib.Path:
    """Um `sha256` por arquivo do pacote, menos o próprio arquivo de checksums."""
    destino = pasta / NOME_DOS_CHECKSUMS
    linhas = []
    for arquivo in sorted(pasta.rglob("*")):
        if not arquivo.is_file() or arquivo.name == NOME_DOS_CHECKSUMS:
            continue
        linhas.append(f"{sha256(arquivo)}  {arquivo.relative_to(pasta)}")
    destino.write_text("\n".join(linhas) + "\n", encoding="utf-8")
    return destino


def conferir_checksums(pasta: pathlib.Path) -> list[str]:
    """As diferenças entre o que foi gravado e o que está no disco.

    Confere os dois sentidos: arquivo alterado **e** arquivo que apareceu
    depois. Só o primeiro deixaria passar um dump trocado por outro ao lado.
    """
    arquivo = pasta / NOME_DOS_CHECKSUMS
    if not arquivo.exists():
        return [f"{NOME_DOS_CHECKSUMS} não existe — o pacote não está completo"]

    problemas: list[str] = []
    declarados: dict[str, str] = {}
    for linha in arquivo.read_text(encoding="utf-8").splitlines():
        if not linha.strip():
            continue
        esperado, relativo = linha.split("  ", 1)
        declarados[relativo] = esperado
        alvo = pasta / relativo
        if not alvo.exists():
            problemas.append(f"{relativo}: declarado no pacote e ausente do disco")
        elif sha256(alvo) != esperado:
            problemas.append(f"{relativo}: checksum não confere — o arquivo mudou")

    presentes = {
        str(a.relative_to(pasta))
        for a in pasta.rglob("*")
        if a.is_file() and a.name != NOME_DOS_CHECKSUMS
    }
    for extra in sorted(presentes - set(declarados)):
        problemas.append(f"{extra}: está no pacote e não foi declarado")
    return problemas


@dataclass
class Manifesto:
    """O que o pacote afirma sobre o estado que guardou."""

    dados: dict[str, Any] = field(default_factory=dict)

    def gravar(self, pasta: pathlib.Path) -> pathlib.Path:
        destino = pasta / NOME_DO_MANIFESTO
        destino.write_text(
            json.dumps(self.dados, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        return destino

    @classmethod
    def ler(cls, pasta: pathlib.Path) -> "Manifesto":
        caminho = pasta / NOME_DO_MANIFESTO
        if not caminho.exists():
            raise PacoteRecusado(f"{caminho} não existe — isto não é um pacote de recuperação")
        return cls(json.loads(caminho.read_text(encoding="utf-8")))


def arvore_suja(raiz: pathlib.Path) -> str:
    """O que `git status --porcelain` acusa. Vazio é árvore limpa.

    O pacote grava `git rev-parse HEAD` como a versão do código que o produziu.
    Com a árvore suja esse *commit* descreve outro código, e a restauração
    reconstruiria com modelos que ninguém tem.
    """
    return subprocess.run(
        ["git", "status", "--porcelain"], cwd=raiz, capture_output=True, text=True, check=True
    ).stdout.strip()


def commit_atual(raiz: pathlib.Path) -> str:
    return subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=raiz, capture_output=True, text=True, check=True
    ).stdout.strip()


def copiar_artefatos(raiz: pathlib.Path, destino: pathlib.Path) -> tuple[list[str], list[str]]:
    """Os arquivos de trabalho que os oráculos usam.

    Devolve `(copiados, padrões sem nenhum arquivo)`. Padrão vazio é **dito**,
    não suposto: sem o manifesto do legado os testes pulam ou usam o de outra
    geração, e um pacote que não avisa disso parece completo.
    """
    copiados: list[str] = []
    vazios: list[str] = []
    for padrao in ARTEFATOS:
        encontrados = sorted(raiz.glob(padrao))
        if not encontrados:
            vazios.append(padrao)
            continue
        for origem in encontrados:
            relativo = origem.relative_to(raiz)
            alvo = destino / relativo
            alvo.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(origem, alvo)
            copiados.append(str(relativo))
    return copiados, vazios


def promover(destino: Destino) -> pathlib.Path:
    """`candidato/` → `aprovado/`, e o anterior é apagado.

    Só depois de `verify` **e** de uma restauração validada — a decisão é de
    quem opera, e este módulo só executa o que ela mandou.
    """
    if not destino.candidato.exists():
        raise PacoteRecusado(f"não há candidato em {destino.candidato}")
    if (destino.aprovado).exists():
        shutil.rmtree(destino.aprovado)
    destino.candidato.rename(destino.aprovado)
    return destino.aprovado


def diretorio_padrao(raiz: pathlib.Path) -> Destino:
    """`RECOVERY_DIR` do ambiente, ou `<raiz>/data/recovery` (D46)."""
    bruto = os.environ.get("RECOVERY_DIR")
    return Destino(pathlib.Path(bruto) if bruto else (raiz / "data" / "recovery").resolve())
