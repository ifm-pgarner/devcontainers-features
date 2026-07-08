#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Default test for the snow-cli feature. Run automatically by:
#   devcontainer features test -f snow-cli -i mcr.microsoft.com/devcontainers/base:ubuntu .
#-------------------------------------------------------------------------------------------------------------
set -e

# Import the dev container features test library (provides `check` and `reportResults`).
source dev-container-features-test-lib

check "snow on PATH"        bash -lc "command -v snow"
check "snow --version"      bash -lc "snow --version"
check "snow --help runs"    bash -lc "snow --help >/dev/null"

# The CLI must be usable by the non-root container user, not only by root.
# When the test already runs as non-root, invoke directly; when it runs as
# root, drop to the `vscode` user (passwordless `su` only works as root).
check "runs as non-root user" bash -lc 'if [ "$(id -u)" -eq 0 ]; then su vscode -c "snow --version"; else snow --version; fi'

reportResults
