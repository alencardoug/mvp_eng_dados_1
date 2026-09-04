"""Motor de geração.

O motor não sabe o que é um pedido. Ele sabe três coisas: quantas linhas cada
tabela precisa ter (da configuração), que colunas existem e de que tipo (dos
modelos) e como produzir um valor (do YAML ou do tipo). O que é um pedido está
nos construtores de domínio, que montam o **esqueleto** das linhas — quem é
filho de quem, qual data veio antes de qual — e entregam ao motor para
preencher o resto.

Essa divisão é o que mantém o ADR-0005 honesto. Cardinalidade e distribuição
são declaração; causalidade de negócio é código, pequeno e por domínio, do
mesmo jeito que o ADR previu ao reservar os "provedores próprios".
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Any, Iterable

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    Uuid,
)

from mvp_ed1.generator import enums
from mvp_ed1.generator.config import Config
from mvp_ed1.generator.providers import Provedores
from mvp_ed1.generator.rng import Fonte, Relogio

#: Prefixo de campo auxiliar: vive na linha durante a geração e não vai ao banco.
AUXILIAR = "__"

#: Colunas dos mixins. Não passam pelo preenchimento por tipo: quem as decide é
#: `_marcas_de_tempo`, a partir do tempo de negócio da linha. Deixá-las cair no
#: padrão por tipo daria a `created_at` uma data uniforme no período — e a
#: `deleted_at` um valor preenchido em *toda* linha, que apagaria o banco
#: inteiro do ponto de vista de quem lê exclusão lógica.
MARCAS_DE_TEMPO = ("created_at", "updated_at", "deleted_at")


class Motor:
    def __init__(
        self,
        config: Config,
        *,
        seed: int | None = None,
        as_of_date: dt.date | None = None,
        fator: str | float | None = None,
    ) -> None:
        self.config = config
        self.seed = config.seed if seed is None else seed
        self.as_of_date = config.as_of_date if as_of_date is None else as_of_date
        self.fator = fator
        self.fim = dt.datetime.combine(self.as_of_date, dt.time(0, 0), config.fuso)
        self.inicio = config.inicio
        self.relogio = Relogio(
            self.inicio, self.fim, config.pesos_por_mes, config.pesos_por_hora
        )
        self.provedores = Provedores(self.inicio, self.fim)
        self._fontes: dict[str, Fonte] = {}

    # ── Recursos por tabela ──────────────────────────────────────────────────
    def fonte(self, tabela: str) -> Fonte:
        """Fonte de aleatoriedade da tabela, criada uma vez e reusada."""
        if tabela not in self._fontes:
            self._fontes[tabela] = Fonte(
                self.seed, self.as_of_date, tabela, self.config.localidade
            )
        return self._fontes[tabela]

    def linhas(self, tabela: str) -> int:
        return self.config.linhas(tabela, self.fator)

    # ── Preenchimento ────────────────────────────────────────────────────────
    def preencher(self, tabela: str, esqueletos: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
        """Completa cada esqueleto com o que ainda falta para virar uma linha.

        O que o construtor de domínio já colocou é lei — o motor nunca
        sobrescreve. Ele só preenche o vazio, e para de vez se encontrar uma
        chave estrangeira obrigatória que ninguém definiu: seguir adiante ali
        significaria descobrir o problema no `COPY`, sem saber de que linha veio.
        """
        modelo = enums.tabela(tabela)
        fonte = self.fonte(tabela)
        spec_da_tabela = self.config.tabelas[tabela]
        linhas: list[dict[str, Any]] = []

        for indice, linha in enumerate(esqueletos):
            if "id" in modelo.columns and "id" not in linha:
                linha["id"] = indice + 1
            for coluna in modelo.columns:
                nome = coluna.name
                if nome in linha or nome in MARCAS_DE_TEMPO or _gerada_pelo_banco(coluna):
                    continue
                if coluna.foreign_keys:
                    if coluna.nullable:
                        linha[nome] = None
                        continue
                    raise ValueError(
                        f"{tabela}.{nome}: chave estrangeira obrigatória não definida pelo "
                        f"construtor do domínio (linha {indice})"
                    )
                linha[nome] = self._valor(
                    tabela, coluna, spec_da_tabela.coluna(nome), fonte, linha, indice
                )
            self._marcas_de_tempo(modelo, linha, fonte, spec_da_tabela.momento)
            linhas.append(linha)
        return linhas

    def _valor(
        self,
        tabela: str,
        coluna: Any,
        spec: dict[str, Any],
        fonte: Fonte,
        linha: dict[str, Any],
        indice: int,
    ) -> Any:
        if "nulo" in spec and fonte.chance(float(spec["nulo"])):
            return None
        if "constante" in spec:
            return spec["constante"]
        if "sequencia" in spec:
            return spec["sequencia"].format(n=indice + 1)
        if "pesos" in spec or "valores" in spec:
            return self._enumerado(tabela, coluna, spec, fonte, indice)
        if "faixa" in spec:
            minimo, maximo = spec["faixa"]
            if isinstance(coluna.type, (Integer, BigInteger, SmallInteger)):
                return fonte.inteiro(int(minimo), int(maximo))
            return fonte.decimal(float(minimo), float(maximo), int(spec.get("casas", 2)))
        if "faker" in spec:
            return _limitar(getattr(fonte.faker, spec["faker"])(), coluna)
        if "provedor" in spec:
            return _limitar(self.provedores.gerar(spec["provedor"], fonte, linha, indice), coluna)
        # Coluna enumerada no modelo e não declarada no YAML não cai no padrão
        # de texto: ela vale o que o modelo aceita. Sem isso, `objective` de
        # campanha viraria uma palavra do Faker e a `CHECK` reprovaria a carga
        # inteira — que foi exatamente o que aconteceu na primeira execução.
        if enums.enumeracoes().get(tabela, {}).get(coluna.name):
            return self._enumerado(tabela, coluna, spec, fonte, indice)
        return self._por_tipo(tabela, coluna, fonte, linha, indice)

    def _enumerado(
        self, tabela: str, coluna: Any, spec: dict[str, Any], fonte: Fonte, indice: int
    ) -> Any:
        """Valor de uma lista declarada, com a cobertura garantida por construção.

        As primeiras linhas de uma coluna enumerada recebem, uma a uma, cada
        valor que o modelo aceita; só depois o sorteio entra. É o que faz "todo
        valor de enumeração presente" (ADR-0014) deixar de depender da sorte:
        com peso 1 em 10 e oito linhas, um valor some em 43% das sementes — e o
        teste de cobertura viraria loteria em vez de asserção.

        `ciclo` desliga o sorteio de vez: em tabela de domínio fechado, a
        n-ésima linha é o n-ésimo valor, e é isso que mantém nome, tipo e
        cidade alinhados entre colunas da mesma linha.
        """
        aceitos = enums.enumeracoes().get(tabela, {}).get(coluna.name)
        opcoes = spec.get("valores") or aceitos
        if spec.get("ciclo"):
            return opcoes[indice % len(opcoes)]
        if aceitos and indice < len(aceitos):
            return aceitos[indice]
        if "pesos" in spec:
            return fonte.ponderada(spec["pesos"])
        return fonte.escolha(opcoes)

    def _por_tipo(
        self, tabela: str, coluna: Any, fonte: Fonte, linha: dict[str, Any], indice: int
    ) -> Any:
        """Padrão pelo tipo declarado no modelo — o "Faker dinâmico" do ADR-0005.

        Coluna cujo padrão do banco já diz o que ela deve valer recebe o
        próprio padrão: reinventá-lo aqui criaria uma segunda opinião sobre a
        mesma coluna.
        """
        tipo = coluna.type
        if coluna.server_default is not None and not isinstance(tipo, DateTime):
            padrao = _do_server_default(coluna)
            if padrao is not None:
                return padrao
        if isinstance(tipo, Uuid):
            return fonte.uuid()
        if isinstance(tipo, Boolean):
            return fonte.chance(0.8)
        if isinstance(tipo, (Integer, BigInteger, SmallInteger)):
            return fonte.inteiro(1, 100)
        if isinstance(tipo, Numeric):
            casas = tipo.scale or 2
            return fonte.decimal(1, 1000, casas)
        if isinstance(tipo, DateTime):
            return self.relogio.uniforme(fonte)
        if isinstance(tipo, Date):
            return self.relogio.uniforme(fonte).date()
        if isinstance(tipo, Text):
            return fonte.faker.sentence(nb_words=10)
        if isinstance(tipo, String):
            return _limitar(fonte.faker.word(), coluna)
        return None

    def _marcas_de_tempo(
        self, modelo: Any, linha: dict[str, Any], fonte: Fonte, coluna_momento: str | None
    ) -> None:
        """`created_at`, `updated_at` e `deleted_at` a partir do tempo de negócio.

        `created_at` igual ao momento em que o fato aconteceu não é detalhe
        estético: é o que faz `updated_at` servir de cursor de carga incremental
        (ADR-0015) em vez de ser ruído. Qual coluna carrega esse momento é
        declaração — a chave `momento` do YAML —, porque só o domínio sabe se é
        `placed_at`, `ordered_at` ou `registered_at`.
        """
        colunas = modelo.columns
        momento = linha.pop(f"{AUXILIAR}momento", None)
        if momento is None and coluna_momento:
            momento = linha.get(coluna_momento)
        if "created_at" in colunas and linha.get("created_at") is None:
            linha["created_at"] = momento or self.relogio.uniforme(fonte)
        if "updated_at" in colunas and linha.get("updated_at") is None:
            linha["updated_at"] = self.relogio.depois(linha["created_at"], fonte, 0, 720)
        if "deleted_at" in colunas and "deleted_at" not in linha:
            linha["deleted_at"] = (
                self.relogio.depois(linha["created_at"], fonte, 1, 2000)
                if fonte.chance(self.config.exclusao_logica)
                else None
            )

    # ── Saída ────────────────────────────────────────────────────────────────
    @staticmethod
    def colunas_gravaveis(tabela: str) -> tuple[str, ...]:
        """Colunas que o `COPY` escreve — as demais são do banco."""
        modelo = enums.tabela(tabela)
        return tuple(c.name for c in modelo.columns if not _gerada_pelo_banco(c))


def _gerada_pelo_banco(coluna: Any) -> bool:
    """`GENERATED ALWAYS`: coluna calculada ou identidade não sobrescrevível.

    `quantity_available` é derivada pelo banco e `event_sequence` é identidade
    `always` — escrever nas duas é erro de sintaxe no `COPY`, não escolha.
    """
    if coluna.computed is not None:
        return True
    return coluna.identity is not None and bool(coluna.identity.always)


def _do_server_default(coluna: Any) -> Any:
    """Converte o `server_default` textual para valor Python, quando dá.

    Só serve para os padrões simples que os modelos usam — `true`, `0`, `'BR'`.
    Qualquer outra coisa devolve `None` e o valor sai do tipo.
    """
    texto = getattr(coluna.server_default, "arg", None)
    texto = str(getattr(texto, "text", texto)).strip().strip("'")
    if texto in {"true", "false"}:
        return texto == "true"
    if isinstance(coluna.type, (Integer, BigInteger, SmallInteger)):
        return int(texto) if texto.lstrip("-").isdigit() else None
    if isinstance(coluna.type, Numeric):
        try:
            return Decimal(texto)
        except Exception:
            return None
    if isinstance(coluna.type, (String, Text)) and texto and "(" not in texto:
        return texto
    return None


def _limitar(valor: Any, coluna: Any) -> Any:
    """Corta texto ao tamanho declarado no modelo.

    `varchar(80)` que recebe 120 caracteres é erro do banco no fim da carga.
    Cortar aqui é a diferença entre um dado feio e uma execução perdida.
    """
    limite = getattr(coluna.type, "length", None)
    if limite and isinstance(valor, str) and len(valor) > limite:
        return valor[:limite]
    return valor
