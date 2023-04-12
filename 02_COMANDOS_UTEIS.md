# Comandos importantes

### Kind
``` bash
# criar um cluster com um nome especifico
kind create cluster --name <cluster_name>

# criar um cluster a partir de um arquivo de configuração yaml.
kind create cluster --name <cluster_name> --config <config.yaml>

# listar os clusters criados com o Kind
kind get clusters

# exportar os logs do cluster para um diretório
kind --name <cluster_name> export logs <diretorio>

# excluir os clusters(todos neste exemplo)
kind delete clusters $(kind get clusters)

# excluir os clusters
kind delete clusters --all
```

### Kubectl ([documentação](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands))
``` bash
## listar pods do namespace default
## -o wide  -> traz mais informações como o endereço IP do Pod e node que ele foi escalonado
  kubectl get pods -o wide

## listar os pods de um namespace especifico
  kubectl get pods --namespace=<namespace_name>

## listar os pods de todos os namespaces
  kubectl get pods --all-namespaces  

## listar pods e exibir seus labels
  kubectl get pods --show-labels
  
## obter representação yaml do pod e expotar para um arquivo
  kubectl get pods <pod_name> -o yaml > pod.yaml 

## listar detalhes dos um pods
  kubectl describe pods

## listar detalhes de um pod
  kubectl describe pods <pod_name>

## criar um pod a partir de uma imagem de container
  kubectl run <pod_name> --image=<image>

## executar um Pod de forma temporaria interativa, ele será excluído ao sair do bash
  kubectl run --rm -it <pod_name> --image=<pod_image> -- bash 

## criar um pod a partir de uma imagem de container
## --expose=true  -> create a ClusterIP service associated with the pod. Requires `--port`
## --port=8080    -> the port that this container exposes.
  kubectl run <pod_name> \
  --image=<pod_image> \
  --port=8080 \
  --expose=true \
  --env=TESTE00=TESTE00 \
  --env=TESTE01=TESTE01 \
  --labels='app=myapp,label=teste' \
  --restart=OnFailure \  
  -- /bin/bash -c 'echo hello world'  

## simular a criação de um pod e exportar sua representação yaml para um arquivo
  kubectl run --image=<image> <pod_name> --dry-run=client -o yaml > pod.yaml

## logs de um container de um Pod com um único container
  kubectl logs <pod_name>

## logs de um container específico em um Pod multicontainers
## -f, --follow   -> cria um stream dos logs e os acompanha em tempo real
## -p, --previous -> busca os logs da execução anterior do container
## --tail=n       -> exibe as ultimas 'n' linhas dos logs
  kubectl logs <pod_name> -c <container_name>

## comando utilizado para criar um recurso
# Available Commands:
#  clusterrole           Create a cluster role
#  clusterrolebinding    Create a cluster role binding for a particular cluster role
#  configmap             Create a config map from a local file, directory or literal value
#  cronjob               Create a cron job with the specified name
#  deployment            Create a deployment with the specified name
#  ingress               Create an ingress with the specified name
#  job                   Create a job with the specified name
#  namespace             Cria a namespace com um nome especificado
#  quota                 Create a quota with the specified name
#  role                  Create a role with single rule
#  rolebinding           Create a role binding for a particular role or cluster role
#  secret                Cria um secret utilizando um sub-comando especificado
#  service               Create a service using a specified subcommand
#  serviceaccount        Cria uma conta de serviço com um nome especificado
  kubectl create <resource_type> <resource_name> [OPTIONS]

## explicação sobre os recursos, --recursive retorna todas as opções de parametros do recurso
  kubectl explain <resource> --recursive
  kubectl explain deployment.spec.template
  kubectl explain pod.spec.containers

## obter help a partir do CLI
  kubectl run --help
  kubectl create --help
  kubectl create job --help

## listar os contextos disponiveis
  kubectl config get-contexts		

## set the current-context in a kubeconfig file
  kubectl config use-context <context_name>

## definir um namespace padrao, nao será necessário passar o namespace em todos os comandos
  kubectl config set-context <context> --namespace=<namespace>
  kubectl config set-context --current --namespace=<namespace>

## exibir o contexto atual
  kubectl config current-context  
```

### Helm ([documentação](https://helm.sh/docs/helm/))
``` bash
# Adicionando repositório
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Removento repositório
helm repo remove prometheus-community

# Listando repositórios
helm repo list

# Listando charts disponíveis no repositório prometheus-community
helm search repo prometheus-community

# Instalando chart COM repositório adicionado
# helm install RELEASE_NAME REPOSITORY/CHART_NAME
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --version 45.7.1 \
  --namespace prometheus \
  --create-namespace \
  --set grafana.adminPassword=rafael

# Instalando chart SEM repositório adicionado
# Demonstrando a possibilidade de usar yaml ao invés de --set
helm upgrade \
  --install \
  --version 45.7.1 \
  --namespace prometheus \
  --create-namespace \
  --repo https://prometheus-community.github.io/helm-charts kube-prometheus kube-prometheus-stack \
  --values - <<EOF
  grafana:
    adminPassword: admin
EOF

# Alterando parâmetro do chart COM repositório adicionado
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace prometheus  \
  --set grafana.adminPassword=rafael

# Alterando parâmetro do chart SEM repositório adicionado
# Demonstrando a possibilidade de usar yaml ao invés de --set
helm upgrade \
  --repo https://prometheus-community.github.io/helm-charts kube-prometheus kube-prometheus-stack \
  --namespace prometheus  \
  --values - <<EOF
  grafana:
    adminPassword: teste
EOF

# Listando atributos alterados na flag --values durante a instalação do chart
# Use a flag -a no comando abaixo para listar todos os atributos disponiveis no chart
# Os atributos disponíveis também podem ser encontrados no repositório do chart:
#   https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
helm get values kube-prometheus --namespace prometheus

# Listando Charts(releases) instalados por namespace
# Use a flag -A ou --all-namespaces para listar os charts de todos os namespaces
helm list --namespace prometheus
  NAME             NAMESPACE     REVISION   UPDATED              STATUS     CHART                         APP VERSION
  kube-prometheus  prometheus    3          2023-03-10 06:44:29  deployed   kube-prometheus-stack-45.7.1  v0.63.0    

# Realizar rollback para revisoes anteriores do chart
helm rollback kube-prometheus 2 --namespace prometheus

# Listar revisions do chart
helm history --namespace prometheus kube-prometheus

```
