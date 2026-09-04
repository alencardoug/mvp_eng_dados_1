"""Linha de comando do gerador — o que os alvos do Makefile chamam.

Três verbos, e nenhum deles aceita credencial por argumento: a conexão vem do
ambiente, carregado pelo `Makefile` a partir do `.env` (regra inviolável 1).

    plan          mostra o plano de volume sem tocar no banco
    seed          gera e carrega em `source_db`
    size-report   mede o que existe no banco, sem gerar nada
"""

from __future__ import annotations

import argparse
import datetime as dt
import sys
import time

from sqlalchemy import create_engine

from mvp_ed1.db import BANCOS, database_url
from mvp_ed1.generator import pipeline, report
from mvp_ed1.generator.config import Config, carregar
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.writer import DestinoNaoVazio, escrever


def _argumentos() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m mvp_ed1.generator.cli",
        description="Gerador de dados sintéticos da origem transacional (Etapa 4).",
    )
    sub = parser.add_subparsers(dest="comando", required=True)

    for nome in ("plan", "seed"):
        alvo = sub.add_parser(nome)
        alvo.add_argument("--seed", type=int, default=None, help="semente; padrão vem do YAML")
        alvo.add_argument("--as-of", type=_data, default=None, help="data de corte AAAA-MM-DD")
        alvo.add_argument("--scale", default=None, help="fator de escala declarado; padrão `dev`")
    sub.choices["seed"].add_argument(
        "--force", action="store_true", help="trunca as 40 tabelas antes de carregar"
    )
    sub.choices["seed"].add_argument(
        "--dry-run", action="store_true", help="gera e mede, sem escrever no banco"
    )
    sub.add_parser("size-report")
    return parser


def _data(texto: str) -> dt.date:
    return dt.date.fromisoformat(texto)


def _motor(args, config: Config) -> Motor:
    return Motor(config, seed=args.seed, as_of_date=args.as_of, fator=args.scale)


def plan(args, config: Config) -> int:
    motor = _motor(args, config)
    print(f"semente {motor.seed} · as_of {motor.as_of_date} · fator {args.scale or config.fator_padrao}")
    print(f"{'tabela':<28}{'linhas':>10}{'piso':>8}  origem")
    total = 0
    for tabela, linhas in config.plano(args.scale).items():
        spec = config.tabelas[tabela]
        print(f"{tabela:<28}{linhas:>10,}{spec.piso:>8}  {spec.origem}")
        total += linhas
    print(f"{'TOTAL':<28}{total:>10,}")
    return 0


def seed(args, config: Config) -> int:
    motor = _motor(args, config)
    print(
        f"gerando · semente {motor.seed} · as_of {motor.as_of_date} · "
        f"fator {args.scale or config.fator_padrao}"
    )
    marca = time.perf_counter()
    dados = pipeline.gerar(
        motor,
        progresso=lambda nome, seg, linhas: print(f"  {nome:<34}{seg:>7.2f}s {linhas:>9,} linhas"),
    )
    geracao = time.perf_counter() - marca
    print(f"\ngeradas {dados.total:,} linhas em {geracao:.1f}s")

    if args.dry_run:
        print("--dry-run: nada foi escrito no banco.")
        return 0

    engine = create_engine(database_url(), future=True)
    try:
        resultado = escrever(engine, dados, forcar=args.force)
    except DestinoNaoVazio as erro:
        print(f"\nERRO: {erro}", file=sys.stderr)
        return 2
    finally:
        engine.dispose()
    print(
        f"carregadas {resultado['total']:,} linhas em {resultado['segundos']:.1f}s "
        f"({resultado['total'] / max(resultado['segundos'], 1e-9):,.0f} linhas/s)"
    )
    print(f"tempo total: {geracao + resultado['segundos']:.1f}s")
    return 0


def size_report(args, config: Config) -> int:
    total_geral = 0
    for prefixo in BANCOS:
        engine = create_engine(database_url(prefixo), future=True)
        try:
            tamanho = report.tamanho_do_banco(engine)
            total_geral += tamanho
            print(f"\n{prefixo:<14} {report.formatar(tamanho):>12}")
            linhas = [linha for linha in report.por_tabela(engine) if linha["linhas"]]
            if not linhas:
                print("  (sem tabelas com dados)")
                continue
            print(
                f"  {'tabela':<28}{'linhas':>10}{'dados':>12}{'índices':>12}"
                f"{'total':>12}{'bytes/linha':>13}"
            )
            for linha in linhas:
                por_linha = linha["total_bytes"] / linha["linhas"]
                print(
                    f"  {linha['tabela']:<28}{linha['linhas']:>10,}"
                    f"{report.formatar(linha['dados_bytes']):>12}"
                    f"{report.formatar(linha['indices_bytes']):>12}"
                    f"{report.formatar(linha['total_bytes']):>12}{por_linha:>13,.0f}"
                )
            soma_linhas = sum(linha["linhas"] for linha in linhas)
            soma_bytes = sum(linha["total_bytes"] for linha in linhas)
            print(
                f"  {'TOTAL':<28}{soma_linhas:>10,}{'':>24}"
                f"{report.formatar(soma_bytes):>12}{soma_bytes / soma_linhas:>13,.0f}"
            )
        finally:
            engine.dispose()
    print(f"\nsoma dos três bancos: {report.formatar(total_geral)}")
    print("Tamanho é observação, não limite (ADR-0014).")
    return 0


def main(argv: list[str] | None = None) -> int:
    args = _argumentos().parse_args(argv)
    config = carregar()
    return {"plan": plan, "seed": seed, "size-report": size_report}[args.comando](args, config)


if __name__ == "__main__":
    raise SystemExit(main())
