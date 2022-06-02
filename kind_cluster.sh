#! /bin/bash
echo "
  #################################
  # STARTING CLUSTER INSTALATION  #
  #################################
";
kind create cluster -v=1 --config - <<EOF
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
echo "
  ##################################
  # STARTING CLUSTER CONFIGURATION #
  ##################################
";
##################################################################################
####        CONFIGURACAO DO KUBE-SCHEDULER E KUBE-CONTROLLER MANAGER          ####
####  https://stackoverflow.com/questions/54608441/kubectl-connectivity-issue ####
##################################################################################
echo "CONFIGURANDO KUBE-SCHEDULER E KUBE-CONTROLLER-MANAGER";
echo "ALTERAÇOES SENDO REALIZADAS NO CONTAINER($CONTROL_PLANE_CONTAINER_ID) CONTROL PLANE";

readonly CONTROL_PLANE_CONTAINER_ID=$(docker container ls -f NAME=kind-control-plane --quiet);
docker exec $CONTROL_PLANE_CONTAINER_ID sed -i "s/- --port=0/#- --port=0/g" /etc/kubernetes/manifests/kube-scheduler.yaml
docker exec $CONTROL_PLANE_CONTAINER_ID sed -i "s/- --port=0/#- --port=0/g" /etc/kubernetes/manifests/kube-controller-manager.yaml
docker exec $CONTROL_PLANE_CONTAINER_ID systemctl restart kubelet.service

echo "COMENTANDO --PORT DE /ETC/KUBERNETES/MANIFESTES/KUBE-SCHEDULER.YAML";
docker exec $CONTROL_PLANE_CONTAINER_ID cat etc/kubernetes/manifests/kube-scheduler.yaml | grep -B 2 -A 2 -i "\-\-port"

echo "COMENTANDO --PORT DE /ETC/KUBERNETES/MANIFESTS/KUBE-CONTROLLER-MANAGER.YAML";
docker exec $CONTROL_PLANE_CONTAINER_ID cat etc/kubernetes/manifests/kube-controller-manager.yaml | grep -B 2 -A 2 -i "\-\-port"

sleep 5;
echo " INSTALANDO E CONFIGURANDO CILIUM CNI $CILIUM_VERSION";
readonly CILIUM_VERSION=1.11.4

echo "PRE-LOADING CILIUM DOCKER IMAGES TO KIND NODES";
docker pull quay.io/cilium/cilium:v$CILIUM_VERSION
kind load docker-image quay.io/cilium/cilium:v$CILIUM_VERSION

echo "INSTALLING CILIUM $CILIUM_VERSION THROUGH HELM CHART";
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

sleep 5;
echo "
  #####################################
  # CLUSTER CONFIGURED WAIT 2 MINUTES #
  #   TO CILIUM FINISH INSTALATION    #
  #    OR CHECK PODS AT NAMESPACE     #
  #           KUBE-SYSTEM             #
  #####################################
";

echo;
echo "
  ################
  # CLUSTER INFO #
  ################
";
kubectl cluster-info;
# CLUSTER_PORT=$(kubectl cluster-info | grep -E -o "([0-9]{5})" | head -1);
