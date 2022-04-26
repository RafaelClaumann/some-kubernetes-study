# Kubernetes com Kind

### 📖 [Documentação Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
### 📂 [Descomplicando Kubernetes - LINUX Tips](https://github.com/badtuxx/DescomplicandoKubernetes)
### 🎦 [Aulão Descomplicando O Kubernetes - LINUX Tips](https://www.youtube.com/watch?v=zz1p3gjyHgc)

## Instalando Kubectl
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#kubectl

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
```

## Instalando Kind
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#instala%C3%A7%C3%A3o-no-gnulinux

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Cluster Multi-Node Kind
``` bash
# https://github.com/badtuxx/DescomplicandoKubernetes/blob/main/pt/day_one/descomplicando_kubernetes.md#criando-um-cluster-com-m%C3%BAltiplos-n%C3%B3s-locais-com-o-kind
# https://kind.sigs.k8s.io/docs/user/quick-start/#configuring-your-kind-cluster

# criar arquivo de configuração
cat << EOF > $HOME/kind-3nodes.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

## criar cluster multi-node baseado no arquivo de configuração
kind create cluster --name <cluster-name> --config $HOME/kind-3nodes.yaml
``` 
### Exemplos de Configuração Cluster Multi-Node
``` yaml
# three node (two workers) cluster config
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
