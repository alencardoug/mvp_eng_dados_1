# ADR-0021 — Carregar a procedência em coluna própria no empilhamento

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D15 |

## Contexto

Na Etapa 10 a [origem legada](../origem_legada.md), depois de limpa, é empilhada ao fluxo principal
na camada `trusted`. As duas origens têm chaves naturais próprias e independentes: nada impede que o
cliente `1024` exista nas duas, significando pessoas diferentes. Sem uma chave de procedência, o
empilhamento colide silenciosamente — e colisão silenciosa em chave é o defeito mais caro possível,
porque contamina toda fato que referencia a dimensão.

A pergunta que a governança fará depois é outra e igualmente importante: **quantos registros vieram
do legado, e quais?** Uma solução que resolve a colisão mas apaga a origem responde à primeira
necessidade e não à segunda.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **`source_system` + chave natural** | Coluna explícita desde a camada `raw`, e chave substituta = hash de (`source_system`, chave natural). A colisão é impossível por construção e a procedência é legível em qualquer camada — dá para filtrar, auditar e reconciliar por origem. Encaixa no hash já escolhido no [ADR-0017](0017-chaves-substitutas-e-scd.md) | Uma coluna técnica em toda tabela empilhada |
| Faixa de chave por origem | Chaves curtas, colisão resolvida sem coluna extra | A procedência vira conhecimento implícito na faixa: ninguém descobre a origem sem consultar documentação, e a faixa estoura sem aviso. Prática legada, hoje desaconselhada |
| Hash composto, sem coluna | Evita colisão sem engordar a tabela | A procedência fica irrecuperável — hash não se desfaz. "Quantos clientes vieram do legado?" deixa de ter resposta |
| `source_system` + cadeia completa de linhagem por registro | Linhagem em nível de registro: rastreia qualquer linha do consumo até o registro bruto que a gerou; é o padrão de ambiente auditado | Quatro colunas técnicas em toda tabela empilhada e mais metadados a manter, sem que exista hoje a pergunta que as justifique |

## Decisão

Toda tabela que recebe mais de uma origem carrega **`source_system`** como coluna explícita, desde
`raw` e `raw_legacy` até `analytics`. A chave substituta é o **hash de (`source_system`, chave
natural)**, seguindo o mecanismo do [ADR-0017](0017-chaves-substitutas-e-scd.md).

`source_system` é de preenchimento obrigatório e valor restrito a um domínio declarado — não é campo
livre.

## Consequências

- **Positivas:** colisão entre origens deixa de ser possível por construção, não por vigilância; a
  reconciliação por origem passa a ser uma cláusula `WHERE`; e a pergunta "o que veio do legado?",
  que a governança fará, tem resposta direta em qualquer camada.
- **Negativas:** uma coluna técnica em toda tabela empilhada, inclusive nas que hoje têm origem
  única — porque descobrir depois que uma tabela passou a ter duas origens é tarde. E o hash inclui
  a origem, então o mesmo registro migrado entre sistemas mudaria de chave: caso que não existe
  neste projeto, e fica registrado para não ser descoberto como surpresa.
- **Paridade com o GCP:** coluna comum, sem tradução. O `source_system` também é o candidato natural
  a chave de particionamento ou agrupamento no BigQuery, se a fase GCP precisar.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md) §5 — o empilhamento;
  [Modelo de Dados](../modelo_de_dados.md) §6 — a coluna nas camadas;
  [Dicionário de Dados](../dicionario_de_dados.md) — `source_system` como campo padrão;
  [Governança de Dados](../governanca_de_dados.md) — classificação do campo.
