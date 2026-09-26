# Vaultez CLI

Access your [Vaultez](https://vaultez.app) secrets from the terminal.

## Installation

```bash
gem install vaultez-cli
```

## Getting started

Authenticate with your Vaultez account:

```bash
vaultez login
```

You will be prompted for your email and password. Your session token is stored
locally in `~/.vaultez/config.yml`.

## Commands

### `vaultez login`

Authenticate with your Vaultez account.

```bash
vaultez login
```

### `vaultez logout`

Revoke your session token and clear local credentials.

```bash
vaultez logout
```

### `vaultez fetch`

Fetch companies, projects, or secrets.

**List all your companies:**
```bash
vaultez fetch --companies
```

**List projects in a company:**
```bash
vaultez fetch --company="Acme" --projects
```

**List all secrets in a project:**
```bash
vaultez fetch --company="Acme" --project="Backend"
```

Secrets are printed as `KEY='value'` lines. Every value is single-quoted, so
the output is safe to `eval` or `source` whatever the secret contains:

```bash
eval "$(vaultez fetch --project="Backend")"
set -a; source <(vaultez fetch --project="Backend"); set +a
```

**Output formats.** Choose one with `--format`:

| Format   | Output                                   | Use it for                               |
|----------|------------------------------------------|------------------------------------------|
| `env`    | `KEY='value'` (default)                  | `eval`, `source`                         |
| `shell`  | `export KEY='value'`                     | `eval`, `source`, exported to child processes |
| `dotenv` | `KEY='value'`, or `KEY="..."` with escapes when needed | `.env` files (dotenv, Next.js, Vite, Docker Compose) |
| `github` | `KEY<<delimiter` blocks                  | `>> "$GITHUB_ENV"` in GitHub Actions, multi-line values included |
| `json`   | `[{"id":…,"name":…,"value":…}]`          | Scripts; `--json` is the same            |

```bash
vaultez fetch --project="Backend" --format=dotenv > .env.local
vaultez fetch --format=github >> "$GITHUB_ENV"
vaultez fetch --project="Backend" --format=json | jq -r '.[].name'
```

Secrets whose names can't be variable names (only letters, numbers and `_`,
not starting with a number, e.g. `Test Secret`) are skipped with a warning on
stderr. They are still included in `json` output.

**Errors never end up in your files.** Stdout only carries data. Errors and
notices such as "No secrets found" go to stderr, and every error (including an
unknown flag) exits with status 1, so check it before using the output:

```bash
vaultez fetch --project="Backend" --format=dotenv > .env.local || exit 1
```

**Fetch a single secret:**
```bash
vaultez fetch --company="Acme" --project="Backend" --secret="DATABASE_URL"
```

The plain value is printed with no quoting or trailing newline, so it pipes cleanly:

```bash
export DATABASE_URL=$(vaultez fetch --project="Backend" --secret="DATABASE_URL")
```

> The `--company` flag is optional when you have a default company set or only
> belong to one company.

### `vaultez config`

Update your local CLI configuration.

**Set a default company** so you don't need to pass `--company` every time:

```bash
vaultez config --default-company="Acme"
```

## Project tokens

For CI/scripts, you can authenticate with a project token instead of a personal
session. Create one in the Tokens tab of your project settings, then set it via
the `VAULTEZ_TOKEN` environment variable:

```bash
VAULTEZ_TOKEN="vz_..." vaultez fetch
VAULTEZ_TOKEN="vz_..." vaultez fetch --secret="DATABASE_URL"
```

A project token already knows which project it belongs to, so no `--project`
flag is needed.

In GitHub Actions:

```yaml
- name: Fetch secrets from Vaultez
  env:
    VAULTEZ_TOKEN: ${{ secrets.VAULTEZ_TOKEN }}
  run: |
    gem install vaultez-cli
    vaultez fetch --format=github >> "$GITHUB_ENV"
```

> **Never pass a token as a command-line flag** (e.g. `--token=vz_...`). CLI
> arguments are visible to every other local user via `ps` for as long as the
> process runs, and get saved in your shell history. Always use the
> `VAULTEZ_TOKEN` environment variable instead.

## How it works

The CLI authenticates against the Vaultez API and respects the same access
controls as the web app. You will only see secrets your account has been
granted access to.

Every secret fetch is logged as an activity in the Vaultez web UI, so all
terminal access is auditable.

## Development

```bash
bundle install
bundle exec rake test
```

## License

MIT
