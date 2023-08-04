# Kubernetes Validation Admission Controller

### documentações, exemplos e anotações
- [blog: Guide to Kubernetes Admission Controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)
- [blog: Chaves Simétricas e Assimétricas](https://4future.com.br/index.php/2021/10/11/criptografia-chaves-simetricas-e-assimetricas/)
- [blog: How to Create Self-Signed Certificates using OpenSSL](https://devopscube.com/create-self-signed-certificates-openssl/)
- [blog: Create CSR using OpenSSL Without Prompt](https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/)
- [anotação: Admission Controllers: 147~150](https://www.notion.so/rafaelclaumann/Kubernetes-Certified-Application-Developer-CKAD-68eb3670ef054c2d8b43b7de06ef89ba?pvs=4#a3d26ac96c5143f7a462d16f7216d67e)
- [anotação: Admission Controller Webhook Self Signed Certificate](https://rafaelclaumann.notion.site/Admission-Controller-Webhook-TLS-da91546676964e1986ad4cb7bb497074?pvs=4)
- [doc: AdmissionReview struct fields](https://github.com/kubernetes/api/blob/master/admission/v1beta1/types.go)
- [doc: Admission Controllers Reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [exemplo: simple-kubernetes-webhook](https://github.com/slackhq/simple-kubernetes-webhook)
- [exemplo: warden](https://github.com/theITHollow/warden)
- [video: warden](https://www.youtube.com/watch?v=RFQ30mhdf3c)

### requisitos mínimos
- docker
- kubectl
- kind
- openssl
- python

### passo-a-passo para implantar o webhook
- Gerar os certificados usando o script _certs.sh_
- Copiar o certificado(_server.crt_) e a chave privada(_server.key_) para a pasta app
- Definir o campo _caBundle_ do _webhook.yaml_ com o valor de certificado da CA(_ca.crt_) em base64: `cat ca.crt | base64`
- Construir a imagem do app: `docker build --tag warden:v1 .`
- Carregar a imagem do app no cluster _kind_: `kind load docker-image warden:v1`
- Aplicar o manifesto _deploy.yaml_
- Aplicar o manifesto _webhook.yaml_
- Acompanhar os logs do app: `kubectl logs --namespace validation <pod_name> --follow`
- Criar um pod arbitrário e avaliar os logs do app: `kubectl run --rm -it nginx --image nginx -- /bin/bash`

### pass-a-passo para iniciar o servidor python local
- criar _venv_ na pasta app: `python -m venv venv`
- ininiciar o _venv_: `source ./venv/bin/activate`
- instalar dependencias: `pip install -r requirements.txt`
- copiar certificado(_server.crt_) e chave privada(_server.key_) do servidor para a pasta app
- iniciar aplicação: `python -m flask --debug --app=server run --host=0.0.0.0 --cert=server.crt --key=server.key`



Porque o campo imagePullPolicy do deploy.yaml tem valor IfNotPresent? [resposta](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster)

Quais são os campos e atributos do objeto request acessado em server.py? [resposta](https://flask.palletsprojects.com/en/2.3.x/api/#flask.Request)

Porque foi preciso criar um arquivo(log_config.py) só para configurar os logs? [resposta](https://flask.palletsprojects.com/en/2.3.x/logging/)

k set image --namespace validation deployments warden-deployment warden-ctnr=warden:v1



