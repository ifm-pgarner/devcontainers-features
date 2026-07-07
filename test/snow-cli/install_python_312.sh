#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Scenario test: install the CLI with a non-default `pythonVersion` (3.12) and
# confirm `snow` still works globally. Matches the "install_python_312" key in
# scenarios.json.
#-------------------------------------------------------------------------------------------------------------
set -e

source dev-container-features-test-lib

check "snow on PATH"          bash -lc "command -v snow"
check "snow --version"        bash -lc "snow --version"
check "runs as non-root user" bash -lc "su vscode -c 'snow --version'"

reportResults
