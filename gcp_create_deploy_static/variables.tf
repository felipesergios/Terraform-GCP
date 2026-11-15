variable "project_id" {
  description = "ID do projeto Google Cloud."
  type        = string
  default     = "felipeufrn"
}

variable "region" {
  description = "Região do bucket do Cloud Storage."
  type        = string
  default     = "southamerica-east1"
}

variable "bucket_name" {
  description = "Nome globalmente único do bucket."
  type        = string
}

variable "force_destroy" {
  description = "Permite apagar o bucket mesmo contendo objetos. Mantenha false para evitar exclusão acidental."
  type        = bool
  default     = false
}
