
# Playwright CLI (playwright) (playwright-cli)

Installs the Playwright CLI (`playwright`) globally via npm, plus browser binaries into a shared location usable by every user in the container.

## Example Usage

```json
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/playwright-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the `playwright` npm package to install (e.g. 1.48.0). Use 'latest' for the newest release. | string | latest |
| browsers | Which browser binaries to download. Comma-separated list of chromium/firefox/webkit, 'all' for every browser, or 'none' to install only the CLI. | string | chromium |
| installDeps | Install the OS-level packages the browsers need (via `playwright install-deps`). Requires an apt-based base image. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ifm-pgarner/devcontainers-features/blob/main/src/playwright-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
