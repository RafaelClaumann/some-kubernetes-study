## Configurando RBAC
O objetivo é criar dois `Pods`, dois `Namespaces` e listar os `Services` presentes nesses namespaces a partir de requisições HTTP para o `API Server`.

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
# Tentando listar Services no `foo`.
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
					"services is forbidden: User 
					\"system:serviceaccount:foo:default\" 
					cannot list resource \"services\" in
					API group \"\" in the namespace \"foo\"",
	  "reason": "Forbidden",
	  "details": {
	    "kind": "services"
	  },
	  "code": 403
	}
```

#### Criando Role
``` bash
# Opcao-01(declarativa) usando manifesto yaml.
# Criando `Role` para os Pods do namespace `foo`.
$kubectl apply -f role.yaml --namespace foo
  role.rbac.authorization.k8s.io/service-reader created

# Opcao-02(imperativa) usando comando.
# Criando `Role` para os Pods do namespace `bar`.
$kubectl create role service-reader \
--verb=get \
--verb=list \
--resource=services \
--namesapace bar
```

#### Vinculando ServiceAccount e Role com RoleBinding
``` bash
# Opcao-01(declarativa) usando manifesto yaml.
# Realizando vinculo entre `Role` e `ServiceAccount` no namespace `foo` através de uma `RoleBinding`.
$kubectl apply -f role_binding.yaml -n foo
  rolebinding.rbac.authorization.k8s.io/bind-service-reader created

# Opcao-02(imperativa) usando comando.
# Realizando vinculo entre `Role` e `ServiceAccount` no namespace `bar` através de uma `RoleBinding`.
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
