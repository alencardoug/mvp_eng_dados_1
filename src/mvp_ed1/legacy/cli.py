"""Linha de comando da origem legada — o que o Makefile chama.

Como o gerador da origem principal, nenhuma credencial vem por argumento: a
conexão sai do ambiente, carregado do `.env` (regra inviolável 1).

    plan       mostra o que seria gerado e injetado, sem tocar no banco
    manifesto  recalcula o manifesto do lote determinístico, sem tocar no banco
    seed       gera, injeta, carrega em `legacy_db` e escreve o manifesto
    remover    apaga linhas de negócio por chave e grava no diário o que o banco devolveu
    inserir    insere uma linha de negócio (JSON) e grava o que o banco devolveu
    alterar    altera uma célula de uma linha de negócio e grava antes e depois
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

#: Fora do Git: o manifesto é evidência de teste, não artefato versionado. O
#: diretório guarda um arquivo por lote (`manifesto-<hash>.json`) e o *link*
#: `manifesto.json` para o corrente.
MANIFESTOS = pathlib.Path("data/legacy")
MANIFESTO = MANIFESTOS / "manifesto.json"


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
    # Os parâmetros **efetivos** viajam com o manifesto: são eles, e não a
    # intenção, que identificam o lote junto com o hash de conteúdo.
    parametros = {
        "semente": catalogo.semente,
        "fator": catalogo.fator,
        "as_of": motor.as_of_date.isoformat(),
        "limite_de_texto": catalogo.limite_de_texto,
    }
    return catalogo, resultado, parametros


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
    cobertos = len(catalogo.injetaveis) - len(ausentes)
    print(f"cobertura: {cobertos}/{len(catalogo.injetaveis)} códigos injetáveis")
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
    sub.add_parser("manifesto", help="recalcula o manifesto do lote determinístico, sem banco")
    semear = sub.add_parser("seed")
    semear.add_argument("--force", action="store_true", help="trunca o legado antes de carregar")
    remover = sub.add_parser("remover", help="apaga linhas de negócio e grava o diário (ADR-0045)")
    remover.add_argument("--tabela", required=True)
    remover.add_argument("--chaves", nargs="*", help="chaves de negócio explícitas")
    remover.add_argument("--quantidade", type=int, help="N ocorrências aptas, escolhidas pelo oráculo")
    inserir = sub.add_parser("inserir", help="insere uma linha de negócio e grava o diário")
    inserir.add_argument("--tabela", required=True)
    inserir.add_argument("--valores", required=True, help='JSON com as colunas, ex. \'{"id": "9001", "code": "b9001"}\'')
    alterar = sub.add_parser("alterar", help="altera uma célula de uma linha e grava o diário")
    alterar.add_argument("--tabela", required=True)
    alterar.add_argument("--chave", required=True, help="valor da chave de negócio")
    alterar.add_argument("--coluna", required=True)
    alterar.add_argument("--valor", help="novo valor; omitido = nulo")
    args = parser.parse_args(argv)

    if args.comando in ("remover", "inserir", "alterar"):
        import json

        from mvp_ed1.legacy import mutacoes

        engine = create_engine(database_url(LEGACY))
        if args.comando == "remover":
            registro = mutacoes.remover(engine, args.tabela, chaves=args.chaves, quantidade=args.quantidade)
            print(f"removidas {registro['linhas_apagadas']} linhas de {args.tabela} ({registro['chave']} in {registro['chaves']}); "
                  f"restantes após commit: {registro['restantes_apos_commit']}")
        elif args.comando == "inserir":
            registro = mutacoes.inserir(engine, args.tabela, json.loads(args.valores))
            print(f"inserida em {args.tabela}: legacy_row_id {registro['devolvida']['legacy_row_id']}")
        else:
            registro = mutacoes.alterar(engine, args.tabela, args.chave, args.coluna, args.valor)
            print(f"alteradas {len(registro['devolvidas'])} linhas de {args.tabela}.{args.coluna} onde {registro['chave']} = {args.chave}")
        print(f"hash de {args.tabela}: {registro['hash_antes']['hash'][:12]} → {registro['hash_depois']['hash'][:12]}; diário atualizado")
        return 0 if "erro" not in registro else 1

    if args.comando == "catalogo":
        _catalogo(carregar())
        return 0

    if args.comando == "models":
        from mvp_ed1.legacy import dbt
        from mvp_ed1.legacy import classification
        from mvp_ed1.legacy import ponte
        from mvp_ed1.legacy import schema

        catalogo = carregar()
        promessas = _promessas()
        escritos = dbt.gerar(catalogo, promessas)
        fontes = dbt.DESTINO / "_legacy__sources.yml"
        fontes.write_text(dbt.sources_yml(), encoding="utf-8")
        # A guarda leva os mesmos parâmetros que entraram na impressão digital:
        # quem decide quais variáveis contam é `parametros_do_tratamento`, e uma
        # vez só — listar de novo aqui seria a segunda lista que diverge.
        limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
        material = [dbt.modelo(catalogo, t, promessas, limites) for t in schema.tabelas()]
        material.append(classification.records_sql())
        material.append(classification.classification_sql(catalogo))
        escritos.extend(
            classification.generate(
                catalogo,
                fingerprint=dbt.impressao_digital(catalogo, promessas),
                parametros=dbt.parametros_do_tratamento(material),
            )
        )
        escritos.extend(ponte.gerar())
        escritos.extend(ponte.gerar_testes())
        from mvp_ed1.legacy import remocao

        escritos.extend(remocao.gerar())
        print(f"{len(escritos)} modelos e a declaração de fontes em {dbt.DESTINO}/")
        return 0

    catalogo, resultado, parametros = _gerar()
    _resumo(catalogo, resultado)

    if args.comando == "plan":
        return 0

    if args.comando == "manifesto":
        caminho = writer.gravar_manifesto(catalogo, resultado, parametros, MANIFESTOS)
        print(f"\nmanifesto: {caminho} (nenhum banco foi tocado)")
        return 0

    engine = create_engine(database_url(LEGACY))
    try:
        medida = writer.escrever(engine, resultado, forcar=args.force)
    except writer.DestinoNaoVazio as erro:
        print(f"\n{erro}", file=sys.stderr)
        return 1
    caminho = writer.gravar_manifesto(catalogo, resultado, parametros, MANIFESTOS)
    print(
        f"\ncarregado: {medida['linhas']:,} linhas em {medida['segundos']} s; "
        "conteúdo conferido por hash".replace(",", ".")
    )
    print(f"manifesto: {caminho}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
