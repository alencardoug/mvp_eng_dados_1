"""O livro retido no Cloud Storage cumpre o mesmo contrato do livro em disco (Etapa 13, G2.1).

O *bucket* daqui é um dublê em memória com as duas respostas que importam do real: `412` na
escrita condicionada a um objeto que já existe, e `404` na leitura do que não existe. A prova
contra o Cloud Storage de verdade fica no fim, só com `GCP_TESTES=1`: o projeto é destruído no
fim da Etapa 13, e o `make check` não pode depender dele.
"""

from __future__ import annotations

import datetime as dt
import os
import uuid

import pytest
from google.api_core import exceptions

from mvp_ed1.recovery import ledger, livro_gcs
from mvp_ed1.recovery.livro_gcs import Lugar


class _Blob:
    def __init__(self, bucket: "_Bucket", nome: str):
        self._bucket, self.name = bucket, nome

    def download_as_bytes(self) -> bytes:
        if self.name not in self._bucket.objetos:
            raise exceptions.NotFound(self.name)
        return self._bucket.objetos[self.name]

    def upload_from_string(self, dados, content_type=None, if_generation_match=None):
        if if_generation_match != 0:
            raise AssertionError("o livro só escreve condicionado a não existir")
        if self.name in self._bucket.objetos:
            raise exceptions.PreconditionFailed(self.name)
        self._bucket.objetos[self.name] = dados


class _Bucket:
    def __init__(self, nome: str, existe: bool = True, pode_criar: bool = True):
        self.nome, self._existe, self._pode_criar, self.objetos = nome, existe, pode_criar, {}

    def exists(self) -> bool:
        return self._existe

    def blob(self, nome: str) -> _Blob:
        return _Blob(self, nome)

    def test_iam_permissions(self, permissoes):
        return list(permissoes) if self._pode_criar else []


class _Pagina(list):
    """O iterador do `list_blobs`: os prefixos só aparecem depois de consumido, como no cliente real."""

    def __init__(self, itens, prefixos):
        super().__init__(itens)
        self._prefixos, self.prefixes = prefixos, set()

    def __iter__(self):
        self.prefixes = set(self._prefixos)
        return super().__iter__()


class _Cliente:
    def __init__(self, bucket: _Bucket):
        self._b = bucket

    def bucket(self, nome: str) -> _Bucket:
        assert nome == self._b.nome
        return self._b

    def list_blobs(self, nome, prefix="", delimiter=None):
        diretos, prefixos = [], set()
        for chave in self._b.objetos:
            if not chave.startswith(prefix):
                continue
            resto = chave[len(prefix):]
            if delimiter and delimiter in resto:
                prefixos.add(prefix + resto.split(delimiter, 1)[0] + delimiter)
            else:
                diretos.append(_Blob(self._b, chave))
        return _Pagina(diretos, prefixos)


@pytest.fixture
def bucket(monkeypatch) -> _Bucket:
    b = _Bucket("mvp-ed1-gcp-livro")
    monkeypatch.setattr(livro_gcs, "_cliente", lambda: _Cliente(b))
    return b


BASE = {"kind": "baseline", "format": ledger.FORMAT, "x": 1}
AGORA = dt.datetime(2026, 11, 7, 12, 0, tzinfo=dt.timezone.utc)


def test_o_lugar_se_comporta_como_o_caminho_que_os_chamadores_usam():
    raiz = Lugar.de("gs://b/livro/prod/")
    assert str(raiz) == "gs://b/livro/prod" and raiz.name == "prod"
    registro = raiz / "epoch_0001_x" / "r.json"
    assert registro.name == "r.json" and str(registro.parent) == "gs://b/livro/prod/epoch_0001_x"
    assert str(Lugar.de("gs://b") / "e") == "gs://b/e"
    with pytest.raises(livro_gcs.LivroGcsError):
        Lugar.de("gs://")


def test_a_raiz_gs_exige_o_bucket(bucket):
    assert ledger.root({ledger.ENV: "gs://mvp-ed1-gcp-livro/livro"}) == Lugar("mvp-ed1-gcp-livro", "livro")
    bucket._existe = False
    with pytest.raises(ledger.LedgerError, match="não existe ou não é legível"):
        ledger.root({ledger.ENV: "gs://mvp-ed1-gcp-livro/livro"})


def test_a_epoca_nasce_com_a_linha_de_base_e_o_registro_nunca_e_substituido(bucket):
    raiz = Lugar("mvp-ed1-gcp-livro", "livro")
    with pytest.raises(ledger.LedgerError, match="nenhuma época"):
        ledger.current_epoch(raiz)
    aberta = ledger.open_epoch(raiz, BASE, agora=AGORA)
    epoca = ledger.current_epoch(raiz)
    assert aberta.path == epoca / ledger.BASELINE and epoca.name == "epoch_0001_20261107T120000Z"
    ledger.publish(epoca, "a.json", {"kind": "attempt", "n": 1})
    with pytest.raises(ledger.LedgerError, match="nunca é substituído"):
        ledger.publish(epoca, "a.json", {"kind": "attempt", "n": 2})
    assert ledger.records(epoca) == [{"kind": "attempt", "n": 1}, BASE]


def test_epoca_sem_linha_de_base_nao_conta(bucket):
    raiz = Lugar("mvp-ed1-gcp-livro", "livro")
    ledger.open_epoch(raiz, BASE, agora=AGORA)
    # Uma segunda época que só tem um registro solto — a abertura caiu antes da linha de base.
    bucket.objetos["livro/epoch_0002_20261107T130000Z/solto.json"] = b"{}"
    assert ledger.current_epoch(raiz).name == "epoch_0001_20261107T120000Z"
    # A seguinte pula o número da que não chegou a ter linha de base, como no disco.
    assert ledger.open_epoch(raiz, BASE, agora=AGORA).path.parent.name.startswith("epoch_0003_")


def test_a_prova_de_escrita_nao_deixa_objeto(bucket):
    raiz = Lugar("mvp-ed1-gcp-livro", "livro")
    ledger.open_epoch(raiz, BASE, agora=AGORA)
    antes = dict(bucket.objetos)
    assert ledger.writable_epoch({ledger.ENV: "gs://mvp-ed1-gcp-livro/livro"}).name.startswith("epoch_0001")
    assert bucket.objetos == antes
    bucket._pode_criar = False
    with pytest.raises(PermissionError):
        ledger.writable_epoch({ledger.ENV: "gs://mvp-ed1-gcp-livro/livro"})


def test_o_mesmo_roteiro_da_o_mesmo_livro_no_disco_e_no_bucket(bucket, tmp_path):
    """O contrato, não a implementação: abrir, publicar, recusar a repetição, ler — igual nos dois."""
    def roteiro(raiz):
        ledger.open_epoch(raiz, BASE, agora=AGORA)
        epoca = ledger.current_epoch(raiz)
        for n in (2, 1, 3):
            ledger.publish(epoca, f"r{n}.json", {"kind": "attempt", "n": n})
        recusas = 0
        try:
            ledger.publish(epoca, "r1.json", {"kind": "attempt", "n": 9})
        except ledger.LedgerError:
            recusas += 1
        for invalido in ("x/y.json", ".oculto.json", "sem_extensao"):
            try:
                ledger.publish(epoca, invalido, {})
            except ledger.LedgerError:
                recusas += 1
        return epoca.name, ledger.records(epoca), recusas

    assert roteiro(tmp_path) == roteiro(Lugar("mvp-ed1-gcp-livro", "livro"))


@pytest.mark.skipif(os.environ.get("GCP_TESTES") != "1", reason="só com GCP_TESTES=1 (Cloud Storage real)")
def test_no_cloud_storage_de_verdade_a_repeticao_e_recusada():
    """Contra o *bucket* do livro do Terraform (`<projeto>-livro`). Os objetos ficam: a retenção do
    *bucket* (D70) não deixa apagar antes do prazo, e o desmonte tira a retenção antes do `destroy`."""
    livro_gcs._cliente.cache_clear()
    raiz = Lugar(f"{os.environ['GCP_PROJECT_ID']}-livro", f"testes/{uuid.uuid4().hex}")
    ledger.open_epoch(raiz, BASE, agora=AGORA)
    epoca = ledger.current_epoch(raiz)
    ledger.publish(epoca, "a.json", {"kind": "attempt"})
    with pytest.raises(ledger.LedgerError, match="nunca é substituído"):
        ledger.publish(epoca, "a.json", {"kind": "outro"})
    assert ledger.records(epoca) == [{"kind": "attempt"}, BASE]
    ledger.probe_writable(epoca)
