#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Default test for the databricks-cli feature. Run automatically by:
#   devcontainer features test -f databricks-cli -i mcr.microsoft.com/devcontainers/base:ubuntu .
#-------------------------------------------------------------------------------------------------------------
set -e

# Import the dev container features test library (provides `check` and `reportResults`).
source dev-container-features-test-lib

check "databricks on PATH"     bash -lc "command -v databricks"
check "databricks --version"   bash -lc "databricks --version"
check "databricks --help runs" bash -lc "databricks --help >/dev/null"

# The CLI must be usable by the non-root container user, not only by root.
check "runs as non-root user" bash -lc 'if [ "$(id -u)" -eq 0 ]; then su vscode -c "databricks --version"; else databricks --version; fi'

# Interactive OAuth logins are stored in the persisted /dc/databricks volume.
# The symlink and ownership target the remote user (`vscode`), so check as them.
AS_VSCODE='if [ "$(id -u)" -eq 0 ]; then su vscode -c "$1"; else bash -c "$1"; fi'
check "plaintext auth storage"    bash -lc '[ "$DATABRICKS_AUTH_STORAGE" = "plaintext" ]'
check "config file in volume"     bash -lc '[ "$DATABRICKS_CONFIG_FILE" = "/dc/databricks/.databrickscfg" ]'
check "token cache dir in volume" bash -lc "${AS_VSCODE}" _ '[ "$(readlink ~/.databricks)" = "/dc/databricks" ]'
check "auth dir writable by user" bash -lc "${AS_VSCODE}" _ 'touch ~/.databricks/.write-test && rm ~/.databricks/.write-test'

reportResults
