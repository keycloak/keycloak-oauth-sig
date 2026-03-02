# Attestation Proof Configuration

This directory contains configuration files and scripts for setting up attestation proof validation in Keycloak OID4VCI.

## Files

- **`attestation_trusted_keys.json`** - JWKS file containing trusted public keys for attestation proof validation
- **`configure_attestation_trusted_keys.sh`** - Script to configure trusted keys in Keycloak realm
- **`attestation_trusted_keys_with_x5c.json`** - JWKS file with x5c certificate chain included

## Quick Start

1. Ensure your trusted keys are in `attestation_trusted_keys.json` (public keys only, no private keys)

2. Run the configuration script:
   ```bash
   ./src/conformance_attestation/configure_attestation_trusted_keys.sh attestation_trusted_keys.json
   ```

3. The script will:
   - Extract public keys from the JWKS file
   - Authenticate with Keycloak admin
   - Configure the `oid4vc.attestation.trusted_keys` realm attribute

## Current Configuration

The `attestation_trusted_keys.json` file contains:
- **Key ID**: `key-1`
- **Algorithm**: ES256
- **Curve**: P-256

## Usage in Conformance Tests

When configuring the conformance test suite:
- **Credential Proof Type Hint**: `jwt` (or `attestation` if supported)
- **Key Attestation JWKS**: Use the full JWKS with private key (generate separately using mkjwk.org)

The public key in this directory is what Keycloak uses to verify attestation JWT signatures.
