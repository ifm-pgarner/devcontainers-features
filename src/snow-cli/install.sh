#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Installs the Snowflake CLI (`snow`) using uv, making it available globally on PATH
# for every user in the container (not just the root user that runs this script).
#-------------------------------------------------------------------------------------------------------------
set -euo pipefail

# Feature options are passed in as UPPERCASE environment variables.
VERSION="${VERSION:-latest}"
PYTHON_VERSION="${PYTHONVERSION:-3.11}"

# Global, world-readable locations so the non-root container user can run the tool.
export UV_INSTALL_DIR="/usr/local/bin"          # where the uv/uvx binaries land
export UV_TOOL_BIN_DIR="/usr/local/bin"          # where the `snow` symlink lands (on everyone's PATH)
export UV_TOOL_DIR="/opt/uv/tools"               # where the tool's isolated venv lives
export UV_PYTHON_INSTALL_DIR="/opt/uv/python"    # where uv-managed CPython lives

echo "Activating feature 'snow-cli' (version=${VERSION}, python=${PYTHON_VERSION})"

# ---------------------------------------------------------------------------
# Ensure prerequisites (curl + certs) for the uv installer.
# ---------------------------------------------------------------------------
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get install -y --no-install-recommends "$@"
    fi
}

# CA certs are needed for the HTTPS download regardless of whether curl is
# already present, so ensure them unconditionally.
check_packages ca-certificates
if ! command -v curl >/dev/null 2>&1; then
    check_packages curl
fi

# ---------------------------------------------------------------------------
# Ensure uv is installed globally (reuse an existing uv if one is present,
# e.g. from the uv devcontainer feature).
# ---------------------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv into ${UV_INSTALL_DIR}..."
    mkdir -p "${UV_INSTALL_DIR}"
    curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi

UV_BIN="$(command -v uv)"
echo "Using uv at ${UV_BIN} ($("${UV_BIN}" --version))"

# ---------------------------------------------------------------------------
# Install the Snowflake CLI. The PyPI package is `snowflake-cli`; the command
# it provides is `snow`. uv downloads a managed CPython if none matches.
# ---------------------------------------------------------------------------
PACKAGE="snowflake-cli"
if [ "${VERSION}" != "latest" ]; then
    PACKAGE="snowflake-cli==${VERSION}"
fi

echo "Installing ${PACKAGE} with uv..."
mkdir -p "${UV_TOOL_DIR}" "${UV_PYTHON_INSTALL_DIR}" "${UV_TOOL_BIN_DIR}"
"${UV_BIN}" tool install --python "${PYTHON_VERSION}" "${PACKAGE}"

# Make uv's own dirs and the installed `snow` entrypoint readable/executable by
# all users. Scope this to uv-managed paths so we don't touch unrelated
# binaries under the shared ${UV_TOOL_BIN_DIR} (e.g. /usr/local/bin).
chmod -R a+rX /opt/uv 2>/dev/null || true
chmod a+rx "${UV_TOOL_BIN_DIR}/snow" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Verify.
# ---------------------------------------------------------------------------
if ! command -v snow >/dev/null 2>&1; then
    echo "ERROR: 'snow' was not found on PATH after installation." >&2
    exit 1
fi
echo "Installed: $(snow --version)"

# Clean up apt lists to keep the image small.
rm -rf /var/lib/apt/lists/*

echo "Done. The 'snow' CLI is available on PATH."
