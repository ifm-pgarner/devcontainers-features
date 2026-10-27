#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Scenario test: install a pinned CLI version and confirm that exact version is
# on PATH. Matches the "install_pinned_version" key in scenarios.json.
#-------------------------------------------------------------------------------------------------------------
set -e

source dev-container-features-test-lib

check "databricks on PATH"      bash -lc "command -v databricks"
check "pinned version installed" bash -lc "databricks --version | grep -F 0.250.0"

reportResults
