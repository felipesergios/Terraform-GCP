locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
# Get VPC created before
data "google_compute_network" "mycloud_network" {
  name = var.network_name
}
# Get Subnet
data "google_compute_subnetwork" "infra" {
  name   = var.subnet_name
  region = var.region
}
# Firewall SSH - Open port to sysadmin only 
resource "google_compute_firewall" "allow_ssh" {

  name = "allow-ssh"

  network = data.google_compute_network.mycloud_network.id

  direction = "INGRESS"

  priority = 1000

  #source_ranges = ["0.0.0.0/0"]
  source_ranges = ["${var.ssh_ip_sysadmin}/32"]

  # A regra será aplicada somente à VM que possuir
  # a tag "ssh".
  target_tags = ["ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  description = "Permite acesso SSH à instancia."
}

resource "google_compute_instance" "vm" {

  name = var.instance_name

  zone = var.zone

  machine_type = "e2-micro"

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-13"

      # Disk in GiB
      size = 10

      type = "pd-standard"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.infra.id
    access_config {}
  }
  tags = ["ssh"]

  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }
}