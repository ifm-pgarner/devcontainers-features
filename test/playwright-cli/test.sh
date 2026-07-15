#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Default test for the playwright-cli feature. Run automatically by:
#   devcontainer features test -f playwright-cli -i mcr.microsoft.com/devcontainers/base:ubuntu .
#-------------------------------------------------------------------------------------------------------------
set -e

# Import the dev container features test library (provides `check` and `reportResults`).
source dev-container-features-test-lib

check "playwright on PATH"     bash -lc "command -v playwright"
check "playwright --version"   bash -lc "playwright --version"
check "playwright --help runs" bash -lc "playwright --help >/dev/null"

# Default install downloads chromium into the shared browser path.
check "browsers path set"      bash -lc '[ "$PLAYWRIGHT_BROWSERS_PATH" = "/ms-playwright" ]'
check "chromium downloaded"    bash -lc "ls -d /ms-playwright/chromium-* >/dev/null"

# The CLI and browsers must be usable by the non-root container user, not only
# by root. When the test already runs as non-root, invoke directly; when it
# runs as root, drop to the `vscode` user (passwordless `su` only works as root).
check "runs as non-root user" bash -lc 'if [ "$(id -u)" -eq 0 ]; then su vscode -c "playwright --version"; else playwright --version; fi'

reportResults
