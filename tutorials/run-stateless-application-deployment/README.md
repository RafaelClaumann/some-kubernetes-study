https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/

### Creating and exploring an nginx deployment

Criando dois `Pods` nginx 1.14.2 através de `Deployments` com `ReplicaSet`.
``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: nginx-deployment
spec:
    selector:
    matchLabels:
        app: nginx
    replicas: 2 # tells deployment to run 2 pods matching the template
    template:
      metadata:
        labels:
          app: nginx
    spec:
        containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
          - containerPort: 80
```

``` bash
## kubectl apply -f deployment.yaml
    deployment.apps/nginx-deployment created

## kubectl get deployments
	NAME               READY   UP-TO-DATE   AVAILABLE   AGE
	nginx-deployment   2/2     2            2           35s

## kubectl get pods -l app=nginx
	NAME                                READY   STATUS    RESTARTS   AGE
	nginx-deployment-66b6c48dd5-bjsxv   1/1     Running   0          73s
	nginx-deployment-66b6c48dd5-wscjf   1/1     Running   0          73s

## kubectl describe deployments nginx-deployment
	Name:                   nginx-deployment
	Namespace:              develop
	CreationTimestamp:      Fri, 15 Apr 2022 14:58:34 -0300
	Labels:                 <none>
	Annotations:            deployment.kubernetes.io/revision: 1
	Selector:               app=nginx
	Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
	(...)
	Pod Template:
	  Labels:  app=nginx
	  Containers:
	   nginx:
	    Image:        nginx:1.14.2
	(...)

## kubectl describe pods nginx-deployment-66b6c48dd5-bjsxv
	Name:         nginx-deployment-66b6c48dd5-bjsxv
	Namespace:    develop
	Priority:     0
	Node:         descomplicando-worker/172.18.0.4
	Start Time:   Fri, 15 Apr 2022 14:58:34 -0300
	Labels:       app=nginx
	              pod-template-hash=66b6c48dd5
	(...)
	Containers:
	  nginx:
	    Container ID:   containerd://21e4f3edca6fe24cd66ea42ce16f10480f3ee382c9888fd85a24c4c76f8116ad
	    Image:          nginx:1.14.2
	(...)
```

### Updating the deployment
É possível atualizar o deployment aplicando um novo arquivo yaml cujas propriedades especifiquem o nome de um `Deployment` existente e o label correto no `Selector`, isto não anula a possibilidade de editar o arquivo existente.

``` yaml
# (...)
spec:
    containers:
    - name: nginx
    image: nginx:1.16.1 # Update the version of nginx from 1.14.2 to 1.16.1
    ports:
    - containerPort: 80
# (...)
```


``` bash
## kubectl apply -f deployment.yaml
    deployment.apps/nginx-deployment configured

## kubectl describe deployments nginx-deployment
	Name:                   nginx-deployment
	Namespace:              develop
	CreationTimestamp:      Fri, 15 Apr 2022 14:58:34 -0300
	Labels:                 <none>
	Annotations:            deployment.kubernetes.io/revision: 2
	Selector:               app=nginx
	Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
	(...)
	Pod Template:
	  Labels:  app=nginx
	  Containers:
	   nginx:
	    Image:        nginx:1.16.1
	 (...)

## kubectl get pods -l app=nginx
	NAME                                READY   STATUS    RESTARTS   AGE
	nginx-deployment-559d658b74-b6ncp   1/1     Running   0          3m46s
	nginx-deployment-559d658b74-fk9h9   1/1     Running   0          4m7s

## kubectl describe pods nginx-deployment-559d658b74-b6ncp
	Name:         nginx-deployment-559d658b74-b6ncp
	Namespace:    develop
	Priority:     0
	Node:         descomplicando-worker/172.18.0.4
	Start Time:   Fri, 15 Apr 2022 15:06:30 -0300
	Labels:       app=nginx
	              pod-template-hash=559d658b74
	(...)
	Containers:
	  nginx:
	    Container ID:   containerd://a16b91351af725f4dea9625205d2f547722c9b153ecf4f54a58fb27671b414a8
	    Image:          nginx:1.16.1
	(...)
```

### Scaling the application by increasing the replica count
You can increase the number of Pods in your Deployment by applying a new YAML file. This YAML file sets replicas to 4, which specifies that the Deployment should have four Pods:

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: nginx-deployment
spec:
    selector:
      matchLabels:
        app: nginx
    replicas: 4 # Update the replicas from 2 to 4
    # (...)
```


``` bash
## kubectl get pods -l app=nginx
	NAME                                READY   STATUS    RESTARTS   AGE
	nginx-deployment-559d658b74-b6ncp   1/1     Running   0          7m
	nginx-deployment-559d658b74-fk9h9   1/1     Running   0          7m21s

## kubectl apply -f deployment.yaml
	deployment.apps/nginx-deployment configured

## kubectl get pods -l app=nginx
	NAME                                READY   STATUS              RESTARTS   AGE
	nginx-deployment-559d658b74-2mnlr   0/1     ContainerCreating   0          1s
	nginx-deployment-559d658b74-b6ncp   1/1     Running             0          10m
	nginx-deployment-559d658b74-fk9h9   1/1     Running             0          10m
	nginx-deployment-559d658b74-xf9p6   0/1     ContainerCreating   0          1s

## kubectl get pods -l app=nginx
	NAME                                READY   STATUS    RESTARTS   AGE
	nginx-deployment-559d658b74-2mnlr   1/1     Running   0          37s
	nginx-deployment-559d658b74-b6ncp   1/1     Running   0          11m
	nginx-deployment-559d658b74-fk9h9   1/1     Running   0          11m
	nginx-deployment-559d658b74-xf9p6   1/1     Running   0          37s

## kubectl delete deployment nginx-deployment
	deployment.apps "nginx-deployment" deleted
```

### Observações

Quando o label informado no `Selector` é diferente ou não existe nos labels do `Metadata` no `Template` do container ocorre um erro e o `Deployment` não é criado.

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
    app: nginx
replicas: 5 # tells deployment to run 4 pods matching the template
template:
    metadata:
      labels:
        app: nginxx
    spec:
      containers:
    (...)
```        

`kubectl apply -f deployment2.yaml`
``` bash
    The Deployment "nginx-deployment" is invalid: spec.template.metadata.labels: Invalid value: map[string]string{"app":"nginxx"}: `selector` does not match template `labels`
```

- Criar um deployment chamado `nginx-deployment` com versão 1.14.2 e label app=nginx
- Validar os pods e deployment garantindo a versao 1.14.2 e label app=nginx
- Criar um deployment chamado `nginx-deployment-dois` com versão 1.16.1 e label app=nginx
- Validar os pods e deployment garantindo a versao 1.16.1 e label app=nginx
- Garantir que os pods do `nginx-deployment` não foram alterados

De acordo com as tentativas abaixo `pods` de diferentes `Deployments` podem possuir o mesmo `Label` e é possível aplicar atualizações a estes pods sem que haja alteração nos pods do deployment vizinho que possuem o mesmo label.

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 5 # tells deployment to run 5 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```        

``` bash
## kubectl apply -f deployment_1.14.2.yaml
    deployment.apps/nginx-deployment created

## kubectl get deployments,pods
    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-deployment   5/5     5            5           12s

    NAME                                    READY   STATUS    RESTARTS   AGE
    pod/nginx-deployment-66b6c48dd5-2c6s7   1/1     Running   0          12s
    pod/nginx-deployment-66b6c48dd5-84wfb   1/1     Running   0          12s
    pod/nginx-deployment-66b6c48dd5-bqmxv   1/1     Running   0          12s
    pod/nginx-deployment-66b6c48dd5-hnxxp   1/1     Running   0          12s
    pod/nginx-deployment-66b6c48dd5-pgz2v   1/1     Running   0          12s

## kubectl describe deployments nginx-deployment
    Name:                   nginx-deployment
    Namespace:              develop
    Pod Template:
    Labels:  app=nginx
    Containers:
    nginx:
        Image:        nginx:1.14.2

## kubectl describe pods nginx-deployment-66b6c48dd5-2c6s7
    Name:         nginx-deployment-66b6c48dd5-2c6s7
    Namespace:    develop
    Labels:       app=nginx
                pod-template-hash=66b6c48dd5
    Controlled By:  ReplicaSet/nginx-deployment-66b6c48dd5
    Containers:
    nginx:
        Container ID:   containerd://2c7979baa0283d00cf2ad7763a818a59b4df3d4d23890feb4f5f3180af99c387
        Image:          nginx:1.14.2
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-dois
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 5 # tells deployment to run 5 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.16.1
        ports:
        - containerPort: 80
```        

``` bash
## kubectl apply -f deployment_1.16.1.yaml
    deployment.apps/nginx-deployment-dois created`

## Agora ele lista todos os clusters dos dois deployments no namespace `develop`
## kubectl get deployments,pods
    NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-deployment        5/5     5            5           4m20s
    deployment.apps/nginx-deployment-dois   5/5     5            5           22s

    NAME                                         READY   STATUS    RESTARTS   AGE
    pod/nginx-deployment-66b6c48dd5-2c6s7        1/1     Running   0          4m20s
    pod/nginx-deployment-66b6c48dd5-84wfb        1/1     Running   0          4m20s
    pod/nginx-deployment-66b6c48dd5-bqmxv        1/1     Running   0          4m20s
    pod/nginx-deployment-66b6c48dd5-hnxxp        1/1     Running   0          4m20s
    pod/nginx-deployment-66b6c48dd5-pgz2v        1/1     Running   0          4m20s
    pod/nginx-deployment-dois-559d658b74-56svs   1/1     Running   0          21s
    pod/nginx-deployment-dois-559d658b74-8w66b   1/1     Running   0          21s
    pod/nginx-deployment-dois-559d658b74-fd9v8   1/1     Running   0          21s
    pod/nginx-deployment-dois-559d658b74-gv8lr   1/1     Running   0          22s
    pod/nginx-deployment-dois-559d658b74-qhh59   1/1     Running   0          21s

## kubectl describe deployments nginx-deployment-dois
    Name:                   nginx-deployment-dois
    Namespace:              develop
    Pod Template:
    Labels:  app=nginx
    Containers:
    nginx:
        Image:        nginx:1.16.1

## kubectl describe pods nginx-deployment-dois-559d658b74-56svs
    Name:         nginx-deployment-dois-559d658b74-56svs
    Namespace:    develop
    Labels:       app=nginx
                pod-template-hash=559d658b74
    Controlled By:  ReplicaSet/nginx-deployment-dois-559d658b74
    Containers:
    nginx:
        Container ID:   containerd://e10e1eff7db7550c1d29277cada8b0d47df945596dfd8356d5b0ff3991ab35d4
        Image:          nginx:1.16.1

## pod do nginx-deployment manteve-se inalterado, como esperado.
## kubectl describe pods nginx-deployment-66b6c48dd5-2c6s7
    Name:         nginx-deployment-66b6c48dd5-2c6s7
    Namespace:    develop
    Labels:       app=nginx
                pod-template-hash=66b6c48dd5
    Controlled By:  ReplicaSet/nginx-deployment-66b6c48dd5
    Containers:
    nginx:
        Container ID:   containerd://2c7979baa0283d00cf2ad7763a818a59b4df3d4d23890feb4f5f3180af99c387
        Image:          nginx:1.14.2
```
