#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

###############################################################################
# ИНИЦИАЛИЗАЦИЯ
###############################################################################

log_info "=========================================="
log_info "Kubernetes RBAC: Roles Creation"
log_info "=========================================="

if ! kubectl cluster-info &>/dev/null; then
    echo "Kubernetes кластер недоступен"
    exit 1
fi

###############################################################################
# СОЗДАНИЕ NAMESPACES
###############################################################################

log_section "1. Создание Namespaces"

NAMESPACES=(
    "sales" "sales-db"
    "tenant" "tenant-db"
    "finance" "finance-db"
    "data" "data-db"
)

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &>/dev/null; then
        log_info "Namespace '$ns' уже существует"
    else
        kubectl create namespace "$ns"
        log_info "✓ Создан namespace: $ns"
    fi
done

###############################################################################
# СОЗДАНИЕ CLUSTERROLES
###############################################################################

log_section "2. Создание ClusterRoles"

log_info "Создание ClusterRole: cluster-viewer"
kubectl apply -f - << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "events", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list", "watch"]
EOF
log_info "✓ ClusterRole cluster-viewer создана"

###############################################################################
# СОЗДАНИЕ ROLES В КАЖДОМ NAMESPACE
###############################################################################

log_section "3. Создание Roles в каждом namespace"

DOMAINS=("sales" "tenant" "finance" "data")

for domain in "${DOMAINS[@]}"; do
    log_info "Обработка домена: $domain"
    NS="${domain}"

    # domain-admin
    kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: domain-admin
  namespace: $NS
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/exec", "pods/attach"]
  verbs: ["create", "get", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["services", "configmaps", "secrets"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["serviceaccounts"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["replicasets"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
EOF
    log_info "  ✓ Role domain-admin создана"

    # domain-developer
    kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: domain-developer
  namespace: $NS
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["create", "get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create", "get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/exec", "pods/attach"]
  verbs: ["create", "get", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["create", "get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["create", "get", "list", "watch", "update", "patch"]
EOF
    log_info "  ✓ Role domain-developer создана"

    # domain-viewer
    kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: domain-viewer
  namespace: $NS
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
EOF
    log_info "  ✓ Role domain-viewer создана"
done

log_info "✓ Все Roles созданы успешно"

exit 0