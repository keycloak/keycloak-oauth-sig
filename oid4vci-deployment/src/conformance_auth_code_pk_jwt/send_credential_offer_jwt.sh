#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# OID4VCI Conformance Test - Send Credential Offer Script (JWT Client)
# This script sends the credential offer to the OpenID Foundation conformance test suite
# using the JWT client configuration for authorization code flow

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper.sh and initialize environment
source "$SCRIPT_DIR/../utils/helper.sh"
init_script

# Derive URLs from environment
NGROK_URL="${KEYCLOAK_EXTERNAL_ADDR:-https://$KEYCLOAK_HOSTNAME}"
KEYCLOAK_REALM_URL="$NGROK_URL/realms/$KEYCLOAK_REALM"
TEST_SUITE_BASE_URL="https://demo.certification.openid.net/test/a/keycloak-oid4vci-test"

log "=== OID4VCI Conformance Test - Send Credential Offer (JWT Client) ==="
log "Keycloak URL: $KEYCLOAK_REALM_URL"
log "Test Suite URL: $TEST_SUITE_BASE_URL"
log "Client ID: openid4vc-rest-api-jwt"
log "Credential Configuration ID: IdentityCredential"
log ""

# Function to wait for user input
wait_for_user() {
    echo ""
    echo "Press Enter to continue to the next step..."
    read -r
    echo ""
}

# Step 1: Get a fresh user access token using Private Key JWT authentication
log "Step 1: Getting fresh user access token (Private Key JWT auth)..."

TOKEN_ENDPOINT="$NGROK_URL/realms/$KEYCLOAK_REALM/protocol/openid-connect/token"

# Generate client_assertion JWT signed with ES256
log "Generating client_assertion JWT..."
CLIENT_ASSERTION=$(python3 "$SCRIPT_DIR/generate_client_assertion.py" "openid4vc-rest-api-jwt" "$TOKEN_ENDPOINT")

if [ -z "$CLIENT_ASSERTION" ]; then
    error "Failed to generate client_assertion JWT"
fi

log "Client assertion generated (first 50 chars): ${CLIENT_ASSERTION:0:50}..."
log "Running: curl -k -s -X POST $TOKEN_ENDPOINT ..."
wait_for_user

USER_ACCESS_TOKEN=$(curl -k -s -X POST "$TOKEN_ENDPOINT" \
    -d "client_id=openid4vc-rest-api-jwt" \
    -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    -d "client_assertion=$CLIENT_ASSERTION" \
    -d "username=$USERS_FRANCIS_NAME" \
    -d "password=$USERS_FRANCIS_PASSWORD" \
    -d "grant_type=password" \
    -d "scope=openid" | jq -r '.access_token')



if [ "$USER_ACCESS_TOKEN" = "null" ] || [ -z "$USER_ACCESS_TOKEN" ]; then
    error "Failed to get user access token"
fi

log "✅ Got fresh user access token: ${USER_ACCESS_TOKEN:0:50}..."


# Step 2: Create a registered credential offer via Keycloak
log ""
log "Step 2: Creating registered credential offer via Keycloak..."
log "This will create an internal CredentialOfferState in Keycloak."
wait_for_user

# 1. First, get the offer URI (this creates the session state in Keycloak)
OFFER_URI_RESPONSE=$(curl -k -s -X GET "$KEYCLOAK_REALM_URL/protocol/oid4vc/credential-offer-uri?credential_configuration_id=IdentityCredential&pre_authorized=false&client_id=openid4vc-rest-api-jwt&type=uri" \
    -H "Authorization: Bearer $USER_ACCESS_TOKEN")

NONCE=$(echo "$OFFER_URI_RESPONSE" | jq -r '.nonce')
if [ "$NONCE" = "null" ] || [ -z "$NONCE" ]; then
    error "Failed to create offer session in Keycloak. Response: $OFFER_URI_RESPONSE"
fi

# 2. Fetch the actual Credential Offer JSON from Keycloak using the nonce
# This ensures we send the exact JSON that Keycloak expects
CREDENTIAL_OFFER=$(curl -k -s -X GET "$NGROK_URL/realms/$KEYCLOAK_REALM/protocol/oid4vc/credential-offer/$NONCE")

if [ "$CREDENTIAL_OFFER" = "null" ] || [ -z "$CREDENTIAL_OFFER" ]; then
    error "Failed to fetch credential offer JSON from Keycloak for nonce: $NONCE"
fi

log "✅ Fetched Registered Credential Offer from Keycloak:"
echo "$CREDENTIAL_OFFER" | jq .

# Step 3: URL encode the credential offer and send to test suite
log ""
log "Step 3: URL encoding and sending credential offer to test suite..."
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
    log "2. The test suite will now use the JWT client for authentication"
    log ""
    log "🔗 Test Suite Dashboard: $TEST_SUITE_BASE_URL"
elif echo "$RESPONSE" | grep -q "error"; then
    log "⚠️  Test suite returned an error:"
    echo $RESPONSE | jq .
else
    log "✅ Authorization code flow credential offer sent successfully!"
    log "The test suite should now be processing the authorization code flow with JWT client."
    log ""
    log "📋 Next Steps:"
    log "1. Check the test suite dashboard"
    log "2. The test will use authorization_code grant type"
    log "3. The test will use client_id: openid4vc-rest-api-jwt"
    log "4. The test will use Private Key JWT authentication with ES256"
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
log "📋 JWT Client Configuration:"
log "- Client ID: openid4vc-rest-api-jwt"
log "- Grant Type: authorization_code"
log "- Authentication: Private Key JWT (client-jwt)"
log "- Key ID: key-1"
log "- Signing Algorithm: ES256 (ECDSA P-256)"
log "- Redirect URI: https://demo.certification.openid.net/test/a/keycloak-oid4vci-test/callback"
log ""
