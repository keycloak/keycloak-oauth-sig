## Migrating `oid4vci-deployment` to Keycloak 26.7.0

Keycloak **26.7.0** keeps OID4VCI experimental but moves pre-authorized code and the `create-credential-offer` REST endpoint behind dedicated feature flags. The local harness already uses the programmatic `create-credential-offer` protocol endpoint; no credential-request script changes are required for 26.7.

### Checklist

1. **Use Keycloak 26.7.0**  
   The default Docker Compose image tag in `config.yaml` is `26.7.0`. For tarball/`setup`, set `keycloak.version` to `26.7.0` (or rely on `latest` once that resolves to 26.7.x).

2. **Enable pre-authorized code**  
   Set `keycloak.enable_preauth_code: true` so `KEYCLOAK_FEATURES` includes `oid4vc-vci-preauth-code`.

3. **Enable REST credential-offer creation**  
   Set `keycloak.enable_rest_credential_offer: true` so `KEYCLOAK_FEATURES` includes `oid4vc-vci-rest-credential-offer`. Without it, the `create-credential-offer` endpoint is disabled on 26.7+.

4. **Grant verifiable credentials to the demo user** 
   On 26.7+, issuance requires an explicit per-user VC grant for each credential scope (IdentityCredential, SteuerberaterCredential, KMACredential). Grant these in the Admin Console for the demo user, or via the Admin API if you automate setup elsewhere. The `keycloak-ssi config` script does **not** perform this step.

5. **Recreate Keycloak after flag changes**  
   Restart or recreate the Keycloak container so `KC_FEATURES` picks up the new flags.

### Sample `config.override.yaml`

```yaml
keycloak:
  enable_preauth_code: true
  enable_rest_credential_offer: true
  enable_credential_offer_create: true
```

### Verification

```bash
# From oid4vci-deployment/
keycloak-ssi compose up -d
# Wait until https://localhost:8443 is up
keycloak-ssi config
keycloak-ssi test preauth IdentityCredential
keycloak-ssi test preauth SteuerberaterCredential
keycloak-ssi test preauth KMACredential
```

Confirm container features include the gated flags:

```bash
docker compose exec app printenv KC_FEATURES
# expect: oid4vc-vci,oid4vc-vci-preauth-code,oid4vc-vci-rest-credential-offer
```

### Upstream references

- [Keycloak 26.7.0 release announcement](https://www.keycloak.org/2026/07/keycloak-2670-released)
- [Keycloak 26.7.0 GitHub release](https://github.com/keycloak/keycloak/releases/tag/26.7.0)
- [OID4VCI configuration (Server Administration Guide)](https://www.keycloak.org/docs/latest/server_admin/#_oid4vci)
- [Setting up Keycloak as a credential issuer with OpenID4VCI](https://www.keycloak.org/2026/01/issue-credentials-over-openid4vci)

Discovery context: [adorsys/keycloak-oid4vc#295](https://github.com/adorsys/keycloak-oid4vc/issues/295).
