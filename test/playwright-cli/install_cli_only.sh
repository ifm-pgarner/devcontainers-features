#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Scenario test: install the CLI only (browsers=none, installDeps=false) and
# confirm no browsers were downloaded. Matches the "install_cli_only" key in
# scenarios.json.
#-------------------------------------------------------------------------------------------------------------
set -e

source dev-container-features-test-lib

check "playwright on PATH"    bash -lc "command -v playwright"
check "playwright --version"  bash -lc "playwright --version"
check "no browsers installed" bash -lc '[ ! -d /ms-playwright ] || [ -z "$(ls -A /ms-playwright 2>/dev/null)" ]'

reportResults
