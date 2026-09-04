"""Ordem de geração.

A sequência é a de Geração de Dados §3, e ela não é preferência: é a ordem em
que os fatos acontecem. Referência antes de entidade, entidade antes de evento,
evento antes de estado derivado. Inverter dois passos aqui não produz erro de
sintaxe — produz um pedido que aponta para um carrinho que ainda não existe.

O `Dataset` recusa gerar a mesma tabela duas vezes e recusa ler uma que ainda
não foi gerada. É o que transforma "ordem errada" em falha imediata e legível.
"""

from __future__ import annotations

import time
from typing import Callable

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.domains import (
    atendimento,
    catalogo,
    clientes,
    compras,
    estoque,
    logistica,
    marketing,
    pagamentos,
    vendas,
)
from mvp_ed1.generator.engine import Motor

Passo = tuple[str, Callable[[Motor, Dataset], None]]

#: Cada passo pode produzir mais de uma tabela — as que nascem juntas.
PASSOS: tuple[Passo, ...] = (
    # 1. Dados de referência.
    ("clientes: segmentos", clientes.segmentos),
    ("vendas: canais", vendas.canais),
    ("pagamentos: meios", pagamentos.meios),
    ("estoque: armazéns", estoque.armazens),
    ("logística: transportadoras", logistica.transportadoras),
    ("catálogo: categorias", catalogo.categorias),
    ("catálogo: marcas", catalogo.marcas),
    # 2. Entidades mestres.
    ("clientes: cadastro", clientes.cadastro),
    ("catálogo: produtos e SKUs", catalogo.produtos),
    ("compras: fornecedores", compras.fornecedores),
    ("atendimento: agentes", atendimento.agentes),
    # 3. Preços, campanhas e cupons.
    ("catálogo: preços", catalogo.precos),
    ("marketing: campanhas e cupons", marketing.campanhas),
    # 4. Compras e formação do estoque.
    ("compras: ordens e recebimentos", compras.ordens),
    # 5. Carrinhos e pedidos.
    ("vendas: carrinhos", vendas.carrinhos),
    ("vendas: pedidos", vendas.pedidos),
    ("marketing: resgates", marketing.resgates),
    # 6. Pagamentos e remessas.
    ("pagamentos: fluxo financeiro", pagamentos.fluxo),
    ("logística: remessas e entregas", logistica.remessas),
    # 7. Livro de estoque, reservas e saldo — depende de tudo que o move.
    ("estoque: livro, reservas e saldo", estoque.livro),
    # 8. Atendimento, pendurado nos fatos já existentes.
    ("atendimento: chamados", atendimento.chamados),
)


def gerar(motor: Motor, *, progresso: Callable[[str, float, int], None] | None = None) -> Dataset:
    """Executa os passos em ordem e devolve o conjunto completo."""
    dados = Dataset()
    for nome, passo in PASSOS:
        marca = time.perf_counter()
        antes = dados.total
        passo(motor, dados)
        if progresso:
            progresso(nome, time.perf_counter() - marca, dados.total - antes)
    return dados
