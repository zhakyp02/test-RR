locals {
  region_str    = split("-", var.region)
  region_letter = substr(local.region_str[1], 8, 1)
  region_number = substr(local.region_str[1], length(local.region_str[1]) - 1, 1)

  instance_name = var.instance_name == null ? lower("gep${local.region_letter}${local.region_number}${lookup(var.user_labels, "tla")}") : var.instance_name

  replicas = {
    for x in var.read_replicas : "${local.instance_name}-replicas-${var.read_replica_name_suffix}-${local.instance_name}" => x
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
  project_id     = var.project_id

}
