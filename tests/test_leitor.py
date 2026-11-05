"""O login de leitura sem banco: o que o `.env` pode declarar e o verificador da senha.

A prova de acesso — conexão de verdade, lê `consumption`, não escreve, não
escala — está em `tests/test_acesso.py`; aqui fica o que se confere sem nada de pé.
"""

from __future__ import annotations

import base64
import hashlib
import hmac

import pytest

from mvp_ed1 import governance as g

SENHA = "A" * 12 + "b" * 12 + "0" * 8


def test_sem_as_duas_chaves_nao_ha_login() -> None:
    assert g.leitor_do_ambiente({}) is None


def test_as_duas_chaves_dao_o_login() -> None:
    ambiente = {g.LEITOR_USUARIO: "consumption_reader", g.LEITOR_SENHA: SENHA}
    assert g.leitor_do_ambiente(ambiente) == ("consumption_reader", SENHA)


@pytest.mark.parametrize(
    "ambiente",
    [
        {g.LEITOR_USUARIO: "consumption_reader"},
        {g.LEITOR_SENHA: SENHA},
        {g.LEITOR_USUARIO: "analyst", g.LEITOR_SENHA: SENHA},
        {g.LEITOR_USUARIO: "mvp_warehouse", g.LEITOR_SENHA: SENHA, "WAREHOUSE_DB_USER": "mvp_warehouse"},
        {g.LEITOR_USUARIO: "Leitor; drop role x", g.LEITOR_SENHA: SENHA},
        {g.LEITOR_USUARIO: "consumption_reader", g.LEITOR_SENHA: "curta123"},
        {g.LEITOR_USUARIO: "consumption_reader", g.LEITOR_SENHA: "x' or '1" + "a" * 30},
        {g.LEITOR_USUARIO: "reader\n", g.LEITOR_SENHA: SENHA},           # RVL2-02: `$` aceitava
        {g.LEITOR_USUARIO: "consumption_reader", g.LEITOR_SENHA: SENHA + "\n"},
    ],
    ids=["so-usuario", "so-senha", "papel", "superusuario", "nome-estranho", "senha-curta", "senha-com-aspas",
         "nome-com-quebra", "senha-com-quebra"],
)
def test_declaracao_incompleta_ou_perigosa_e_recusada(ambiente) -> None:
    with pytest.raises(RuntimeError):
        g.leitor_do_ambiente(ambiente)


def test_o_verificador_e_o_scram_da_senha_e_nao_a_contem() -> None:
    """Recalculado à parte (RFC 5802): a chave guardada confere com a senha e o sal do próprio verificador."""
    verificador = g._verificador_scram(SENHA)
    assert SENHA not in verificador
    metodo, resto = verificador.split("$", 1)
    iteracoes_e_sal, chaves = resto.split("$")
    iteracoes, sal = iteracoes_e_sal.split(":")
    guardada, servidor = chaves.split(":")
    assert metodo == "SCRAM-SHA-256" and int(iteracoes) == 4096
    salgada = hashlib.pbkdf2_hmac("sha256", SENHA.encode(), base64.b64decode(sal), int(iteracoes))
    cliente = hmac.new(salgada, b"Client Key", hashlib.sha256).digest()
    assert base64.b64decode(guardada) == hashlib.sha256(cliente).digest()
    assert base64.b64decode(servidor) == hmac.new(salgada, b"Server Key", hashlib.sha256).digest()
    assert g._verificador_scram(SENHA) != verificador, "o sal é novo a cada chamada"


def test_as_funcoes_fechadas_a_public_sao_as_que_escrevem_ou_tomam_lock() -> None:
    """RVL2-01: criar e escrever *large object*, e tomar *advisory lock* — nunca ler nem soltar.

    RVL2-2-01: e gravar mensagem no WAL."""
    fechadas = set(g.FECHADAS_A_PUBLIC)
    assert {"lo_create", "lo_creat", "lo_from_bytea", "lowrite", "lo_put", "lo_unlink"} <= fechadas
    assert {"pg_advisory_lock", "pg_try_advisory_lock", "pg_advisory_xact_lock"} <= fechadas
    assert "pg_logical_emit_message" in fechadas
    assert not {n for n in fechadas if "unlock" in n or n in ("lo_get", "loread", "lo_close")}
    assert len(fechadas) == len(g.FECHADAS_A_PUBLIC)


def test_nada_do_catalogo_entra_em_texto_python() -> None:
    """RVL2-02: os papéis de que o login é membro e o nome do banco se compõem no servidor.

    O dublê responde ao que se pergunta do catálogo com um nome que fecharia o
    identificador; o SQL emitido não o contém, porque ninguém o pergunta."""
    perigoso = 'x" from consumption_reader; alter role analyst superuser; --'
    emitidos: list[str] = []

    class Dublê:
        def execute(self, sql, p=None):
            emitidos.append(str(sql))
            return self

        def exec_driver_sql(self, sql):
            emitidos.append("<alter role com o verificador>")

        def scalars(self):
            return self

        def all(self):
            return [perigoso, *g.FECHADAS_A_PUBLIC]

        def scalar_one(self):
            return perigoso

    g._garantir_leitor(Dublê(), "consumption_reader", SENHA)
    assert not [s for s in emitidos if "alter role analyst" in s]
    assert any("format('revoke %I from %I'" in s for s in emitidos)
    assert any("format('revoke temporary on database %I from public', current_database())" in s for s in emitidos)
