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
# Create the demo user (default: Francis from users.francis.name)
# -----------------------------------------------------------------------------
log "Creating user '$USERS_FRANCIS_NAME' if not exists..."
if ! kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" | jq -e '.[0].id' >/dev/null 2>&1; then
  kcadm create users -r "$KEYCLOAK_REALM" \
    -s "username=$USERS_FRANCIS_NAME" \
    -s firstName=Francis \
    -s lastName=Pouatcha \
    -s email=fpo@mail.de \
    -s enabled=true
  success "User '$USERS_FRANCIS_NAME' created."
else
  warn "User '$USERS_FRANCIS_NAME' already exists."
fi

# -----------------------------------------------------------------------------
# Set password for the demo user
# -----------------------------------------------------------------------------
log "Setting password for user '$USERS_FRANCIS_NAME'..."
if kcadm set-password -r "$KEYCLOAK_REALM" --username "$USERS_FRANCIS_NAME" --new-password "$USERS_FRANCIS_PASSWORD"; then
  success "Password ensured for '$USERS_FRANCIS_NAME'."
else
  warn "Failed to set password for '$USERS_FRANCIS_NAME' (user may already have a password, or Keycloak rejected the update)."
fi

# -----------------------------------------------------------------------------
# Conditionally assign 'credential-offer-create' realm role to the demo user
# This realm role grants permission to create credential offers.
# Only assigned when KEYCLOAK_ENABLE_CREDENTIAL_OFFER_CREATE is true.
# -----------------------------------------------------------------------------
CREDENTIAL_OFFER_ROLE="credential-offer-create"
# Resolve once for role assignment and VC grants; non-fatal if lookup fails.
FRANCIS_USER_ID=""
FRANCIS_USER_ID=$(kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" --fields id 2>/dev/null \
  | jq -r '.[0].id // empty' 2>/dev/null) || FRANCIS_USER_ID=""
if [[ "$KEYCLOAK_ENABLE_CREDENTIAL_OFFER_CREATE" == "true" ]]; then
  log "Checking existence of realm role '$CREDENTIAL_OFFER_ROLE'..."

  if kcadm get roles/$CREDENTIAL_OFFER_ROLE -r "$KEYCLOAK_REALM" >/dev/null 2>&1; then
    log "Assigning realm role '$CREDENTIAL_OFFER_ROLE' to user '$USERS_FRANCIS_NAME'..."
    if [ -n "$FRANCIS_USER_ID" ] && [ "$FRANCIS_USER_ID" != "null" ]; then
      kcadm add-roles -r "$KEYCLOAK_REALM" \
        --uid "$FRANCIS_USER_ID" \
        --rolename "$CREDENTIAL_OFFER_ROLE" || \
        warn "Failed to assign '$CREDENTIAL_OFFER_ROLE' role to user '$USERS_FRANCIS_NAME' (it may already be assigned)."
      success "Realm role '$CREDENTIAL_OFFER_ROLE' assigned to '$USERS_FRANCIS_NAME'."
    else
      error "Could not find user '$USERS_FRANCIS_NAME' to assign realm role '$CREDENTIAL_OFFER_ROLE'."
    fi
  else
    error "Realm role '$CREDENTIAL_OFFER_ROLE' does not exist in realm '$KEYCLOAK_REALM'."
  fi
else
  log "Skipping '$CREDENTIAL_OFFER_ROLE' role assignment (disabled in configuration)."
fi

# -----------------------------------------------------------------------------
# Grant demo verifiable credentials to the demo user (Keycloak 26.7+)
# On 26.7+, create-credential-offer and issuance require an explicit per-user
# VC grant matching the credential client scope. Safe to re-run: existing
# grants are skipped with a warning. On older Keycloak the endpoint may be
# absent; failures are non-fatal so 26.6.x setups keep working.
# -----------------------------------------------------------------------------
if [ -n "${FRANCIS_USER_ID:-}" ] && [ "$FRANCIS_USER_ID" != "null" ]; then
  log "Granting demo verifiable credentials to '$USERS_FRANCIS_NAME'..."
  CLIENT_SCOPE_CONFIG_FILE="$WORK_DIR/src/config/client-scope-config.json"
  CREDENTIAL_SCOPES=()
  if [ -f "$CLIENT_SCOPE_CONFIG_FILE" ]; then
    mapfile -t CREDENTIAL_SCOPES < <(jq -r '.[].name' "$CLIENT_SCOPE_CONFIG_FILE" 2>/dev/null || true)
  fi
  if [ "${#CREDENTIAL_SCOPES[@]}" -eq 0 ]; then
    warn "Could not read credential scopes from '$CLIENT_SCOPE_CONFIG_FILE'; using default demo scopes."
    CREDENTIAL_SCOPES=(IdentityCredential SteuerberaterCredential KMACredential)
  fi

  for CREDENTIAL_SCOPE in "${CREDENTIAL_SCOPES[@]}"; do
    if kcadm create "users/$FRANCIS_USER_ID/vc/credentials" -r "$KEYCLOAK_REALM" \
        -s "credentialScopeName=$CREDENTIAL_SCOPE" >/dev/null 2>&1; then
      success "Granted '$CREDENTIAL_SCOPE' to '$USERS_FRANCIS_NAME'."
    else
      warn "Could not grant '$CREDENTIAL_SCOPE' to '$USERS_FRANCIS_NAME' (may already exist, or unsupported on this Keycloak version)."
    fi
  done
else
  warn "Skipping verifiable credential grants; could not resolve user id for '$USERS_FRANCIS_NAME'."
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
