#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Generate ECDSA Key and Extract Public Coordinates for JWK
# -----------------------------------------------------------------------------

# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

# -----------------------------------------------------------------------------
# Generate ECDSA Key in keystore if missing
# -----------------------------------------------------------------------------
if [[ ! -f "$USERS_FRANCIS_KEYSTORE_PATH" ]]; then
    log "Generating ECDSA key in $USERS_FRANCIS_KEYSTORE_PATH..."
    keytool -genkeypair \
        -keyalg EC \
        -groupname secp256r1 \
        -keystore "$USERS_FRANCIS_KEYSTORE_PATH" \
        -storepass "$USERS_FRANCIS_KEYSTORE_PASSWORD" \
        -alias "$USERS_FRANCIS_KEYSTORE_ECDSA_ALIAS" \
        -keypass "$USERS_FRANCIS_KEYSTORE_PASSWORD" \
        -storetype "$USERS_FRANCIS_KEYSTORE_TYPE" \
        -dname "CN=Francis Pouatcha, OU=Keycloak Competence Center, O=Adorsys Lab, L=Bangangte, ST=West, C=Cameroon"
else
    log "Keystore $USERS_FRANCIS_KEYSTORE_PATH already exists. Skipping generation."
fi

# -----------------------------------------------------------------------------
# Extract public key in DER format
# -----------------------------------------------------------------------------
log "Extracting public key in DER format..."
cat "$USERS_FRANCIS_KEYSTORE_PATH" | openssl ec \
    -passin pass:"$USERS_FRANCIS_KEYSTORE_PASSWORD" \
    -pubout -outform der \
    -out "$PROJECT_TARGET_DIR/francis_pub.der"

# -----------------------------------------------------------------------------
# Extract X and Y coordinates from DER
# -----------------------------------------------------------------------------
# Get last 64 bytes (public key coordinates for P-256)
hex=$(dd if="$PROJECT_TARGET_DIR/francis_pub.der" bs=1 skip=$(($(wc -c < "$PROJECT_TARGET_DIR/francis_pub.der") - 64)) count=64 2>/dev/null | xxd -p | tr -d '\n')

# Split into X and Y (each 32 bytes / 64 hex chars)
x_hex="${hex:0:64}"
y_hex="${hex:64:64}"

# -----------------------------------------------------------------------------
# Convert hex to Base64URL (no padding)
# -----------------------------------------------------------------------------
x_b64=$(echo "$x_hex" | xxd -r -p | openssl base64 -A | tr '+/' '-_' | tr -d '=' | tr -d '\n')
y_b64=$(echo "$y_hex" | xxd -r -p | openssl base64 -A | tr '+/' '-_' | tr -d '=' | tr -d '\n')

# -----------------------------------------------------------------------------
# Build user key proof header JSON
# -----------------------------------------------------------------------------
cat "$WORK_DIR/src/config/user_key_proof_header.json" | jq --arg x "$x_b64" --arg y "$y_b64" \
    '.jwk.x = $x | .jwk.y = $y' \
    > "$PROJECT_TARGET_DIR/user_key_proof_header.json"

log "User key proof header generated at: $PROJECT_TARGET_DIR/user_key_proof_header.json"
