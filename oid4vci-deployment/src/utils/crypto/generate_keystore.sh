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

log "Generating keystore $KEYSTORE_PATH..."

# EC key (ECDSA)
keytool -genkeypair \
    -keyalg EC -keysize 256 -validity 3650 \
    -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
    -alias "$KEYSTORE_ALIASES_ECDSA_KEY" -keypass "$KEYSTORE_PASSWORD" \
    -storetype "$KEYSTORE_TYPE" \
    -dname "CN=ECDSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

# RSA signing key
keytool -genkeypair \
    -keyalg RSA -keysize 3072 -validity 3650 \
    -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
    -alias "$KEYSTORE_ALIASES_RSA_SIG_KEY" -keypass "$KEYSTORE_PASSWORD" \
    -storetype "$KEYSTORE_TYPE" \
    -dname "CN=RSA Signing Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

# RSA encryption key
keytool -genkeypair \
    -keyalg RSA -keysize 3072 -validity 3650 \
    -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
    -alias "$KEYSTORE_ALIASES_RSA_ENC_KEY" -keypass "$KEYSTORE_PASSWORD" \
    -storetype "$KEYSTORE_TYPE" \
    -dname "CN=RSA Encryption Key, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=CM"

log "Keystore generated successfully at $KEYSTORE_PATH."
