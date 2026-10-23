<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values taken from the token exchange server's response straight to $GITHUB_OUTPUT without sanitizing them: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` (line 138) and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` (line 139). Both values come from `jq -r` on a response from the server at inputs.exchange-url, and the caller controls that input. A hostile or compromised server could return newlines in these fields and inject extra outputs. Fix: run `printf '%s' ... | tr -d '\n\r'` on each value before writing it. The CARABINER_CREDENTIALS write to GITHUB_ENV is already safe because the token is checked against a single-line JWT regex first.

Locations:

- `action.yml:138`
- `action.yml:139`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Removed CR/LF from expires_in and granted_scope (both from the exchange server's response) with printf | tr -d '\n\r' before writing them to GITHUB_OUTPUT. Nothing else changed.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Replaced `for res in ${requested_resources}` with a whitespace split into an array (`read -r -d '' -a resources <<< ...  || true`, guarded for empty values) and a quoted `"${resources[@]}"` loop. This keeps upstream's whitespace splitting but removes filename globbing. The length check keeps an empty array safe under set -u on bash 3.2.

