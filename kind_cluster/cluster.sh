#! /bin/bash

# options:
#   no-options                   -> install clean cluster
#   -c  / --cni                  -> install cilium cni(should be the first parameter)
#   -m  / --metrics              -> install metrics server
#   -i  / --ingress              -> install nginx ingress controller
#   -p  / --prometheus           -> install kube prometheus stack
#   -pi / --prometheus-ingress   -> install ingress-nginx, kube prometheus stack and service monitor on nginx

# examples:
#   sh cluster.sh -c -m -p -i
#   sh cluster.sh --cni --metrics --prometheus --ingress
#
#   sh cluster.sh -m -p -i
#   sh cluster.sh --metrics --prometheus --ingress

#   sh cluster.sh -c -m -pi
#   sh cluster.sh --cni --metrics --prometheus-ingress

readonly KIND_IMAGE="kindest/node:v1.25.11@sha256:227fa11ce74ea76a0474eeefb84cb75d8dad1b08638371ecf0e86259b35be0c8"

readonly CILIUM_HELM_CHART_VERSION=1.13.0
readonly CILIUM_HELM_REPOSITORY_URL=https://helm.cilium.io 
readonly CILIUM_HELM_RELEASE_NAME=cilium
readonly CILIUM_NAMESPACE_NAME=cilium

readonly METRICS_SERVER_HELM_CHART_VERSION=3.8.4
readonly METRICS_SERVER_HELM_REPOSITORY_URL=https://kubernetes-sigs.github.io/metrics-server
readonly METRICS_SERVER_HELM_RELEASE_NAME=metrics
readonly METRICS_SERVER_NAMESPACE_NAME=metrics-server

readonly PROMETHEUS_STACK_HELM_CHART_VERSION=45.7.1
readonly PROMETHEUS_STACK_HELM_REPOSITORY_URL=https://prometheus-community.github.io/helm-charts
readonly PROMETHEUS_STACK_HELM_RELEASE_NAME=prometheus
readonly PROMETHEUS_STACK_NAMESPACE_NAME=monitoring

readonly INGRESS_NGINX_HELM_CHART_VERSION=4.5.2
readonly INGRESS_NGINX_HELM_REPOSITORY_URL=https://kubernetes.github.io/ingress-nginx
readonly INGRESS_NGINX_HELM_RELEASE_NAME=nginx
readonly INGRESS_NGINX_NAMESPACE_NAME=ingress

main() {
  # parâmetro posicional '-c / --cni' deve ser o primeiro fornecido para o script
  # ele define se o cluster será criado com Cilium CNI ou Kindnet CNI(default)
  if [ "$1" == "-c" ] || [ "$1" == "--cni" ]; then
    echo_green_pattern "Criando cluster com Cilium CNI"
    cluster_with_cni
  else
    echo_green_pattern "Criando cluster sem Cilium CNI"
    basic_cluster
  fi

  # variaveis usadas para controlar possíveis repetições de parâmetros posicionais
  metrics_server=false
  prometheus=false
  ingress_nginx=false
  prometheus_ingress=false

  # laço de repetição sobre os parâmetros posicionais fornecidos na invocação do script
  while [ "$1" ]
    do
      if [ "$1" == "-m" ] || [ "$1" == "--metrics" ] && [ "$metrics_server" == false ]; then
        install_metrics_server
        metrics_server=true
      fi

      if [ "$1" == "-p" ] || [ "$1" == "--prometheus" ] && [ "$prometheus" == false ]; then
        install_prometheus_stack
        prometheus=true
      fi
        
      if [ "$1" == "-i" ] || [ "$1" == "--ingress" ] && [ "$ingress_nginx" == false ]; then
        install_ingress_nginx
        ingress_nginx=true
      fi

      if [ "$1" == "-pi" ] || [ "$1" == "--prometheus-ingress" ] && [ "$prometheus_ingress" == false ]; then
        # verifica se existe release 'nginx' implantado com helm e, se não existir, ele será implantado
        NGINX=$(helm list --all-namespaces --deployed --no-headers --selector="name=$INGRESS_NGINX_HELM_RELEASE_NAME" --short)
        if [ "$NGINX" != "$INGRESS_NGINX_HELM_RELEASE_NAME" ]; then
          install_ingress_nginx
          ingress_nginx=true
        fi
        
        # verifica se existe release 'prometheus_stack' implantado com helm e, se não existir, ele será implantado
        PROMETHEUS=$(helm list --all-namespaces --deployed --no-headers --selector="name=$PROMETHEUS_STACK_HELM_RELEASE_NAME" --short)
        if [ "$PROMETHEUS" != "$PROMETHEUS_STACK_HELM_RELEASE_NAME" ]; then
          install_prometheus_stack
          prometheus=true
        fi

        # criando recurso Ingress para acessar o grafana via http://localhost/grafana
        kubectl create ingress grafana-ingress \
        --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
        --class=nginx \
        --rule="/grafana*=prometheus-grafana:3000" 

        # patch no nginx para exportar suas métricas
        # https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#prometheus-and-grafana-installation-using-service-monitors
        echo_green_pattern "Patch ingress ngnix"
        helm upgrade \
          --repo "$INGRESS_NGINX_HELM_REPOSITORY_URL" "$INGRESS_NGINX_HELM_RELEASE_NAME" ingress-nginx \
          --namespace "$INGRESS_NGINX_NAMESPACE_NAME" \
          --reuse-values \
          --set controller.metrics.enabled=true \
          --set controller.metrics.serviceMonitor.enabled=true \
          --set controller.metrics.serviceMonitor.additionalLabels."release="$PROMETHEUS_STACK_HELM_RELEASE_NAME
      fi
      shift
  done
  exit 0
}

function basic_cluster() {
    kind create cluster --config - <<EOF
    apiVersion: kind.x-k8s.io/v1alpha4
    kind: Cluster 
    nodes:
      - role: control-plane
        image: ${KIND_IMAGE} 
        extraPortMappings:
          - containerPort: 80
            hostPort: 80
            protocol: TCP
          - containerPort: 443
            hostPort: 443
            protocol: TCP
      - role: worker
        image: ${KIND_IMAGE} 
      - role: worker
        image: ${KIND_IMAGE} 
EOF
}

function cluster_with_cni() {
  kind create cluster --config - <<EOF
    apiVersion: kind.x-k8s.io/v1alpha4
    kind: Cluster 
    nodes:
      - role: control-plane
        image: ${KIND_IMAGE} 
        extraPortMappings:
          - containerPort: 80
            hostPort: 80
            protocol: TCP
          - containerPort: 443
            hostPort: 443
            protocol: TCP
      - role: worker
        image: ${KIND_IMAGE} 
      - role: worker
        image: ${KIND_IMAGE} 
    networking:
      disableDefaultCNI: true
      kubeProxyMode: none
      podSubnet: "10.244.0.0/16"        # Configuracao para o Cilium
      serviceSubnet: "10.96.0.0/12"     # Configuracao para o Cilium
EOF

  echo_green_pattern "Instalando e configurando Cilium CNI"
  helm upgrade \
    --install \
    --version $CILIUM_HELM_CHART_VERSION \
    --namespace $CILIUM_NAMESPACE_NAME \
    --create-namespace \
    --repo $CILIUM_HELM_REPOSITORY_URL $CILIUM_HELM_RELEASE_NAME cilium \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=kind-control-plane \
    --set k8sServicePort=6443 \
    --set hostServices.enabled=false \
    --set externalIPs.enabled=true \
    --set nodePort.enabled=true \
    --set hostPort.enabled=true \
    --set image.pullPolicy=IfNotPresent \
    --set ipam.mode=kubernetes \
    --set hubble.enabled=false \
    --set hubble.relay.enabled=false \
    --set hubble.ui.enabled=false

  echo_green_pattern "Esperando a instalação do Cilium CNI"
  kubectl wait \
    --namespace=$CILIUM_NAMESPACE_NAME \
    --for=condition=ready pod \
    --selector='app.kubernetes.io/name in(cilium-agent, cilium-operator)' \
    --timeout=-1s  # -1 = wait 1 week

  echo
  kubectl get pods --namespace $CILIUM_NAMESPACE_NAME
}

function install_metrics_server() {
  echo_green_pattern "Instalando e configurando metrics server"

  helm upgrade \
    --install \
    --version $METRICS_SERVER_HELM_CHART_VERSION \
    --namespace $METRICS_SERVER_NAMESPACE_NAME \
    --create-namespace \
    --repo $METRICS_SERVER_HELM_REPOSITORY_URL $METRICS_SERVER_HELM_RELEASE_NAME  metrics-server \
    --values - <<EOF
    defaultArgs:
      - --cert-dir=/tmp
      - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
      - --kubelet-use-node-status-port
      - --metric-resolution=15s
      - --kubelet-insecure-tls
EOF

  echo
  kubectl get pods --namespace $METRICS_SERVER_NAMESPACE_NAME
}

function install_prometheus_stack() {
  echo_green_pattern "Instalando e configurando kube prometheus stack"
  
  helm upgrade \
    --install \
    --version $PROMETHEUS_STACK_HELM_CHART_VERSION \
    --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
    --create-namespace \
    --repo $PROMETHEUS_STACK_HELM_REPOSITORY_URL $PROMETHEUS_STACK_HELM_RELEASE_NAME kube-prometheus-stack \
    --values - <<EOF
    prometheus:
      prometheusSpec:
        podMonitorSelectorNilUsesHelmValues: false
        serviceMonitorSelectorNilUsesHelmValues: false
    grafana:
      env:
        GF_SERVER_ROOT_URL: "http://cluster.com/grafana"
        GF_SERVER_SERVE_FROM_SUB_PATH: "true"
      adminPassword: admin
EOF

  # patch para tornar o service prometheus-grafana NodePort
  # grafana acessivel em http://<node-ip-address>:30000
  kubectl patch \
   --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
   service prometheus-grafana \
    -p '{"spec": {"ports": [{"name": "http-web" ,"port": 80,"targetPort": 3000,"nodePort":30000}],"type": "NodePort"}}'

  echo
  kubectl get pods --namespace $PROMETHEUS_STACK_NAMESPACE_NAME
}

function install_ingress_nginx() {
  echo_green_pattern "Instalando e configurando nginx ingress controller"
  kubectl label node kind-control-plane ingress-ready=true

  helm upgrade \
    --install \
    --version $INGRESS_NGINX_HELM_CHART_VERSION \
    --namespace $INGRESS_NGINX_NAMESPACE_NAME \
    --create-namespace \
    --repo $INGRESS_NGINX_HELM_REPOSITORY_URL $INGRESS_NGINX_HELM_RELEASE_NAME ingress-nginx \
    --values - <<EOF  
    controller:
      updateStrategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 1
      hostPort:
        enabled: true
      terminationGracePeriodSeconds: 0
      service:
        type: NodePort
      watchIngressWithoutClass: true
      nodeSelector:
        ingress-ready: "true"
      tolerations:
        - key: "node-role.kubernetes.io/master"
          operator: "Equal"
          effect: "NoSchedule"
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Equal"
          effect: "NoSchedule"
      publishService:
        enabled: false
      extraArgs:
        publish-status-address: localhost
EOF

  echo
  kubectl get pods --namespace $INGRESS_NGINX_NAMESPACE_NAME
}

function echo_green_pattern() {
  GREEN='\033[0;32m'
  NOCOLOR='\033[0m'
  echo -e "${GREEN}$1${NOCOLOR}"
}

main "$@"; exit
