#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Realm PKCS12 keystore. ecdsa_key is signed by a local CA. A self-signed
# ecdsa_key keeps its private key. A certificate that is not self-signed stays.
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

# Sets ECDSA_LEAF_SELF_SIGNED. The certificate is self-signed when its subject and
# issuer names match and the signature verifies with its own public key.
inspect_ecdsa_leaf() {
    local p12="$1"
    local work="$2"
    openssl pkcs12 -in "$p12" -nokeys -clcerts \
        -passin "pass:${KEYSTORE_PASSWORD}" -out "$work/leaf.crt" >/dev/null 2>&1 || return 1
    cat > "$work/LeafSelfSigned.java" << 'EOF'
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.InvalidKeyException;
import java.security.SignatureException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

public class LeafSelfSigned {
    public static void main(String[] args) throws Exception {
        X509Certificate certificate = (X509Certificate) CertificateFactory.getInstance("X.509")
                .generateCertificate(Files.newInputStream(Path.of(args[0])));
        if (!certificate.getSubjectX500Principal().equals(certificate.getIssuerX500Principal())) {
            System.out.println("false");
            return;
        }
        try {
            certificate.verify(certificate.getPublicKey());
            System.out.println("true");
        } catch (SignatureException | InvalidKeyException e) {
            System.out.println("false");
        }
    }
}
EOF
    java "$work/LeafSelfSigned.java" "$work/leaf.crt" > "$work/result" || return 1
    ECDSA_LEAF_SELF_SIGNED="$(<"$work/result")"
}

ensure_local_issuance_ca() {
    ensure_directory_exists "$CA_DIR"
    if [[ -f "$CA_KEY" && -f "$CA_CERT" ]]; then
        return 0
    fi
    log "Creating local issuance CA..."
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout "$CA_KEY" -out "$CA_CERT" -days 3650 -nodes \
        -subj "$CA_SUBJECT" >/dev/null 2>&1 || return 1
    chmod 600 "$CA_KEY" || return 1
}

install_ca_signed_ecdsa() (
    local existing_p12="${1:-}"
    local work_dir key_pem dest
    work_dir="$(mktemp -d)" || return 1
    # Expand the path now. The local variable is gone when the EXIT trap runs.
    trap 'rm -rf '"${work_dir@Q}" EXIT
    key_pem="${work_dir}/ecdsa.key"

    if [[ -n "$existing_p12" ]]; then
        log "Reusing existing ${KEYSTORE_ALIASES_ECDSA_KEY} private key."
        openssl pkcs12 -in "$existing_p12" -nocerts -nodes \
            -passin "pass:${KEYSTORE_PASSWORD}" -out "$key_pem" >/dev/null 2>&1 || return 1
    else
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$key_pem" >/dev/null 2>&1 || return 1
    fi

    ensure_local_issuance_ca || return 1
    openssl req -new -key "$key_pem" -subj "$ECDSA_SUBJECT" -out "${work_dir}/ecdsa.csr" >/dev/null 2>&1 || return 1
    openssl x509 -req \
        -in "${work_dir}/ecdsa.csr" \
        -CA "$CA_CERT" -CAkey "$CA_KEY" -CAserial "$CA_SERIAL" -CAcreateserial \
        -out "${work_dir}/ecdsa.crt" -days 3650 -sha256 >/dev/null 2>&1 || return 1
    openssl pkcs12 -export \
        -inkey "$key_pem" \
        -in "${work_dir}/ecdsa.crt" \
        -certfile "$CA_CERT" \
        -name "$KEYSTORE_ALIASES_ECDSA_KEY" \
        -out "${work_dir}/ecdsa.p12" \
        -passout "pass:${KEYSTORE_PASSWORD}" >/dev/null 2>&1 || return 1
    keytool -list \
        -keystore "${work_dir}/ecdsa.p12" \
        -storetype PKCS12 \
        -storepass "$KEYSTORE_PASSWORD" \
        -alias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null || return 1

    # Swap the entry on a copy so a failed import cannot drop the existing key.
    ensure_directory_exists "$(dirname "$KEYSTORE_PATH")"
    dest="${work_dir}/keystore.p12"
    if [[ -f "$KEYSTORE_PATH" ]]; then
        cp "$KEYSTORE_PATH" "$dest" || return 1
        if keystore_alias_exists "$KEYSTORE_ALIASES_ECDSA_KEY" "$dest"; then
            keytool -delete \
                -alias "$KEYSTORE_ALIASES_ECDSA_KEY" \
                -keystore "$dest" \
                -storetype "$KEYSTORE_TYPE" \
                -storepass "$KEYSTORE_PASSWORD" >/dev/null || return 1
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
        -destalias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null || return 1
    cp "$dest" "$KEYSTORE_PATH" || return 1
)

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

# Subshell so this EXIT trap cannot replace a trap in the setup script that sources this file.
prepare_ecdsa_key() (
    if [[ -f "$KEYSTORE_PATH" ]] && keystore_alias_exists "$KEYSTORE_ALIASES_ECDSA_KEY"; then
        local leaf_dir
        leaf_dir="$(mktemp -d)" || return 1
        trap 'rm -rf '"${leaf_dir@Q}" EXIT
        keytool -importkeystore -noprompt \
            -srckeystore "$KEYSTORE_PATH" \
            -srcstoretype "$KEYSTORE_TYPE" \
            -srcstorepass "$KEYSTORE_PASSWORD" \
            -srcalias "$KEYSTORE_ALIASES_ECDSA_KEY" \
            -destkeystore "${leaf_dir}/leaf.p12" \
            -deststoretype PKCS12 \
            -deststorepass "$KEYSTORE_PASSWORD" \
            -destalias "$KEYSTORE_ALIASES_ECDSA_KEY" >/dev/null || return 1
        inspect_ecdsa_leaf "${leaf_dir}/leaf.p12" "$leaf_dir" || return 1
        if [[ "$ECDSA_LEAF_SELF_SIGNED" == "true" ]]; then
            log "Replacing self-signed ${KEYSTORE_ALIASES_ECDSA_KEY} certificate with a CA-signed certificate..."
            install_ca_signed_ecdsa "${leaf_dir}/leaf.p12" || return 1
        else
            log "ES256 certificate for ${KEYSTORE_ALIASES_ECDSA_KEY} is not self-signed."
        fi
    else
        log "Generating keystore $KEYSTORE_PATH..."
        install_ca_signed_ecdsa || return 1
    fi
)
prepare_ecdsa_key || error "Failed to prepare the ${KEYSTORE_ALIASES_ECDSA_KEY} certificate."

ensure_rsa_keypair "$KEYSTORE_ALIASES_RSA_SIG_KEY" \
    "CN=RSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"
ensure_rsa_keypair "$KEYSTORE_ALIASES_RSA_ENC_KEY" \
    "CN=RSA Encryption Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

log "Keystore ready at $KEYSTORE_PATH."
