# 03 — Cloud SQL for PostgreSQL: a origem

> **Quando fazer.** **Seg 09**, passos 1 a 6, 8 e 9: a instância está de pé desde as 11:30. O passo 7 fica de fora.

**Em uma frase.** O mesmo PostgreSQL 16 dos contêineres `source_db` e `legacy_db`, como serviço:
a Google cuida de disco, *backup*, *patch* e alta disponibilidade; você cuida de schema, usuários e
consultas. Recebe as migrações Alembic, o gerador de dados e o `seed-legacy` sem mudança.

**Quanto custa e por quê.** Por **hora ligada** (vCPU + RAM), por GB de disco e por *backup*.
A instância `db-custom-2-7680` está na
[Capacidade §2.14](../docs/capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026); parada, cobra só disco. São dois bancos na **mesma** instância.

**Onde fica.** ☰ → *SQL* (`console.cloud.google.com/sql/instances`). Página da instância →
abas *Overview*, *Connections*, *Users*, *Databases*, *Backups*, *Replicas*, *Operations*,
*Query Insights*, *Logs*, *System insights*, *Edit*.

**O que é deste projeto aqui.** A instância `mvp-ed1-origens` (PostgreSQL 16, `us-central1`) com os
bancos `source_db` (schema `oltp`, 40 tabelas) e `legacy_db`; o usuário da origem, que também serve
ao Debezium Server (com **replicação lógica**: flag `cloudsql.logical_decoding=on`, *publication* e
*replication slot*; o atributo `REPLICATION` veio no passo 10 da §6.6); a rede: IP privado para o
GKE e o Composer, e IP público sem *authorized networks*, usado só pelo Cloud SQL Auth Proxy.

## Roteiro guiado

1. **Overview.** Versão (16), região/zona, vCPU/RAM, disco, IP, estado. *Por quê:* região tem
   de ser a mesma do BigQuery e do Composer (cap. 01, tráfego entre regiões). Anote o *connection
   name* (`projeto:regiao:instancia`) — é o que o *Cloud SQL Auth Proxy* e o Composer usam.
2. **Edit → Flags.** Procure `cloudsql.logical_decoding`, `max_connections`, `jit` (o projeto
   desligou o JIT localmente por medição — [Capacidade §2.10](../docs/capacidade_e_recuperacao.md);
   veja se o Terraform replicou). *Por quê:* o Debezium não captura sem *logical decoding*; a
   diferença entre "CDC funciona" e "não funciona" é uma flag.
3. **Databases** e **Users.** Os bancos e os usuários. *Por quê:* o usuário do Debezium precisa
   de `REPLICATION`; usuário do Airbyte só de leitura — é o `ingestor` da §7 na ponta da origem.
4. **Connections.** Rede: IP público + *authorized networks*, ou IP privado (VPC). *Cloud SQL
   Auth Proxy* é o caminho seguro sem abrir IP. *Por quê:* é onde "por que o Composer não conecta"
   se resolve; e onde a decisão de segurança da origem está visível.
5. **Backups.** *Automated backups* ligado? *Point-in-time recovery*? Retenção? *Por quê:* cada
   *backup* cobra disco e **sobrevive ao `destroy`** se o Terraform não desligar — cap. 11.
6. **Operations.** Toda operação administrativa (criação, *backup*, *restart*, *import*) com hora e
   quem pediu. *Por quê:* é o registro de que a instância nasceu pelo Terraform, quando.
7. **Query Insights.** Não está ligado na instância, e **não ligue**: mudaria a configuração por
   fora do Terraform. Fica como leitura: em produção, é aqui que se veem as consultas mais caras,
   por usuário. *Por quê:* é o
   `auto_explain` do armazém local ([Capacidade §2.11](../docs/capacidade_e_recuperacao.md)) em
   forma de tela — mostra o `SELECT` do Airbyte por tabela e o custo do *backfill*.
8. **Logs.** Abre o Logs Explorer com `resource.type="cloudsql_database"`. Procure
   `postgres.log` durante uma sincronização: conexões do Airbyte, o *replication slot* do
   Debezium. *Por quê:* registro do sistema, não captura.
9. **Cloud SQL Studio** (no menu da instância; não exercitado aqui): entre no `source_db` com o
   usuário da origem (a senha está no Secret Manager) e rode `select count(*) from oltp.orders`. Não
   use `gcloud sql connect`, que libera seu IP nas redes autorizadas. *Por quê:* reproduzível; e é o "origem no instante" da
   reconciliação `oltp → raw` (Qualidade §7) — o número que o BigQuery `raw` tem de bater.

## Onde aciona, onde registra, o que controla

- **Aciona:** conexões (Airbyte, Debezium, você); operações administrativas em *Operations*,
  *Backups*, *Import/Export*.
- **Registra:** *Operations* (admin), *Logs* (`postgres.log`, `pgaudit` se ligado), *Query
  Insights* (consultas), *System insights* (CPU, memória, conexões, disco).
- **Controla:** flags, usuários, rede, *backups*/PITR, tamanho da máquina, *maintenance window*,
  proteção contra exclusão (`deletion_protection` — se ligada, o `destroy` falha, de propósito).

## Armadilhas

- `deletion_protection` ligada é boa prática e **impede o `terraform destroy`**: o Terraform
  precisa desligá-la antes — confira o HCL.
- *Backups* automáticos e PITR (*WAL* retido) cobram e ficam depois do `destroy` da instância
  se forem *on-demand*. Aqui os automáticos estão desligados, e o `make gcp-desmonte-sql` prova que nada ficou.
- *Replication slot* do Debezium **retém WAL** se o *pod* parar sem apagar o *slot*: disco
  cresce até encher. Com o *pod* parado, olhe *System insights → Storage*.
- Instância "parada" (*Stop*) ainda cobra disco; só o `destroy` zera.

## Evidência a levar

- Captura de *Overview* (versão, região, máquina) e de *Flags* com `cloudsql.logical_decoding`.
- As contagens de 3–4 tabelas (para a reconciliação), com a consulta usada.
- Captura de *Operations* com a criação pelo Terraform.

## O que você saberá dizer depois

- "A origem roda em Cloud SQL com *logical decoding* ligado para o Debezium; o Airbyte lê por
  usuário próprio e o CDC por *replication slot*."
- "`deletion_protection` e *backups* são o que sobrevive a um `destroy` mal feito — o desmonte
  provou que não sobrou nenhum."
