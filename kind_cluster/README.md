# Instalação kind cluster completo

## Pre requisitos
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/)
- linux

## O que tem no cluster
Três nodes(_1x control plane, 2x workers_) e alguns addons opcionais(_Cilium CNI, Metrics Server, Kube Prometheus Stack, Nginx Ingress Controller_).

## Opções de instalação
| opção 	                     | resultado                                                                                                                        | 
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| no-options                   | cluster sem addons                                                                                                               |
| -c  ou --cni| [cilium CNI](https://github.com/cilium/cilium), se usado, deve ser o primeiro parâmetro |
| -m  ou --metrics              | [metrics-server](https://github.com/kubernetes-sigs/metrics-server)  |
| -i  ou --ingress              | [nginx-ingress-controller](https://github.com/kubernetes/ingress-nginx)  |
| -p  ou --prometheus           | [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) com grafana via NodePort `http://<node-ip>:30000` |
| -pi ou --prometheus-ingress   | nginx-ingress-controller, kube-prometheus-stack e service-monitor-nginx com grafana via ingress `http://localhost/grafana` |

## Instalando o cluster
``` bash
# Arquivo para instalação: RafaelClaumann/some-kubernetes-study/blob/main/kind_cluster.sh
curl -LO https://raw.githubusercontent.com/RafaelClaumann/some-kubernetes-study/main/kind_cluster.sh

# cluster sem addons
sh kind_cluster.sh

# nginx-ingress-controller, kube-prometheus-stack e service-monitor-nginx
# grafana em http://localhost/grafana ou http://<node-ip>:30000
# atenção: o kube-prometheus-stack utiliza as métricas coletadas pelo metrics-server
sh kind_cluster.sh -pi

# cilium, metrics-server, nginx-ingress e kube-prometheus
# grafana em http://localhost/grafana ou http://<node-ip>:30000
sh kind_cluster.sh -c -m -i -p

# clium CNI, nginx-ingress-controller, kube-prometheus-stack e service-monitor-nginx
# grafana em http://localhost/grafana ou http://<node-ip>:30000
sh kind_cluster.sh -c -pi -m 
```

## Resultado esperado
- Estado dos nodes
``` bash
$kubectl get nodes -o wide     
  NAME                STATUS  ROLES          VERSION  INTERNAL-IP  EXTERNAL-IP  OS-IMAGE            CONTAINER-RUNTIME
  kind-control-plane  Ready   control-plane  v1.25.3  172.18.0.4   <none>       Ubuntu 22.04.1 LTS  containerd://1.6.9
  kind-worker         Ready   <none>         v1.25.3  172.18.0.2   <none>       Ubuntu 22.04.1 LTS  containerd://1.6.9
  kind-worker2        Ready   <none>         v1.25.3  172.18.0.3   <none>       Ubuntu 22.04.1 LTS  containerd://1.6.9
```
- Estado dos helm charts instalados
``` bash
$helm list --all-namespaces  
  NAME            NAMESPACE       REVISION  UPDATED           STATUS      CHART                          APP VERSION
  cilium          cilium          1         2023-03-10 18:56  deployed    cilium-1.13.0                  1.13.0     
  nginx           ingress         1         2023-03-10 19:01  deployed    ingress-nginx-4.5.2            1.6.4      
  metrics         metrics-server  1         2023-03-10 18:57  deployed    metrics-server-3.8.4           0.6.2      
  prometheus      monitoring      1         2023-03-10 18:58  deployed    kube-prometheus-stack-45.7.1   v0.63.0
```
- Validando grafana e nginx
``` bash
###
### Grafana acessível através de NodePort ou Ingress
curl 172.18.0.2:30000
  <a href="/grafana/login">Found</a>

curl localhost/grafana
  <a href="/grafana/login">Found</a>

###
### Teste do nginx utilizando o arquivo `validate_nginx_setup.yaml`
kubectl apply -f https://raw.githubusercontent.com/RafaelClaumann/some-kubernetes-study/main/validate_nginx_setup.yaml

curl localhost/foo/hostname
  foo-app

curl localhost/bar/hostname
  bar-app

kubectl delete -f https://raw.githubusercontent.com/RafaelClaumann/some-kubernetes-study/main/validate_nginx_setup.yaml
```

# Outras informações 

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
