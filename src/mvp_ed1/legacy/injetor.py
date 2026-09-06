"""Degradação dos valores e injeção dos defeitos declarados.

O gerador do legado **não** produz dados do zero: ele parte de um conjunto
consistente, produzido pelo mesmo motor da origem principal, e o degrada. É
assim porque o legado precisa ser *logicamente idêntico* ao transacional
(Origem Legada §2) — reescrever a geração daria uma segunda definição do
domínio, que divergiria da primeira no dia seguinte.

São duas passagens, nesta ordem:

    degradar   todo valor vira texto, como uma origem sem tipagem o guardaria
    injetar    os defeitos do catálogo entram, um alvo por vez, com manifesto

O **manifesto** sai daqui e é o oráculo dos testes. Ele registra o que foi feito
a cada ocorrência: código, coluna, valor antes, valor depois e o resultado que o
tratamento deve alcançar. A transformação nunca o lê.
"""

from __future__ import annotations

import datetime as dt
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from mvp_ed1.generator import enums
from mvp_ed1.generator.rng import Fonte
from mvp_ed1.legacy import schema
from mvp_ed1.legacy.catalogo import Catalogo, Falha
from mvp_ed1.models import Base

#: Resultados possíveis do tratamento, na ordem de precedência da Origem Legada
#: §3.1.1: rejeição vence conversão, que vence aceitação.
REJEITADO, CORRIGIDO, ACEITO = "rejected", "corrected", "accepted"

_POR_EXTENSO = {
    1: "um", 2: "dois", 3: "três", 4: "quatro", 5: "cinco",
    6: "seis", 7: "sete", 8: "oito", 9: "nove", 10: "dez",
}


@dataclass
class Achado:
    """Uma falha aplicada a uma ocorrência. Linha do manifesto."""

    tabela: str
    legacy_row_id: int
    coluna: str | None
    codigo: str
    valor_original: str | None
    valor_legado: str | None
    resultado_esperado: str


@dataclass
class Resultado:
    linhas: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    achados: list[Achado] = field(default_factory=list)

    def resultado_por_ocorrencia(self) -> dict[tuple[str, int], str]:
        """Classificação esperada de cada ocorrência, aplicando a precedência.

        Todos os achados são registrados; a **ocorrência** é contada uma vez só.
        """
        veredito: dict[tuple[str, int], str] = {}
        for a in self.achados:
            chave = (a.tabela, a.legacy_row_id)
            atual = veredito.get(chave)
            if atual == REJEITADO:
                continue
            if a.resultado_esperado == REJEITADO or atual is None:
                veredito[chave] = a.resultado_esperado
        return veredito


def _texto(valor: Any) -> str | None:
    """Como uma origem sem tipagem guardaria o valor."""
    if valor is None:
        return None
    if isinstance(valor, bool):
        return "true" if valor else "false"
    if isinstance(valor, dt.datetime):
        return valor.isoformat()
    if isinstance(valor, dt.date):
        return valor.isoformat()
    if isinstance(valor, Decimal):
        return f"{valor:f}"
    return str(valor)


def degradar(dados: dict[str, list[dict[str, Any]]]) -> dict[str, list[dict[str, Any]]]:
    """Converte o conjunto consistente para a representação frouxa do legado.

    Acrescenta `legacy_row_id` — a identidade física da ocorrência, sem a qual
    duas linhas idênticas seriam indistinguíveis (ADR-0038).
    """
    saida: dict[str, list[dict[str, Any]]] = {}
    for tabela in schema.tabelas():
        colunas = schema.colunas(tabela)
        linhas = []
        for i, linha in enumerate(dados.get(tabela, ()), start=1):
            nova = {schema.IDENTIDADE: i}
            nova.update({c: _texto(linha.get(c)) for c in colunas})
            linhas.append(nova)
        saida[tabela] = linhas
    return saida


class Injetor:
    """Aplica o catálogo sobre o conjunto degradado."""

    def __init__(self, catalogo: Catalogo, promessas: frozenset[str], as_of: dt.date) -> None:
        self.catalogo = catalogo
        self.promessas = promessas
        self.as_of = as_of

    def _fonte(self, codigo: str) -> Fonte:
        """Uma fonte por falha: acrescentar uma não desloca o sorteio das outras."""
        return Fonte(self.catalogo.semente, self.as_of, f"legacy:{codigo}", "pt_BR")

    def alvos(self, resultado: Resultado, falha: Falha) -> list[tuple[str, str]]:
        """Pares (tabela, coluna) que a falha alcança e que têm valor a estragar."""
        pares = []
        for tabela, linhas in resultado.linhas.items():
            if not linhas:
                continue
            for coluna in schema.colunas(tabela):
                arq = schema.arquetipo(tabela, coluna, self.promessas)
                if schema.alcanca(falha.arquetipo, arq):
                    pares.append((tabela, coluna))
        return pares


# ── As formas de estragar um valor ───────────────────────────────────────────
# Uma função por forma declarada no catálogo. O nome da função **é** o nome da
# forma: uma forma no YAML sem função aqui falha na injeção, e não em silêncio.


def _por_extenso(valor: str, fonte: Fonte, **_: Any) -> str:
    return _POR_EXTENSO.get(int(valor), valor)


def _decimal_zero(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"{valor}.0"


def _decimal_virgula_zero(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"{valor},0"


def _fracionario(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"{valor}.5"


def _com_unidade(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"{_POR_EXTENSO.get(int(valor), valor)} caixas"


def _vazio(valor: str, fonte: Fonte, **_: Any) -> str:
    return ""


def _negativo(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"-{valor.lstrip('-')}"


def _absurdamente_alto(valor: str, fonte: Fonte, **_: Any) -> str:
    return str(fonte.inteiro(10_000_000, 99_999_999))


def _pt_br(valor: str, fonte: Fonte, **_: Any) -> str:
    inteiro, _, decimal = valor.partition(".")
    return f"{int(inteiro):,}".replace(",", ".") + f",{(decimal or '00')[:2]:0<2}"


def _en_us(valor: str, fonte: Fonte, **_: Any) -> str:
    inteiro, _, decimal = valor.partition(".")
    return f"{int(inteiro):,}" + f".{(decimal or '00')[:2]:0<2}"


def _com_simbolo(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"R$ {_pt_br(valor, fonte)}"


def _dd_mm_aaaa(valor: str, fonte: Fonte, **_: Any) -> str:
    d = dt.datetime.fromisoformat(valor)
    return d.strftime("%d/%m/%Y")


def _aaaa_ponto_mm_dd(valor: str, fonte: Fonte, **_: Any) -> str:
    d = dt.datetime.fromisoformat(valor)
    return d.strftime("%Y.%m.%d")


def _mes_invalido(valor: str, fonte: Fonte, **_: Any) -> str:
    d = dt.datetime.fromisoformat(valor)
    return f"{d.day:02d}/13/{d.year}"


def _dia_inexistente(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"31/02/{dt.datetime.fromisoformat(valor).year}"


def _so_mes_e_ano(valor: str, fonte: Fonte, **_: Any) -> str:
    d = dt.datetime.fromisoformat(valor)
    return f"{d.month:02d}/{d.year}"


def _depois_do_corte(valor: str, fonte: Fonte, *, as_of: dt.date, **_: Any) -> str:
    d = dt.datetime.fromisoformat(valor)
    futuro = dt.datetime.combine(as_of, dt.time(12, 0), tzinfo=d.tzinfo) + dt.timedelta(
        days=fonte.inteiro(30, 400)
    )
    return futuro.isoformat()


def _sem_fuso(valor: str, fonte: Fonte, **_: Any) -> str:
    return dt.datetime.fromisoformat(valor).replace(tzinfo=None).isoformat(sep=" ")


def _utf8_como_latin1(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.encode("utf-8").decode("latin-1")


def _espaco_a_volta(valor: str, fonte: Fonte, **_: Any) -> str:
    return f"  {valor} "


def _caixa_alterada(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.upper() if not valor.isupper() else valor.lower()


def _espaco_duplo(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.replace(" ", "  ", 1) if " " in valor else f"{valor}  "


def _cortado_no_limite(valor: str, fonte: Fonte, *, limite: int, **_: Any) -> str:
    """Corta no limite da coluna antiga — e só quando há o que perder.

    A primeira versão repetia o valor até encher a coluna moderna, o que produzia
    `PRD-000005PRD-000005PRD-000005PR`: comprimento certo, aparência de nada.
    Truncamento de verdade é um valor **longo** entrando numa coluna estreita, e
    o que sobra é o começo dele. Valor mais curto que a coluna não é truncável, e
    devolvê-lo intacto faz o injetor procurar outro alvo.
    """
    return valor[:limite] if len(valor) > limite else valor


def _marcador_textual(valor: str, fonte: Fonte, *, marcadores: tuple[str, ...], **_: Any) -> str:
    return fonte.escolha(marcadores)


def _sim_nao(valor: str, fonte: Fonte, **_: Any) -> str:
    return "sim" if valor == "true" else "não"


def _s_n(valor: str, fonte: Fonte, **_: Any) -> str:
    return "S" if valor == "true" else "N"


def _um_zero(valor: str, fonte: Fonte, **_: Any) -> str:
    return "1" if valor == "true" else "0"


def _valor_inexistente(valor: str, fonte: Fonte, *, dominio: tuple[str, ...] = (), **_: Any) -> str:
    """Como o sistema antigo escrevia o mesmo estado: abreviado e em caixa alta.

    `adjustment_legado` denunciava a si mesmo — nenhum sistema grava assim. Uma
    sigla de três letras é o que uma origem dos anos noventa realmente teria, e
    obriga o tratamento a rejeitar por **não reconhecer**, que é o ponto, em vez
    de por encontrar uma marca óbvia.
    """
    sigla = valor[:3].upper()
    return sigla if sigla not in {v.upper() for v in dominio} else f"{sigla}9"


def _sem_arroba(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.replace("@", ".", 1)


def _com_espaco(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.replace("@", " @", 1)


def _dominio_invalido(valor: str, fonte: Fonte, **_: Any) -> str:
    return valor.split("@")[0] + "@dominio"


def _id_inexistente(valor: str, fonte: Fonte, **_: Any) -> str:
    return str(fonte.inteiro(900_000, 999_999))


FORMAS = {
    nome: funcao
    for nome, funcao in list(globals().items())
    if nome.startswith("_") and callable(funcao) and nome[1:2].isalpha()
}


# ── Formas que atingem a linha inteira ───────────────────────────────────────
# Não são transformação de valor: mexem na existência ou na coerência da
# ocorrência. Por isso ficam fora de `FORMAS` e são orquestradas à parte.

#: Colunas que nunca recebem defeito de valor. Estragar a identidade física
#: tornaria a própria ocorrência irrastreável, e o manifesto perderia a que
#: linha ele se refere.
INTOCAVEIS = frozenset({schema.IDENTIDADE})


def _proximo_id(linhas: list[dict[str, Any]]) -> int:
    return max((l[schema.IDENTIDADE] for l in linhas), default=0) + 1


class _Aplicador:
    """Executa uma falha do catálogo sobre o conjunto degradado."""

    def __init__(self, injetor: "Injetor", resultado: Resultado) -> None:
        self.i = injetor
        self.r = resultado
        #: Células já estragadas. Uma segunda falha na mesma célula sobrescreve
        #: o valor da primeira, e o manifesto passa a declarar um achado que não
        #: existe mais — o oráculo mentindo. Foram dois casos assim, e os dois
        #: apareceram como "regra não detecta" antes de a causa ficar clara.
        self.ocupadas: set[tuple[str, int, str]] = set()
        self.limites = schema.limites(
            injetor.catalogo.limite_de_texto, injetor.catalogo.colunas_estreitadas
        )

    def executar(self, falha: Falha) -> int:
        fonte = self.i._fonte(falha.codigo)
        metodo = getattr(self, f"_{falha.arquetipo}", None)
        if metodo is not None:
            return metodo(falha, fonte)
        return self._por_coluna(falha, fonte)

    # ── Caso geral: um valor, uma coluna ─────────────────────────────────────
    def _por_coluna(self, falha: Falha, fonte: Fonte) -> int:
        alvos = self.i.alvos(self.r, falha)
        if not alvos:
            return 0
        aplicadas = 0
        for _ in range(falha.frequencia):
            for _tentativa in range(40):
                tabela, coluna = fonte.escolha(alvos)
                if coluna in INTOCAVEIS:
                    continue
                if not self._injetavel(falha, tabela, coluna):
                    continue
                linhas = self.r.linhas[tabela]
                linha = fonte.escolha(linhas)
                if (tabela, linha[schema.IDENTIDADE], coluna) in self.ocupadas:
                    continue
                original = linha.get(coluna)
                if original in (None, ""):
                    continue
                forma = fonte.escolha(list(falha.formas))
                if forma == "absorve_os_seguintes":
                    if not self._absorver(falha, tabela, linha, coluna):
                        continue
                    self.ocupadas.add((tabela, linha[schema.IDENTIDADE], coluna))
                    aplicadas += 1
                    break
                try:
                    novo = FORMAS[f"_{forma}"](
                        original,
                        fonte,
                        as_of=self.i.as_of,
                        limite=self.limites.get((tabela, coluna), len(original)),
                        marcadores=self.i.catalogo.nulos_disfarcados,
                        dominio=enums.enumeracoes().get(tabela, {}).get(coluna, ()),
                    )
                except (ValueError, KeyError, TypeError):
                    continue
                if novo == original:
                    continue
                linha[coluna] = novo
                self.ocupadas.add((tabela, linha[schema.IDENTIDADE], coluna))
                self._registrar(falha, tabela, linha, coluna, original, novo)
                aplicadas += 1
                break
        return aplicadas

    # ── Delimitador: o campo absorve os seguintes, que ficam vazios ──────────
    def _absorver(self, falha: Falha, tabela: str, linha: dict, coluna: str) -> bool:
        """Simula a linha deslocada na importação por CSV.

        Numa coluna PostgreSQL o delimitador **não** desloca nada sozinho: quem
        deslocava era o carregador de arquivo da origem antiga. O efeito
        observável, e o único que faz sentido reproduzir, é este — o campo
        carrega o resto da linha, e os seguintes ficam vazios.
        """
        colunas = [c for c in schema.colunas(tabela) if c not in INTOCAVEIS]
        posicao = colunas.index(coluna)
        seguintes = colunas[posicao + 1 : posicao + 3]

        # As colunas engolidas ficam vazias, e isso **apaga** qualquer defeito
        # que já estivesse nelas: o achado continuaria no manifesto sem existir
        # no dado. Aconteceu uma vez, e apareceu disfarçado de "a regra de
        # booleano não detecta" — o valor tinha sido comido pelo vizinho.
        identidade = linha[schema.IDENTIDADE]
        if any((tabela, identidade, c) in self.ocupadas for c in seguintes):
            return False

        engolidos = [linha.get(c) for c in seguintes if linha.get(c)]
        if not engolidos:
            return False
        original = linha[coluna]
        delim = self.i.catalogo.delimitador
        linha[coluna] = delim.join([original, *engolidos])
        for c in seguintes:
            if linha.get(c):
                linha[c] = ""
            self.ocupadas.add((tabela, identidade, c))
        self._registrar(falha, tabela, linha, coluna, original, linha[coluna])
        return True

    # ── Linha repetida: a duplicata exata ────────────────────────────────────
    def _registro(self, falha: Falha, fonte: Fonte) -> int:
        aplicadas = 0
        for _ in range(falha.frequencia):
            tabela = fonte.escolha(self._tabelas_alvo())
            linhas = self.r.linhas[tabela]
            original = fonte.escolha(linhas)
            copia = dict(original)
            copia[schema.IDENTIDADE] = _proximo_id(linhas)
            linhas.append(copia)
            # A canônica é a de menor identificador (ADR-0038): ela não é
            # achado. Só a excedente entra no manifesto.
            self.r.achados.append(
                Achado(
                    tabela=tabela,
                    legacy_row_id=copia[schema.IDENTIDADE],
                    coluna=None,
                    codigo=falha.codigo,
                    valor_original=str(original[schema.IDENTIDADE]),
                    valor_legado=str(copia[schema.IDENTIDADE]),
                    resultado_esperado=REJEITADO,
                )
            )
            aplicadas += 1
        return aplicadas

    # ── Mesma chave natural, atributo divergente ─────────────────────────────
    def _chave_natural(self, falha: Falha, fonte: Fonte) -> int:
        aplicadas = 0
        candidatas = [t for t in self._tabelas_alvo() if len(self.r.linhas[t]) > 1]
        for _ in range(falha.frequencia):
            tabela = fonte.escolha(candidatas)
            linhas = self.r.linhas[tabela]
            original = fonte.escolha(linhas)
            # Só coluna de **texto livre**. Acrescentar " (rev)" a um timestamp
            # produz `2025-07-01T00:09:09-03:00 (rev)`, que não é duplicata
            # parcial: é valor malformado, que é outra falha do catálogo. O
            # ponto do `DUP_PARTIAL` é a mesma chave com atributo **divergente**
            # e válido — a ambiguidade está em qual das duas versões vale, não
            # em nenhuma delas ser legível.
            texto = [
                c
                for c in schema.colunas(tabela)
                if c != "id"
                and isinstance(original.get(c), str)
                and original.get(c)
                and schema.arquetipo(tabela, c, self.i.promessas)
                in ("texto", "texto_com_limite")
            ]
            if not texto:
                continue
            coluna = fonte.escolha(texto)
            copia = dict(original)
            copia[schema.IDENTIDADE] = _proximo_id(linhas)
            copia[coluna] = f"{original[coluna]} (rev)"
            linhas.append(copia)
            # As duas versões são rejeitadas: não há critério de desempate. E as
            # duas registram a **divergência**, não o próprio valor: um achado
            # em que original e legado são iguais não ilustra nada, e foi o que
            # tornou este código ilegível no manifesto da primeira geração.
            for linha in (original, copia):
                self.r.achados.append(
                    Achado(
                        tabela=tabela,
                        legacy_row_id=linha[schema.IDENTIDADE],
                        coluna=coluna,
                        codigo=falha.codigo,
                        valor_original=original[coluna],
                        valor_legado=copia[coluna],
                        resultado_esperado=REJEITADO,
                    )
                )
            aplicadas += 1
        return aplicadas

    # ── Total que não reconcilia com os itens ────────────────────────────────
    def _total_do_pedido(self, falha: Falha, fonte: Fonte) -> int:
        linhas = self.r.linhas.get("orders", [])
        if not linhas:
            return 0
        aplicadas = 0
        for _ in range(falha.frequencia):
            linha = fonte.escolha(linhas)
            original = linha.get("total_amount")
            if not original:
                continue
            novo = f"{Decimal(original) + Decimal(fonte.inteiro(50, 900)):f}"
            linha["total_amount"] = novo
            self._registrar(falha, "orders", linha, "total_amount", original, novo)
            aplicadas += 1
        return aplicadas

    def _tabelas_alvo(self) -> list[str]:
        """Tabelas que podem receber defeito de linha inteira."""
        return [
            t
            for t, linhas in self.r.linhas.items()
            if linhas and t not in self.i.catalogo.dominios_fechados
        ]

    def _injetavel(self, falha: Falha, tabela: str, coluna: str) -> bool:
        """A falha seria mesmo um defeito **nesta** coluna?

        Injetar negativo em `quantity_delta` produziria um movimento de saída
        perfeitamente legítimo, e cortar `currency` no limite produziria `BRL`
        — que é o valor certo. Um defeito que não é defeito nunca seria
        detectado, e o oráculo falharia por culpa da injeção.
        """
        if tabela in self.i.catalogo.dominios_fechados:
            return False
        qualificado = f"{tabela}.{coluna}"
        if falha.codigo == "NUM_OUT_OF_RANGE":
            return qualificado not in self.i.catalogo.quantidades_com_sinal
        if falha.codigo == "TEXT_TRUNCATED":
            return qualificado in self.i.catalogo.colunas_estreitadas
        return True

    def _registrar(
        self, falha: Falha, tabela: str, linha: dict, coluna: str, antes: str, depois: str
    ) -> None:
        self.r.achados.append(
            Achado(
                tabela=tabela,
                legacy_row_id=linha[schema.IDENTIDADE],
                coluna=coluna,
                codigo=falha.codigo,
                valor_original=antes,
                valor_legado=depois,
                resultado_esperado=CORRIGIDO if falha.converte else REJEITADO,
            )
        )


def injetar(
    catalogo: Catalogo,
    dados: dict[str, list[dict[str, Any]]],
    *,
    promessas: frozenset[str],
    as_of: dt.date,
) -> Resultado:
    """Degrada o conjunto e aplica o catálogo inteiro sobre ele.

    A ordem entre as falhas é a de declaração no YAML, e é determinística: cada
    falha tem a sua própria fonte de aleatoriedade, então acrescentar uma ao
    catálogo não desloca o sorteio das outras.
    """
    resultado = Resultado(linhas=degradar(dados))
    aplicador = _Aplicador(Injetor(catalogo, promessas, as_of), resultado)
    for falha in catalogo.injetaveis:
        aplicador.executar(falha)
    _record_required_nulls(catalogo, resultado)
    return resultado


def _record_required_nulls(catalog: Catalogo, result: Resultado) -> None:
    """Oráculo da D32, sem executar o limpador nem alterar os dados injetados.

    A ausência é reconhecida diretamente nos marcadores declarados e nos
    campos vazios da importação deslocada. Inclui nulo que já veio da base;
    é achado derivado, não uma segunda injeção na mesma célula.
    """
    if "NULL_REQUIRED" not in catalog.falhas:
        return
    for table, rows in result.linhas.items():
        metadata = Base.metadata.tables[f"oltp.{table}"]
        required = [c for c in schema.colunas(table) if not metadata.c[c].nullable]
        for row in rows:
            for column in required:
                value = row.get(column)
                missing = value is None or value.strip() == "" or value.strip() in catalog.nulos_disfarcados
                if missing:
                    result.achados.append(Achado(
                        tabela=table, legacy_row_id=row[schema.IDENTIDADE], coluna=column,
                        codigo="NULL_REQUIRED", valor_original=value, valor_legado=None,
                        resultado_esperado=REJEITADO,
                    ))
