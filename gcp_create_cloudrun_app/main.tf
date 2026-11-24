
# ============================================================
# REDE EXISTENTE
# ============================================================

data "google_compute_network" "existing" {
  name = var.network_name
}

data "google_compute_subnetwork" "infra" {
  name   = var.subnetwork_name
  region = var.region
}

# ============================================================
# ESTADO REMOTO DO CLOUD SQL
# ============================================================

data "terraform_remote_state" "database" {
  backend = "gcs"

  config = {
    bucket = "felipeufrn-terraform-state"
    prefix = "gcp_create_database"
  }
}

# ============================================================
# CONTA DE SERVIÇO DO CLOUD RUN
# ============================================================

resource "google_service_account" "nodejs" {
  project      = var.project_id
  account_id   = "nodejs-cloudrun"
  display_name = "Cloud Run - nodejs Web"
}

# ============================================================
# APIs
# ============================================================

resource "google_project_service" "cloud_run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ============================================================
# PERMISSÃO PARA ACESSAR O SEGREDO
# ============================================================

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  project   = var.project_id
  secret_id = var.secret_name

  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.nodejs.email}"
}

# ============================================================
# ZABBIX WEB
# ============================================================

resource "google_cloud_run_v2_service" "nodejs" {
  project  = var.project_id
  name     = "nodejs-web"
  location = var.region

  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.nodejs.email
    timeout         = "300s"

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = data.google_compute_network.existing.id
        subnetwork = data.google_compute_subnetwork.infra.id
        tags       = ["cloud-run-zabbix"]
      }
    }

    containers {
      image = "felipesergios/simple-api:latest"

      ports {
        container_port = 3000
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      # ------------------------------------------------------
      # CONFIGURAÇÃO DO BANCO - DADOS DO ESTADO REMOTO
      # ------------------------------------------------------
      env {
        name  = "SECRET"
        value = var.secret_app
      }
      env {
        name  = "DATABASE_HOST"
        value = tostring(data.terraform_remote_state.database.outputs.mysql_private_ip[0])
      }

      env {
        name  = "DB_SERVER_PORT"
        value = "3306"
      }

      env {
        name  = "DATABASE"
        value = data.terraform_remote_state.database.outputs.mysql_database_name
      }

      env {
        name  = "DATABASE_USER"
        value = data.terraform_remote_state.database.outputs.mysql_user
      }

      # ------------------------------------------------------
      # SENHA - SECRET MANAGER
      # O Cloud Run busca o segredo diretamente.
      # ------------------------------------------------------

      env {
        name = "DATABASE_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = var.secret_name
            version = "latest"
          }
        }
      }

    }
  }

  depends_on = [
    google_project_service.cloud_run,
    google_project_service.secret_manager,
    google_secret_manager_secret_iam_member.db_password_access
  ]
}

# ============================================================
# ACESSO PÚBLICO
# ============================================================

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.nodejs.location
  name     = google_cloud_run_v2_service.nodejs.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

# ============================================================
# OUTPUTS
# ============================================================

output "simple_api__url" {
  description = "URL pública da API em nodejs"
  value       = google_cloud_run_v2_service.nodejs.uri
}
