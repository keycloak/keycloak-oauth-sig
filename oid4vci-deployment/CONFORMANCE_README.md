# Keycloak OID4VCI Conformance Testing Guide

This guide outlines the steps to start and configure Keycloak for OID4VCI conformance tests.

## 1. Prerequisites

### Ngrok
Start ngrok to expose your local Keycloak instance on port 8443.
```bash
ngrok http 8443
```
*Note: Ensure the public URL provided by ngrok matches the `hostname` in your `config.yaml`.*

### Database
Start the PostgreSQL database container.
```bash
docker compose up db -d
```

## 2. Configuration

Update `config.yaml` in the project root with your ngrok hostname and the appropriate target branch.

```yaml
keycloak:
  hostname: "your-ngrok-url.ngrok-free.app"
  target_branch: "oid4vci-conformance"
```

## 3. Keycloak Setup

### Start Keycloak
Run the setup script to download/build and start Keycloak with basic configurations.
```bash
./keycloak-ssi.sh setup
```

### Import Base Configuration
Import the OID4VCI realm and basic client/user settings.
```bash
./keycloak-ssi.sh import
```

## 4. Conformance-Specific Configuration

Navigate to the `src` directory for the following steps:
```bash
cd src
```

### Configure Attestation Trusted Keys
```bash
./conformance_attestation/configure_attestation_trusted_keys.sh \
  conformance_attestation/attestation_trusted_keys_with_x5c.json
```

### Configure JWT Client
Register the client specifically for Private Key JWT authentication tests.
```bash
./conformance_auth_code_pk_jwt/register_jwt_client.sh
```

## 5. Running Tests

When the conformance test suite is running and waiting for a credential offer, run the appropriate script based on the grant type being tested.

### For Authorization Code Flow (JWT Client)
```bash
cd src
./conformance_auth_code_pk_jwt/send_credential_offer_jwt.sh
```

### For Pre-Authorized Code Flow
```bash
cd src
./conformance_pre-authorized-code/send_credential_offer.sh
```

---

## Appendix: Custom Keys and Certificates

If you need to generate custom JWKs or certificates for testing (e.g., for the `x5c` header or `jwks` string):

1. Visit [mkjwk.org](https://mkjwk.org/).
2. Choose your desired algorithm (e.g., **ES256** for ECDSA or **RS256** for RSA).
3. Ensure you select "Signed JWT (RS256, ES256, etc.)" as the Use case.
4. You can provide your own X.509 certificate or have it generate a self-signed one.
5. Copy the resulting **Public Key JWK** or **Full Keypair** and use it in your client configuration (like `src/conformance_auth_code_pk_jwt/openid4vc-rest-api-jwt.json`).

