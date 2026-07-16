#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Scenario test: install with a non-default browser selection (firefox) and
# confirm the firefox binary landed in the shared browser path. Matches the
# "install_firefox" key in scenarios.json.
#-------------------------------------------------------------------------------------------------------------
set -e

source dev-container-features-test-lib

check "playwright on PATH"     bash -lc "command -v playwright"
check "playwright --version"   bash -lc "playwright --version"
check "firefox downloaded"     bash -lc "ls -d /ms-playwright/firefox-* >/dev/null"
check "chromium not installed" bash -lc "! ls -d /ms-playwright/chromium-* >/dev/null 2>&1"
check "runs as non-root user"  bash -lc 'if [ "$(id -u)" -eq 0 ]; then su vscode -c "playwright --version"; else playwright --version; fi'

reportResults
