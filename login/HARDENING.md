<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the exchange server via `jq -r`. The server is chosen by `inputs.exchange-url`, so the values are input-derived. `jq -r` turns embedded \n characters in a JSON string into real newlines, so a hostile or misconfigured server can inject extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first. The two output writes have no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an env var holding input data is expanded without quotes. Offending line: `for res in ${requested_resources}; do`. `requested_resources` comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`). Leaving it unquoted lets the shell split it on whitespace and expand glob characters (*, ?, [...]) from the caller's value against the filesystem. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"`, run `set -f` before the loop, then iterate with `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before `expires_in` and `granted_scope` are written to $GITHUB_OUTPUT, they now go through `printf '%s' | tr -d '\n\r'` to remove newlines. script-injection: the resource list is now split into an array with `read -r -d '' -a ... || true`, guarded by an empty-value check. This splits on whitespace like upstream's unquoted expansion did, but without glob expansion. The loop expands the array as `${resources[@]+"${resources[@]}"}`, so an empty array doesn't fail under `set -u`, including on bash 3.2. I didn't run the action or a fresh analysis pass.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, I replaced the unquoted `for res in ${requested_resources}` loop. The resource list now goes into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, which splits on whitespace (newlines too) and does not expand wildcards. A `-n` check skips it when the value is empty, and the loop expands the array quoted, in a form that is safe under `set -u` on older bash. Splitting still works the way upstream's did, and the xargs normalization step is unchanged.

