#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# WORK_DIR is set by the CLI
source "$WORK_DIR/src/utils/helper.sh"
init_script

# =============================================================================
# Hardcoded Configuration Variables
# These values are project-specific and unlikely to change across environments
# =============================================================================
KC_CLI_PROJECT_DIR="$PROJECT_TARGET_DIR/keycloak-config-cli"
KC_CLI_JAR_FILE="keycloak-config-cli.jar"
REPO_URL="https://github.com/adorsys/keycloak-config-cli.git"

# =============================================================================
# Clone and build Keycloak Config CLI if needed
# =============================================================================
if [[ -f "$KC_CLI_PROJECT_DIR/target/$KC_CLI_JAR_FILE" ]]; then
    log "Keycloak Config CLI JAR exists. Skipping build."
else
    if [[ -d "$KC_CLI_PROJECT_DIR" ]]; then
        log "Removing existing CLI project folder $KC_CLI_PROJECT_DIR..."
        rm -rf "$KC_CLI_PROJECT_DIR"
    fi
    log "Cloning repository $REPO_URL..."
    git clone "$REPO_URL" "$KC_CLI_PROJECT_DIR"
    cd "$KC_CLI_PROJECT_DIR" || error "Cannot cd to CLI project dir"
    if [[ -n "$CLI_TAG" ]]; then
        log "Checking out tag $CLI_TAG..."
        git checkout tags/"$CLI_TAG" -b "$CLI_TAG"
    fi
    log "Building CLI..."
    ./mvnw clean install -DskipTests
fi

# ---------------------------------------------------------------------------
# Run CLI JAR to import realm configuration
# ---------------------------------------------------------------------------
log "Running Keycloak Config CLI..."
cd "$WORK_DIR" && java -DCLIENT_SECRET="$CLIENTS_SECRET" \
     -DKEYCLOAK_ADMIN_ADDR="$KEYCLOAK_ADMIN_ADDR" \
     -DKEYSTORE_PASSWORD="$KEYSTORE_PASSWORD" \
     -DKEYSTORE_PATH="$KEYSTORE_PATH" \
     -DKEYCLOAK_REALM="$KEYCLOAK_REALM" \
     -DISSUER_BACKEND_URL="$ISSUER_BACKEND_URL" \
     -DISSUER_FRONTEND_URL="$ISSUER_FRONTEND_URL" \
     -DISSUER_DID="$ISSUER_DID" \
     -DTEST_CLIENT_URL="$TEST_CLIENT_URL" \
     -jar "$KC_CLI_PROJECT_DIR/target/$KC_CLI_JAR_FILE" \
     -Dimport-realm=true \
     --import.var-substitution.enabled=true \
     --keycloak.url="$KEYCLOAK_ADMIN_ADDR" \
     --keycloak.user="$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" \
     --keycloak.password="$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" \
     --keycloak.ssl-verify=false \
     --logging.level.root=info \
     --import.files.locations="$CLI_REALM_FILE"

log "Realm configuration imported successfully."
