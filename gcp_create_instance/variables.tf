variable "project_id" {
  description = "ID do projeto GCP onde a VM será criada."
  type        = string
}

variable "region" {
  description = "Região onde a VM será criada."

  type = string

  default = "southamerica-east1"
}

variable "zone" {
  description = "Zona onde a VM será criada."

  type = string

  default = "southamerica-east1-a"
}

# ============================================================
# REDE EXISTENTE
# ============================================================

variable "network_name" {
  description = "Nome da VPC existente."

  type = string

  default = "gcp-mycloud-network"
}


variable "subnet_name" {
  description = "Nome da subnet existente."

  type = string

  default = "infra"
}

# ============================================================

variable "instance_name" {
  description = "Nome da máquina virtual."

  type = string

  default = "gcp-mycloud-vm"
}

variable "ssh_user" {
  description = "Usuário SSH da VM"
  type        = string
  default     = "felipe"
}

variable "ssh_public_key_path" {
  description = "Caminho da chave pública SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_ip_sysadmin"{
    description = "Ip Publico do sysadmin"
    type    = string
}