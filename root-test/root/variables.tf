variable "project_id" {
  type        = string
  description = "Project ID of the GCP project"
}

variable "region" {
  type        = string
  description = "Region of the GCP project"
}

# variable "subnet_link" {
#   type = string
# }

variable "tla" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "identifier" {
  description = "Unique identifier for the instance name suffix"
  type        = string
  default     = "01"
}

variable "zones" {
  description = "The zones to host the cluster in (required if it's a zonal cluster)"
  type        = list(string)
  default     = ["us-central1-a"]
}

variable "database_version" {
  description = "The database version to use"
  type        = string
}

variable "tier" {
  description = "The tier for the master instance"
  type        = string
}

variable "require_ssl" {
  type        = bool
  description = "Enable SSL on the instance"
  default     = true # will likely need to make this "true" in the final version
}

variable "network" {
  type        = string
  description = "Self-link to private VPC where instance will be located. Must have a GPSA reserved range configured."
  default     = null
}

variable "user_labels" {
  description = "The key/value labels for the master instances."
  type        = map(string)
}

variable "database_flags" {
  description = "Config flags for the instance"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "machine_type" {
  type        = string
  description = "The machine type to create."
  default     = "e2-micro"
}

variable "additional_database" {
  type        = bool
  description = "A flag to enable or disable additional databases creation"
  #   default     = false
}

variable "add_database_name" {
  type = string
  #default = "additional-database"
}

variable "add_database_charset" {
  type = string
  #default = "UTF8"
}

variable "add_database_collation" {
  type = string
  #default = "en_US.UTF8"
}

variable "read_replicas" {
  description = "List of read replicas to create"
  type = list(object({
    name            = string
    tier            = string
    zone            = string
    disk_type       = string
    disk_autoresize = bool
    disk_size       = string
    user_labels     = map(string)
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
}

variable "read_replica_name_suffix" {
  description = "The optional suffix to add to the read instance name"
  type        = string
}

variable "read_replica_deletion_protection" {
  description = "Used to block Terraform from deleting replica SQL Instances."
  type        = bool
  default     = false
}
