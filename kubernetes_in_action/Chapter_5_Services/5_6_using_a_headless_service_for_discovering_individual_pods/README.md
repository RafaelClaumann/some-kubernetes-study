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

  Name:   my-headless-svc.default.svc.cluster.local
  Address: 10.111.58.133
```

##### Headless Service (`clusterIP: None`)
``` bash
# FQDN: <svc-name>.<namespace>.svc.cluster.local
# return Service Pods addresses
kubectl run --rm -it dnsutils \
--image=tutum/dnsutils \       ```
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
