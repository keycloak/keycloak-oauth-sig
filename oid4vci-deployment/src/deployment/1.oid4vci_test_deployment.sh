#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# OID4VCI configuration script
# - Ensures Keycloak is running
# - Creates realm, registers key providers and clients
# - Configures client scopes and validates OID4VCI config
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
# Ensure Keycloak is running
# -----------------------------------------------------------------------------
keycloak_pid="$(get_keycloak_pid || true)"
if [[ -z "${keycloak_pid:-}" ]]; then
  error "Keycloak is not running. Start Keycloak using '0.start-kc-oid4vci.sh' first."
fi
log "Keycloak is running (PID: $keycloak_pid)."

# -----------------------------------------------------------------------------
# Authenticate admin
# -----------------------------------------------------------------------------
log "Authenticating admin user..."
kcadm config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$(kc_truststore_path)"
kcadm config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master \
    --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD"

# -----------------------------------------------------------------------------
# Create realm
# -----------------------------------------------------------------------------
log "Creating realm '$KEYCLOAK_REALM' (if not exists)..."
kcadm create realms -s realm="$KEYCLOAK_REALM" -s enabled=true >/dev/null 2>&1 || warn "Realm already exists; continuing."

# Keycloak 26+ requires java-keystore under data/{realm}/
mkdir -p "$KEYCLOAK_INSTALL_DIR/data/$KEYCLOAK_REALM"
cp "${PROJECT_TARGET_DIR}/kc_keystore.pkcs12" "$KEYCLOAK_INSTALL_DIR/data/$KEYCLOAK_REALM/kc_keystore.pkcs12"
KEYSTORE_PATH="kc_keystore.pkcs12"

# -----------------------------------------------------------------------------
# Configure key providers
# -----------------------------------------------------------------------------
log "Configuring key providers (ECDSA, RSA signing, RSA encryption)..."

ECDSA_JSON="$WORK_DIR/src/config/issuer_key_ecdsa.json"
RSA_JSON="$WORK_DIR/src/config/issuer_key_rsa.json"
RSA_ENC_JSON="$WORK_DIR/src/config/encryption_key_rsa.json"

configure_key_provider() {
  local json_template="$1"
  local alias="$2"

  if [[ ! -f "$json_template" ]]; then
    error "Key provider template not found: $json_template"
  fi

  jq --arg keystore "$KEYSTORE_PATH" \
     --arg keystorePassword "$KEYSTORE_PASSWORD" \
     --arg keystoreType "$KEYSTORE_TYPE" \
     --arg keyAlias "$alias" \
     --arg keyPassword "$KEYSTORE_PASSWORD" \
     '.config.keystore = [$keystore] |
      .config.keystorePassword = [$keystorePassword] |
      .config.keystoreType = [$keystoreType] |
      .config.keyAlias = [$keyAlias] |
      .config.keyPassword = [$keyPassword]' "$json_template"
}

register_key_provider() {
  local name="$1"
  local json_content="$2"

  local exists
  # Request id+name: --fields name alone omits .id and made the check always miss.
  exists=$(kcadm get components -r "$KEYCLOAK_REALM" --fields id,name \
            | jq -r --arg n "$name" '.[]? | select(.name == $n) | .id' | head -n1)

  if [[ -n "$exists" ]]; then
    warn "Key provider '$name' already exists (ID: $exists); skipping."
    return 0
  fi

  local err
  if ! err=$(echo "$json_content" | kcadm create components -r "$KEYCLOAK_REALM" -o -f - 2>&1); then
    error "Failed to register key provider '$name': $err"
  fi
  success "Registered key provider '$name'."
}

# ECDSA
if [[ -f "$ECDSA_JSON" ]]; then
  ECDSA_PROVIDER_JSON=$(configure_key_provider "$ECDSA_JSON" "$KEYSTORE_ALIASES_ECDSA_KEY")
  NAME=$(jq -r '.name' "$ECDSA_JSON")
  register_key_provider "$NAME" "$ECDSA_PROVIDER_JSON"
fi

# RSA Signing
if [[ -f "$RSA_JSON" ]]; then
  RSA_PROVIDER_JSON=$(configure_key_provider "$RSA_JSON" "$KEYSTORE_ALIASES_RSA_SIG_KEY")
  NAME=$(jq -r '.name' "$RSA_JSON")
  register_key_provider "$NAME" "$RSA_PROVIDER_JSON"
fi

# RSA Encryption
if [[ -f "$RSA_ENC_JSON" ]]; then
  RSA_ENC_PROVIDER_JSON=$(configure_key_provider "$RSA_ENC_JSON" "$KEYSTORE_ALIASES_RSA_ENC_KEY")
  NAME=$(jq -r '.name' "$RSA_ENC_JSON")
  register_key_provider "$NAME" "$RSA_ENC_PROVIDER_JSON"
fi

log "Custom key provider registration complete."

# -----------------------------------------------------------------------------
# Update realm attributes
# -----------------------------------------------------------------------------
log "Updating realm attributes..."
if [[ -f "$WORK_DIR/src/config/realm-attributes.json" ]]; then
  cat "$WORK_DIR/src/config/realm-attributes.json" | kcadm update realms/"$KEYCLOAK_REALM" -o -f - >/dev/null || error "Realm update failed"
else
  warn "realm-attributes.json not found; skipping realm attribute update."
fi

# -----------------------------------------------------------------------------
# Create client scopes
# -----------------------------------------------------------------------------
log "Creating client scopes..."
if [[ -f "$WORK_DIR/src/config/client-scope-config.json" ]]; then
  CLIENT_SCOPES_CONFIG=$(jq --arg ISSUER_DID "$KEYCLOAK_ISSUER_DID" 'map(.attributes["vc.issuer_did"] = $ISSUER_DID)' "$WORK_DIR/src/config/client-scope-config.json")
  echo "$CLIENT_SCOPES_CONFIG" | jq -c '.[]' | while read -r scope; do
    echo "$scope" | kcadm create client-scopes -r "$KEYCLOAK_REALM" -f - >/dev/null 2>&1 || \
      warn "Client scope already exists; skipping."
  done
else
  warn "client-scope-config.json not found; skipping client scopes creation."
fi

# -----------------------------------------------------------------------------
# Create clients
# -----------------------------------------------------------------------------
log "Creating clients..."
CLIENTS_CONFIG_FILE="$WORK_DIR/src/config/clients-config.json"
CLIENT_SCOPE_CONFIG_FILE="$WORK_DIR/src/config/client-scope-config.json"

if [[ -f "$CLIENTS_CONFIG_FILE" && -f "$CLIENT_SCOPE_CONFIG_FILE" ]]; then
  # Dynamically get all scope names from client-scope-config.json
  OPTIONAL_SCOPES=$(jq '[.[].name]' "$CLIENT_SCOPE_CONFIG_FILE")

  jq -c '.[]' "$CLIENTS_CONFIG_FILE" | while read -r client; do
    CLIENT_ID=$(echo "$client" | jq -r '.clientId')
    
    # Add the dynamic optional scopes to the client configuration
    MODIFIED_CLIENT=$(echo "$client" | jq --argjson scopes "$OPTIONAL_SCOPES" '.optionalClientScopes = $scopes')

    if [[ "$CLIENT_ID" == "openid4vc-rest-api" ]]; then
      MODIFIED_CLIENT=$(echo "$MODIFIED_CLIENT" | jq \
        --arg CLIENT_SECRET "$CLIENTS_SECRET" \
        --arg ISSUER_BACKEND_URL "$ISSUER_BACKEND_URL" \
        --arg ISSUER_FRONTEND_URL "$ISSUER_FRONTEND_URL" \
        '.secret = $CLIENT_SECRET |
         .redirectUris += [$ISSUER_BACKEND_URL + "/*", "https://localhost:8443/callback"] |
         .webOrigins += [$ISSUER_BACKEND_URL, "https://localhost:8443"] |
         .attributes["post.logout.redirect.uris"] = ("##" + $ISSUER_FRONTEND_URL + "##" + $ISSUER_FRONTEND_URL + "/*")')
    elif [[ "$CLIENT_ID" == "oid4vc-demo-public" ]]; then
      MODIFIED_CLIENT=$(echo "$MODIFIED_CLIENT" | jq \
        --arg TEST_CLIENT_URL "$TEST_CLIENT_URL" \
        '.redirectUris = [$TEST_CLIENT_URL + "/*"] |
         .webOrigins = [$TEST_CLIENT_URL] |
         .attributes["post.logout.redirect.uris"] = ($TEST_CLIENT_URL + "##" + $TEST_CLIENT_URL + "/*")')
    fi

    echo "$MODIFIED_CLIENT" | kcadm create clients -r "$KEYCLOAK_REALM" -o -f - >/dev/null 2>&1 || \
      warn "Client '$CLIENT_ID' already exists; skipping."
  done
else
  warn "clients-config.json or client-scope-config.json not found; skipping client creation."
fi

# Validate OID4VCI configuration
# -----------------------------------------------------------------------------
log "Validating OID4VCI configuration..."
response=$(curl -ks "$KEYCLOAK_ADMIN_ADDR/.well-known/openid-credential-issuer/realms/$KEYCLOAK_REALM")
[[ -z "$response" ]] && error "No response from Keycloak OIDC credential issuer endpoint."

# Dynamically validate all credentials from the configuration file
jq -r '.[].name' "$CLIENT_SCOPE_CONFIG_FILE" | while read -r credential; do
  jq -e --arg c "$credential" '."credential_configurations_supported"[$c]' <<< "$response" >/dev/null || \
    error "Configuration missing: '$credential' not found in OID4VCI configuration."
done

success "Keycloak server is running and OID4VCI credentials are configured successfully."
log "Configuration script completed successfully."
