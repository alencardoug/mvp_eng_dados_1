"""A interface do Airbyte do GKE por port-forward, sem deixar o token para trás (Registro §55)."""

from __future__ import annotations

import pathlib

MAKEFILE = (pathlib.Path(__file__).resolve().parent.parent / "Makefile").read_text(encoding="utf-8")


def test_o_alvo_abre_a_interface_pelo_server_e_limpa_no_ctrl_c():
    ui = MAKEFILE.split("\ngcp-airbyte-ui:", 1)[1].split("\n\n", 1)[0]
    # Airbyte 1.x: a interface sai do próprio airbyte-server; não há Service `webapp`.
    assert "port-forward service/airbyte-airbyte-server-svc" in ui and "webapp" not in ui
    # O kubeconfig com o token fica na pasta do GCP_LIMPEZA; o Ctrl+C precisa chegar ao trap.
    assert "$(GCP_LIMPEZA)" in ui and "trap 'exit 130' INT TERM" in ui and "wait $$encaminhamento" in ui
    # A 8000 é do Airbyte local (abctl): a porta da interface do GKE é outra, e conferida livre.
    assert "\nGCP_AIRBYTE_UI_PORTA ?= 18080\n" in MAKEFILE and "GCP_PORTA_LIVRE,$(GCP_AIRBYTE_UI_PORTA)" in ui
