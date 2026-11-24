variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnetwork_name" {
  type = string
}

variable "secret_app" {
  type = string
}

variable "secret_name" {
  type        = string
  description = "Nome do segredo da senha MySQL no Secret Manager"
  default = "mysql-sandbox-root"
}

variable "zabbix_server_host" {
  description = "Endereço do Zabbix Server"
  type        = string
  default     = "zabbix-server"
}

variable "timezone" {
  type    = string
  default = "America/Fortaleza"
}