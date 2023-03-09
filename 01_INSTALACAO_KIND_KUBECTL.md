# Kubernetes com Kind

### 📖 [Documentação Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
### 📖 [Documentação Kubernetes](https://kubernetes.io/docs/home/)
### 📂 [Descomplicando Kubernetes - LINUX Tips](https://github.com/badtuxx/DescomplicandoKubernetes)
### 🎦 [Aulão Descomplicando O Kubernetes - LINUX Tips](https://www.youtube.com/watch?v=zz1p3gjyHgc)
### 🎦 [CLUSTER K8S COM NGINX INGRESS CONTROLLER EM SUA MÁQUINA(Kind) - Linux Tips](https://www.youtube.com/watch?v=1lx91nhzNe0&t=889s&ab_channel=LINUXtips)

---

## Instalando kubectl
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#instala%C3%A7%C3%A3o-do-kubectl-no-gnulinux

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
```

## Instalando kind
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#kind

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Criando cluster multi-node kind
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#kind
# https://kind.sigs.k8s.io/docs/user/quick-start/#configuring-your-kind-cluster

# criar arquivo de configuração
kind create cluster \
--name <cluster_name_opcional> \
--config - <<EOF
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  nodes:
    - role: control-plane
    - role: worker
    - role: worker
EOF
```

### Exemplos de configurações de clusters multi-node
``` yaml
# tnhree node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
``` 
``` yaml
# a cluster with 3 control-plane nodes and 3 workers
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: control-plane
  - role: control-plane
  - role: worker
  - role: worker
  - role: worker
```
