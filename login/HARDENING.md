<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the reply of the server at INPUTS_EXCHANGE_URL (`inputs.exchange-url`), which the caller controls. Values containing newlines could add extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because a single-line JWT regex checks it first.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of input data. `for res in ${requested_resources}; do` expands `requested_resources`, which comes from INPUTS_RESOURCE (`inputs.resource`), without quotes. The shell therefore applies word splitting and glob expansion to a value the caller controls. Splitting on spaces is intended here, so the fix is to split safely (for example `read -ra resources <<< "$requested_resources"`) and loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run to test the changes.

- **github-env-injection:** `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to $GITHUB_OUTPUT. A server reply containing newlines can no longer add extra step outputs.
- **script-injection:** the unquoted `for res in ${requested_resources}` loop is gone. When the list isn't empty, the code splits it into an array with `read -r -d '' -a resources <<< "$requested_resources" || true` and loops over the quoted array. The `${resources[@]+...}` form keeps an empty array from failing under `set -u` on older bash. It still splits on whitespace, as the original loop did, but no longer expands globs.

The earlier `xargs` step that tidies up the input is unchanged.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Replaced `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true` split and iteration over the quoted array (using the ${arr[@]+...} form for set -u compatibility on bash 3.2). Whitespace splitting is preserved, glob expansion removed.

