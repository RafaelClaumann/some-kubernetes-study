#! /bin/bash

echo "
#####################################
## INICIANDO INSTALACAO DO CLUSTER ##
#####################################";
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster 
  nodes:
    - role: control-plane
      image: kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1
      kubeadmConfigPatches:
        - |
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              node-labels: "ingress-ready=true"      
      extraPortMappings:
        - containerPort: 30500
          hostPort: 3500
          listenAddress: "127.0.0.1"
          protocol: tcp
        - containerPort: 80
          hostPort: 80
          protocol: TCP
        - containerPort: 443
          hostPort: 443
          protocol: TCP          
    - role: worker
      image: kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1
    - role: worker
      image: kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1
  networking:
    disableDefaultCNI: true
    kubeProxyMode: none
    podSubnet: "10.244.0.0/16"        # Configuracao para o Cilium
    serviceSubnet: "10.96.0.0/12"     # Configuracao para o Cilium
EOF


echo "
##########################################
## INSTALANDO E CONFIGURANDO CILIUM CNI ##
##########################################";
readonly CILIUM_CHART_VERSION=1.13.0
docker pull quay.io/cilium/cilium:v$CILIUM_CHART_VERSION --quiet
kind load docker-image quay.io/cilium/cilium:v$CILIUM_CHART_VERSION --quiet
helm upgrade \
  --install \
  --version $CILIUM_CHART_VERSION \
  --namespace kube-system \
  --repo https://helm.cilium.io cilium cilium \
  --values - <<EOF
  kubeProxyReplacement: strict
  k8sServiceHost: kind-control-plane
  k8sServicePort: 6443
  hostServices:
    enabled: false
  externalIPs:
    enabled: true
  nodePort:
    enabled: true
  hostPort:
    enabled: true
  image:
    pullPolicy: IfNotPresent
  ipam:
    mode: kubernetes
  hubble:
    enabled: false
    relay:
      enabled: false
    ui:
      enabled: false
EOF

echo "#### WAITING CILIUM INSTALATION ####";
kubectl wait \
  --namespace=kube-system \
  --for=condition=ready pod \
  --selector='app.kubernetes.io/name in(cilium-agent, cilium-operator)' \
  --timeout=-1s  # -1 = wait 1 week


echo "
################################################ 
##   INSTALANDO E CONFIGURANDO METRICS SERVER ##
################################################";
readonly METRICS_SERVER_CHART_VERSION=3.8.4
readonly METRICS_SERVER_NAMESPACE_NAME=metrics-server
helm upgrade \
  --install \
  --version $METRICS_SERVER_CHART_VERSION \
  --namespace $METRICS_SERVER_NAMESPACE_NAME \
  --create-namespace \
  --repo https://kubernetes-sigs.github.io/metrics-server/ metrics-server metrics-server \
  --values - <<EOF
  defaultArgs:
    - --cert-dir=/tmp
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --kubelet-use-node-status-port
    - --metric-resolution=15s
    - --kubelet-insecure-tls
EOF

echo "#### WAITING METRICS-SERVER INSTALATION ####";
kubectl wait \
  --namespace=$METRICS_SERVER_NAMESPACE_NAME \
  --for=condition=ready pod \
  --selector='app.kubernetes.io/instance in(metrics-server)' \
  --timeout=-1s  # -1 = wait 1 week


echo "
#####################################################
## INSTALANDO E CONFIGURANDO KUBE_PROMETHEUS_STACK ##
#####################################################";
readonly PROMETHEUS_STACK_CHART_VERSION=45.7.1
readonly PROMETHEUS_STACK_NAMESPACE_NAME=prometheus
helm upgrade \
  --install \
  --version $PROMETHEUS_STACK_CHART_VERSION \
  --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
  --create-namespace \
  --repo https://prometheus-community.github.io/helm-charts prometheus kube-prometheus-stack \
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
    ingress:
      enabled: "true"
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: "/\$2"
      hosts: ["cluster.com"]
      path: "/grafana(/|$)(.*)"
EOF

kubectl patch \
 --namespace $PROMETHEUS_STACK_NAMESPACE_NAME \
 service prometheus-grafana \
  -p '{"spec": {"ports": [{"name": "http-web" ,"port": 80,"targetPort": 3000,"nodePort":30000}],"type": "NodePort"}}'

echo "#### WAITING KUBE_PROMETHEUS_STACK INSTALATION ####";
kubectl wait \
  --namespace=$PROMETHEUS_STACK_NAMESPACE_NAME \
  --for=condition=ready pod \
  --selector='app.kubernetes.io/instance in(prometheus)' \
  --timeout=-1s  # -1 = wait 1 week


echo "
########################################################
## INSTALANDO E CONFIGURANDO NGINX INGRESS CONTROLLER ##
########################################################";
readonly INGRESS_NGINX_CHART_VERSION=4.5.2
readonly INGRESS_NGINX_NAMESPACE_NAME=ingress-nginx
helm upgrade \
  --install \
  --version $INGRESS_NGINX_CHART_VERSION \
  --namespace $INGRESS_NGINX_NAMESPACE_NAME \
  --create-namespace \
  --repo https://kubernetes.github.io/ingress-nginx ingress-nginx ingress-nginx \
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

    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        additionalLabels:
          release: prometheus

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

echo "#### WAITING INGRESS-NGINX INSTALATION ####";
kubectl wait \
  --namespace=$INGRESS_NGINX_NAMESPACE_NAME \
  --for=condition=ready pod \
  --selector='app.kubernetes.io/instance in(ingress-nginx)' \
  --timeout=-1s  # -1 = wait 1 week
