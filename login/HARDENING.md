<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite 'login' step writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the token-exchange response. The server is chosen by the input `inputs.exchange-url` (INPUTS_EXCHANGE_URL), so whoever calls the action controls the response. Neither value goes through `printf '%s' ... | tr -d '\n\r'` before the write. A response containing newlines could add arbitrary step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because a regex first checks it is a single-line JWT.

Locations:

- `action.yml:158`
- `action.yml:159`

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from the input `inputs.resource` (INPUTS_RESOURCE), and here it is expanded without quotes. The shell splits it on whitespace and also expands glob characters (*, ?, [) against the filesystem. Split the value safely instead, for example with `read -ra arr <<< "$requested_resources"`, and loop over the quoted array `"${arr[@]}"`.

Locations:

- `action.yml:89`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both fixes are in action.yml; I haven't run the action to test them.

- **github-env-injection:** `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. A hostile exchange server can no longer add extra step outputs.
- **script-injection:** the unquoted `for res in ${requested_resources}` is replaced. The value is now read into an array with `read -r -d '' -a` (with `|| true`, inside a guard that skips an empty value), and the loop runs over the quoted array. It still splits on whitespace as before but no longer expands glob characters. The array is expanded in a way that still works under `set -u` when it is empty, including on bash 3.2. The `xargs` step upstream uses to normalise the resource list is unchanged.

