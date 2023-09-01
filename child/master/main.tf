# data "google_project" "project" {
#   project_id = var.project_id
# }

# data "google_project" "project2" {
#   project_id = local.project_id
# }

resource "random_id" "suffix" {
  count       = var.random_instance_name ? 1 : 0
  byte_length = 4
}

resource "google_sql_database_instance" "postgres_db_instance" {
  provider = google-beta
  project  = local.project_id
  name     = local.instance_name

  database_version    = var.database_version
  region              = var.region
  encryption_key_name = var.encryption_key_name
  deletion_protection = var.deletion_protection
  settings {
    tier              = var.tier
    activation_policy = var.activation_policy
    availability_type = var.availability_type


    dynamic "backup_configuration" {
      for_each = [var.backup_configuration]
      content {
        binary_log_enabled             = false
        enabled                        = local.backups_enabled
        start_time                     = lookup(backup_configuration.value, "start_time", null)
        location                       = lookup(backup_configuration.value, "location", null)
        point_in_time_recovery_enabled = local.point_in_time_recovery_enabled
        transaction_log_retention_days = lookup(backup_configuration.value, "transaction_log_retention_days", null)

        dynamic "backup_retention_settings" {
          for_each = local.retained_backups != null || local.retention_unit != null ? [var.backup_configuration] : []
          content {
            retained_backups = local.retained_backups
            retention_unit   = local.retention_unit
          }
        }
      }
    }

    dynamic "ip_configuration" {
      for_each = [local.ip_configurations[local.ip_configuration_enabled ? "enabled" : "disabled"]]
      content {
        ipv4_enabled       = lookup(ip_configuration.value, "ipv4_enabled", null)
        private_network    = lookup(ip_configuration.value, "private_network", null)
        require_ssl        = lookup(ip_configuration.value, "require_ssl", true)
        allocated_ip_range = lookup(ip_configuration.value, "allocated_ip_range", null)

        dynamic "authorized_networks" {
          for_each = lookup(ip_configuration.value, "authorized_networks", [])
          content {
            expiration_time = lookup(authorized_networks.value, "expiration_time", null)
            name            = lookup(authorized_networks.value, "name", null)
            value           = lookup(authorized_networks.value, "value", null)
          }
        }
      }
    }



    dynamic "insights_config" {
      for_each = var.insights_config != null ? [var.insights_config] : []
      content {
        query_insights_enabled  = true
        query_string_length     = lookup(insights_config.value, "query_string_length", 1024)
        record_application_tags = lookup(insights_config.value, "record_application_tags", false)
        record_client_address   = lookup(insights_config.value, "record_client_address", false)
      }
    }
    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit
    disk_size             = var.disk_size
    disk_type             = var.disk_type
    pricing_plan          = var.pricing_plan
    dynamic "database_flags" {
      for_each = local.database_flags
      content {
        name  = lookup(database_flags.value, "name", null)
        value = lookup(database_flags.value, "value", null)
      }
    }

    user_labels = var.user_labels

    location_preference {
      zone           = var.zone
      secondary_zone = var.secondary_zone
    }

    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }
  }
  # Other configurations ...

  lifecycle {
    ignore_changes = [
      settings[0].disk_size
    ]
  }

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  depends_on = [
    null_resource.module_depends_on
  ]
}

resource "google_sql_database" "additional_databases" {
  count     = var.additional_database ? 1 : 0
  project   = local.project_id
  name      = var.add_database_name
  charset   = var.add_database_charset
  collation = var.add_database_collation
  instance  = google_sql_database_instance.postgres_db_instance.name

  depends_on = [
    null_resource.module_depends_on,
    google_sql_database_instance.postgres_db_instance
  ]
}

resource "random_password" "additional_passwords" {
  for_each = local.users

  keepers = {
    name = google_sql_database_instance.postgres_db_instance.name
  }

  length  = 32
  special = false

  depends_on = [
    null_resource.module_depends_on,
    google_sql_database_instance.postgres_db_instance
  ]
}

resource "google_sql_user" "additional_users" {
  for_each = local.users

  project  = local.project_id
  name     = each.value.name
  password = coalesce(each.value["password"], random_password.additional_passwords[each.value.name].result)
  instance = google_sql_database_instance.postgres_db_instance.name

  depends_on = [
    null_resource.module_depends_on,
    google_sql_database_instance.postgres_db_instance,
    # google_sql_database_instance.replicas
  ]
}

resource "null_resource" "module_depends_on" {
  triggers = {
    value = length(var.module_depends_on)
  }
}

resource "google_service_account" "proxy_sa_service_account" {
  account_id   = "proxy-${google_sql_database_instance.postgres_db_instance.name}"
  display_name = "Proxy SA for ${google_sql_database_instance.postgres_db_instance.name} PostgreSQL instance"
  description  = "Service account used for proxy GCE instance"
  project      = local.project_id
}

resource "google_project_iam_member" "proxy_sa_sql_client_role" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.proxy_sa_service_account.email}"
}


# resource "google_compute_instance" "sql_proxy_gce_instance" {
#   project      = local.project_id
#   name         = "sql-proxy-${local.instance_name}"
#   machine_type = var.machine_type
#   zone         = var.zone

#   allow_stopping_for_update = true
#   labels                    = var.user_labels

#   boot_disk {
#     initialize_params {
#       image = "cos-cloud/cos-stable"
#     }
#   }

#   network_interface {
#     subnetwork = var.proxy_subnet
#   }

#   metadata = {
#     "google-logging-enabled"    = "true"
#     # "gce-container-declaration" = "spec:\n containers:\n "
#     "metadata_startup_script"   = "echo '{\"live-restore\": true, \"log-opts\":{\"max-size\": \"1kb\", \"max-file\": \"51\" }, \"storage-driver\": \"overlay2\"}' > /etc/docker/daemon.json && systemctl restart docker"
#   }

#   service_account {
#     email = google_service_account.proxy_sa_service_account.email
#     scopes = [
#       "https://www.googleapis.com/auth/devstorage.read_only",
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring.write",
#       "https://www.googleapis.com/auth/service.management.readonly",
#       "https://www.googleapis.com/auth/servicecontrol",
#       "https://www.googleapis.com/auth/sqlservice.admin",
#       "https://www.googleapis.com/auth/trace.append"
#     ]
#   }

#   depends_on = [
#     null_resource.module_depends_on,
#     google_service_account.proxy_sa_service_account,
#     google_sql_database_instance.postgres_db_instance,
#   ]
# }


resource "random_password" "postgres_user_password" {
  keepers = {
    name = google_sql_database_instance.postgres_db_instance.name
  }
  special = true
  length  = 15
  depends_on = [
    var.module_depends_on,
    google_sql_database_instance.postgres_db_instance,
  ]
}

resource "google_sql_user" "postgres_user" {
  name            = "postgres"
  project         = local.project_id
  instance        = google_sql_database_instance.postgres_db_instance.name
  password        = random_password.postgres_user_password.result
  type            = "BUILT_IN"
  deletion_policy = "ABANDON"

  lifecycle {
    ignore_changes = all
  }
}

resource "google_service_account" "dba_admin_impersonate_sa" {
  account_id   = local.dba_adm_itac_name
  display_name = "DBA Admin impersonation service account for instance ${google_sql_database_instance.postgres_db_instance.name}"
  project      = local.project_id
}

resource "google_sql_user" "dba_admin_impersonate_sa" {
  name     = local.dba_adm_itac_user
  project  = local.project_id
  instance = google_sql_database_instance.postgres_db_instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

// Grant permissions to impersonate as SA
# resource "google_project_iam_member" "db_access_dba_admin_impersonate_iam" {
#   for_each = toset(["roles/iam.serviceAccountUser", "roles/iam.serviceAccountTokenCreator"])

#   service_account_id = google_service_account.dba_admin_impersonate_sa.id
#   role               = each.key
#   member             = "group:app-gcp-cloudsqladmin@keybank.com"
# }

// Create App Support impersonation SA
resource "google_service_account" "app_supp_impersonate_sa" {
  account_id   = local.app_supp_itac_name
  display_name = "App Support impersonation service account for instance ${google_sql_database_instance.postgres_db_instance.name}"
  project      = local.project_id
}

# # resource "google_sql_user" "app_supp_impersonate_sa" {
# #   name     = local.app_supp_itac_user
# #   project  = local.project_id
# #   instance = google_sql_database_instance.postgres_db_instance.name
# #   type     = "CLOUD_IAM_SERVICE_ACCOUNT"
# # }

# // Grant permissions to connect to CloudSQL
# resource "google_project_iam_member" "db_access_app_supp_impersonate_sa" {
#   for_each = toset(["roles/cloudsql.instanceUser", "roles/cloudsql.client", "roles/cloudsql.viewer"])

#   project = local.project_id
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.app_supp_impersonate_sa.email}"
# }

# resource "google_project_iam_member" "lob_impersonate_sa_view" {
#   for_each = var.access_groups

#   project = local.project_id
#   role    = "roles/cloudsql.viewer"
#   member  = "serviceAccount:${google_service_account.lob_impersonate_sa[each.key].email}"
# }

# resource "google_service_account_iam_member" "lob_impersonate_sa_account_user" {
#   for_each = var.access_groups

#   service_account_id = google_service_account.lob_impersonate_sa[each.key].id
#   role               = "roles/iam.serviceAccountUser"
#   member             = "group:${each.value}"
# }

# resource "google_service_account_iam_member" "lob_impersonate_sa_token_creator" {
#   for_each = var.access_groups

#   service_account_id = google_service_account.lob_impersonate_sa[each.key].id
#   role               = "roles/iam.serviceAccountTokenCreator"
#   member             = "group:${each.value}"
# }

# // Create Postgres-equivalent SA
# resource "google_service_account" "db_admin_service_account" {
#   account_id   = "postgres-${google_sql_database_instance.postgres_db_instance.name}"
#   display_name = "Superuser service account for instance ${google_sql_database_instance.postgres_db_instance.name}"
#   project      = local.project_id
# }

# resource "google_sql_user" "db_admin_service_account_user" {
#   name     = local.db_admin_sa
#   project  = local.project_id
#   instance = google_sql_database_instance.postgres_db_instance.name
#   type     = "CLOUD_IAM_SERVICE_ACCOUNT"
# }

# // Add additional access SA's as IAM users in the instance
# resource "google_sql_user" "db_access_service_account_user" {
#   for_each = toset(var.additional_access_service_accounts)

#   project  = local.project_id
#   instance = google_sql_database_instance.postgres_db_instance.name
#   type     = "CLOUD_IAM_SERVICE_ACCOUNT"
# }
