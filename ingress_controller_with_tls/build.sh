rm -r tls.*

openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=o.que.importa.eh.subjectaltname.com /O=another.cn.com" \
	-addext "subjectAltName=DNS:example.com, DNS:test.com"

kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key

kubectl apply -f deploy.yaml

kubectl wait --for=condition=Ready --timeout=-1s pod/foo-app
kubectl wait --for=condition=Ready --timeout=-1s pod/bar-app
