variable "master_instance_name" {
  description = "will on root"

}

variable "project_id" {
  type        = string
  description = "Project ID of the GCP project"
  default     = "propane-dogfish-395916"
}

variable "region" {
  type        = string
  description = "Region of the GCP project"
}


variable "database_version" {
  description = "The database version to use"
  type        = string
}

variable "tier" {
  description = "The tier for the master instance."
  type        = string
}

variable "read_replica_name_suffix" {
  description = "The optional suffix to add to the read instance name"
  type        = string
  default     = "-replica"
}

variable "ip_configuration" {
  description = "The ip configuration for the master instances."
  type = object({
    authorized_networks = list(map(string))
    ipv4_enabled        = bool
    private_network     = string
    require_ssl         = bool
    allocated_ip_range  = string
  })
  default = {
    authorized_networks = []
    ipv4_enabled        = true
    private_network     = null
    require_ssl         = true
    allocated_ip_range  = null
  }
}


variable "user_labels" {
  description = "The key/value labels for the master instances."
  type = object({
    tla                       = string
    ci                        = string
    environment               = string
    portfolio_manager         = string
    new_cost_center           = string
    pending_deletion          = string
    resource_last_update_date = string
    opt_in_handler            = string
    opt_out_handler           = string
    resource_location         = string
    workload_type             = string
  })
  validation {
    condition     = length(var.user_labels) != 0
    error_message = "Must specify label values"
  }
  default = {
    tla                       = "sample_tla"
    ci                        = "sample_ci"
    environment               = "sample_environment"
    portfolio_manager         = "sample_manager"
    new_cost_center           = "sample_cost_center"
    pending_deletion          = "sample_pending"
    resource_last_update_date = "sample_update_date"
    opt_in_handler            = "sample_opt_in"
    opt_out_handler           = "sample_opt_out"
    resource_location         = "sample_location"
    workload_type             = "sample_workload"
  }
}

variable "zone" {
  type        = string
  description = "The zone for the master instance, it should be something like: \"us-central-a\", \"us-east-c\"."
}

variable "activation_policy" {
  description = "The activation policy for the master instance. Can be either \"ALWAYS\", \"NEVER\", or \"ON DEMAND\"."
  type        = string
  default     = "ALWAYS"
}


variable "additional_local_users" {
  description = "A List of Local users to be created in the cluster"
  type = list(object({
    name     = string
    password = string
  }))
  default = []
}

variable "additional_access_service_accounts" {
  description = "A list of existing service account email addresses to be added as IAM database users and granted login access"
  type        = list(string)
  default     = []
}

variable "availability_type" {
  description = "The availability type for the master instance. This is only used to set up high availability for the PostgreSQL Instance."
  type        = string
  default     = "REGIONAL"
}

variable "backup_configuration" {
  description = "The backup_configuration settings subblock for the database settings"
  type = object({
    enabled                        = bool
    start_time                     = string
    location                       = string
    point_in_time_recovery_enabled = bool
    retained_backups               = number
    retention_unit                 = string
    transaction_log_retention_days = number
  })
  default = {
    enabled                        = true
    start_time                     = "01:00"
    location                       = "US"
    point_in_time_recovery_enabled = true
    retained_backups               = 7
    retention_unit                 = "COUNT"
    transaction_log_retention_days = 7
  }
}

variable "create_timeout" {
  description = "The optional timeout that is applied to limit long database creates."
  type        = string
  default     = "30m"
}

variable "database_flags" {
  description = "The database flags for the master instance. See more details [here](https://cloud.google.com/sql/docs/postgres/flags)"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "update_timeout" {
  description = "The optional timout that is applied to limit long database updates."
  type        = string
  default     = "20m"
}

variable "delete_timeout" {
  description = "The optional timeout that is applied to limit long database deletes."
  type        = string
  default     = "30m"
}

variable "deletion_protection" {
  description = "Used to block Terraform from deleting a SQL Instance."
  type        = bool
  default     = false
}

variable "disk_autoresize" {
  description = "Configuration to increase storage size."
  type        = bool
  default     = true
}

variable "disk_size" {
  description = "The disk size for the master instance."
  default     = 10
}

variable "disk_type" {
  description = "The disk type for the master instance."
  type        = string
  default     = "PD_SSD"
}

variable "encryption_key_name" {
  description = "The full path to the encryption key used for the CMEK disk encryption"
  type        = string
  default     = ""
}

variable "identifier" {
  description = "Unique identifier for the instance name suffix"
  type        = string
  default     = "01"
}


variable "instance_name" {
  description = "Name of the instance, Overrides the standard name that is generated based on region, environment, TLA, and identifier"
  type        = string
  default     = null
}

variable "maintenance_window_day" {
  description = "The day of week (1-7) for the master instance maintenance."
  type        = number
  default     = 7
}

variable "maintenance_window_hour" {
  description = "The hour of day (0-23) for the master instance maintenance window."
  type        = number
  default     = 0
}
variable "maintenance_window_update_track" {
  type    = string
  default = "canary"
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which storage can be auto increased."
  type        = number
  default     = 0
}


variable "insights_config" {
  description = "The insights_config settings for the database."
  type = object({
    query_string_length     = number
    record_application_tags = bool
    record_client_address   = bool
  })
  default = null
}

variable "pricing_plan" {
  description = "The pricing plan for the master instance."
  type        = string
  default     = "PER_USE"
}

variable "secondary_zone" {
  type    = string
  default = null
}

variable "read_replicas" {
  description = "List of read replicas to create. Encryption key is required for replica in different region. For replica in same region as master set encryption_key_name = null"
  type = list(object({
    name                = string
    tier                = string
    zone                = string
    disk_type           = string
    disk_autoresize     = bool
    disk_size           = string
    user_labels         = map(string)
    encryption_key_name = optional(string)
    database_flags = list(object({
      name  = string
      value = string
    }))
    ip_configuration = object({
      authorized_networks = list(map(string))
      ipv4_enabled        = bool
      private_network     = string
      require_ssl         = bool
    })
  }))
  default = []
}


variable "random_instance_name" {
  type        = bool
  description = "Sets random suffix at the end of the Cloud SQL resource name"
  default     = false
}

variable "module_depends_on" {
  type    = list(any)
  default = []
}
