
# Databricks CLI (databricks) (databricks-cli)

Installs the Databricks CLI (`databricks`) from the official GitHub release, verified against the published SHA256 checksums. OAuth logins persist across rebuilds in a named volume.

## Example Usage

```json
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/databricks-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the Databricks CLI to install (e.g. 0.250.0). Use 'latest' for the newest release. | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ifm-pgarner/devcontainers-features/blob/main/src/databricks-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
