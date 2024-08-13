openssl genrsa -out "root-ca.key" 4096

openssl req \
          -new -key "root-ca.key" \
          -out "root-ca.csr" -sha256 \
          -subj '/C=CN/ST=ZheJiang/L=HangZhou/O=kubernetes/CN=Local Docker Registry CA'
# 以上命令中 -subj 参数里的 /C 表示国家，如 CN；/ST 表示省；/L 表示城市或者地区；/O 表示组织名；/CN 通用名称。


echo "
[root_ca]
basicConstraints = critical,CA:TRUE,pathlen:1
keyUsage = critical, nonRepudiation, cRLSign, keyCertSign
subjectKeyIdentifier=hash
" > root-ca.cnf

openssl x509 -req  -days 3650  -in "root-ca.csr" \
               -signkey "root-ca.key" -sha256 -out "root-ca.crt" \
               -extfile "root-ca.cnf" -extensions \
               root_ca

# 生成私钥
openssl genrsa -out "registry.local.key" 4096

echo "
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext

[req_distinguished_name]
countryName = CN
countryName_default = CN
stateOrProvinceName = ZheJiang
stateOrProvinceName_default = ZheJiang
localityName = HangZhou
localityName_default = HangZhou
organizationName = kubernetes
organizationName_default = kubernetes
commonName = registry.local
commonName_default = registry.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = registry.local
DNS.2 = master-01
DNS.3 = master-02
DNS.4 = master-03
" > openssl-san.cnf

openssl req -new -key "registry.local.key" -out "site.csr" -sha256 -config openssl-san.cnf

# openssl req -new -key "registry.local.key" -out "site.csr" -sha256 \
#           -subj '/C=CN/ST=ZheJiang/L=HangZhou/O=kubernetes/CN=registry.local'

echo "
[server]
authorityKeyIdentifier=keyid,issuer
basicConstraints = critical,CA:FALSE
extendedKeyUsage=serverAuth
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = DNS:registry.local, DNS:master-01, DNS:master-02, DNS:master-03, IP:127.0.0.1
subjectKeyIdentifier=hash
" > site.cnf

openssl x509 -req -days 3650 -in "site.csr" -sha256 \
    -CA "root-ca.crt" -CAkey "root-ca.key"  -CAcreateserial \
    -out "registry.local.crt" -extfile "site.cnf" -extensions server
