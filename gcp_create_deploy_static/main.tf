# Bucket que armazenará os arquivos estáticos do site.
resource "google_storage_bucket" "website" {
  name                        = var.bucket_name
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  force_destroy               = var.force_destroy

  # Configuração de website estático do Cloud Storage.
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  versioning {
    enabled = true
  }
}

# Permite que visitantes leiam os objetos sem autenticação.
# Pode ser bloqueado por uma política de Public Access Prevention da organização.
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
