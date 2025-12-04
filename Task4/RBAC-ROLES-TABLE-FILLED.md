# Таблица ролей Kubernetes для PropDevelopment
## Таблица ролей и их полномочия

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| **cluster-admin** | Полный доступ ко всему кластеру: просмотр и изменение всех ресурсов, управление RBAC, доступ к secrets, удаление ресурсов, управление cluster-level компонентами | Специалист по ИБ, CTO, Технический лидер |
| **cluster-viewer** | Просмотр (read-only) ко всем ресурсам во всех namespace: pods, services, deployments, configmaps (без значений), events, logs; БЕЗ доступа к secrets и управления ресурсами | Операционные менеджеры, Business Analysts, Аналитики |
| **domain-admin** | Полное управление ресурсами в namespace: создание/изменение/удаление deployments, services, configmaps, secrets, ingresses, PVC; управление подами (exec, logs); работа с service accounts в пределах namespace | Domain Leads, DevOps Engineers (по доменам: sales, tenant, finance, data) |
| **domain-developer** | Создание и изменение ресурсов в namespace (БЕЗ удаления): deployments, services, configmaps, secrets; просмотр pods, services, events; запуск debug контейнеров (pods/exec); просмотр логов | Разработчики (по доменам: sales, tenant, finance, data) |
| **domain-viewer** | Просмотр (read-only) ресурсов в namespace: pods, deployments, services, events, logs; просмотр configmaps (БЕЗ значений); БЕЗ доступа к secrets и без возможности менять ресурсы | QA Engineers, Product Managers (по доменам: sales, tenant, finance, data) |

---

## Расширенное описание ролей

### 1. cluster-admin
**Уровень:** Кластер (все namespace)  
**Назначение:** Полный административный доступ  
**Примеры прав:**
- `*` (все API группы) - `*` (все ресурсы) - `*` (все действия)
- Управление RBAC (roles, rolebindings, clusterroles, clusterrolebindings)
- Управление namespace, nodes, PV (persistent volumes)
- Просмотр и управление secrets
- Удаление любых ресурсов

**Встроенная роль:** Yes (cluster-admin - встроенная в Kubernetes)

---

### 2. cluster-viewer
**Уровень:** Кластер (все namespace)  
**Назначение:** Мониторинг и наблюдение за всей системой  
**Примеры прав:**
- `core` API: `pods, services, configmaps, events, nodes` - `get, list, watch`
- `apps` API: `deployments, statefulsets, daemonsets` - `get, list, watch`
- `networking.k8s.io` API: `ingresses` - `get, list, watch`
- `pods/log` - `get, list`
- БЕЗ доступа: secrets, RBAC ресурсы, управление

**Создание:** Custom ClusterRole

---

### 3. domain-admin
**Уровень:** Namespace (sales, tenant, finance, data + соответствующие -db)  
**Назначение:** Полное управление ресурсами домена  
**Примеры прав:**
- `apps`: `deployments, statefulsets, daemonsets` - `*, [*, patch, update, create, delete]`
- `core`: `pods, services, configmaps, secrets` - `*, [*, patch, update, create, delete]`
- `core`: `pods/exec, pods/attach` - `create, get`
- `networking.k8s.io`: `ingresses` - `*, [*, patch, update, create, delete]`
- `core`: `serviceaccounts` - `get, list, watch, create, update, patch`

**Применяется к:** Каждому namespace отдельно

---

### 4. domain-developer
**Уровень:** Namespace (sales, tenant, finance, data + соответствующие -db)  
**Назначение:** Разработка и деплой приложений (без удаления)  
**Примеры прав:**
- `apps`: `deployments, statefulsets` - `get, list, watch, create, update, patch` (NO delete)
- `core`: `pods` - `get, list, watch, create` (NO delete)
- `core`: `pods/exec, pods/attach` - `create, get`
- `core`: `pods/log` - `get, list`
- `core`: `configmaps, secrets` - `get, list, watch, create, update, patch`
- `core`: `services` - `get, list, watch`

**Применяется к:** Каждому namespace отдельно

---

### 5. domain-viewer
**Уровень:** Namespace (sales, tenant, finance, data + соответствующие -db)  
**Назначение:** Мониторинг и наблюдение за приложениями домена  
**Примеры прав:**
- `apps`: `deployments, statefulsets, daemonsets` - `get, list, watch`
- `core`: `pods, services, configmaps` - `get, list, watch`
- `core`: `pods/log` - `get, list`
- `core`: `events` - `get, list, watch`
- БЕЗ доступа: secrets, создание/изменение/удаление ресурсов

**Применяется к:** Каждому namespace отдельно

---

## Матрица разрешений по действиям

| Действие | cluster-admin | cluster-viewer | domain-admin | domain-developer | domain-viewer |
|----------|---|---|---|---|---|
| Просмотр pods | ✅ Все | ✅ Все | ✅ Свой ns | ✅ Свой ns | ✅ Свой ns |
| Просмотр secrets | ✅ Все | ❌ | ✅ Свой ns | ✅ Свой ns | ❌ |
| Создание deployments | ✅ Все | ❌ | ✅ Свой ns | ✅ Свой ns | ❌ |
| Удаление deployments | ✅ Все | ❌ | ✅ Свой ns | ❌ | ❌ |
| Масштабирование pods | ✅ Все | ❌ | ✅ Свой ns | ✅ Свой ns | ❌ |
| Управление RBAC | ✅ | ❌ | ❌ | ❌ | ❌ |
| Удаление namespace | ✅ | ❌ | ❌ | ❌ | ❌ |
| Просмотр eventos | ✅ Все | ✅ Все | ✅ Свой ns | ✅ Свой ns | ✅ Свой ns |
| Просмотр логов | ✅ Все | ✅ Все | ✅ Свой ns | ✅ Свой ns | ✅ Свой ns |
| Debug (exec в pod) | ✅ Все | ❌ | ✅ Свой ns | ✅ Свой ns | ❌ |

---

## Связь с организационной структурой PropDevelopment

### Структура команд и соответствующие роли

```
PropDevelopment
│
├── Security & Infrastructure
│   ├── Специалист по ИБ → cluster-admin
│   └── CTO → cluster-admin
│
├── Operations Team (глобальный мониторинг)
│   ├── Ops Manager 1 → cluster-viewer
│   └── Ops Manager 2 → cluster-viewer
│
├── Sales Domain Team
│   ├── Sales Lead → domain-admin (sales, sales-db)
│   ├── Sales DevOps → domain-admin (sales, sales-db)
│   ├── Sales Developer 1 → domain-developer (sales, sales-db)
│   ├── Sales Developer 2 → domain-developer (sales, sales-db)
│   └── Sales QA/PM → domain-viewer (sales)
│
├── Tenant/Utilities Domain Team
│   ├── Tenant Lead → domain-admin (tenant, tenant-db)
│   ├── Tenant DevOps → domain-admin (tenant, tenant-db)
│   ├── Tenant Developer 1 → domain-developer (tenant, tenant-db)
│   └── Tenant QA/PM → domain-viewer (tenant)
│
├── Finance Domain Team
│   ├── Finance Lead → domain-admin (finance, finance-db)
│   ├── Finance DevOps → domain-admin (finance, finance-db)
│   ├── Finance Developer 1 → domain-developer (finance, finance-db)
│   └── Finance QA/PM → domain-viewer (finance)
│
└── Data/Analytics Domain Team
    ├── Data Lead → domain-admin (data, data-db)
    ├── Data DevOps → domain-admin (data, data-db)
    ├── Data Developer 1 → domain-developer (data, data-db)
    └── Data QA/PM → domain-viewer (data)
```
---



