#! /bin/bash
readonly CLUSTER_NAME=dev

readonly CILIUM_HELM_CHART_VERSION=1.13.0
readonly CILIUM_HELM_REPOSITORY_URL=https://helm.cilium.io 
readonly CILIUM_HELM_RELEASE_NAME=cilium
readonly CILIUM_NAMESPACE_NAME=cilium

readonly METAL_LB_HELM_CHART_VERSION=0.13.10
readonly METAL_LB_HELM_REPOSITORY_URL=https://metallb.github.io/metallb
readonly METAL_LB_HELM_RELEASE_NAME=metal-lb
readonly METAL_LB_NAMESPACE_NAME=metallb-system

readonly METRICS_SERVER_HELM_CHART_VERSION=3.8.4
readonly METRICS_SERVER_HELM_REPOSITORY_URL=https://kubernetes-sigs.github.io/metrics-server
readonly METRICS_SERVER_HELM_RELEASE_NAME=metrics
readonly METRICS_SERVER_NAMESPACE_NAME=metrics-server

readonly INGRESS_NGINX_HELM_CHART_VERSION=4.5.2
readonly INGRESS_NGINX_HELM_REPOSITORY_URL=https://kubernetes.github.io/ingress-nginx
readonly INGRESS_NGINX_HELM_RELEASE_NAME=nginx
readonly INGRESS_NGINX_NAMESPACE_NAME=ingress

readonly PROMETHEUS_STACK_HELM_CHART_VERSION=45.7.1
readonly PROMETHEUS_STACK_HELM_REPOSITORY_URL=https://prometheus-community.github.io/helm-charts
readonly PROMETHEUS_STACK_HELM_RELEASE_NAME=prometheus
readonly PROMETHEUS_STACK_NAMESPACE_NAME=monitoring

parameters=$@
unique_paramaters=$(tr ' ' '\n' <<<"${parameters[@]}" | awk '!u[$0]++' | tr '\n' ' ')
echo "Parametros fornecidos: $unique_paramaters"

function main() {
  if [[ ${unique_paramaters[@]} =~ "-k" && ${unique_paramaters[@]} =~ "-c" ]]; then
    create_cluster_with_cilium_cni
  else
    create_cluster_with_kindnet_cni
  fi

  if [[ ${unique_paramaters[@]} =~ "-m" ]]; then
    install_metrics_server
  fi

  if [[ ${unique_paramaters[@]} =~ "-l" && ${unique_paramaters[@]} =~ "-i" && ${unique_paramaters[@]} =~ "-p" ]]; then
    install_metallb
    install_ingress_nginx
    install_prometheus_stack
    enable_nginx_service_monitor
  elif [[ ${unique_paramaters[@]} =~ "-l" && ${unique_paramaters[@]} =~ "-i" ]]; then
    install_metallb
    install_ingress_nginx
  elif [[ ${unique_paramaters[@]} =~ "-l" && ${unique_paramaters[@]} =~ "-p" ]]; then
    install_metallb
    install_prometheus_stack
  elif [[ ${unique_paramaters[@]} =~ "-i" && ${unique_paramaters[@]} =~ "-p" ]]; then
    install_ingress_nginx
    install_prometheus_stack
    enable_nginx_service_monitor
  elif [[ ${unique_paramaters[@]} =~ "-l" ]]; then
    install_metallb
  elif [[ ${unique_paramaters[@]} =~ "-i" ]]; then
    install_ingress_nginx
  elif [[ ${unique_paramaters[@]} =~ "-p" ]]; then
    install_prometheus_stack
  fi
}

function create_cluster_with_kindnet_cni() {
  echo "Criando cluster com Kindnet CNI"
  kind create cluster --name $CLUSTER_NAME --config "./cluster_manifests/default.yaml"
}

function create_cluster_with_cilium_cni() {
  echo "Criando cluster Cilium CNI"
  kind create cluster --name $CLUSTER_NAME --config "./cluster_manifests/without_cni.yaml"
  install_cilium_cni
}

function install_cilium_cni() {
  echo "Instalando e configurando { Cilium CNI }"
  helm upgrade \
    --install \
    --version $CILIUM_HELM_CHART_VERSION \
    --namespace $CILIUM_NAMESPACE_NAME \
    --create-namespace \
    --repo $CILIUM_HELM_REPOSITORY_URL $CILIUM_HELM_RELEASE_NAME cilium \
    --values "./config/cilium.yaml"

  echo "Esperando instalação do { Cilium CNI }"
  kubectl wait \
    --namespace=$CILIUM_NAMESPACE_NAME \
    --for=condition=ready pod \
    --selector='app.kubernetes.io/name in(cilium-agent, cilium-operator)' \
    --timeout=-1s  # -1 = wait 1 week
}

function install_metrics_server() {
  echo "Instalando e configurando { Metrics Server }"
  helm upgrade \
    --install \
    --version $METRICS_SERVER_HELM_CHART_VERSION \
    --namespace $METRICS_SERVER_NAMESPACE_NAME \
    --create-namespace \
    --repo $METRICS_SERVER_HELM_REPOSITORY_URL $METRICS_SERVER_HELM_RELEASE_NAME metrics-server \
    --values "./config/metrics.yaml"
  
  echo "Esperando instalação do { Metrics Server }"
  kubectl wait \
    --namespace=$METRICS_SERVER_NAMESPACE_NAME \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/instance=metrics \
    --timeout=-1s

  kubectl get pods --namespace $METRICS_SERVER_NAMESPACE_NAME
}

function install_metallb() {
  echo "Instalando e configurando { Metal LB }"
  helm upgrade \
    --install \
    --version $METAL_LB_HELM_CHART_VERSION \
    --namespace $METAL_LB_NAMESPACE_NAME \
    --create-namespace \
    --repo $METAL_LB_HELM_REPOSITORY_URL $METAL_LB_HELM_RELEASE_NAME metallb

  echo "Esperando instalação do { Metal LB }"
  kubectl wait \
    --namespace=metallb-system \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/instance=metal-lb \
    --timeout=-1s

  # obtendo subnet CIDR do cluster kind
  subnet=$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' kind)
  endereco=$(echo "$subnet" | sed 's|/[0-9]\{1,3\}$||')
  lb_address_range="${endereco%.*}.202-${endereco%.*}.254"

  # definindo a faixa de endereços IP disponíveis para o metallb
  while IFS= read -r line; do
    if [[ "$line" =~ ^\ +\-.* ]]; then
      echo "  - $lb_address_range"
    else
      echo "$line"
    fi
  done < ./config/metallb.yaml > ./config/temp.yaml
  mv ./config/temp.yaml ./config/metallb.yaml

  # aplicando configurações do metallb
  kubectl apply -f ./config/metallb.yaml

  # se ingress ServiceType=NodePort e kube_prometheus instalado, atualize ingress ServiceType=LoadBalancer e habilite o nginx_service_monitor
  # se ingress ServiceType=NodePort, atualize o ingress ServiceType=Load Balancer
  ingress_service_type=$(helm get values -n $INGRESS_NGINX_NAMESPACE_NAME $INGRESS_NGINX_HELM_RELEASE_NAME -o yaml | grep -e "type: NodePort" | tr -d ' ')
  has_prometheus_deployed=$(helm list -n $PROMETHEUS_STACK_NAMESPACE_NAME --short)
  if [[ $ingress_service_type = "type:NodePort" && $has_prometheus_deployed = "$PROMETHEUS_STACK_HELM_RELEASE_NAME" ]]; then
    install_ingress_nginx
    enable_nginx_service_monitor
  elif [[ $ingress_service_type = "type:NodePort" ]]; then
    install_ingress_nginx
  fi
}

function install_ingress_nginx() {
  echo "Instalando e configurando { Nginx Ingress Controller }"
  kubectl label node $CLUSTER_NAME-control-plane ingress-ready=true

  # se o load balancer(metallb) estiver instalado, crie o ingress ServiceType=LoadBalancer
  # caso contrário, instale o ingress ServiceType=NodePort
  has_load_balancer=$(helm list -n $METAL_LB_NAMESPACE_NAME -q)
  if [[ $has_load_balancer = "$METAL_LB_HELM_RELEASE_NAME" ]]; then
    echo "Usando Nginx com Service Type Load Balancer"
    helm upgrade \
      --install \
      --version $INGRESS_NGINX_HELM_CHART_VERSION \
      --namespace $INGRESS_NGINX_NAMESPACE_NAME \
      --create-namespace \
      --repo $INGRESS_NGINX_HELM_REPOSITORY_URL $INGRESS_NGINX_HELM_RELEASE_NAME ingress-nginx \
      --values "./config/ingress_nginx.yaml"
  else
    echo "Usando Nginx com Service Type Node Port"
    helm upgrade \
      --install \
      --version $INGRESS_NGINX_HELM_CHART_VERSION \
      --namespace $INGRESS_NGINX_NAMESPACE_NAME \
      --create-namespace \
      --repo $INGRESS_NGINX_HELM_REPOSITORY_URL $INGRESS_NGINX_HELM_RELEASE_NAME ingress-nginx \
      --values "./config/ingress_nginx.yaml" \
      --set controller.service.type=NodePort \
      --set controller.publishService.enabled=false \
      --set controller.extraArgs.publish-status-address=localhost
  fi

  kubectl get pods --namespace $INGRESS_NGINX_NAMESPACE_NAME
}

function install_prometheus_stack() {
  echo "Instalando e configurando { Kube Prometheus Stack }"
  helm upgrade \
    --install \
    --version $PROMETHEUS_STACK_HELM_CHART_VERSION \
    --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
    --create-namespace \
    --repo $PROMETHEUS_STACK_HELM_REPOSITORY_URL $PROMETHEUS_STACK_HELM_RELEASE_NAME kube-prometheus-stack \
    --set grafana.adminPassword=admin

  kubectl patch \
    --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
    service prometheus-grafana \
    -p '{"spec": {"ports": [{"name": "http-web" ,"port": 80,"targetPort": 3000,"nodePort":30000}],"type": "NodePort"}}'

  kubectl get pods --namespace $PROMETHEUS_STACK_NAMESPACE_NAME

  # se o ingress estiver instalado, habilite o nginx_service_monitor
  has_ingress_deployed=$(helm list --namespace $INGRESS_NGINX_NAMESPACE_NAME -q)
  if [ "$has_ingress_deployed" = $INGRESS_NGINX_HELM_RELEASE_NAME ]; then
    enable_nginx_service_monitor
  fi
}

function enable_nginx_service_monitor() {
  helm upgrade \
    --repo $INGRESS_NGINX_HELM_REPOSITORY_URL $INGRESS_NGINX_HELM_RELEASE_NAME ingress-nginx \
    --namespace $INGRESS_NGINX_NAMESPACE_NAME \
    --reuse-values \
    --set controller.metrics.enabled=true \
    --set controller.metrics.serviceMonitor.enabled=true \
    --set controller.metrics.serviceMonitor.additionalLabels."release="$PROMETHEUS_STACK_HELM_RELEASE_NAME

  helm upgrade \
    --repo $PROMETHEUS_STACK_HELM_REPOSITORY_URL $PROMETHEUS_STACK_HELM_RELEASE_NAME kube-prometheus-stack \
    --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
    --set grafana.adminPassword=admin \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

  kubectl set env deployments/prometheus-grafana \
    --namespace monitoring \
    --containers="grafana" \
    GF_SERVER_SERVE_FROM_SUB_PATH=true

  kubectl set env deployments/prometheus-grafana \
    --namespace monitoring \
    --containers="grafana" \
    GF_SERVER_ROOT_URL=http://localhost.com/grafana

  kubectl wait \
    --namespace=$INGRESS_NGINX_NAMESPACE_NAME \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/instance=nginx \
    --timeout=-1s

  kubectl create ingress grafana-ingress \
    --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
    --class=nginx \
    --rule="/grafana*=prometheus-grafana:3000"
}

main "$@"; exit
