#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Start Keycloak with OID4VCI
# - Stops any running instance
# - Prepares Keycloak via setup script
# - Starts DB container if needed
# - Injects providers and starts Keycloak
# -----------------------------------------------------------------------------

# Load helpers (init_script loads env)
source "$WORK_DIR/src/utils/helper.sh"
init_script

# ---------------------------------------------------------------------------
# Stop any running Keycloak instance
# ---------------------------------------------------------------------------
log "Checking for running Keycloak instance..."
stop_keycloak
log "Keycloak stop process completed."
log "Continuing with script execution..."

# ---------------------------------------------------------------------------
# Setup Keycloak (download/build/unpack, prepare keystore)
# ---------------------------------------------------------------------------
log "Preparing Keycloak..."
"$WORK_DIR/src/deployment/setup-kc-oid4vci.sh"

# ---------------------------------------------------------------------------
# Detect Docker Compose command
# ---------------------------------------------------------------------------
DOCKER_COMPOSE_COMMAND="$(detect_docker_compose)"
log "Docker Compose detected: $DOCKER_COMPOSE_COMMAND"

# ---------------------------------------------------------------------------
# Start database container if not using manual DATABASE_OPTS
# ---------------------------------------------------------------------------
DOCKER_COMPOSE_FILE="${WORK_DIR}/docker-compose.yml"

if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    error "docker-compose.yml not found in project root: $DOCKER_COMPOSE_FILE"
fi

if [[ -z "${DATABASE_OPTS:-}" ]]; then
    log "Starting database container using Docker Compose..."
    # Use eval to properly handle multi-word commands
    eval $DOCKER_COMPOSE_COMMAND -f "$DOCKER_COMPOSE_FILE" up -d db || error "Could not start database container"
    DATABASE_OPTS="--db postgres --db-url-port $DATABASE_EXPOSED_PORT --db-url-database $DATABASE_NAME --db-username $DATABASE_USERNAME --db-password $DATABASE_PASSWORD"
    log "Database container started and DATABASE_OPTS set."
else
    log "Using provided DATABASE_OPTS: $DATABASE_OPTS"
fi

# ---------------------------------------------------------------------------
# Inject providers
# ---------------------------------------------------------------------------
log "Injecting Keycloak providers..."

if [ -d "$WORK_DIR/providers" ] && ls "$WORK_DIR/providers"/*.jar 1> /dev/null 2>&1; then
  echo "Injecting Keycloak providers..."
  mkdir -p "$KEYCLOAK_INSTALL_DIR/providers"
  cp "$WORK_DIR/providers/"*.jar "$KEYCLOAK_INSTALL_DIR/providers"
else
  echo "No providers folder found at $WORK_DIR/providers — skipping injection."
fi

# ---------------------------------------------------------------------------
# Start Keycloak (foreground by default; '-d' to detach and log to file)
# ---------------------------------------------------------------------------

DETACH_MODE="false"
if [[ "${1:-}" == "-d" ]]; then
  DETACH_MODE="true"
fi

log "Starting Keycloak with OID4VCI features..."

cd "$KEYCLOAK_INSTALL_DIR" || error "Cannot cd to $KEYCLOAK_INSTALL_DIR"

# ---------------------------------------------------------------------------
# Ensure bootstrap admin exists before server start
# ---------------------------------------------------------------------------
if [[ -z "${KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME:-}" || -z "${KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD:-}" ]]; then
  error "Bootstrap admin credentials are not set. Check keycloak.bootstrap.* in config."
fi

MIGRATION_OPTS=""
if [[ -n "${DATABASE_MIGRATION_STRATEGY:-}" ]]; then
  MIGRATION_OPTS="--spi-connections-jpa-quarkus-migration-strategy=$DATABASE_MIGRATION_STRATEGY"
fi

log "Ensuring bootstrap admin user exists..."
bootstrap_output="$(bash -c "bin/kc.sh bootstrap-admin user --username \"$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME\" --password:env KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD $DATABASE_OPTS $MIGRATION_OPTS" 2>&1)" || bootstrap_status=$?
bootstrap_status="${bootstrap_status:-0}"
if [[ "$bootstrap_status" -ne 0 ]]; then
  if echo "$bootstrap_output" | grep -Eq "user with username exists|duplicate key value"; then
    log "Bootstrap admin already exists. Continuing startup."
  else
    echo "$bootstrap_output"
    error "Failed to bootstrap admin user."
  fi
fi

if [[ "$DETACH_MODE" == "true" ]]; then
  LOG_DIR="$WORK_DIR/target"
  ensure_directory_exists "$LOG_DIR"
  LOG_FILE="$LOG_DIR/keycloak.log"
  log "Detaching Keycloak; logs will be written to $LOG_FILE"
  KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" \
  nohup bash -c "exec bin/kc.sh $START_COMMAND $DATABASE_OPTS $MIGRATION_OPTS --features=$KEYCLOAK_FEATURES" \
    >"$LOG_FILE" 2>&1 &
  disown || true
else
  KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" \
  exec bash -c "exec bin/kc.sh $START_COMMAND $DATABASE_OPTS $MIGRATION_OPTS --features=$KEYCLOAK_FEATURES"

fi
