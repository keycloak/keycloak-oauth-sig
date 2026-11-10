#!/bin/sh
#
# Serves the CRL of the OID4VCI credential signing CA, named by the CRL distribution point of the credential
# signing certificate. The conformance suite fetches and validates it for ISO mdoc credentials (ISO/IEC 18013-5
# Table B.10 requires nextUpdate to be within 90 days), so a fresh CRL is issued on every start.
#
# /ca: test-target/keycloak/keycloak/oid4vc (vci-issuer-ca.pem and vci-issuer-ca-key.pem)
#
set -e

WORK_DIR=/tmp/ca
mkdir -p "$WORK_DIR" /www
: > "$WORK_DIR/index.txt"
echo 01 > "$WORK_DIR/crlnumber"

cat > "$WORK_DIR/openssl.cnf" << EOF
[ ca ]
default_ca = issuer_ca

[ issuer_ca ]
database = $WORK_DIR/index.txt
crlnumber = $WORK_DIR/crlnumber
default_md = sha256
default_crl_days = 30
crl_extensions = crl_ext

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF

openssl ca -batch -gencrl -config "$WORK_DIR/openssl.cnf" \
    -cert /ca/vci-issuer-ca.pem -keyfile /ca/vci-issuer-ca-key.pem -out "$WORK_DIR/crl.pem"
openssl crl -in "$WORK_DIR/crl.pem" -outform DER -out /www/oid4vci-issuer-ca.crl
openssl crl -in "$WORK_DIR/crl.pem" -noout -text

echo ".crl:application/pkix-crl" > /etc/httpd.conf
exec httpd -f -v -p 8080 -h /www -c /etc/httpd.conf
