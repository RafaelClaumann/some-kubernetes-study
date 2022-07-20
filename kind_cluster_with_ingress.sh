#!/bin/bash
echo "## INICIANDO INSTALACAO DO CLUSTER  ##";
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster 
  nodes:
    - role: control-plane
      image: kindest/node:v1.22.9@sha256:8135260b959dfe320206eb36b3aeda9cffcb262f4b44cda6b33f7bb73f453105
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
          protocol: TCP
        - containerPort: 80
          hostPort: 80
          protocol: TCP
        - containerPort: 443
          hostPort: 443
          protocol: TCP
    - role: worker
      image: kindest/node:v1.22.9@sha256:8135260b959dfe320206eb36b3aeda9cffcb262f4b44cda6b33f7bb73f453105
    - role: worker
      image: kindest/node:v1.22.9@sha256:8135260b959dfe320206eb36b3aeda9cffcb262f4b44cda6b33f7bb73f453105
  networking:
    disableDefaultCNI: true
    kubeProxyMode: none
    podSubnet: "10.244.0.0/16"        # Configuracao para o Cilium
    serviceSubnet: "10.96.0.0/12"     # Configuracao para o Cilium
EOF

echo;
echo "## INSTALANDO E CONFIGURANDO CILIUM CNI";
readonly CILIUM_VERSION=1.11.5
docker pull quay.io/cilium/cilium:v$CILIUM_VERSION --quiet
kind load docker-image quay.io/cilium/cilium:v$CILIUM_VERSION --quiet
helm upgrade \
  --install \
  --version $CILIUM_VERSION \
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
kubectl wait \
  --namespace=kube-system \
  --for=condition=ready pod \
  --selector='k8s-app in(cilium, cilium-operator, kube-dns)' \
  --timeout=-1s  # -1 = wait 1 week

# https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster
# https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx
echo;
echo "## APLICANDO MANIFESTOS DO NGINX INGRESS CONTROLLER";
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait \
  --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=-1s  # -1 = wait 1 week
