#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# OID4VCI Conformance Test - Send Credential Offer Script (Pre-Authorized Code)
# This script sends the credential offer to the OpenID Foundation conformance test suite
# using the pre-authorized code flow.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper.sh and initialize environment
source "$SCRIPT_DIR/../utils/helper.sh"
init_script

# Derive URLs from environment
NGROK_URL="https://$KEYCLOAK_HOSTNAME"
KEYCLOAK_REALM_URL="$NGROK_URL/realms/$KEYCLOAK_REALM"
TEST_SUITE_BASE_URL="https://demo.certification.openid.net/test/a/keycloak-oid4vci-test"
USERNAME="$USERS_FRANCIS_NAME"

log "=== OID4VCI Conformance Test - Send Credential Offer (Pre-Authorized Code) ==="
log "Keycloak URL: $KEYCLOAK_REALM_URL"
log "Test Suite URL: $TEST_SUITE_BASE_URL"
log "Target User: $USERNAME"
log ""

# Function to wait for user input
wait_for_user() {
    echo ""
    echo "Press Enter to continue to the next step..."
    read -r
    echo ""
}

# Step 1: Get a fresh user access token
log "Step 1: Getting fresh user access token..."

TOKEN_ENDPOINT="$KEYCLOAK_REALM_URL/protocol/openid-connect/token"

log "Running: curl -k -s -X POST $TOKEN_ENDPOINT ..."
wait_for_user

USER_ACCESS_TOKEN=$(curl -k -s -X POST "$TOKEN_ENDPOINT" \
    -d "client_id=openid4vc-rest-api" \
    -d "client_secret=$CLIENTS_SECRET" \
    -d "username=$USERNAME" \
    -d "password=$USERS_FRANCIS_PASSWORD" \
    -d "grant_type=password" \
    -d "scope=openid" | jq -r '.access_token')

if [ "$USER_ACCESS_TOKEN" = "null" ] || [ -z "$USER_ACCESS_TOKEN" ]; then
    error "Failed to get user access token"
fi

log "✅ Got fresh user access token: ${USER_ACCESS_TOKEN:0:50}..."

# Step 2: Get a fresh credential offer URI with pre-authorized code flow
log ""
log "Step 2: Getting fresh credential offer URI (pre-authorized code flow)..."
log "Note: pre_authorized=true (default) requires username parameter"
log "Running: curl -k -s -H \"Authorization: Bearer \$USER_ACCESS_TOKEN\" ..."
wait_for_user

CREDENTIAL_OFFER_URI=$(curl -k -s -H "Authorization: Bearer $USER_ACCESS_TOKEN" \
    "$KEYCLOAK_REALM_URL/protocol/oid4vc/credential-offer-uri?credential_configuration_id=IdentityCredential&type=uri&pre_authorized=true&username=$USERNAME")



if echo "$CREDENTIAL_OFFER_URI" | grep -q "Pre-Authorized credential offer requires a target user"; then
    error "Pre-authorized credential offer requires username parameter. Response: $CREDENTIAL_OFFER_URI"
fi

NONCE=$(echo $CREDENTIAL_OFFER_URI | jq -r '.nonce')
if [ "$NONCE" = "null" ] || [ -z "$NONCE" ]; then
    error "Failed to extract nonce from credential offer URI. Response: $CREDENTIAL_OFFER_URI"
fi

log "✅ Got offer session in Keycloak. Nonce: $NONCE"

# Step 3: Fetch the actual Credential Offer JSON from Keycloak using the nonce
log ""
log "Step 3: Fetching the actual Credential Offer JSON from Keycloak..."
log "Running: curl -k -s \"$KEYCLOAK_REALM_URL/protocol/oid4vc/credential-offer/\$NONCE\""
wait_for_user

CREDENTIAL_OFFER=$(curl -k -s "$KEYCLOAK_REALM_URL/protocol/oid4vc/credential-offer/$NONCE")

if [ "$CREDENTIAL_OFFER" = "null" ] || [ -z "$CREDENTIAL_OFFER" ]; then
    error "Failed to fetch credential offer JSON from Keycloak for nonce: $NONCE"
fi

log "✅ Fetched Registered Credential Offer from Keycloak:"
echo "$CREDENTIAL_OFFER" | jq .

# Verify that the credential offer contains pre-authorized code grant
if echo "$CREDENTIAL_OFFER" | jq -e '.grants."urn:ietf:params:oauth:grant-type:pre-authorized_code"' > /dev/null 2>&1; then
    log "✅ Credential offer contains pre-authorized code grant"
    PRE_AUTH_CODE=$(echo $CREDENTIAL_OFFER | jq -r '.grants."urn:ietf:params:oauth:grant-type:pre-authorized_code"."pre-authorized_code"')
    log "Pre-authorized code: ${PRE_AUTH_CODE:0:50}..."
else
    log "⚠️  Warning: Credential offer does not contain pre-authorized code grant"
fi

# Step 4: URL encode the credential offer and send to test suite
log ""
log "Step 4: URL encoding and sending credential offer to test suite..."
CREDENTIAL_OFFER_ENCODED=$(echo "$CREDENTIAL_OFFER" | jq -c . | jq -rR @uri)

log "Encoded credential offer: ${CREDENTIAL_OFFER_ENCODED:0:100}..."
log "Sending to: $TEST_SUITE_BASE_URL/credential_offer"
wait_for_user

RESPONSE=$(curl -k -s -X POST "$TEST_SUITE_BASE_URL/credential_offer?credential_offer=$CREDENTIAL_OFFER_ENCODED" \
    -H "Content-Type: application/json")

log "Test suite response:"
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    echo "$RESPONSE" | jq .
else
    echo "$RESPONSE"
fi

# Check the response
log ""
log "=== Response Analysis ==="
if echo "$RESPONSE" | grep -q "authorization_details"; then
    log "✅ SUCCESS: Test suite received the credential offer!"
    log ""
    log "📋 Next Steps:"
    log "1. Check the test suite dashboard for detailed results"
    log ""
    log "🔗 Test Suite Dashboard: $TEST_SUITE_BASE_URL"
elif echo "$RESPONSE" | grep -q "error"; then
    log "⚠️  Test suite returned an error:"
    echo $RESPONSE | jq .
else
    log "✅ Pre-authorized code flow credential offer sent successfully!"
    log "The test suite should now be processing the pre-authorized code flow."
    log ""
    log "📋 Next Steps:"
    log "1. Check the test suite dashboard"
    log ""
    log "🔗 Test Suite Dashboard: $TEST_SUITE_BASE_URL"
fi

# Summary
log ""
log "=== Script Completed ==="
log "🔗 Key URLs:"
log "- Test Suite: $TEST_SUITE_BASE_URL"
log "- Keycloak Admin: $NGROK_URL/admin"
log "- Credential Issuer: $KEYCLOAK_REALM_URL/.well-known/openid-credential-issuer"
log ""
