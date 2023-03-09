# Uso de Extra Port Mappings no Kind

Durante a leitura da documentação do `kind` encontrei o trecho abaixo que trata das `extra port mappings`:
```txt
If you are running Docker without the Docker Desktop Application on Linux, you can simply send traffic to the node IPs from the host without extra port mappings.

https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings
```

Sempre utilizei `extra port mappings` para acessar `Services` do tipo `NodePort` criados no cluster, mas após a leitura da documentação decidi tentar remover as `extra port mappings`.

Um ponto positivo ao uso de `extra port mappings` é a possibilidade de acessar o `Service` sem conhecer o(s) endereço(s) IP dos `Nodes`, basta acessar `localhost:hostPort`.


## Diferença na Criação do Cluster
```bash
# TEMPLATE_CLUSTER_COM_EXTRA_PORT_MAPPINGS
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster 
  nodes:
    - role: control-plane
      extraPortMappings:
        - containerPort: 32500            # nodePort exposta pelo Service do tipo NodePort
          hostPort: 2500                  # porta para acessar o Service em localhost
          listenAddress: "127.0.0.1"
          protocol: tcp
    - role: worker
    - role: worker
EOF

# TEMPLATE_CLUSTER_SEM_EXTRA_PORT_MAPPINGS
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster
  nodes:
      - role: control-plane
      - role: worker
      - role: worker
EOF
```

## Validando Acesso **com e sem** Extra Port Mappings

### 1 - Criando o cluster
```bash
kind create cluster --config - <<EOF
  apiVersion: kind.x-k8s.io/v1alpha4
  kind: Cluster
  nodes:
      - role: control-plane
        extraPortMappings:
          - containerPort: 32500
            hostPort: 2500
            listenAddress: "127.0.0.1"
            protocol: tcp      
      - role: worker
      - role: worker
EOF
```

### 2 - Aplicando o manifesto para criação dos `Services` e `Pod`
```yaml
# https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/#ServiceSpec
# https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
# SERVICE_SEM_EXTRA_PORT_MAPPINGS
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service-1
spec:
  type: NodePort
  selector:
    app: http-echo-pod  
  ports:
    - name: no-extra-port-mappings
      nodePort: 30500
      port: 3000
      targetPort: 3500
      protocol: TCP

--- 

# SERVICE_USANDO_EXTRA_PORT_MAPPINGS
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service-2
spec:
  type: NodePort
  selector:
    app: http-echo-pod  
  ports:
    - name: with-extra-port-mappings
      nodePort: 32500
      port: 2900
      targetPort: 3500
      protocol: TCP      

---

# https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports
# https://github.com/hashicorp/http-echo
apiVersion: v1
kind: Pod
metadata:
  name: http-echo
  labels:
    app: http-echo-pod
spec:
  containers:
    - name: http-echo-container
      image: hashicorp/http-echo
      args:
        - --listen=:3500
        - -text=hello-world
      ports:
        - name: http-echo-port
          containerPort: 3500
          protocol: TCP
  restartPolicy: Always
```

### 3 - Validando as chamadas para os `Services` usando o endereço IP dos `Nodes` e `localhost`
```bash
$kubectl get nodes -o wide 
  NAME                 ROLES           VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE
  kind-control-plane   control-plane   v1.25.3   172.18.0.4    <none>        Ubuntu 22.04.1 LTS
  kind-worker          <none>          v1.25.3   172.18.0.2    <none>        Ubuntu 22.04.1 LTS
  kind-worker2         <none>          v1.25.3   172.18.0.3    <none>        Ubuntu 22.04.1 LTS

$kubectl apply -f manifest.yaml                          
  service/nodeport-service-1 created
  service/nodeport-service-2 created
  pod/http-echo created

$kubectl get all -o wide --show-labels
  NAME            READY   STATUS    IP           NODE          LABELS
  pod/http-echo   1/1     Running   10.244.2.2   kind-worker   app=http-echo-pod

  NAME                        TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)         SELECTOR
  service/nodeport-service-1  NodePort   10.96.97.165  <none>       3000:30500/TCP  app=http-echo-pod
  service/nodeport-service-2  NodePort   10.96.7.65    <none>       2900:32500/TCP  app=http-echo-pod

#### TESTANDO_SERVICE_SEM_EXTRA_PORT_MAPPINGS
$curl 172.18.0.2:30500 && curl 172.18.0.3:30500 && curl 172.18.0.4:30500
  hello-world
  hello-world
  hello-world

#### TESTANDO_SERVICE_COM_EXTRA_PORT_MAPPINGS
$curl 172.18.0.2:32500 && curl 172.18.0.3:32500 && curl 172.18.0.4:32500
  hello-world
  hello-world
  hello-world

$curl localhost:2500  # porta mapeada no manifesto do cluster
  hello-world
```