# devcontainers-snow-cli

A [dev container Feature](https://containers.dev/implementors/features/) that
installs the Snowflake CLI (`snow`) into your development container.

It is published once to GHCR and reused across repositories (e.g.
`superservice-analytics` and `data-analytics-hub`) so there is no duplicated,
drift-prone install logic in each project.

## What it installs

- The [`snowflake-cli`](https://pypi.org/project/snowflake-cli/) PyPI package,
  which provides the `snow` command.
- Installed with [`uv`](https://docs.astral.sh/uv/) into `/usr/local/bin`, so
  `snow` is on `PATH` for every user in the container (including the non-root
  `vscode` user). `uv` downloads a managed Python if a matching one isn't
  already present, so there is no dependency on a system Python.

Published image:

```
ghcr.io/ifm-pgarner/devcontainers-snow-cli/snow-cli
```

## Usage

Reference the Feature in your project's `.devcontainer/devcontainer.json`:

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-snow-cli/snow-cli:1": {}
}
```

Pin as loosely or tightly as you like: `:1`, `:1.0`, or `:1.0.0`.

### Options

| Option          | Default    | Description                                                        |
| --------------- | ---------- | ------------------------------------------------------------------ |
| `version`       | `latest`   | `snowflake-cli` PyPI version to install (e.g. `3.5.0`).            |
| `pythonVersion` | `3.11`     | Python version `uv` uses to run the CLI (a managed one is fetched).|

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-snow-cli/snow-cli:1": {
        "version": "latest",
        "pythonVersion": "3.11"
    }
}
```

## Providing Snowflake credentials

**Never bake Snowflake credentials into the image or commit them to git.** The
Feature installs the CLI only; it does not manage credentials.

The recommended approach keeps your real `config.toml` (with named connection
profiles) outside of any repository and **bind-mounts** it into the container.
This keeps one shared credentials file across all your projects and avoids
copying secrets into each repo.

Add a `mounts` entry to your `devcontainer.json`:

```jsonc
"mounts": [
    "source=${localEnv:HOME}${localEnv:USERPROFILE}/.snowflake,target=/home/vscode/.snowflake,type=bind"
]
```

### Why the `${localEnv:HOME}${localEnv:USERPROFILE}` trick

`${localEnv:...}` substitutions read the **host** OS environment. The two
variables are concatenated so the same config works cross-platform with no
manual setup per teammate:

- **macOS / Linux:** `HOME` is set, `USERPROFILE` is empty → resolves to
  `~/.snowflake`.
- **Windows:** `USERPROFILE` is set, `HOME` is empty → resolves to
  `%USERPROFILE%\.snowflake`.

For this to work, everyone must put their config at the explicit `.snowflake`
directory:

- macOS / Linux: `~/.snowflake/config.toml`
- Windows: `%USERPROFILE%\.snowflake\config.toml`

Use that explicit path rather than each OS's differing native default (Linux
XDG, Windows AppData, macOS Application Support). The `snow` CLI checks
`~/.snowflake` first before falling back to those OS-specific defaults, so this
is honoured.

> **Caveats (verify in your environment):**
> - Mixed slash separators are expected to resolve on Windows/Docker (both are
>   slash-tolerant) but this should be confirmed on a real Windows machine.
> - Under **WSL2**, `USERPROFILE` can leak into the Linux environment via
>   Windows interop. If it does, the concatenation produces two paths and the
>   mount breaks — check with `echo "$HOME$USERPROFILE"` inside WSL.

`.env` (via the devcontainer `envFile` property) is still fine for values the
container process itself needs (e.g. `SNOWFLAKE_ACCOUNT` if you ever switch to
pure env-var auth), but it is **not** the place for the mount's host-side path —
`${localEnv:...}` never reads a project's `.env` file.

### Full consumer example

```jsonc
{
    "name": "superservice-analytics",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/ifm-pgarner/devcontainers-snow-cli/snow-cli:1": {}
    },
    "mounts": [
        "source=${localEnv:HOME}${localEnv:USERPROFILE}/.snowflake,target=/home/vscode/.snowflake,type=bind"
    ]
}
```

After rebuilding the container, confirm your profiles are visible:

```bash
snow connection list
```

## Repository layout

```
.
├── src/snow-cli/
│   ├── devcontainer-feature.json   # Feature metadata + options
│   └── install.sh                  # Install logic (uv → snowflake-cli)
├── test/snow-cli/
│   ├── test.sh                     # Default test
│   ├── scenarios.json              # Scenario definitions
│   └── install_python_312.sh       # Scenario test
└── .github/workflows/
    ├── release.yaml                # Publish to GHCR + generate docs
    └── test.yaml                   # Run feature tests in CI
```

## Contributing / releasing

1. Make your changes under `src/snow-cli/`.
2. **Bump `version`** in `src/snow-cli/devcontainer-feature.json` (semver) — this
   is what triggers a new published version.
3. Merge to `main`. The `release.yaml` workflow publishes to GHCR via
   [`devcontainers/action`](https://github.com/devcontainers/action) and opens a
   PR with the auto-generated per-feature `README.md` (don't hand-write that
   file).
4. **First publish only:** set the GHCR package visibility to **public** so
   consumer repos can pull it without authentication.

Tests run automatically on pull requests via `test.yaml`, or locally with:

```bash
devcontainer features test -f snow-cli -i mcr.microsoft.com/devcontainers/base:ubuntu .
```

## License

[MIT](./LICENSE)
