### Cоздай политики

```bash
kubectl delete networkpolicies --all -n task5
```
```bash
kubectl apply -f non-admin-api-allow.yaml
```
```bash
kubectl get networkpolicies -n task5
```

### Убедись, что 4 pod’а и сервисы живы:
```bash
kubectl get pods -n task5 --show-labels
```
```bash
kubectl get svc -n task5
```

### Прогоняй тесты:

# 1: должно работать
```bash
kubectl get svc -n task5
```

```bash
kubectl exec -it front-end-app -n task5 -- curl --max-time 2 http://back-end-api-app:80
```

# 2: должно БЛОКИРОВАТЬСЯ
```bash
kubectl exec -it front-end-app -n task5 -- curl --max-time 2 http://admin-back-end-api-app:80
```

# 3: должно работать
```bash
kubectl exec -it admin-front-end-app -n task5 -- curl --max-time 2 http://admin-back-end-api-app:80
```

# 4: должно БЛОКИРОВАТЬСЯ
```bash
kubectl exec -it admin-front-end-app -n task5 -- curl --max-time 2 http://back-end-api-app:80
```