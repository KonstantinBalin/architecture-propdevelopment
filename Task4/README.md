# Тестирование

```bash
minikube start
```

###
```bash
./create-users.sh
```
```bash
./create-roles.sh
```
```bash
./create-rolebindings.sh
```
```bash
kubectl get rolebindings -n sales
```
# Developer: sales-dev-1
```bash
kubectl auth can-i create pods -n sales --as=system:serviceaccount:sales:sales-dev-1
# yes ✓
```
```bash
kubectl auth can-i delete pods -n sales --as=system:serviceaccount:sales:sales-dev-1
# yes ✓
```

# Admin: sales-devops
```bash
kubectl auth can-i create pods -n sales --as=system:serviceaccount:sales:sales-devops
```
```bash
kubectl auth can-i delete pods -n sales --as=system:serviceaccount:sales:sales-devops
```

# Viewer: sales-qa
```bash
kubectl auth can-i get pods -n sales --as=system:serviceaccount:sales:sales-qa
```
```bash
kubectl auth can-i create pods -n sales --as=system:serviceaccount:sales:sales-qa
```

system:serviceaccount:sales:sales-dev-1
create pods → yes
delete pods → no

system:serviceaccount:sales:sales-devops
create pods → yes
delete pods → yes

system:serviceaccount:sales:sales-qa
get pods → yes
create pods → no