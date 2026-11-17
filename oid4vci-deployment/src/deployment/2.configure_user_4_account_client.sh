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
# Authenticate admin
# -----------------------------------------------------------------------------
log "Obtaining admin token..."
kcadm config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$(kc_truststore_path)"
kcadm config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD"
success "Admin token obtained."

# -----------------------------------------------------------------------------
# Configure openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Configuring openid4vc-rest-api client..."
export ACC_CLIENT_ID=$(kcadm get clients -r "$KEYCLOAK_REALM" -q clientId=openid4vc-rest-api --fields id | jq -r '.[0].id')
log "Stored openid4vc-rest-api Client ID: $ACC_CLIENT_ID"

# -----------------------------------------------------------------------------
# Enable direct grant on the openid4vc-rest-api client
# -----------------------------------------------------------------------------
log "Enabling direct grant on the openid4vc-rest-api client..."
kcadm update clients/$ACC_CLIENT_ID -r "$KEYCLOAK_REALM" -s directAccessGrantsEnabled=true -o --fields 'id,directAccessGrantsEnabled' || true
success "Direct grant enabled."

# -----------------------------------------------------------------------------
# Create user Francis
# -----------------------------------------------------------------------------
log "Creating user Francis if not exists..."
if ! kcadm get users -r "$KEYCLOAK_REALM" -q username=francis | jq -e '.[0].id' >/dev/null 2>&1; then
  USER_FRANCIS_ID=$(kcadm create users -r "$KEYCLOAK_REALM" -s username=francis -s firstName=Francis -s lastName=Pouatcha -s email=fpo@mail.de -s enabled=true -i)
  kcadm create "users/$USER_FRANCIS_ID/vc/credentials" -r "$KEYCLOAK_REALM" -s credentialScopeName=IdentityCredential
  kcadm create "users/$USER_FRANCIS_ID/vc/credentials" -r "$KEYCLOAK_REALM" -s credentialScopeName=GatedIdentityCredential
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

# Resolve Francis user ID once for reuse below.
FRANCIS_USER_ID=$(kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" --fields id | jq -r '.[0].id // empty')
[[ -n "$FRANCIS_USER_ID" ]] || error "Could not find user Francis."

# -----------------------------------------------------------------------------
# Grant verifiable credentials (Keycloak 26.7+ only)
# Query the running server, not config — KEYCLOAK_VERSION (tarball) and
# KEYCLOAK_IMAGE_TAG (docker) are independent and may diverge.
# -----------------------------------------------------------------------------
KC_MAJOR_MINOR=""
KC_VERSION_RAW=""

KC_VERSION_RAW=$(kcadm get serverinfo 2>/dev/null | jq -r '.systemInfo.version // empty' 2>/dev/null) || KC_VERSION_RAW=""

if [[ "$KC_VERSION_RAW" =~ ^([0-9]+)\.([0-9]+) ]]; then
  KC_MAJOR_MINOR="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
fi

kc_version_gte() {
  local required="$1" actual="$2"
  local r_major r_minor a_major a_minor
  IFS='.' read -r r_major r_minor <<< "$required"
  IFS='.' read -r a_major a_minor <<< "$actual"
  [[ "$a_major" -gt "$r_major" ]] ||
    { [[ "$a_major" -eq "$r_major" ]] && [[ "$a_minor" -ge "$r_minor" ]]; }
}

if [[ -n "$KC_MAJOR_MINOR" ]] && kc_version_gte "26.7" "$KC_MAJOR_MINOR"; then
  log "Keycloak $KC_VERSION_RAW (>= 26.7). Granting enabled credentials to Francis..."

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
else
  if [[ -z "$KC_MAJOR_MINOR" ]]; then
    warn "Could not determine Keycloak server version; skipping credential grants."
  else
    warn "Keycloak $KC_VERSION_RAW < 26.7; skipping credential grants."
  fi
fi

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
    if [ -n "$FRANCIS_USER_ID" ] && [ "$FRANCIS_USER_ID" != "null" ]; then
      kcadm add-roles -r "$KEYCLOAK_REALM" \
        --uid "$FRANCIS_USER_ID" \
        --rolename $CREDENTIAL_OFFER_ROLE || \
        warn "Failed to assign '$CREDENTIAL_OFFER_ROLE' role (may already be assigned)."
      success "Realm role '$CREDENTIAL_OFFER_ROLE' assigned to Francis."
    else
      error "Could not find user Francis to assign realm role '$CREDENTIAL_OFFER_ROLE'."
    fi
  else
    error "Realm role '$CREDENTIAL_OFFER_ROLE' does not exist in realm '$KEYCLOAK_REALM'."
  fi
else
  log "Skipping '$CREDENTIAL_OFFER_ROLE' role assignment (disabled)."
fi

# -----------------------------------------------------------------------------
# Generate user key proof if needed
# -----------------------------------------------------------------------------
if [ ! -f "$PROJECT_TARGET_DIR/user_key_proof_header.json" ]; then
  log "Generating keypair for user..."
  . "$WORK_DIR/src/utils/crypto/generate_user_key.sh"
  success "User keyproof generated."
else
  warn "User key proof header already exists."
fi

success "Script execution completed."
