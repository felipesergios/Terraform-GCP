terraform {
  backend "gcs" {
    bucket = "felipeufrn-terraform-state"
    prefix = "gcp_create_cloudrun_app"
  }
}