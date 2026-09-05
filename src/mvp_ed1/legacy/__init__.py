"""Origem legada — geração, injeção de falhas e manifesto (Etapa 10).

O pacote produz a **segunda origem** do projeto: um banco antigo sem
governança, logicamente idêntico ao transacional e deliberadamente sujo. O
contrato de negócio está em `docs/origem_legada.md`; aqui está a implementação.

Três peças, e a ordem entre elas importa:

    catalogo   carrega e valida o catálogo declarativo (ADR-0022)
    schema     deriva a estrutura frouxa dos modelos SQLAlchemy
    injetor    degrada os valores e injeta os defeitos, produzindo o manifesto

O **manifesto** é o oráculo dos testes e nunca é lido pela transformação. Se
fosse, o teste passaria a medir a si mesmo (Origem Legada §3.2).
"""

from mvp_ed1.legacy.catalogo import Catalogo, carregar

__all__ = ["Catalogo", "carregar"]
