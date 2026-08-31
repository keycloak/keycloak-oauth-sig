#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Helpers and env
# -----------------------------------------------------------------------------
# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

# -----------------------------------------------------------------------------
# Ensure KEYCLOAK_INSTALL_DIR is resolved if KEYCLOAK_VERSION is "latest"
# This is needed so the kcadm helper can find the local Keycloak install
# -----------------------------------------------------------------------------
ensure_keycloak_install_dir_resolved

# -----------------------------------------------------------------------------
# Get admin token using environment variables for credentials
# -----------------------------------------------------------------------------
log "Obtaining admin token..."
kcadm config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$(kc_truststore_path)"
kcadm config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD"
success "Admin token obtained."

# -----------------------------------------------------------------------------
# Read the direct access property of the openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Reading direct access property of the openid4vc-rest-api client..."
kcadm get clients -r "$KEYCLOAK_REALM" -q clientId=openid4vc-rest-api --fields 'id,directAccessGrantsEnabled' || true

# -----------------------------------------------------------------------------
# Store property ACC_CLIENT_ID in an environment variable
# -----------------------------------------------------------------------------
export ACC_CLIENT_ID=$(kcadm get clients -r "$KEYCLOAK_REALM" -q clientId=openid4vc-rest-api --fields id | jq -r '.[0].id')
log "Stored openid4vc-rest-api Client ID: $ACC_CLIENT_ID"

# -----------------------------------------------------------------------------
# Enable direct grant on the openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Enabling direct grant on the openid4vc-rest-api client..."
kcadm update clients/$ACC_CLIENT_ID -r "$KEYCLOAK_REALM" -s directAccessGrantsEnabled=true -o --fields 'id,directAccessGrantsEnabled' || true
success "Direct grant enabled."

# -----------------------------------------------------------------------------
# Create a user named Francis
# -----------------------------------------------------------------------------
log "Creating user Francis if not exists..."
if ! kcadm get users -r "$KEYCLOAK_REALM" -q username=francis | jq -e '.[0].id' >/dev/null 2>&1; then
  kcadm create users -r "$KEYCLOAK_REALM" -s username=francis -s firstName=Francis -s lastName=Pouatcha -s email=fpo@mail.de -s enabled=true
  success "User Francis created."
else
  warn "User Francis already exists."
fi

# -----------------------------------------------------------------------------
# Set password for Francis
# -----------------------------------------------------------------------------
log "Setting password for user Francis..."
kcadm set-password -r "$KEYCLOAK_REALM" --username "$USERS_FRANCIS_NAME" --new-password "$USERS_FRANCIS_PASSWORD" || true
success "Password ensured for Francis."

# -----------------------------------------------------------------------------
# Grant enabled credentials to Francis
# -----------------------------------------------------------------------------
# Keycloak requires an explicit per-user grant before a credential can be
# issued. Keep the demo user synchronized with credentials.enabled so newly
# enabled samples can be tested immediately after running `keycloak-ssi config`.
log "Granting enabled credentials to user Francis..."
FRANCIS_USER_ID=$(kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" --fields id | jq -r '.[0].id // empty')
[[ -n "$FRANCIS_USER_ID" ]] || error "Could not find user Francis to grant credentials."

ENABLED_CREDENTIALS=$(enabled_credentials_json)
GRANTED_CREDENTIALS=$(kcadm get "users/$FRANCIS_USER_ID/vc/credentials" -r "$KEYCLOAK_REALM")

jq -r '.[]' <<< "$ENABLED_CREDENTIALS" | while read -r credential; do
  if jq -e --arg credential "$credential" \
    'any(.[]; .credentialScopeName == $credential)' <<< "$GRANTED_CREDENTIALS" >/dev/null; then
    log "Credential '$credential' is already granted to Francis."
    continue
  fi

  jq -n --arg credential "$credential" '{credentialScopeName: $credential}' | \
    kcadm create "users/$FRANCIS_USER_ID/vc/credentials" -r "$KEYCLOAK_REALM" -f - >/dev/null || \
    error "Failed to grant credential '$credential' to Francis."
  success "Credential '$credential' granted to Francis."
done

# -----------------------------------------------------------------------------
# Conditionally assign 'credential-offer-create' realm role to Francis
# This realm role grants permission to create credential offers.
# Only assigned when KEYCLOAK_ENABLE_CREDENTIAL_OFFER_CREATE is true.
# -----------------------------------------------------------------------------
CREDENTIAL_OFFER_ROLE="credential-offer-create"
if [[ "$KEYCLOAK_ENABLE_CREDENTIAL_OFFER_CREATE" == "true" ]]; then
  log "Checking existence of realm role '$CREDENTIAL_OFFER_ROLE'..."

  if kcadm get roles/$CREDENTIAL_OFFER_ROLE -r "$KEYCLOAK_REALM" >/dev/null 2>&1; then
    log "Assigning realm role '$CREDENTIAL_OFFER_ROLE' to user Francis..."
    FRANCIS_USER_ID=$(kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" --fields id | jq -r '.[0].id')
    if [ -n "$FRANCIS_USER_ID" ] && [ "$FRANCIS_USER_ID" != "null" ]; then
      kcadm add-roles -r "$KEYCLOAK_REALM" \
        --uid "$FRANCIS_USER_ID" \
        --rolename $CREDENTIAL_OFFER_ROLE || \
        warn "Failed to assign '$CREDENTIAL_OFFER_ROLE' role to user Francis (it may already be assigned)."
      success "Realm role '$CREDENTIAL_OFFER_ROLE' assigned to Francis."
    else
      error "Could not find user Francis to assign realm role '$CREDENTIAL_OFFER_ROLE'."
    fi
  else
    error "Realm role '$CREDENTIAL_OFFER_ROLE' does not exist in realm '$KEYCLOAK_REALM'."
  fi
else
  log "Skipping '$CREDENTIAL_OFFER_ROLE' role assignment (disabled in configuration)."
fi

# -----------------------------------------------------------------------------
# Prepare user key proof header if not existent
# -----------------------------------------------------------------------------
if [ ! -f "$PROJECT_TARGET_DIR/user_key_proof_header.json" ]; then
  log "Generating keypair for user..."
  . "$WORK_DIR/src/utils/crypto/generate_user_key.sh"
  success "User keyproof generated."
else
  warn "User key proof header already exists."
fi

success "Script execution completed."
