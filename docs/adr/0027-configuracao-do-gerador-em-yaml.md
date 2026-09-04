# ADR-0027 — Declarar o gerador em YAML, com o piso derivado dos modelos

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (decisão nova, levantada na Etapa 4) |
| Substitui / é substituída por | — |

## Contexto

O [ADR-0005](0005-geracao-com-faker-orientada-a-configuracao.md) fixou que o gerador é um motor
genérico lendo um arquivo declarativo, e deixou duas coisas em aberto que só a implementação
obrigava a fechar.

A primeira é o **formato**: "JSON ou YAML", nas palavras do próprio ADR. A escolha não é cosmética.
Esse arquivo é o que o [`CLAUDE.md`](../../CLAUDE.md) §5 manda o Owner revisar **integralmente** —
é o tratamento do risco **R14**, código gerado em volume que ninguém consegue revisar. Um arquivo
que não aceita comentário empurra a justificativa de cada número para fora dele, e a justificativa
apartada do número diverge na primeira edição.

A segunda é o **piso de cobertura** do [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md).
O ADR diz que o piso garante "todo valor de enumeração presente ao menos uma vez" em qualquer
escala, e não diz de onde o piso sai. Escrevê-lo à mão nas 40 tabelas significaria copiar para a
configuração o que as `CHECK` dos modelos já declaram — exatamente a segunda declaração que o
[ADR-0009](0009-sqlalchemy-para-acesso-a-dados.md) recusou ao decidir que a configuração é
*conferida* contra os modelos em vez de repeti-los.

Havia ainda um agravante medido durante a implementação: distribuição por peso **não** entrega
cobertura. Com peso 1 em 10 e oito linhas, um valor de enumeração desaparece em 43% das sementes.
Um teste de cobertura sobre isso seria loteria, não asserção.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **YAML, com piso derivado das enumerações e `min_rows` onde falta** | Comentário na linha do número, que é o que torna a revisão integral viável; um só formato de configuração no repositório, já que o dbt da Etapa 5 é YAML; o piso nasce correto e acompanha sozinho toda enumeração nova no modelo | Uma dependência a mais (`PyYAML`); o piso derivado cobre enumeração e não regra estrutural, o que exige o `min_rows` declarado como complemento |
| JSON | Está na biblioteca padrão, zero dependência nova | Não aceita comentário. O porquê de cada proporção passaria a morar fora do arquivo, criando a duplicação que o **P8** proíbe — e some no primeiro `git diff` |
| Módulo Python declarativo | Erro de tipo aparece no import; a configuração referencia os modelos diretamente | Apaga a fronteira entre declaração e código. O que a §5 manda revisar integralmente deixaria de ser "não-código", e o **R14** volta pela janela |
| Piso escrito à mão nas 40 tabelas | Nada implícito: 40 números revisáveis linha a linha | Repete o que os modelos já dizem. Na primeira enumeração nova alguém esquece de subir o piso, e a cobertura cai sem que nada reclame |
| Piso só derivado das enumerações | Zero manutenção | Cobre enumeração e nada mais. Profundidade de hierarquia e pares armazém/SKU suficientes para o estoque não teriam como ser expressos, e falhariam calados |

## Decisão

A configuração do gerador é um **arquivo YAML único**,
[`src/mvp_ed1/generator/geracao.yml`](../../src/mvp_ed1/generator/geracao.yml), com o motivo de
cada número escrito na própria linha.

O **piso de cobertura é derivado das `CHECK` de enumeração dos modelos**. Onde a cobertura exige
mais do que enumeração, a configuração declara `min_rows` **acompanhado de `motivo`** — piso sem
motivo é recusado no carregamento, antes de qualquer linha ser gerada.

Duas garantias de construção acompanham a decisão, porque sem elas o piso seria promessa:

1. as **primeiras linhas** de toda coluna enumerada recebem, uma a uma, cada valor que o modelo
   aceita; o sorteio por peso só começa depois disso;
2. valor que o domínio torna impossível é **dispensado por declaração**, com o motivo escrito —
   `order_status_history.from_status` nunca vale `cancelled` nem `returned`, porque não há
   transição saindo de estado terminal.

## Consequências

- **Positivas:** o arquivo que o Owner revisa integralmente carrega a justificativa junto do número,
  e não em documento paralelo; "todo valor de enumeração presente" passa a ser verdade por
  construção em vez de resultado de sorte, e sobrevive a troca de semente; uma enumeração nova no
  modelo levanta o piso da tabela sozinha; o repositório terá **uma** linguagem de configuração, a
  mesma do dbt na Etapa 5.
- **Negativas:** `PyYAML` entra como dependência para ler um único arquivo, e YAML tem armadilhas
  próprias — indentação significativa e valores que parecem texto e viram booleano. O piso derivado
  cobre só enumeração: toda regra estrutural continua sendo trabalho manual em `min_rows`, e
  esquecê-la não produz erro, produz cobertura menor. A dispensa de cobertura é uma porta para
  silenciar teste legítimo; ela é aceitável porque é declarada, tem motivo escrito e é revisada
  como qualquer outra linha da configuração.
- **Paridade com o GCP:** o mesmo arquivo, com o fator `cloud`, alimenta a carga no Cloud SQL na
  Etapa 13 — é literalmente o que o [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md)
  previu ao dizer que o fator é o único ponto que muda entre as fases. O YAML não depende de
  infraestrutura: é lido pelo mesmo processo Python nos dois ambientes.
- **Documentos a atualizar:** [Geração de Dados](../geracao_de_dados.md) §1 e §4;
  [Arquitetura](../arquitetura.md) §7; [Qualidade de Dados](../qualidade_de_dados.md) §2.
