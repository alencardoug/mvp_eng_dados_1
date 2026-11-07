"""O Debezium Server da fase GCP, gerado da declaração do conector local (Etapa 13, G2.3; D78)."""

from __future__ import annotations

from mvp_ed1.streaming.config import carregar


def test_o_application_properties_esta_em_dia_com_a_declaracao_do_conector():
    from mvp_ed1.streaming import debezium_server

    assert debezium_server.main(["--conferir"]) == 0, "rode python -m mvp_ed1.streaming.debezium_server"


def test_o_debezium_server_leva_o_conector_local_e_a_d78():
    import yaml

    from mvp_ed1.streaming import debezium_server

    texto = debezium_server.gerar()
    propriedades = dict(l.split("=", 1) for l in texto.splitlines() if l and not l.startswith("#"))
    local = yaml.safe_load(debezium_server.DECLARACAO.read_text(encoding="utf-8"))["config"]
    for chave, valor in local.items():
        if chave.startswith("topic.creation.") or chave == "database.hostname":
            assert f"debezium.source.{chave}" not in propriedades or chave == "database.hostname"
            continue
        assert propriedades[f"debezium.source.{chave}"] == str(valor), chave
    assert propriedades["debezium.transforms.unwrap.add.fields"] == "op,lsn"
    assert propriedades["debezium.transforms.tempo.headers"] == carregar().nuvem.atributo_de_tempo
    assert propriedades["debezium.format.header.schemas.enable"] == "false"


def test_o_topico_de_heartbeat_do_gerador_existe_no_terraform():
    from pathlib import Path

    from mvp_ed1.streaming import debezium_server

    prefixo = debezium_server.SOBREPOSTO["topic.heartbeat.prefix"][0]
    topico = f"{prefixo}.{yaml_prefixo()}"
    assert f'"{topico}"' in Path("terraform/armazenamento.tf").read_text(encoding="utf-8")


def yaml_prefixo() -> str:
    import yaml

    from mvp_ed1.streaming import debezium_server

    return yaml.safe_load(debezium_server.DECLARACAO.read_text(encoding="utf-8"))["config"]["topic.prefix"]
