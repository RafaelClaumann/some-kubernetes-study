# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/

# criar uma Autoridade Certificadora(CA), isto é, chave privada(ca.key) e certificado(ca.crt).
# a CA será usada para assinar o certificado do servidor(server.crt) que será gerado nos passos seguintes.
# arquivos_gerados: ca.crt ca.key
openssl req -x509 -sha256 \
  -nodes \
  -newkey rsa:2048 \
  -keyout ca.key \
  -out ca.crt \
  -subj "/C=BR/ST=Santa Catarina/L=Florianopolis/O=Certificate Authority/OU=Self" \
  -days 356

# criar uma chave privada(server.key) e uma solicitação de assinatura de certificado(server.csr) para
# assinar o certificado do servidor(server.crt) no próximo passo.
# arquivos_gerados: server.key server.csr
openssl req \
  -nodes \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.csr \
  -subj "/C=BR/ST=Santa Catarina/L=Florianopolis/O=Admission Webhook/OU=Kubernetes"

# gerar um certificado assinado(server.crt) para o servidor usando a ca.crt, ca.key e server.csr.
# subjectAltName DNS deve ser igual ao nome de DNS do Service criado em deploy.yaml: <svc_name>.<namespace>.svc
# arquivos_gerados: server.crt server.srl
readonly WEBHOOK_SERVICE_DNS_NAME=warden.validation.svc
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:$WEBHOOK_SERVICE_DNS_NAME") \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -days 365

# arquivos_gerados: ca.crt, ca.key, server.crt, server.key, server.csr, server.srl
