#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Realm PKCS12 keystore. ecdsa_key is signed by a local CA. A self-signed
# ecdsa_key keeps its private key. A leaf already signed by another issuer stays.
# -----------------------------------------------------------------------------

# WORK_DIR is set by the CLI. Skip init when the caller already set KEYSTORE_PATH.
if [[ -z "${_CONFIGURATION_LOADED:-}" ]]; then
    source "$WORK_DIR/src/utils/helper.sh"
    init_script
fi

ECDSA_SUBJECT="/CN=ECDSA Signing Key/OU=Keycloak Competence Center/O=Adorsys Lab/L=Bangangte/ST=West/C=CM"
CA_SUBJECT="/CN=OID4VCI Local Issuance CA/O=Adorsys Lab/C=CM"
CA_DIR="${PROJECT_TARGET_DIR:-${WORK_DIR}/target}"
CA_KEY="${CA_DIR}/issuance-ca.key"
CA_CERT="${CA_DIR}/issuance-ca.crt"
CA_SERIAL="${CA_DIR}/issuance-ca.srl"

keystore_alias_exists() {
    local alias="$1"
    local keystore="${2:-$KEYSTORE_PATH}"
    [[ -f "$keystore" ]] || return 1
    keytool -list \
        -keystore "$keystore" \
        -storetype "$KEYSTORE_TYPE" \
        -storepass "$KEYSTORE_PASSWORD" \
        -alias "$alias" >/dev/null 2>&1
}

# Sets ECDSA_LEAF_SELF_SIGNED. Call this directly so a read failure stops the script.
inspect_ecdsa_leaf() {
    local p12="$1"
    local cert_pem subject issuer
    cert_pem="$(openssl pkcs12 -in "$p12" -nokeys -clcerts -passin "pass:${KEYSTORE_PASSWORD}" 2>/dev/null)"
    [[ -n "$cert_pem" ]] || error "Could not read the ${KEYSTORE_ALIASES_ECDSA_KEY} certificate."
    subject="$(openssl x509 -noout -subject -nameopt RFC2253 <<< "$cert_pem")"
    issuer="$(openssl x509 -noout -issuer -nameopt RFC2253 <<< "$cert_pem")"
    subject="${subject#subject=}"
    issuer="${issuer#issuer=}"
    subject="${subject// /}"
    issuer="${issuer// /}"
    if [[ "$subject" == "$issuer" ]]; then
        ECDSA_LEAF_SELF_SIGNED=true
    else
        ECDSA_LEAF_SELF_SIGNED=false
    fi
}

ensure_local_issuance_ca() {
    ensure_directory_exists "$CA_DIR"
    if [[ -f "$CA_KEY" && -f "$CA_CERT" ]]; then
        return 0
    fi
    log "Creating local issuance CA..."
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout "$CA_KEY" -out "$CA_CERT" -days 3650 -nodes \
        -subj "$CA_SUBJECT" >/dev/null 2>&1
    chmod 600 "$CA_KEY"
}

install_ca_signed_ecdsa() {
    local existing_p12="${1:-}"
    local work_dir key_pem
    work_dir="$(mktemp -d)"
    key_pem="${work_dir}/ecdsa.key"

    if [[ -n "$existing_p12" ]]; then
        log "Reusing existing ${KEYSTORE_ALIASES_ECDSA_KEY} private key."
        openssl pkcs12 -in "$existing_p12" -nocerts -nodes \
            -passin "pass:${KEYSTORE_PASSWORD}" -out "$key_pem" >/dev/null 2>&1
    else
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$key_pem" >/dev/null 2>&1
    fi

    ensure_local_issuance_ca
    openssl req -new -key "$key_pem" -subj "$ECDSA_SUBJECT" -out "${work_dir}/ecdsa.csr" >/dev/null 2>&1
    openssl x509 -req \
        -in "${work_dir}/ecdsa.csr" \
        -CA "$CA_CERT" -CAkey "$CA_KEY" -CAserial "$CA_SERIAL" -CAcreateserial \
        -out "${work_dir}/ecdsa.crt" -days 3650 -sha256 >/dev/null 2>&1
    openssl pkcs12 -export \
        -inkey "$key_pem" \
        -in "${work_dir}/ecdsa.crt" \
        -certfile "$CA_CERT" \
        -name "$KEYSTORE_ALIASES_ECDSA_KEY" \
        -out "${work_dir}/ecdsa.p12" \
        -passout "pass:${KEYSTORE_PASSWORD}" >/dev/null 2>&1
    keytool -list \
        -keystore "${work_dir}/ecdsa.p12" \
        -storetype PKCS12 \
        -storepass "$KEYSTORE_PASSWORD" \
        -alias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null

    # Swap the entry on a copy so a failed import cannot drop the existing key.
    ensure_directory_exists "$(dirname "$KEYSTORE_PATH")"
    local dest="${work_dir}/keystore.p12"
    if [[ -f "$KEYSTORE_PATH" ]]; then
        cp "$KEYSTORE_PATH" "$dest"
        if keystore_alias_exists "$KEYSTORE_ALIASES_ECDSA_KEY" "$dest"; then
            keytool -delete \
                -alias "$KEYSTORE_ALIASES_ECDSA_KEY" \
                -keystore "$dest" \
                -storetype "$KEYSTORE_TYPE" \
                -storepass "$KEYSTORE_PASSWORD" >/dev/null
        fi
    fi
    keytool -importkeystore -noprompt \
        -srckeystore "${work_dir}/ecdsa.p12" \
        -srcstoretype PKCS12 \
        -srcstorepass "$KEYSTORE_PASSWORD" \
        -srcalias "$KEYSTORE_ALIASES_ECDSA_KEY" \
        -destkeystore "$dest" \
        -deststoretype "$KEYSTORE_TYPE" \
        -deststorepass "$KEYSTORE_PASSWORD" \
        -destkeypass "$KEYSTORE_PASSWORD" \
        -destalias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null
    cp "$dest" "$KEYSTORE_PATH"
    rm -rf "$work_dir"
}

ensure_rsa_keypair() {
    local alias="$1"
    local dname="$2"
    if keystore_alias_exists "$alias"; then
        return 0
    fi
    keytool -genkeypair \
        -keyalg RSA -keysize 3072 -validity 3650 \
        -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
        -alias "$alias" -keypass "$KEYSTORE_PASSWORD" \
        -storetype "$KEYSTORE_TYPE" \
        -dname "$dname" >/dev/null
}

if [[ -f "$KEYSTORE_PATH" ]] && keystore_alias_exists "$KEYSTORE_ALIASES_ECDSA_KEY"; then
    leaf_dir="$(mktemp -d)"
    keytool -importkeystore -noprompt \
        -srckeystore "$KEYSTORE_PATH" \
        -srcstoretype "$KEYSTORE_TYPE" \
        -srcstorepass "$KEYSTORE_PASSWORD" \
        -srcalias "$KEYSTORE_ALIASES_ECDSA_KEY" \
        -destkeystore "${leaf_dir}/leaf.p12" \
        -deststoretype PKCS12 \
        -deststorepass "$KEYSTORE_PASSWORD" \
        -destalias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null
    inspect_ecdsa_leaf "${leaf_dir}/leaf.p12"
    if [[ "$ECDSA_LEAF_SELF_SIGNED" == "true" ]]; then
        log "Replacing self-signed ${KEYSTORE_ALIASES_ECDSA_KEY} certificate with a CA-signed certificate..."
        install_ca_signed_ecdsa "${leaf_dir}/leaf.p12"
    else
        log "ES256 certificate for ${KEYSTORE_ALIASES_ECDSA_KEY} is already signed by a CA."
    fi
    rm -rf "$leaf_dir"
else
    log "Generating keystore $KEYSTORE_PATH..."
    install_ca_signed_ecdsa
fi

ensure_rsa_keypair "$KEYSTORE_ALIASES_RSA_SIG_KEY" \
    "CN=RSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"
ensure_rsa_keypair "$KEYSTORE_ALIASES_RSA_ENC_KEY" \
    "CN=RSA Encryption Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

log "Keystore ready at $KEYSTORE_PATH."
