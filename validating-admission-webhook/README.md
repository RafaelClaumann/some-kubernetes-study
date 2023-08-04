# Kubernetes Validation Admission Controller

- [Admission Controllers: 147~150](https://www.notion.so/rafaelclaumann/Kubernetes-Certified-Application-Developer-CKAD-68eb3670ef054c2d8b43b7de06ef89ba?pvs=4#a3d26ac96c5143f7a462d16f7216d67e)

python -m venv venv 

source ./venv/bin/activate

pip install Flask

python -m flask --debug --app=server run --host=0.0.0.0 --cert=server.crt --key=server.key

cat rootCA.crt | base64

https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster
  containers:
    - name: warden
      image: warden:v1
      imagePullPolicy: IfNotPresent

https://flask.palletsprojects.com/en/2.3.x/api/#flask.request
  To access incoming request data, you can use the global request object.
  Flask parses incoming request data for you and gives you access to it through that global object.
  The request object is an instance of a Request(https://flask.palletsprojects.com/en/2.3.x/api/#flask.Request).


https://flask.palletsprojects.com/en/2.3.x/logging/
  If you don’t configure logging, Python’s default log level is usually ‘warning’. Nothing below the configured level will be visible.
  This example uses dictConfig() to create a logging configuration similar to Flask’s default, except for all logs:
    https://flask.palletsprojects.com/en/2.3.x/logging/#basic-configuration


docker build --tag warden:v1 .
docker run --rm -it -p 8080:5000 warden:v1

k set image --namespace validation deployments warden-deployment warden-ctnr=warden:v1


- Gerar os certificados usando o script certs.sh
- Copiar o certificado(server.crt) e a chave privada(server.key) para a pasta app
- Definir o campo `caBundle` do webhook.yaml com o valor de certificado da CA(ca.crt) em base64: `cat ca.crt | base64`
- Construir a imagem do app: `docker build --tag warden:v1 .`
- Carregar a imagem do app no cluster `kind`: `kind load docker-image warden:v1`
- Aplicar o manifesto deploy.yaml
- Aplicar o manifesto webhook.yaml
- Acompanhar os logs do app: `kubectl logs --namespace validation <pod_name> --follow`
- tentar criar um pod no cluster e avaliar os logs do app: `kubectl run --rm -it nginx --image nginx -- /bin/bash`
