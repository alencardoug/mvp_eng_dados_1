"""Linha de comando da origem legada — o que o Makefile chama.

Como o gerador da origem principal, nenhuma credencial vem por argumento: a
conexão sai do ambiente, carregado do `.env` (regra inviolável 1).

    plan   mostra o que seria gerado e injetado, sem tocar no banco
    seed   gera, injeta, carrega em `legacy_db` e escreve o manifesto
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import sys

import yaml
from sqlalchemy import create_engine

from mvp_ed1.db import LEGACY, database_url
from mvp_ed1.generator import pipeline
from mvp_ed1.generator.config import carregar as carregar_config
from mvp_ed1.generator.engine import Motor
from mvp_ed1.legacy import injetor, writer
from mvp_ed1.legacy.catalogo import CAMINHO, carregar

#: Fora do Git: o manifesto é evidência de teste, não artefato versionado.
MANIFESTO = pathlib.Path("data/legacy/manifesto.json")


def _promessas() -> frozenset[str]:
    return frozenset(yaml.safe_load(CAMINHO.read_text(encoding="utf-8"))["promessas"])


def _gerar():
    catalogo = carregar()
    motor = Motor(carregar_config(), seed=catalogo.semente, as_of_date=None, fator=catalogo.fator)
    dataset = pipeline.gerar(motor)
    dados = {tabela: dataset[tabela] for tabela in dataset}
    resultado = injetor.injetar(
        catalogo, dados, promessas=_promessas(), as_of=motor.as_of_date
    )
    return catalogo, resultado


def _catalogo(catalogo) -> None:
    """Imprime o catálogo em português, para revisão sem abrir o YAML.

    A revisão que importa aqui não é de sintaxe: é decidir se **converter ou
    rejeitar** está certo em cada linha. Quem decide isso é o Owner
    (`CLAUDE.md` §5), e ele não deve precisar ler YAML para fazê-lo.
    """
    print(f"Catálogo de falhas v{catalogo.versao} — {len(catalogo.falhas)} tipos\n")
    print(f"{'CÓDIGO':22} {'COMO SE RECONHECE':44} {'DECISÃO':10} {'QUANTOS':>7}")
    print("-" * 88)
    for falha in catalogo.falhas.values():
        decisao = "converter" if falha.converte else "REJEITAR"
        texto = falha.deteccao if len(falha.deteccao) <= 44 else falha.deteccao[:42] + ".."
        print(f"{falha.codigo:22} {texto:44} {decisao:10} "
              f"{falha.frequencia if falha.frequencia else '—':>7}")
    print("-" * 88)
    print(f"{'':22} {'':44} {'total':10} {catalogo.registros_falhos_planejados:>7}\n")
    print("Converter é para quando existe **uma** interpretação possível; rejeitar,")
    print("quando existe mais de uma. O critério está em docs/origem_legada.md §3.1.")


def _resumo(catalogo, resultado) -> None:
    por_codigo = collections.Counter(a.codigo for a in resultado.achados)
    veredito = collections.Counter(resultado.resultado_por_ocorrencia().values())
    linhas = sum(len(v) for v in resultado.linhas.values())

    print(f"catálogo v{catalogo.versao} · semente {catalogo.semente} · fator {catalogo.fator}")
    print(f"{len(resultado.linhas)} tabelas · {linhas:,} linhas".replace(",", "."))
    print(f"{len(resultado.achados)} achados em {sum(veredito.values())} ocorrências")
    for resultado_esperado, quantidade in sorted(veredito.items()):
        print(f"  {resultado_esperado:<10} {quantidade:>4}")

    ausentes = [f.codigo for f in catalogo.injetaveis if f.codigo not in por_codigo]
    print(f"cobertura: {len(por_codigo)}/{len(catalogo.injetaveis)} códigos injetáveis")
    if ausentes:
        print("SEM COBERTURA: " + ", ".join(ausentes))
        sys.exit(1)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m mvp_ed1.legacy.cli",
        description="Gerador da origem legada com injeção declarativa de falhas (Etapa 10).",
    )
    sub = parser.add_subparsers(dest="comando", required=True)
    sub.add_parser("plan")
    sub.add_parser("catalogo")
    sub.add_parser("models")
    semear = sub.add_parser("seed")
    semear.add_argument("--force", action="store_true", help="trunca o legado antes de carregar")
    args = parser.parse_args(argv)

    if args.comando == "catalogo":
        _catalogo(carregar())
        return 0

    if args.comando == "models":
        from mvp_ed1.legacy import dbt
        from mvp_ed1.legacy import classification
        from mvp_ed1.legacy import ponte

        catalogo = carregar()
        escritos = dbt.gerar(catalogo, _promessas())
        fontes = dbt.DESTINO / "_legacy__sources.yml"
        fontes.write_text(dbt.sources_yml(), encoding="utf-8")
        escritos.extend(classification.generate(catalogo))
        escritos.extend(ponte.gerar())
        escritos.extend(ponte.gerar_testes())
        print(f"{len(escritos)} modelos e a declaração de fontes em {dbt.DESTINO}/")
        return 0

    catalogo, resultado = _gerar()
    _resumo(catalogo, resultado)

    if args.comando == "plan":
        return 0

    engine = create_engine(database_url(LEGACY))
    try:
        medida = writer.escrever(engine, resultado, forcar=args.force)
    except writer.DestinoNaoVazio as erro:
        print(f"\n{erro}", file=sys.stderr)
        return 1
    caminho = writer.gravar_manifesto(resultado, MANIFESTO)
    print(f"\ncarregado: {medida['linhas']:,} linhas em {medida['segundos']} s".replace(",", "."))
    print(f"manifesto: {caminho}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
