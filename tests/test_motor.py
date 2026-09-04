"""O motor — as garantias que ele dá independentemente do domínio."""

from __future__ import annotations

import datetime as dt

import pytest

from mvp_ed1.generator import enums
from mvp_ed1.generator.config import Config
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import Fonte, cobrir, repartir


@pytest.fixture(scope="module")
def fonte() -> Fonte:
    return Fonte(7, dt.date(2026, 9, 1), "teste", "pt_BR")


@pytest.mark.parametrize(
    "total,grupos,minimo,maximo",
    [(110000, 40000, 1, 6), (7500, 3500, 1, 5), (1520, 380, 1, None), (3, 10, 1, 2)],
)
def test_reparticao_soma_exatamente_o_total(fonte, total, grupos, minimo, maximo) -> None:
    """Sortear um tamanho por grupo erraria a soma por construção."""
    parcelas = repartir(total, grupos, fonte, minimo, maximo)
    assert sum(parcelas) == total
    assert len(parcelas) == grupos


def test_reparticao_respeita_o_teto_quando_ele_cabe(fonte) -> None:
    parcelas = repartir(1000, 500, fonte, minimo=1, maximo=4)
    assert max(parcelas) <= 4 and min(parcelas) >= 1


def test_cobertura_insere_o_que_faltava(fonte) -> None:
    coberta = cobrir(["a"] * 10, ("a", "b", "c"))
    assert set(coberta) == {"a", "b", "c"}
    assert len(coberta) == 10


def test_cobertura_nao_inventa_linha_quando_nao_ha_espaco(fonte) -> None:
    assert cobrir(["a", "a"], ("a", "b", "c")) == ["a", "a"]


def test_colunas_gravaveis_excluem_o_que_o_banco_gera(config: Config) -> None:
    """`GENERATED ALWAYS` não entra no `COPY` — é erro, não escolha."""
    movimentos = Motor.colunas_gravaveis("inventory_movements")
    assert "event_sequence" not in movimentos
    assert "movement_id" in movimentos
    assert "quantity_available" not in Motor.colunas_gravaveis("inventory_balances")
    assert "quantity_on_hand" in Motor.colunas_gravaveis("inventory_balances")


def test_motor_recusa_chave_estrangeira_obrigatoria_ausente(config: Config) -> None:
    """Seguir adiante aqui daria um `COPY` recusado sem dizer de que linha veio."""
    motor = Motor(config)
    with pytest.raises(ValueError, match="chave estrangeira obrigatória"):
        motor.preencher("orders", [{}])


def test_motor_nunca_sobrescreve_o_que_o_construtor_definiu(config: Config) -> None:
    motor = Motor(config)
    linha = motor.preencher("brands", [{"name": "Marca fixa", "code": "BRD-XYZ"}])[0]
    assert linha["name"] == "Marca fixa"
    assert linha["code"] == "BRD-XYZ"


def test_motor_corta_texto_no_tamanho_do_modelo(config: Config) -> None:
    """`varchar(2)` que recebe 40 caracteres é execução perdida no fim da carga."""
    motor = Motor(config)
    for linha in motor.preencher("customer_addresses", [{"customer_id": 1} for _ in range(20)]):
        assert len(linha["state"]) <= 2
        assert len(linha["city"]) <= 80


def test_primeiras_linhas_cobrem_a_enumeracao_do_modelo(config: Config) -> None:
    """Cobertura por construção, não por sorte — a garantia central do piso."""
    motor = Motor(config)
    aceitos = enums.valores("customers", "status")
    linhas = motor.preencher("customers", [{"segment_id": None} for _ in range(len(aceitos))])
    assert [linha["status"] for linha in linhas] == list(aceitos)


def test_created_at_acompanha_o_tempo_de_negocio(config: Config) -> None:
    """`updated_at` só serve de cursor incremental se não for ruído (ADR-0015)."""
    motor = Motor(config)
    linha = motor.preencher("orders", [{
        "customer_id": 1, "sales_channel_id": 1, "cart_id": None,
        "placed_at": motor.inicio, "subtotal_amount": 10, "discount_amount": 0,
        "shipping_amount": 0, "tax_amount": 0, "total_amount": 10, "status": "pending",
    }])[0]
    assert linha["created_at"] == motor.inicio
    assert linha["updated_at"] >= linha["created_at"]


def test_exclusao_logica_nao_marca_toda_linha(config: Config) -> None:
    motor = Motor(config)
    linhas = motor.preencher("brands", [{} for _ in range(200)])
    excluidas = sum(1 for linha in linhas if linha["deleted_at"] is not None)
    assert excluidas < len(linhas) * 0.1


def test_nenhum_evento_ocorre_depois_do_corte(config: Config, dados) -> None:
    """`as_of_date` é o "hoje" da simulação; evento no futuro é absurdo silencioso."""
    for movimento in dados["inventory_movements"]:
        assert movimento["occurred_at"] <= motor_fim(config)
    for pedido in dados["orders"]:
        assert pedido["placed_at"] <= motor_fim(config)


def motor_fim(config: Config) -> dt.datetime:
    return Motor(config).fim
