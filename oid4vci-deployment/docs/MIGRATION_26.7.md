## Migrating `oid4vci-deployment` to Keycloak 26.7.0

Keycloak **26.7.0** keeps OID4VCI experimental but splits several previously always-on behaviors into dedicated feature flags and admin APIs. This checklist brings the local harness from **26.6.3** up so pre-authorized and offer-based issuance works again.

### Checklist

1. **Enable the REST credential-offer feature**  
   Set `keycloak.enable_credential_offer_create: true` so `KEYCLOAK_FEATURES` includes `oid4vc-vci-rest-credential-offer`. Without it, `create-credential-offer` returns that REST credential offer is not enabled.

2. **Enable pre-authorized code**  
   Set `keycloak.enable_preauth_code: true` so `KEYCLOAK_FEATURES` includes `oid4vc-vci-preauth-code`. Pre-auth grants were moved off the base `oid4vc-vci` feature in 26.7.

3. **Grant per-user verifiable credentials**  
   On 26.7+, offers and issuance require an explicit user VC grant (`users/{id}/vc/credentials`) for each credential scope. `keycloak-ssi config` grants Identity, Steuerberater, and KMA for the demo user.

4. **Prefer `create-credential-offer`**  
   Use `GET .../protocol/oid4vc/create-credential-offer` as the primary path. Retrieve the offer from `.../credential-offer/{nonce}` using the `{ issuer, nonce }` response. Legacy `credential-offer-uri` returns HTTP 404 on 26.7 and is only a fallback for older Keycloak.

5. **Expect built-in `oid4vc_natural_person_*` metadata**  
   Issuer metadata may include Keycloak-built-in configurations (`oid4vc_natural_person_jwt`, `oid4vc_natural_person_sd`) in addition to the demo scopes. Demos and validation assert that **required** configuration IDs exist; they do **not** require an exact configuration count of three. See [Built-in natural person credentials](#built-in-natural-person-credentials).

### Sample `config.override.yaml` for 26.7 demos

```yaml
keycloak:
  enable_preauth_code: true
  enable_credential_offer_create: true

keycloak_image:
  tag: "26.7.0"
```

Copy from `config.override.example.yaml` and adjust as needed. After changing feature flags, recreate the Keycloak container so `KC_FEATURES` is applied.

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

Confirm container features include both gated flags, for example:

```bash
docker compose exec app printenv KC_FEATURES
# expect: oid4vc-vci,oid4vc-vci-preauth-code,oid4vc-vci-rest-credential-offer
```

### Built-in natural person credentials

On 26.7.0, `credential_configurations_supported` can list Keycloak’s built-in natural-person configurations alongside this repo’s demo credentials.

**Chosen approach:** keep demos and `config` validation on IdentityCredential, SteuerberaterCredential, and KMACredential. Assert each required ID is present in metadata; ignore extra built-ins. Do not disable built-ins unless a future Keycloak option makes that straightforward for local demos.

Inventory of metadata checks in this tree:

| Location | Behavior |
| -------- | -------- |
| `src/deployment/1.oid4vci_test_deployment.sh` | Asserts each name from `client-scope-config.json` exists under `credential_configurations_supported` (presence, not count). |

### Upstream references

- [Keycloak 26.7.0 release announcement](https://www.keycloak.org/2026/07/keycloak-2670-released)
- [Keycloak 26.7.0 GitHub release](https://github.com/keycloak/keycloak/releases/tag/26.7.0)
- [OID4VCI configuration (Server Administration Guide)](https://www.keycloak.org/docs/latest/server_admin/#_oid4vci)
- [Setting up Keycloak as a credential issuer with OpenID4VCI](https://www.keycloak.org/2026/01/issue-credentials-over-openid4vci)

Discovery context: [adorsys/keycloak-oid4vc#295](https://github.com/adorsys/keycloak-oid4vc/issues/295).
