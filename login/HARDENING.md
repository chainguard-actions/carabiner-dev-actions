<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The step writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` without cleaning the values first. Both values are parsed with jq from the response of the token exchange server, and that server's URL comes from the caller (`inputs.exchange-url`). A JSON string can contain newlines, so a hostile or misconfigured server could add extra step outputs. The JWT access token is checked against a regex before it is written to GITHUB_ENV, but these two values are not. Run each value through `printf '%s' ... | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of data the caller controls. The line `for res in ${requested_resources}; do` expands `requested_resources` without quotes, and that value comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`). The shell splits it on whitespace and also expands glob characters, so `*` or `?` in the input would be replaced by matching file names from the workspace. To split safely, read the value into an array with `read -r -a res_arr <<< "$requested_resources"` and loop over `"${res_arr[@]}"`, or turn globbing off with `set -f`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires_in and granted_scope with printf | tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a res_arr` split (whitespace, no globbing) and loop over "${res_arr[@]}"; guard keeps set -u safe on empty input.

