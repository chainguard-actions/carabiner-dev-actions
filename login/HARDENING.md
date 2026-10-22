<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'login' writes values taken from the token exchange response to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` cleanup step. Lines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both expires_in and granted_scope come from `jq -r` on the response body, and the server that sends that response is set by the caller through inputs.exchange-url (INPUTS_EXCHANGE_URL). A hostile or misconfigured server could put a newline inside .scope or .expires_in (jq -r decodes \n). That would add extra output lines and inject or override step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is not affected: the token must first match a strict anchored JWT regex. Fix: run each value through `$(printf '%s' "$v" | tr -d '\n\r')` before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope are now passed through printf '%s' | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. The step runs with set -euo pipefail, and the source values are plain variables (not command substitutions), so error handling works the same as before. Nothing else was changed.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, replaced `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true` and iterate over the quoted array (using the ${arr[@]+...} form for set -u / bash 3.2 safety). Whitespace splitting is preserved; glob expansion is eliminated.

