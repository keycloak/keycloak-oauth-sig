# Conformance Test: Authorization Code Flow with Private Key JWT

This directory contains scripts and configuration for running OID4VCI conformance tests using the **authorization code flow** with **Private Key JWT (client-jwt)** client authentication.

## Files

- **`send_credential_offer_jwt.sh`** — Sends a credential offer to the OpenID Foundation conformance test suite
- **`register_jwt_client.sh`** — Registers/updates the `openid4vc-rest-api-jwt` client in Keycloak
- **`openid4vc-rest-api-jwt.json`** — Client configuration for the JWT-authenticated client

## Quick Start

1. Ensure Keycloak is running and configured (`./keycloak-ssi.sh setup && ./keycloak-ssi.sh config`)

2. Register the JWT client:
   ```bash
   ./src/conformance_auth_code_pk_jwt/register_jwt_client.sh
   ```

3. Send a credential offer to the test suite:
   ```bash
   ./src/conformance_auth_code_pk_jwt/send_credential_offer_jwt.sh
   ```

## JWT Client Configuration

| Setting | Value |
|---|---|
| Client ID | `openid4vc-rest-api-jwt` |
| Authentication Type | `private_key_jwt` (client-jwt) |
| Signing Algorithm | ES256 (ECDSA P-256) |
| Key ID | `key-1` |
| Grant Type | `authorization_code` |
| Redirect URI | `https://demo.certification.openid.net/test/a/keycloak-oid4vci-test/callback` |
