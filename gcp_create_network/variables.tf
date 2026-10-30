variable "project_id" {
  description = "ID do projeto GCP onde a infraestrutura será criada."
  type        = string
}

variable "region" {
  description = "Região GCP onde as subnets e o Cloud NAT serão criados."
  type        = string

  default = "southamerica-east1"
}