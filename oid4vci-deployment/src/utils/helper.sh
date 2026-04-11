#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Keycloak SSI Deployment Helper Functions
# Common utilities for all deployment scripts
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Standardized Color Codes and Logging
# -----------------------------------------------------------------------------
# Only set colors if they haven't been set already (avoid conflicts with CLI)
[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[1;34m'
[[ -z "${NC:-}" ]] && readonly NC='\033[0m' # No Color

# Standardized logging functions
log()     { printf "\n${CYAN}[INFO]${NC} %s\n" "$*"; }
warn()    { printf "\n${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
error()   { printf "\n${RED}[ERROR]${NC} %s\n" "$*" >&2; exit 1; }
success() { printf "\n${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
debug()   { printf "\n${BLUE}[DEBUG]${NC} %s\n" "$*"; }


# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------
setup_environment() {
    # Set strict error handling
    set -euo pipefail
    IFS=$'\n\t'

    # Use WORK_DIR if already set (by CLI), otherwise determine it
    if [[ -z "${WORK_DIR:-}" ]]; then
        # Find the project root by walking upward
        local search_dir="${PWD}"

        while true; do
            # Stop if we reached filesystem root
            local parent="$(dirname "$search_dir")"
            [[ "$parent" == "$search_dir" ]] && break

            # Detect project root
            if [[ -f "$search_dir/src/utils/helper.sh" || -f "$search_dir/docker-compose.yml" ]]; then
                WORK_DIR="$search_dir"
                export WORK_DIR
                break
            fi

            # Move up
            search_dir="$parent"
        done

        if [[ -z "${WORK_DIR:-}" ]]; then
            error "Could not determine project root. Run from within the repository."
        fi
    fi

    # Load configuration from YAML with environment variable overrides, only if not already loaded
    if [[ -z "${_CONFIGURATION_LOADED:-}" ]]; then
        load_configuration
        export _CONFIGURATION_LOADED="true"
    fi
}

# -----------------------------------------------------------------------------
# YAML Configuration Export
# Exports YAML properties as uppercase, underscore-separated environment variables
# -----------------------------------------------------------------------------
export_yaml_as_env() {
    local yaml_files=("$@")
    
    # Filter to only existing files (defensive check)
    local existing_files=()
    for file in "${yaml_files[@]}"; do
        [[ -f "$file" ]] && existing_files+=("$file")
    done
    
    # Require at least one file
    if [[ ${#existing_files[@]} -eq 0 ]]; then
        error "No valid YAML configuration files provided"
        return 1
    fi
    
    # 1. Merge config files, flatten to properties, and clean up for shell export.
    #    Store this raw output for two passes.
    # Strategy: Merge files sequentially where later files override earlier ones
    # Use unified approach: ireduce works for both single and multiple files
    set +u # Temporarily disable 'nounset' for yq and sed pipeline
    
    # Merge files using yq: later files override earlier ones
    # This works for both single file (no-op merge) and multiple files (actual merge)
    local raw_props_output=$(yq eval-all '. as $item ireduce ({}; . * $item) | to_props' "${existing_files[@]}" | \
        sed -E 's/^[[:space:]]*//; s/[[:space:]]*=[[:space:]]*/=/' | \
        grep -vE '^\s*#' | \
        grep -E '^[a-zA-Z_][a-zA-Z0-9_.]*='
    )

    # Pass 1: Export all variables with their raw values first.
    # This makes all potential reference targets available as environment variables.
    set +u
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        local env_var_name
        env_var_name=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '.' '_')
        # Export the raw value
        export "$env_var_name"="$value"
        echo "$env_var_name=$value"
        case "$key" in
            "keycloak_endpoints.https_port")
                export KEYCLOAK_HTTPS_PORT="$value"
                ;;
            "keycloak_endpoints.admin_addr")
                export KEYCLOAK_ADMIN_ADDR="$value"
                ;;
            "keycloak.target_branch")
                export KEYCLOAK_TARGET_BRANCH="$value"
                ;;
        esac
    done <<< "$raw_props_output"
    set -u # Restore 'nounset'

    # Pass 2: Now that all variables are exported, re-evaluate and export with substitution.
    set +u # Temporarily disable 'nounset' for variable assignment
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        local env_var_name
        env_var_name=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '.' '_')
        # Resolve placeholders using envsubst, now that all variables are in the environment
        local resolved_value
        resolved_value=$(echo "$value" | envsubst)
        # Re-export the variable with its resolved value
        export "$env_var_name"="$resolved_value"
        case "$key" in
            "keycloak_endpoints.https_port")
                export KEYCLOAK_HTTPS_PORT="$resolved_value"
                ;;
            "keycloak_endpoints.admin_addr")
                export KEYCLOAK_ADMIN_ADDR="$resolved_value"
                ;;
            "keycloak.target_branch")
                export KEYCLOAK_TARGET_BRANCH="$resolved_value"
                ;;
            "keycloak.oid4vci_dir")
                export KEYCLOAK_OID4VCI_DIR="$resolved_value"
                ;;
            "keycloak.realm")
                export KEYCLOAK_REALM="$resolved_value"
                ;;
            "keycloak_endpoints.issuer_did")
                export ISSUER_DID="$resolved_value"
                ;;
            "keycloak.enable_credential_offer_create")
                export KEYCLOAK_ENABLE_CREDENTIAL_OFFER_CREATE="$resolved_value"
                ;;
        esac
    done <<< "$raw_props_output"
    set -u # Restore 'nounset'

    # Derived aliases for convenience
    [[ -n "${KEYCLOAK_ENDPOINTS_ADMIN_ADDR:-}" ]] && export KEYCLOAK_ADMIN_ADDR="${KEYCLOAK_ENDPOINTS_ADMIN_ADDR}"
    [[ -n "${KEYCLOAK_ENDPOINTS_ISSUER_DID:-}" ]] && export KEYCLOAK_ISSUER_DID="${KEYCLOAK_ENDPOINTS_ISSUER_DID}"
    [[ -n "${ISSUER_ENDPOINTS_BACKEND:-}" ]] && export ISSUER_BACKEND_URL="${ISSUER_ENDPOINTS_BACKEND}"
    [[ -n "${ISSUER_ENDPOINTS_FRONTEND:-}" ]] && export ISSUER_FRONTEND_URL="${ISSUER_ENDPOINTS_FRONTEND}"
    [[ -n "${CLIENTS_TEST_CLIENT:-}" ]] && export TEST_CLIENT_URL="${CLIENTS_TEST_CLIENT}"
    
    # Collect features to start Keycloak with
    KEYCLOAK_FEATURES="${KEYCLOAK_FEATURES:-oid4vc-vci}"
    [[ "${KEYCLOAK_ENABLE_PREAUTH_CODE:-}" == "true" ]] && KEYCLOAK_FEATURES="$KEYCLOAK_FEATURES,oid4vc-vci-preauth-code"
    export KEYCLOAK_FEATURES

    # Adjust KEYSTORE_PATH based on where Keycloak is running
    if [[ -n "${KEYSTORE_PATH:-}" ]]; then
        local docker_compose_cmd
        docker_compose_cmd="$(detect_docker_compose 2>/dev/null || echo "")"
        local keycloak_in_docker=false

        # Check if Keycloak is running in Docker (app container)
        if [[ -n "$docker_compose_cmd" ]]; then
            if eval "$docker_compose_cmd" ps app --format json 2>/dev/null | grep -q '"State":"running"' 2>/dev/null || \
                eval "$docker_compose_cmd" ps app 2>/dev/null | grep -q "app.*Up" 2>/dev/null; then
                keycloak_in_docker=true
            fi
        fi

        if [[ "$keycloak_in_docker" == "true" ]]; then
            # Keycloak in Docker: use container path
            export KEYSTORE_PATH="/opt/keycloak/target/kc_keystore.pkcs12"
        elif [[ -n "${KEYCLOAK_SSI_IN_CONTAINER:-}" ]]; then
            # CLI in container, Keycloak on host: convert container path to host path
            local host_project_root="${HOST_WORK_DIR:-}"

            # Try to detect host path from Docker volume mount if HOST_WORK_DIR not set
            if [[ -z "$host_project_root" ]] && command -v docker &>/dev/null && [[ -S /var/run/docker.sock ]]; then
                local container_name
                container_name="$(hostname 2>/dev/null || echo "")"
                if [[ -n "$container_name" ]]; then
                    host_project_root=$(docker inspect "$container_name" 2>/dev/null | \
                        jq -r '.[0].Mounts[] | select(.Destination == "/workspace") | .Source' 2>/dev/null | head -1 || echo "")
                fi
            fi

            if [[ -n "$host_project_root" ]]; then
                export KEYSTORE_PATH="$host_project_root/target/kc_keystore.pkcs12"
            else
                warn "Cannot determine host path for KEYSTORE_PATH. Set HOST_WORK_DIR in docker-compose.yml."
            fi
        fi
    fi
}

# -----------------------------------------------------------------------------
# Get Latest Keycloak Release Version (Patch Only)
# Fetches the latest patch version within the same minor version from GitHub API.
# Only auto-updates patch versions (e.g., 26.5.*) to avoid breaking changes from
# minor/major version updates that may require configuration changes.
# IMPORTANT: This function must print ONLY the plain version string to stdout,
# because callers capture its output via command substitution.
# -----------------------------------------------------------------------------
get_latest_keycloak_version() {
    # Use a cache file in the project target directory or fallback to /tmp
    local cache_dir="${PROJECT_TARGET_DIR:-${WORK_DIR:-/tmp}/target}"
    local cache_file="${cache_dir}/.keycloak_latest_version_cache"
    local base_version_file="${cache_dir}/.keycloak_base_version_cache"
    local cache_age=3600  # Cache for 1 hour (3600 seconds)
    local latest_version
    local base_version=""  # e.g., "26.5" for version "26.5.1" (initialized to avoid set -u issues)

    # Ensure cache directory exists
    mkdir -p "$(dirname "$cache_file")" 2>/dev/null || true

    # Check if we have a cached version that's still fresh
    if [[ -f "$cache_file" ]] && [[ -f "$base_version_file" ]]; then
        local cache_time
        cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local age=$((current_time - cache_time))

        if [[ $age -lt $cache_age ]]; then
            latest_version=$(cat "$cache_file" 2>/dev/null || echo "")
            base_version=$(cat "$base_version_file" 2>/dev/null || echo "")
            if [[ -n "$latest_version" ]] && [[ -n "$base_version" ]]; then
                # Log to stderr so it does not pollute the captured value
                log "Using cached latest Keycloak patch version: $latest_version (base: $base_version.*)" >&2
                echo "$latest_version"
                return 0
            fi
        else
            # Cache expired, but we still need the base version for filtering
            base_version=$(cat "$base_version_file" 2>/dev/null || echo "")
        fi
    fi

    # If no base version exists, fetch the absolute latest to establish the base
    if [[ -z "$base_version" ]]; then
        log "Establishing base version from latest Keycloak release..." >&2
        local absolute_latest
        absolute_latest=$(
            curl -sL "https://api.github.com/repos/keycloak/keycloak/releases/latest" | \
            jq -r '.tag_name // .name' 2>/dev/null | \
            sed 's/^v//' | \
            grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | \
            head -n1 | \
            tr -d '\r' | tr -d '\n'
        )

        if [[ -z "$absolute_latest" ]] || [[ "$absolute_latest" == "null" ]]; then
            error "Failed to fetch latest Keycloak version. Please check your internet connection or set a specific version in config.yaml"
        fi

        # Extract base version (major.minor) from the latest version
        base_version=$(echo "$absolute_latest" | sed -E 's/^([0-9]+\.[0-9]+)\.[0-9]+$/\1/')
        echo "$base_version" > "$base_version_file"
        log "Base version established: $base_version.*" >&2
    fi

    # Fetch latest patch version within the same minor version
    log "Fetching latest patch version for $base_version.* from GitHub..." >&2
    
    # Get all releases and filter for the base version, then get the latest patch
    latest_version=$(
        curl -sL "https://api.github.com/repos/keycloak/keycloak/releases?per_page=100" | \
        jq -r '.[].tag_name' 2>/dev/null | \
        sed 's/^v//' | \
        grep -E "^${base_version}\.[0-9]+$" | \
        sort -V | \
        tail -n1 | \
        tr -d '\r' | tr -d '\n'
    )

    # Fallback: try parsing from releases page if API fails
    if [[ -z "$latest_version" ]] || [[ "$latest_version" == "null" ]]; then
        debug "GitHub API failed, trying alternative method..." >&2
        # For fallback, we'll just get the latest and hope it matches
        latest_version=$(
            curl -sL "https://github.com/keycloak/keycloak/releases" | \
            grep -oE 'releases/tag/[0-9]+\.[0-9]+\.[0-9]+' | \
            sed 's|releases/tag/||' | \
            sed 's/^v//' | \
            grep -E "^${base_version}\.[0-9]+$" | \
            sort -V | \
            tail -n1 | \
            tr -d '\r' | tr -d '\n'
        )
    fi

    # Validate that the resolved version is a proper semver (major.minor.patch)
    if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Resolved Keycloak version '$latest_version' is not a valid semantic version (expected format: major.minor.patch)"
    fi

    if [[ -z "$latest_version" ]] || [[ "$latest_version" == "null" ]]; then
        warn "No patch version found for $base_version.*. Using base version as fallback." >&2
        # Fallback to the base version with .0 if no patch found
        latest_version="${base_version}.0"
    fi

    # Cache the version and base version
    echo "$latest_version" > "$cache_file"
    echo "$base_version" > "$base_version_file"
    success "Latest Keycloak patch version: $latest_version (base: $base_version.*)" >&2

    # Print ONLY the version to stdout
    echo "$latest_version"
}

# -----------------------------------------------------------------------------
# Configuration Loading
# -----------------------------------------------------------------------------
load_configuration() {
    local config_file="$WORK_DIR/config.yaml"
    local override_file="$WORK_DIR/config.override.yaml"
    local yq_files=("$config_file")

    # Check if config.yaml exists
    if [[ ! -f "$config_file" ]]; then
        error "config.yaml not found. Configuration file is required."
        return 1
    fi

    log "Loading configuration from $config_file"

    # Apply overrides from config.override.yaml if it exists
    if [[ -f "$override_file" ]]; then
        log "Applying overrides from $override_file"
        yq_files+=("$override_file")
    fi

    # Export variables using the new helper function.
    # The yq dependency check is now handled inside export_yaml_as_env.
    export_yaml_as_env "${yq_files[@]}" > /dev/null
}

# -----------------------------------------------------------------------------
# Environment Variable Injection
# -----------------------------------------------------------------------------
inject_environment_variables() {
    local yaml_content="$1"

    # Use yq to process environment variable injection
    # This handles ${VAR_NAME} and ${VAR_NAME:-default} syntax
    echo "$yaml_content" | yq '(.. | select(tag == "!!str")) |= envsubst'
}

# -----------------------------------------------------------------------------
# Keycloak Process Management
# -----------------------------------------------------------------------------
get_keycloak_pid() {
    local pid
    if command -v pgrep &>/dev/null; then
        pid=$(pgrep -f keycloak | head -n1 || true)
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            pid=$(ps aux | grep -i '[q]uarkus' | awk 'NR==1{print $2}' || true)
        else
            pid=$(ps aux | grep -i '[k]eycloak' | awk 'NR==1{print $2}' || true)
        fi
    fi
    echo "$pid"
}

stop_keycloak() {
    local keycloak_pid
    keycloak_pid="$(get_keycloak_pid || true)"

    if [[ -n "$keycloak_pid" ]]; then
        log "Keycloak instance found (PID: $keycloak_pid). Shutting it down..."
        if ! kill "$keycloak_pid"; then
            return 1
        fi
        # Wait for process to terminate
        sleep 2
        if kill -0 "$keycloak_pid" 2>/dev/null; then
            kill -9 "$keycloak_pid" 2>/dev/null || true
            sleep 1
        fi
        if kill -0 "$keycloak_pid" 2>/dev/null; then
            return 1
        fi
        log "Keycloak stopped."
    else
        log "No running Keycloak instance found."
    fi

    # -------------------------------------------------------------------------
    # Stop and remove database container + volume using Docker Compose
    # -------------------------------------------------------------------------
    DOCKER_COMPOSE_FILE="${WORK_DIR}/docker-compose.yml"
    if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
        DOCKER_COMPOSE_COMMAND="$(detect_docker_compose)"
        log "Stopping and removing database container..."
        eval "$DOCKER_COMPOSE_COMMAND -f \"$DOCKER_COMPOSE_FILE\" down -v db" || \
            warn "Failed to stop/remove database container or volume. You may need to clean manually."
        log "Database container and volume removed."
    else
        warn "docker-compose.yml not found. Cannot stop DB container."
    fi
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------
urlencode() {
    jq -nr --arg str "$1" '$str|@uri'
}

# -----------------------------------------------------------------------------
# Docker Compose Detection
# -----------------------------------------------------------------------------
detect_docker_compose() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        error "Neither 'docker compose' (v2) nor 'docker-compose' (v1) is installed."
    fi
}

# -----------------------------------------------------------------------------
# Directory Management
# -----------------------------------------------------------------------------
ensure_directory_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log "Created directory: $dir"
    fi
}

# -----------------------------------------------------------------------------
# Keycloak Cryptographic Material
# -----------------------------------------------------------------------------
ensure_keycloak_crypto_materials() {
    # Ensure PROJECT_TARGET_DIR is set (fallback to WORK_DIR/target if not configured)
    PROJECT_TARGET_DIR="${PROJECT_TARGET_DIR:-${WORK_DIR:-/tmp}/target}"
    KEYSTORE_PATH="${PROJECT_TARGET_DIR}/kc_keystore.pkcs12"

    if [[ -z "${SSL_TRUST_STORE:-}" ]]; then
        error "SSL_TRUST_STORE is not defined. Ensure configuration is loaded."
    fi

    ensure_directory_exists "$(dirname "$SSL_TRUST_STORE")"
    if [[ ! -f "$SSL_TRUST_STORE" ]]; then
        log "Generating SSL keys..."
        source "$WORK_DIR/src/utils/crypto/generate-kc-certs.sh" || error "Failed to generate SSL certificates."
    else
        log "Trust store exists at $SSL_TRUST_STORE. Skipping SSL key generation."
    fi

    ensure_directory_exists "$(dirname "$KEYSTORE_PATH")"
    local keystore_basename
    keystore_basename="$(basename "$KEYSTORE_PATH")"
    local keystore_cache="$WORK_DIR/src/utils/crypto/$keystore_basename"

    if [[ -f "$keystore_cache" ]]; then
        log "Reusing existing keystore $keystore_cache..."
        cp "$keystore_cache" "$KEYSTORE_PATH"
    else
        log "Generating new keystore..."
        source "$WORK_DIR/src/utils/crypto/generate_keystore.sh" || error "Failed to generate keystore."
        if [[ -f "$KEYSTORE_PATH" ]]; then
            cp "$KEYSTORE_PATH" "$keystore_cache"
        fi
    fi
}

# -----------------------------------------------------------------------------
# kcadm Helper
# - Prefer local Keycloak install (after setup-kc-oid4vci.sh)
# - Fallback to running kcadm inside the Docker Compose app container
# -----------------------------------------------------------------------------
kcadm() {
    if [[ -x "${KEYCLOAK_INSTALL_DIR:-}/bin/kcadm.sh" ]]; then
        "${KEYCLOAK_INSTALL_DIR}/bin/kcadm.sh" "$@"
    else
        # Fallback to containerized Keycloak; assumes compose service is named "app"
        # and Keycloak is installed under /opt/keycloak in the container image.
        docker compose exec -T app /opt/keycloak/bin/kcadm.sh "$@"
    fi
}

# -----------------------------------------------------------------------------
# Ensure KEYCLOAK_INSTALL_DIR is resolved if KEYCLOAK_VERSION is "latest"
# - This ensures KEYCLOAK_INSTALL_DIR points to the actual installed directory
#   (e.g., keycloak-26.5.1) instead of the literal "keycloak-latest"
# -----------------------------------------------------------------------------
ensure_keycloak_install_dir_resolved() {
    if [[ "${KEYCLOAK_VERSION:-}" == "latest" ]]; then
        # Ensure PROJECT_TARGET_DIR is set (fallback to WORK_DIR/target if not configured)
        PROJECT_TARGET_DIR="${PROJECT_TARGET_DIR:-${WORK_DIR:-/tmp}/target}"
        local resolved_version
        resolved_version="$(get_latest_keycloak_version)"
        export KEYCLOAK_VERSION="$resolved_version"
        export KEYCLOAK_INSTALL_DIR="${PROJECT_TOOLS_DIR}/keycloak-${KEYCLOAK_VERSION}"
        export KEYCLOAK_TARBALL_PATH="${PROJECT_TARGET_DIR}/keycloak-${KEYCLOAK_VERSION}.tar.gz"
    fi
}

# -----------------------------------------------------------------------------
# Keycloak Truststore Path Helper
# - Returns the appropriate truststore path for kcadm depending on where it runs
#   - Local install: uses SSL_TRUST_STORE from config (host path)
#   - Container:     uses /opt/keycloak/target/cacerts (mounted from host target/)
# -----------------------------------------------------------------------------
kc_truststore_path() {
    if [[ -x "${KEYCLOAK_INSTALL_DIR:-}/bin/kcadm.sh" ]]; then
        echo "${SSL_TRUST_STORE}"
    else
        echo "/opt/keycloak/target/cacerts"
    fi
}

# -----------------------------------------------------------------------------
# Prerequisite Checks
# -----------------------------------------------------------------------------
check_dependencies() {
    # Heavy dependencies are only required inside the CLI container.
    if [[ -z "${KEYCLOAK_SSI_IN_CONTAINER:-}" ]]; then
        return 0
    fi

    local missing_deps=()
    for dep in openssl keytool jq yq stat; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies in CLI container: ${missing_deps[*]}. Please rebuild the cli image."
    fi
}

# -----------------------------------------------------------------------------
# Script Initialization
# -----------------------------------------------------------------------------
init_script() {
    # Ensure environment and WORK_DIR are initialized
    setup_environment
    # Resolve KEYCLOAK_VERSION \"latest\" to a concrete version and set KEYCLOAK_INSTALL_DIR/KEYCLOAK_TARBALL_PATH
    ensure_keycloak_install_dir_resolved

    # Log script start
    local script_name
    if [[ ${#BASH_SOURCE[@]} -gt 1 ]]; then
        script_name="$(basename "${BASH_SOURCE[1]}")"
    else
        script_name="$(basename "${BASH_SOURCE[0]}")"
    fi
    log "Starting $script_name"
}

# -----------------------------------------------------------------------------
# Export functions for use in other scripts
# -----------------------------------------------------------------------------
export -f log warn error success
export -f setup_environment get_keycloak_pid stop_keycloak
export -f urlencode detect_docker_compose init_script ensure_directory_exists check_dependencies export_yaml_as_env
export -f ensure_keycloak_crypto_materials get_latest_keycloak_version kcadm kc_truststore_path ensure_keycloak_install_dir_resolved
