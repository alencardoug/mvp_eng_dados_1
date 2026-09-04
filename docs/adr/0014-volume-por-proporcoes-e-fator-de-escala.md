# ADR-0014 — Parametrizar o volume por proporções e fator de escala

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D26 |

## Contexto

O orçamento de **4 GB** veio da proposta original do projeto e atravessou o Termo de Abertura, o
documento de Capacidade, as contagens por tabela do Modelo de Dados e o critério do milhão de linhas
na Etapa 12. Nunca foi medido — era uma indicação genérica para o tamanho do banco PostgreSQL.

Em 04/09/2026 o Owner reformulou a premissa: **o trabalho com alto volume passa a pertencer à fase
GCP**. O ambiente local deixa de ser dimensionado por tamanho e passa a ser dimensionado por
**cobertura** — restrição já registrada no [Termo](../../Abertura_de_projeto.md) §8, v1.2. A
prioridade declarada é robustez processual: o mesmo código deve funcionar com pouco e com muito
volume, sem que o volume local seja a pressão que o valida.

Isso invalida os três perfis existentes — `smoke`, `demo` e `demo_4gb` —, que eram escalas de
tamanho e nada mais.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Proporções únicas + fator de escala** | Uma configuração declarativa fixa as proporções entre as 40 tabelas e um fator multiplica tudo, então a coerência entre tabelas é mantida por construção; um piso por tabela garante cobertura em qualquer escala; mudar de fase é mudar um número | Piso e fator interagem: em fator baixo o piso domina, e a proporção efetiva deixa de ser a declarada. Precisa ser dito, não descoberto |
| Perfis nomeados independentes | Leitura direta — vê-se exatamente quantas linhas cada tabela terá | 40 números por perfil para manter em sincronia; as proporções entre tabelas, que é o que dá realismo, divergem na primeira edição desatenta |
| Escala contínua, sem perfis nomeados | Flexibilidade máxima na linha de comando | "Rodei com qual volume?" perde resposta reproduzível, e reproduzir uma execução passa a depender de lembrar o número — tensão direta com a geração determinística do [ADR-0005](0005-geracao-com-faker-orientada-a-configuracao.md) |
| Manter `demo_4gb` como teto documentado | Preserva a referência de tamanho para a fase de nuvem | Mantém no repositório um número nunca medido com aparência de compromisso, o que o princípio **P5** proíbe |

## Decisão

Um **único conjunto de proporções** entre as 40 tabelas, com **fator de escala** e **piso por
tabela**. Dois valores nomeados do mesmo arquivo:

| Nome | Fator | Onde |
|---|---|---|
| `dev` | 1 | Padrão em **todas** as etapas locais |
| `cloud` | a definir na Etapa 13, por medição | Fase GCP |

O **piso** é o que garante a cobertura, e vale independentemente do fator. Em qualquer escala, a
geração precisa produzir:

- toda tabela populada — nenhuma das 40 vazia;
- todo valor de enumeração presente ao menos uma vez;
- todo tipo de falha do [catálogo do legado](../origem_legada.md) representado;
- toda invariante de negócio do [Modelo de Dados](../modelo_de_dados.md) §4 exercida ao menos uma
  vez, incluindo os casos que devem falhar.

`smoke`, `demo` e `demo_4gb` são aposentados.

## Consequências

- **Positivas:** a definição de pronto passa a ser verificável por teste — cobertura é uma
  asserção, tamanho era uma medição; ciclos de desenvolvimento curtos em todas as etapas; a
  passagem para volume alto vira mudança de um parâmetro, não de configuração.
- **Negativas:** o projeto deixa de exercitar, na fase local, os problemas que só aparecem em
  volume — plano de execução ruim, índice ausente, materialização incremental que se torna
  obrigatória. Esses problemas passam a ser descobertos na fase GCP. O
  [ADR-0016](0016-materializacao-por-camada.md) registra explicitamente que a escolha de
  materialização foi tomada **sem** essa pressão, para que a decisão possa ser revista lá com
  conhecimento de causa. É custo aceito e declarado, não esquecido.
- **Paridade com o GCP:** o mesmo arquivo de proporções, com o fator `cloud`, alimenta a carga no
  Cloud SQL. O fator é o único ponto que muda entre as fases.
- **Documentos a atualizar:** [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — documento
  inteiro; [Geração de Dados](../geracao_de_dados.md) — perfis e parâmetros;
  [Modelo de Dados](../modelo_de_dados.md) §3 — as contagens deixam de ser compromisso e passam a
  ser exemplo em fator 1; [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — Etapas 4 e
  12; [`CLAUDE.md`](../../CLAUDE.md) §7 e [Termo](../../Abertura_de_projeto.md) §8, já feitos.
