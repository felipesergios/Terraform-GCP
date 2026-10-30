
output "mysql_instance_name" {
  description = "Nome da instância Cloud SQL."
  value       = google_sql_database_instance.instance.name
}

output "mysql_connection_name" {
  description = "Connection Name para Cloud SQL Auth Proxy."
  value       = google_sql_database_instance.instance.connection_name
}

output "mysql_region" {
  description = "Região da instância."
  value       = google_sql_database_instance.instance.region
}

output "mysql_database_version" {
  description = "Versão do MySQL."
  value       = google_sql_database_instance.instance.database_version
}

output "mysql_tier" {
  description = "Tier da instância."
  value       = google_sql_database_instance.instance.settings[0].tier
}

output "mysql_private_ip" {
  description = "Endereço IP privado atribuído à instância."
  value = [
    for ip in google_sql_database_instance.instance.ip_address :
    ip.ip_address if ip.type == "PRIVATE"
  ]
}

output "mysql_public_ip" {
  description = "Endereço IP público, caso exista."
  value = [
    for ip in google_sql_database_instance.instance.ip_address :
    ip.ip_address if ip.type == "PRIMARY"
  ]
}

output "mysql_database_name" {
  description = "Banco de dados criado."
  value       = google_sql_database.database.name
}

output "mysql_user" {
  description = "Usuário MySQL criado."
  value       = google_sql_user.mysql_root.name
}
