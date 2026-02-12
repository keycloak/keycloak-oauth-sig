#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# Keycloak SSI CLI Tool
# =============================================================================
# Professional CLI for Keycloak SSI deployment and testing
# 
# Commands:
#   setup    - Build and start Keycloak with OID4VCI features
#   config   - Configure realm, key providers, clients, and users
#   test     - Test credential flows (preauth | authcode)
#   import   - Import ready realm configuration
# =============================================================================

# Colors for output (avoid conflicts with helper.sh)
# Use real ANSI escapes only when stdout is a TTY
if [ -t 1 ]; then
  CLI_RED="$(printf '\033[0;31m')"
  CLI_GREEN="$(printf '\033[0;32m')"
  CLI_YELLOW="$(printf '\033[1;33m')"
  CLI_CYAN="$(printf '\033[0;36m')"
  CLI_BLUE="$(printf '\033[1;34m')"
  CLI_NC="$(printf '\033[0m')"
else
  CLI_RED=""; CLI_GREEN=""; CLI_YELLOW=""; CLI_CYAN=""; CLI_BLUE=""; CLI_NC="";
fi

# =============================================================================
# Project Root Detection
# Uses XDG Base Directory specification for clean, professional CLI behavior
# =============================================================================

# Determine project root using XDG Base Directory specification
determine_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Prefer running locally from the cloned repository
    if [[ -f "$script_dir/src/utils/helper.sh" ]]; then
        echo "$script_dir"
        return
    fi
    # If installed, use XDG Base Directory
    local xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local project_root="$xdg_data_home/keycloak-ssi-deployment"
    if [[ -f "$project_root/src/utils/helper.sh" ]]; then
        echo "$project_root"
        return
    fi
    echo "Keycloak SSI project not found. Run from the project root or install with './keycloak-ssi.sh install'." >&2
    exit 1
}

# Set project root
WORK_DIR="$(determine_project_root "${1:-}")"

# Export WORK_DIR so helper functions can use it
export WORK_DIR

# Load helper functions
source "$WORK_DIR/src/utils/helper.sh"

# =============================================================================
# CLI Functions
# =============================================================================

show_help() {
    printf "%s\n" \
"${CLI_CYAN}USAGE${CLI_NC}" \
"  keycloak-ssi <command> [options]" \
"" \
"${CLI_CYAN}COMMANDS${CLI_NC}" \
"  ${CLI_GREEN}setup [-d]${CLI_NC}                  Build and start Keycloak with OID4VCI features" \
"  ${CLI_GREEN}compose${CLI_NC}                     Run docker compose commands (e.g., './keycloak-ssi compose up -d')" \
"  ${CLI_GREEN}config${CLI_NC}                      Configure realm, key providers, clients, and users" \
"  ${CLI_GREEN}test${CLI_NC}                        <preauth|authcode> <CredentialType>   Test credential flows" \
"  ${CLI_GREEN}import${CLI_NC}                      Import ready realm configuration" \
"  ${CLI_GREEN}stop${CLI_NC}                        Stop running Keycloak instance" \
"  ${CLI_GREEN}install${CLI_NC}                     Install CLI to system PATH" \
"  ${CLI_GREEN}uninstall${CLI_NC}                   Remove CLI from system PATH" \
"  ${CLI_GREEN}help${CLI_NC}                        Show this help message" \
"" \
"${CLI_CYAN}EXAMPLES${CLI_NC}" \
"  keycloak-ssi install" \
"  keycloak-ssi setup" \
"  keycloak-ssi setup -d" \
"  keycloak-ssi compose up -d" \
"  keycloak-ssi compose down -v" \
"  keycloak-ssi config" \
"  keycloak-ssi test preauth IdentityCredential" \
"  keycloak-ssi test authcode IdentityCredential" \
"  keycloak-ssi import" \
"  keycloak-ssi stop" \
"  keycloak-ssi uninstall" \
"" \
"${CLI_YELLOW}Note:${CLI_NC} 'setup' may take 5-10 minutes on first run."
}

show_banner() {
    echo
    # Use figlet if available, fallback to simple text
    if command -v figlet >/dev/null 2>&1; then
        figlet -f slant "Keycloak SSI" | sed 's/^/  /'
        echo ""
        echo "${CLI_CYAN}  CLI Tool • Deployment • Configuration • Testing${CLI_NC}"
    else
        echo "${CLI_CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${CLI_NC}"
        echo "${CLI_CYAN}║                              Keycloak SSI CLI Tool                            ║${CLI_NC}"
        echo "${CLI_CYAN}║                     Deployment • Configuration • Testing                      ║${CLI_NC}"
        echo "${CLI_CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${CLI_NC}"
    fi
    echo
}

log() {
    echo -e "${CLI_BLUE}[INFO]${CLI_NC} $1"
}

success() {
    echo -e "${CLI_GREEN}[SUCCESS]${CLI_NC} $1"
}

warn() {
    echo -e "${CLI_YELLOW}[WARN]${CLI_NC} $1"
}

error() {
    echo -e "${CLI_RED}[ERROR]${CLI_NC} $1"
    exit 1
}

run_in_cli_container_if_needed() {
    # When invoked on the host (outside the CLI container), delegate selected
    # commands into the lightweight cli service to avoid host OS dependencies.
    if [[ -n "${KEYCLOAK_SSI_IN_CONTAINER:-}" ]]; then
        return 0
    fi

    local cmd="${1:-help}"
    case "$cmd" in
        config|test|import)
            local DOCKER_COMPOSE_CMD
            DOCKER_COMPOSE_CMD="$(detect_docker_compose)"
            # Ensure docker compose inside the cli container sees the same
            # project as the host stack by setting COMPOSE_PROJECT_NAME.
            local project_name
            project_name="$(basename "$WORK_DIR")"
            # Generate an env file for docker compose from config.yaml to avoid
            # relying on host environment variables for interpolation.
            local env_file=".env"
            local config_files=("$WORK_DIR/config.yaml")
            local override_file="$WORK_DIR/config.override.yaml"
            [[ -f "$override_file" ]] && config_files+=("$override_file")
            rm -f "$env_file"
            export_yaml_as_env "${config_files[@]}" > "$env_file"
            # Forward all original arguments into the cli service, using the env file.
            # Build command array to properly forward all arguments.
            local compose_args=("--env-file" "$env_file" "run" "--rm" "cli")
            # Append all original arguments
            compose_args+=("$@")
            # Execute with proper environment (use eval like cmd_compose does)
            COMPOSE_PROJECT_NAME="$project_name" eval "$DOCKER_COMPOSE_CMD" "${compose_args[@]}"
            exit $?
            ;;
        *)
            # Other commands (setup, compose, stop, install, uninstall, help)
            # are executed directly on the host.
            ;;
    esac
}

# =============================================================================
# Command Functions
# =============================================================================

cmd_setup() {
    local detach_flag="${1:-}"
    log "Setting up Keycloak with OID4VCI features..."
    log "This may take 5-10 minutes for first-time build..."

    # Start setup script in foreground by default; support '-d' to detach
    if [[ "$detach_flag" == "-d" ]]; then
        log "Starting Keycloak setup in detached mode..."
        WORK_DIR="$WORK_DIR" "$WORK_DIR/src/deployment/0.start-kc-oid4vci.sh" -d
    else
        log "Starting Keycloak setup in foreground..."
        WORK_DIR="$WORK_DIR" "$WORK_DIR/src/deployment/0.start-kc-oid4vci.sh"
    fi

    # Wait for Keycloak to be ready
    log "Waiting for Keycloak to be ready..."
    for i in {1..120}; do
        if curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/master" >/dev/null 2>&1; then
            success "Keycloak is ready and running"
            success "Admin Console: $KEYCLOAK_ADMIN_ADDR"
            return 0
        fi
        if [[ $i -eq 120 ]]; then
            error "Keycloak failed to start within 2 minutes"
        fi
        echo -n "."
        sleep 1
    done
}

cmd_config() {
    log "Configuring realm, key providers, clients, and users..."
    
    # Check if Keycloak is running (host-mode only). When running inside the
    # cli container, connectivity is validated implicitly by the scripts via
    # kcadm/curl and docker compose exec calls.
    if [[ -z "${KEYCLOAK_SSI_IN_CONTAINER:-}" ]]; then
        if ! curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/master" >/dev/null 2>&1; then
            error "Keycloak is not running. Run 'keycloak-ssi setup' first."
        fi
    fi
    
    # Run configuration scripts
    log "Running OID4VCI configuration..."
    "$WORK_DIR/src/deployment/1.oid4vci_test_deployment.sh"
    
    log "Configuring user and account client..."
    "$WORK_DIR/src/deployment/2.configure_user_4_account_client.sh"
    
    success "Configuration completed"
    success "Test User: francis / $USERS_FRANCIS_PASSWORD"
}

cmd_test() {
    local flow="${1:-}"
    local credential_type="${2:-}"
    
    if [[ -z "$flow" || -z "$credential_type" ]]; then
        error "Usage: keycloak-ssi test <preauth|authcode> <CredentialType>"
    fi
    
    # Check if Keycloak is running
    if ! curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/master" >/dev/null 2>&1; then
        error "❌ Keycloak is not running. Run 'keycloak-ssi setup' first."
    fi

    case "$flow" in
        "preauth")
            log "Testing Pre-authorized Code Flow..."
            log "Credential: $credential_type"
            "$WORK_DIR/src/credentials/request_credential.sh" "$credential_type"
            ;;
        "authcode")
            log "Testing Authorization Code + PKCE Flow..."
            log "Credential: $credential_type"
            "$WORK_DIR/src/credentials/request_credential_with_auth_code_flow.sh" "$credential_type"
            ;;
        *)
            error "Invalid flow. Use 'preauth' or 'authcode'"
            ;;
    esac
    
    success "Test completed"
}

cmd_import() {
    log "📥 Importing ready realm configuration..."
    
    # Check if Keycloak is running
    if ! curl -k -s "$KEYCLOAK_ADMIN_ADDR/realms/master" >/dev/null 2>&1; then
        error "❌ Keycloak is not running. Run 'keycloak-ssi setup' first."
    fi

    # Run import script
    "$WORK_DIR/src/utils/import_kc_config.sh"
    
    success "Realm configuration imported"
}

cmd_stop() {
    log "Stopping Keycloak if running..."
    stop_keycloak
    success "Stop command completed"
}

cmd_compose() {
    log "Running docker compose command: docker compose $@"

    local args=("$@")
    local is_starting=false
    
    # Check if this is a start command (up/start)
    for arg in "${args[@]}"; do
        case "$arg" in
            up|start)
                is_starting=true
                break
                ;;
        esac
    done

    # Ensure crypto materials only when starting
    if "$is_starting"; then
        log "Ensuring Keycloak certificates and keystore are present..."
        ensure_keycloak_crypto_materials
    fi

    # Generate .env file from merged config files
    local env_file=".env.generated"
    if "$is_starting"; then
        log "Generating temporary .env file from config.yaml..."
    fi
    
    # Build config file array: base config + optional override (same pattern as load_configuration)
    local config_files=("$WORK_DIR/config.yaml")
    local override_file="$WORK_DIR/config.override.yaml"
    [[ -f "$override_file" ]] && config_files+=("$override_file")
    
    # Generate .env content from merged YAML configs
    rm -f "$env_file"
    export_yaml_as_env "${config_files[@]}" > "$env_file"

    # Prepare docker compose command
    local DOCKER_COMPOSE_CMD
    DOCKER_COMPOSE_CMD="$(detect_docker_compose)"

    # Process arguments: add -v to 'down' if not present
    local new_args=()
    local has_down=false
    local has_volumes=false
    
    for arg in "${args[@]}"; do
        case "$arg" in
            down)
                has_down=true
                ;;
            -v|--volumes)
                has_volumes=true
                ;;
        esac
        new_args+=("$arg")
    done
    
    # Auto-add -v to 'down' command if not specified
    if "$has_down" && ! "$has_volumes"; then
        log "Adding -v flag to 'docker compose down' command."
        new_args+=("-v")
    fi

    # Execute docker compose with generated .env file
    eval "$DOCKER_COMPOSE_CMD" "${new_args[@]}"
    local compose_exit_code=$?

    # Clean up temporary .env file (silently)
    rm -f "$env_file"

    return "$compose_exit_code"
}

cmd_install() {
    log "Installing keycloak-ssi CLI to system PATH..."

    # Determine install directory
    local install_dir="/usr/local/bin"
    if [[ ! -w "$install_dir" ]]; then
        install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
    fi

    local install_path="$install_dir/keycloak-ssi"

    # Check if already installed
    if command -v keycloak-ssi >/dev/null 2>&1; then
        local existing_path
        existing_path="$(command -v keycloak-ssi)"
        if [[ "$existing_path" == "$install_path" ]]; then
            success "CLI is already installed at $existing_path"
            return 0
        else
            warn "CLI is installed at $existing_path, reinstalling to $install_path..."
        fi
    fi

    # Install project files to XDG Base Directory using symbolic link
    local xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local project_install_dir="$xdg_data_home/keycloak-ssi-deployment"
    
    log "Installing project files to $project_install_dir..."
    
    # Ensure the parent directory exists for the project installation
    mkdir -p "$xdg_data_home"

    # Remove existing installation (whether symlink or directory)
    if [[ -e "$project_install_dir" ]]; then
        rm -rf "$project_install_dir"
    fi
    
    # Create symbolic link to project directory
    ln -s "$WORK_DIR" "$project_install_dir" || error "Failed to create symbolic link"

    # Install CLI script
    rm -f "$install_path"
    cp "$WORK_DIR/keycloak-ssi.sh" "$install_path"
    chmod +x "$install_path"

    # Check if PATH includes install directory
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        warn "Please add $install_dir to your PATH:"
        echo "  export PATH=\"\$PATH:$install_dir\""
        echo "  # Add to ~/.bashrc or ~/.zshrc for persistence"
    fi

    success "CLI installed to $install_path"
    success "Project files installed to $project_install_dir"
    success "You can now run 'keycloak-ssi' from anywhere"
}

cmd_uninstall() {
    log "Uninstalling keycloak-ssi CLI..."
    
    # Try common locations
    local locations=("/usr/local/bin/keycloak-ssi" "$HOME/.local/bin/keycloak-ssi")
    local removed=false
    
    for location in "${locations[@]}"; do
        if [[ -f "$location" ]]; then
            rm -f "$location"
            success "Removed $location"
            removed=true
        fi
    done
    
    # Remove project files from XDG Base Directory (symlink or directory)
    local xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local project_install_dir="$xdg_data_home/keycloak-ssi-deployment"
    
    if [[ -e "$project_install_dir" ]]; then
        rm -f "$project_install_dir"  # Works for both symlinks and directories
        success "Removed project files from $project_install_dir"
        removed=true
    fi
    
    if [[ "$removed" == "false" ]]; then
        warn "No keycloak-ssi installation found in common locations"
    else
        success "CLI uninstalled successfully"
    fi
}

# =============================================================================
# Main CLI Logic
# =============================================================================

main() {
    # Delegate heavy commands into the cli container when running on the host.
    run_in_cli_container_if_needed "$@"

    # Check dependencies first
    check_dependencies

    # Show banner
    show_banner

    # Load configuration from config.yaml
    setup_environment

    # Parse command
    case "${1:-help}" in
        "setup")
            cmd_setup "${2:-}"
            ;;
        "config")
            cmd_config
            ;;
        "test")
            cmd_test "${2:-}" "${3:-}"
            ;;
        "import")
            cmd_import
            ;;
        "compose")
            shift # Remove 'compose' from arguments, pass the rest to cmd_compose
            cmd_compose "$@"
            ;;
        "stop")
            cmd_stop
            ;;
        "install")
            cmd_install
            ;;
        "uninstall")
            cmd_uninstall
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${CLI_RED}[ERROR]${CLI_NC} Unknown command: $1" >&2
            echo "Run 'keycloak-ssi help' for usage information."
            # exit 1
            ;;
    esac
}

# =============================================================================
# Trap for graceful shutdown
# =============================================================================

# Function to handle script exit and clean up
cleanup() {
    stop_keycloak
}

# Trap SIGINT (Ctrl+C) and SIGTERM signals
trap cleanup SIGINT SIGTERM

# Run main function
main "$@"
