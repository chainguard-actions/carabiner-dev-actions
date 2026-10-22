<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the composite step 'login', values parsed out of the token-exchange server's response are written to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step. The lines are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server URL comes from the caller-supplied inputs.exchange-url, so the response is untrusted, and `jq -r` can emit embedded newlines. That lets a hostile response inject extra outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is regex-checked to be a single line, but these two writes are not checked at all.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. The line `for res in ${requested_resources}; do` expands requested_resources without quotes. That variable is built from INPUTS_RESOURCE, which is set from ${{ inputs.resource }}. Without quotes the shell applies word splitting and glob expansion to the value. Split it safely instead, for example with `read -r -a resources <<< "$requested_resources"` and then `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Strip newlines from expires_in and granted_scope (printf | tr -d '\n\r') before they are written to GITHUB_OUTPUT. Replaced the unquoted 'for res in ${requested_resources}' loop with a guarded 'read -r -d "" -a resources' whitespace split (with || true). The loop now goes over the quoted array using the ${arr[@]+...} form, which is safe under set -u. The split is the same as before (on whitespace), but globbing no longer happens.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml login step, expires_in and granted_scope are sanitized via printf '%s' | tr -d '\n\r' into safe_* variables before being written to $GITHUB_OUTPUT. The script runs with pipefail, and the inputs are already-captured variables, so no error status is masked.

