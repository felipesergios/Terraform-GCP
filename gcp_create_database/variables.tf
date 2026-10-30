variable "project_id" {
  description = "ID do projeto GCP onde a infraestrutura será criada."
  type        = string
}

variable "region" {
  description = "Região GCP onde as subnets e o Cloud NAT serão criados."
  type        = string
  default = "southamerica-east1"
}

variable "dba_ip" {
  description = "IP público autorizado a acessar o Cloud SQL (CIDR /32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.dba_ip, 0)) && can(regex("/32$", var.dba_ip))
    error_message = "Informe um endereço IPv4 válido com máscara /32. Exemplo: 200.100.50.10/32."
  }
}

variable "secret_name"{
  description = "Informe o nome do segredo"
  type        = string
  default     = "mysql-sandbox-root"
}