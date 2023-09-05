resource "google_compute_instance" "sql_proxy_gce_instance" {
  project      = local.project_id
  name         = "sql-proxy-${local.instance_name}"
  machine_type = var.machine_type
  zone         = var.zone

  allow_stopping_for_update = true
  labels                    = var.user_labels

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    subnetwork = var.proxy_subnet
    # network = "default"
  }

  metadata = {
    "google-logging-enabled"    = "true"
    "gce-container-declaration" = "spec:\n containers:\n  - name: sql-proxy\n   image: 'gcr.io/cloudsql-docker/gce-proxy:latest'\n   command:\n  - /cloud_sql_proxy\n  args:\n    - >-\n   -instances=${var.connection_name}=tcp:0.0.0.0:${var.proxy_port}\n  securityContext:\n  privileged: true\n   stdin: true\n  tty:  true\n  restartPolicy: Always"
    "metadata_startup_script"   = "echo '{\"live-restore\": true, \"log-opts\":{\"max-size\": \"1kb\", \"max-file\": \"5\" }, \"storage-driver\": \"overlay2\", \"mtu\": 1460}' | sudo jq . | sudo tee /etc/docker/daemon.json >/dev/null; sudo systemctl restart docker"
  }

  service_account {
    email = google_service_account.proxy_sa_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/sqlservice.admin",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  depends_on = [
    google_service_account.proxy_sa_service_account,
  ]
}


resource "google_service_account" "proxy_sa_service_account" {
  account_id   = "proxy-${var.sql_instance_name}"
  display_name = "Proxy SA for ${var.sql_instance_name} PostgreSQL instance"
  description  = "Service account used for proxy GCE instance"
  project      = local.project_id
}

resource "google_project_iam_member" "proxy_sa_sql_client_role" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.proxy_sa_service_account.email}"
}

