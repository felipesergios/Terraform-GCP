
#!/usr/bin/env bash

# ============================================================
# GCP Static Website - Terraform + Cloud Storage
# Provisiona a infraestrutura e publica o site estático.
# ============================================================

set -Eeuo pipefail

# Diretório onde está localizado este script.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="${PROJECT_DIR}/site"
TFVARS_FILE="${PROJECT_DIR}/terraform.tfvars"

cd "$PROJECT_DIR"

# ------------------------------------------------------------
# Funções auxiliares
# ------------------------------------------------------------

log() {
    echo -e "\n[INFO] $1"
}

error() {
    echo -e "\n[ERROR] $1" >&2
    exit 1
}

# ------------------------------------------------------------
# Verificação de dependências
# ------------------------------------------------------------

log "Verificando dependências..."

for cmd in terraform gcloud; do
    command -v "$cmd" >/dev/null 2>&1 || error "$cmd não está instalado."
done

[[ -d "$SITE_DIR" ]] || error "Diretório site/ não encontrado."
[[ -f "${SITE_DIR}/index.html" ]] || error "Arquivo site/index.html não encontrado."
[[ -f "$TFVARS_FILE" ]] || error "Arquivo terraform.tfvars não encontrado. Copie terraform.tfvars.example e configure as variáveis."

# ------------------------------------------------------------
# Verificação de autenticação GCP
# ------------------------------------------------------------

log "Verificando autenticação Google Cloud..."

gcloud auth print-access-token >/dev/null 2>&1 || error "Não autenticado no Google Cloud. Execute: gcloud auth login"

# ------------------------------------------------------------
# Terraform Init
# ------------------------------------------------------------

log "Inicializando Terraform..."

terraform init -input=false

# ------------------------------------------------------------
# Terraform Validate
# ------------------------------------------------------------

log "Validando configuração Terraform..."

terraform fmt -check -recursive
terraform validate

# ------------------------------------------------------------
# Terraform Plan
# ------------------------------------------------------------

log "Gerando plano de execução..."

terraform plan -input=false -var-file="$TFVARS_FILE" -out=tfplan

# ------------------------------------------------------------
# Terraform Apply
# ------------------------------------------------------------

log "Aplicando infraestrutura..."

terraform apply -input=false tfplan

rm -f tfplan

# ------------------------------------------------------------
# Obtendo nome do bucket
# ------------------------------------------------------------

log "Obtendo informações do bucket..."

BUCKET_NAME="$(terraform output -raw bucket_name 2>/dev/null)" \
    || error "Output bucket_name não encontrado no Terraform."

[[ -n "$BUCKET_NAME" ]] || error "O nome do bucket está vazio."

# ------------------------------------------------------------
# Deploy dos arquivos estáticos
# ------------------------------------------------------------

log "Publicando arquivos no Cloud Storage..."

gcloud storage rsync \
    --recursive \
    --delete-unmatched-destination-objects \
    "$SITE_DIR" \
    "gs://${BUCKET_NAME}"

# ------------------------------------------------------------
# Resultado
# ------------------------------------------------------------

WEBSITE_URL="$(terraform output -raw website_url 2>/dev/null || true)"

echo
echo "============================================================"
echo " DEPLOY CONCLUÍDO COM SUCESSO"
echo "============================================================"
echo " Bucket : ${BUCKET_NAME}"
echo " Site   : ${WEBSITE_URL}"
echo "============================================================"
