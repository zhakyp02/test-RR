locals {
  nhid_db_users = []

  dba_adm_itac_name = substr("sa-dba-adm-${google_sql_database_instance.postgres_db_instance.name}", 0, 30)
  dba_adm_itac_user = trimsuffix(google_service_account.dba_admin_impersonate_sa.email, ".gserviceaccount.com")

  app_supp_itac_name = substr("sa-app-supp-${google_sql_database_instance.postgres_db_instance.name}", 0, 38)
  app_supp_itac_user = trimsuffix(google_service_account.app_supp_impersonate_sa.email, ".gserviceaccount.com")

  region_str    = split("-", var.region)
  region_letter = substr(local.region_str[1], 8, 1)
  region_number = substr(local.region_str[1], length(local.region_str[1]) - 1, 1)

  instance_name = var.instance_name == null ? lower("gep${local.region_letter}${local.region_number}${lookup(var.user_labels, "tla")}") : var.instance_name

  replicas = {
    for x in var.read_replicas : "${local.instance_name}-replicas-${var.read_replica_name_suffix}${local.instance_name}" => x
  }


  default_database_flags = [
    {
      name  = "cloudsql.iam_authentication",
      value = "on"
    },
    {
      name  = "log_checkpoints",
      value = "on"
    },
    {
      name  = "log_connections",
      value = "off" // Changed from "on"
    },
    {
      name  = "log_disconnections",
      value = "off" // Changed from "on"
    },
    {
      name  = "log_lock_waits",
      value = "on"
    },
    {
      name  = "log_min_messages",
      value = "error"
    },
    {
      name  = "log_temp_files",
      value = "0"
    },
    {
      name  = "log_min_duration_statement",
      value = "-1"
    },
    {
      name  = "log_statement",
      value = "ddl"
    },
  ]

  database_flags = concat(var.database_flags, local.default_database_flags)

  # user_labels = merge(
  #   var.user_labels,
  #   {
  #     "tla": var.tla,
  #     "tlo": var.tlo,
  #     "environment": var.environment,
  #     "cost center": var.cost_center
  #   }
  # )

  project_id = var.project_id == null ? var.project_id : var.project_id

  ip_configuration_enabled = length(keys(var.ip_configuration)) > 0 ? true : false
  ip_configurations = {
    enabled  = var.ip_configuration
    disabled = {}
  }
  users                  = { for u in local.additional_local_users : u.name => u }
  additional_local_users = concat(local.nhid_db_users, var.additional_local_users)

  point_in_time_recovery_enabled = var.availability_type == "REGIONAL" ? lookup(var.backup_configuration, "point_in_time_recovery_enabled", true) : false
  backups_enabled                = var.availability_type == "REGIONAL" ? lookup(var.backup_configuration, "enabled", true) : false
  retained_backups               = var.availability_type == "REGIONAL" ? lookup(var.backup_configuration, "retained_backups", null) : null
  retention_unit                 = var.availability_type == "REGIONAL" ? lookup(var.backup_configuration, "retention_unit", null) : null
}
