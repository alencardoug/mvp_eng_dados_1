"""Os verbos do ponto único de recuperação.

    python -m mvp_ed1.recovery pack               monta o candidato
    python -m mvp_ed1.recovery verify [--dir X]   confere sem restaurar nada
    python -m mvp_ed1.recovery rebase             re-basa as gerações (passo 4b)
    python -m mvp_ed1.recovery promote            candidato/ → aprovado/

A **sequência de restauração** não está aqui: ela mistura `pg_restore`,
`stream-*`, `airbyte-*` e `dbt-rebuild`, e vive no `Makefile`, que é a
interface de operação do projeto (ADR-0012). O que vive aqui é o que sabe ler
os bancos e decidir — e o que o `Makefile` chama nos passos 5 e 9.

**A autorização de restaurar é `RESTAURAR=1`, não `FORCE`**, e é consumida na
entrada: os submakes de descarte recebem `FORCE=1` um a um, e os de subida
recebem `FORCE=` vazio, com o preflight obrigatório (RV12-06). `FORCE` não
atravessa o *restore*.
"""

from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import subprocess
import sys
from typing import Any

from mvp_ed1.recovery import leitura, oraculos, pacote, rebase

RAIZ = pathlib.Path(__file__).resolve().parents[3]


def _motor(prefixo: str):
    import sqlalchemy as sa

    from mvp_ed1 import db

    return sa.create_engine(db.database_url(prefixo), future=True)


def _conteineres(servico: str) -> str:
    nomes = subprocess.run(
        [str(RAIZ / "docker" / "conteineres.sh"), "resolver", servico],
        capture_output=True, text=True, check=True,
    ).stdout.split()
    if not nomes:
        raise pacote.PacoteRecusado(
            f"não resolvi o contêiner do serviço {servico!r} neste projeto. Rode `make up`."
        )
    return nomes[0]


def _pg_dump(servico: str, usuario: str, banco: str, destino: pathlib.Path, schemas=()) -> None:
    comando = ["docker", "exec", _conteineres(servico), "pg_dump", "-Fc", "-U", usuario, "-d", banco]
    for schema in schemas:
        comando += ["-n", schema]
    with destino.open("wb") as arquivo:
        processo = subprocess.run(comando, stdout=arquivo, stderr=subprocess.PIPE)
    if processo.returncode != 0:
        raise pacote.PacoteRecusado(
            f"pg_dump de {banco} falhou: {processo.stderr.decode(errors='replace')[:400]}"
        )


def _env(chave: str) -> str:
    import os

    valor = os.environ.get(chave)
    if not valor:
        raise pacote.PacoteRecusado(
            f"{chave} ausente do ambiente. Use os alvos do Makefile, que carregam o .env."
        )
    return valor


# ── pack ────────────────────────────────────────────────────────────────────
def comando_pack(args: argparse.Namespace) -> int:
    from mvp_ed1 import db

    destino = pacote.diretorio_padrao(RAIZ) if not args.dir else pacote.Destino(pathlib.Path(args.dir))
    print(f"[recovery] RECOVERY_DIR = {destino.raiz}")

    sujo = pacote.arvore_suja(RAIZ)
    if sujo and not args.permitir_arvore_suja:
        print(
            "RECUSADO — árvore suja. O manifesto grava `git rev-parse HEAD` como a versão do\n"
            "  código que produziu este estado; com a árvore suja esse commit descreve outro\n"
            "  código, e a restauração reconstruiria com modelos que ninguém tem.\n"
            f"{sujo}",
            file=sys.stderr,
        )
        return 1

    if destino.candidato.exists():
        import shutil

        shutil.rmtree(destino.candidato)
    destino.candidato.mkdir(parents=True)

    corte = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    print(f"[recovery] corte em {corte} — janela parada")

    _pg_dump("source_db", _env("SOURCE_DB_USER"), _env("SOURCE_DB_NAME"), destino.candidato / "source_db.dump")
    _pg_dump("legacy_db", _env("LEGACY_DB_USER"), _env("LEGACY_DB_NAME"), destino.candidato / "legacy_db.dump")
    _pg_dump(
        "warehouse_db", _env("WAREHOUSE_DB_USER"), _env("WAREHOUSE_DB_NAME"),
        destino.candidato / "warehouse_memoria.dump", pacote.SCHEMAS_DE_MEMORIA,
    )
    print(f"[recovery] três dumps em {destino.candidato}")

    copiados, ausentes = pacote.copiar_artefatos(RAIZ, destino.candidato)

    origem, legado, armazem = _motor(db.SOURCE), _motor(db.LEGACY), _motor(db.WAREHOUSE)
    try:
        manifesto = pacote.Manifesto(
            {
                "corte": corte,
                "commit": pacote.commit_atual(RAIZ),
                "artefatos_copiados": copiados,
                "artefatos_ausentes": ausentes,
                "alembic": {
                    "source_db": leitura.alembic_current(RAIZ),
                    "legacy_db": leitura.alembic_current(RAIZ, "legacy"),
                },
                "governance_versions": leitura.versoes_do_armazem(armazem),
                "max_event_sequence": leitura.maior_event_sequence(origem),
                "contagens": {
                    "source_db": leitura.contagens(origem, ["oltp"]),
                    "legacy_db": leitura.contagens(legado, ["legacy"]),
                    "warehouse_db": leitura.contagens(armazem, list(pacote.SCHEMAS_DE_MEMORIA)),
                },
                "oraculo_scd": leitura.oraculo_scd(armazem),
                "oraculo_capturas": leitura.oraculo_das_capturas(armazem),
                "oraculo_quarentena": leitura.oraculo_da_quarentena(armazem),
                "limite": (
                    "guarda as fontes e a memória do armazém (raw_legacy, governance, "
                    "snapshots, quarantine). NÃO guarda raw, staging, trusted, analytics, "
                    "consumption, o cursor do CDC, nem o estado do Airbyte e do Airflow — "
                    "esses são reconstruídos e provados iguais."
                ),
            }
        )
    finally:
        for motor in (origem, legado, armazem):
            motor.dispose()

    manifesto.gravar(destino.candidato)
    _escrever_roteiro(destino.candidato, manifesto)
    pacote.escrever_checksums(destino.candidato)

    print(f"[recovery] manifesto, roteiro e checksums gravados")
    if ausentes:
        print(
            f"[recovery] ATENÇÃO: nenhum arquivo para os padrões {ausentes} — "
            "os oráculos que dependem deles não estarão no pacote",
            file=sys.stderr,
        )
    print(f"candidato pronto em {destino.candidato}")
    return 0


def _escrever_roteiro(pasta: pathlib.Path, manifesto: pacote.Manifesto) -> None:
    (pasta / pacote.NOME_DO_ROTEIRO).write_text(
        f"""# Como restaurar este pacote

Corte: **{manifesto.dados['corte']}** · código: **{manifesto.dados['commit']}**

```bash
export RECOVERY_DIR={pasta.parent}
make recovery-verify
make recovery-restore RESTAURAR=1
```

`recovery-restore` executa a sequência inteira, na ordem, e para na primeira
falha. Ela **não** é `make dbt-build RESET=1`: esse alvo chama
`dbt-drop-snapshots`, que derruba o schema `snapshots` — certo para regenerar a
origem, **errado depois de um restore**, porque o histórico SCD que acabou de
voltar não se reconstrói. O alvo de uma restauração é **`dbt-rebuild`**.

O que este pacote **não** traz: {manifesto.dados['limite']}
""",
        encoding="utf-8",
    )


# ── verify ──────────────────────────────────────────────────────────────────
def comando_verify(args: argparse.Namespace) -> int:
    destino = pacote.diretorio_padrao(RAIZ) if not args.dir else pacote.Destino(pathlib.Path(args.dir))
    pasta = destino.candidato if destino.candidato.exists() else destino.aprovado
    print(f"[recovery] conferindo {pasta}")

    problemas = pacote.conferir_checksums(pasta)
    manifesto = pacote.Manifesto.ler(pasta)

    for nome in ("source_db.dump", "legacy_db.dump", "warehouse_memoria.dump"):
        dump = pasta / nome
        if not dump.exists():
            problemas.append(f"{nome}: ausente do pacote")
            continue
        listado = subprocess.run(
            ["pg_restore", "--list", str(dump)], capture_output=True, text=True
        )
        if listado.returncode != 0:
            problemas.append(f"{nome}: `pg_restore --list` recusou — {listado.stderr.strip()[:200]}")

    if args.contra_o_banco:
        problemas += _conferir_contra_o_banco(manifesto)

    for problema in problemas:
        print(f"  {problema}", file=sys.stderr)
    if problemas:
        print(f"\nrecovery-verify: {len(problemas)} problema(s)", file=sys.stderr)
        return 1
    print(
        "recovery-verify: checksums conferem, manifesto legível, os três dumps se listam. "
        "Listar o pacote não é restaurá-lo — isso é a linha 9 de B5."
    )
    return 0


def _conferir_contra_o_banco(manifesto: pacote.Manifesto) -> list[str]:
    """Contagens e oráculos do manifesto × o que os bancos têm agora."""
    from mvp_ed1 import db

    problemas: list[str] = []
    armazem = _motor(db.WAREHOUSE)
    try:
        atual = leitura.oraculo_da_quarentena(armazem)
        problemas += [
            f"quarentena: {p}" for p in oraculos.contido(manifesto.dados["oraculo_quarentena"], atual)
        ]
        novas = oraculos.acrescimo(manifesto.dados["oraculo_quarentena"], atual)
        if novas:
            print(f"[recovery] quarentena: {len(novas)} fatia(s) acrescentada(s) desde o corte")

        scd_atual = leitura.oraculo_scd(armazem)
        for tabela, esperado in manifesto.dados["oraculo_scd"].items():
            encontrado = scd_atual.get(tabela)
            if encontrado is None:
                problemas.append(f"snapshot {tabela} sumiu")
            elif encontrado != esperado:
                problemas.append(
                    f"snapshot {tabela} mudou: manifesto {esperado} × agora {encontrado}"
                )
    finally:
        armazem.dispose()
    return problemas


# ── rebase (passo 4b) ───────────────────────────────────────────────────────
def comando_rebase(args: argparse.Namespace) -> int:
    """Re-basa as gerações retidas, por tabela, preservando as classes.

    O contrato inteiro está em `rebase.py`. Aqui fica só a aplicação: lê as
    gerações distintas, monta o plano, confere o contrato **antes** de escrever
    e recua se ele não for satisfeito.
    """
    import sqlalchemy as sa

    from mvp_ed1 import db

    armazem = _motor(db.WAREHOUSE)
    try:
        with armazem.connect() as conexao:
            tabelas = leitura.tabelas_do_schema(conexao, leitura.SCHEMA_DO_BRUTO)
        if not tabelas:
            print("[recovery] raw_legacy vazio — nada a re-basear")
            return 0

        planos: dict[str, dict[int, int]] = {}
        for tabela in tabelas:
            geracoes = leitura.geracoes_da_tabela(armazem, tabela)
            if not geracoes:
                continue
            try:
                mapa = rebase.plano(geracoes)
            except rebase.RebaseImpossivel as erro:
                print(f"RECUSADO — {tabela}: {erro}", file=sys.stderr)
                return 1
            violacoes = rebase.conforme(mapa)
            if violacoes:
                print(f"RECUSADO — {tabela}: {violacoes}", file=sys.stderr)
                return 1
            planos[tabela] = mapa

        if args.dry_run:
            for tabela, mapa in planos.items():
                print(f"  {tabela}: {len(mapa)} classe(s) → {min(mapa.values())}..{max(mapa.values())}")
            print("[recovery] --dry-run: nada foi escrito")
            return 0

        # Uma transação só: metade re-baseada é pior que nada.
        with armazem.begin() as conexao:
            for tabela, mapa in planos.items():
                if all(origem == destino for origem, destino in mapa.items()):
                    continue
                casos = " ".join(
                    f"when _airbyte_generation_id = {origem} then {destino}"
                    for origem, destino in mapa.items()
                )
                conexao.execute(
                    sa.text(
                        f'update {leitura.SCHEMA_DO_BRUTO}."{tabela}" '
                        f"set _airbyte_generation_id = case {casos} end"
                    )
                )
        print(f"[recovery] re-base aplicado a {len(planos)} tabela(s)")

        fora: list[str] = []
        for tabela in planos:
            fora += [
                f"{tabela}: {p}"
                for p in rebase.dominio_valido(leitura.geracoes_da_tabela(armazem, tabela))
            ]
        if fora:
            for problema in fora:
                print(f"  {problema}", file=sys.stderr)
            return 1
        print("[recovery] domínio conferido: toda linha retida com geração estritamente negativa")
        return 0
    finally:
        armazem.dispose()


# ── restore-dumps (passo 4) ─────────────────────────────────────────────────
def _pg_restore(servico: str, usuario: str, banco: str, dump: pathlib.Path) -> None:
    """`--clean --if-exists`: o destino está **povoado**, e é esse o caso.

    `pg_restore` devolve código 1 com avisos benignos (objeto que não existia
    para `drop`), e tratar todo aviso como falha faria a restauração recuar por
    nada. O que decide é o passo 5, que compara com o manifesto — aqui só se
    propaga a falha dura.
    """
    with dump.open("rb") as arquivo:
        processo = subprocess.run(
            [
                "docker", "exec", "-i", _conteineres(servico),
                "pg_restore", "--clean", "--if-exists", "--no-owner",
                "-U", usuario, "-d", banco,
            ],
            stdin=arquivo, capture_output=True,
        )
    erro = processo.stderr.decode(errors="replace")
    if processo.returncode not in (0, 1):
        raise pacote.PacoteRecusado(f"pg_restore de {banco} falhou ({processo.returncode}): {erro[:600]}")
    if erro.strip():
        print(f"[recovery] avisos de {banco}: {erro.strip().splitlines()[-1][:200]}")


def comando_restore_dumps(args: argparse.Namespace) -> int:
    pasta = _pasta_do_pacote(args)
    for servico, usuario, banco, nome in (
        ("source_db", "SOURCE_DB_USER", "SOURCE_DB_NAME", "source_db.dump"),
        ("legacy_db", "LEGACY_DB_USER", "LEGACY_DB_NAME", "legacy_db.dump"),
        ("warehouse_db", "WAREHOUSE_DB_USER", "WAREHOUSE_DB_NAME", "warehouse_memoria.dump"),
    ):
        print(f"[recovery] restaurando {nome} em destino povoado")
        _pg_restore(servico, _env(usuario), _env(banco), pasta / nome)
    return 0


def comando_restore_artefatos(args: argparse.Namespace) -> int:
    """Devolve manifesto do legado, diário e cursor do produtor ao *checkout*.

    A regra, escrita: **restaurar o livro restaura o cursor.** Um cursor do
    produtor à frente do livro faria os eventos seguintes nascerem depois de um
    buraco, e a reconciliação dos dois caminhos acusaria o que a restauração
    causou.
    """
    import shutil

    pasta = _pasta_do_pacote(args)
    manifesto = pacote.Manifesto.ler(pasta)
    relativos = manifesto.dados.get("artefatos_copiados", [])
    if not relativos:
        print("[recovery] o pacote não trouxe artefato nenhum — nada a devolver")
    for relativo in relativos:
        origem = pasta / relativo
        if not origem.exists():
            print(f"[recovery] {relativo}: declarado no manifesto e ausente do pacote", file=sys.stderr)
            return 1
        alvo = RAIZ / relativo
        alvo.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(origem, alvo)
        print(f"[recovery] devolvido: {relativo}")
    return 0


# ── conferir-restauracao (passo 9) ──────────────────────────────────────────
def comando_conferir_restauracao(args: argparse.Namespace) -> int:
    """Os oráculos explícitos, no roteiro executável — não só o `PASS` do dbt."""
    from mvp_ed1 import db
    from mvp_ed1.legacy import captura

    manifesto = pacote.Manifesto.ler(_pasta_do_pacote(args))
    problemas: list[str] = []
    armazem = _motor(db.WAREHOUSE)
    origem = _motor(db.SOURCE)
    try:
        versoes = leitura.versoes_do_armazem(armazem)
        if versoes != manifesto.dados["governance_versions"]:
            problemas.append(
                f"governance._versions: manifesto {manifesto.dados['governance_versions']} × agora {versoes}"
            )

        scd = leitura.oraculo_scd(armazem)
        for tabela, esperado in manifesto.dados["oraculo_scd"].items():
            if scd.get(tabela) != esperado:
                problemas.append(f"snapshot {tabela}: {esperado} × {scd.get(tabela)}")

        quarentena = leitura.oraculo_da_quarentena(armazem)
        problemas += [f"quarentena: {p}" for p in oraculos.contido(manifesto.dados["oraculo_quarentena"], quarentena)]
        novas = oraculos.acrescimo(manifesto.dados["oraculo_quarentena"], quarentena)
        print(
            f"[recovery] quarentena: {len(manifesto.dados['oraculo_quarentena'])} fatia(s) do "
            f"manifesto contidas, {len(novas)} acrescentada(s) pela captura nova"
        )

        capturas = leitura.oraculo_das_capturas(armazem)
        retido = manifesto.dados["oraculo_capturas"]["maior_snapshot"]
        certificadas = capturas["certificadas"]
        if retido is not None and not [c for c in certificadas if c > retido]:
            problemas.append(
                f"nenhuma captura certificada acima da retida ({retido}) — "
                "a sincronização do passo 8 não produziu identidade nova"
            )
        for tabela, dados in capturas["geracoes_por_tabela"].items():
            if dados["nulas"]:
                problemas.append(f"{tabela}: {dados['nulas']} linha(s) com geração nula")
            if dados["maxima"] is not None and dados["maxima"] >= 0 and dados["minima"] < 0:
                print(
                    f"[recovery] {tabela}: faixa retida {dados['minima']}..-1 e carga nova "
                    f"até {dados['maxima']} — as faixas não se encontram"
                )

        sequencia = leitura.maior_event_sequence(origem)
        if sequencia < manifesto.dados["max_event_sequence"]:
            problemas.append(
                f"max(event_sequence) da origem regrediu: manifesto "
                f"{manifesto.dados['max_event_sequence']} × agora {sequencia}"
            )

        selecionada = max(certificadas) if certificadas else None
        if selecionada is None:
            problemas.append("nenhuma captura certificada depois da restauração")
        else:
            print(f"[recovery] captura selecionada: {selecionada} (certificada)")
        _ = captura  # a lista de certificadas vem dele, por `leitura`
    finally:
        armazem.dispose()
        origem.dispose()

    for problema in problemas:
        print(f"  {problema}", file=sys.stderr)
    if problemas:
        print(f"\nconferir-restauracao: {len(problemas)} problema(s)", file=sys.stderr)
        return 1
    print(
        "conferir-restauracao: memória contida, versões intactas, identidade nova acima da "
        "retida e faixas de geração separadas.\n"
        "  A comparação dos dois caminhos e as oito fronteiras são do `make check` do passo 8."
    )
    return 0


def _pasta_do_pacote(args: argparse.Namespace) -> pathlib.Path:
    destino = pacote.diretorio_padrao(RAIZ) if not args.dir else pacote.Destino(pathlib.Path(args.dir))
    return destino.candidato if destino.candidato.exists() else destino.aprovado


def comando_promote(args: argparse.Namespace) -> int:
    destino = pacote.diretorio_padrao(RAIZ) if not args.dir else pacote.Destino(pathlib.Path(args.dir))
    aprovado = pacote.promover(destino)
    print(f"promovido: {aprovado}")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python -m mvp_ed1.recovery", description=__doc__)
    p.add_argument("--dir", default=None, help="RECOVERY_DIR; absoluto, sempre")
    sub = p.add_subparsers(dest="comando", required=True)

    pk = sub.add_parser("pack", help="monta o candidato a pacote")
    pk.add_argument("--permitir-arvore-suja", action="store_true", help=argparse.SUPPRESS)
    pk.set_defaults(func=comando_pack)

    vf = sub.add_parser("verify", help="confere o pacote sem restaurar nada")
    vf.add_argument(
        "--contra-o-banco", action="store_true",
        help="compara também com o estado vivo (só vale enquanto é o mesmo estado)",
    )
    vf.set_defaults(func=comando_verify)

    rb = sub.add_parser("rebase", help="re-basa as gerações retidas do bruto (passo 4b)")
    rb.add_argument("--dry-run", action="store_true", help="mostra o plano e não escreve")
    rb.set_defaults(func=comando_rebase)

    sub.add_parser(
        "restore-dumps", help="pg_restore das duas fontes e da memória (passo 4)"
    ).set_defaults(func=comando_restore_dumps)
    sub.add_parser(
        "restore-artefatos", help="devolve manifesto do legado, diário e cursor (passo 6)"
    ).set_defaults(func=comando_restore_artefatos)
    sub.add_parser(
        "conferir-restauracao", help="os oráculos explícitos do passo 9"
    ).set_defaults(func=comando_conferir_restauracao)
    sub.add_parser("promote", help="candidato/ → aprovado/").set_defaults(func=comando_promote)

    args = p.parse_args(argv)
    try:
        return args.func(args)
    except pacote.PacoteRecusado as erro:
        print(f"RECUSADO — {erro}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
