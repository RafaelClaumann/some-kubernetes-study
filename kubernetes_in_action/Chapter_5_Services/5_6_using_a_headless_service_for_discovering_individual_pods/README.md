#### Comparing ClusterIP x Headless Service nslookup

##### Normal ClusterIP Service
``` bash
# FQDN: <svc-name>.<namespace>.svc.cluster.local
# returns only Service ClusterIP address
kubectl run --rm -it dnsutils \
--image=tutum/dnsutils \
--restart=Never \
-- nslookup my-svc

  Server:         10.96.0.10
  Address:        10.96.0.10#53

  Name:   my-svc.default.svc.cluster.local
  Address: 10.111.58.133
```

##### Headless Service (`clusterIP: None`)
``` bash
# FQDN: <svc-name>.<namespace>.svc.cluster.local
# return Service Pods addresses
kubectl run --rm -it dnsutils \
--image=tutum/dnsutils \ 
--restart=Never \
-- nslookup my-headless-svc

  Server:         10.96.0.10
  Address:        10.96.0.10#53
  
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.1.110
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.1.181
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.1.142
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.2.118
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.2.148
```

##### Headless Service (`clusterIP: None`) with `publishNotReadyAddresses`
``` bash
# current Pods status, no one is READY
kubectl get pods,svc -o wide
	NAME                  READY   STATUS    IP             NODE
	pod/my-deploy-ggkl9   0/1     Running   10.244.1.52    kind-worker
	pod/my-deploy-hx5lt   0/1     Running   10.244.2.252   kind-worker2
	pod/my-deploy-sblj2   0/1     Running   10.244.1.97    kind-worker

	NAME                      TYPE        CLUSTER-IP  PORT(S)   SELECTOR
	service/my-headless-svc   ClusterIP   None        8080/TCP  app=my-app

# FQDN: <svc-name>.<namespace>.svc.cluster.local
# return Service Pods addresses including not READY Pods
kubectl run --rm -it dnsutils \
--image=tutum/dnsutils \ 
--restart=Never \
-- nslookup my-headless-svc

  Server:         10.96.0.10
  Address:        10.96.0.10#53
  
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.1.52
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.2.252 
  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.244.1.97
```
