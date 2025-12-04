#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

###############################################################################
# ИНИЦИАЛИЗАЦИЯ
###############################################################################

log_info "=========================================="
log_info "Kubernetes RBAC: RoleBindings Creation"
log_info "=========================================="

###############################################################################
# ФУНКЦИЯ: Создание ClusterRoleBinding
###############################################################################

create_cluster_role_binding() {
    local USERNAME=$1
    local CLUSTER_ROLE=$2
    local NAMESPACE=$3

    # КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: apiGroup должен быть пустой для ServiceAccount!
    kubectl create clusterrolebinding "${USERNAME}-${CLUSTER_ROLE}" \
        --clusterrole="$CLUSTER_ROLE" \
        --serviceaccount="${NAMESPACE}:${USERNAME}" \
        --dry-run=client -o yaml 2>/dev/null | \
        # Исправляем apiGroup в YAML
        sed 's/apiGroup: rbac.authorization.k8s.io/apiGroup: ""/' | \
        kubectl apply -f - > /dev/null 2>&1

    log_info "  ✓ ClusterRoleBinding: $USERNAME → $CLUSTER_ROLE"
}

###############################################################################
# ФУНКЦИЯ: Создание RoleBinding
###############################################################################

create_role_binding() {
    local USERNAME=$1
    local ROLE=$2
    local NAMESPACE=$3

    kubectl create rolebinding "${USERNAME}-${ROLE}" \
        --role="$ROLE" \
        --serviceaccount="${NAMESPACE}:${USERNAME}" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml 2>/dev/null | \
        # Исправляем apiGroup в YAML
        sed 's/apiGroup: rbac.authorization.k8s.io/apiGroup: ""/' | \
        kubectl apply -f - > /dev/null 2>&1

    log_info "    ✓ RoleBinding: $USERNAME → $ROLE (namespace: $NAMESPACE)"
}

###############################################################################
# 1. CLUSTERROLEBINDINGS
###############################################################################

log_section "1. Создание ClusterRoleBindings"

# Security specialist → cluster-admin
create_cluster_role_binding "security-specialist" "cluster-admin" "kube-system"

# Ops managers → cluster-viewer
create_cluster_role_binding "ops-manager-1" "cluster-viewer" "kube-system"
create_cluster_role_binding "ops-manager-2" "cluster-viewer" "kube-system"

###############################################################################
# 2. ROLEBINDINGS (Sales)
###############################################################################

log_section "2. Создание RoleBindings: Sales"

# Sales lead → domain-admin
create_role_binding "sales-lead" "domain-admin" "sales"

# Sales devops → domain-admin
create_role_binding "sales-devops" "domain-admin" "sales"

# Sales developers → domain-developer
create_role_binding "sales-dev-1" "domain-developer" "sales"
create_role_binding "sales-dev-2" "domain-developer" "sales"

# Sales QA → domain-viewer
create_role_binding "sales-qa" "domain-viewer" "sales"

###############################################################################
# 3. ROLEBINDINGS (Tenant)
###############################################################################

log_section "3. Создание RoleBindings: Tenant"

# Tenant lead → domain-admin
create_role_binding "tenant-lead" "domain-admin" "tenant"

# Tenant devops → domain-admin
create_role_binding "tenant-devops" "domain-admin" "tenant"

# Tenant developers → domain-developer
create_role_binding "tenant-dev-1" "domain-developer" "tenant"

# Tenant QA → domain-viewer
create_role_binding "tenant-qa" "domain-viewer" "tenant"

###############################################################################
# 4. ROLEBINDINGS (Finance)
###############################################################################

log_section "4. Создание RoleBindings: Finance"

# Finance lead → domain-admin
create_role_binding "finance-lead" "domain-admin" "finance"

# Finance devops → domain-admin
create_role_binding "finance-devops" "domain-admin" "finance"

# Finance developers → domain-developer
create_role_binding "finance-dev-1" "domain-developer" "finance"

# Finance QA → domain-viewer
create_role_binding "finance-qa" "domain-viewer" "finance"

###############################################################################
# 5. ROLEBINDINGS (Data)
###############################################################################

log_section "5. Создание RoleBindings: Data"

# Data lead → domain-admin
create_role_binding "data-lead" "domain-admin" "data"

# Data devops → domain-admin
create_role_binding "data-devops" "domain-admin" "data"

# Data developers → domain-developer
create_role_binding "data-dev-1" "domain-developer" "data"

# Data QA → domain-viewer
create_role_binding "data-qa" "domain-viewer" "data"

###############################################################################
# ФИНАЛЬНЫЙ ОТЧЁТ
###############################################################################

log_info "=========================================="
log_info "Создание RoleBindings завершено!"
log_info "=========================================="

# Проверяем что всё создалось
log_info "Проверка ClusterRoleBindings:"
CRBS=$(kubectl get clusterrolebinding --no-headers 2>/dev/null | grep -E "(security-specialist|ops-manager)" | wc -l)
log_info "  Создано: $CRBS ClusterRoleBindings"

log_info "Проверка RoleBindings по namespace:"
for ns in sales tenant finance data; do
    count=$(kubectl get rolebinding -n "$ns" --no-headers 2>/dev/null | wc -l)
    log_info "  $ns: $count RoleBindings"
done

log_info ""
log_info "✅ Все RoleBindings созданы успешно!"

exit 0
