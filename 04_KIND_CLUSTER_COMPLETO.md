# Instalando Kind Cluster Completo

### 📌 O que tem no cluster
- Três nodes, um control-plane e dois workers
- Cilium CNI
- Metrics Server
- Kube Prometheus Stack
- Nginx Ingress Controller

### 📌 Como criar o cluster
``` bash
curl -LO https://raw.githubusercontent.com/RafaelClaumann/some-kubernetes-study/main/kind_cluster_completo.sh

sh kind_cluster_completo.sh
```

### 📌 Comentarios e links importantes 

#### Kind
- Onde encontrar o SHA1 das imagens do Kubernetes pro kind? - [link](https://github.com/kubernetes-sigs/kind/releases/tag/v0.17.0)
- Porque usar `Extra Port Mappings` nas portas 433 e 80? - [link](https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster)
- Porque usar essas configurações de `networking`? - [link](https://medium.com/@charled.breteche/kind-cluster-with-cilium-and-no-kube-proxy-c6f4d84b5a9d)

#### Cilium
- Matriz de compatibilidade Cilium x Kubernetes - [link](https://docs.cilium.io/en/stable/network/kubernetes/compatibility/)
- Guia de Instalação Medium - [link](https://medium.com/@charled.breteche/kind-cluster-with-cilium-and-no-kube-proxy-c6f4d84b5a9d)
- Guia de instalção documentação oficial - [link](https://docs.cilium.io/en/stable/installation/k8s-install-helm/)
- Repositório com os charts do Cilium - [link](https://quay.io/repository/cilium/cilium?tab=tags&tag=latest)
- Quais são os valores possíveis na configuração do chart? - [link](https://github.com/cilium/cilium/blob/master/install/kubernetes/cilium/values.yaml)

#### Metrics Server
- Matriz de compatibilidade Metrics Server x Kubernetes - [link](https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix)
- Porque usar a flag `--kubelet-insecure-tls` ? - [link01](https://github.com/kubernetes-sigs/kind/issues/398#issuecomment-478311167) [link02](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#configuration)
- Quais são os valores possíveis na configuração do chart? - [link](https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/values.yaml)

#### Kube Prometheus Stack
- Ausencia de matriz de compatibilidade Kube Prometheus x Kubernetes - [link](https://github.com/prometheus-community/helm-charts/issues/97)
- Configurações para coletar metricas do Nginx Ingress Controller - [link](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#configure-prometheus)
``` yaml
prometheus:
  prometheusSpec:
    podMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
```
- Comando rápido para fazer um Port Forward e acessar o Grafana em `localhost:3000`
``` bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n prometheus
```
- Porque fazer um `kubectl patch` no Service `prometheus-grafana`? Com essa alteração  é possível acessar o Grafana através do endereço IP de qualquer node cluster e porta sem a necessidade do comando `port-forward`.

#### Nginx Ingress Controller
- Matriz de compatibilidade Nginx Ingress Controller x Kubernetes - [link](https://github.com/kubernetes/ingress-nginx#supported-versions-table)
- Guia de instalação Nginx Ingress Controller documentação oficial - [link](https://kubernetes.github.io/ingress-nginx/deploy/)
- Documentação do Kind incentiva a instalação do Nginx usando manifestos ao invés de helm chart - [link](https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx)
- Erro observado ao instalar o Nginx via helm chart sem valores customizados - [link](https://sam-thomas.medium.com/kubernetes-ingressclass-error-ingress-does-not-contain-a-valid-ingressclass-78aab72c15a6)
- Quais valores customizados utilizar no helm chart para que o Nginx funcione? - [link01](https://github.com/kubernetes-sigs/kind/issues/1693#issuecomment-1166157946) [link02](https://github.com/kubernetes/ingress-nginx/blob/main/hack/manifest-templates/provider/kind/values.yaml)
- Configuraçao para a coleta de metricas - [link](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#re-configure-nginx-ingress-controller)
``` yaml
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: prometheus  # deve ser igual ao nome ao release do chart kube-prometheus-stack
```
- Quais são os valores possíveis na configuração do chart? - [link01-kind](https://github.com/kubernetes/ingress-nginx/blob/main/hack/manifest-templates/provider/kind/values.yaml) [link02-geral](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml)
