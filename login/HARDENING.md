<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes two values parsed from the token-exchange server's JSON response to $GITHUB_OUTPUT without first stripping newlines with `printf '%s' ... | tr -d '\n\r'`: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on a response from a server picked by inputs.exchange-url. A string containing newlines can therefore add extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is already checked against a single-line JWT regex, but these two writes have no such check. Fix: sanitize each value before writing it, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of input-derived data. Line 76: `for res in ${requested_resources}; do`. `requested_resources` comes from inputs.resource (via INPUTS_RESOURCE), and it is expanded without quotes, so the shell splits it on whitespace and also expands glob patterns in it. Fix: split it into an array safely, e.g. `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires_in and granted_scope with tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a` array split (whitespace, no globbing) and a set -u safe array expansion.

