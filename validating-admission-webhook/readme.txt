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


docker build --tag warden:v1 .
docker run --rm -it -p 8080:5000 warden:v1

k set image --namespace validation deployments warden-deployment warden-ctnr=warden:v1


1 - gerar certificados
2 - copiar server.crt e server.key para a pasta app
3 - copiar o ca.crt em base64 no campo caBundle de webhook.yaml
4 - construir a imagem docker do app
5 - aplicar o manifesto deploy.yaml
6 - aplicar o manifesto webhook.yaml
7 - acompanhar os logs do app
  k logs --namespace validation <pod_name> -f
8 - tentar criar um pod no cluster para avaliar o comportamento do webhook
