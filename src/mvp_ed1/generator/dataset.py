"""Coleção das linhas geradas, por tabela.

Existe para que os construtores conversem entre si sem passar quinze listas de
mão em mão: o construtor de pagamentos precisa dos pedidos, o de estoque
precisa das remessas e dos recebimentos. Todos leem daqui.

Campos auxiliares — os que começam com `__` — viajam junto com a linha durante
a geração e **não** são gravados: `colunas_gravaveis` é quem decide o que vai
ao banco, e ela sai dos modelos.
"""

from __future__ import annotations

import hashlib
from typing import Any, Iterator

Linha = dict[str, Any]


class Dataset:
    def __init__(self) -> None:
        self._tabelas: dict[str, list[Linha]] = {}

    def guardar(self, tabela: str, linhas: list[Linha]) -> list[Linha]:
        if tabela in self._tabelas:
            raise ValueError(f"{tabela}: gerada duas vezes — cada tabela tem um só construtor")
        self._tabelas[tabela] = linhas
        return linhas

    def __getitem__(self, tabela: str) -> list[Linha]:
        try:
            return self._tabelas[tabela]
        except KeyError as erro:
            geradas = ", ".join(self._tabelas) or "nenhuma"
            raise KeyError(
                f"{tabela} ainda não foi gerada — a ordem do pipeline está errada. "
                f"Geradas até aqui: {geradas}"
            ) from erro

    def __contains__(self, tabela: str) -> bool:
        return tabela in self._tabelas

    def __iter__(self) -> Iterator[str]:
        return iter(self._tabelas)

    def contagens(self) -> dict[str, int]:
        return {tabela: len(linhas) for tabela, linhas in self._tabelas.items()}

    @property
    def total(self) -> int:
        return sum(len(linhas) for linhas in self._tabelas.values())

    def impressao_digital(self) -> str:
        """Resumo de 64 caracteres do conteúdo gravável, na ordem de gravação.

        É como "a mesma `seed` produz exatamente os mesmos dados" deixa de ser
        afirmação e vira comparação de duas execuções. Só o que vai ao banco
        entra na conta: campo auxiliar muda de forma sem mudar o resultado.
        """
        from mvp_ed1.generator.engine import Motor  # importação tardia: evita ciclo

        resumo = hashlib.sha256()
        for tabela in sorted(self._tabelas):
            colunas = Motor.colunas_gravaveis(tabela)
            resumo.update(f"\n#{tabela}:{len(self._tabelas[tabela])}".encode())
            for linha in self._tabelas[tabela]:
                resumo.update(
                    "\x1f".join(str(linha[coluna]) for coluna in colunas).encode()
                )
        return resumo.hexdigest()
