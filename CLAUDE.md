# Convenções de Trabalho

> **O que vive aqui:** como se trabalha neste repositório — idioma, nomenclatura, *commits*, modo
> de desenvolvimento assistido e definição de pronto.
>
> **O que não vive aqui:** o que o projeto é (ver [Termo de Abertura](Abertura_de_projeto.md)); o
> mapa dos documentos (ver [README](README.md)); como executar (ver
> [Execução Local](docs/execucao_local.md)).

---

## 1. Contexto em cinco linhas

MVP de engenharia e governança de dados de ponta a ponta, sobre um marketplace de varejo
*omnichannel* sintético: PostgreSQL → Airbyte → dbt → datamart dimensional → views, orquestrado por
Airflow, com um fluxo de streaming de estoque (Debezium → Redpanda → Beam) e replicação futura no
GCP por Terraform. Todos os dados são sintéticos. A fase local precede e condiciona a fase GCP.
O padrão de execução é o de um ambiente corporativo real: o dado é simulado, a engenharia não
(**P10**). O foco é construir — o estudo do resultado é atividade posterior à entrega.

---

## 2. Idioma

| Conteúdo | Idioma |
|---|---|
| Documentos, comentários de governança, READMEs, ADRs, dicionário de dados, glossários | Português brasileiro |
| Código Python: variáveis, funções, módulos | Inglês |
| Objetos de banco: schemas, tabelas, colunas, views, *constraints* | Inglês |
| Identificadores técnicos em geral, incluindo chaves de `meta:` e nomes de blocos `{% docs %}` | Inglês |
| Mensagens de *commit* | Português |
| Nomes de arquivos de documentação | Português |

**Exceções:** termos técnicos consagrados (*staging*, *data warehouse*, *view*, *streaming*)
permanecem em inglês dentro de textos em português; conteúdo exigido em inglês por ferramenta ou
padrão externo é gerado em inglês.

---

## 3. Nomenclatura

- `snake_case` em objetos de banco e em Python.
- Tabelas transacionais no plural (`customers`, `order_items`); dimensões no singular com prefixo
  (`dim_customer`); fatos com prefixo (`fact_sales_order_item`).
- Modelos dbt de *staging* seguem `stg_<origem>__<tabela>`.
- Cada camada é um schema próprio — a camada **nunca** vira prefixo de nome de tabela.
- Valores monetários em tipo decimal; **nunca `float`**.
- *Timestamps* de evento sempre com fuso horário (`timestamptz`).

O padrão de afixos está fixado pelo [ADR-0013](docs/adr/0013-nomenclatura-por-prefixo-de-tipo.md).

---

## 4. Commits

Formato [Conventional Commits](https://www.conventionalcommits.org/) com descrição em português:

```
docs: adiciona plano de desenvolvimento
feat: implementa motor de geração orientado a configuração
fix: corrige reconciliação de contagens entre staging e trusted
```

Um *commit* por assunto. Mensagem que precisa de "e" para descrever o que fez provavelmente são
dois *commits*.

---

## 5. Modo de desenvolvimento assistido

O Claude Code é **ferramenta de desenvolvimento**, sem poder de aprovação. O Owner atua como
arquiteto e Data Custodian: conecta as peças, valida as entregas e decide.

Isso muda o cálculo de esforço — documentar 40 tabelas, escrever centenas de testes estruturais e
preencher metadados deixa de ser proibitivo. Mas cria o risco **R14**: volume gerado que ninguém
consegue revisar de verdade. As regras abaixo existem para manter a revisão viável.

**Preferir sempre geração orientada a artefato declarativo.** Configuração do gerador, `.yml` do
dbt, arquivo de conector — não dezenas de scripts equivalentes. O que se revisa é a declaração, não
a repetição.

**Revisão integral do declarativo, amostragem no derivado.** O Owner revisa 100% do que é
declaração — configuração do gerador, `.yml` do dbt, modelos SQLAlchemy, catálogo de falhas do
legado, ADRs — e por amostragem o que nasce dela: migrações geradas, testes repetitivos,
documentação de coluna. É o que torna **R14** administrável: se a declaração está correta e a
geração é determinística, o derivado herda a correção. O corolário é que **erro em declaração é
bloqueante**; erro em derivado é sintoma, e se corrige na declaração — nunca no arquivo gerado.

**Nunca decidir sozinho o que exige ADR.** Escolha de ferramenta, mudança de camada, alteração de
modelagem central ou de tratamento de dados são decisão do Owner. Na dúvida, propor e registrar
como pendência, não implementar.

**Não inventar.** Métrica, volume, linhagem ou resultado que não foi medido é marcado como pendente
(princípio **P5**). "Planejado" e "medido" são rótulos diferentes e nunca se misturam.

**Cada assunto tem um dono documental.** Antes de escrever, conferir o mapa da documentação no
[README](README.md) e escrever **no lugar certo, uma vez só**. Duplicar informação entre documentos
é considerado defeito — os documentos divergem, e o leitor deixa de saber qual vale.

---

## 6. Regras invioláveis

1. Nenhum segredo no repositório. Credenciais apenas em `.env`; `.env.example` versionado sem
   valores.
2. Somente dados sintéticos. Nenhum dado pessoal real, de qualquer origem.
3. Nenhuma camada é editada manualmente — correções nascem de código versionado.
4. Nenhum registro é descartado em silêncio: o que não passa vai para `quarantine` com motivo.
5. Nenhum componente novo na arquitetura sem ADR que declare problema resolvido, custo aceito e
   contrapartida na fase GCP.

---

## 7. Definição de pronto

Antes de considerar uma entrega concluída:

- [ ] migrações aplicáveis do zero;
- [ ] pipeline executável de ponta a ponta;
- [ ] testes de qualidade de dados passando;
- [ ] reconciliação entre camadas conferida;
- [ ] catálogo, dicionário e linhagem atualizados na mesma entrega;
- [ ] campos novos classificados quanto à sensibilidade;
- [ ] cobertura conferida — todas as tabelas populadas e todos os casos de borda representados;
- [ ] revisão de segredos e de `.gitignore`;
- [ ] revisão feita conforme a §5 — integral no declarativo, por amostragem no derivado;
- [ ] documentação revisada, sem duplicar o que já existe em outro artefato;
- [ ] decisões relevantes registradas em ADR;
- [ ] critérios de conclusão da etapa, no [plano](docs/plano_de_desenvolvimento.md), satisfeitos.

Os critérios de sucesso do projeto — que são outra coisa: valem para a entrega final — estão no
[Termo de Abertura](Abertura_de_projeto.md).
