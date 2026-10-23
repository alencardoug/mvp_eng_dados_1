# ADR-0049 — Separar a classificação da exposição do dado sintético

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 23/10/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — ; decidida em 22/10/2026 como O2 e N8 do [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/69d74ef/PLAN.md#12-the-decisions), que abre a versão de manutenção `v1.1.0` |
| Substitui / é substituída por | — ; complementa o [ADR-0011](0011-classificacao-e-papeis-de-acesso.md), cujos níveis e papéis não mudam |

## Contexto

A [Governança §4](../governanca_de_dados.md#4-classificação-de-sensibilidade) dava a cada nível de
`sensitivity` uma **regra de exposição**: `confidential` "fora das views de consumo abertas ao perfil
de análise"; `personal` "nunca exibido em exemplos; mascarado nas views de consumo quando não for
necessário". As duas nunca foram aplicadas. O `analyst` lê o schema `consumption` inteiro — a
concessão é da camada (`+grants` no `dbt_project.yml`, Governança §7) —, e **28 colunas
`confidential` em 10 das 16 views** chegam a ele: a receita de P01, a margem de P08, o custo do
estoque de P11. Nenhuma view tem coluna `personal`, e nada mascara coisa alguma. A política dizia uma
coisa e a declaração fazia outra; a divergência foi apontada na revisão do plano do `bi-como-codigo`
(RP-02, 22/10/2026), não por teste daqui.

Ela ficou visível porque o projeto vai publicar as 16 views fora do armazém, num site público. Em
22/10/2026 o Owner decidiu que **nenhum campo sintético é restrito nas análises** — todos podem, e
devem, aparecer (O2) — e fixou o alcance: **classificar não é expor** (N8). A classificação continua;
a exposição de dado sintético fica livre.

A razão da restrição era proteger valor comercial e pessoa real. No projeto não há nenhum dos dois:
a [regra inviolável 2](../../CLAUDE.md#6-regras-invioláveis) e a
[Governança §3](../governanca_de_dados.md#3-dados-não-permitidos) proíbem dado real de qualquer
origem. O que a classificação ainda faz — e continua a fazer — é declarar **o que o campo seria**:
é ela que vira *policy tag* na Etapa 13 ([ADR-0025](0025-policy-tags-por-fluxo-automatizado.md)).

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **A — Separar classificar de expor** | A classificação continua verdadeira e completa; a política passa a descrever o que o armazém faz; quem vê o quê vira decisão de concessão, explícita e testável | O controle de exposição deixa de ser exercitado na fase local — fica para as *policy tags* da Etapa 13 |
| B — Reclassificar como `public` o que for publicado | Nenhuma regra muda | A classificação passaria a mentir: margem tem valor comercial seja o dado real ou não. A *policy tag* da Etapa 13 nasceria errada, e a classificação derivada por linhagem herdaria o erro. A revisão do plano (§4.4) já advertia: não trocar metadado gerado para `public` só para viabilizar o site |
| C — Cumprir a regra antiga: tirar as colunas `confidential` das views do `analyst` | A política volta a valer como está escrita | As 16 perguntas são de receita, margem e custo: P01 sem receita líquida não responde nada. Contraria a O2, e protege um dado que não existe |
| D — Exceção só para o site, mantendo a regra no armazém | O armazém não muda | Duas regras para o mesmo dado; a divergência de hoje — o `analyst` lendo 28 colunas `confidential` — continuaria sem resposta |

## Decisão

A classificação de sensibilidade continua obrigatória e inalterada em todo campo de toda camada, e
deixa de decidir a exposição: dado sintético de qualquer nível pode ser exposto, nas views de
consumo e fora do armazém, e quem acessa o quê é decidido por concessão — nunca por reclassificação.

O que **não** muda:

- os quatro níveis, a catraca de `tests/test_classificacao.py` e a classificação derivada por
  linhagem (Governança §§4 e 5.1);
- o acesso por camada (Governança §7): o `analyst` continua a ler só `consumption`. Exposição livre
  é sobre o **dado**, não sobre as camadas — publicar o modelo dimensional, por exemplo, continua a
  exigir um contrato de consumo, com ADR;
- a proibição de dado real (Governança §3). A liberdade de exposição é **consequência** dela: se um
  dia o código servisse a dado real, esta decisão não valeria, e a regra de exposição precisaria
  voltar.

## Consequências

- **Positivas:** a política e a declaração deixam de divergir — as 28 colunas lidas pelo `analyst`
  passam a estar dentro da regra. A publicação das 16 views no `bi-como-codigo` não viola a
  governança que ela mesma apresenta. A classificação mantém todo o seu valor: descreve o campo, e
  é dela que a Etapa 13 tira as *policy tags*. E a exposição passa a ter um único lugar de decisão,
  a concessão, que já é declarada e testada (`tests/test_acesso.py`).
- **Negativas:** a fase local deixa de exercitar o mascaramento de `personal` e a exclusão de
  `confidential` que a §4 prometia — o controle sobre a exposição passa a ser exercitado só nas
  *policy tags* da Etapa 13. Quem lê `confidential` ao lado de "livre" precisa de explicação, e ela
  vive na Governança §4. E a decisão fica presa ao dado sintético: reutilizar o código com dado real
  exige reabri-la.
- **Paridade com o GCP:** a mesma separação, com as peças nativas. A classificação vira *policy tag*
  pelo fluxo automatizado do [ADR-0025](0025-policy-tags-por-fluxo-automatizado.md), com o controle
  de acesso da taxonomia **ligado**; a exposição é a concessão do papel de leitor refinado
  (*Fine-Grained Reader*) pelo IAM a cada grupo que consome. O grupo do `analyst` a recebe nas
  *tags* do dado sintético, e o critério da Etapa 13 — acesso negado comprovado — se prova com uma
  identidade sem a concessão. Classificar é a *tag*; expor é o IAM.
- **Documentos a atualizar:** [Governança de Dados](../governanca_de_dados.md) §4 (a coluna *Regra*
  e o parágrafo sobre `personal`) e §5.2 (quem recebe a concessão); este Registro;
  [README](../../README.md) (contador e *Decisões já tomadas*).
