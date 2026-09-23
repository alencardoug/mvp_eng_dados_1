"""Os verbos do ponto único de recuperação.

    python -m mvp_ed1.recovery pack                    monta o candidato
    python -m mvp_ed1.recovery verify [--dir X]        confere sem restaurar nada
    python -m mvp_ed1.recovery rebase                  re-basa as gerações (passo 4b)
    python -m mvp_ed1.recovery restore-dumps           pg_restore das fontes e da memória (passo 4)
    python -m mvp_ed1.recovery restore-artefatos       devolve manifesto do legado e cursor (passo 6)
    python -m mvp_ed1.recovery avancar-jobs            o contador de jobs de um Airbyte novo (D50)
    python -m mvp_ed1.recovery conferir-restauracao --job N    os oráculos explícitos (passo 9)
    python -m mvp_ed1.recovery promote                 candidato/ → aprovado/

A **sequência de restauração** não está aqui: ela mistura `pg_restore`,
`stream-*`, `airbyte-*` e `dbt-rebuild`, e vive no `Makefile`, que é a
interface de operação do projeto (ADR-0012). O que vive aqui é o que sabe ler
os bancos e decidir — e o que o `Makefile` chama nos passos 4, 4b, 5, 6, 8 e 9.

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
    resolvido = subprocess.run(
        [str(RAIZ / "docker" / "conteineres.sh"), "resolver", servico],
        capture_output=True, text=True,
    )
    # Lista vazia e falha de enumeração são respostas diferentes (RVE-08): a
    # segunda é "não sei", e não sei não autoriza nada.
    if resolvido.returncode != 0:
        raise pacote.PacoteRecusado(
            f"não consegui enumerar os contêineres do serviço {servico!r} — o Docker respondeu? "
            f"(conteineres.sh saiu {resolvido.returncode})"
        )
    nomes = resolvido.stdout.split()
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


def _destino(args: argparse.Namespace) -> pacote.Destino:
    return pacote.diretorio_padrao(RAIZ) if not args.dir else pacote.Destino(pathlib.Path(args.dir))


# ── pack ────────────────────────────────────────────────────────────────────
def comando_pack(args: argparse.Namespace) -> int:
    destino = _destino(args)
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

    # O candidato novo nasce ao lado do anterior e só o substitui inteiro e
    # conferido (RVE-10): antes, um `rmtree` precedia o primeiro dump, e uma
    # falha nesse dump deixava a única volta perdida.
    pasta = pacote.comecar_montagem(destino)
    try:
        _montar(pasta)
    except BaseException:
        pacote.abandonar_montagem(destino)
        if destino.candidato.exists():
            print(f"[recovery] o candidato anterior em {destino.candidato} foi preservado", file=sys.stderr)
        raise
    candidato = pacote.concluir_montagem(destino)
    print(f"candidato pronto em {candidato}")
    return 0


def _montar(pasta: pathlib.Path) -> None:
    from mvp_ed1 import db

    corte = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    print(f"[recovery] corte em {corte} — janela parada")

    _pg_dump("source_db", _env("SOURCE_DB_USER"), _env("SOURCE_DB_NAME"), pasta / "source_db.dump")
    _pg_dump("legacy_db", _env("LEGACY_DB_USER"), _env("LEGACY_DB_NAME"), pasta / "legacy_db.dump")
    _pg_dump(
        "warehouse_db", _env("WAREHOUSE_DB_USER"), _env("WAREHOUSE_DB_NAME"),
        pasta / "warehouse_memoria.dump", pacote.SCHEMAS_DE_MEMORIA,
    )
    print(f"[recovery] três dumps em {pasta}")

    copiados, ausentes, links = pacote.copiar_artefatos(RAIZ, pasta)

    origem, legado, armazem = _motor(db.SOURCE), _motor(db.LEGACY), _motor(db.WAREHOUSE)
    try:
        manifesto = pacote.Manifesto(
            {
                "corte": corte,
                "commit": pacote.commit_atual(RAIZ),
                "oraculo_formato": oraculos.FORMATO,
                "artefatos_copiados": copiados,
                "artefatos_ausentes": ausentes,
                "artefatos_links": links,
                "alembic": {
                    "source_db": leitura.alembic_current(RAIZ),
                    "legacy_db": leitura.alembic_current(RAIZ, "legacy"),
                },
                "geracao": leitura.geracao_registrada(RAIZ),
                "governance_versions": leitura.versoes_do_armazem(armazem),
                "max_event_sequence": leitura.maior_event_sequence(origem),
                "contagens": {
                    "source_db": leitura.contagens(origem, ["oltp"]),
                    "legacy_db": leitura.contagens(legado, ["legacy"]),
                    "warehouse_db": leitura.contagens(armazem, list(pacote.SCHEMAS_DE_MEMORIA)),
                },
                "tamanhos": {
                    "source_db": leitura.tamanhos(origem, ["oltp"]),
                    "legacy_db": leitura.tamanhos(legado, ["legacy"]),
                    "warehouse_db": leitura.tamanhos(armazem, list(pacote.SCHEMAS_DE_MEMORIA)),
                },
                "oraculo_scd": leitura.oraculo_scd(armazem),
                "oraculo_capturas": leitura.oraculo_das_capturas(armazem),
                "oraculo_particao": leitura.oraculo_da_particao(armazem),
                "oraculo_quarentena": leitura.oraculo_da_quarentena(armazem),
                "oraculo_exclusoes": leitura.oraculo_das_exclusoes(armazem),
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

    if manifesto.campos_ausentes():
        raise pacote.PacoteRecusado(f"manifesto incompleto: faltam {manifesto.campos_ausentes()}")
    manifesto.gravar(pasta)
    _escrever_roteiro(pasta, manifesto)
    pacote.escrever_checksums(pasta)

    print("[recovery] manifesto, roteiro e checksums gravados")
    if ausentes:
        print(
            f"[recovery] ATENÇÃO: nenhum arquivo para os padrões {ausentes} — "
            "os oráculos que dependem deles não estarão no pacote",
            file=sys.stderr,
        )
    geracao = manifesto.dados["geracao"]
    if geracao.get("source_db") is None:
        print(f"[recovery] ATENÇÃO: {geracao.get('source_db_motivo')}", file=sys.stderr)


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

O `pg_restore` de cada dump roda em **uma transação** (`--single-transaction`,
que implica `--exit-on-error`): qualquer erro — dependência de objeto fora do
dump, papel ausente, permissão — desfaz o dump inteiro e a sequência para com
o diagnóstico. Nada fica pela metade.

Num Airbyte **novo**, a sequência avança o contador de jobs para além da
captura retida antes de sincronizar (`make recovery-airbyte-jobs`, D50).

O que este pacote **não** traz: {manifesto.dados['limite']}
""",
        encoding="utf-8",
    )


# ── verify ──────────────────────────────────────────────────────────────────
def comando_verify(args: argparse.Namespace) -> int:
    pasta = _pasta_do_pacote(args)
    print(f"[recovery] conferindo {pasta}")

    problemas = pacote.conferir_checksums(pasta)
    manifesto = pacote.Manifesto.ler(pasta)
    problemas += manifesto.problemas_de_forma(oraculos.FORMATO)

    for nome in ("source_db.dump", "legacy_db.dump", "warehouse_memoria.dump"):
        dump = pasta / nome
        if not dump.exists():
            problemas.append(f"{nome}: ausente do pacote")
            continue
        # `pg_restore` vive **nos contêineres**, não no host: o projeto fixa a
        # imagem do PostgreSQL por digest e não exige cliente instalado na
        # máquina de quem clona. Medido ao conferir o primeiro pacote.
        with dump.open("rb") as arquivo:
            listado = subprocess.run(
                ["docker", "exec", "-i", _conteineres("warehouse_db"), "pg_restore", "--list"],
                stdin=arquivo, capture_output=True, text=True,
            )
        if listado.returncode != 0:
            problemas.append(f"{nome}: `pg_restore --list` recusou — {listado.stderr.strip()[:200]}")
        elif not listado.stdout.strip():
            problemas.append(f"{nome}: `pg_restore --list` não devolveu entrada nenhuma")

    if args.contra_o_banco and not problemas:
        problemas += _conferir_contra_o_banco(manifesto)

    for problema in problemas:
        print(f"  {problema}", file=sys.stderr)
    if problemas:
        print(f"\nrecovery-verify: {len(problemas)} problema(s)", file=sys.stderr)
        return 1
    print(
        "recovery-verify: checksums conferem, manifesto completo e no formato atual, os três "
        "dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5."
    )
    return 0


def _comparar(rotulo: str, esperado: Any, encontrado: Any) -> list[str]:
    if esperado == encontrado:
        return []
    if isinstance(esperado, dict) and isinstance(encontrado, dict):
        diferentes = sorted(
            k for k in set(esperado) | set(encontrado) if esperado.get(k) != encontrado.get(k)
        )
        return [
            f"{rotulo}: {k} — manifesto {esperado.get(k)!r} × agora {encontrado.get(k)!r}"
            for k in diferentes[:20]
        ] + ([f"{rotulo}: … e mais {len(diferentes) - 20} diferença(s)"] if len(diferentes) > 20 else [])
    return [f"{rotulo}: manifesto {esperado!r} × agora {encontrado!r}"]


def _conferir_contra_o_banco(manifesto: pacote.Manifesto) -> list[str]:
    """O passo 5, inteiro: o que o manifesto afirma × o que os bancos têm agora.

    É o mesmo estado do pacote — logo depois do `pack`, ou logo depois do
    `restore-dumps` + `rebase` — e por isso a comparação é de **igualdade**
    em tudo, menos nas gerações: elas podem estar como no manifesto (antes do
    re-base) ou todas na faixa negativa (depois), e a partição das linhas entre
    elas é a mesma nos dois casos (RVE-04).
    """
    from mvp_ed1 import db

    dados = manifesto.dados
    problemas: list[str] = []
    origem, legado, armazem = _motor(db.SOURCE), _motor(db.LEGACY), _motor(db.WAREHOUSE)
    try:
        problemas += _comparar("contagens em source_db", dados["contagens"]["source_db"], leitura.contagens(origem, ["oltp"]))
        problemas += _comparar("contagens em legacy_db", dados["contagens"]["legacy_db"], leitura.contagens(legado, ["legacy"]))
        problemas += _comparar(
            "contagens em warehouse_db",
            dados["contagens"]["warehouse_db"],
            leitura.contagens(armazem, list(pacote.SCHEMAS_DE_MEMORIA)),
        )
        problemas += _comparar(
            "alembic",
            dados["alembic"],
            {"source_db": leitura.alembic_current(RAIZ), "legacy_db": leitura.alembic_current(RAIZ, "legacy")},
        )
        problemas += _comparar("governance._versions", dados["governance_versions"], leitura.versoes_do_armazem(armazem))
        problemas += _comparar("max(event_sequence)", dados["max_event_sequence"], leitura.maior_event_sequence(origem))
        print("[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos")

        atual = leitura.oraculo_da_quarentena(armazem)
        problemas += [f"quarentena: {p}" for p in oraculos.contido(dados["oraculo_quarentena"], atual)]
        novas = oraculos.acrescimo(dados["oraculo_quarentena"], atual)
        if novas:
            problemas.append(
                f"quarentena: {len(novas)} fatia(s) que o manifesto não tem — este não é o "
                f"estado do pacote: {sorted(novas)[:3]}"
            )
        print(
            f"[recovery] quarentena: {len(dados['oraculo_quarentena'])} fatia(s) do "
            f"manifesto conferidas por contagem e conteúdo, {len(novas)} acrescentada(s) desde o corte"
        )

        problemas += _comparar("snapshots SCD", dados["oraculo_scd"], leitura.oraculo_scd(armazem))
        print(f"[recovery] SCD: {len(dados['oraculo_scd'])} snapshot(s) conferidos pelo digest canônico de todas as colunas")

        # A memória de exclusões fica para o passo 9: ela é `trusted`, que o
        # restore não traz — renasce no `dbt-rebuild` do passo 8, e num clone
        # o que existe aqui é a do build anterior.
        problemas += _conferir_capturas_e_geracoes(dados, armazem, depois_da_carga_nova=False)
    finally:
        for motor in (origem, legado, armazem):
            motor.dispose()
    return problemas


def _conferir_capturas_e_geracoes(dados: dict, armazem, *, depois_da_carga_nova: bool) -> list[str]:
    """Certificados, classes de geração, nulos e a partição das linhas retidas.

    Antes da carga nova as retidas são todas as linhas; depois dela, só as da
    faixa negativa — e a assinatura, invariante ao re-base, tem de ser a mesma
    do manifesto nos dois casos.
    """
    problemas: list[str] = []
    capturas = leitura.oraculo_das_capturas(armazem)
    esperadas = dados["oraculo_capturas"]
    if depois_da_carga_nova:
        faltam = sorted(set(esperadas["certificadas"]) - set(capturas["certificadas"]))
        if faltam:
            problemas.append(f"capturas certificadas do manifesto que sumiram: {faltam}")
    else:
        problemas += _comparar("capturas certificadas", esperadas["certificadas"], capturas["certificadas"])

    rebaseadas = 0
    for tabela, esperado in esperadas["geracoes_por_tabela"].items():
        atual = capturas["geracoes_por_tabela"].get(tabela)
        if atual is None:
            problemas.append(f"{tabela}: tabela do bruto sumiu")
            continue
        if atual["nulas"]:
            problemas.append(f"{tabela}: {atual['nulas']} linha(s) com geração nula")
        if depois_da_carga_nova:
            continue
        if atual["classes"] != esperado["classes"]:
            problemas.append(
                f"{tabela}: {esperado['classes']} classe(s) de geração no manifesto × {atual['classes']} agora"
            )
        if (atual["minima"], atual["maxima"]) == (esperado["minima"], esperado["maxima"]):
            continue
        if atual["maxima"] is not None and atual["maxima"] < 0:
            rebaseadas += 1
            continue
        problemas.append(
            f"{tabela}: gerações {atual['minima']}..{atual['maxima']} não são as do manifesto "
            f"({esperado['minima']}..{esperado['maxima']}) nem uma faixa negativa re-baseada"
        )

    particao = leitura.oraculo_da_particao(armazem, apenas_retidas=depois_da_carga_nova)
    divergentes = _comparar("partição das linhas retidas por geração", dados["oraculo_particao"], particao)
    problemas += divergentes
    estado = "re-baseadas na faixa negativa" if rebaseadas or depois_da_carga_nova else "como no manifesto"
    veredito = (
        f"{len(particao)} tabela(s) do bruto com a partição por geração igual à do manifesto"
        if not divergentes else "partição por geração DIFERENTE da do manifesto"
    )
    print(
        f"[recovery] capturas: {len(esperadas['certificadas'])} certificada(s) do manifesto "
        f"{'conferidas' if not problemas else 'conferidas com problemas'}; {veredito} (gerações {estado})"
    )
    return problemas


# ── rebase (passo 4b) ───────────────────────────────────────────────────────
def comando_rebase(args: argparse.Namespace) -> int:
    """Re-basa as gerações retidas, por tabela, preservando as classes.

    O contrato inteiro está em `rebase.py`. Aqui fica só a aplicação: lê as
    gerações distintas, monta o plano, confere o contrato **antes** de escrever
    e, depois de escrever, confere a partição **antes de confirmar** — a mesma
    transação recua se uma linha mudou de classe (RVE-04).
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

        # Uma transação só: metade re-baseada é pior que nada. E o oráculo do
        # passo — mesma quantidade de classes, mesma partição das linhas, toda
        # geração estritamente negativa e não nula — é lido **dentro** dela: a
        # violação desfaz a escrita em vez de ser descoberta depois do commit.
        recusas: list[str] = []
        try:
            _aplicar_rebase(armazem, planos, recusas)
        except _Recuo:
            pass
        if recusas:
            print("RECUSADO — o re-base foi desfeito; o bruto está como estava:", file=sys.stderr)
            for recusa in recusas:
                print(f"  {recusa}", file=sys.stderr)
            return 1
        print(
            f"[recovery] re-base aplicado a {len(planos)} tabela(s); partição conferida antes de "
            "confirmar: mesmas classes, mesmo agrupamento, toda linha retida com geração "
            "estritamente negativa"
        )
        return 0
    finally:
        armazem.dispose()


class _Recuo(Exception):
    """Sai do `begin()` sem confirmar: a transação inteira é desfeita."""


def _aplicar_rebase(armazem, planos: dict[str, dict[int, int]], recusas: list[str]) -> None:
    import sqlalchemy as sa

    with armazem.begin() as conexao:
        for tabela, mapa in planos.items():
                antes = rebase.assinatura(leitura.chaves_e_geracoes(conexao, tabela))
                if any(origem != destino for origem, destino in mapa.items()):
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
                depois = rebase.assinatura(leitura.chaves_e_geracoes(conexao, tabela))
                recusas += [f"{tabela}: {p}" for p in rebase.particao_preservada_por_assinatura(antes, depois)]
                recusas += [
                    f"{tabela}: {p}"
                    for p in rebase.dominio_valido(
                        g for (g,) in conexao.execute(
                            sa.text(
                                f'select distinct _airbyte_generation_id from {leitura.SCHEMA_DO_BRUTO}."{tabela}"'
                            )
                        )
                    )
                ]
        if recusas:
            raise _Recuo()


# ── restore-dumps (passo 4) ─────────────────────────────────────────────────
def _pg_restore(servico: str, usuario: str, banco: str, dump: pathlib.Path) -> None:
    """`--clean --if-exists --single-transaction`: o destino está **povoado**.

    `pg_restore` devolve 1 quando **acumulou erros** (`exit_code = n_errors ?
    1 : 0`, `pg_restore.c`), e não por aviso benigno — `--if-exists` já cala o
    `drop` de objeto ausente. Tratar 1 como aviso deixava um `COPY` que falhou
    passar, e o passo 5 encontrar linhas dobradas em vez de uma recusa (RVE-03).
    Com `--single-transaction` (que implica `--exit-on-error`) o primeiro erro
    — dependência de objeto fora do dump, papel ausente, permissão — desfaz o
    dump inteiro: o destino fica **como estava**, e o diagnóstico sai por
    inteiro, não só a última linha.
    """
    with dump.open("rb") as arquivo:
        processo = subprocess.run(
            [
                "docker", "exec", "-i", _conteineres(servico),
                "pg_restore", "--clean", "--if-exists", "--no-owner", "--single-transaction",
                "-U", usuario, "-d", banco,
            ],
            stdin=arquivo, capture_output=True,
        )
    erro = processo.stderr.decode(errors="replace").strip()
    if processo.returncode != 0:
        raise pacote.PacoteRecusado(
            f"pg_restore de {banco} falhou (código {processo.returncode}) e a transação foi "
            f"desfeita — o banco está como estava. Diagnóstico completo:\n{erro[:4000]}"
        )
    if erro:
        print(f"[recovery] avisos de {banco} (código 0):\n{erro[:2000]}")


def comando_restore_dumps(args: argparse.Namespace) -> int:
    pasta = _pasta_do_pacote(args)
    for servico, usuario, banco, nome in (
        ("source_db", "SOURCE_DB_USER", "SOURCE_DB_NAME", "source_db.dump"),
        ("legacy_db", "LEGACY_DB_USER", "LEGACY_DB_NAME", "legacy_db.dump"),
        ("warehouse_db", "WAREHOUSE_DB_USER", "WAREHOUSE_DB_NAME", "warehouse_memoria.dump"),
    ):
        print(f"[recovery] restaurando {nome} em destino povoado, numa transação só")
        _pg_restore(servico, _env(usuario), _env(banco), pasta / nome)
    return 0


def comando_restore_artefatos(args: argparse.Namespace) -> int:
    """Devolve ao *checkout* o estado de trabalho do pacote — o que ele traz, e o que ele não traz.

    A regra, escrita: **restaurar o livro restaura o cursor.** Um cursor do
    produtor à frente do livro faria os eventos seguintes nascerem depois de um
    buraco, e a reconciliação dos dois caminhos acusaria o que a restauração
    causou.

    **A ausência também volta (RVE2-05).** O que o pacote não traz e o
    *checkout* tem é de outra carga, e sai do caminho renomeado
    (`pacote.afastar_o_que_o_pacote_nao_traz`): sem isso, o registro de geração
    de uma carga posterior sobrevivia, e o próximo pacote o atribuía à origem
    restaurada — onde o candidato diz `None` com motivo.

    **Link volta como link, e nunca se escreve através dele.** `copy2` sobre
    `data/legacy/manifesto.json` seguia o link do *checkout* e sobrescrevia o
    manifesto do lote que ele apontasse — outro, depois de uma recarga.

    Tudo é conferido antes de qualquer arquivo mudar: pacote sem um arquivo
    declarado, ou com link para um arquivo que ele não traz, recusa inteiro.
    """
    import shutil

    pasta = _pasta_do_pacote(args)
    manifesto = pacote.Manifesto.ler(pasta)
    relativos = manifesto.dados.get("artefatos_copiados", [])
    links = manifesto.dados.get("artefatos_links")
    if links is None:
        print(
            "[recovery] manifesto sem `artefatos_links` — é de antes do registro de links; "
            "refaça o pacote (make recovery-pack)",
            file=sys.stderr,
        )
        return 1
    faltando = [relativo for relativo in relativos if not (pasta / relativo).exists()]
    for relativo in faltando:
        print(f"[recovery] {relativo}: declarado no manifesto e ausente do pacote", file=sys.stderr)
    for relativo in pacote.links_sem_destino(relativos, links):
        print(f"[recovery] {relativo}: link para {links[relativo]}, que o pacote não traz", file=sys.stderr)
        faltando.append(relativo)
    if faltando:
        return 1

    instante = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    for relativo in pacote.afastar_o_que_o_pacote_nao_traz(RAIZ, relativos, instante):
        print(f"[recovery] afastado: {relativo} (o pacote não o traz) → *{pacote.SUFIXO_AFASTADO}{instante}")
    if not relativos:
        print("[recovery] o pacote não trouxe artefato nenhum — nada a devolver")
    for relativo in relativos:
        alvo = RAIZ / relativo
        alvo.parent.mkdir(parents=True, exist_ok=True)
        if alvo.is_symlink() or relativo in links:
            alvo.unlink(missing_ok=True)
        if relativo in links:
            alvo.symlink_to(links[relativo])
            print(f"[recovery] devolvido: {relativo} → {links[relativo]}")
        else:
            shutil.copy2(pasta / relativo, alvo)
            print(f"[recovery] devolvido: {relativo}")
    return 0


# ── avancar-jobs (D50, passo 8) ─────────────────────────────────────────────
def comando_avancar_jobs(args: argparse.Namespace) -> int:
    """O contador de jobs de um Airbyte **novo** passa da captura retida (D50).

    `snapshot_id` é o `jobId` do Airbyte. Uma instalação nova recomeça em 1, e
    o armazém restaurado certifica capturas até `max(snapshot_id)`: a guarda da
    identidade recusaria toda sincronização, e é para isso que ela existe. O
    passo operacional decidido pelo Owner é avançar a sequência interna de jobs
    para o retido, de modo que o próximo nasça acima dele.

    O que este verbo **não** confunde (RVE-06): o maior job existente com o
    próximo valor da sequência — a pergunta é feita à sequência, com `is_called`
    —; e avançar a sequência com criar um job: a listagem da API continua a
    mesma até o job seguinte nascer, e a guarda (`identidade.exigir`) continua
    lendo a listagem. Numa recuperação real, com o mesmo Airbyte, não há o que
    fazer, e é isso que ele diz.

    O interno do Airbyte é premissa declarada, e o `docker/airbyte_jobs.sh`
    **para** com a mensagem se ela falhar: tabela `jobs` ou sequência ausentes,
    pod ou banco com outro nome.
    """
    from mvp_ed1 import db
    from mvp_ed1.legacy import captura

    armazem = _motor(db.WAREHOUSE)
    try:
        certificadas = captura.certificadas(armazem)
    finally:
        armazem.dispose()
    if not certificadas:
        print("[recovery] nenhuma captura certificada no armazém — não há identidade a proteger")
        return 0
    retido = max(certificadas)

    estado = _airbyte_jobs("ler")
    proximo = estado["ultimo_valor"] + 1 if estado["chamado"] else estado["ultimo_valor"]
    print(
        f"[recovery] Airbyte: maior job {estado['maior_job']}, sequência {estado['sequencia']} em "
        f"{estado['ultimo_valor']} ({'já usada' if estado['chamado'] else 'nunca usada'}) → "
        f"próximo job {proximo}; captura retida {retido}"
    )
    if proximo > retido:
        print("[recovery] o próximo job já nasce acima da captura retida — nada a avançar")
        return 0

    depois = _airbyte_jobs("avancar", str(retido))
    proximo = depois["ultimo_valor"] + 1 if depois["chamado"] else depois["ultimo_valor"]
    if proximo <= retido:
        raise pacote.PacoteRecusado(
            f"avancei a sequência e o próximo job continua {proximo} ≤ {retido} — pós-condição "
            "de D50 não satisfeita; nenhuma sincronização deve ser disparada"
        )
    print(
        f"[recovery] sequência avançada para {depois['ultimo_valor']}: o próximo job nasce como "
        f"{proximo} > {retido}. A listagem da API só o mostra depois de um job existir — "
        "`sync-airbyte` cria o primeiro, e é por isso que ele vem antes de `sync-legacy`."
    )
    return 0


def _airbyte_jobs(*acao: str) -> dict[str, Any]:
    saida = subprocess.run(
        [str(RAIZ / "docker" / "airbyte_jobs.sh"), *acao], capture_output=True, text=True
    )
    if saida.returncode != 0:
        raise pacote.PacoteRecusado(
            f"airbyte_jobs.sh {' '.join(acao)} saiu {saida.returncode}: "
            f"{(saida.stderr or saida.stdout).strip()[:600]}"
        )
    campos = dict(linha.split("=", 1) for linha in saida.stdout.split() if "=" in linha)
    try:
        return {
            "maior_job": int(campos["maior_job"]),
            "ultimo_valor": int(campos["ultimo_valor"]),
            "chamado": campos["chamado"] == "t",
            "sequencia": campos["sequencia"],
        }
    except (KeyError, ValueError) as erro:
        raise pacote.PacoteRecusado(f"resposta ilegível de airbyte_jobs.sh: {saida.stdout!r}") from erro


# ── conferir-restauracao (passo 9) ──────────────────────────────────────────
def _conferir_auditoria_da_captura_nova(armazem, novas: list[int], acrescimo: dict[str, Any]) -> list[str]:
    """O acréscimo da quarentena é **exatamente** o que a classificação da captura nova rejeitou.

    Não "só fatias da captura nova" — isso aceitava a falta da fatia esperada
    (RVE2-01). O esperado vem da classificação corrente, que é a da captura
    selecionada: cada fatia rejeitada dela reaparece com a mesma contagem e o
    mesmo digest, e nada a mais entra em nome dela. Rejeição nenhuma é
    acréscimo vazio, e passa — o que não passa é a classificação tratar outra
    captura, ou não existir.
    """
    classificacao = leitura.classificacao_corrente(armazem)
    if classificacao is None:
        return [
            f"quarentena: {leitura.TABELA_DA_CLASSIFICACAO} não existe — sem ela não há esperado "
            "para a auditoria da captura nova"
        ]
    problemas: list[str] = []
    tratadas = sorted({leitura.snapshot_da_fatia(chave) for chave in classificacao["tratadas"]})
    if tratadas != novas:
        problemas.append(
            f"quarentena: a classificação corrente trata a(s) captura(s) {tratadas}, e as novas são {novas}"
        )
    esperado = classificacao["rejeitadas"]
    da_nova = {chave: fatia for chave, fatia in acrescimo.items() if leitura.snapshot_da_fatia(chave) in novas}
    problemas += [f"quarentena, auditoria da captura nova: {p}" for p in oraculos.contido(esperado, da_nova)]
    sobrando = oraculos.acrescimo(esperado, da_nova)
    if sobrando:
        problemas.append(
            f"quarentena: fatia(s) da captura nova que a classificação dela não rejeitou: {list(sobrando)[:3]}"
        )
    return problemas


def comando_conferir_restauracao(args: argparse.Namespace) -> int:
    """Os oráculos explícitos, no roteiro executável — não só o `PASS` do dbt.

    O que se prova aqui, contra o manifesto e nunca contra número escrito em
    plano (RVE-05): as fontes de volta (contagens, Alembic, corte do livro), a
    memória intacta (versões, SCD, certificados, partição das linhas retidas),
    a quarentena **contida** e acrescida **exatamente** da auditoria da captura
    nova — a do job que o passo 8 disparou —, a memória de exclusões renascida
    igual, e o livro quente igual ao lote: chave e as 16 colunas de negócio,
    saldo por armazém/SKU, soma dos deltas, com o tamanho do livro da origem.

    **Ausência não é igualdade (RVE2-01).** Conferir só que o acréscimo não
    tinha fatia estranha aceitava a falta da fatia esperada, e comparar os dois
    caminhos do livro aceitava os dois vazios. O esperado do acréscimo vem da
    classificação da captura disparada; o do livro, da origem.
    """
    from mvp_ed1 import db

    manifesto = pacote.Manifesto.ler(_pasta_do_pacote(args))
    dados = manifesto.dados
    problemas: list[str] = manifesto.problemas_de_forma(oraculos.FORMATO)
    if problemas:
        for problema in problemas:
            print(f"  {problema}", file=sys.stderr)
        return 1

    origem, legado, armazem = _motor(db.SOURCE), _motor(db.LEGACY), _motor(db.WAREHOUSE)
    try:
        # As fontes.
        contagens_da_origem = leitura.contagens(origem, ["oltp"])
        problemas += _comparar("contagens em source_db", dados["contagens"]["source_db"], contagens_da_origem)
        problemas += _comparar("contagens em legacy_db", dados["contagens"]["legacy_db"], leitura.contagens(legado, ["legacy"]))
        problemas += _comparar(
            "alembic",
            dados["alembic"],
            {"source_db": leitura.alembic_current(RAIZ), "legacy_db": leitura.alembic_current(RAIZ, "legacy")},
        )
        sequencia = leitura.maior_event_sequence(origem)
        if sequencia < dados["max_event_sequence"]:
            problemas.append(
                f"max(event_sequence) da origem regrediu: manifesto {dados['max_event_sequence']} × agora {sequencia}"
            )
        print("[recovery] fontes: contagens, Alembic e corte do livro conferidos contra o manifesto")

        # A memória.
        problemas += _comparar("governance._versions", dados["governance_versions"], leitura.versoes_do_armazem(armazem))
        problemas += _comparar("snapshots SCD", dados["oraculo_scd"], leitura.oraculo_scd(armazem))
        problemas += _comparar("memória de exclusões", dados["oraculo_exclusoes"], leitura.oraculo_das_exclusoes(armazem))
        problemas += _conferir_capturas_e_geracoes(dados, armazem, depois_da_carga_nova=True)

        # A captura nova: a identidade que o Airbyte devolveu, não um número do plano.
        capturas = leitura.oraculo_das_capturas(armazem)
        retido = dados["oraculo_capturas"]["maior_snapshot"]
        novas = sorted(set(capturas["certificadas"]) - set(dados["oraculo_capturas"]["certificadas"]))
        desde_o_corte = leitura.capturas_certificadas_desde(armazem, dados["corte"])
        if not novas:
            problemas.append("nenhuma captura certificada além das do manifesto — a sincronização do passo 8 não produziu identidade nova")
        if retido is not None and [c for c in novas if c <= retido]:
            problemas.append(f"captura(s) nova(s) com identidade não acima da retida ({retido}): {novas}")
        if novas != desde_o_corte:
            problemas.append(
                f"as capturas novas ({novas}) não são as certificadas depois do corte ({desde_o_corte})"
            )
        # O job vem do passo 8, sempre (RVE2-01): sem ele, "as capturas novas"
        # seriam as que o banco diz, e o que se quer provar é o que o Airbyte
        # devolveu a quem disparou.
        if novas != [args.job]:
            problemas.append(f"o job disparado foi {args.job}, e as capturas novas são {novas}")
        for tabela, geracao in capturas["geracoes_por_tabela"].items():
            if geracao["maxima"] is not None and geracao["maxima"] < 0:
                problemas.append(f"{tabela}: a carga nova não escreveu nada — só há gerações retidas")

        quarentena = leitura.oraculo_da_quarentena(armazem)
        problemas += [f"quarentena: {p}" for p in oraculos.contido(dados["oraculo_quarentena"], quarentena)]
        acrescimo = oraculos.acrescimo(dados["oraculo_quarentena"], quarentena)
        estranhas = [chave for chave in acrescimo if leitura.snapshot_da_fatia(chave) not in novas]
        if estranhas:
            problemas.append(f"quarentena: fatia(s) acrescentadas que não são da captura nova: {estranhas[:3]}")
        problemas += _conferir_auditoria_da_captura_nova(armazem, novas, acrescimo)
        print(
            f"[recovery] quarentena: {len(dados['oraculo_quarentena'])} fatia(s) do manifesto contidas, "
            f"{len(acrescimo)} acrescentada(s) pela(s) captura(s) {novas}"
        )

        # O livro: os dois caminhos, e o tamanho que eles precisam ter.
        caminhos = leitura.comparar_caminhos(armazem, sequencia)
        for campo in ("so_no_lote", "so_no_fluxo", "payloads_diferentes", "saldos_diferentes"):
            if caminhos[campo]:
                problemas.append(f"caminhos do livro: {campo} = {caminhos[campo]} (esperado 0)")
        if caminhos["soma_lote"] != caminhos["soma_fluxo"]:
            problemas.append(f"caminhos do livro: soma dos deltas {caminhos['soma_lote']} × {caminhos['soma_fluxo']}")
        na_origem = contagens_da_origem.get(leitura.LIVRO_NA_ORIGEM)
        if na_origem is None:
            problemas.append(f"caminhos do livro: {leitura.LIVRO_NA_ORIGEM} não foi contado na origem")
        elif (caminhos["linhas_lote"], caminhos["linhas_fluxo"]) != (na_origem, na_origem):
            problemas.append(
                f"caminhos do livro: {caminhos['linhas_lote']} no lote e {caminhos['linhas_fluxo']} no fluxo "
                f"até o corte, e a origem tem {na_origem} — iguais entre si não é o livro de volta"
            )
        print(
            f"[recovery] livro até {caminhos['corte']}: {caminhos['linhas_lote']} no lote, "
            f"{caminhos['linhas_fluxo']} no fluxo; só num lado {caminhos['so_no_lote']}/{caminhos['so_no_fluxo']}, "
            f"payloads diferentes {caminhos['payloads_diferentes']}, saldos diferentes {caminhos['saldos_diferentes']}, "
            f"soma dos deltas {caminhos['soma_lote']} × {caminhos['soma_fluxo']}"
        )

        selecionada = max(capturas["certificadas"]) if capturas["certificadas"] else None
        if selecionada is not None:
            print(f"[recovery] captura selecionada: {selecionada} (certificada)")
    finally:
        for motor in (origem, legado, armazem):
            motor.dispose()

    for problema in problemas:
        print(f"  {problema}", file=sys.stderr)
    if problemas:
        print(f"\nconferir-restauracao: {len(problemas)} problema(s)", file=sys.stderr)
        return 1
    print(
        "conferir-restauracao: fontes iguais ao manifesto, memória contida e intacta, identidade "
        "nova acima da retida, auditoria dela igual ao que a classificação rejeitou, memória de "
        "exclusões renascida igual, livro da origem inteiro e igual nos dois caminhos.\n"
        "  As oito fronteiras e os testes de dados são do `make check` do passo 8."
    )
    return 0


def _pasta_do_pacote(args: argparse.Namespace) -> pathlib.Path:
    destino = _destino(args)
    return destino.candidato if destino.candidato.exists() else destino.aprovado


def comando_promote(args: argparse.Namespace) -> int:
    aprovado = pacote.promover(_destino(args))
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
        "avancar-jobs", help="avança o contador de jobs de um Airbyte novo para além da captura retida (D50)"
    ).set_defaults(func=comando_avancar_jobs)
    cr = sub.add_parser("conferir-restauracao", help="os oráculos explícitos do passo 9")
    cr.add_argument(
        "--job", type=int, required=True,
        help="o jobId da sincronização do legado disparada no passo 8 (o Makefile o traz de lá)",
    )
    cr.set_defaults(func=comando_conferir_restauracao)
    sub.add_parser("promote", help="candidato/ → aprovado/").set_defaults(func=comando_promote)

    args = p.parse_args(argv)
    try:
        return args.func(args)
    except pacote.PacoteRecusado as erro:
        print(f"RECUSADO — {erro}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
