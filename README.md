# devcontainers-features

A collection of [dev container Features](https://containers.dev/implementors/features/)
for our development containers:

- **`snow-cli`** — the Snowflake CLI (`snow`).
- **`playwright-cli`** — the Playwright CLI (`playwright`) plus browser binaries.
- **`databricks-cli`** — the Databricks CLI (`databricks`).

Each Feature is published to GHCR when changes are merged to the `main` branch.

## snow-cli

### What it installs

- The [`snowflake-cli`](https://pypi.org/project/snowflake-cli/) PyPI package,
  which provides the `snow` command.
- Installed with [`uv`](https://docs.astral.sh/uv/) into `/usr/local/bin`, so
  `snow` is on `PATH` for every user in the container (including the non-root
  `vscode` user). `uv` downloads a managed Python if a matching one isn't
  already present, so there is no dependency on a system Python.

Published image:

```
ghcr.io/ifm-pgarner/devcontainers-features/snow-cli
```

### Usage

Reference the Feature in your project's `.devcontainer/devcontainer.json`:

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/snow-cli:1": {}
}
```

Pin as loosely or tightly as you like: `:1`, `:1.0`, or `:1.0.0`.

#### Options

| Option          | Default    | Description                                                        |
| --------------- | ---------- | ------------------------------------------------------------------ |
| `version`       | `latest`   | `snowflake-cli` PyPI version to install (e.g. `3.5.0`).            |
| `pythonVersion` | `3.11`     | Python version `uv` uses to run the CLI (a managed one is fetched).|

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/snow-cli:1": {
        "version": "latest",
        "pythonVersion": "3.11"
    }
}
```

### Providing Snowflake credentials

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

#### Why the `${localEnv:HOME}${localEnv:USERPROFILE}` trick

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

#### Full consumer example

```jsonc
{
    "name": "superservice-analytics",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/ifm-pgarner/devcontainers-features/snow-cli:1": {}
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

## playwright-cli

### What it installs

- The [`playwright`](https://www.npmjs.com/package/playwright) npm package,
  installed globally so the `playwright` command is on `PATH` for every user.
- Browser binaries, downloaded into a shared `/ms-playwright` directory (the
  same convention as Microsoft's official Playwright images) via
  `PLAYWRIGHT_BROWSERS_PATH`, so they're usable by the non-root `vscode` user.
- Optionally, the OS-level libraries the browsers need (`playwright
  install-deps`).

Node.js is required and is pulled in automatically via the Feature's
`dependsOn` on `ghcr.io/devcontainers/features/node`.

Published image:

```
ghcr.io/ifm-pgarner/devcontainers-features/playwright-cli
```

### Usage

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/playwright-cli:1": {}
}
```

#### Options

| Option        | Default    | Description                                                                                  |
| ------------- | ---------- | -------------------------------------------------------------------------------------------- |
| `version`     | `latest`   | `playwright` npm version to install (e.g. `1.48.0`).                                         |
| `browsers`    | `chromium` | Browsers to download: comma-separated `chromium`/`firefox`/`webkit`, `all`, or `none`.       |
| `installDeps` | `true`     | Install the OS packages the browsers need (`playwright install-deps`; needs an apt base image). |

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/playwright-cli:1": {
        "version": "latest",
        "browsers": "chromium,firefox",
        "installDeps": true
    }
}
```

> **Note:** `browsers` installs the browsers Playwright itself ships. The
> `playwright install chrome`/`msedge` channels (system-branded builds) are not
> covered by this Feature's default flow.

## databricks-cli

### What it installs

- The prebuilt `databricks` binary from the
  [databricks/cli GitHub releases](https://github.com/databricks/cli/releases),
  the same artifact the official
  [curl installer](https://docs.databricks.com/aws/en/dev-tools/cli/install#curl-installation-for-linux-macos-and-windows)
  uses, installed to `/usr/local/bin` so it's on `PATH` for every user.
- Unlike the upstream `curl | sh` script, the Feature resolves `latest` at
  build time and verifies the archive against the release's `SHA256SUMS` file
  before installing. Supports `amd64` and `arm64`.

Published image:

```
ghcr.io/ifm-pgarner/devcontainers-features/databricks-cli
```

### Usage

```jsonc
"features": {
    "ghcr.io/ifm-pgarner/devcontainers-features/databricks-cli:1": {}
}
```

#### Options

| Option    | Default  | Description                                              |
| --------- | -------- | -------------------------------------------------------- |
| `version` | `latest` | Databricks CLI version to install (e.g. `0.250.0`).      |

### Signing in

The Feature is set up for interactive OAuth (U2M) login, which Databricks
recommends over personal access tokens. Inside the container, run:

```bash
databricks auth login --host https://<deployment-name>.cloud.databricks.com
```

(Omit `--host` to pick a workspace at `login.databricks.com`.) VS Code opens
the login page in your host browser and forwards the callback into the
container. Then check it worked:

```bash
databricks auth profiles
databricks current-user me
```

#### How the login is stored

- The Feature mounts a named Docker volume, `databricks-cli-auth`, at
  `/dc/databricks`. It is shared by every project using this Feature, so you
  sign in once per machine and the login survives container rebuilds.
- `DATABRICKS_CONFIG_FILE` points at `/dc/databricks/.databrickscfg`. For
  OAuth profiles this holds only the host and profile name, no secrets.
- `~/.databricks` (the OAuth token cache) is symlinked into the volume.
- The container has no OS keyring, so the Feature sets
  `DATABRICKS_AUTH_STORAGE=plaintext`. Tokens are stored unencrypted inside the
  volume (mode `0700`, owned by the remote user). Access tokens expire within
  an hour and are refreshed automatically.

To sign out, run `databricks auth logout`. To wipe the login entirely,
`docker volume rm databricks-cli-auth`.

**Never commit `.databrickscfg` files or tokens, or bake them into images.**
For CI/automation, use OAuth M2M with a service principal: supply
`DATABRICKS_HOST`, `DATABRICKS_CLIENT_ID` and `DATABRICKS_CLIENT_SECRET` from
your CI secret store.

## Repository layout

```
.
├── src/
│   ├── snow-cli/
│   │   ├── devcontainer-feature.json   # Feature metadata + options
│   │   └── install.sh                  # Install logic (uv → snowflake-cli)
│   ├── playwright-cli/
│   │   ├── devcontainer-feature.json   # Feature metadata + options
│   │   └── install.sh                  # Install logic (npm → playwright + browsers)
│   └── databricks-cli/
│       ├── devcontainer-feature.json   # Feature metadata + options
│       └── install.sh                  # Install logic (GitHub release → databricks)
├── test/
│   ├── snow-cli/
│   │   ├── test.sh                     # Default test
│   │   ├── scenarios.json              # Scenario definitions
│   │   └── install_python_312.sh       # Scenario test
│   ├── playwright-cli/
│   │   ├── test.sh                     # Default test
│   │   ├── scenarios.json              # Scenario definitions
│   │   ├── install_cli_only.sh         # Scenario test (browsers=none)
│   │   └── install_firefox.sh          # Scenario test (browsers=firefox)
│   └── databricks-cli/
│       ├── test.sh                     # Default test
│       ├── scenarios.json              # Scenario definitions
│       └── install_pinned_version.sh   # Scenario test (version=0.250.0)
└── .github/workflows/
    ├── release.yaml                # Publish to GHCR + generate docs
    └── test.yaml                   # Run feature tests in CI
```

## Contributing / releasing

1. Make your changes under `src/<feature>/` (e.g. `src/snow-cli/` or
   `src/playwright-cli/`).
2. **Bump `version`** in that feature's `devcontainer-feature.json` (semver) —
   this is what triggers a new published version.
3. Merge to `main`. The `release.yaml` workflow publishes every feature under
   `./src` to GHCR via
   [`devcontainers/action`](https://github.com/devcontainers/action) and opens a
   PR with the auto-generated per-feature `README.md` (don't hand-write that
   file).
4. **First publish only:** set the GHCR package visibility to **public** so
   consumer repos can pull it without authentication.

Tests run automatically on pull requests via `test.yaml`, or locally with:

```bash
devcontainer features test -f snow-cli       -i mcr.microsoft.com/devcontainers/base:ubuntu .
devcontainer features test -f playwright-cli -i mcr.microsoft.com/devcontainers/base:ubuntu .
```

## License

[MIT](./LICENSE)
