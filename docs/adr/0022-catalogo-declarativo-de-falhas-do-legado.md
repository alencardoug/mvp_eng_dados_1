# ADR-0022 — Declarar as falhas do legado em catálogo único

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D28 |

## Contexto

A [origem legada](../origem_legada.md) é deliberadamente defeituosa, e o projeto precisa de duas
coisas simétricas: um **injetor**, que produz os defeitos na geração, e um **tratamento**, que os
converte quando a equivalência é inequívoca ou os rejeita com motivo quando não é. Se as duas
listas divergirem, o projeto injeta defeito que ninguém trata — ou trata defeito que nunca ocorre,
e o teste passa sem provar nada.

O catálogo atual tem sete linhas e um parágrafo dizendo que "outras falhas cobrem" mais casos. Esse
parágrafo é a divergência começando: o que não está declarado não é injetado, não é tratado e não é
testado.

O Owner declarou que a variedade de defeitos é prioridade — mais importante que volume — porque é
onde está o tratamento robusto por código.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Catálogo declarativo único, ampliado** | Um YAML é a fonte da verdade: cada tipo de falha declara padrão de detecção, conversão determinística quando existe e código de motivo de rejeição quando não existe. Dele saem o injetor, as regras de limpeza e os testes que usam o manifesto como oráculo — a simetria fica garantida por construção. Ampliar de 7 para cerca de 20 tipos é o que torna o tratamento interessante | Mais regras e testes para revisar; e um YAML expressivo o bastante para descrever detecção e conversão tem gramática própria a manter |
| Catálogo declarativo, mantido em 7 tipos | Menor superfície | Sete tipos exercitam o mecanismo, não o problema. O tratamento robusto que é a prioridade declarada não aparece |
| Regras em Python por tabela | Máxima expressividade: casos irregulares que YAML nenhum descreve ficam fáceis | A simetria injetar ↔ tratar passa a depender de disciplina humana, e a revisão vira leitura de dezenas de módulos — o padrão que o `CLAUDE.md` §5 manda evitar (risco **R14**) |
| Rejeitar tudo, sem converter | Regra única, impossível de aplicar errado; nenhuma conversão silenciosa corrompe dado | Elimina o problema mais instrutivo do legado: decidir quando a equivalência é inequívoca (`oito` → 8) e quando não é (`oito caixas`) |

## Decisão

Um **catálogo declarativo único**, versionado, é a fonte da verdade das falhas do legado. Cada
entrada declara:

| Campo | Conteúdo |
|---|---|
| Identificador | Código estável do tipo de falha, usado como motivo de rejeição |
| Campo lógico | A que tipo de campo se aplica |
| Detecção | Como o valor defeituoso é reconhecido |
| Conversão | A regra determinística, quando a equivalência é inequívoca |
| Rejeição | O motivo codificado, quando não há regra válida |
| Injeção | Como o gerador produz o defeito, e com que frequência |

Dele são gerados o injetor de falhas, as regras de limpeza e os testes — nenhum dos três é escrito à
mão de forma independente.

O catálogo é **ampliado dos 7 tipos atuais para cerca de 20**, incluindo, além dos existentes:
codificação textual quebrada, duplicata parcial, referência órfã, total que não reconcilia, data
futura indevida, campo truncado, delimitador dentro do campo e nulo disfarçado de texto (`NULL`,
`N/A`, `-`, string vazia). A lista definitiva vive na [Origem Legada](../origem_legada.md), que é o
dono documental do assunto.

O **manifesto** continua sendo o oráculo dos testes e continua não sendo consultado pela
transformação — se fosse, o teste mediria a si mesmo.

## Consequências

- **Positivas:** injetar e tratar deixam de poder divergir; o que se revisa é uma declaração, não
  dezenas de módulos equivalentes; e a cobertura de tipos de falha vira asserção verificável, que é
  o piso de cobertura exigido pelo [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md).
- **Negativas:** cerca de 20 tipos significam mais regras de limpeza, mais motivos de quarentena e
  mais testes; e o formato declarativo precisa ser expressivo sem virar linguagem de programação
  disfarçada — se um caso exigir lógica que o YAML não descreve, a resposta é um tipo de falha
  melhor definido, não um campo de código embutido.
- **Paridade com o GCP:** o catálogo é dado, não código de plataforma: o mesmo arquivo alimenta o
  tratamento no BigQuery. Os motivos de rejeição viram valores da tabela de quarentena, igual em
  ambas as fases.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md) §3 — o catálogo ampliado;
  [Qualidade de Dados](../qualidade_de_dados.md) — os testes derivados;
  [Governança de Dados](../governanca_de_dados.md) — motivos de quarentena;
  [Geração de Dados](../geracao_de_dados.md) — o injetor.
