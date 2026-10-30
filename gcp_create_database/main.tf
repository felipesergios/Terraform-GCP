
# Consulta a senha diretamente no Google Secret Manager
data "google_secret_manager_secret_version" "mysql_root" {
  secret  = var.secret_name
  project = var.project_id
  version = "latest"
}

# Consulta a VPC existente
data "google_compute_network" "infra" {
  name = "gcp-mycloud-network"
}

# Instância Cloud SQL
resource "google_sql_database_instance" "instance" {
  name             = "my-database-instance"
  region           = var.region
  database_version = "MYSQL_8_4"

  settings {
    tier              = "db-f1-micro"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"

    # Configuração de rede privada
    ip_configuration {
      ipv4_enabled    = true
      private_network = data.google_compute_network.infra.id

      # Configuração anterior de IP público
      # Mantida comentada para referência futura.
      #
      # ipv4_enabled = true
      #
      authorized_networks {
         name  = "dba-access"
         value = var.dba_ip
       }
    }
  }

  deletion_protection = false
}

# Banco de dados
resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.instance.name
}

# Usuário MySQL
resource "google_sql_user" "mysql_root" {
  name     = "root"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = data.google_secret_manager_secret_version.mysql_root.secret_data
}
