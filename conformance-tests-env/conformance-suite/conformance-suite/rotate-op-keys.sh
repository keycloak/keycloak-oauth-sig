#!/bin/bash

# Rotates the realm's signing keys for the oidcc-server-rotate-keys test.
# run-test-plan.py calls this script just before starting the test (see Dockerfile).
#
# A new RS256 key is added with a lower priority than the existing key:
# it is published in jwks_uri (new key), the existing key remains (old key),
# and the existing key keeps signing tokens so that tests running in parallel are not affected.

set -e

KEYCLOAK_URL=${KEYCLOAK_URL:-http://keycloak:8080/auth}
KEYCLOAK_REALM=${KEYCLOAK_REALM:-test}
KEYCLOAK_USER=${KEYCLOAK_USER:-admin}
KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD:-admin}
NEW_KEY_PRIORITY=${NEW_KEY_PRIORITY:-50}

echo "`date '+%Y-%m-%d %H:%M:%S'`: rotating signing keys of realm ${KEYCLOAK_REALM}"

TOKEN=$(curl -sf -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -d grant_type=password -d client_id=admin-cli \
    --data-urlencode "username=${KEYCLOAK_USER}" --data-urlencode "password=${KEYCLOAK_PASSWORD}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

REALM_ID=$(curl -sf -H "Authorization: Bearer ${TOKEN}" "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')

curl -sf -X POST "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/components" \
    -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
    -d @- <<EOF
{
    "name": "rsa-rotated-$(date '+%Y%m%d%H%M%S')",
    "providerId": "rsa-generated",
    "providerType": "org.keycloak.keys.KeyProvider",
    "parentId": "${REALM_ID}",
    "config": {
        "priority": ["${NEW_KEY_PRIORITY}"],
        "enabled": ["true"],
        "active": ["true"],
        "algorithm": ["RS256"],
        "keySize": ["2048"]
    }
}
EOF

echo "`date '+%Y-%m-%d %H:%M:%S'`: added a new RS256 signing key (priority ${NEW_KEY_PRIORITY})"
