#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Generate Keycloak keystore with EC and RSA keys
# -----------------------------------------------------------------------------

# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

if [[ -f "$KEYSTORE_PATH" ]]; then
    log "Keystore $KEYSTORE_PATH already exists. Skipping generation."
    return 0
fi

# -----------------------------------------------------------------------------
# Define Root CA paths
# -----------------------------------------------------------------------------
ROOT_CA_KEY="${PROJECT_TARGET_DIR}/root-ca.key.pem"
ROOT_CA_CERT="${PROJECT_TARGET_DIR}/root-ca.crt.pem"
CSR_PATH="${PROJECT_TARGET_DIR}/temp.csr"
CERT_PATH="${PROJECT_TARGET_DIR}/temp.crt"

# -----------------------------------------------------------------------------
# Generate local Root CA if missing
# -----------------------------------------------------------------------------
if [[ ! -f "$ROOT_CA_KEY" ]]; then
    log "Generating local Root CA..."
    openssl req -x509 -newkey rsa:4048 -nodes \
        -keyout "$ROOT_CA_KEY" -out "$ROOT_CA_CERT" -days 3650 \
        -subj "/CN=Adorsys Local Root CA/O=Adorsys Lab/C=CM"
fi

log "Generating keystore $KEYSTORE_PATH..."

# Helper function to generate and sign a keypair
generate_and_sign_key() {
    local alias="$1"
    local alg="$2"
    local size="$3"
    local dname="$4"

    log "Generating and signing key for alias: $alias ($alg)"

    # 1. Generate keypair (initially self-signed)
    keytool -genkeypair \
        -keyalg "$alg" -keysize "$size" -validity 3650 \
        -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
        -alias "$alias" -keypass "$KEYSTORE_PASSWORD" \
        -storetype "$KEYSTORE_TYPE" \
        -dname "$dname"

    # 2. Generate Certificate Signing Request (CSR)
    keytool -certreq \
        -alias "$alias" -keystore "$KEYSTORE_PATH" \
        -storepass "$KEYSTORE_PASSWORD" -file "$CSR_PATH"

    # 3. Sign the CSR with Local Root CA
    openssl x509 -req -in "$CSR_PATH" \
        -CA "$ROOT_CA_CERT" -CAkey "$ROOT_CA_KEY" -CAcreateserial \
        -out "$CERT_PATH" -days 3650 -sha256

    # 4. Import Root CA certificate into keystore (required for chain)
    keytool -importcert -trustcacerts -noprompt \
        -alias "root-ca" -file "$ROOT_CA_CERT" \
        -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD"

    # 5. Import signed certificate back into keystore
    keytool -importcert -noprompt \
        -alias "$alias" -file "$CERT_PATH" \
        -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD"
    
    # Cleanup temp files
    rm -f "$CSR_PATH" "$CERT_PATH"
}

# EC key (ECDSA)
generate_and_sign_key "$KEYSTORE_ALIASES_ECDSA_KEY" "EC" "256" \
    "CN=ECDSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

# RSA signing key
generate_and_sign_key "$KEYSTORE_ALIASES_RSA_SIG_KEY" "RSA" "3072" \
    "CN=RSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

# RSA encryption key
generate_and_sign_key "$KEYSTORE_ALIASES_RSA_ENC_KEY" "RSA" "3072" \
    "CN=RSA Encryption Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

log "Keystore generated successfully at $KEYSTORE_PATH."
