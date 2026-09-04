# ADR-0025 — Aplicar as policy tags por fluxo automatizado

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | Q1 |

## Contexto

O [ADR-0011](0011-classificacao-e-papeis-de-acesso.md) fixou quatro níveis de classificação e cinco
papéis, mantidos como YAML versionado ([ADR-0007](0007-catalogo-como-codigo.md)). Na fase GCP essa
classificação precisa virar **policy tags** no BigQuery, que é o mecanismo que efetivamente nega
acesso a coluna.

O Termo, até a versão 1.1, colocava **CI/CD de infraestrutura fora do escopo**. Só que aplicar
*policy tags* a partir do YAML é, na prática, um passo de CI/CD — e mantê-lo manual significa que a
governança do projeto é aplicada por alguém lembrar de rodar um comando. Governança aplicada à mão
não é governança verificável.

A questão foi levantada como **Q1** e resolvida com abertura de escopo. O Termo v1.2 §4 registra a
exceção.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **CI/CD mínimo, restrito às policy tags** | A classificação passa a ser aplicada por máquina a partir da fonte versionada, e a divergência entre YAML e BigQuery vira impossível em vez de improvável. É a demonstração de governança que um repositório público de referência deveria ter | Exige emenda ao Termo, autenticação do CI no GCP, e abre uma porta que precisa ser mantida estreita |
| Script manual na Etapa 13 | Preserva o escopo original intacto; a fonte da verdade continua sendo o YAML, que é o ponto principal | Aplicação depende de alguém rodar o comando; a divergência entre o declarado e o aplicado é questão de tempo, e ninguém é avisado quando ocorre |
| Terraform aplica as tags | Coerente com o [ADR-0004](0004-terraform-como-iac.md), e não é CI/CD — é IaC, já no escopo | Acopla governança ao ciclo de vida da infraestrutura: reclassificar um campo passaria a exigir `terraform apply` sobre o ambiente inteiro, e o mapeamento YAML → HCL é gerado, não escrito |
| Adiar para a Etapa 13 | Decidir com o Terraform já pronto | A questão tem três opções claras hoje e não fica mais clara esperando; e o desenho da governança na nuvem ficaria sem âncora |

## Decisão

Um **fluxo automatizado único e declarado** aplica as *policy tags* no BigQuery a partir do YAML de
classificação, disparado quando esse YAML muda. Nada além disso é automatizado: o restante do CI/CD
permanece fora do escopo, conforme o [Termo](../../Abertura_de_projeto.md) §4.

**Condição inseparável da decisão:** a autenticação usa **federação de identidade** (*Workload
Identity Federation*), com credencial de curta duração emitida no momento da execução. **Nenhuma
chave de conta de serviço é armazenada como segredo**, em nenhuma hipótese — a regra 1 do
[`CLAUDE.md`](../../CLAUDE.md) não admite exceção, e uma chave longeva num repositório público seria
a pior forma possível de violá-la.

O fluxo tem permissão apenas para gerenciar *policy tags* e sua vinculação a colunas. Não cria, não
altera e não lê dados.

## Consequências

- **Positivas:** a classificação declarada e a aplicada deixam de poder divergir; o repositório
  demonstra governança automatizada, que é o padrão corporativo (**P10**); e a tabela de
  classificação aplicada do [ADR-0023](0023-escopo-do-schema-governance.md) ganha uma contraparte
  verificável na nuvem.
- **Negativas:** o Termo precisou ser emendado, e a fronteira "CI/CD fora do escopo" passa a ter uma
  exceção — que precisa ser defendida a cada nova tentação de ampliá-la. A federação de identidade é
  mais trabalhosa de configurar do que colar uma chave num segredo, e essa dificuldade é justamente
  o motivo pelo qual muita gente faz errado.
- **Paridade com o GCP:** a decisão é sobre a fase GCP. Na fase local não há equivalente — *policy
  tags* não existem no PostgreSQL, onde a classificação é aplicada por concessão de papel
  ([ADR-0011](0011-classificacao-e-papeis-de-acesso.md)). Esta é a assimetria prevista pelo próprio
  ADR-0011, não uma quebra do **P4**.
- **Documentos a atualizar:** [Governança de Dados](../governanca_de_dados.md) — a aplicação na
  nuvem; [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — Etapa 13;
  [Arquitetura](../arquitetura.md) §5; [Termo](../../Abertura_de_projeto.md) §4 — já feito na v1.2.
