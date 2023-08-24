# Nginx Ingress Controller com TLS

## Configurar arquivo _/etc/hosts_
#### Cluster kind com metallb e Service nginx do tipo LoadBalancer
``` shell
# endereço IP do Service ingress controller do namespace ingress
export ingress_addr=kubectl get svc -n ingress -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'
echo "$ingress_addr example.com" | tr -d '"' | sudo tee -a /etc/hosts
```

#### Cluster kind sem metallb e Service nginx do tipo NodePort
``` shell
# endereço IP do container control-plane
export ip_address=$(\
    docker container inspect \
    $(docker container ls --filter name=".*-control-plane" --quiet) \
    --format "{{json .NetworkSettings.Networks.kind.IPAddress}}"
    )
echo "$ip_address example.com" | tr -d '"' | sudo tee -a /etc/hosts
```

#### Exemplo _/etc/hosts_
``` shell
cat /etc/hosts
    127.0.0.1  localhost
    127.0.1.1  rafael-nitroan51544
    ::1        localhost ip6-localhost ip6-loopback
    ff02::1    ip6-allnodes
    ff02::2    ip6-allrouters

    172.19.255.200 example.com
    172.19.255.200 test.com
```

## Criar certificado assinado e chave privada
``` shell
# gerando certificado
openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout tls.key \
    -out tls.crt \
    -subj "/CN=o.que.importa.eh.subjectaltname.com /O=another.cn.com" \
    -addext "subjectAltName=DNS:example.com, DNS:test.com"

# verificando estrutura do certificado:
openssl x509 -noout -text -in tls.crt  
    Certificate:
        Data:
            Signature Algorithm: ...
            Issuer: CN = example.com, O = another.cn.com
            Subject: CN = example.com, O = another.cn.com
            Subject Public Key Info:
                Public Key Algorithm: ...
                ...
            X509v3 extensions:
                ...
                X509v3 Subject Alternative Name: 
                    DNS:example.com, DNS:test.com
```

## Criar Secret para armazenar certificado e chave privada
``` shell
    kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

## Aplicar arquivo deploy
``` shell
    kubectl apply -f deploy.yaml
```

## Validar chamadas HTTP e HTTPS
``` shell
curl --cacert tls.crt https://example.com/foo/hostname
    foo-app

curl --cacert tls.crt https://example.com/bar/hostname
    <html>
    <head><title>404 Not Found</title></head>
    <body>
    </html>

curl --cacert tls.crt https://example.test.com/bar/hostname
    bar-app

curl --cacert tls.crt https://test.com/foo/hostname
    <html>
    <head><title>404 Not Found</title></head>
    </html>    
```

## Links

- Nginx Ingress Controller Kind - [link](https://kind.sigs.k8s.io/docs/user/ingress/)
- Metallb Kind - [link](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
- Kubernetes in Action - Capitulo 5 Services - [link](https://rafaelclaumann.notion.site/Chapter-5-Services-enabling-clients-to-discover-and-talk-to-pods-68a9fb7cfd9143b6bd93afc8dc0adeda)
- Rewrite Target Nginx - [link](https://kubernetes.github.io/ingress-nginx/examples/rewrite/)
- Create a Kubernetes TLS Ingress from scratch in Minikube - [link](https://www.youtube.com/watch?v=7K0gAYmWWho&ab_channel=kubucation)
- How To Configure Ingress TLS/SSL Certificates in Kubernetes - [link](https://devopscube.com/configure-ingress-tls-kubernetes/)
- Create a multiple domains (SAN) self-signed SSL certificate - [link](https://transang.me/create-a-multiple-domains-self-signed-ssl-certificate-with-testing-scripts/)
