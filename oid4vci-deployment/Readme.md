# Keycloak as an OID4VC Issuer

Bring OpenID for Verifiable Credential Issuance (OID4VCI) to a vanilla Keycloak with a single CLI. This repo contains a tiny-but-complete toolkit: Docker compose files, scripted setup, and curl-based request flows so you can evaluate VC issuance locally.

## What You Get

- Opinionated Keycloak instance (Postgres + HTTPS) with the `oid4vc-vci` feature enabled.
- `keycloak-ssi` CLI that wraps every script under `src/` and handles configuration, setup, and testing.
- Ready-made credential definitions (IdentityCredential, SteuerberaterCredential, KMACredential), an opt-in mDoc sample, and a demo user for both pre-authorized and authorization-code flows.

## TL;DR

> Prereqs: Java 17+ (Java 21 for `import`), `openssl`, `keytool`, `jq`, `yq`, `docker`, and optionally `figlet` for pretty banners.
>
> - `docs/CLI_GUIDE.md` - 🚨 extended CLI reference and command list. Please take a look since it will help you understand how to interact with this repo.

### Optional: Install CLI Globally

A CLI tool to interact with this project was built in the keycloak-ssi.sh file. This can be installed to be available globally or you can directly interact with the scipt. To install:

```bash
./keycloak-ssi.sh install
```

To know more about the tool:

```bash
keycloak-ssi help
```

### Quick Local Spin-Up (Docker Compose)

```bash
keycloak-ssi compose up -d   # Keycloak (app) and Postgres (db)
```

**⚠️ Important:** After running the command above, ensure that Keycloak is fully started and accessible at `https://localhost:8443` before running any further commands.

```bash
keycloak-ssi config          # configures realm, clients, demo users, keys (runs inside cli container)
keycloak-ssi test preauth IdentityCredential
```

- Uses `config.yaml` plus overrides to drive runtime settings.
- Admin console available at `${KEYCLOAK_ENDPOINTS_ADMIN_ADDR}` (defaults to `https://localhost:8443`).

### Stop / Clean

```bash
keycloak-ssi compose down -v    # stop containers
keycloak-ssi stop            # stop a tarball-based run
```

## How It Works

1. `setup` builds Keycloak from either an official tarball or a source branch (controlled by `keycloak.version` and `keycloak.target_branch`).
2. `compose` runs the bundled `docker-compose.yml` (Postgres + Keycloak).
3. `config` runs inside the `cli` container and applies the realm via kcadm scripts, creating credential definitions as client scopes.
4. `test` runs inside the `cli` container and issues credentials through curl, covering pre-authorized and authorization-code + PKCE flows.

## Configuration Model

| Layer                  | Description                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `config.yaml`          | Base defaults for Keycloak, database, credentials, demo users.                                                               |
| `config.override.yaml` | Optional environment-specific, overrides config.yaml.                                                                        |
| Environment vars       | Highest priority. Use `SECTION_KEY=value` (e.g., `KEYCLOAK_HTTPS_PORT=9443`). Values inside YAML may reference `${ENV_VAR}`. |

Key settings to review:
Our config contains many settings to configure Keycloak. The more relevant are:

- `keycloak.version` / `keycloak.target_branch`: decide between upstream tarball and custom branch (set version to `999.0.0-SNAPSHOT` to trigger branch build).
- `keycloak.https_port`, `keycloak.hostname`: align with your local HTTPS requirements.
- `database.*`: container DB parameters such as port, username, password.
- `users.*`: Users that will be added to keycloak.
- `credentials.enabled`: comma-separated credential client scopes to configure. The default contains the three release-compatible SD-JWT credentials and excludes the experimental mDoc sample.

## Experimental mDoc Sample

`MobileDrivingLicence` demonstrates an `mso_mdoc` credential using:

- DocType `org.iso.18013.5.1.mDL` and namespace `org.iso.18013.5.1`.
- `ES256` issuer signing, `cose_key` holder binding, and JWT proof of possession.
- The demo user's `firstName` and `lastName` as `given_name` and `family_name`, plus the static specimen document number `D1234567`.

The sample is excluded from `credentials.enabled` by default because mDoc support is not in Keycloak 26.7.x. Use a Keycloak main/nightly build that contains the experimental `oid4vc-mdoc` feature. Enabling the sample automatically adds that feature to `KEYCLOAK_FEATURES`.

This is an issuance/interoperability sample, not a complete ISO/IEC 18013-5 mDL profile. A production mDL must also supply the remaining mandatory data elements with their required CBOR types, including tagged dates, portrait bytes, and structured driving privileges, and must use a production document-signer certificate and trust chain.

### Run and test with Keycloak nightly

Create `config.override.yaml` next to `config.yaml`:

```yaml
keycloak:
  enable_preauth_code: true
  enable_credential_offer_create: true
  enable_rest_credential_offer: true

keycloak_image:
  tag: "nightly"

credentials:
  enabled: "IdentityCredential,SteuerberaterCredential,KMACredential,MobileDrivingLicence"
```

Recreate and configure the deployment so the changed feature list is applied at server startup:

```bash
./keycloak-ssi.sh compose up -d --force-recreate
./keycloak-ssi.sh config
```

Keycloak 26.7+ requires an explicit per-user grant. Grant the `MobileDrivingLicence` credential to `francis` in the Admin Console, or use the Admin REST API:

```bash
ADMIN_TOKEN=$(curl -sk \
  -d client_id=admin-cli \
  -d username=admin \
  -d password=admin \
  -d grant_type=password \
  https://localhost:8443/realms/master/protocol/openid-connect/token | jq -r .access_token)

USER_ID=$(curl -sk \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  'https://localhost:8443/admin/realms/oid4vc-vci/users?username=francis&exact=true' | jq -r '.[0].id')

curl -ski -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"credentialScopeName":"MobileDrivingLicence"}' \
  "https://localhost:8443/admin/realms/oid4vc-vci/users/$USER_ID/vc/credentials"
```

Verify discovery and issue the credential:

```bash
curl -sk \
  https://localhost:8443/.well-known/openid-credential-issuer/realms/oid4vc-vci \
  | jq '.credential_configurations_supported.MobileDrivingLicence'

./keycloak-ssi.sh test preauth MobileDrivingLicence
./keycloak-ssi.sh test authcode MobileDrivingLicence
```

The discovery entry should report `format: "mso_mdoc"`, DocType `org.iso.18013.5.1.mDL`, `cose_key` binding, and ES256 (COSE algorithm `-7`). The issuance response contains the base64url-encoded CBOR `IssuerSigned` document in its `credential` value.

## Credential Request Playbooks

### Pre-Authorized Code + Key Binding

```bash
keycloak-ssi test preauth IdentityCredential
```

What happens:

1. Generates a wallet key pair.
2. Signs a proof of possession.
3. Calls the credential endpoint with the pre-authorized code provided during configuration.

### Authorization Code + PKCE

```bash
keycloak-ssi test authcode IdentityCredential
```

What happens:

1. Creates PKCE verifier/challenge.
2. Authenticates the demo user via the Keycloak auth endpoint.
3. Exchanges the auth code for a token using PKCE.
4. Requests IdentityCredential with key binding.

Both flows trust the self-signed TLS certificate generated by the setup scripts, so the curl helpers add `-k`. Swap in trusted certs for broader testing.

## Operational Notes

- **Verify Keycloak health**: `curl -k -s ${KEYCLOAK_ADMIN_ADDR}/realms/master` inside `cmd_setup` waits up to two minutes.
- **Certificates**: `generate-kc-certs.sh` produces the HTTPS cert/key and truststore referenced in `config.yaml`. Update passwords/paths there if you reuse existing certs.
- **Client scopes = credentials**: Each credential type is modeled as a client scope (see `src/config/client-scope-config.json`). Assign the scope to clients and add `"oid4vci.enabled": "true"` in client attributes.
- **Logs & artifacts**: `target/` holds Keycloak logs, downloaded tarballs, and generated keys. **Clean it if you need a fresh start.**

## Troubleshooting

- **CLI cannot find the project**: run commands from the repo root or reinstall via `./keycloak-ssi.sh install`.
- **`keycloak-ssi import` fails**: requires Java 21 because Keycloak Config CLI depends on it.
- **SSL errors from external tools**: replace the generated certificate with one trusted by your OS or disable `-k` only after adding trust.
- **Credential request rejected**: confirm the client has the correct client scopes and attributes, and that the user possesses mapped claims (see protocol mappers inside each scope).

## More Docs

- [README_Advanced.md](docs/README_Advanced.md) Here we stored our old readme. Contains important yet more advanced config info. Please refer to it if you want a deeper understanding of the repo.
