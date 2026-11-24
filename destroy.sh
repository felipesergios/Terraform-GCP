
#!/usr/bin/env bash

# ============================================================
# Terraform GCP - Destroy Orchestrator
# Autor: Felipe
#
# Destrói os recursos dos projetos Terraform selecionados.
# Em caso de erro, interrompe imediatamente.
# ============================================================

set -Eeuo pipefail

# Diretório raiz do projeto
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Arquivo de log
LOG_FILE="${ROOT_DIR}/destroy.log"

# ============================================================
# PROJETOS TERRAFORM
#
# enabled=true  -> projeto será destruído
# enabled=false -> projeto será ignorado
# ============================================================

declare -A PROJECTS=(
    [gcp_create_network]=true
    [gcp_create_database]=true
    [gcp_create_cloudrun_app]=true

    [gcp_create_instance]=false
    [gcp_create_deploy_static]=false
)

# ============================================================
# ORDEM DE DESTRUIÇÃO
#
# Sempre destruir primeiro os recursos dependentes.
# ============================================================

PROJECT_ORDER=(
    gcp_create_deploy_static
    gcp_create_cloudrun_app
    gcp_create_instance
    gcp_create_database
    gcp_create_network
)

# ============================================================
# FUNÇÕES
# ============================================================

log() {
    echo
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "[ERRO] $1"
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

    [[ -f "${project_dir}/terraform.tfstate" ]] \
        || [[ -d "${project_dir}/.terraform" ]] \
        || error "Estado Terraform ou diretório de inicialização não encontrado em ${project}"

    [[ -n "$(find "$project_dir" -maxdepth 1 -name '*.tf' -print -quit)" ]] \
        || error "Nenhum arquivo .tf encontrado em ${project}"

    log "Estrutura do projeto validada."
}

destroy_project() {

    local project="$1"
    local project_dir="${ROOT_DIR}/${project}"

    log "============================================================"
    log "INICIANDO DESTROY: ${project}"
    log "============================================================"

    cd "$project_dir"

    # 1. Terraform Init
    log "[1/3] Executando terraform init..."

    terraform init -input=false -no-color \
        || error "Falha no terraform init: ${project}"

    # 2. Terraform Validate
    log "[2/3] Executando terraform validate..."

    terraform validate -no-color \
        || error "Falha no terraform validate: ${project}"

    # 3. Terraform Plan Destroy
    log "[3/3] Executando terraform plan -destroy..."

    terraform plan \
        -destroy \
        -input=false \
        -no-color \
        -out=destroy.tfplan \
        || error "Falha no terraform plan -destroy: ${project}"

    # Confirmação individual antes de destruir
    echo
    echo "ATENÇÃO: Os recursos do projeto ${project} serão destruídos."
    read -r -p "Confirma a destruição deste projeto? (s/N): " confirmation

    [[ "$confirmation" =~ ^[sS]$ ]] \
        || error "Destroy cancelado pelo usuário em ${project}."

    # 4. Terraform Apply Destroy
    log "Executando terraform apply do plano de destruição..."

    terraform apply \
        -input=false \
        -no-color \
        destroy.tfplan \
        || error "Falha no terraform destroy: ${project}"

    log "DESTROY CONCLUÍDO: ${project}"

    cd "$ROOT_DIR"
}

# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

main() {

    log "TERRAFORM GCP - DESTROY ORCHESTRATOR"

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
        || error "Nenhum projeto habilitado para destruição."

    log "Total de projetos habilitados: ${enabled_count}"

    echo
    echo "Projetos que serão destruídos:"

    for project in "${PROJECT_ORDER[@]}"; do

        if [[ "${PROJECTS[$project]:-false}" == true ]]; then
            echo "  -> ${project}"
        fi

    done

    echo
    echo "============================================================"
    echo "ATENÇÃO: ESTA OPERAÇÃO É DESTRUTIVA!"
    echo "============================================================"

    read -r -p "Digite DESTROY para continuar: " confirmation

    [[ "$confirmation" == "DESTROY" ]] \
        || error "Operação cancelada pelo usuário."

    # Executa os projetos na ordem definida
    for project in "${PROJECT_ORDER[@]}"; do

        if [[ "${PROJECTS[$project]:-false}" == true ]]; then
            destroy_project "$project"
        fi

    done

    log "============================================================"
    log "TODOS OS DESTROYS FORAM CONCLUÍDOS COM SUCESSO!"
    log "============================================================"

    cd "$ROOT_DIR"
}

# ============================================================
# EXECUÇÃO
# ============================================================

main "$@" 2>&1 | tee -a "$LOG_FILE"
