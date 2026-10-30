output "vpc_name" {
  description = "Nome da VPC criada."
  value       = google_compute_network.gcp_mycloud_network.name
}

output "vpc_id" {
  description = "ID da VPC criada."
  value       = google_compute_network.gcp_mycloud_network.id
}

output "infra_subnet" {
  description = "Nome e CIDR da subnet de infraestrutura."
  value = {
    name = google_compute_subnetwork.infra.name
    cidr = google_compute_subnetwork.infra.ip_cidr_range
  }
}

output "prod_subnet" {
  description = "Nome e CIDR da subnet de produção."
  value = {
    name = google_compute_subnetwork.prod.name
    cidr = google_compute_subnetwork.prod.ip_cidr_range
  }
}

output "cloud_nat_name" {
  description = "Nome do Cloud NAT."
  value       = google_compute_router_nat.gcp_mycloud_nat.name
}