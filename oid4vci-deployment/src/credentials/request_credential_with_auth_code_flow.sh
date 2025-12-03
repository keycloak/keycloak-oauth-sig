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
# Paths
# ===============================
WORK_DIR_CONFIG="$WORK_DIR/src/config"
UTILS_DIR="$WORK_DIR/src/utils/crypto"
TARGET_DIR="${PROJECT_TARGET_DIR:-/tmp}"

# ===============================
# Argument Validation
# ===============================
if [ -z "$1" ]; then
  log_error "Usage: $0 <CREDENTIAL_TYPE>"
  log_warn "Example: $0 IdentityCredential"
  exit 1
fi

CREDENTIAL_TYPE="$1"

# ===============================
# Configure Admin
# ===============================
log "Configuring Keycloak admin credentials..."
$KEYCLOAK_INSTALL_DIR/bin/kcadm.sh config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$SSL_TRUST_STORE"

if ! $KEYCLOAK_INSTALL_DIR/bin/kcadm.sh get realms --server "$KEYCLOAK_ADMIN_ADDR" --realm master > /dev/null 2>&1; then
  log "No existing admin credentials found. Configuring new credentials..."
  $KEYCLOAK_INSTALL_DIR/bin/kcadm.sh config credentials \
    --server "$KEYCLOAK_ADMIN_ADDR" \
    --realm master \
    --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" \
    --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" || {
      error "Failed to configure Keycloak admin credentials"
      exit 1
    }
else
  success "Admin credentials already configured."
fi

# ===============================
# Check User 'francis'
# ===============================
log "Verifying user 'francis'..."
if ! $KEYCLOAK_INSTALL_DIR/bin/kcadm.sh get users -r "$KEYCLOAK_REALM" --fields username | jq -e '.[] | select(.username=="francis")' > /dev/null; then
  error "User 'francis' does not exist. Run 2.configure_user_4_account_client.sh first."
  exit 1
fi
success "User 'francis' found."

# ===============================
# Generate Key Proof if Missing
# ===============================
if [ ! -f "$UTILS_DIR/generate_user_key.sh" ]; then
  error "Missing $UTILS_DIR/generate_user_key.sh"
  exit 1
fi

if [ ! -f "$TARGET_DIR/user_key_proof_header.json" ]; then
  log "Generating key proof for user..."
  . "$UTILS_DIR/generate_user_key.sh" || {
    error "Failed to generate user key proof"
    exit 1
  }
  success "User key proof generated."
fi

# ===============================
# PKCE Generator
# ===============================
generate_pkce() {
    local code_verifier
    code_verifier=$(openssl rand -base64 96 | tr -d '+/=' | tr -d '\n' | cut -c -128)
    
    local code_challenge
    code_challenge=$(echo -n "$code_verifier" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '=' | tr -d '\n')
    
    echo "$code_verifier" "$code_challenge"
}

# ===============================
# Request Credential via Auth Code Flow
# ===============================
request_credential() {
  local credential_id="$1"
  local scopes="openid $credential_id"
  log "=== Requesting credential: ${credential_id} ==="

  local pkce_output
  pkce_output=$(generate_pkce)
  code_verifier=$(echo "$pkce_output" | cut -d' ' -f1)
  code_challenge=$(echo "$pkce_output" | cut -d' ' -f2)
  log "PKCE generated successfully."
  debug "Code verifier: $code_verifier"
  debug "Code challenge: $code_challenge"

  local encoded_scopes
  encoded_scopes=$(urlencode "$scopes")
  local issuer_state="state-$(uuidgen)"
  local issuer_url="${KEYCLOAK_ADMIN_ADDR}/realms/${KEYCLOAK_REALM}"

  local authorization_details_json
  authorization_details_json=$(jq -n --arg credential_id "$credential_id" --arg issuer_url "$issuer_url" '[{"type":"openid_credential", "credential_configuration_id": $credential_id, "locations": [$issuer_url]}]' | tr -d '\n')
  local encoded_authorization_details
  encoded_authorization_details=$(urlencode "$authorization_details_json")

  local auth_url="${KEYCLOAK_ADMIN_ADDR}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/auth?response_type=code&client_id=openid4vc-rest-api&redirect_uri=https://localhost:8443/callback&scope=${encoded_scopes}&issuer_state=${issuer_state}&authorization_details=${encoded_authorization_details}&code_challenge=${code_challenge}&code_challenge_method=S256"

  warn "Manual step required: Open the following URL in your browser and login as 'francis':"
  echo -e "\n$auth_url\n"
  read -p "Paste the 'code' parameter from the redirect URL: " auth_code

  if [ -z "$auth_code" ]; then
    error "No authorization code provided. Exiting."
    exit 1
  fi
  success "Authorization code obtained."

  log "Exchanging authorization code for token..."
  local token_response
  token_response=$(curl -s -k -X POST "${KEYCLOAK_ADMIN_ADDR}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "code=${auth_code}" \
    --data-urlencode "client_id=openid4vc-rest-api" \
    --data-urlencode "client_secret=${CLIENTS_SECRET}" \
    --data-urlencode "redirect_uri=https://localhost:8443/callback" \
    --data-urlencode "code_verifier=${code_verifier}" \
    --data-urlencode "authorization_details=$authorization_details_json")

  local access_token
  access_token=$(echo "$token_response" | jq -r '.access_token')
  if [ -z "$access_token" ] || [ "$access_token" == "null" ]; then
    error "Token exchange failed: $token_response"
    exit 1
  fi
  success "Access token obtained successfully."

  # Set the credential access token for key proof generation
  export CREDENTIAL_ACCESS_TOKEN="$access_token"

  # Retrieve nonce
  log "Retrieving nonce..."
  C_NONCE=$(curl -k -s -X POST "$KEYCLOAK_ADMIN_ADDR/realms/$KEYCLOAK_REALM/protocol/oid4vc/nonce" | jq -r '.c_nonce')
  if [ -z "$C_NONCE" ]; then
    error "Failed to retrieve C_NONCE"
    exit 1
  fi
  success "C_NONCE: $C_NONCE"

  # Generate key proof
  log "Generating key proof..."
  . "$UTILS_DIR/generate_key_proof.sh" || {
    error "Failed to generate key proof"
    exit 1
  }
  success "Key proof generated."

  # Prepare credential request
  local req_body
  req_body=$(jq --arg credential_identifier "$credential_id" --arg proof_jwt "$USER_KEY_PROOF" \
    '.credential_identifier = $credential_identifier | .proofs.jwt = [ $proof_jwt ]' \
    "$WORK_DIR_CONFIG/credential_request_body.json")

  log "Requesting credential..."
  local credential
  credential=$(curl -s -k -X POST "${KEYCLOAK_ADMIN_ADDR}/realms/${KEYCLOAK_REALM}/protocol/oid4vc/credential" \
    -H "Authorization: Bearer ${access_token}" \
    -H "Content-Type: application/json" \
    -d "$req_body" | jq .)

  if [ -z "$credential" ] || [ "$credential" == "null" ] || echo "$credential" | jq -e '.error' > /dev/null; then
    error "Credential issuance failed for $credential_id. Response: $credential"
    exit 1
  fi

  success "Credential '$credential_id' successfully issued."
  echo -e "\n$credential\n"
}

# ===============================
# Execute
# ===============================
request_credential "$CREDENTIAL_TYPE"
success "Credential request process completed successfully!"

