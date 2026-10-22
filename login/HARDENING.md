<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of input-derived data. `requested_resources` comes from INPUTS_RESOURCE (${{ inputs.resource }}) and is expanded without quotes in `for res in ${requested_resources}; do`. Splitting on spaces is intended here, but the unquoted expansion also expands glob characters (e.g. `*`, `?`, `[...]`) in the caller-supplied input against the filesystem. Split the value safely instead, for example with `set -f` or `read -ra resources <<< "$requested_resources"`, and loop over "${resources[@]}".

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

Two values are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from the token-exchange server's JSON response (`jq -r '.expires_in'` and `jq -r '.scope'`), and that server is chosen by the caller-controlled input `inputs.exchange-url`. `jq -r` turns embedded \n into real newlines, so a hostile or compromised exchange server could inject extra step outputs. Only the access token is checked to be a single-line JWT before it is written to GITHUB_ENV; these two values are not checked at all.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Resource list is now split into a bash array with `read -r -d '' -a` (guarded for empty, `|| true` for set -e). The loop uses `${resources[@]+"${resources[@]}"}`, so it stays safe under set -u, and glob characters are no longer expanded. expires_in and granted_scope have newlines stripped (`printf '%s' | tr -d '\n\r'`) before being written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the loop `for res in ${requested_resources}` is replaced with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true`, followed by a loop over the quoted array elements. The split is still on whitespace, as upstream's was, but glob characters in the input are no longer expanded. The empty-array expansion is written to be safe under `set -u` on older bash versions.

