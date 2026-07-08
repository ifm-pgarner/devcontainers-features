
# Snowflake CLI (snow) (snow-cli)

Installs the Snowflake CLI (`snow`) using uv, available globally on PATH.

## Example Usage

```json
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/snow-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the snowflake-cli PyPI package to install (e.g. 3.5.0). Use 'latest' for the newest release. | string | latest |
| pythonVersion | Python version uv uses to run the CLI. uv downloads a managed CPython if a matching one is not already present. | string | 3.11 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ifm-pgarner/devcontainers-features/blob/main/src/snow-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
