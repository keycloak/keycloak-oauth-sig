#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

# ---------------------------------------------------------------------------
# Generate self-signed server certificate if missing
# ---------------------------------------------------------------------------
if [[ ! -f "$SSL_SERVER_KEY" || ! -f "$SSL_SERVER_CERT" ]]; then
    log "Generating self-signed server certificate..."
    openssl req -newkey rsa:2048 -nodes \
        -keyout "$SSL_SERVER_KEY" -x509 -days 3650 \
        -out "$SSL_SERVER_CERT" -config "$WORK_DIR/src/utils/crypto/cert-config.txt" \
        -extensions v3_req
else
    log "Server key/certificate already exist. Skipping generation."
fi

# ---------------------------------------------------------------------------
# Import server certificate into truststore if missing
# ---------------------------------------------------------------------------
if [[ ! -f "$SSL_TRUST_STORE" ]]; then
    log "Importing server certificate into trust store..."
    keytool -importcert -trustcacerts -noprompt \
        -alias localhost \
        -file "$SSL_SERVER_CERT" \
        -keystore "$SSL_TRUST_STORE" \
        -storepass "$SSL_TRUST_STORE_PASS"
else
    log "Trust store already exists. Skipping import."
fi

log "Certificate setup completed."
