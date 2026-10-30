output "instance_name" {
  description = "Nome da VM."

  value = google_compute_instance.vm.name
}


output "zone" {
  description = "Zona da VM."

  value = google_compute_instance.vm.zone
}


output "private_ip" {
  description = "IP privado da VM."

  value = google_compute_instance.vm.network_interface[0].network_ip
}


output "public_ip" {
  description = "IP público da VM."

  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}


output "ssh_command" {
  description = "Comando SSH para acessar a VM."

  value = "ssh felipe@${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}