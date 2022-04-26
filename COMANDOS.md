### Comandos Kind
``` bash
# criar um cluster com um nome especifico
kind create cluster --name <cluster_name>

# criar um cluster a partir de um arquivo de configuração yaml.
kind create cluster --name <cluster_name> --config <config.yaml>

# listar os clusters criados com o Kind
kind get clusters

# exportar os logs do cluster para um diretório
kind --name <cluster_name> export logs <diretorio>

# excluir o cluster(todos neste exemplo)
kind delete clusters $(kind get clusters)
```

### Comandos Kubectl
``` bash
## listar as máquinas(nodes) em execução
  kubectl get nodes
  
## exibir os detalhes de um node  
  kubectl describe node <node_name>

## listar os contextos disponiveis
  kubectl config get-contexts		

## set the current-context in a kubeconfig file
  kubectl config use-context <context_name>

## definir um namespace padrao, nao será necessário passar o namespace em todos os comandos
  kubectl config set-context <context> --namespace=<namespace>
  kubectl config set-context --current --namespace=<namespace>

## exibir o contexto atual
  kubectl config current-context
  
## comando utilizado para criar um namespace, pode ser criado utilizando um template yaml...
## https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#creating-a-new-namespace
## 
##  apiVersion: v1
##  kind: Namespace
##  metadata:
##    name: <namespace-name>
  kubectl create namespace <namespace-name>
  kubectl create -f my-namespace.yaml

## listar os namespaces disponiveis
  kubectl get namespaces
  kubectl get ns

## criar um pod a partir de uma imagem de container
  kubectl run --image=<image> <pod_name>
  
## retornar informações importantes de um pod específico
  kubectl describe pods <pod_name> --namespace <namespace>  

## retorna o YAML do pod	
  kubectl get pods <pod_name> -o yaml --namespace <namespace>

## listar os pods em execução no namespace/node, wide trás mais informações como IP do Pod
  kubectl get pods --namespace <namespace>
  kubectl get pods --all-namespaces
  kubectl get pods -o wide

## explicação sobre o recurso, --recursive retorna todas as opções de parametros do recurso
  kubectl explain <resource> --recursive
  kubectl explain deployment
  kubectl explain pod.kind
```
