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

Secrets are printed in `KEY=value` format, ready to be sourced into your shell.

**Fetch a single secret:**
```bash
vaultez fetch --company="Acme" --project="Backend" --secret="DATABASE_URL"
```

The plain value is printed with no extra formatting, so it pipes cleanly:

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

## How it works

The CLI authenticates against the Vaultez API and respects the same access
controls as the web app. You will only see secrets your account has been
granted access to.

Every secret fetch is logged as an activity in the Vaultez web UI, so all
terminal access is auditable.

## License

MIT
