<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the composite step 'login', two values are written to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on the reply of the token exchange server. The caller picks that server through `inputs.exchange-url`. `jq -r` prints embedded newlines as real newlines, so a malicious or compromised server can add extra step outputs. Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` before writing it. The CARABINER_CREDENTIALS write to GITHUB_ENV is already protected by a strict single-line JWT regex check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of input-derived data: `for res in ${requested_resources}; do`. `requested_resources` comes from `INPUTS_RESOURCE` (`inputs.resource`). Leaving it unquoted means the shell splits it on whitespace and also expands glob characters in it (e.g. `*`, `?`, `[`) against the working directory. Fix: split it safely into an array, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires-in and scope with printf|tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced unquoted `for res in ${requested_resources}` with a whitespace split into an array via `read -r -d '' -a ... || true` (guarded for empty, set -u safe), avoiding glob expansion while preserving whitespace splitting semantics.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml login step, expires_in and granted_scope are sanitized with printf '%s' ... | tr -d '\n\r' immediately before being written to $GITHUB_OUTPUT. The scope-narrowing warning logic is unchanged.

