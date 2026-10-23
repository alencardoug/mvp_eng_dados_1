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
    ],
    ids=["so-usuario", "so-senha", "papel", "superusuario", "nome-estranho", "senha-curta", "senha-com-aspas"],
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
