<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values taken from the token exchange server's response to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization. The values are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on a response from a server whose address is the caller-controlled input `inputs.exchange-url`, so they can contain newlines and inject extra outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV on line 136 is protected by a single-line JWT regex check. The two output writes have no protection.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data. In the 'login' step, `for res in ${requested_resources}; do` expands `requested_resources` without quotes. That variable comes from `INPUTS_RESOURCE` (`inputs.resource`), so the shell word-splits it and expands any glob characters it contains. Fix: split it safely into an array, e.g. `read -ra resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`. Alternatively, turn globbing off with `set -f` before the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires_in and granted_scope with printf '%s' | tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced the unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources` array split (whitespace, no globbing, || true for set -e) and a set -u safe loop over the array.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope are now passed through tr -d '\n\r' just before they are written to $GITHUB_OUTPUT. The original variables are kept for the warning and notice messages. The pipeline runs under set -euo pipefail, so errors are still caught.

