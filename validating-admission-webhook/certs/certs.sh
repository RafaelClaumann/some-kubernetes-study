# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/

# criar uma Autoridade Certificadora(CA), isto é, chave privada(ca.key) e certificado(ca.crt)
# para assinar o certificado do servidor(server.crt), que será gerado nos passos seguintes.
openssl req -x509 -sha256 \
  -nodes \
  -newkey rsa:2048 \
  -keyout ca.key \
  -out ca.crt \
  -subj "/C=BR/ST=Santa Catarina/L=Florianopolis/O=Certificate Authority/OU=Self" \
  -days 356

# criar uma chave privada(server.key) e uma solicitação de assinatura de certificado((server.csr) para o servidor.
openssl req \
  -nodes \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.csr \
  -subj "/C=BR/ST=Santa Catarina/L=Florianopolis/O=Admission Webhook/OU=Kubernetes"

# assinar o certificado(server.crt) usando a server.csr, ca.key e ca.crt.
# subjectAltName DNS deve ser igual ao nome de DNS do Service criado em deploy.yaml
#   <svc_name>.<namespace>.svc.cluster.local
readonly WEBHOOK_SERVICE_DNS_NAME=warden.validation.svc
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:$WEBHOOK_SERVICE_DNS_NAME") \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -days 365
