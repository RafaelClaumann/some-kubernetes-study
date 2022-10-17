## Configurando RBAC

O objetivo é criar dois `Namespaces` com um `Pod` em cada namespace e listar os `Services` de ambos os namespaces através de requisições HTTP disparadas a partir dos Pods. <br>
Os Pods serão compostos por dois containers:
- `curl` para realizar as requisições HTTP.
- `alpine` terá a instalação do `kubectl` e executará o comando `kubectl proxy`. O comando fará o forward das requisições HTTP feitas em http://localhost:8001 para o API Server do cluster.
	- [kubectl proxy](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#proxy)
	- [using kubectl proxy](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#using-kubectl-proxy)
	- [proxies in kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/proxies/)


#### Criando `Pods` e `Namespaces`
``` bash
$kubectl apply -f namespace.yaml
  namespace/foo created

$kubectl create namespace bar
  namespace/bar created

$kubectl create -f pod.yaml --namespace foo
$kubectl create -f pod.yaml --namespace bar
```

#### Tentando Listar `Services`
``` bash
# Tentando listar os Services a partir do Pod no namespace `foo`.
# O mesmo resultado acontecerá ao tentar listar os Services no namesapace `bar`.
$kubectl exec -it my-pod -n foo -c curl  -- \
curl localhost:8001/api/v1/namespaces/foo/services
	{
	  "kind": "Status",
	  "apiVersion": "v1",
	  "metadata": {
	    
	  },
	  "status": "Failure",
	  "message":
				"services is forbidden:
				User system:serviceaccount:foo:default  cannot list resource
				services in API group \"\" in the namespace foo",
	  "reason": "Forbidden",
	  "details": {
	    "kind": "services"
	  },
	  "code": 403
	}
```

#### Criando Role
``` bash
# Criando `Role` para o Pod do namespace `foo`. (declarativo)
$kubectl apply -f role.yaml --namespace foo
  role.rbac.authorization.k8s.io/service-reader created

# Criando `Role` para os Pods do namespace `bar`. (imperativo)
$kubectl create role service-reader \
--verb=get \
--verb=list \
--resource=services \
--namesapace bar
```

#### Vinculando ServiceAccount e Role com RoleBinding
``` bash
# Vinculo entre Role e ServiceAccount no namespace foo através de uma RoleBinding. (declarativo)
$kubectl apply -f role_binding.yaml -n foo
  rolebinding.rbac.authorization.k8s.io/bind-service-reader created

# Vinculo entre Role e ServiceAccount no namespace bar através de uma RoleBinding. (imperativo)
$kubectl create rolebinding bind-service-reader \
--role=service-reader \
--serviceaccount=bar:default \
--namespace=bar
```

#### Resultado Final: Listando Services
``` bash
# Listando Services no namespace `foo` após o vinculo entre Role e ServiceAccount.
$kubectl exec -it my-pod -n foo -c curl  -- \
curl localhost:8001/api/v1/namespaces/foo/services
	{
	  "kind": "ServiceList",
	  "apiVersion": "v1",
	  "metadata": {
	    "resourceVersion": "13724"
	  },
	  "items": []
	}

# Listando Services no namespace `foo` após o vinculo entre Role e ServiceAccount.
$kubectl exec -it my-pod -n bar -c curl  -- \
curl localhost:8001/api/v1/namespaces/bar/services
  {
    "kind": "ServiceList",
    "apiVersion": "v1",
    "metadata": {
      "resourceVersion": "14424"
    },
    "items": []
  }
```
