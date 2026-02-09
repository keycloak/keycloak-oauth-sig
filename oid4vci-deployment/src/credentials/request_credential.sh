#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ===============================
# Load Environment
# ===============================
# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script


# ===============================
# Argument Validation
# ===============================
if [ -z "$1" ]; then
  error "Usage: $0 <CREDENTIAL_TYPE>"
  exit 1
fi

CREDENTIAL_TYPE="$1"

# ===============================
# Paths
# ===============================
WORK_DIR_CONFIG="$WORK_DIR/src/config"
UTILS_DIR="$WORK_DIR/src/utils/crypto"
TARGET_DIR="${TARGET_DIR:-/tmp}"

# Use internal admin address when running inside container
ADMIN_ADDR="${KEYCLOAK_INTERNAL_ADMIN_ADDR:-$KEYCLOAK_ADMIN_ADDR}"

# ===============================
# Get User Token
# ===============================
log "Requesting access token for user '$USERS_FRANCIS_NAME'..."

response=$(curl -k -s -o "$TARGET_DIR/response.json" -w "%{http_code}" -X POST \
  "$ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/openid-connect/token" \
  -d "client_id=openid4vc-rest-api" \
  -d "client_secret=$CLIENTS_SECRET" \
  -d "username=$USERS_FRANCIS_NAME" \
  -d "password=$USERS_FRANCIS_PASSWORD" \
  -d "grant_type=password" \
  -d "scope=openid")

if [ "$response" -ne 200 ]; then
  error "Failed to retrieve user token (HTTP $response)"
  exit 1
fi

USER_ACCESS_TOKEN=$(jq -r '.access_token' < "$TARGET_DIR/response.json")
success "User Access Token retrieved."

# ===============================
# Credential Offer
# ===============================
log "Requesting credential offer for '$CREDENTIAL_TYPE'..."

CREDENTIAL_OFFER_LINK=$(curl -k -s "$ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/credential-offer-uri?credential_configuration_id=$CREDENTIAL_TYPE&username=$USERS_FRANCIS_NAME" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' | jq -r '"\(.issuer)\(.nonce)"')

if [ -z "$CREDENTIAL_OFFER_LINK" ] || [ "$CREDENTIAL_OFFER_LINK" == "null" ]; then
  error "Failed to retrieve CREDENTIAL_OFFER_LINK"
  exit 1
fi

success "Credential Offer Link: $CREDENTIAL_OFFER_LINK"

CREDENTIAL_OFFER=$(curl -k -s "$CREDENTIAL_OFFER_LINK" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN")

log "Credential Offer retrieved."

PRE_AUTHORIZED_CODE=$(echo "$CREDENTIAL_OFFER" | jq -r '."grants"."urn:ietf:params:oauth:grant-type:pre-authorized_code"."pre-authorized_code"')

if [ -z "$PRE_AUTHORIZED_CODE" ] || [ "$PRE_AUTHORIZED_CODE" == "null" ]; then
  error "Failed to extract PRE_AUTHORIZED_CODE"
  exit 1
fi

success "Pre-Authorized Code: $PRE_AUTHORIZED_CODE"

# ===============================
# Get Nonce
# ===============================
log "Requesting nonce from Keycloak..."

C_NONCE=$(curl -k -s -X POST "$ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/nonce" | jq -r '.c_nonce')

if [ -z "$C_NONCE" ] || [ "$C_NONCE" == "null" ]; then
  error "Failed to retrieve C_NONCE"
  exit 1
fi

success "C_NONCE: $C_NONCE"

# ===============================
# Obtain Credential Bearer Token
# ===============================
log "Requesting credential bearer token..."

CREDENTIAL_BEARER_TOKEN=$(curl -k -s "$ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/openid-connect/token" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=urn:ietf:params:oauth:grant-type:pre-authorized_code' \
  -d "pre-authorized_code=$PRE_AUTHORIZED_CODE" \
  -d "client_id=openid4vc-rest-api" \
  -d "client_secret=$CLIENTS_SECRET")

CREDENTIAL_ACCESS_TOKEN=$(echo "$CREDENTIAL_BEARER_TOKEN" | jq -r '.access_token')

if [ -z "$CREDENTIAL_ACCESS_TOKEN" ] || [ "$CREDENTIAL_ACCESS_TOKEN" == "null" ]; then
  error "Failed to retrieve credential access token"
  exit 1
fi

CREDENTIAL_IDENTIFIER=$(echo "$CREDENTIAL_BEARER_TOKEN" | jq -r '.authorization_details[0].credential_identifiers[0]')

if [ -z "$CREDENTIAL_IDENTIFIER" ] || [ "$CREDENTIAL_IDENTIFIER" == "null" ]; then
  error "No credential_identifier returned in token response"
  exit 1
fi

success "Credential Identifier: $CREDENTIAL_IDENTIFIER"
success "Credential Access Token retrieved."

# ===============================
# Generate Key Proof
# ===============================
log "Generating key proof..."
. "$UTILS_DIR/generate_key_proof.sh"
success "Key proof generated."

# ===============================
# Prepare Request Payload
# ===============================
REQ_BODY=$(jq \
  --arg credential_identifier "$CREDENTIAL_IDENTIFIER" \
  --arg proof_jwt "$USER_KEY_PROOF" \
  '.credential_identifier = $credential_identifier | .proofs.jwt = [$proof_jwt]' \
  "$WORK_DIR_CONFIG/credential_request_body.json")

# ===============================
# Obtain Credential
# ===============================
log "Requesting credential '$CREDENTIAL_TYPE'..."

CREDENTIAL=$(curl -k -s "$ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/credential" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $CREDENTIAL_ACCESS_TOKEN" \
  -d "$REQ_BODY" | jq .)

if [ -z "$CREDENTIAL" ] || [ "$CREDENTIAL" == "null" ]; then
  error "Failed to retrieve credential."
  exit 1
fi

success "'$CREDENTIAL_TYPE' credential retrieved successfully!"
echo -e "\n$CREDENTIAL\n"
