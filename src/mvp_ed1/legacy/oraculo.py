"""O esperado independente por ocorrência — o que a classificação **deve** dizer de cada linha.

Antes disto o manifesto sabia dizer, por ocorrência, só o que o injetor tinha
feito com ela. A classificação diz mais: cascata, duplicata, órfão, total do
pedido, obrigatoriedade — e nada disso tinha esperado independente (achado R13
da terceira revisão). Este módulo calcula, para **toda** ocorrência gerada, o
multiconjunto de achados, a saída e a origem da rejeição que a classificação
tem de produzir, a partir de três coisas e só delas:

* as **mutações que o injetor aplicou** (os achados de valor do manifesto, com
  o contrato `recuperacao` do catálogo dizendo o que cada conversão devolve);
* o **conjunto final de linhas** degradadas — é sobre ele que duplicata exata,
  chave conflitante, órfão e total do pedido são recomputados, porque o injetor
  pode desfazer sem querer o que declarou (um defeito de valor injetado na
  cópia de uma duplicata exata a torna inexata);
* a **declaração compartilhada**: os modelos SQLAlchemy (chaves, unicidades,
  referências, obrigatoriedade) e o catálogo (códigos, ação, tolerância).

O que este módulo **não** lê, de propósito: `classification.py`, `dbt.py`,
`ponte.py`, qualquer SQL gerado ou o banco. Dois algoritmos do mesmo autor
concordando não provam nada se um copiou o outro; a independência aqui é de
insumo, e as contraprovas por mutação em `tests/test_legado.py` são o que
mostra que a concordância não é trivial.

A semântica implementada é a dos ADRs 0038 e 0040, com os quatro casos que a
documentação não decidia fechados pelo Owner em 14/09/2026 (Origem Legada §5):

* excedente de duplicata exata **não** é pai — a referência resolve à canônica,
  e se ela está apta o filho não cascateia;
* duplicata parcial rejeita as duas versões, logo nenhuma está apta e os filhos
  cascateiam;
* filho de pai cuja chave ficou nula é **órfão** (`FK_ORPHAN`, defeito próprio),
  não cascata — o vínculo não resolve para ocorrência nenhuma;
* num ciclo com raiz rejeitada toda a componente é `rejected`, e a **raiz
  conserva a causa própria** (`own_invalid`); só os alcançados são
  `parent_rejected`.
"""

from __future__ import annotations

import collections
import re
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from typing import Any

from sqlalchemy import Boolean, UniqueConstraint

from mvp_ed1.legacy import schema
from mvp_ed1.legacy.catalogo import Catalogo
from mvp_ed1.legacy.injetor import CORRIGIDO, REJEITADO, Resultado
from mvp_ed1.models import Base

#: Códigos que a classificação computa do **contexto**, e que por isso este
#: módulo recomputa em vez de copiar do manifesto.
DE_CONTEXTO = frozenset({"NULL_REQUIRED", "DUP_EXACT", "DUP_PARTIAL", "FK_ORPHAN", "TOTAL_MISMATCH"})
CASCATA = "PARENT_REJECTED"

ACCEPTED, CORRECTED, REJECTED = "accepted", "corrected", "rejected"
OWN_INVALID, DUPLICATE_EXCESS, PARENT_REJECTED = "own_invalid", "duplicate_excess", "parent_rejected"

Chave = tuple[str, int]


@dataclass(frozen=True)
class AchadoEsperado:
    """Um elemento do multiconjunto: código, coluna e o vínculo que o explica."""

    codigo: str
    coluna: str | None
    vinculo: tuple[Any, ...] | None = None

    def como_lista(self) -> list[Any]:
        return [self.codigo, self.coluna, list(self.vinculo) if self.vinculo is not None else None]


@dataclass
class Veredito:
    classification: str
    rejection_origin: str | None
    achados: list[AchadoEsperado] = field(default_factory=list)
    #: Valor esperado depois da limpeza, por coluna com achado corrigível.
    valores_esperados: dict[str, str | None] = field(default_factory=dict)

    def multiconjunto(self) -> collections.Counter:
        return collections.Counter(self.achados)


# ── Contrato por tabela, derivado dos modelos ─────────────────────────────────

_PREDICADO = re.compile(r"([a-z_]+)( is (?:not )?null)?")


@dataclass(frozen=True)
class Contrato:
    obrigatorias: tuple[str, ...]
    #: Cada unicidade: colunas e condições `(coluna, tipo)` com tipo em
    #: `is_null`, `is_not_null`, `is_true`.
    unicidades: tuple[tuple[tuple[str, ...], tuple[tuple[str, str], ...]], ...]
    #: Cada referência: `(coluna, tabela_pai, coluna_pai)`.
    referencias: tuple[tuple[str, str, str], ...]


def contrato(tabela: str) -> Contrato:
    """Obrigatoriedade, unicidades (inclusive parciais) e referências de uma tabela.

    Derivado **diretamente** do `Base.metadata`, com a mesma gramática restrita
    de predicado que a classificação aceita — índice único com predicado fora
    dela é erro aqui também, nunca unicidade incondicional por omissão.
    """
    modelo = Base.metadata.tables[f"oltp.{tabela}"]
    disponiveis = set(schema.colunas(tabela))
    chaves = {tuple(c.name for c in modelo.primary_key.columns)}
    chaves.update(
        tuple(c.name for c in item.columns)
        for item in modelo.constraints
        if isinstance(item, UniqueConstraint)
    )
    unicidades: list[tuple[tuple[str, ...], tuple[tuple[str, str], ...]]] = [
        (chave, ()) for chave in sorted(chaves) if chave and set(chave) <= disponiveis
    ]
    for indice in sorted(modelo.indexes, key=lambda i: i.name):
        if not indice.unique:
            continue
        condicoes: list[tuple[str, str]] = []
        predicado = indice.dialect_options["postgresql"].get("where")
        if predicado is not None:
            for clausula in str(predicado).split(" and "):
                casado = _PREDICADO.fullmatch(clausula)
                if not casado or casado[1] not in disponiveis:
                    raise ValueError(f"predicado de índice não suportado: {indice.name}")
                coluna, sufixo = casado.groups()
                if sufixo is None and not isinstance(modelo.c[coluna].type, Boolean):
                    raise ValueError(f"predicado não booleano: {indice.name}.{coluna}")
                condicoes.append((coluna, (sufixo or " is true").strip().replace(" ", "_")))
        unicidades.append((tuple(c.name for c in indice.columns), tuple(condicoes)))
    return Contrato(
        obrigatorias=tuple(c.name for c in modelo.columns if c.name in disponiveis and not c.nullable),
        unicidades=tuple(unicidades),
        referencias=tuple(
            (coluna.name, fk.column.table.name, fk.column.name)
            for coluna in modelo.columns
            for fk in sorted(coluna.foreign_keys, key=lambda f: f.target_fullname)
        ),
    )


# ── Valores ──────────────────────────────────────────────────────────────────

def _transportado(valor: Any) -> str | None:
    """O valor como chega ao bruto: string vazia é nulo (normalização de transporte)."""
    if valor is None:
        return None
    texto = str(valor)
    return None if texto == "" else texto


def _numerico(texto: str | None) -> Decimal | None:
    """`numeric` válido no PostgreSQL, ou `None`. Texto por extenso não é número."""
    if texto is None:
        return None
    candidato = texto.strip()
    if not re.fullmatch(r"[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?", candidato):
        return None
    try:
        return Decimal(candidato)
    except InvalidOperation:  # pragma: no cover — o regex já filtra
        return None


# ── O cálculo ────────────────────────────────────────────────────────────────

def esperar(catalogo: Catalogo, resultado: Resultado) -> dict[Chave, Veredito]:
    """Veredito esperado de **toda** ocorrência do lote."""
    linhas: dict[Chave, dict[str, Any]] = {}
    por_tabela: dict[str, list[Chave]] = collections.defaultdict(list)
    for tabela in schema.tabelas():
        for linha in resultado.linhas.get(tabela, ()):
            chave = (tabela, int(linha[schema.IDENTIDADE]))
            linhas[chave] = linha
            por_tabela[tabela].append(chave)

    # 1. Achados de valor do manifesto, e o payload **limpo** que a conversão
    #    deve produzir: original onde a recuperação é `original`, nulo onde é
    #    `nulo`, o texto defeituoso preservado onde a falha é rejeição.
    valor: dict[Chave, list[AchadoEsperado]] = collections.defaultdict(list)
    corrigidos: dict[Chave, bool] = collections.defaultdict(bool)
    limpo: dict[Chave, dict[str, str | None]] = {}
    esperados: dict[Chave, dict[str, str | None]] = collections.defaultdict(dict)
    for chave, linha in linhas.items():
        limpo[chave] = {c: _transportado(linha.get(c)) for c in schema.colunas(chave[0])}
    for achado in resultado.achados:
        if achado.codigo in DE_CONTEXTO or achado.coluna is None:
            continue
        chave = (achado.tabela, achado.legacy_row_id)
        if chave not in linhas:
            raise ValueError(f"achado sobre ocorrência inexistente: {achado}")
        valor[chave].append(AchadoEsperado(achado.codigo, achado.coluna))
        falha = catalogo.falhas[achado.codigo]
        if achado.resultado_esperado == CORRIGIDO:
            corrigidos[chave] = True
            esperado = achado.valor_original if falha.recuperacao == "original" else None
            limpo[chave][achado.coluna] = _transportado(esperado)
            esperados[chave][achado.coluna] = esperado

    contratos = {tabela: contrato(tabela) for tabela in schema.tabelas()}
    contexto: dict[Chave, list[AchadoEsperado]] = collections.defaultdict(list)

    # 2. Obrigatoriedade sobre o payload limpo.
    for chave in linhas:
        for coluna in contratos[chave[0]].obrigatorias:
            if limpo[chave][coluna] is None:
                contexto[chave].append(AchadoEsperado("NULL_REQUIRED", coluna))

    # 3. Duplicata exata: mesmo payload **original**; a canônica é a de menor
    #    identidade física, e é a única que existe para quem a referencia.
    canonica: dict[Chave, int] = {}
    for tabela, chaves in por_tabela.items():
        grupos: dict[tuple, list[int]] = collections.defaultdict(list)
        for chave in chaves:
            assinatura = tuple(_transportado(linhas[chave].get(c)) for c in schema.colunas(tabela))
            grupos[assinatura].append(chave[1])
        for identidades in grupos.values():
            menor = min(identidades)
            for identidade in identidades:
                canonica[(tabela, identidade)] = menor
                if identidade != menor:
                    contexto[(tabela, identidade)].append(
                        AchadoEsperado("DUP_EXACT", None, (menor,))
                    )

    # 4. Unicidades sobre o payload limpo: mesma chave completa, condições
    #    satisfeitas, payloads originais distintos — todas as versões caem.
    for tabela, chaves in por_tabela.items():
        for colunas, condicoes in contratos[tabela].unicidades:
            grupos: dict[tuple, dict[tuple, list[Chave]]] = collections.defaultdict(
                lambda: collections.defaultdict(list)
            )
            for chave in chaves:
                valores = tuple(limpo[chave][c] for c in colunas)
                if any(v is None for v in valores):
                    continue
                if not all(_condicao(limpo[chave], coluna, tipo) for coluna, tipo in condicoes):
                    continue
                original = tuple(_transportado(linhas[chave].get(c)) for c in schema.colunas(tabela))
                grupos[valores][original].append(chave)
            for versoes in grupos.values():
                if len(versoes) > 1:
                    for chaves_da_versao in versoes.values():
                        for chave in chaves_da_versao:
                            contexto[chave].append(AchadoEsperado("DUP_PARTIAL", None, colunas))

    # 5. Referências: resolvem só à canônica; sem canônica é órfão.
    indice_pai: dict[tuple[str, str, str], list[Chave]] = collections.defaultdict(list)
    for chave in linhas:
        if canonica[chave] != chave[1]:
            continue
        for coluna, texto in limpo[chave].items():
            if texto is not None:
                indice_pai[(chave[0], coluna, texto)].append(chave)
    arestas: dict[Chave, list[tuple[str, Chave]]] = collections.defaultdict(list)
    for chave in linhas:
        for coluna, tabela_pai, coluna_pai in contratos[chave[0]].referencias:
            texto = limpo[chave][coluna]
            if texto is None:
                continue
            pais = indice_pai.get((tabela_pai, coluna_pai, texto), [])
            if not pais:
                contexto[chave].append(AchadoEsperado("FK_ORPHAN", coluna, (tabela_pai, coluna_pai)))
            for pai in pais:
                arestas[chave].append((coluna, pai))

    # 6. Total do pedido contra o que a origem registrou (D33), descontando só
    #    a duplicata exata dos itens.
    tolerancia = catalogo.falhas["TOTAL_MISMATCH"].tolerance or Decimal("0")
    itens: dict[str, list[Chave]] = collections.defaultdict(list)
    for chave in por_tabela.get("order_items", ()):
        if canonica[chave] == chave[1] and limpo[chave].get("order_id") is not None:
            itens[limpo[chave]["order_id"]].append(chave)
    for chave in por_tabela.get("orders", ()):
        pedido = limpo[chave]
        total = _numerico(pedido.get("total_amount"))
        subtotal = _numerico(pedido.get("subtotal_amount"))
        partes = [_numerico(pedido.get(c)) for c in ("discount_amount", "shipping_amount", "tax_amount")]
        ajustes = None if any(p is None for p in partes) else -partes[0] + partes[1] + partes[2]
        divergente = total is not None and subtotal is not None and ajustes is not None and (
            total != subtotal + ajustes
        )
        if not divergente and subtotal is not None:
            do_pedido = itens.get(pedido.get("id"), [])
            brutos = []
            validos = True
            for item in do_pedido:
                quantidade = _numerico(limpo[item].get("quantity"))
                preco = _numerico(limpo[item].get("unit_price"))
                if quantidade is None or preco is None:
                    validos = False
                    continue
                brutos.append(quantidade * preco)
            if validos and abs(subtotal - sum(brutos, Decimal("0"))) > tolerancia:
                divergente = True
        if divergente:
            contexto[chave].append(AchadoEsperado("TOTAL_MISMATCH", "total_amount"))

    # 7. Raízes: defeito próprio que rejeita. Cascata até o ponto fixo, só sobre
    #    quem não é raiz — a raiz conserva a causa própria.
    def _rejeita(codigo: str) -> bool:
        return not catalogo.falhas[codigo].converte

    raizes = {
        chave
        for chave in linhas
        if any(_rejeita(a.codigo) for a in valor[chave]) or contexto[chave]
    }
    rejeitadas = set(raizes)
    while True:
        novas = {
            chave
            for chave, ligacoes in arestas.items()
            if chave not in rejeitadas and any(pai in rejeitadas for _, pai in ligacoes)
        }
        if not novas:
            break
        rejeitadas |= novas
    cascata: dict[Chave, list[AchadoEsperado]] = collections.defaultdict(list)
    for chave, ligacoes in arestas.items():
        if chave in raizes:
            continue
        for coluna, pai in ligacoes:
            if pai in rejeitadas:
                cascata[chave].append(AchadoEsperado(CASCATA, coluna, (pai[0], pai[1])))

    # 8. Saída e origem, com a precedência do ADR-0038.
    vereditos: dict[Chave, Veredito] = {}
    for chave in linhas:
        achados = valor[chave] + contexto[chave] + cascata[chave]
        proprio = any(_rejeita(a.codigo) and a.codigo != "DUP_EXACT" for a in valor[chave] + contexto[chave])
        excedente = any(a.codigo == "DUP_EXACT" for a in contexto[chave])
        rejeitada = chave in rejeitadas
        if rejeitada:
            saida, origem = REJECTED, (OWN_INVALID if proprio else DUPLICATE_EXCESS if excedente else PARENT_REJECTED)
        elif corrigidos[chave]:
            saida, origem = CORRECTED, None
        else:
            saida, origem = ACCEPTED, None
        vereditos[chave] = Veredito(saida, origem, achados, dict(esperados.get(chave, {})))
    return vereditos


def _condicao(limpo: dict[str, str | None], coluna: str, tipo: str) -> bool:
    texto = limpo.get(coluna)
    if tipo == "is_null":
        return texto is None
    if tipo == "is_not_null":
        return texto is not None
    if tipo == "is_true":
        return texto == "true"
    raise ValueError(f"condição desconhecida: {tipo}")


def conferir_com_o_injetor(resultado: Resultado, vereditos: dict[Chave, Veredito]) -> list[str]:
    """Todo achado de contexto que o injetor **declarou** precisa reaparecer no recomputado.

    É a consistência interna do oráculo: o injetor sabe que injetou um órfão; se
    o recômputo sobre as linhas finais não o encontra, ou o injetor desfez a
    própria injeção depois, ou este módulo está errado — nos dois casos é defeito
    do oráculo, e aparece antes de qualquer comparação com o banco.
    """
    divergencias = []
    for achado in resultado.achados:
        if achado.codigo not in DE_CONTEXTO:
            continue
        veredito = vereditos[(achado.tabela, achado.legacy_row_id)]
        if not any(a.codigo == achado.codigo for a in veredito.achados):
            divergencias.append(
                f"{achado.tabela}#{achado.legacy_row_id}: injetor declarou {achado.codigo}, "
                f"recomputado tem {[a.codigo for a in veredito.achados]}"
            )
        if achado.resultado_esperado == REJEITADO and veredito.classification != REJECTED:
            divergencias.append(
                f"{achado.tabela}#{achado.legacy_row_id}: injetor esperava rejeição por "
                f"{achado.codigo}, recomputado diz {veredito.classification}"
            )
    return divergencias


def serializar(vereditos: dict[Chave, Veredito]) -> list[list[Any]]:
    """Forma compacta para o manifesto: uma lista por ocorrência."""
    return [
        [tabela, identidade, v.classification, v.rejection_origin,
         [a.como_lista() for a in v.achados], v.valores_esperados]
        for (tabela, identidade), v in sorted(vereditos.items())
    ]


# ── Comparação com o que a classificação produziu ────────────────────────────

VINCULOS = {
    CASCATA: ("parent_table", "parent_row_id"),
    "DUP_EXACT": ("canonical_row_id",),
    "FK_ORPHAN": ("parent_table", "parent_key"),
    "DUP_PARTIAL": ("key_columns",),
}


def achado_obtido(codigo: str, coluna: str | None, contexto: dict[str, Any] | None) -> AchadoEsperado:
    """Um achado como a classificação o grava (`findings`), na forma do multiconjunto."""
    campos = VINCULOS.get(codigo)
    if campos is None:
        return AchadoEsperado(codigo, coluna)
    contexto = contexto or {}
    valores: list[Any] = []
    for campo in campos:
        valor = contexto.get(campo)
        valores.append(tuple(valor) if isinstance(valor, list) else valor)
    vinculo = valores[0] if codigo == "DUP_PARTIAL" else tuple(valores)
    return AchadoEsperado(codigo, coluna, vinculo)


@dataclass
class Divergencia:
    chave: Chave
    campo: str
    esperado: Any
    obtido: Any


def comparar(esperado: dict[Chave, Veredito], obtido: dict[Chave, Veredito]) -> list[Divergencia]:
    """Toda diferença, dos dois lados — precisão e *recall* no grão ocorrência × achado.

    Ocorrência que só existe de um lado é divergência; saída ou origem
    diferentes são divergência; e o multiconjunto de achados é comparado como
    multiconjunto, para que uma duplicidade indevida não se esconda num
    conjunto.
    """
    divergencias: list[Divergencia] = []
    for chave in sorted(set(esperado) | set(obtido)):
        e, o = esperado.get(chave), obtido.get(chave)
        if e is None or o is None:
            divergencias.append(Divergencia(chave, "ocorrencia", e is not None, o is not None))
            continue
        if e.classification != o.classification:
            divergencias.append(Divergencia(chave, "classification", e.classification, o.classification))
        if e.rejection_origin != o.rejection_origin:
            divergencias.append(Divergencia(chave, "rejection_origin", e.rejection_origin, o.rejection_origin))
        faltando = e.multiconjunto() - o.multiconjunto()
        sobrando = o.multiconjunto() - e.multiconjunto()
        if faltando or sobrando:
            divergencias.append(
                Divergencia(chave, "achados", sorted(map(str, faltando.elements())), sorted(map(str, sobrando.elements())))
            )
    return divergencias
