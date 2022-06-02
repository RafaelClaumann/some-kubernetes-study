#! /bin/bash
echo "## INICIANDO INSTALACAO DO CLUSTER  ##";
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster 
  nodes:
    - role: control-plane
      image: kindest/node:v1.22.9@sha256:8135260b959dfe320206eb36b3aeda9cffcb262f4b44cda6b33f7bb73f453105
      extraPortMappings:
      - containerPort: 30500
        hostPort: 3500
        listenAddress: "127.0.0.1"
        protocol: tcp
      - containerPort: 30600
        hostPort: 3600
        listenAddress: "127.0.0.1"
        protocol: tcp
      - containerPort: 30700
        hostPort: 3700
        listenAddress: "127.0.0.1"
        protocol: tcp
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

sleep 5;
echo "## CONFIGURANDO KUBE-SCHEDULER E KUBE-CONTROLLER-MANAGER ##";
##################################################################################
####        CONFIGURACAO DO KUBE-SCHEDULER E KUBE-CONTROLLER MANAGER          ####
####  https://stackoverflow.com/questions/54608441/kubectl-connectivity-issue ####
#### https://github.com/kubernetes/kubeadm/issues/2207#issuecomment-666985459 ####
##################################################################################
readonly CONTROL_PLANE_CONTAINER_ID=$(docker container ls -f NAME=kind-control-plane --quiet);
docker exec $CONTROL_PLANE_CONTAINER_ID sed -i "s/- --port=0/#- --port=0/g" /etc/kubernetes/manifests/kube-scheduler.yaml
docker exec $CONTROL_PLANE_CONTAINER_ID sed -i "s/- --port=0/#- --port=0/g" /etc/kubernetes/manifests/kube-controller-manager.yaml
docker exec $CONTROL_PLANE_CONTAINER_ID systemctl restart kubelet.service

sleep 5;
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
EOF
