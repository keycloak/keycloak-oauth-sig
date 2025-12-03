#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Setup Keycloak with OID4VCI
# - Downloads or builds Keycloak
# - Unpacks into the tools directory
# - Prepares keystore and SSL certificates
# -----------------------------------------------------------------------------

# Load helper (init_script loads env)
source "$WORK_DIR/src/utils/helper.sh"
init_script

# ---------------------------------------------------------------------------
# Ensure a directory exists
# ---------------------------------------------------------------------------
ensure_directory_exists "$PROJECT_TARGET_DIR"
ensure_directory_exists "$PROJECT_TOOLS_DIR"

# ---------------------------------------------------------------------------
# Download Keycloak tarball if it does not exist
# ---------------------------------------------------------------------------
download_tarball() {
    if [[ ! -f "$KEYCLOAK_TARBALL_PATH" ]]; then
        log "Downloading Keycloak $KEYCLOAK_VERSION tarball..."
        curl -fSL -o "$KEYCLOAK_TARBALL_PATH" \
            "https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz" \
            || error "Could not download Keycloak tarball"
        log "Keycloak tarball downloaded to $KEYCLOAK_TARBALL_PATH."
    else
        log "Keycloak tarball already exists at $KEYCLOAK_TARBALL_PATH."
    fi
}

# ---------------------------------------------------------------------------
# Clone custom Keycloak repository and build if needed
# ---------------------------------------------------------------------------
clone_and_build_keycloak() {
    local repo_url="${KEYCLOAK_REPO_URL:-https://github.com/keycloak/keycloak.git}"
    local target_dir="$PROJECT_TARGET_DIR/$KEYCLOAK_OID4VCI_DIR"
    local build_artifact="$target_dir/quarkus/dist/target/keycloak-999.0.0-SNAPSHOT.tar.gz"

    if [[ ! -d "$target_dir" ]]; then
        log "Cloning Keycloak repository from $repo_url..."
        git clone --depth 1 --branch "$KEYCLOAK_TARGET_BRANCH" "$repo_url" "$target_dir" \
            || error "Could not clone the repository"
        log "Keycloak cloned into $target_dir."
    else
        log "Keycloak repository already exists at $target_dir."
    fi

    if [[ ! -f "$build_artifact" ]]; then
        log "Building Keycloak..."
        cd "$target_dir" || error "Cannot cd into $target_dir"
        ./mvnw clean install -DskipTests || error "Failed to build Keycloak"
        log "Keycloak build completed successfully."
    else
        log "Keycloak build artifact exists. Skipping build."
    fi
}

# ---------------------------------------------------------------------------
# Determine installation mode
# ---------------------------------------------------------------------------
KC_USE_UPSTREAM=true
if [[ "$KEYCLOAK_VERSION" == "999.0.0-SNAPSHOT" ]]; then
    KC_USE_UPSTREAM=false
fi

# ---------------------------------------------------------------------------
# Unpack Keycloak tarball
# ---------------------------------------------------------------------------
unpack_keycloak() {
    local tar_file
    if [[ "$KC_USE_UPSTREAM" == true ]]; then
        tar_file="$KEYCLOAK_TARBALL_PATH"
    else
        tar_file="$PROJECT_TARGET_DIR/$KEYCLOAK_OID4VCI_DIR/quarkus/dist/target/keycloak-999.0.0-SNAPSHOT.tar.gz"
    fi

    if [[ -d "$KEYCLOAK_INSTALL_DIR" ]]; then
        log "Removing existing Keycloak installation..."
        rm -rf "$KEYCLOAK_INSTALL_DIR" || error "Failed to remove existing installation"
    fi

    log "Unpacking Keycloak..."
    tar xzf "$tar_file" -C "$PROJECT_TOOLS_DIR" || error "Could not unpack Keycloak tarball"
    log "Keycloak unpacked to $KEYCLOAK_INSTALL_DIR."
}

# ---------------------------------------------------------------------------
# Execute main setup
# ---------------------------------------------------------------------------
if [[ "$KC_USE_UPSTREAM" == true ]]; then
    log "Using upstream Keycloak tarball..."
    download_tarball
    unpack_keycloak
else
    log "Building custom Keycloak from source..."
    clone_and_build_keycloak
    unpack_keycloak
fi

cd "$WORK_DIR" || error "Cannot return to working directory"

# ---------------------------------------------------------------------------
# Ensure SSL certificates and keystore are available
# ---------------------------------------------------------------------------
ensure_keycloak_crypto_materials

log "Setup completed successfully."
