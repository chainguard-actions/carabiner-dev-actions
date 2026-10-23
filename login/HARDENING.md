<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): a shell variable built from untrusted input is expanded without quotes. `for res in ${requested_resources}; do` expands requested_resources, which comes from INPUTS_RESOURCE (${{ inputs.resource }}), with no quotes. That exposes the input-controlled value to glob expansion as well as word splitting. Split the value safely instead, for example with `read -ra resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The values written to GITHUB_OUTPUT are not sanitized. `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write fields taken from the token-exchange response. That response comes from the server at INPUTS_EXCHANGE_URL (${{ inputs.exchange-url }}), so the caller controls which server answers. jq -r turns embedded \n into real newlines, so a hostile response could inject extra outputs. Neither write runs the value through `printf '%s' ... | tr -d '\n\r'` first. The CARABINER_CREDENTIALS write to GITHUB_ENV is already checked against a single-line JWT regex, so it is safe.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: requested_resources is now split into an array with `read -r -d '' -a` (with a guard for empty values and `|| true`). The loop then goes over the quoted array, using the `${arr[@]+...}` form so `set -u` works with an empty array, so no glob expansion happens. It still splits on whitespace, as upstream's unquoted for-loop did. github-env-injection: expires_in and granted_scope now have \n and \r removed with `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, step 'login': expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' just before they are written to GITHUB_OUTPUT. These values come from the exchange server's response, so this stops a hostile server from adding extra step outputs. Both inputs are variables the script already holds, so no command failure can be hidden by the pipeline. Nothing else changed.

