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
# Get admin token using environment variables for credentials
# -----------------------------------------------------------------------------
log "Obtaining admin token..."
KCADM="$KEYCLOAK_INSTALL_DIR/bin/kcadm.sh"
"$KCADM" config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$SSL_TRUST_STORE"
"$KCADM" config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD"
success "Admin token obtained."

# -----------------------------------------------------------------------------
# Read the direct access property of the openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Reading direct access property of the openid4vc-rest-api client..."
"$KCADM" get clients -r "$KEYCLOAK_REALM" -q clientId=openid4vc-rest-api --fields 'id,directAccessGrantsEnabled' || true

# -----------------------------------------------------------------------------
# Store property ACC_CLIENT_ID in an environment variable
# -----------------------------------------------------------------------------
export ACC_CLIENT_ID=$("$KCADM" get clients -r "$KEYCLOAK_REALM" -q clientId=openid4vc-rest-api --fields id | jq -r '.[0].id')
log "Stored openid4vc-rest-api Client ID: $ACC_CLIENT_ID"

# -----------------------------------------------------------------------------
# Enable direct grant on the openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Enabling direct grant on the openid4vc-rest-api client..."
"$KCADM" update clients/$ACC_CLIENT_ID -r "$KEYCLOAK_REALM" -s directAccessGrantsEnabled=true -o --fields 'id,directAccessGrantsEnabled' || true
success "Direct grant enabled."

# -----------------------------------------------------------------------------
# Create a user named Francis
# -----------------------------------------------------------------------------
log "Creating user Francis if not exists..."
if ! "$KCADM" get users -r "$KEYCLOAK_REALM" -q username=francis | jq -e '.[0].id' >/dev/null 2>&1; then
  "$KCADM" create users -r "$KEYCLOAK_REALM" -s username=francis -s firstName=Francis -s lastName=Pouatcha -s email=fpo@mail.de -s enabled=true
  success "User Francis created."
else
  warn "User Francis already exists."
fi

# -----------------------------------------------------------------------------
# Set password for Francis
# -----------------------------------------------------------------------------
log "Setting password for user Francis..."
"$KCADM" set-password -r "$KEYCLOAK_REALM" --username "$USERS_FRANCIS_NAME" --new-password "$USERS_FRANCIS_PASSWORD" || true
success "Password ensured for Francis."

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
