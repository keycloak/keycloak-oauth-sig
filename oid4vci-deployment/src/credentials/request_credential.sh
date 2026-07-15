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

# ===============================
# Get User Token
# ===============================
log "Requesting access token for user '$USERS_FRANCIS_NAME'..."

response=$(curl -k -s -o "$TARGET_DIR/response.json" -w "%{http_code}" -X POST \
  "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/openid-connect/token" \
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

log_offer_failure() {
  local BODY="$1"
  local LABEL="$2"
  local ERR DESC
  ERR=$(echo "$BODY" | jq -r '.error // empty' 2>/dev/null || true)
  DESC=$(echo "$BODY" | jq -r '.error_description // empty' 2>/dev/null || true)
  if [ -n "$ERR" ] || [ -n "$DESC" ]; then
    warn "$LABEL: error=${ERR:-n/a} error_description=${DESC:-n/a}"
  elif [ -n "$BODY" ]; then
    warn "$LABEL: unexpected response: $BODY"
  else
    warn "$LABEL: empty response"
  fi
}

# Must run in current shell so CREDENTIAL_OFFER_LINK / LAST_OFFER_BODY persist.
LAST_OFFER_BODY=""
CREDENTIAL_OFFER_LINK=""
fetch_credential_offer_link() {
  local CREDENTIAL_OFFER_PATH="$1"
  local HTTP_CODE
  local RESPONSE

  CREDENTIAL_OFFER_LINK=""
  RESPONSE=$(curl -k -s -w "\n%{http_code}" \
    "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/$CREDENTIAL_OFFER_PATH" \
    -H "Authorization: Bearer $USER_ACCESS_TOKEN" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json')
  HTTP_CODE=$(printf '%s' "$RESPONSE" | tail -n1)
  LAST_OFFER_BODY=$(printf '%s' "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" != "200" ] || [ -z "$LAST_OFFER_BODY" ] || \
     ! echo "$LAST_OFFER_BODY" | jq -e 'has("issuer") and has("nonce")' > /dev/null 2>&1; then
    return 1
  fi

  CREDENTIAL_OFFER_LINK=$(echo "$LAST_OFFER_BODY" | jq -r \
    'if (.issuer | endswith("/")) then "\(.issuer)\(.nonce)" else "\(.issuer)/\(.nonce)" end')
  return 0
}

if ! fetch_credential_offer_link "create-credential-offer?credential_configuration_id=$CREDENTIAL_TYPE&target_user=$USERS_FRANCIS_NAME&pre_authorized=true"; then
  log_offer_failure "$LAST_OFFER_BODY" "create-credential-offer failed"
  log "Retrying with legacy credential-offer-uri (older Keycloak only)..."
  if ! fetch_credential_offer_link "credential-offer-uri?credential_configuration_id=$CREDENTIAL_TYPE&username=$USERS_FRANCIS_NAME"; then
    log_offer_failure "$LAST_OFFER_BODY" "Failed to retrieve CREDENTIAL_OFFER_LINK"
    error "Failed to retrieve CREDENTIAL_OFFER_LINK"
  fi
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

C_NONCE=$(curl -k -s -X POST "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/nonce" | jq -r '.c_nonce')

if [ -z "$C_NONCE" ] || [ "$C_NONCE" == "null" ]; then
  error "Failed to retrieve C_NONCE"
  exit 1
fi

success "C_NONCE: $C_NONCE"

# ===============================
# Obtain Credential Bearer Token
# ===============================
log "Requesting credential bearer token..."

CREDENTIAL_BEARER_TOKEN=$(curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/openid-connect/token" \
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

CREDENTIAL=$(curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/credential" \
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
