output "instance_name" {
  value       = google_sql_database_instance.postgres_db_instance.name
  description = "The instance name for the master instance"
}
