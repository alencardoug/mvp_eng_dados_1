# Capacidade e Recuperação

> **O que vive aqui:** o orçamento de armazenamento do ambiente local, como ele é medido e
> imposto, e o único ponto de recuperação do projeto.
>
> **O que não vive aqui:** os parâmetros do gerador (ver
> [Geração de Dados](geracao_de_dados.md)); as metas de linhas por tabela (ver
> [Modelo de Dados](modelo_de_dados.md)); o *snapshot* imutável do legado, que tem outra finalidade
> (ver [Origem Legada](origem_legada.md#4-snapshot-imutável)).

| Campo | Informação |
|---|---|
| Limite planejado | **4 GB decimais** (`4.000.000.000` bytes) |
| Abrangência | `source_db` + `legacy_db` + `warehouse_db` + ponto de recuperação |
| Versão | 1.1 |
| Situação | Planejado — a recalibrar com a medição do perfil `demo`, na Etapa 4 |
| Última revisão | 03/09/2026 |

---

## 1. Orçamento do perfil `demo_4gb`

O perfil foi dimensionado para permanecer abaixo do limite mesmo com a multiplicação de linhas
entre camadas.

| Componente | Linhas físicas | Orçamento máximo |
|---|---:|---:|
| `oltp`, incluindo índices | 2.526.495 a 2.576.495 | 750 MiB |
| `raw`, incluindo metadados do Airbyte | 2.526.495 a 2.576.495 | 1.650 MiB |
| `analytics`, incluindo índices | 569.820 a 619.820 | 350 MiB |
| Snapshot, tratamento e quarentena do legado | ~100 registros falhos e seus resultados | 50 MiB |
| Metadados persistidos de Airbyte, dbt e governança | Variável | 200 MiB |
| Ponto de recuperação comprimido | `source_db` + `legacy_db` | 450 MiB |
| **Meta ocupada** | **5,62 mi no seed; até 5,77 mi após o streaming, mais o legado** | **Até 3.450 MiB** |
| **Reserva até o limite** | — | **~365 MiB** |

Como a largura real das linhas e a compressão só serão conhecidas após a implementação, a faixa
esperada é de **3,4 a 3,9 GB** — nunca acima do limite configurado.

### 1.1 Condições de validade

O orçamento só se sustenta se:

- `staging` usar **views**;
- modelos intermediários de `trusted` usarem views ou materialização `ephemeral` sempre que
  possível;
- existir **somente uma cópia persistida** dos dados brutos de cada origem;
- o banco principal **não** gerar *snapshots* periódicos nem fatos *snapshot*, além do único ponto
  de recuperação aprovado;
- o legado mantiver somente o *snapshot* imutável aprovado e as saídas de tratamento
  correspondentes;
- índices forem criados por necessidade de consulta e integridade, não em todas as colunas;
- textos livres de atendimento tiverem tamanho máximo e não carregarem anexos;
- cargas completas antigas e tabelas temporárias forem removidas de forma controlada após o
  sucesso da execução.

### 1.2 O que está fora do limite

Imagens Docker, logs, arquivos temporários e WAL transitório **não** entram nos 4 GB. A execução
local deve reservar **pelo menos 8 GB de disco** para operar com segurança — e mais folga se
Airbyte, Airflow e a mensageria estiverem ativos simultaneamente.

---

## 2. Controle automático do limite

O pipeline **mede**, não presume:

- emitir alerta ao alcançar `3.700.000.000` bytes;
- impedir novas expansões ao alcançar `4.000.000.000` bytes;
- registrar tamanho por banco, schema, tabela e índice ao final de cada etapa;
- estimar previamente a expansão das tabelas de eventos antes de materializá-las;
- validar o tamanho do *snapshot* candidato somado aos bancos antes de promovê-lo;
- ao precisar reduzir, reduzir primeiro outros eventos de alta cardinalidade, **preservando
  `cart_items` acima de 1 milhão de linhas**;
- interromper o produtor de streaming ao atingir 50.000 novos movimentos ou o limite de
  armazenamento — o que ocorrer primeiro;
- **falhar explicitamente** se uma mudança de schema ou de materialização romper o orçamento.

As medições usam `pg_database_size`, `pg_total_relation_size` e `pg_indexes_size`. O tamanho dos
arquivos do ponto de recuperação também é somado ao total persistido.

Os valores deste documento são recalibrados a partir da medição do perfil `demo`, ao fim da
Etapa 4 — bytes por linha e crescimento de índice medidos numa fração do volume e extrapolados —,
e conferidos contra a execução real do `demo_4gb` na Etapa 12. A documentação distingue sempre o
**planejado** do **medido** (**P5**).

---

## 3. Ponto único de recuperação

Após uma execução ponta a ponta aprovada, o projeto mantém **um único *snapshot* lógico last known
good**, em formato customizado e comprimido do `pg_dump`. Ele permite restaurar uma fonte degradada
e reconstruir as demais camadas.

### 3.1 Conteúdo do pacote

- `source_db.dump`;
- `legacy_db.dump`;
- *checksums* dos arquivos;
- `seed`, `as_of_date` e versão das migrações;
- último `event_sequence` e cursor de CDC confirmado;
- *commit* Git correspondente ao código aprovado;
- manifesto com contagens e tamanhos por tabela;
- instruções testadas de restauração e de reconstrução do `warehouse_db`.

### 3.2 Regras

- O `warehouse_db` **não** entra no pacote: é refeito por Airbyte, dbt e Airflow a partir das duas
  fontes restauradas. Incluí-lo duplicaria armazenamento sem ganho.
- O pacote **não é versionado no Git**.
- Um novo *snapshot* só substitui o anterior depois que migrações, pipeline, testes,
  reconciliações, *checksums* e uma **validação de restauração** forem concluídos.
- Durante a troca pode haver espaço temporário para o anterior e o candidato; ao final, somente o
  aprovado é retido.
- A restauração **altera o estado dos bancos** e só é executada mediante decisão explícita do
  responsável técnico.
