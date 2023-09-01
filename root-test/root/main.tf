module "cloudsql_postgres_sync_test" {
  source     = "../../child/master"
  project_id = var.project_id
  region     = var.region
    # network            = var.network
  zone             = var.zones[0]
  database_version = var.database_version
  #   proxy_subnet     = var.subnet_link
  tier                               = var.tier
  identifier                         = "03"
  additional_access_service_accounts = ["sa-proj-default@${var.project_id}.iam.gserviceaccount.com"]
  user_labels                        = var.user_labels
  database_flags                     = var.database_flags

  ip_configuration = {
    "authorized_networks" : []
    "ipv4_enabled" : true,
    "private_network" : null #var.network,
    "require_ssl" : var.require_ssl
    "allocated_ip_range" : null
  }
  #   read_replicas            = var.read_replicas
  #   read_replica_name_suffix = var.read_replica_name_suffix
  additional_database    = var.additional_database
  add_database_name      = var.add_database_name
  add_database_charset   = var.add_database_charset
  add_database_collation = var.add_database_collation
}


module "cloudsql_postgres_rr_test" {
  source                   = "../../child/readreplica"
  project_id               = var.project_id
  region                   = var.region
  zone                     = var.zones[0]
  database_version         = var.database_version
  master_instance_name     = module.cloudsql_postgres_sync_test.instance_name
  tier                     = var.tier
  read_replicas            = var.read_replicas
  read_replica_name_suffix = var.read_replica_name_suffix
}
