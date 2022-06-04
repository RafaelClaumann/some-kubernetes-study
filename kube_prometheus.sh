#!/bin/bash
# https://github.com/prometheus-operator/kube-prometheus
readonly INSTALL_DIR=kube-prometheus-instalation
readonly RELEASE_VERSION=0.9

echo "Clonando manifestos kube-prometheus - release ${RELEASE_VERSION}"
curl -LO https://github.com/prometheus-operator/kube-prometheus/archive/refs/heads/release-${RELEASE_VERSION}.zip

sleep 2
echo "Descompactando arquivos"
rm -r ${INSTALL_DIR} &>/dev/null
mkdir ${INSTALL_DIR}
unzip -q release-${RELEASE_VERSION}.zip
mv --force kube-prometheus-release-${RELEASE_VERSION}/manifests ${INSTALL_DIR}
rm -r release-${RELEASE_VERSION}.zip
rm -r kube-prometheus-release-${RELEASE_VERSION}

sleep 5
echo "Aplicando manifestos de /manifests/setup/"
kubectl apply -f ${INSTALL_DIR}/manifests/setup/ &>/dev/null

sleep 5
echo "Aplicando manifestos de /manifests/"
kubectl apply -f ${INSTALL_DIR}/manifests/ &>/dev/null

sleep 5
echo "Realizando patch em /manifests/grafana-service.yaml"
echo "grafana-service.yaml exposto via NodePort 30500"
echo "{\"spec\": {\"ports\": [{\"name\": \"http\" ,\"port\": 3000,\"targetPort\": \"http\",\"nodePort\":30500}],\"type\": \"NodePort\"}}";
kubectl patch \
 --namespace monitoring \
 service grafana \
  -p '{"spec": {"ports": [{"name": "http" ,"port": 3000,"targetPort": "http","nodePort":30500}],"type": "NodePort"}}' 
