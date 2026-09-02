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

# Resolve Francis user ID once for reuse below
FRANCIS_USER_ID=$(kcadm get users -r "$KEYCLOAK_REALM" -q username="$USERS_FRANCIS_NAME" --fields id | jq -r '.[0].id')

# -----------------------------------------------------------------------------
# Grant verifiable credentials (Keycloak 26.7+ only)
# Query the running server, not config — KEYCLOAK_VERSION (tarball) and
# KEYCLOAK_IMAGE_TAG (docker) are independent and may diverge.
# -----------------------------------------------------------------------------
KC_MAJOR_MINOR=""
KC_VERSION_RAW=""

KC_VERSION_RAW=$(kcadm get serverinfo 2>/dev/null | jq -r '.systemInfo.version // empty' 2>/dev/null) || KC_VERSION_RAW=""

if [[ -n "$KC_VERSION_RAW" ]] && [[ "$KC_VERSION_RAW" != *"SNAPSHOT"* ]]; then
  if [[ "$KC_VERSION_RAW" =~ ^([0-9]+)\.([0-9]+) ]]; then
    KC_MAJOR_MINOR="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  fi
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
  log "Keycloak $KC_VERSION_RAW (>= 26.7). Granting verifiable credentials..."

  CONFIG_FILE="$WORK_DIR/config.yaml"
  OVERRIDE_FILE="$WORK_DIR/config.override.yaml"
  CREDENTIAL_SCOPES=()

  if [[ -f "$CONFIG_FILE" ]]; then
    YQ_ARGS=("$CONFIG_FILE")
    [[ -f "$OVERRIDE_FILE" ]] && YQ_ARGS+=("$OVERRIDE_FILE")

    while IFS= read -r scope; do
      CREDENTIAL_SCOPES+=("$scope")
    done < <(
      yq eval-all '
        . as $item ireduce ({}; . * $item)
        | .users.francis.credential_scopes // []
        | map(envsubst)
        | .[]
      ' "${YQ_ARGS[@]}" 2>/dev/null
    )
  fi

  if [[ ${#CREDENTIAL_SCOPES[@]} -gt 0 ]]; then
    ADMIN_TOKEN=$(\
      curl -k -s --fail-with-body -X POST \
        "$KEYCLOAK_ADMIN_ADDR/realms/master/protocol/openid-connect/token" \
        --data-urlencode "client_id=admin-cli" \
        --data-urlencode "username=$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" \
        --data-urlencode "password=$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" \
        --data-urlencode "grant_type=password" |
      jq -er '.access_token'
    ) || ADMIN_TOKEN=""

    if [[ -z "$ADMIN_TOKEN" ]]; then
      warn "Failed to obtain admin token for credential grants."
    else
      for scope in "${CREDENTIAL_SCOPES[@]}"; do
        log "Granting credential scope '$scope' to '$USERS_FRANCIS_NAME'..."

        HTTP_CODE=$(curl -k -s -o /dev/null -w '%{http_code}' \
          -X POST "$KEYCLOAK_ADMIN_ADDR/admin/realms/$KEYCLOAK_REALM/users/$FRANCIS_USER_ID/vc/credentials" \
          -H 'Content-Type: application/json' \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -d "$(jq -n --arg scope "$scope" '{credentialScopeName: $scope}')")

        case "$HTTP_CODE" in
          200|201) success "Credential scope '$scope' granted." ;;
          409) warn "Credential scope '$scope' already granted; skipping." ;;
          *) warn "Could not grant '$scope' (HTTP $HTTP_CODE)." ;;
        esac
      done
    fi
  else
    warn "No credential_scopes configured for user '$USERS_FRANCIS_NAME'."
  fi
else
  if [[ -n "$KC_VERSION_RAW" ]] && [[ "$KC_VERSION_RAW" == *"SNAPSHOT"* ]]; then
    warn "SNAPSHOT build ($KC_VERSION_RAW); skipping credential grants (feature availability unknown)."
  elif [[ -z "$KC_MAJOR_MINOR" ]]; then
    warn "Could not determine Keycloak server version; skipping credential grants."
  else
    warn "Keycloak $KC_VERSION_RAW < 26.7; skipping credential grants."
  fi
fi

# -----------------------------------------------------------------------------
# Assign credential-offer-create role (when enabled)
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
