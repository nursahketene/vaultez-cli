# Changelog

## 0.4.0

**Breaking:** the default `vaultez fetch` output now quotes values. Anything
that parsed the old `KEY=value` lines by splitting on `=` will now see the
quotes. Use `--format=json` for machine parsing.

- Values are single-quoted (`KEY='value'`), so the output is safe to `eval` or
  `source`. Before, a value containing a space, `;`, `$(...)` or a newline
  could run commands or break the line when sourced.
- New `--format` option: `env` (default), `shell`, `dotenv`, `github` and
  `json`. `--json` still works and is the same as `--format=json`.
- Secrets whose names aren't valid variable names are skipped, with a warning
  on stderr, instead of producing a broken line. `json` output still includes
  them.
- Errors and notices ("No secrets found", "No companies found") go to stderr in
  every mode, so `vaultez fetch > .env` never writes them into the file.
- Usage errors, such as an unknown flag or `--format` value, now exit with
  status 1 instead of 0.
- Added a test suite (`bundle exec rake test`).

## 0.3.2

- Pin thor to an exact version.
