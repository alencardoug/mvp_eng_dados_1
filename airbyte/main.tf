# ══════════════════════════════════════════════════════════════════════════════
# Ingestão: `oltp` (source_db) → `raw` (warehouse_db).
#
# O modo de sincronização de cada tabela **não** é escrito aqui: vem de
# `streams.yml`, que é a declaração única exigida pelo ADR-0015. Duplicar o modo
# entre o YAML e o HCL criaria duas verdades sobre a mesma tabela, e a segunda
# divergiria na primeira edição desatenta.
#
# O provider 1.x expõe recursos genéricos — `airbyte_source` com a configuração
# em JSON e o conector identificado por `definition_id` — em vez de um recurso
# por conector. É mais verboso de ler e imune a mudança de spec de conector, que
# é a troca certa para um projeto que vai repetir isto na nuvem.
# ══════════════════════════════════════════════════════════════════════════════

locals {
  streams = yamldecode(file("${path.module}/streams.yml"))

  # Tradução do vocabulário do ADR-0015 para o da API do Airbyte. É a única
  # tradução do arquivo, e existe para que a declaração fale a língua da decisão
  # em vez da língua da ferramenta.
  modo_para_sync_mode = {
    full_refresh        = "full_refresh_overwrite"
    full_refresh_append = "full_refresh_append"
    dedup_history       = "incremental_deduped_history"
    append              = "incremental_append"
  }

  # Credenciais por origem. O `streams.yml` declara **o quê** se lê de cada uma;
  # aqui está de onde. Separar as duas coisas é o que permite acrescentar origem
  # sem tocar em credencial, e trocar credencial sem tocar na declaração.
  bancos = {
    retail = {
      host     = var.source_db_host
      port     = var.source_db_port
      database = var.source_db_name
      username = var.source_db_user
      password = var.source_db_password
    }
    legacy = {
      host     = var.legacy_db_host
      port     = var.legacy_db_port
      database = var.legacy_db_name
      username = var.legacy_db_user
      password = var.legacy_db_password
    }
  }

  # `tabelas` tem duas formas no YAML, e a diferença não é descuido: `retail`
  # declara o modo **por tabela**, porque cada uma tem o seu critério; `legacy`
  # declara um modo só para as 40, porque o critério é o mesmo em todas e
  # repeti-lo quarenta vezes seria repetição que envelhece. A normalização
  # abaixo é o preço dessa escolha, e cabe em cinco linhas.
  # As duas compreensões são separadas, e não um ternário, porque o HCL avalia
  # os dois ramos e exige tipos iguais entre eles — e aqui um lado é mapa e o
  # outro é lista. Ambas produzem o **mesmo** formato de saída, que é o que o
  # bloco de conexão consome sem saber de qual origem veio.
  fluxos = merge(
    {
      for origem, spec in local.streams.origens : origem => {
        for nome, tabela in spec.tabelas : nome => {
          modo   = tabela.modo
          cursor = try(tabela.cursor, null)
          chave  = try(tabela.chave, null)
        }
      } if !can(spec.modo)
    },
    {
      for origem, spec in local.streams.origens : origem => {
        for nome in spec.tabelas : nome => {
          modo   = spec.modo
          cursor = null
          chave  = null
        }
      } if can(spec.modo)
    },
  )
}

resource "airbyte_source" "origem" {
  for_each = local.streams.origens

  name          = "source_${each.key}"
  workspace_id  = var.airbyte_workspace_id
  definition_id = var.postgres_source_definition_id

  configuration = jsonencode({
    host     = local.bancos[each.key].host
    port     = local.bancos[each.key].port
    database = local.bancos[each.key].database
    username = local.bancos[each.key].username
    password = local.bancos[each.key].password
    schemas  = [each.value.schema]

    # Leitura por cursor, não por CDC: o log de transações da origem é
    # território do Debezium na Etapa 7, e dois consumidores disputando o mesmo
    # slot de replicação é problema que não precisa existir.
    replication_method = { method = "Standard" }

    # Sem TLS e sem túnel porque origem e destino estão na mesma máquina, atrás
    # do Docker. Na nuvem isto vira conexão privada — Etapa 13, mapa de paridade.
    ssl_mode      = { mode = "disable" }
    tunnel_method = { tunnel_method = "NO_TUNNEL" }
  })
}

resource "airbyte_destination" "camada" {
  for_each = local.streams.origens

  name          = "warehouse_db_${each.value.destino}"
  workspace_id  = var.airbyte_workspace_id
  definition_id = var.postgres_destination_definition_id

  configuration = jsonencode({
    host     = var.warehouse_db_host
    port     = var.warehouse_db_port
    database = var.warehouse_db_name
    username = var.warehouse_db_user
    password = var.warehouse_db_password
    schema   = each.value.destino

    # ── Por que CASCADE, e por que ele é seguro aqui ─────────────────────────
    # `full_refresh_overwrite` **derruba** a tabela de destino a cada carga, e as
    # views de `staging` dependem dela: sem CASCADE a segunda sincronização
    # falha com "cannot drop table because other objects depend on it".
    #
    # O que ele apaga são as views que o dbt recria no `dbt build` seguinte, não
    # dado. O `raw` é declarado **descartável** pelo ADR-0008 justamente por
    # isso: ele é réplica, e a fonte da verdade é `oltp`.
    #
    # A consequência precisa ser dita: a ordem `sync` → `dbt build` deixa de ser
    # preferência e passa a ser obrigatória. Entre as duas, as views de
    # `staging` não existem. É o orquestrador que garante a ordem — e é uma das
    # razões de o ADR-0003 ter ido buscar um.
    #
    # ── E por que ele é **desligado** no legado ──────────────────────────────
    # `raw_legacy` é snapshot imutável e retido (ADR-0008 e ADR-0037): a carga
    # acrescenta, nunca derruba. Ligar CASCADE ali seria autorizar o destino a
    # apagar a captura anterior — a única coisa contra a qual a exclusão física
    # é detectada. A declaração de cada origem diz se o destino é descartável.
    drop_cascade = each.value.destino_descartavel

    ssl_mode      = { mode = "disable" }
    tunnel_method = { tunnel_method = "NO_TUNNEL" }
  })
}

resource "airbyte_connection" "ingestao" {
  for_each = local.streams.origens

  name           = "${each.value.schema}_para_${each.value.destino}"
  source_id      = airbyte_source.origem[each.key].source_id
  destination_id = airbyte_destination.camada[each.key].destination_id

  # O destino manda no nome do schema: sem isto o Airbyte recria `oltp` dentro
  # do armazém e a camada `raw` do ADR-0008 deixa de existir onde foi declarada.
  namespace_definition = "destination"

  # Disparo pelo Airflow, não por agendador próprio: dependência entre ingestão
  # e transformação é responsabilidade do orquestrador (ADR-0003).
  schedule = { schedule_type = "manual" }

  configurations = {
    streams = [
      for nome, spec in local.fluxos[each.key] : {
        name         = nome
        sync_mode    = local.modo_para_sync_mode[spec.modo]
        cursor_field = spec.cursor == null ? null : [spec.cursor]
        primary_key  = spec.chave == null ? null : [for c in spec.chave : [c]]
      }
    ]
  }
}
