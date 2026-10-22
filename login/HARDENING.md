<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of input-derived data in the composite step 'login'. Line: `for res in ${requested_resources}; do`. `requested_resources` comes from INPUTS_RESOURCE (inputs.resource) after passing through `xargs`. Because the expansion is unquoted, the shell treats any glob characters in the value as filename patterns and expands them against files on the runner. Read the value into an array safely instead, e.g. `read -r -a res_list <<< "$requested_resources"; for res in "${res_list[@]}"; do`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without running `printf '%s' ... | tr -d '\n\r'` first. Lines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of a server whose URL is set by the caller (inputs.exchange-url). `jq -r` turns `\n` escapes into real newlines, so a hostile response could inject extra output lines. Only the access token is checked against a JWT regex; these two values are not. Strip newlines before writing, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the list of resource URIs is no longer expanded unquoted. It is now read into an array with `read -r -d '' -a` (behind an emptiness check, with `|| true`), and the loop runs over that array quoted, using the `${arr[@]+...}` form so `set -u` doesn't fail on an empty list. It still splits on whitespace as before, but glob characters are no longer expanded against files on the runner. github-env-injection: newlines and carriage returns are now stripped from expires_in and granted_scope before they are written to GITHUB_OUTPUT. Nothing was run to test this.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

action.yml: the line `for res in ${requested_resources}` no longer expands the variable unquoted. The value is now split on whitespace with `read -r -d '' -a resources <<< "$requested_resources" || true`, and the loop runs over `${resources[@]+"${resources[@]}"}`. Each word stays quoted, so glob characters like `*` and `?` are no longer matched against the runner's files. The loop is skipped when the input is empty, and the `${arr[@]+...}` form keeps an empty array from erroring under `set -u` on older bash. Resources are still split on whitespace exactly as before.

