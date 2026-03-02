#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Script to configure trusted keys for attestation proof validation in Keycloak OID4VCI
#
# Usage:
#   ./configure_attestation_trusted_keys.sh <jwks_file.json>
#
# Example:
#   ./configure_attestation_trusted_keys.sh attestation_trusted_keys.json

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper.sh and initialize environment
source "$SCRIPT_DIR/../utils/helper.sh"
init_script

# Ensure KEYCLOAK_INSTALL_DIR is resolved
ensure_keycloak_install_dir_resolved

log "=== Configure Attestation Trusted Keys ==="

# Check if jq is available
if ! command -v jq &> /dev/null; then
    error "jq is required but not installed. Please install jq first."
fi

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "  $0 <jwks_file.json>"
    echo ""
    echo "Example:"
    echo "  $0 attestation_trusted_keys.json"
    exit 1
fi

# Get JWKS file path
JWKS_FILE="$1"

# Resolve the JWKS file path
if [[ ! -f "$JWKS_FILE" ]]; then
    # If not found at provided path, try relative to script directory
    if [[ -f "$SCRIPT_DIR/$JWKS_FILE" ]]; then
        JWKS_FILE="$SCRIPT_DIR/$JWKS_FILE"
    else
        error "JWKS file not found: $JWKS_FILE (checked current directory and $SCRIPT_DIR)"
    fi
fi

if [ ! -f "$JWKS_FILE" ]; then
    error "JWKS file not found: $JWKS_FILE"
fi

log "Reading trusted keys from file: $JWKS_FILE"

# Extract public keys (remove 'd' parameter if present) and convert to array
TRUSTED_KEYS_JSON=$(jq -c '.keys[] | del(.d) | select(.kid != null)' "$JWKS_FILE" | jq -s '.')

if [ -z "$TRUSTED_KEYS_JSON" ] || [ "$TRUSTED_KEYS_JSON" = "[]" ]; then
    error "No valid keys found in JWKS file. Ensure keys have 'kid' field."
fi

# Display the trusted keys that will be configured
log "Trusted keys to configure:"
echo "$TRUSTED_KEYS_JSON" | jq .

# Get admin token
log "Obtaining admin token..."
kcadm config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$(kc_truststore_path)" 2>/dev/null || true

kcadm config credentials \
    --server "$KEYCLOAK_ADMIN_ADDR" \
    --realm master \
    --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" \
    --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" || \
    error "Failed to authenticate with Keycloak admin"

# Check if realm exists, create if it doesn't
log "Checking if realm '$KEYCLOAK_REALM' exists..."
if ! kcadm get realms/"$KEYCLOAK_REALM" --server "$KEYCLOAK_ADMIN_ADDR" > /dev/null 2>&1; then
    log "Realm '$KEYCLOAK_REALM' does not exist. Creating it..."
    kcadm create realms \
        -s realm="$KEYCLOAK_REALM" \
        -s enabled=true \
        --server "$KEYCLOAK_ADMIN_ADDR" || \
        error "Failed to create realm '$KEYCLOAK_REALM'"
    success "Realm '$KEYCLOAK_REALM' created successfully"
else
    log "Realm '$KEYCLOAK_REALM' already exists"
fi

# Update realm attribute
log "Updating realm attribute: oid4vc.attestation.trusted_keys"
log "Realm: $KEYCLOAK_REALM"

# Convert the JSON array to a compact string for the realm attribute
# Realm attributes are stored as strings, so we need to pass the JSON as a string
TRUSTED_KEYS_STRING=$(echo "$TRUSTED_KEYS_JSON" | jq -c .)

# Create JSON payload for realm update
REALM_UPDATE_JSON=$(jq -n \
    --arg trusted_keys_str "$TRUSTED_KEYS_STRING" \
    '{
        "attributes": {
            "oid4vc.attestation.trusted_keys": $trusted_keys_str
        }
    }')

log "Realm update payload:"
echo "$REALM_UPDATE_JSON" | jq .

# Use kcadm to update the realm by piping JSON via stdin
echo "$REALM_UPDATE_JSON" | kcadm update realms/"$KEYCLOAK_REALM" -f - --server "$KEYCLOAK_ADMIN_ADDR" || \
    error "Failed to update realm attribute"



success "Successfully configured trusted keys for attestation proof validation"
log ""
log "Summary:"
log "- Realm: $KEYCLOAK_REALM"
log "- Attribute: oid4vc.attestation.trusted_keys"
log "- Number of keys: $(echo "$TRUSTED_KEYS_JSON" | jq 'length')"
log ""
log "Key IDs configured:"
echo "$TRUSTED_KEYS_JSON" | jq -r '.[].kid' | while read -r kid; do
    log "  - $kid"
done
