<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Composite step 'login' writes values parsed from the token-exchange server's response to $GITHUB_OUTPUT without the required printf '%s' ... | tr -d '\n\r' sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the response body. The server is chosen by the untrusted input `inputs.exchange-url`, and `jq -r` can print strings that contain newlines, so a hostile response could inject extra outputs. (The CARABINER_CREDENTIALS write to GITHUB_ENV is regex-checked as a single-line JWT first, but these two writes have no check.) Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` right before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of workflow-controlled data. Offending line: `for res in ${requested_resources}; do`. `requested_resources` comes from the env var INPUTS_RESOURCE (inputs.resource). Because the expansion is unquoted, the shell splits it into words and also glob-expands any glob characters in the input. Fix: split the value safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

action.yml: expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before being written to GITHUB_OUTPUT. The unquoted `for res in ${requested_resources}` is replaced: the value is first split into an array with `read -r -d '' -a resources <<< ... || true`, which splits on whitespace like before but no longer expands glob characters. The read only runs when the value is non-empty. The loop then uses `${resources[@]+"${resources[@]}"}`, so an empty array doesn't trip `set -u` on older bash.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Replaced `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true` and a loop over the quoted array elements (using a form that is safe under set -u). It still splits on whitespace the same way upstream did, but it no longer expands glob characters.

