# 03 — Cloud SQL for PostgreSQL: a origem

**Em uma frase.** O mesmo PostgreSQL 16 dos contêineres `source_db` e `legacy_db`, como serviço:
a Google cuida de disco, *backup*, *patch* e alta disponibilidade; você cuida de schema, usuários e
consultas. Recebe as migrações Alembic, o gerador de dados e o `seed-legacy` sem mudança.

**Quanto custa e por quê.** Por **hora ligada** (vCPU + RAM), por GB de disco e por *backup*.
Instância pequena (2 vCPU / 8 GB) fica na casa de US$ 100–130/mês
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)); parada, cobra só disco. Dois
bancos na **mesma** instância custam uma; duas instâncias custam duas — confira o que o Terraform
fez.

**Onde fica.** ☰ → *SQL* (`console.cloud.google.com/sql/instances`). Página da instância →
abas *Overview*, *Connections*, *Users*, *Databases*, *Backups*, *Replicas*, *Operations*,
*Query Insights*, *Logs*, *System insights*, *Edit*.

**O que é deste projeto aqui.** A instância (ou duas) com os bancos da origem principal (schema
`oltp`, 40 tabelas) e do legado; o usuário do Airbyte e o do Datastream (este precisa de
**replicação lógica** ligada: flag `cloudsql.logical_decoding=on` e uma *publication* + *replication
slot*, o mesmo mecanismo do Debezium); a rede: IP privado, ou IP público com *authorized networks*.

## Roteiro guiado

1. **Overview.** Versão (16?), região/zona, vCPU/RAM, disco, IP, estado. *Por quê:* região tem
   de ser a mesma do BigQuery e do Composer (cap. 01, tráfego entre regiões). Anote o *connection
   name* (`projeto:regiao:instancia`) — é o que o *Cloud SQL Auth Proxy* e o Composer usam.
2. **Edit → Flags.** Procure `cloudsql.logical_decoding`, `max_connections`, `jit` (o projeto
   desligou o JIT localmente por medição — [Capacidade §2.10](../docs/capacidade_e_recuperacao.md);
   veja se o Terraform replicou). *Por quê:* o Datastream não captura sem *logical decoding*; a
   diferença entre "CDC funciona" e "não funciona" é uma flag.
3. **Databases** e **Users.** Os bancos e os usuários. *Por quê:* usuário do Datastream precisa
   de `REPLICATION`; usuário do Airbyte só de leitura — é o `ingestor` da §7 na ponta da origem.
4. **Connections.** Rede: IP público + *authorized networks*, ou IP privado (VPC). *Cloud SQL
   Auth Proxy* é o caminho seguro sem abrir IP. *Por quê:* é onde "por que o Composer não conecta"
   se resolve; e onde a decisão de segurança da origem está visível.
5. **Backups.** *Automated backups* ligado? *Point-in-time recovery*? Retenção? *Por quê:* cada
   *backup* cobra disco e **sobrevive ao `destroy`** se o Terraform não desligar — cap. 11.
6. **Operations.** Toda operação administrativa (criação, *backup*, *restart*, *import*) com hora e
   quem pediu. *Por quê:* é o registro de que a instância nasceu pelo Terraform, quando.
7. **Query Insights.** Ligue se não estiver (custa quase nada). Depois de uma sincronização do
   Airbyte e do *backfill* do Datastream, veja as consultas mais caras, por usuário. *Por quê:* é o
   `auto_explain` do armazém local ([Capacidade §2.11](../docs/capacidade_e_recuperacao.md)) em
   forma de tela — mostra o `SELECT` do Airbyte por tabela e o custo do *backfill*.
8. **Logs.** Abre o Logs Explorer com `resource.type="cloudsql_database"`. Procure
   `postgres.log` durante uma sincronização: conexões do Airbyte, o *replication slot* do
   Datastream. *Por quê:* registro do sistema, não captura.
9. **Cloud Shell:** `gcloud sql connect <instancia> --user=postgres` e um `\dn`, `\dt oltp.*`,
   `select count(*) from oltp.orders`. *Por quê:* reproduzível; e é o "origem no instante" da
   reconciliação `oltp → raw` (Qualidade §7) — o número que o BigQuery `raw` tem de bater.

## Onde aciona, onde registra, o que controla

- **Aciona:** conexões (Airbyte, Datastream, você); operações administrativas em *Operations*,
  *Backups*, *Import/Export*.
- **Registra:** *Operations* (admin), *Logs* (`postgres.log`, `pgaudit` se ligado), *Query
  Insights* (consultas), *System insights* (CPU, memória, conexões, disco).
- **Controla:** flags, usuários, rede, *backups*/PITR, tamanho da máquina, *maintenance window*,
  proteção contra exclusão (`deletion_protection` — se ligada, o `destroy` falha, de propósito).

## Armadilhas

- `deletion_protection` ligada é boa prática e **impede o `terraform destroy`**: o Terraform
  precisa desligá-la antes — confira o HCL.
- *Backups* automáticos e PITR (*WAL* retido) cobram e ficam depois do `destroy` da instância
  se forem *on-demand* — confira em *Backups* na sexta.
- *Replication slot* do Datastream **retém WAL** se o *stream* parar sem apagar o *slot*: disco
  cresce até encher. Ao pausar o Datastream, olhe *System insights → Storage*.
- Instância "parada" (*Stop*) ainda cobra disco; só o `destroy` zera.

## Evidência a levar

- Captura de *Overview* (versão, região, máquina) e de *Flags* com `cloudsql.logical_decoding`.
- Captura de *Query Insights* após uma sincronização do Airbyte.
- Saída do `gcloud sql connect` com as contagens de 3–4 tabelas (para a reconciliação).
- Captura de *Operations* com a criação pelo Terraform.

## O que você saberá dizer depois

- "A origem roda em Cloud SQL com *logical decoding* ligado para o Datastream; o Airbyte lê por
  usuário próprio e o CDC por *replication slot*."
- "Li o custo das consultas do Airbyte por tabela no *Query Insights*."
- "`deletion_protection` e *backups* são o que sobrevive a um `destroy` mal feito — conferi na
  sexta."
