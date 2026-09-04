"""Construtores de domínio.

Cada módulo aqui sabe uma coisa que o motor não sabe: como um pedido nasce de
um carrinho, por que uma captura nunca excede a autorização, o que faz um saldo
de estoque não ficar negativo. São as invariantes do Modelo de Dados §4 escritas
como regra de geração — as mesmas que a Etapa 5 vai reescrever como teste.

Um construtor recebe o motor e o `Dataset` já preenchido pelos anteriores, e
devolve linhas guardadas no `Dataset`. A ordem das chamadas é do `pipeline`.
"""
