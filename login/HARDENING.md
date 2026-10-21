<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes values parsed from the token-exchange server's response to $GITHUB_OUTPUT without the printf '%s' ... | tr -d '\n\r' sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on a response from the server at inputs.exchange-url, which the caller controls. That response can contain newlines, so a malicious or compromised exchange server could inject extra step outputs. (The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a strict single-line JWT regex first, so it is safe in practice.)

Locations:

- `action.yml:134`
- `action.yml:135`

### script-injection (severity: high)

Sub-rule (b): an expansion of input-derived data is not quoted. `for res in ${requested_resources}; do` — requested_resources comes from INPUTS_RESOURCE (inputs.resource). Leaving it unquoted means the shell applies word-splitting and glob expansion to the input, so a value like `*` expands to file names in the working directory. Fix: split the value safely without globbing, for example with `read -ra resources <<< "$requested_resources"` and then `for res in "${resources[@]}"`.

Locations:

- `action.yml:63`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires_in and granted_scope with printf '%s' | tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced the unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources <<< ... || true` (whitespace split, no globbing; kept upstream's xargs normalization) and iterate the array using a set -u-safe expansion.

