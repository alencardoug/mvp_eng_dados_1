# ADR-0023 — Restringir o schema `governance` a controle e auditoria

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D14 |

## Contexto

O [ADR-0008](0008-schemas-do-armazem.md) fixou sete schemas e deixou `governance` **fora**, com o
escopo condicionado a esta decisão — inclusive a possibilidade de não existir. Declarar um schema de
conteúdo indefinido era o que o risco **R14** e o princípio **P6** pediam para evitar.

A restrição real é não duplicar: o [ADR-0007](0007-catalogo-como-codigo.md) já fez do dbt o dono do
catálogo e da linhagem. Um schema `governance` que materializasse catálogo criaria duas verdades
sobre o mesmo assunto, que o princípio **P8** trata como defeito.

Mas há um conjunto de informações que o dbt **não** guarda: quando cada carga rodou e com que
resultado, se a reconciliação entre camadas fechou, o que está em quarentena e por quê, e qual
classificação foi de fato aplicada a cada campo. Hoje isso vive em artefato JSON de *build* — sem
série histórica, sem consulta SQL, sem alerta sobre tendência.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Controle, auditoria e reconciliação** | Guarda exatamente o que o dbt não guarda, e nada do que ele guarda. Histórico consultável por SQL é o mínimo que um ambiente auditado exige, e é o que permite responder "quando esta tabela foi carregada e por qual execução?" | Quatro conjuntos de tabelas a criar, popular e manter, com escrita a partir do Airflow e do dbt |
| Só resultado de reconciliação | Atende ao critério técnico do Termo com uma peça só | Log de execução e classificação aplicada ficam sem dono consultável, e a resposta volta a depender de vasculhar log do Airflow |
| Nenhum schema, tudo no dbt | Menor superfície; nenhuma chance de divergir do dbt | Resultados de teste continuam em arquivo de *build*: sem série histórica, sem consulta, sem alerta. Distante do que uma empresa faz (**P10**) |
| `governance` completo, incluindo catálogo | Tudo consultável por SQL num lugar só, como uma ferramenta de governança corporativa entregaria | Contradiz o ADR-0007 e cria a duplicação que o `CLAUDE.md` trata como defeito. Exigiria substituir o ADR-0007, não apenas complementá-lo |

## Decisão

O schema **`governance` é declarado**, e o seu escopo é fechado em quatro conjuntos:

| Conjunto | O que registra |
|---|---|
| Log de execução | Cada execução de pipeline: início, fim, resultado, versão do código |
| Reconciliação | Contagens por camada e o veredito de cada conferência, com série histórica |
| Índice de quarentena | O que foi rejeitado, de qual origem, por qual motivo do catálogo do [ADR-0022](0022-catalogo-declarativo-de-falhas-do-legado.md) |
| Classificação aplicada | Qual nível do [ADR-0011](0011-classificacao-e-papeis-de-acesso.md) cada campo recebeu, e quando |

**Catálogo e linhagem permanecem no dbt.** Nada do que o `dbt docs` produz é materializado aqui.
A fronteira: o dbt descreve **como o armazém é**; `governance` registra **o que aconteceu com ele**.

## Consequências

- **Positivas:** a reconciliação entre camadas — critério de sucesso técnico do Termo — passa a ter
  série histórica em vez de um veredito volátil; a classificação aplicada fica auditável por
  consulta, e não por leitura de YAML; a quarentena ganha índice consultável, o que dá operacional
  concreto à regra 4 do `CLAUDE.md`.
- **Negativas:** quatro conjuntos de tabelas a criar e popular, com escrita a partir do Airflow e do
  dbt; e o schema precisa ser mantido **fora** do fluxo de dados — nenhum modelo de `analytics` pode
  ler dele, sob pena de a auditoria virar entrada do que ela audita.
- **Paridade com o GCP:** um *dataset* `governance` com as mesmas tabelas. A classificação aplicada
  é a tabela que alimenta as *policy tags* do [ADR-0025](0025-policy-tags-por-fluxo-automatizado.md).
- **Documentos a atualizar:** [ADR-0008](0008-schemas-do-armazem.md) permanece intacto — esta
  decisão o complementa, como ele previu; [Arquitetura](../arquitetura.md) §2 — o oitavo schema;
  [Governança de Dados](../governanca_de_dados.md) — os quatro conjuntos;
  [Modelo de Dados](../modelo_de_dados.md) §6.
