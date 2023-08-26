# Script kind cluster

### Objetivos
- automatizar a criação de um cluster kubernetes usando kind e oferencendo a possibilidade de instalar addons adicionais

### Pre requisitos
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/)
- linux

### Opções de criação
| opção 	                     | resultado                                                                                                                        | 
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| -k                           | cluster criado com Kindnet CNI(default)        |
| -k -c                        | cluster criado com [Cilium CNI](https://github.com/cilium/cilium) |
| -m                           | instalar [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)  |
| -l                           | instalar [Metallb](https://github.com/metallb/metallb)  |
| -i                           | instalar [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx)  |
| -p                           | instalar [Kube Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)  |

### Criando o cluster
``` bash
# download do arquivo para criação do cluster
$ curl -LO https://raw.githubusercontent.com/RafaelClaumann/some-kubernetes-study/main/kind_cluster.sh

# criar cluster sem addons usando Kindnet CNI(default) e outras opções
$ sh kind_cluster.sh -k [ options ]

# criar o cluster com Cilium CNI
$ sh kind_cluster.sh -k -c [ options ]

# instalar Metrics Server, Metallb, Nginx Ingress Controller e Prometheus Stack em um cluster existente 
$ sh kind_cluster.sh -m -l -i -p
```

### Resultado esperado
``` bash
# kubernetes ready nodes
$ kubectl get nodes -o wide     
  NAME                STATUS  ROLES          VERSION  INTERNAL-IP  EXTERNAL-IP  OS-IMAGE        CONTAINER-RUNTIME
  kind-control-plane  Ready   control-plane  v1.25.3  172.18.0.4   <none>       Ubuntu 22.04.1  containerd://1.6.9
  kind-worker         Ready   <none>         v1.25.3  172.18.0.2   <none>       Ubuntu 22.04.1  containerd://1.6.9
  kind-worker2        Ready   <none>         v1.25.3  172.18.0.3   <none>       Ubuntu 22.04.1  containerd://1.6.9

# helm charts instalados
$ helm list --all-namespaces  
  NAME            NAMESPACE       REVISION  UPDATED                         STATUS
  metal-lb        metallb-system  1         metallb-0.13.10                 v0.13.10
  metrics         metrics-server  1         metrics-server-3.8.4            0.6.2
  nginx           ingress         3         ingress-nginx-4.7.1             1.8.1
  prometheus      monitoring      3         kube-prometheus-stack-48.4.0    v0.66.0

# grafana acessivel via Service NodePort
$ curl 172.18.0.2:30000
  <a href="/grafana/login">Found</a>

# grafana acessivel via Ingress
$ curl localhost/grafana
  <a href="/grafana/login">Found</a>

# validando do nginx
# https://kind.sigs.k8s.io/docs/user/ingress/#using-ingress
$ kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

$ curl localhost/foo/hostname
  foo-app

$ curl localhost/bar/hostname
  bar-app

$ kubectl delete -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
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
