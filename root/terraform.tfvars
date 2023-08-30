project_id = "propane-dogfish-395916"
region     = "us-central1"
network    = "https://www.googleapis.com/compute/v1/projects/propane-dogfish-395916/global/networks/default"
# subnet_link      = "https://www.googleapis.com/compute/v1/projects/propane-dogfish-395916/regions/us-central1/subnetworks/global/networks/default"
database_version = "POSTGRES_14"
tier             = "db-custom-2-4096"
machine_type     = "e2-micro"

user_labels = {
  tla                       = "dbs"
  ci                        = "dbs"
  environment               = "it"
  portfolio_manager         = "chris_newman"
  new_cost_center           = "0000000"
  pending_deletion          = "none"
  resource_last_update_date = "auto_update"
  opt_in_handler            = "none"
  opt_out_handler           = "none"
  resource_location         = "us_central1"
  workload_type             = "none"
}


database_flags = [
  {
    name  = "cloudsql.enable_pglogical"
    value = "on"
  },
  {
    name  = "cloudsql.logical_decoding"
    value = "on"
  },
  {
    name  = "max_replication_slots"
    value = "10"
  },
  {
    name  = "max_worker_processes"
    value = "8"
  },
  {
    name  = "max_wal_senders"
    value = "10"
  },
  {
    name  = "track_commit_timestamp"
    value = "on"
  },
  {
    name  = "pglogical.conflict_resolution"
    value = "apply_remote"
  }
]



tla         = "dbl"
cost_center = "0000000"
# identifier = "02"
read_replica_name_suffix = "1"
additional_database      = true
add_database_name        = "additional-database"
add_database_charset     = "UTF8"
add_database_collation   = "en_US.UTF8"


read_replicas = [
  {
    name              = "test-replicas"
    zone              = "us-central1-a"
    availability_type = "ZONAL"
    tier              = "db-custom-2-7680"
    ip_configuration = {
      ipv4_enabled        = true
      require_ssl         = true
      private_network     = null
      allocated_ip_range  = null
      authorized_networks = []
    }
    disk_autoresize       = null
    database_flags        = []
    disk_autoresize_limit = null
    disk_size             = null
    disk_type             = "PD_HDD"
    user_labels = {
      tla = "dbl"
    }
    encryption_key_name = null
  }
]
