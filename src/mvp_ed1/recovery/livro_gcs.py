"""O livro retido num *bucket* do Cloud Storage — a fase GCP do ADR-0050 (Etapa 13, G2.1).

Na fase local o livro é um diretório (`ledger.py`), e o "nunca substituído" é o `os.link`, que
falha se o nome já existe. Aqui a raiz é `gs://<bucket>/<prefixo>` em `LEGACY_LEDGER_DIR`, uma época
é um prefixo, um registro é um objeto, e o "nunca substituído" é a **escrita condicionada**:
`ifGenerationMatch=0`, "só crie se não existe" — o Cloud Storage recusa com `412 Precondition
Failed` quando o objeto já está lá
([request preconditions](https://cloud.google.com/storage/docs/request-preconditions)).

O que muda com o meio, e por quê:

- **Sem temporário nem `fsync`.** O objeto aparece inteiro ou não aparece; o rito do temporário
  existe no disco para o registro nunca ser lido pela metade, e aqui o meio já garante isso.
- **Época sem diretório.** No disco a época é criada vazia e a linha de base vem depois; aqui o
  prefixo só existe quando tem objeto. Uma época que não chegou a ter linha de base continua não
  contando, como no disco (`current_epoch` pula).
- **A prova de escrita não escreve.** O `ingestor` tem `objectCreator`, que não apaga, e a
  retenção do *bucket* (D70) não deixaria apagar: um objeto de prova ficaria para sempre. A prova é
  `testIamPermissions` com `storage.objects.create` — a mesma pergunta, sem resíduo.

A classe `Lugar` imita do `pathlib` só o que os chamadores do livro usam: `/`, `.name`, `.parent` e
`str()`. O resto passa pelas funções deste módulo, que o `ledger` chama quando a raiz é um `Lugar`.
"""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache

PREFIXO = "gs://"


class LivroGcsError(Exception):
    """Falha do livro no Cloud Storage; o `ledger` a traduz no `LedgerError` dele."""


@dataclass(frozen=True)
class Lugar:
    bucket: str
    caminho: str = ""  # sem barra no começo nem no fim

    @classmethod
    def de(cls, valor: str) -> "Lugar":
        resto = valor[len(PREFIXO):].strip("/")
        bucket, _, caminho = resto.partition("/")
        if not bucket:
            raise LivroGcsError(f"{valor}: sem bucket")
        return cls(bucket, caminho.strip("/"))

    def __truediv__(self, nome: str) -> "Lugar":
        return Lugar(self.bucket, f"{self.caminho}/{nome}" if self.caminho else nome)

    @property
    def name(self) -> str:
        return self.caminho.rsplit("/", 1)[-1]

    @property
    def parent(self) -> "Lugar":
        return Lugar(self.bucket, self.caminho.rsplit("/", 1)[0] if "/" in self.caminho else "")

    def __str__(self) -> str:
        return f"{PREFIXO}{self.bucket}/{self.caminho}" if self.caminho else f"{PREFIXO}{self.bucket}"

    def _prefixo(self) -> str:
        return f"{self.caminho}/" if self.caminho else ""


@lru_cache(maxsize=1)
def _cliente():
    from google.cloud import storage

    return storage.Client()


def _bucket(lugar: Lugar, cliente=None):
    return (cliente or _cliente()).bucket(lugar.bucket)


def existe_raiz(lugar: Lugar, cliente=None) -> bool:
    """O *bucket* existe e é legível. A raiz, sendo prefixo, não precisa existir antes da 1ª época."""
    from google.api_core import exceptions

    try:
        return _bucket(lugar, cliente).exists()
    except exceptions.Forbidden:
        return False


def subprefixos(lugar: Lugar, cliente=None) -> list[Lugar]:
    """Os "subdiretórios" imediatos da raiz: os prefixos de época."""
    iterador = (cliente or _cliente()).list_blobs(lugar.bucket, prefix=lugar._prefixo(), delimiter="/")
    list(iterador)  # os prefixos só se conhecem depois de consumir as páginas
    return [Lugar(lugar.bucket, p.rstrip("/")) for p in sorted(iterador.prefixes)]


def ler(lugar: Lugar, cliente=None) -> bytes | None:
    """O conteúdo de um objeto, ou `None` se não existe."""
    from google.api_core import exceptions

    try:
        return _bucket(lugar, cliente).blob(lugar.caminho).download_as_bytes()
    except exceptions.NotFound:
        return None


def criar(lugar: Lugar, dados: bytes, cliente=None) -> None:
    """Cria o objeto **só se não existe** (`ifGenerationMatch=0`). Existindo, `FileExistsError`."""
    from google.api_core import exceptions

    try:
        _bucket(lugar, cliente).blob(lugar.caminho).upload_from_string(
            dados, content_type="application/json", if_generation_match=0)
    except exceptions.PreconditionFailed:
        raise FileExistsError(str(lugar)) from None


def objetos(lugar: Lugar, cliente=None) -> list[tuple[str, bytes]]:
    """(nome, conteúdo) dos objetos imediatamente abaixo do prefixo, pelo nome."""
    blobs = (cliente or _cliente()).list_blobs(lugar.bucket, prefix=lugar._prefixo(), delimiter="/")
    saida = []
    for blob in sorted(blobs, key=lambda b: b.name):
        nome = blob.name[len(lugar._prefixo()):]
        if nome:
            saida.append((nome, blob.download_as_bytes()))
    return saida


def pode_criar(lugar: Lugar, cliente=None) -> bool:
    """A credencial corrente pode criar objetos no *bucket* — sem criar nenhum."""
    concedidas = _bucket(lugar, cliente).test_iam_permissions(["storage.objects.create"])
    return "storage.objects.create" in concedidas
