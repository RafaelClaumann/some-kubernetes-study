# Instalando Kind Cluster Completo

### 📌 Pre requisitos
- kind
- kubectl
- helm

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
- Ausencia de matriz da compatibilidade Kube Prometheus Stack x Kubernetes - [link](https://github.com/prometheus-community/helm-charts/issues/97)
- Configurações para coletar as metricas do Nginx Ingress Controller - [link](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#configure-prometheus)
``` yaml
# helm chart values
prometheus:
  prometheusSpec:
    podMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
```
- Comando rápido para fazer um Port Forward e testar o acesso ao Grafana em `localhost:3000`
``` bash
$kubectl port-forward svc/prometheus-grafana 3000:80 -n prometheus
```
- Acessando Grafana através do Service NodePort após execução do comando `kubectl patch`
``` bash
$curl 172.18.0.2:30000
  <a href="/grafana/login">Found</a>.

$curl 172.18.0.3:30000
  <a href="/grafana/login">Found</a>.

$curl 172.18.0.4:30000
  <a href="/grafana/login">Found</a>.
```
- Configurações para expor o Grafana através do Nginx Ingress Controller - [link](https://fabianlee.org/2022/07/02/prometheus-exposing-prometheus-grafana-as-ingress-for-kube-prometheus-stack/)
``` yaml
# helm chart values 
  grafana:
    env:
      GF_SERVER_ROOT_URL: "http://cluster.com/grafana"
      GF_SERVER_SERVE_FROM_SUB_PATH: "true"
    ingress:
      enabled: "true"
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: "/\$2"  # https://kubernetes.github.io/ingress-nginx/examples/rewrite/#rewrite-target
      hosts: ["cluster.com"]
      path: "/grafana(/|$)(.*)"      
```
``` bash
$kubectl get nodes -o wide
  NAME                 ROLES           VERSION   INTERNAL-IP
  kind-control-plane   control-plane   v1.25.3   172.18.0.3    # adicionar ip do node ao /etc/hosts
  kind-worker          <none>          v1.25.3   172.18.0.2    # adicionar ip do node ao /etc/hosts
  kind-worker2         <none>          v1.25.3   172.18.0.4    # adicionar ip do node ao /etc/hosts

$cat /etc/hosts                                                                                               
  # Host addresses
  172.18.0.2 my-cluster.com   # ip do node /etc/hosts ! se o ip mudar sera preciso ajustar
  172.18.0.3 my-cluster.com   # ip do node /etc/hosts ! se o ip mudar sera preciso ajustar
  172.18.0.4 my-cluster.com   # ip do node /etc/hosts ! se o ip mudar sera preciso ajustar

  127.0.0.1  localhost
  127.0.1.1  rafael-nitroan51544
  ::1        localhost ip6-localhost ip6-loopback
  ff02::1    ip6-allnodes
  ff02::2    ip6-allrouters

# Acessando através do nginx
$curl cluster.com/grafana  
  <a href="/grafana/login">Found</a>.
```

#### Nginx Ingress Controller
- Matriz de compatibilidade Nginx Ingress Controller x Kubernetes - [link](https://github.com/kubernetes/ingress-nginx#supported-versions-table)
- Guia de instalação Nginx Ingress Controller documentação oficial - [link](https://kubernetes.github.io/ingress-nginx/deploy/)
- Documentação do Kind incentiva a instalação do Nginx usando manifestos ao invés de helm chart - [link](https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx)
- Erro observado ao instalar o Nginx via helm chart sem valores customizados - [link](https://sam-thomas.medium.com/kubernetes-ingressclass-error-ingress-does-not-contain-a-valid-ingressclass-78aab72c15a6)
- Quais valores customizados utilizar no helm chart para que o Nginx funcione? - [link01](https://github.com/kubernetes-sigs/kind/issues/1693#issuecomment-1166157946) [link02](https://github.com/kubernetes/ingress-nginx/blob/main/hack/manifest-templates/provider/kind/values.yaml)
- Configuraçao para a coleta de metricas - [link](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#re-configure-nginx-ingress-controller)
``` yaml
# helm chart values
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: prometheus  # deve ser igual ao nome ao release do chart kube-prometheus-stack
```
- Quais são os valores possíveis na configuração do chart? - [link01-kind](https://github.com/kubernetes/ingress-nginx/blob/main/hack/manifest-templates/provider/kind/values.yaml) [link02-geral](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml)
