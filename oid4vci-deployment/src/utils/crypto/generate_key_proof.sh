#!/bin/bash

# Source common env variables
# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

# Stop if CREDENTIAL_ACCESS_TOKEN is not retrieved
if [ -z "$CREDENTIAL_ACCESS_TOKEN" ]; then
    echo "Generating key proof requires a credential access token, env: CREDENTIAL_ACCESS_TOKEN"
    exit 1
fi

# Ensure user_key_proof_header exists; if not, run the provisioning script
if [ ! -f "$PROJECT_TARGET_DIR/user_key_proof_header.json" ]; then
    echo "user_key_proof_header.json not found. Running user provisioning to generate it..."
    if [ -x "$WORK_DIR/src/deployment/2.configure_user_4_account_client.sh" ]; then
        WORK_DIR="$WORK_DIR" bash "$WORK_DIR/src/deployment/2.configure_user_4_account_client.sh"
    else
        echo "Provisioning script not found or not executable: $WORK_DIR/src/deployment/2.configure_user_4_account_client.sh" >&2
        exit 1
    fi
fi

# The proof timestamp
iat=$(date +%s)

# Use the c_nonce from the Keycloak nonce endpoint as the nonce value
if [ -z "$C_NONCE" ] || [ "$C_NONCE" = "null" ]; then
    echo "Error: C_NONCE (challenge nonce) is missing."
    echo "Ensure that the c_nonce was retrieved from the Keycloak nonce endpoint before running this script."
    exit 1
fi

nonce="$C_NONCE"

# Use the issuer DID (issuer identifier) for aud field, which matches what Keycloak advertises
# Prefer ISSUER_DID from config, fallback to constructed value
aud="${ISSUER_DID:-${KEYCLOAK_ISSUER_DID:-$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM}}"

# Fetch actual issuer identifier from well-known endpoint to ensure aud matches
ADMIN_ADDR="${KEYCLOAK_INTERNAL_ADMIN_ADDR:-$KEYCLOAK_ADMIN_ADDR}"
WELL_KNOWN_RESPONSE=$(curl -ks "$ADMIN_ADDR/.well-known/openid-credential-issuer/realms/$KEYCLOAK_REALM" 2>/dev/null || echo "")
if [[ -n "$WELL_KNOWN_RESPONSE" ]]; then
    ACTUAL_ISSUER=$(echo "$WELL_KNOWN_RESPONSE" | jq -r '.credential_issuer // empty' 2>/dev/null || echo "")
    if [[ -n "$ACTUAL_ISSUER" && "$ACTUAL_ISSUER" != "null" ]]; then
        aud="$ACTUAL_ISSUER"
    fi
fi

cat $WORK_DIR/src/config/user_key_proof_payload.json | jq --argjson iat $iat --arg nonce "$nonce" --arg aud "$aud" '.iat = $iat | .nonce=$nonce | .aud=$aud' > $PROJECT_TARGET_DIR/user_key_proof_payload.json

# -----------------------------------------------------------------------------
# Encode header and payload (exact same approach as original script)
# -----------------------------------------------------------------------------
KEY_PROOF_HEADER_BASE64URL=$(openssl base64 -in $PROJECT_TARGET_DIR/user_key_proof_header.json | tr '+/' '-_' | tr -d '=' | tr -d '\n')
KEY_PROOF_PAYLOAD_BASE64URL=$(openssl base64 -in $PROJECT_TARGET_DIR/user_key_proof_payload.json | tr '+/' '-_' | tr -d '=' | tr -d '\n')

SIGN_INPUT=$(echo -n $KEY_PROOF_HEADER_BASE64URL.$KEY_PROOF_PAYLOAD_BASE64URL)

# -----------------------------------------------------------------------------
# Extract private key from PKCS12
# -----------------------------------------------------------------------------
openssl pkcs12 \
  -in "$USERS_FRANCIS_KEYSTORE_PATH" \
  -nocerts -nodes \
  -out "$PROJECT_TARGET_DIR/francis_private_key.pem" \
  -passin pass:"$USERS_FRANCIS_KEYSTORE_PASSWORD"

# -----------------------------------------------------------------------------
# Sign input and extract R/S values
# -----------------------------------------------------------------------------
echo -n "$SIGN_INPUT" | openssl dgst -sha256 -sign "$PROJECT_TARGET_DIR/francis_private_key.pem" -out "$PROJECT_TARGET_DIR/signature.der"

R_HEX=$(openssl asn1parse -inform DER -in $PROJECT_TARGET_DIR/signature.der | grep -A 1 'INTEGER' | head -n 1 | awk '{print $7}' | tr -d ':')
S_HEX=$(openssl asn1parse -inform DER -in $PROJECT_TARGET_DIR/signature.der | grep -A 1 'INTEGER' | tail -n 1 | awk '{print $7}' | tr -d ':')

# -----------------------------------------------------------------------------
# Concatenate R and S and base64url encode
# -----------------------------------------------------------------------------
KEY_PROOF_SIGN_BASE64URL=$(echo $R_HEX$S_HEX | xxd -r -p | openssl base64 -A | tr '+/' '-_' | tr -d '=' | tr -d '\n')

# -----------------------------------------------------------------------------
# Construct final proof
# -----------------------------------------------------------------------------
USER_KEY_PROOF=$(echo -n $KEY_PROOF_HEADER_BASE64URL.$KEY_PROOF_PAYLOAD_BASE64URL.$KEY_PROOF_SIGN_BASE64URL)

echo -e "USER_KEY_PROOF: $USER_KEY_PROOF \n"
