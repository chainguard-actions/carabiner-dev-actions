<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step writes values taken from the token-exchange server's response straight to $GITHUB_OUTPUT: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server is whatever inputs.exchange-url points to, so the caller controls these values. Both come from `jq -r`, which turns JSON '\n' escapes into real newlines, and the values are never passed through `printf '%s' ... | tr -d '\n\r'` before the write. A hostile response could add extra outputs. Only the CARABINER_CREDENTIALS write is protected, by the JWT regex check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), an unquoted expansion of input data: `for res in ${requested_resources}; do`. requested_resources comes from inputs.resource (through INPUTS_RESOURCE and xargs). Because the expansion is unquoted, the shell applies glob/pathname expansion to the input on top of the intended word splitting. A safer pattern is `read -ra resources <<< "$requested_resources"` followed by a loop over the quoted `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: expires_in and granted_scope are passed through printf '%s' | tr -d '\n\r' before being written to $GITHUB_OUTPUT. script-injection: replaced the unquoted `for res in ${requested_resources}` with an array built via `read -r -d '' -a` (whitespace split including newlines, no glob expansion), guarded by a non-empty check and iterated as "${resources[@]}" (safe under set -u since the guard ensures at least one element).

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Sanitized expires_in and granted_scope with printf '%s' | tr -d '\n\r' before writing to $GITHUB_OUTPUT. The values are already-captured variables, so the pipeline does not mask any command failure.

