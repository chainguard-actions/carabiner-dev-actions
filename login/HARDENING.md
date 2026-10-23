<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` (line 137) and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` (line 138). Both values are pulled with `jq -r` from the token-exchange response, and the server is chosen by the untrusted `inputs.exchange-url` (INPUTS_EXCHANGE_URL). The values are not passed through `printf '%s' ... | tr -d '\n\r'` before the write. A JSON string containing newlines can therefore add extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV (line 136) is checked against an anchored single-line JWT regex first, but the two GITHUB_OUTPUT writes have no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): the step 'login' expands a value derived from untrusted input without quotes: `for res in ${requested_resources}; do` (line 76). requested_resources comes from INPUTS_RESOURCE (`inputs.resource`). Because the expansion is unquoted, the shell splits it into words and also expands glob characters (`*`, `?`, `[...]`) taken from the input. Fix: read it into an array with `read -ra res_list <<< "$requested_resources"` and loop over `"${res_list[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

The expires-in and scope values are now passed through printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. The unquoted `for res in ${requested_resources}` loop is replaced with a guarded `read -r -d '' -a res_list ... || true` and a loop over the quoted array. Resources are still split on whitespace as before, but glob characters are no longer expanded. The loop expands the array with ${arr[@]+...} because the script runs under set -u.

