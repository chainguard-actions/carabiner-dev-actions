<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the login step, `expires_in` and `granted_scope` come from the token-exchange server's JSON response (`jq -r '.expires_in'` / `jq -r '.scope'`). That server is chosen by the untrusted `inputs.exchange-url`. Both values are written to $GITHUB_OUTPUT with no newline removal: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. A hostile or redirected exchange server could return values containing newlines and add extra step outputs. Fix: strip newlines first, e.g. `safe=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for expires_in. (The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex, so it is safe.)

Locations:

- `action.yml:149`
- `action.yml:150`

### script-injection (severity: high)

Rule (b): an unquoted shell variable holds untrusted data. `requested_resources` comes from `inputs.resource` (through the INPUTS_RESOURCE env var) and is expanded without quotes in `for res in ${requested_resources}; do`. The shell splits the value on whitespace and also expands glob characters, so input such as `*` or `/etc/*` turns into filenames before being sent as resource parameters. Fix: split the value safely without globbing, e.g. `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do`.

Locations:

- `action.yml:79`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Strips CR/LF from expires_in and granted_scope before writing them to GITHUB_OUTPUT. Resource list is now split on whitespace with `read -r -d '' -a` (with the -n guard and `|| true`) and iterated as a quoted array, so glob characters are no longer expanded; the empty-array expansion is safe under set -u.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope now pass through printf '%s' | tr -d '\n\r' right before they are written to $GITHUB_OUTPUT. These are simple variable values, not command substitutions, and the step runs with pipefail, so this does not change how errors are handled.

