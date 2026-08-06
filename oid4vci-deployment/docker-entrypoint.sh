#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Container entrypoint for Keycloak-SSI
# - Mirrors how local scripts initialize configuration
# - Loads variables from config.yaml / config.override.yaml via helper.sh
# - Then starts Keycloak with OID4VCI features enabled
# -----------------------------------------------------------------------------

# Ensure WORK_DIR is set to the project root inside the container
export WORK_DIR="${WORK_DIR:-/opt/keycloak}"

# Load helper functions and configuration loader
if [[ ! -f "$WORK_DIR/src/utils/helper.sh" ]]; then
  echo "[ERROR] helper.sh not found at $WORK_DIR/src/utils/helper.sh" >&2
  exit 1
fi

source "$WORK_DIR/src/utils/helper.sh"
init_script

export KC_BOOTSTRAP_ADMIN_USERNAME="${KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME}"
export KC_BOOTSTRAP_ADMIN_PASSWORD="${KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD}"

cd "$KEYCLOAK_INSTALL_DIR"

eval "exec bin/kc.sh $START_COMMAND $DATABASE_OPTS --features=oid4vc-vci"
