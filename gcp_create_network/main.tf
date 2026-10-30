# ============================================================
# VPC
# ============================================================
#
# Equivalente aproximado à VCN da OCI.
#
# No GCP a VPC é global e não possui CIDR diretamente.
# O CIDR é definido nas subnets.
#
# Portanto, diferente da OCI, não colocamos:
#
# cidr = "172.16.0.0/16"
#
# na VPC.
#
resource "google_compute_network" "gcp_mycloud_network" {

  # Nome da VPC
  name = "gcp-mycloud-network"

  # VPC customizada.
  #
  # Com "NONE", nós mesmos definimos as subnets,
  # ao invés de o GCP criar subnets automaticamente.
  auto_create_subnetworks = false

  # Permite que o Terraform gerencie rotas customizadas
  # associadas à VPC.
  routing_mode = "REGIONAL"
}


# ============================================================
# SUBNET - INFRA
# ============================================================
#
# Equivalente à primeira subnet da VCN.
#
# OCI:
#   infra
#   172.16.10.0/24
#
# GCP:
#   Subnetwork regional
#
resource "google_compute_subnetwork" "infra" {

  name = "infra"

  # Região onde essa subnet existirá.
  region = var.region

  # CIDR da subnet.
  ip_cidr_range = "172.16.10.0/24"

  # VPC à qual a subnet pertence.
  network = google_compute_network.gcp_mycloud_network.id

  # Mantemos o acesso privado aos recursos do Google
  # disponível para recursos dessa subnet.
  private_ip_google_access = true
}


# ============================================================
# SUBNET - PROD
# ============================================================
#
# Segunda subnet da VPC.
#
# OCI:
#   prod
#   172.16.20.0/24
#
# GCP:
#   Subnetwork regional
#
resource "google_compute_subnetwork" "prod" {

  name = "prod"

  region = var.region

  ip_cidr_range = "172.16.20.0/24"

  network = google_compute_network.gcp_mycloud_network.id

  private_ip_google_access = true
}


# ============================================================
# CLOUD ROUTER
# ============================================================
#
# O Cloud Router é necessário para o Cloud NAT.
#
# Ele não é exatamente equivalente a um "DRG" da OCI.
# Seu papel aqui é fornecer o componente de roteamento
# necessário para o Cloud NAT.
#
resource "google_compute_router" "gcp_mycloud_router" {

  name = "gcp-mycloud-router"

  region = var.region

  network = google_compute_network.gcp_mycloud_network.id

  bgp {
    # ASN privado utilizado pelo Cloud Router.
    asn = 64514
  }
}


# ============================================================
# CLOUD NAT
# ============================================================
#
# Equivalente funcional ao NAT Gateway da OCI.
#
# Permite que máquinas com IP privado saiam para a Internet
# sem precisarem possuir um IP público.
#
# Exemplo:
#
# VM privada
# 172.16.10.x
#       |
#       v
#   Cloud NAT
#       |
#       v
#    Internet
#
resource "google_compute_router_nat" "gcp_mycloud_nat" {

  name = "gcp-mycloud-nat"

  router = google_compute_router.gcp_mycloud_router.name

  region = var.region

  # NAT somente para IPs das subnets configuradas
  # neste projeto.
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.infra.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.prod.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}