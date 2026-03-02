# Conformance Test: Pre-Authorized Code Flow

This directory contains scripts for running OID4VCI conformance tests using the **pre-authorized code flow**.

## Files

- **`send_credential_offer.sh`** — Sends a pre-authorized credential offer to the OpenID Foundation conformance test suite

## Quick Start

1. Ensure Keycloak is running and configured (`./keycloak-ssi.sh setup && ./keycloak-ssi.sh config`)

2. Send a pre-authorized credential offer to the test suite:
   ```bash
   ./src/conformance_pre-authorized-code/send_credential_offer.sh
   ```

## Flow Details

The script performs the following steps:

1. **Get user access token** — Authenticates as the test user via password grant
2. **Create credential offer** — Requests a pre-authorized credential offer URI from Keycloak (with `pre_authorized=true` and `username` parameter)
3. **Fetch credential offer JSON** — Retrieves the full credential offer using the nonce
4. **Send to test suite** — URL-encodes and POSTs the offer to the conformance test suite

## Notes

- The `pre_authorized=true` parameter requires a `username` to bind the offer to a specific user
- The credential offer will contain a `urn:ietf:params:oauth:grant-type:pre-authorized_code` grant with a pre-authorized code
