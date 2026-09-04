"""Provedores próprios do projeto.

O `Faker` responde por valor sintático — nome, rua, frase. O que ele não
representa é responsabilidade daqui (ADR-0005): coerência entre cidade, UF e
CEP, documentos que **não** podem ser válidos, e-mails em domínio reservado,
nomes de produto que combinam com a categoria.

A regra que rege este módulo é a §7 de Geração de Dados: dado sintético não
pode coincidir com pessoa real. Por isso nenhum documento aqui passa em
validação de dígito verificador — é intencional, e é o motivo de não usarmos
`faker.cpf()`, que gera CPF aritmeticamente válido.
"""

from __future__ import annotations

import datetime as dt
import unicodedata
from typing import Any, Callable

from mvp_ed1.generator.rng import Fonte

#: Cidade, UF e prefixo de CEP coerentes entre si. Geografia é fato público;
#: o que é sintético é o endereço construído sobre ela.
LOCALIDADES: tuple[tuple[str, str, str], ...] = (
    ("São Paulo", "SP", "013"), ("Campinas", "SP", "130"), ("Santos", "SP", "110"),
    ("Rio de Janeiro", "RJ", "200"), ("Niterói", "RJ", "240"),
    ("Belo Horizonte", "MG", "301"), ("Uberlândia", "MG", "384"),
    ("Curitiba", "PR", "800"), ("Londrina", "PR", "860"),
    ("Porto Alegre", "RS", "900"), ("Caxias do Sul", "RS", "950"),
    ("Florianópolis", "SC", "880"), ("Joinville", "SC", "892"),
    ("Salvador", "BA", "400"), ("Feira de Santana", "BA", "444"),
    ("Recife", "PE", "500"), ("Fortaleza", "CE", "600"),
    ("Brasília", "DF", "700"), ("Goiânia", "GO", "740"),
    ("Belém", "PA", "660"), ("Manaus", "AM", "690"), ("Vitória", "ES", "290"),
)

_CATEGORIAS_RAIZ = ("Eletrônicos", "Casa e Cozinha", "Moda", "Esporte e Lazer")
_CATEGORIAS_MEIO = (
    "Áudio", "Informática", "Utilidades", "Mobiliário", "Vestuário",
    "Calçados", "Treino", "Camping",
)
_CATEGORIAS_FOLHA = (
    "Fones de ouvido", "Caixas de som", "Notebooks", "Periféricos", "Panelas",
    "Organizadores", "Sofás", "Estantes", "Camisetas", "Calças", "Tênis",
    "Sandálias",
)
_LINHAS_DE_PRODUTO = (
    "Compacto", "Profissional", "Essencial", "Premium", "Clássico", "Urbano",
    "Studio", "Traveler", "Max", "Nano", "Prime", "Origem",
)
_MATERIAIS = (
    "Alumínio", "Bambu", "Algodão", "Inox", "Couro sintético", "Cerâmica",
    "Vidro", "Nylon", "Carvalho", "Titânio",
)
_MARCAS = (
    "Aurora", "Boreal", "Cardume", "Dilúvio", "Estrela", "Farol", "Granito",
    "Horizonte", "Ipê", "Jacarandá", "Lume", "Maré", "Norte", "Orvalho",
    "Pampa", "Quartzo", "Recife", "Serra", "Tapajós", "Uirapuru", "Vento",
    "Xisto", "Zênite", "Âmbar", "Ébano", "Ônix", "Cristal", "Duna",
)
_TRANSPORTADORAS = (
    "Rota Sul", "Expresso Litoral", "TransPampa", "Via Central", "Malha Norte",
    "Entrega Já", "LogPrime", "Caminho Certo",
)
_TEMAS_DE_CAMPANHA = (
    "Semana do Consumidor", "Liquida Inverno", "Volta às Aulas", "Black Week",
    "Natal Antecipado", "Mês do Cliente", "Esquenta Verão", "Aniversário da Loja",
    "Frete Zero", "Reativa Cliente", "Queima de Estoque", "Dia das Mães",
)
_ASSUNTOS = (
    "Pedido não chegou no prazo", "Produto veio com defeito",
    "Quero trocar o tamanho", "Cobrança em duplicidade",
    "Cancelamento do pedido", "Dúvida sobre a nota fiscal",
    "Rastreio parado há dias", "Reembolso não caiu",
    "Endereço de entrega errado", "Cupom não foi aplicado",
)
_MENSAGENS = (
    "Registrado o contato do cliente pelo canal de atendimento.",
    "Cliente informou que o prazo prometido já passou.",
    "Encaminhado para a equipe responsável pela análise.",
    "Solicitada a coleta reversa junto à transportadora.",
    "Reembolso aberto no sistema financeiro.",
    "Cliente confirmou o recebimento e concordou com a solução.",
    "Sem resposta do cliente até o momento.",
    "Chamado reaberto a pedido do cliente.",
)
_MOTIVOS_DE_REEMBOLSO = (
    "Produto com defeito", "Arrependimento em até 7 dias", "Entrega não realizada",
    "Divergência de item", "Cancelamento a pedido do cliente",
)
_COMPLEMENTOS = ("Apto 12", "Bloco B", "Casa 2", "Fundos", "Sala 304", "Cobertura", "Loja 3")


class Provedores:
    """Registro dos provedores próprios, endereçados pelo nome no YAML."""

    def __init__(self, inicio: dt.datetime, fim: dt.datetime) -> None:
        self.inicio = inicio
        self.fim = fim
        self._registro: dict[str, Callable[..., Any]] = {
            nome[2:]: getattr(self, nome)
            for nome in dir(self)
            if nome.startswith("p_") and callable(getattr(self, nome))
        }

    def existe(self, nome: str) -> bool:
        return nome in self._registro

    def gerar(self, nome: str, fonte: Fonte, linha: dict[str, Any], indice: int) -> Any:
        try:
            provedor = self._registro[nome]
        except KeyError as erro:
            disponiveis = ", ".join(sorted(self._registro))
            raise KeyError(f"provedor {nome!r} não existe. Há: {disponiveis}") from erro
        return provedor(fonte, linha, indice)

    # ── Geografia coerente ───────────────────────────────────────────────────
    def _localidade(self, fonte: Fonte, linha: dict[str, Any]) -> tuple[str, str, str]:
        """Escolhe uma vez por linha e memoriza.

        A coerência entre cidade, UF e CEP não pode depender da ordem em que as
        três colunas são preenchidas — quem chegar primeiro decide, e as outras
        duas leem a mesma escolha.
        """
        escolha = linha.get("__localidade")
        if escolha is None:
            escolha = fonte.escolha(LOCALIDADES)
            linha["__localidade"] = escolha
        return escolha

    def p_cidade(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return self._localidade(fonte, linha)[0]

    def p_uf(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return self._localidade(fonte, linha)[1]

    def p_cep(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        prefixo = self._localidade(fonte, linha)[2]
        return f"{prefixo}{fonte.inteiro(0, 99):02d}-{fonte.inteiro(0, 999):03d}"

    def p_complemento(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.escolha(_COMPLEMENTOS)

    # ── Identificadores que não podem ser válidos ────────────────────────────
    def p_documento_pessoa(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        """Formato de CPF, dígito verificador propositalmente ausente.

        `SIN` no lugar do dígito deixa explícito que não é documento — nenhum
        CPF real tem letra, então a colisão com pessoa real é impossível (§7).
        """
        return f"{fonte.inteiro(0, 999):03d}.{fonte.inteiro(0, 999):03d}.{indice:03d}-SIN"

    def p_documento_empresa(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return f"{fonte.inteiro(0, 99):02d}.{fonte.inteiro(0, 999):03d}.{indice:03d}/0001-SIN"

    def p_telefone(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return f"+55 ({fonte.inteiro(11, 99)}) 9{fonte.inteiro(0, 9999):04d}-{fonte.inteiro(0, 9999):04d}"

    def p_email(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        """Domínio reservado, sempre. Nenhum e-mail gerado aqui pode existir."""
        usuario = fonte.faker.user_name()
        return f"{usuario}.{indice}@example.com"

    def p_email_corporativo(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        nome = str(linha.get("first_name", "agente")).lower()
        sobrenome = str(linha.get("last_name", "suporte")).lower()
        limpo = _sem_acento(f"{nome}.{sobrenome}")
        return f"{limpo}.{indice}@example.com"

    def p_contato(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        """E-mail ou telefone conforme o tipo já sorteado para a linha."""
        if linha.get("contact_type") == "email":
            return self.p_email(fonte, linha, indice)
        return self.p_telefone(fonte, linha, indice)

    # ── Nomes comerciais ─────────────────────────────────────────────────────
    def p_nome_de_marca(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return f"{_MARCAS[indice % len(_MARCAS)]} {fonte.escolha(('', 'Co.', 'Brasil', 'Design', 'Lab'))}".strip()

    def p_nome_de_produto(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return (
            f"{fonte.escolha(_CATEGORIAS_FOLHA)} {fonte.escolha(_LINHAS_DE_PRODUTO)} "
            f"{fonte.escolha(_MATERIAIS)}"
        )

    def p_razao_social(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return f"{fonte.escolha(_MARCAS)} {fonte.escolha(('Indústria', 'Comércio', 'Distribuidora'))} Ltda"

    def p_nome_fantasia(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.escolha(_MARCAS)

    def p_nome_de_transportadora(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return _TRANSPORTADORAS[indice % len(_TRANSPORTADORAS)]

    def p_nome_de_campanha(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return f"{_TEMAS_DE_CAMPANHA[indice % len(_TEMAS_DE_CAMPANHA)]} {self.inicio.year + indice // len(_TEMAS_DE_CAMPANHA)}"

    def p_codigo_de_cupom(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        tema = _sem_acento(_TEMAS_DE_CAMPANHA[indice % len(_TEMAS_DE_CAMPANHA)]).upper()
        return f"{tema.split()[0][:8]}{indice:04d}"

    # ── Texto ────────────────────────────────────────────────────────────────
    def p_frase_curta(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.faker.sentence(nb_words=8)

    def p_assunto_de_chamado(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.escolha(_ASSUNTOS)

    def p_mensagem_de_chamado(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.escolha(_MENSAGENS)

    def p_motivo_de_reembolso(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> str:
        return fonte.escolha(_MOTIVOS_DE_REEMBOLSO)

    # ── Datas ────────────────────────────────────────────────────────────────
    def p_momento_no_periodo(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> dt.datetime:
        segundos = int((self.fim - self.inicio).total_seconds())
        return self.inicio + dt.timedelta(seconds=fonte.inteiro(0, segundos))

    def p_data_de_nascimento(self, fonte: Fonte, linha: dict[str, Any], indice: int) -> dt.date:
        idade = fonte.inteiro(18, 80)
        return (self.fim - dt.timedelta(days=idade * 365 + fonte.inteiro(0, 364))).date()


def _sem_acento(texto: str) -> str:
    normalizado = unicodedata.normalize("NFKD", texto)
    return "".join(c for c in normalizado if not unicodedata.combining(c) and (c.isalnum() or c in "._-"))


#: Hierarquia de categorias usada pelo construtor do catálogo.
ARVORE_DE_CATEGORIAS = (_CATEGORIAS_RAIZ, _CATEGORIAS_MEIO, _CATEGORIAS_FOLHA)
