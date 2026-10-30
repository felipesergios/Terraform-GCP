data "google_compute_network" "existing" {
  name = var.network_name
}

data "google_compute_subnetwork" "infra" {
  name   = var.subnetwork_name
  region = var.region
}

resource "google_project_service" "cloud_run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloud_run_v2_service" "nginx" {
  project  = var.project_id
  name     = "nginx-test"
  location = var.region

  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    timeout = "60s"

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = data.google_compute_network.existing.id
        subnetwork = data.google_compute_subnetwork.infra.id
        tags       = ["cloud-run-nginx"]
      }
    }

    containers {
      image = "nginx:alpine"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      command = ["/bin/sh", "-c"]

      args = [
        "sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
      ]
    }
  }

  depends_on = [google_project_service.cloud_run]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.nginx.location
  name     = google_cloud_run_v2_service.nginx.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

output "nginx_url" {
  value = google_cloud_run_v2_service.nginx.uri
}
