
#!/usr/bin/env bash

# ============================================================
# Terraform GCP - Deploy Orchestrator
# Autor: Felipe
#
# Executa init, validate, plan e apply nos projetos selecionados.
# Em caso de erro, interrompe imediatamente o deploy.
# ============================================================

set -Eeuo pipefail

# Diretório raiz onde está localizado este script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configurações
AUTO_APPROVE=true
PLAN_FILE="deploy.tfplan"

# ============================================================
# PROJETOS TERRAFORM
#
# enabled=true  -> projeto será implantado
# enabled=false -> projeto será ignorado
#
# Para adicionar novos projetos futuramente, basta incluí-los.
# ============================================================

declare -A PROJECTS=(
    [gcp_create_network]=true
    [gcp_create_database]=true
    [gcp_create_cloudrun_app]=true

    [gcp_create_instance]=false
    [gcp_create_deploy_static]=false
)

# Ordem de execução dos projetos
PROJECT_ORDER=(
    gcp_create_network
    gcp_create_database
    gcp_create_instance
    gcp_create_cloudrun_app
    gcp_create_deploy_static
)

# ============================================================
# FUNÇÕES
# ============================================================

log() {
    echo
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo
    echo "[ERRO] $1" >&2
    exit 1
}

check_dependencies() {

    log "Verificando dependências..."

    command -v terraform >/dev/null 2>&1 \
        || error "Terraform não encontrado no PATH."

    log "Terraform encontrado: $(terraform version | head -n 1)"
}

check_project() {

    local project="$1"
    local project_dir="${ROOT_DIR}/${project}"

    log "Verificando projeto: ${project}"

    [[ -d "$project_dir" ]] \
        || error "Diretório não encontrado: ${project_dir}"

    [[ -f "${project_dir}/terraform.tfvars" ]] \
        || error "Arquivo terraform.tfvars não encontrado em ${project}"

    [[ -n "$(find "$project_dir" -maxdepth 1 -name '*.tf' -print -quit)" ]] \
        || error "Nenhum arquivo .tf encontrado em ${project}"

    log "Estrutura do projeto validada."
}

deploy_project() {

    local project="$1"
    local project_dir="${ROOT_DIR}/${project}"

    log "============================================================"
    log "INICIANDO DEPLOY: ${project}"
    log "============================================================"

    cd "$project_dir"

    # 1. Terraform Init
    log "[1/4] Executando terraform init..."

    terraform init -input=false -no-color \
        || error "Falha no terraform init: ${project}"

    # 2. Terraform Validate
    log "[2/4] Executando terraform validate..."

    terraform validate -no-color \
        || error "Falha no terraform validate: ${project}"

    # 3. Terraform Plan
    log "[3/4] Executando terraform plan..."

    terraform plan \
        -input=false \
        -no-color \
        -out="$PLAN_FILE" \
        || error "Falha no terraform plan: ${project}"

    # 4. Terraform Apply
    log "[4/4] Executando terraform apply..."

    if [[ "$AUTO_APPROVE" == true ]]; then

        terraform apply \
            -input=false \
            -no-color \
            "$PLAN_FILE" \
            || error "Falha no terraform apply: ${project}"

    else

        terraform apply "$PLAN_FILE" \
            || error "Falha no terraform apply: ${project}"

    fi

    log "DEPLOY CONCLUÍDO: ${project}"

    # Retorna para a raiz
    cd "$ROOT_DIR"
}

# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

main() {

    clear

    log "TERRAFORM GCP - DEPLOY ORCHESTRATOR"

    check_dependencies

    log "Verificando projetos habilitados..."

    local enabled_count=0

    for project in "${PROJECT_ORDER[@]}"; do

        if [[ "${PROJECTS[$project]:-false}" == true ]]; then

            check_project "$project"

            ((enabled_count+=1))

        fi

    done

    [[ "$enabled_count" -gt 0 ]] \
        || error "Nenhum projeto habilitado para deploy."

    log "Total de projetos habilitados: ${enabled_count}"

    echo
    echo "Projetos que serão implantados:"

    for project in "${PROJECT_ORDER[@]}"; do

        if [[ "${PROJECTS[$project]:-false}" == true ]]; then
            echo "  -> ${project}"
        fi

    done

    echo
    read -r -p "Deseja iniciar o deploy? (s/N): " confirmation

    [[ "$confirmation" =~ ^[sS]$ ]] \
        || error "Deploy cancelado pelo usuário."

    # Executa os projetos na ordem definida
    for project in "${PROJECT_ORDER[@]}"; do

        if [[ "${PROJECTS[$project]:-false}" == true ]]; then
            deploy_project "$project"
        fi

    done

    log "============================================================"
    log "TODOS OS DEPLOYS FORAM CONCLUÍDOS COM SUCESSO!"
    log "============================================================"

    cd "$ROOT_DIR"
}

main "$@"
