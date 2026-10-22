<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' composite step writes values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization. Lines 137-138 are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the token-exchange response. The step requests that response from `${INPUTS_EXCHANGE_URL}` (inputs.exchange-url), which the calling workflow controls. jq -r can return strings with newlines in them, so a hostile or compromised exchange server could add extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, but expires_in and granted_scope get no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of workflow-controlled data. The offending line is `for res in ${requested_resources}; do`. requested_resources comes from INPUTS_RESOURCE (inputs.resource) via xargs, and it is expanded without quotes. The shell then splits it on whitespace and also expands glob characters in it. Split it safely instead, e.g. `read -ra resources <<< "$requested_resources"; for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run to test the changes; they were only checked by reading the code.

**script-injection (line 76):** the loop `for res in ${requested_resources}` no longer expands the input unquoted. The resource list is now split into an array with `read -r -d '' -a ... || true`. The read only runs when the value is non-empty. It splits on whitespace like before but no longer expands glob characters. The loop goes over the array with `${resources[@]+"${resources[@]}"}`, the same pattern the script already uses for `scope_args`. That keeps `set -u` from failing on an empty list in older bash versions.

**github-env-injection (lines 137-138):** `expires_in` and `granted_scope` are now passed through `printf '%s' ... | tr -d '\n\r'` before they are written to `$GITHUB_OUTPUT`. Each is cleaned in its own step, separate from the `jq` call that produced it. The original values are still used in the warning and notice messages.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope are now passed through tr -d '\n\r' right before they are written to $GITHUB_OUTPUT. The value is already in a variable when it is cleaned, so no command exit status is hidden. The CARABINER_CREDENTIALS write to GITHUB_ENV is unchanged because it is already checked against a single-line JWT pattern.

