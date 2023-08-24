### 1 - Configurar o arquivo _/etc/hosts_
- Cluster kind com metallb e Service nginx do tipo LoadBalancer.
``` shell
# endereço IP do Service ingress controller do namespace ingress
export ingress_controllers_address=kubectl get svc -n ingress -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'
echo "$ingress_controllers_address example.com" | tr -d '"' | sudo tee -a /etc/hosts
```

- Cluster kind sem metallb e Service nginx do tipo NodePort.
``` shell
# endereço IP do container control-plane
export ip_address=$(\
    docker container inspect \
    $(docker container ls --filter name=".*-control-plane" --quiet) \
    --format "{{json .NetworkSettings.Networks.kind.IPAddress}}"
    )
echo "$ip_address example.com" | tr -d '"' | sudo tee -a /etc/hosts
```

- Exemplo _/etc/hosts_
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

### 2 - Criar o certificado assinado e chave privada:
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

### 3 - Criar um Secret para armazenar certificado e chave privada
``` shell
    kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

### 4 - Aplicar o arquivo deploy
``` shell
    kubectl apply -f deploy.yaml
```

### 5 - Validar as chamadas HTTP e HTTPS.
``` shell
curl --cacert tls.crt https://example.com/foo/hostname
    foo-app

curl --cacert tls.crt https://example.test.com/bar/hostname
    bar-app
```

----

Create a multiple domains (SAN) self-signed SSL certificate
https://transang.me/create-a-multiple-domains-self-signed-ssl-certificate-with-testing-scripts/
