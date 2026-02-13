# Keycloak SSI CLI Guide

```
      __ __                __            __      __________ ____
     / //_/__  __  _______/ /___  ____ _/ /__   / ___/ ___//  _/
    / ,< / _ \/ / / / ___/ / __ \/ __ `/ //_/   \__ \\__ \ / /
   / /| /  __/ /_/ / /__/ / /_/ / /_/ / ,<     ___/ /__/ // /
  /_/ |_\___/\__, /\___/_/\____/\__,_/_/|_|   /____/____/___/
            /____/
```

CLI Tool • Deployment • Configuration • Testing

---

## Overview

The Keycloak SSI CLI simplifies the setup, configuration, and testing of Self-Sovereign Identity (SSI) environments built on Keycloak with OID4VCI (OpenID for Verifiable Credential Issuance).
It automates complex tasks such as realm setup, credential flow testing, and environment provisioning — all from a single, portable CLI interface.

---

## Prerequisites

Before using the CLI tool, ensure the following dependencies are installed on your system:

- **OpenSSL** — for SSL/TLS certificate generation and cryptographic operations
- **Keytool** — Java key and certificate management utility (included with JDK)
- **jq** — lightweight and flexible command-line JSON processor
- **yq** — portable command-line YAML processor (used for configuration management)
- **figlet** — ASCII art generator for an enhanced CLI display
- **Java Version:**
  - A minimum of Java 17 is required.
  - For compatibility with the `keycloak-ssi import` feature (which uses the [Keycloak Config CLI](https://github.com/adorsys/keycloak-config-cli)), Java 21 is recommended.
    Make sure to set your JAVA_HOME environment variable accordingly:
    ```bash
    export JAVA_HOME=/usr/lib/jvm/jdk-21-oracle-x64/
    ```

---

## Configuration

The CLI uses a configuration system based on shell environment variables for better organization and maintainability. Configuration is managed through `config.yaml` in the project root.

### Override Mechanisms

The system supports multiple levels of configuration overrides:

1. **Environment Variables** (highest priority): `SECTION_KEY=value` format
2. **Partial Overrides**: `config.override.yaml` for environment-specific overrides
3. **Base Configuration**: `config.yaml` (default values)

### Environment Variable Injection

Configuration values support environment variable injection using `${VAR_NAME}` syntax.

### Configuring Environment Variables

The project manages configuration primarily through [`config.yaml`](config.yaml) and [`config.override.yaml`](config.override.yaml). To configure new variables, add them to either of these YAML files.

Variables defined in these files are automatically loaded as environment variables. For example, a YAML property like `keycloak.realm` will be available as the environment variable `KEYCLOAK_REALM`. You can also use environment variable injection within the YAML files using the `${VAR_NAME}` syntax.

---

## Installation (optional)

You can run the CLI directly from the cloned repository without installing it system-wide. Installation is optional and only needed if you want the `keycloak-ssi` command available globally.

### Run without installation

```bash
git clone https://github.com/adorsys/keycloak-ssi-deployment.git
cd keycloak-ssi-deployment
./keycloak-ssi.sh help
```

### Optional: Install globally

```bash
./keycloak-ssi.sh install
keycloak-ssi help
```

The CLI follows the XDG Base Directory specification when installed:

- **CLI Binary:** `~/.local/bin/keycloak-ssi`
- **Project Files:** `~/.local/share/keycloak-ssi-deployment` (symbolic link)

---

## Usage

```bash
keycloak-ssi <command> [options]
```

---

## Commands

| Command                                    | Purpose                                                              | Script Called                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `install`                                  | Install CLI to system PATH                                           | -                                                                                                                         |
| `uninstall`                                | Remove CLI from system PATH                                          | -                                                                                                                         |
| `compose up [-d]`                          | Start the Docker Compose stack (foreground or detached)              | - (runs on host, starts `app`, and `db`)                                                                                  |
| `compose down [-v]`                        | Stop and remove the Docker Compose stack (optionally remove volumes) | - (runs on host)                                                                                                          |
| `setup [-d]`                               | Build and start Keycloak with OID4VCI (host-mode, advanced)          | `src/deployment/0.start-kc-oid4vci.sh`                                                                                    |
| `config`                                   | Configure realm, keys, clients, and test users                       | `src/deployment/1.oid4vci_test_deployment.sh`, `src/deployment/2.configure_user_4_account_client.sh` (via `cli` service)  |
| `test <preauth/authcode> <CredentialType>` | Test credential issuance flows                                       | `src/credentials/request_credential.sh` (preauth), `src/credentials/request_credential_with_auth_code_flow.sh` (authcode) |
| `import`                                   | Import a pre-configured realm                                        | `src/utils/import_kc_config.sh` (via `cli` service)                                                                       |
| `stop`                                     | Stop running Keycloak                                                | `src/utils/helper.sh` (stop_keycloak function)                                                                            |
| `help`                                     | Show this help message                                               | -                                                                                                                         |

---

## Quick Start Example

```bash
# 1️⃣ Start Keycloak and Postgres via Docker Compose
keycloak-ssi compose up -d

# 2️⃣ Configure the realm and create a test user (runs inside cli container)
keycloak-ssi config

# or import a preconfigured realm (runs inside cli container)
keycloak-ssi import

# 3️⃣ Test credential flows (run inside cli container)
keycloak-ssi test preauth IdentityCredential
keycloak-ssi test authcode IdentityCredential

# 4️⃣ Stop the Docker Compose stack and remove volumes
keycloak-ssi compose down -v

# 5️⃣ Uninstall the CLI (optional)
keycloak-ssi uninstall
```
