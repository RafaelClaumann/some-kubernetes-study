
# criar autoridade certificadora
openssl req \
    -x509 \
    -sha256 -days 356 \
    -nodes \
    -newkey rsa:2048 \
    -subj "/CN=demo.mlopshub.com/C=US/L=San Fransisco" \
    -keyout ca.key \
    -out ca.crt

# gerar chave privada do servidor
openssl genrsa -out server.key 2048

# gerar solicitacao de assinatura de certificado(CSR) sem prompt para o cliente
openssl req -new -key server.key -out server.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

# assinar o certificado(server.crt)
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:warden.validation.svc") \
  -days 365 \
  -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt


# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/

# criar autoridade certificadora
openssl req \
  -x509 \
  -sha256 -days 356 \
  -nodes \
  -newkey rsa:2048 \
  -subj "/CN=demo.mlopshub.com/C=US/L=San Fransisco" \
  -keyout ca.key \
  -out ca.crt

# criar CSR e chave sem prompt 
openssl req \
  -nodes \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.csr \
  -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

# assinar o certificado(server.crt)
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:warden.validation.svc") \
  -days 365 \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt
