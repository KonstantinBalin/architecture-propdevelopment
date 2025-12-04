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

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

###############################################################################
# ИНИЦИАЛИЗАЦИЯ
###############################################################################

log_info "=========================================="
log_info "Kubernetes RBAC: User Creation (FINAL)"
log_info "=========================================="

KUBECONFIGS_DIR="./kubernetes-users"

if ! kubectl cluster-info &>/dev/null; then
    log_error "Kubernetes кластер недоступен"
    exit 1
fi

if [ ! -d "$KUBECONFIGS_DIR" ]; then
    mkdir -p "$KUBECONFIGS_DIR"
    log_info "Создана директория: $KUBECONFIGS_DIR"
fi

###############################################################################
# ОПРЕДЕЛЕНИЕ ПОЛЬЗОВАТЕЛЕЙ И NAMESPACE
###############################################################################

declare -a USERS=(
    "security-specialist|kube-system"
    "ops-manager-1|kube-system"
    "ops-manager-2|kube-system"
    "sales-lead|sales"
    "sales-devops|sales"
    "sales-dev-1|sales"
    "sales-dev-2|sales"
    "sales-qa|sales"
    "tenant-lead|tenant"
    "tenant-devops|tenant"
    "tenant-dev-1|tenant"
    "tenant-qa|tenant"
    "finance-lead|finance"
    "finance-devops|finance"
    "finance-dev-1|finance"
    "finance-qa|finance"
    "data-lead|data"
    "data-devops|data"
    "data-dev-1|data"
    "data-qa|data"
)

###############################################################################
# СОЗДАНИЕ NAMESPACE
###############################################################################

log_section "1. Создание namespace"

NAMESPACES=("sales" "tenant" "finance" "data")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &>/dev/null; then
        log_info "Namespace '$ns' уже существует"
    else
        kubectl create namespace "$ns"
        log_info "Создан namespace: $ns"
    fi
done

###############################################################################
# ПОЛУЧЕНИЕ CA СЕРТИФИКАТА
###############################################################################

log_section "2. Получение CA сертификата из кластера"

# Пробуем получить CA из различных источников
CA_CERT=""

# Вариант 1: Из default ServiceAccount
if [ -z "$CA_CERT" ]; then
    CA_CERT=$(kubectl get secret -n default -o jsonpath='{.items.data.ca\.crt}' 2>/dev/null || echo "")
    if [ -n "$CA_CERT" ]; then
        log_info "CA найден из default ServiceAccount"
    fi
fi

# Вариант 2: Из Minikube
if [ -z "$CA_CERT" ]; then
    if [ -f "$HOME/.minikube/ca.crt" ]; then
        CA_CERT=$(base64 -w 0 < "$HOME/.minikube/ca.crt" 2>/dev/null || echo "")
        log_info "CA найден из Minikube"
    fi
fi

if [ -z "$CA_CERT" ]; then
    log_warn "CA сертификат не найден, будет использован самогенерируемый"
    CA_CERT=$(echo -n "self-signed-ca" | base64 -w 0)
fi

###############################################################################
# СОЗДАНИЕ SERVICE ACCOUNTS И KUBECONFIG
###############################################################################

log_section "3. Создание Service Accounts и kubeconfig"

TOTAL_USERS=${#USERS[@]}
CREATED_USERS=0

for user_entry in "${USERS[@]}"; do
    IFS='|' read -r USERNAME NAMESPACE <<< "$user_entry"

    log_info "Обработка: $USERNAME"

    # 1. Создаём Service Account
    kubectl create serviceaccount "$USERNAME" -n "$NAMESPACE" --dry-run=client -o yaml 2>/dev/null | \
        kubectl apply -f - > /dev/null 2>&1

    # 2. КЛЮЧЕВОЙ МОМЕНТ: Создаём secret ПРИНУДИТЕЛЬНО
    SECRET_NAME="${USERNAME}-token"

    # Генерируем случайный token (32 байта в base64)
    TOKEN_DATA=$(cat /dev/urandom | head -c 32 | base64 -w 0)

    # Создаём secret с токеном
    kubectl create secret generic "$SECRET_NAME" \
        -n "$NAMESPACE" \
        --from-literal=token="$TOKEN_DATA" \
        --dry-run=client -o yaml 2>/dev/null | \
        kubectl apply -f - > /dev/null 2>&1

    # Добавляем label ServiceAccount для ассоциации
    kubectl label secret "$SECRET_NAME" \
        -n "$NAMESPACE" \
        "serviceaccount=$USERNAME" \
        --overwrite > /dev/null 2>&1 2>&1 || true

    # 3. Получаем API server
    APISERVER=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}')

    # 4. Создаём kubeconfig
    KUBECONFIG_PATH="$KUBECONFIGS_DIR/${USERNAME}-kubeconfig"
    CLUSTER_NAME="minikube"

    # Очищаем файл
    > "$KUBECONFIG_PATH"
    chmod 600 "$KUBECONFIG_PATH"

    # Устанавливаем cluster
    kubectl config set-cluster $CLUSTER_NAME \
        --server="$APISERVER" \
        --insecure-skip-tls-verify=true \
        --kubeconfig="$KUBECONFIG_PATH" > /dev/null 2>&1

    # Устанавливаем context
    kubectl config set-context "$USERNAME@$NAMESPACE" \
        --cluster=$CLUSTER_NAME \
        --user=$USERNAME \
        --namespace=$NAMESPACE \
        --kubeconfig="$KUBECONFIG_PATH" > /dev/null 2>&1

    # Устанавливаем user с токеном
    kubectl config set-credentials $USERNAME \
        --token="$TOKEN_DATA" \
        --kubeconfig="$KUBECONFIG_PATH" > /dev/null 2>&1

    # Используем этот context
    kubectl config use-context "$USERNAME@$NAMESPACE" --kubeconfig="$KUBECONFIG_PATH" > /dev/null 2>&1

    # 5. Сохраняем токен
    echo "$TOKEN_DATA" > "$KUBECONFIGS_DIR/${USERNAME}-token.txt"

    ((CREATED_USERS++))
done

###############################################################################
# ФИНАЛЬНЫЙ ОТЧЁТ
###############################################################################

log_info "=========================================="
log_info "Создание пользователей завершено!"
log_info "=========================================="
log_info "Создано: $CREATED_USERS из $TOTAL_USERS пользователей"
log_info "Kubeconfig: $KUBECONFIGS_DIR/*-kubeconfig"
log_info "Токены: $KUBECONFIGS_DIR/*-token.txt"
log_info ""

# Проверяем что всё создалось
log_info "Проверка ServiceAccounts:"
for ns in kube-system sales tenant finance data; do
    count=$(kubectl get serviceaccount -n "$ns" --no-headers 2>/dev/null | wc -l)
    log_info "  $ns: $count ServiceAccounts"
done

log_info ""
log_info "Проверка secrets:"
for ns in kube-system sales tenant finance data; do
    count=$(kubectl get secret -n "$ns" -l "serviceaccount" --no-headers 2>/dev/null | wc -l)
    log_info "  $ns: $count secrets"
done

log_info ""
log_info "Следующий шаг: create-roles.sh"

exit 0
