#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Installs the Playwright CLI (`playwright`) globally via npm, plus browser
# binaries into a shared, world-readable location so every user in the
# container (not just root) can run the tool and launch the browsers.
#-------------------------------------------------------------------------------------------------------------
set -euo pipefail

# Feature options are passed in as UPPERCASE environment variables.
VERSION="${VERSION:-latest}"
BROWSERS="${BROWSERS:-chromium}"
INSTALL_DEPS="${INSTALLDEPS:-true}"

# Shared browser location (matches the convention used by Microsoft's official
# Playwright images). Declared in devcontainer-feature.json's containerEnv so
# the running container sees it too; set it here for the install step as well.
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

echo "Activating feature 'playwright-cli' (version=${VERSION}, browsers=${BROWSERS}, installDeps=${INSTALL_DEPS})"

# ---------------------------------------------------------------------------
# npm must be available. The `node` feature (declared via dependsOn) provides
# it; fail loudly with guidance if it is somehow missing.
# ---------------------------------------------------------------------------
if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: 'npm' was not found on PATH. This feature needs Node.js." >&2
    echo "       Add the node feature, e.g. \"ghcr.io/devcontainers/features/node:1\": {}." >&2
    exit 1
fi
echo "Using npm at $(command -v npm) ($(npm --version)), node $(node --version)"

# ---------------------------------------------------------------------------
# Install the Playwright CLI globally. The npm package is `playwright`; the
# command it provides is `playwright`.
# ---------------------------------------------------------------------------
PACKAGE="playwright"
if [ "${VERSION}" != "latest" ]; then
    PACKAGE="playwright@${VERSION}"
fi

echo "Installing ${PACKAGE} globally with npm..."
npm install -g "${PACKAGE}"

if ! command -v playwright >/dev/null 2>&1; then
    echo "ERROR: 'playwright' was not found on PATH after installation." >&2
    exit 1
fi
echo "Installed: $(playwright --version)"

# ---------------------------------------------------------------------------
# Download browser binaries into the shared PLAYWRIGHT_BROWSERS_PATH.
#   browsers=none          -> CLI only, no browsers
#   browsers=all           -> every supported browser
#   browsers=chromium,...  -> the named browsers
# `--with-deps` (when installDeps=true) also apt-installs the OS libraries the
# browsers require; this needs root, which the feature install runs as.
# ---------------------------------------------------------------------------
if [ "${BROWSERS}" = "none" ] || [ -z "${BROWSERS}" ]; then
    echo "Skipping browser download (browsers='${BROWSERS}')."
else
    mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}"

    INSTALL_ARGS=()
    if [ "${INSTALL_DEPS}" = "true" ]; then
        INSTALL_ARGS+=("--with-deps")
    fi

    if [ "${BROWSERS}" != "all" ]; then
        # Turn a comma-separated list into individual arguments.
        IFS=',' read -ra BROWSER_LIST <<< "${BROWSERS}"
        for b in "${BROWSER_LIST[@]}"; do
            # Trim surrounding whitespace.
            b="$(echo "${b}" | xargs)"
            [ -n "${b}" ] && INSTALL_ARGS+=("${b}")
        done
    fi

    echo "Downloading browsers into ${PLAYWRIGHT_BROWSERS_PATH}: playwright install ${INSTALL_ARGS[*]}"
    playwright install "${INSTALL_ARGS[@]}"

    # Make the browser binaries readable/executable by all container users.
    chmod -R a+rX "${PLAYWRIGHT_BROWSERS_PATH}" 2>/dev/null || true
fi

# Clean up apt lists (install-deps may have populated them) to keep the image small.
rm -rf /var/lib/apt/lists/*

echo "Done. The 'playwright' CLI is available on PATH."
