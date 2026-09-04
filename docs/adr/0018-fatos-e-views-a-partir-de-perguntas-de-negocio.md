# ADR-0018 — Derivar fatos e views de consumo das perguntas de negócio

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D24, D27 |

## Contexto

O [Modelo de Dados](../modelo_de_dados.md) §3.1 declara as nove tabelas fato e o **grão** de cada
uma, mas não os atributos nem as medidas. E o schema `consumption` ([ADR-0008](0008-schemas-do-armazem.md))
existe sem que se saiba o que ele expõe.

As duas decisões são uma só: uma medida existe porque alguém pergunta algo que exige somá-la, e uma
view de consumo é a forma dessa pergunta. Decidir separadamente produz o defeito clássico — um
datamart que responde tudo em tese e nada em particular.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Perguntas de negócio primeiro** | É o método Kimball: 12 a 15 perguntas concretas escritas antes de qualquer SQL, e cada fato declara em YAML seu grão, suas medidas classificadas como aditiva / semiaditiva / não aditiva, e as dimensões conformadas que a atendem; **D24** e **D27** caem juntas | Exige escrever as perguntas antes, o que atrasa o primeiro modelo |
| Derivar do modelo transacional | Mecânico, rápido e completo: toda coluna numérica vira medida, toda chave estrangeira vira dimensão | Produz fatos infladas de colunas que ninguém consulta e, pior, sem distinção entre aditivo e semiaditivo — a distinção que impede somar saldo de estoque ao longo do tempo |
| Padrão de referência do varejo | Desenho testado por décadas, com forte valor demonstrativo | O domínio tem *marketplace*, cupom, atendimento e *streaming* de estoque, que o padrão clássico não cobre; adaptar sem perguntas é palpite |

| Contrato das views | A favor | Contra |
|---|---|---|
| **Contrato dbt aplicado** (`contract: enforced`) | Colunas, tipos, obrigatoriedade e grão declarados em YAML e **verificados pela máquina**: o *build* quebra se um modelo mudar de forma. Mais versionamento, para que mudança quebrante nasça como `v2` em vez de quebrar quem consome | Rigidez durante o desenvolvimento, quando a forma ainda muda; cada alteração exige atualizar a declaração |
| Contrato documentado, não aplicado | Menos atrito enquanto a forma se estabiliza | Contrato que nada verifica é documentação: diverge do modelo real na primeira alteração e ninguém fica sabendo |
| Uma view por fato | Cobertura simétrica, fácil de gerar | View de consumo deve responder pergunta de negócio, não espelhar tabela física; do jeito mecânico o consumidor ainda precisa conhecer o modelo dimensional inteiro |
| Views recortadas por papel de acesso | Amarra consumo e governança numa peça só | Multiplica as views pelos cinco papéis e mistura semântica de negócio com controle de acesso no mesmo objeto — o [ADR-0011](0011-classificacao-e-papeis-de-acesso.md) já resolve acesso por concessão |

## Decisão

**As perguntas de negócio vêm primeiro.** Antes do primeiro modelo de `analytics`, 12 a 15
perguntas concretas são escritas no [Glossário de Negócio](../glossario_de_negocio/) — o dono
documental do vocabulário que elas usam.

Cada fato então declara, em YAML revisável:

- o **grão**, em uma frase, e o teste de unicidade que o comprova;
- as **medidas**, cada uma classificada como **aditiva**, **semiaditiva** (somável em todas as
  dimensões menos tempo — o caso do saldo de estoque) ou **não aditiva** (razões e percentuais, que
  se recalculam, nunca se somam);
- as **dimensões conformadas** que a atendem.

**Cada pergunta vira uma view de consumo**, nomeada pela pergunta que responde, com
**`contract: enforced`**: colunas, tipos, obrigatoriedade e grão verificados no *build*. Mudança
quebrante nasce como nova versão da view; a anterior permanece até que se declare o contrário.

## Consequências

- **Positivas:** nenhuma medida existe sem consumidor declarado; a classificação de aditividade
  fica registrada onde o gerador de testes a lê, então somar uma medida semiaditiva ao longo do
  tempo passa a ser erro detectável e não apenas erro conhecido; o contrato é verificado por
  máquina, o que dispensa vigilância humana.
- **Negativas:** a Etapa 5 ganha um trabalho anterior ao SQL, e alterar a forma de uma view passa a
  exigir atualizar a declaração — atrito deliberado, que é o ponto do contrato.
- **Paridade com o GCP:** `contract: enforced` funciona sobre BigQuery, e as views de consumo viram
  *authorized views* no *dataset* separado que o [ADR-0008](0008-schemas-do-armazem.md) já reservou.
- **Documentos a atualizar:** [Glossário de Negócio](../glossario_de_negocio/) — as perguntas;
  [Modelo de Dados](../modelo_de_dados.md) §3.1 — medidas e aditividade por fato;
  [Qualidade de Dados](../qualidade_de_dados.md) — teste de grão e verificação de contrato;
  [Governança de Dados](../governanca_de_dados.md) §7 — as views nomeadas.
