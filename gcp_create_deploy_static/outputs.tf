output "bucket_name" {
  description = "Nome do bucket usado para publicar os arquivos."
  value       = google_storage_bucket.website.name
}

output "website_url" {
  description = "Endpoint HTTP de website do Cloud Storage."
  value       = "http://${google_storage_bucket.website.name}.storage.googleapis.com"
}

output "upload_command" {
  description = "Comando para enviar o conteúdo da pasta site/."
  value       = "gcloud storage rsync --recursive ./site gs://${google_storage_bucket.website.name}"
}
