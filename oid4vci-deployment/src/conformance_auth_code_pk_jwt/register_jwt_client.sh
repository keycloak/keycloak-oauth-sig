#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Register jwt client in Keycloak
# This script creates/updates the openid4vc-rest-api-jwt client

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper.sh and initialize environment
source "$SCRIPT_DIR/../utils/helper.sh"
init_script

# Ensure KEYCLOAK_INSTALL_DIR is resolved
ensure_keycloak_install_dir_resolved

log "Waiting for Keycloak at ${KEYCLOAK_ADMIN_ADDR}..."
until curl -s -k "${KEYCLOAK_ADMIN_ADDR}/health" > /dev/null; do
    sleep 5
done
log "Keycloak is running."

# Configure kcadm truststore
kcadm config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$(kc_truststore_path)" || error "Failed to configure kcadm truststore"

# Configure admin credentials if not already set
if ! kcadm get realms --server "$KEYCLOAK_ADMIN_ADDR" --realm master > /dev/null 2>&1; then
    log "Configuring Keycloak admin credentials..."
    kcadm config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" || error "Failed to configure Keycloak admin credentials"
else
    log "Admin credentials already configured."
fi

log "Checking if JWT client 'openid4vc-rest-api-jwt' already exists..."
CLIENT_ID=$(kcadm get clients -r "$KEYCLOAK_REALM" --fields id,clientId --server "$KEYCLOAK_ADMIN_ADDR" | jq -r '.[] | select(.clientId=="openid4vc-rest-api-jwt") | .id')

if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" == "null" ]; then
    log "Creating new JWT client 'openid4vc-rest-api-jwt'..."
    cat "$SCRIPT_DIR/openid4vc-rest-api-jwt.json" | kcadm create clients -r "$KEYCLOAK_REALM" -o -f - --server "$KEYCLOAK_ADMIN_ADDR" || error "Failed to create JWT client"
    CLIENT_ID=$(kcadm get clients -r "$KEYCLOAK_REALM" --fields id,clientId --server "$KEYCLOAK_ADMIN_ADDR" | jq -r '.[] | select(.clientId=="openid4vc-rest-api-jwt") | .id')
    log "JWT client created successfully."
else
    log "JWT client 'openid4vc-rest-api-jwt' already exists. Updating..."
    cat "$SCRIPT_DIR/openid4vc-rest-api-jwt.json" | kcadm update clients/$CLIENT_ID -r "$KEYCLOAK_REALM" -o -f - --server "$KEYCLOAK_ADMIN_ADDR" || error "Failed to update JWT client"
    log "JWT client updated successfully."
fi



log "JWT client ID: $CLIENT_ID"

log "=== JWT Client Configuration for Conformance Testing ==="
log "Client ID: openid4vc-rest-api-jwt"
log "Authentication Type: Private Key JWT (client-jwt)"
log "Signing Algorithm: ES256"
log "Key ID: key-1"

log ""

log "=== Conformance Test Configuration ==="
log "For the conformance test, configure:"
log "1. Client ID: openid4vc-rest-api-jwt"
log "2. Authentication Type: private_key_jwt"
log "3. Signing Algorithm: ES256"
log "4. Redirect URI: https://demo.certification.openid.net/test/a/keycloak-oid4vci-test/callback"
log ""

success "JWT client setup completed successfully!"
