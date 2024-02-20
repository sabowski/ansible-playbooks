#!/usr/bin/env bash

if [ "$#" -gt 1 ]; then
  echo "Error: too many arguments"
  echo "Usage: Provide a host name as an argument (or none to just create the root CA)"
  exit 1
fi

DOMAIN=local.test

if ! [ -f rootCA.crt ]; then
  echo "Info: root CA does not exist, creating"
  # Create root CA & Private key
  openssl req -x509 \
              -sha256 -days 356 \
              -nodes \
              -newkey rsa:2048 \
              -subj "/CN=${DOMAIN}/C=US/L=Anytown" \
              -keyout rootCA.key -out rootCA.crt 
else
  echo "Info: root CA exists. To create a new one first delete rootCA.crt and rootCA.key"
fi

if [ "$#" -eq 0 ]
then
  echo "Info: No hostname argument provided, exiting"
  exit 0
else
  HOSTNAME=$1
fi

# Generate Private key 

echo "Info: generating cert and key for ${HOSTNAME}.${DOMAIN}"

openssl genrsa -out "${HOSTNAME}.${DOMAIN}.key" 2048

# Create csf conf

cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = Maryland
L = Baltimore
O = MyOrg
OU = Test
CN = ${HOSTNAME}.${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${HOSTNAME}.${DOMAIN}
IP.1 = 127.0.0.1

EOF

# create CSR request using private key

openssl req -new -key "${HOSTNAME}.${DOMAIN}.key" -out "${HOSTNAME}.${DOMAIN}.csr" -config csr.conf

# Create a external config file for the certificate

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME}.${DOMAIN}

EOF

# Create SSl with self signed CA

    # -CAcreateserial -out "${HOSTNAME}.${DOMAIN}.crt" \
openssl x509 -req \
    -in "${HOSTNAME}.${DOMAIN}.csr" \
    -CA rootCA.crt -CAkey rootCA.key \
    -out "${HOSTNAME}.${DOMAIN}.crt" \
    -days 365 \
    -sha256 -extfile cert.conf

echo "Info: deleting temp files"
rm cert.conf csr.conf "${HOSTNAME}.${DOMAIN}.csr"
echo "Done"
