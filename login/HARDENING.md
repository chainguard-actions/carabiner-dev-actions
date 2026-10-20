<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an expansion of untrusted data is not double-quoted. requested_resources comes from inputs.resource (via env INPUTS_RESOURCE, then xargs) and is expanded without quotes in `for res in ${requested_resources}; do`. The shell therefore applies word splitting and glob/pathname expansion to a value the caller controls. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do`, or turn off globbing with `set -f` before the loop.

Locations:

- `action.yml:78`

### github-env-injection (severity: high)

Step 'login' writes values taken from the token-exchange server's response straight to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server address comes from the caller-controlled input exchange-url, and `jq -r` prints embedded newlines as-is. A hostile or compromised server can therefore add extra step outputs. (The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, so it is not flagged.) Fix: strip newlines first, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for expires_in.

Locations:

- `action.yml:148`
- `action.yml:149`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list is now read into an array with `read -r -d '' -a ... || true`, behind a check that skips it when the input is empty. It still splits on whitespace, as upstream did, but no longer expands globs. The loop expands the array in a form that is safe under `set -u` on bash 3.2. github-env-injection: newlines are stripped from expires_in and granted_scope with `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. Nothing was run to test these edits.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt step 3 of the login script: it masks the token and exports CARABINER_CREDENTIALS to GITHUB_ENV with printf (the variable name comes from the README). Put the safe_expires_in sanitization back on its own line and removed the raw expires-in/scope echo lines. Only the sanitized safe_expires_in/safe_scope values are written to GITHUB_OUTPUT now.

