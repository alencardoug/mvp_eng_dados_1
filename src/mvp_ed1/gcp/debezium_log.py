"""O reinício do *pod* do Debezium Server, decidido pelo log do *pod* novo (Etapa 13, G2.3; RV13J-3-01).

O destino quente não mostra um *snapshot* refeito: o `MERGE` da D75 suprime as linhas repetidas. Só
o log do *pod* novo diz se ele retomou dos *offsets* do disco ou fotografou a tabela de novo. A
decisão aceita só o que se prova, na ordem em que o conector escreve:

1. `Snapshot step 1 - Preparing` em qualquer ponto — o *snapshot* foi refeito: **falha**;
2. `A previous offset indicating a completed snapshot has been found.` **antes** de
   `Starting streaming` — retomou dos *offsets* e passou ao *streaming* sem fotografar: **passa**;
3. `Starting streaming` sem essa frase antes — passou ao *streaming* sem dizer de onde (o
   `No previous offset found` também contém "previous offset", e não é retomada): **inconclusivo**;
4. nada disso ainda — **pendente**: a receita lê o log de novo até o prazo, e no prazo é
   inconclusivo. Só a passagem ao *streaming* encerra a observação: antes dela, o *snapshot* ainda
   pode começar.

As frases são as do conector PostgreSQL **3.6.2.Final** (lidas nos *jars* da imagem
`quay.io/debezium/connect:3.6.2.Final` desta máquina, 08/11/2026); a imagem da janela é a
**3.7.1.Final**, não conferida. Frase que mudou dá inconclusivo, nunca passa.

    python -m mvp_ed1.gcp.debezium_log LOG     # sai 0 passa, 1 falha, 2 inconclusivo, 3 pendente
"""

from __future__ import annotations

import pathlib
import sys

SNAPSHOT = "Snapshot step 1 - Preparing"
RETOMADA = "A previous offset indicating a completed snapshot has been found."
STREAMING = "Starting streaming"

PASSA, FALHA, INCONCLUSIVO, PENDENTE = 0, 1, 2, 3


def veredito(texto: str) -> tuple[int, str]:
    if SNAPSHOT in texto:
        return FALHA, "o pod novo refez o snapshot: os offsets do disco não valeram"
    if STREAMING not in texto:
        return PENDENTE, "o pod novo ainda não passou ao streaming"
    retomada = texto.find(RETOMADA)
    if 0 <= retomada < texto.find(STREAMING):
        return PASSA, "o pod novo retomou dos offsets e passou ao streaming, sem snapshot"
    return INCONCLUSIVO, "o pod novo passou ao streaming sem dizer que retomou de um snapshot completo"


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print("uso: python -m mvp_ed1.gcp.debezium_log LOG", file=sys.stderr)
        return INCONCLUSIVO
    codigo, motivo = veredito(pathlib.Path(argv[0]).read_text(encoding="utf-8", errors="replace"))
    print(motivo)
    return codigo


if __name__ == "__main__":
    sys.exit(main())
