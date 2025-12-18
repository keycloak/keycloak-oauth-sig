# Keycloak as a Verifiable Credential Issuer with OID4VCI

This guide walks you through configuring Keycloak to issue Verifiable Credentials (VCs) using the OpenID for Verifiable Credential Issuance (OID4VCI) protocol.

## Checkout, Build, and Deploy Keycloak

### Prerequisites

Before proceeding, ensure you have the required tools installed.
See the [Prerequisites](./CLI_GUIDE.md#prerequisites) section for details.

### Setting Up Keycloak

You can set up Keycloak in one of two ways, based on your requirements:

1. **Using the Keycloak Tarball:** Downloads an official release from [Keycloak GitHub Releases](https://github.com/keycloak/keycloak/releases).
2. **Cloning and Building a Specific Keycloak Branch:** Builds Keycloak from a specific branch.

### Configuring the Setup Method

The setup behavior is determined automatically by the `setup-kc-oid4vci.sh` script based on the value of the `keycloak.version` variable in your `config.yaml` file.

- When `keycloak.version` is anything other than `999.0.0-SNAPSHOT`, the script downloads and installs the official Keycloak tarball (upstream).
- When `keycloak.version` is set to `999.0.0-SNAPSHOT`, the script clones and builds the custom Keycloak branch instead.

**To choose which setup method is used, simply set the desired value for `keycloak.version` in your `config.yaml` file.**

### Option 1: Using the Keycloak Tarball

Set `keycloak.version` to the desired official Keycloak version (e.g., `26.0.7`) in your `config.yaml` file and run:

```bash
./keycloak-ssi.sh setup
```

This will:

- Download and unpack the tarball (e.g., keycloak-26.0.7.tar.gz).
- Start Keycloak with OID4VCI feature on https://localhost:8443.

### Option 2: Cloning a Specific Branch

Set keycloak version and the desired branch in your `config.yaml` file, for example:

```bash
keycloak.version=999.0.0-SNAPSHOT
keycloak.target_branch=main
```

Then run:

```bash
./keycloak-ssi.sh setup
```

This will:

- Clone and build Keycloak from the specified branch.
- Start Keycloak with OID4VCI feature on https://localhost:8443.

## Alternative-1: Use Kc-config-cli to Configure Keycloak

To set up Keycloak for Verifiable Credential Issuance, we use a script that utilizes the **Keycloak Config CLI** tool. This script imports the necessary configurations into a dedicated realm.

### 1. **Check the `config.yaml` File**

Before running the configuration command `(./keycloak-ssi.sh import)`, make sure your `config.yaml` file is correctly configured.
This file contains the environment variables required for the script to connect to and configure your Keycloak server.

**Key variables to review:**

- `keycloak_endpoints.admin_addr`: URL of your Keycloak server.
- `keycloak.bootstrap.admin_username`: Admin username for Keycloak.
- `keycloak.bootstrap.admin_password`: Admin password for Keycloak.
- `keystore.path`: Keystore path

### 2. **Run the Configuration Script**

After verifying your `config.yaml` file, run the following command to configure your Keycloak environment:

```bash
./keycloak-ssi.sh import
```

This command imports the necessary Keycloak configuration using the settings defined in your `config.yaml` file.

> **Note**: Java 21 is required to run this script and complete the configuration successfully. Make sure your `JAVA_HOME` is set to a **Java 21** installation.

## Alternative-2: Manual Configuration Keycloak for Verifiable Credential Issuance

We can also configure Keycloak manually using the kcadm.sh tool. This shall be executed on the same machine, as it uses `kcadm.sh` on localhost to access the admin interface and shares generated keystore files with Keycloak.

### Prerequisites

Refer to the TLDR section for initial setup requirements.

### Script

After checking your `config.yaml` file, run the following command:

```bash
./keycloak-ssi.sh config
```

## Requesting Credentials

This project now supports both the `pre-authorized code` and `authorization code` grant types for requesting Verifiable Credentials (VCs). The authorization code flow, enhanced with Proof Key for Code Exchange (PKCE), provides additional security by preventing authorization code interception attacks. The following scripts demonstrate how to request credentials using these flows.

Uses only curl to access keycloak interfaces. The `-k` of curl disables ssl certificate validation.

### Request a Credential with Key Binding (Pre-Authorized Code Flow)

```bash
./keycloak-ssi.sh test preauth IdentityCredential
```

This command:

- Creates a key pair for the wallet.
- Signs a key proof.
- Requests an IdentityCredential with key binding using the pre-authorized code flow.

### Request a Credential with Key Binding (Authorization Code Flow with PKCE)

```bash
./keycloak-ssi.sh test authcode IdentityCredential
```

This command:

- Generates a PKCE code_verifier and code_challenge.
- Requests an authorization code via the Keycloak authorization endpoint.
- Exchanges the authorization code for an access token, including the code_verifier.
- Requests IdentityCredential with key binding.

> **Note**: To see which scripts the command runs, refer to the [Commands](./CLI_GUIDE.md#commands) section.

# Detailed Description

## Building and Deploying Keycloak

### Prerequisites

Refer to the TLDR section for initial setup requirements.

### The `config.yaml` File

All configuration values are now defined in `config.yaml`. Ensure this file is correctly set up before running any command.

### Using Keycloak with OID4VCI Support

The project uses the officially released version of Keycloak with OID4VCI support, and it also provides the option to clone and build a specific branch (e.g., for testing new features before integration).

### Cloning and Building Keycloak

The `setup-kc-oid4vci.sh` script simplifies the setup process. It either downloads a prebuilt tarball or builds Keycloak from source, depending on the `keycloak.version` value. **You do not need to set `KC_USE_UPSTREAM` manually.**

```bash
./keycloak-ssi.sh setup
```

This script sets up Keycloak for OID4VCI usage. See [Setting up keycloak](./README_Advanced.MD#setting-up-keycloak)

```bash
echo "unpacking keycloak ..."
tar xzf "$TAR_FILE" -C "$TOOLS_DIR" || { echo "Could not unpack Keycloak tarball"; exit 1; }
echo "Keycloak unpacked to $KC_INSTALL_DIR."
```

`$TAR_FILE`: The path to the Keycloak tarball, either the upstream tarball (if using the official Keycloak release) or the custom build (if building from source).

### Generating SSL Keys for Keycloak

In this documentation, we run Keycloak with SSL enabled. This ensures consistent behavior with production setups and helps avoid potential issues when accessing the administration interface or integrating with other applications.

The following script, [generate-kc-certs.sh](../src/utils/crypto/generate-kc-certs.sh), automates the process of creating a self-signed certificate for Keycloak. It then imports the certificate's public key into a truststore, which can be used by the Keycloak Admin CLI to establish a trusted connection.

The cert config file can be found at: [cert-config.txt](../src/utils/crypto/cert-config.txt)

```bash
#!/usr/bin/env bash
# Load environment variables
source "$WORK_DIR/src/utils/helper.sh"
init_script

 openssl req -newkey rsa:2048 -nodes \
        -keyout "$SSL_SERVER_KEY" -x509 -days 3650 \
        -out "$SSL_SERVER_CERT" -config "$WORK_DIR/src/utils/crypto/cert-config.txt" \
        -extensions v3_req

keytool -importcert -trustcacerts -noprompt \
        -alias localhost \
        -file "$SSL_SERVER_CERT" \
        -keystore "$SSL_TRUST_STORE" \
        -storepass "$SSL_TRUST_STORE_PASS"
```

### Keycloak Startup with SSL

After setting up Keycloak and generating SSL keys, you can start Keycloak with OID4VCI features enabled. Use the `0.start-kc-oid4vci.sh` script:

This script:

- Shuts down any running Keycloak instance.
- Prepares Keycloak by running the setup script `(setup-kc-oid4vci.sh)`.
- Starts the database container if not already running (Used for local development).
- Launches Keycloak with SSL, database connection, and OID4VCI support.

```bash
# Starts keycloak with OID4VCI feature

# Use org.keycloak.quarkus._private.IDELauncher if you want to debug through keycloak sources
KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" \
  exec bash -c "exec bin/kc.sh $START_COMMAND $DATABASE_OPTS --features=oid4vc-vci"
```

For external deployments, **ensure you update the Keycloak admin password** to a more secure value.

Recall the start and database commands in `config.yam;` file are:

```bash
start_command: "start --hostname-strict=false --https-port=${KEYCLOAK_HTTPS_PORT} --https-certificate-file=${SSL_SERVER_CERT} --https-certificate-key-file=${SSL_SERVER_KEY}"
database_opts: "--db postgres --db-url jdbc:postgresql://localhost:5432/keycloak --db-username postgres --db-password postgres"
```

## Configuring Keycloak to Service Verifiable Credentials

### Prerequisites

Refer to the TLDR section for initial setup requirements.

### All-in-One Deployment

All the steps outlined below can be executed by running the script `1.oid4vci_test_deployment.sh`.

### Keycloak Admin CLI

Although Keycloak provides various integrated ways to manage configurations, we use the `kcadm.sh` CLI tool. This approach allows readers to work directly in a shell for quick results. For more complex deployments, consider using [keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli).

### Accessing the Keycloak admin interface with SSL

The following lines will allow you to configure a truststore for used by `kcadm.sh` and obtain and administrator access token to perform administrative tasks.

```bash
# Set a trust store for kcadm.sh
"$KCADM" config truststore --trustpass "$SSL_TRUST_STORE_PASS" "$SSL_TRUST_STORE"
echo "Obtaining admin token..."
# Get admin token using environment variables for credentials
"$KCADM" config credentials --server "$KEYCLOAK_ADMIN_ADDR" --realm master \
    --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD"
```

### Issuer Identifier (DID)

In the decentralized identity ecosystem, a Decentralized Identifier (DID) serves as a unique identifier that resolves to a DID Document. This document contains information such as public keys and service endpoints for the associated entity. As a VC issuer, Keycloak requires a DID to identify itself. Other parties may dereference the DID Document (or its associated endpoint) to retrieve the cryptographic material needed to validate credentials issued by Keycloak.

**Issuer DID is now set by default.**

To override the default issuer DID, add or modify the `vc.issuer_did` attribute in the relevant client scope configuration. For example:

```json
{
  "name": "IdentityCredential",
  "protocol": "oid4vc",
  "attributes": {
    "vc.issuer_did": "did:web:vc.example.com"
  }
}
```

### Configuring a Keycloak ECDSA Signing Key for Verifiable Credentials

Just like a regular bearer token, Keycloak issues VCs. These can be in various formats, such as SD-JWT (JSON documents). Keycloak can sign VCs using its native RSA key pair or, as required by some pilot programs, an Elliptic Curve (EC) key pair. In the latter case, we'll generate the EC key and add it to Keycloak's configuration.

**1. Generating an ECDSA Key:**

We'll use the `keytool` command (part of the Java Development Kit) to create an ECDSA key pair:

```bash
keytool \
  -genkeypair \
  -keyalg EC \
  -keysize 256 \
  -keystore "${KEYCLOAK_KEYSTORE_FILE}" \
  -storepass "${KEYCLOAK_KEYSTORE_PASSWORD}" \
  -alias "${KEYCLOAK_KEYSTORE_ECDSA_KEY_ALIAS}" \
  -keypass "${KEYCLOAK_KEYSTORE_PASSWORD}" \
  -storetype "${KEYCLOAK_KEYSTORE_TYPE}" \
  -dname "CN=ECDSA Signing Key, OU=Keycloak, O=YourOrganization"
```

**2. Preparing the Keycloak Configuration:**

Next, we'll create a JSON file that describes the key to Keycloak. This file will be used by the `kcadm.sh` tool to add the key to the Keycloak configuration.

```json
{
  "id": "ecdsa-issuer-key",
  "name": "ecdsa-issuer-key",
  "providerId": "java-keystore",
  "providerType": "org.keycloak.keys.KeyProvider",
  "config": {
    "keystore": ["$KEYSTORE_PATH"],
    "keystoreType": ["$KEYSTORE_TYPE"],
    "keystorePassword": ["$KEYSTORE_PASSWORD"],
    "keyAlias": ["$KEYSTORE_ALIASES_ECDSA_KEY"],
    "keyPassword": ["$KEYSTORE_PASSWORD"],
    "active": ["true"],
    "priority": ["200"],
    "enabled": ["true"],
    "algorithm": ["ES256"]
  }
}
```

**Key points:**

- `providerId`: "java-keystore" refers to the Keycloak Java KeyStore key provider.
- `algorithm`: "ES256" specifies the ECDSA algorithm with SHA-256.

**3. Adding the Key to Keycloak:**

In order to fill up this template in a shell environment, we need a tool like `jq`, that can manipulate json files on the
command line (as mentioned in the prerequisites).

```bash
# Add concrete info and passwords to key provider
echo "Configuring ecdsa key provider..."
cat $WORK_DIR/issuer_key_ecdsa.json | \
  jq --arg keystore "$KEYCLOAK_KEYSTORE_FILE" \
  --arg keystorePassword "$KEYCLOAK_KEYSTORE_PASSWORD" \
  --arg keystoreType "$KEYCLOAK_KEYSTORE_TYPE" \
  --arg keyAlias "$KEYCLOAK_KEYSTORE_ECDSA_KEY_ALIAS" \
  --arg keyPassword "$KEYCLOAK_KEYSTORE_PASSWORD" \
  '.config.keystore = [$keystore] |
   .config.keystorePassword = [$keystorePassword] |
   .config.keystoreType = [$keystoreType] |
   .config.keyAlias = [$keyAlias] |
   .config.keyPassword = [$keyPassword]' \
  > $TARGET_DIR/issuer_key_ecdsa-tmp.json

jq --arg keystore "$KEYSTORE_PATH" \
     --arg keystorePassword "$KEYSTORE_PASSWORD" \
     --arg keystoreType "$KEYSTORE_TYPE" \
     --arg keyAlias "$alias" \
     --arg keyPassword "$KEYSTORE_PASSWORD" \
     '.config.keystore = [$keystore] |
      .config.keystorePassword = [$keystorePassword] |
      .config.keystoreType = [$keystoreType] |
      .config.keyAlias = [$keyAlias] |
      .config.keyPassword = [$keyPassword]' "$json_template"
```

**4. Adding the Key to the Keycloak Realm:**

The following Bash command adds an EC key to the Keycloak realm specified in the `config.yaml` file and configures it to produce JWS ES256 signatures (ECDSA on curve P-256):

```bash
# Register the EC-key with Keycloak
register_key_provider() {
  local name="$1"
  local json_content="$2"

  local exists
  exists=$("$KCADM" get components -r "$KEYCLOAK_REALM" --fields name \
            | jq -r --arg n "$name" '.[]? | select(.name == $n) | .id' | head -n1)

  if [[ -n "$exists" ]]; then
    warn "Key provider '$name' already exists (ID: $exists); skipping."
    return 0
  fi

  if ! echo "$json_content" | "$KCADM" create components -r "$KEYCLOAK_REALM" -o -f - >/dev/null 2>&1; then
    warn "Failed to register key provider '$name'; it already exists."
  fi
}

# ECDSA
if [[ -f "$ECDSA_JSON" ]]; then
  ECDSA_PROVIDER_JSON=$(configure_key_provider "$ECDSA_JSON" "$KEYSTORE_ALIASES_ECDSA_KEY")
  NAME=$(jq -r '.name' "$ECDSA_JSON")
  register_key_provider "$NAME" "$ECDSA_PROVIDER_JSON"
fi
```

### Defining VCs in Keycloak

**As of the latest version, Verifiable Credentials (VCs) are no longer configured at the realm level.**

#### Client Scope-Based Configuration

Each Verifiable Credential type is now represented as a dedicated Client Scope. All configuration for a credential including its metadata, supported claims, and protocol mappers is defined within the corresponding client scope. This approach enables fine-grained control and aligns with OID4VCI best practices.

**Example: Client Scope for a Verifiable Credential**

```json
{
  "name": "IdentityCredential",
  "protocol": "oid4vc",
  "attributes": {
    "include.in.token.scope": "true",
    "vc.credential_configuration_id": "IdentityCredential",
    "vc.credential_identifier": "IdentityCredential",
    "vc.format": "dc+sd-jwt",
    "vc.expiry_in_seconds": 31536000,
    "vc.verifiable_credential_type": "https://credentials.example.com/identity_credential",
    "vc.supported_credential_types": "identity_credential",
    "vc.credential_contexts": "https://credentials.example.com/identity_credential",
    "vc.cryptographic_binding_methods_supported": "jwk",
    "vc.credential_signing_alg": "ES256",
    "vc.display": "[{\"name\": \"Identity Credential\"}]",
    "vc.sd_jwt.number_of_decoys": "2",
    "vc.credential_build_config.sd_jwt.visible_claims": "iat,nbf",
    "vc.credential_build_config.hash_algorithm": "sha-256",
    "vc.credential_build_config.token_jws_type": "dc+sd-jwt",
    "vc.include_in_metadata": "true"
  },
  "protocolMappers": [
    {
      "name": "given_name-mapper",
      "protocol": "oid4vc",
      "protocolMapper": "oid4vc-user-attribute-mapper",
      "config": {
        "claim.name": "given_name",
        "userAttribute": "firstName",
        "vc.mandatory": "false",
        "vc.display": "[{\"name\":\"Given Name\",\"locale\":\"en\"}]"
      }
    }
    // ... other mappers ...
  ]
}
```

- All credential-specific metadata, supported claims, and display information are now set in the client scope's `attributes`.
- Protocol mappers within the client scope define how user or static data is mapped into the credential claims.

**Assigning Client Scopes to Clients**

To enable issuance of a credential, assign the corresponding client scope to your OpenID Connect client (ideally as optional). **Additionally, the client must have the attribute `"oid4vci.enabled": "true"` in its attributes to be able to request credentials.**

```json
{
  "clientId": "openid4vc-rest-api",
  "optionalClientScopes": ["identity_credential", "stbk_westfalen_lippe"],
  "attributes": {
    "oid4vci.enabled": "true"
  }
}
```

- A client can request multiple credential types by being assigned the corresponding client scopes.
- The `oid4vci.enabled` attribute is required for the client to be recognized as eligible to request Verifiable Credentials via OID4VCI.

**Migration Note:**

- Remove all realm-level VC configuration (such as `verifiable-credentials-config.json`).
- Remove any credential builder configuration, as it is loaded automatically by Keycloak.
- Define all credential types as client scopes in `client-scope-config.json`.
- Assign client scopes to clients as needed.

For more details, see the [client-scope-config.json](../src/config/client-scope-config.json) file.

## Verifiable Credential Formats

Keycloak's OID4VCI implementation supports multiple Verifiable Credential (VC) formats, including:

- **LDP_VC:** Linked Data Proof Verifiable Credentials, as defined in the W3C Verifiable Credentials Data Model specification ([https://www.w3.org/TR/vc-data-model/](https://www.w3.org/TR/vc-data-model/)).
- **JWT_VC:** JSON Web Token Verifiable Credentials, based on the JWT VC Presentation Profile ([https://identity.foundation/jwt-vc-presentation-profile/](https://identity.foundation/jwt-vc-presentation-profile/)).
- **SD-JWT:** Self-Issued OpenID Provider (SIOP) v2 JSON Web Token Verifiable Credentials, as defined in the IETF OAuth SD-JWT VC draft ([https://drafts.oauth.net/oauth-sd-jwt-vc/draft-ietf-oauth-sd-jwt-vc.html](https://drafts.oauth.net/oauth-sd-jwt-vc/draft-ietf-oauth-sd-jwt-vc.html)).

Keycloak automates credential issuance, with a Credential Builder structuring credentials according to the required format and a dedicated Credential Signer handling the signing process. While Credential Builders are configurable, Credential Signers function transparently within the system.

### Credential Builder Configuration

All configuration for credential formats and issuance is now handled at the client scope level. Credential builders are still used but are loaded automatically at Keycloak startup, so manual configuration is no longer required.

**Credential Signing:**
Credential signing is still performed automatically by Keycloak during credential issuance. The signing algorithm and related settings are now specified in the client scope attributes (such as `vc.credential_signing_alg` or similar). No separate credential signing configuration is required at the realm level.

# Key Endpoints

## Credential Issuer Metadata Endpoint

This endpoint is **mandatory** and describes the issuer's capabilities, including supported credential types, formats, cryptographic binding methods, and display information. It also provides the URLs for other essential endpoints like the `credential_endpoint`, `batch_credential_endpoint`, and `deferred_credential_endpoint`. The current keycloak implementation supports only the credential endpoint.

- URL: `https://<your-keycloak-host>/realms/<your-realm>/.well-known/openid-credential-issuer`
- e.g: `https://localhost:8443/realms/master/.well-known/openid-credential-issuer`

### OpenID Configuration Endpoint

This endpoint is **mandatory** in OpenID Connect and provides general metadata about the issuer's OpenID Connect configuration, such as supported scopes, response types, and grant types. While not specific to OID4VCI, it's essential for the overall OpenID Connect flow that underpins VC issuance.

- URL: `https://<your-keycloak-host>/realms/<your-realm>/.well-known/openid-configuration`
- e.g.: `https://localhost:8443/realms/master/.well-known/openid-configuration`

### JWT Issuer Endpoint

This endpoint is **optional** and provides metadata specifically about the issuer's JWT-based VCs. It includes information about supported algorithms, key IDs, and other details relevant to JWT-based VCs.

- URL: `https://<your-keycloak-host>/realms/<your-realm>/.well-known/jwt-vc-issuer`
- e.g: `https://localhost:8443/realms/master/.well-known/jwt-vc-issuer`

## Creating User and User key Materials

### Registering a User

The script `2.configure_user_4_account_client.sh` allows the registration of a new Keycloak user. This user will be used for requesting VCs later in the process.

### Creating User Key Material

Certain credential types require cryptographic binding to the user's identity. This is achieved by associating the VC with a key pair controlled by the user. The script `2.configure_user_4_account_client.sh` also calls `generate_user_key.sh` to generate an ECDSA (Elliptic Curve Digital Signature Algorithm) key pair for this purpose. The user will use the private key to sign proofs during VC interactions, while the public key will be included in the VC.

## Requesting Verifiable Credentials

Keycloak supports two grant types for requesting VCs:

- Pre-authorized Code Flow: Suitable for scenarios where the issuer pre-approves the credential issuance.
- Authorization Code Flow with PKCE: Provides enhanced security through PKCE, requiring user authentication and authorization code exchange.

For examples, see the [Requesting Credentials](./README_Advanced.MD#requesting-credentials) section above, which covers:

- Pre-authorized code flow with key binding [request_credential_with_auth_code_flow.sh](../src/credentials/request_credential_with_auth_code_flow.sh).
- Authorization code flow with PKCE and key binding [request_credential.sh](../src/credentials/request_credential.sh).
- We are missing an example without key binding
