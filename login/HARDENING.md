<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'login' writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are extracted with `jq -r` from the token-exchange server's response. The calling workflow picks that server through `inputs.exchange-url` (INPUTS_EXCHANGE_URL), so these values come from untrusted input. A hostile or compromised server could return a scope or expires_in value containing newlines and inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, but these two output writes are not checked at all.

Locations:

- `action.yml:138`
- `action.yml:139`

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE | xargs) and is expanded without quotes in `for res in ${requested_resources}; do`. Because it is unquoted, glob characters such as `*`, `?` or `[...]` in the input are expanded against the filesystem. Word splitting also happens through the shell parser rather than being done explicitly. To keep the one-per-URI behavior safely, split it explicitly, for example `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`, or turn off globbing with `set -f`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Before writing expires-in and scope to GITHUB_OUTPUT, both values now go through printf '%s' | tr -d '\n\r', which removes newlines. These values come from the exchange server's JSON response. Replaced the unquoted `for res in ${requested_resources}` loop: the list is now split with `read -r -d '' -a resources` (guarded by a non-empty check, with || true) and the loop runs over the resulting array. The array expansion is written to work under set -u and bash 3.2. Splitting on whitespace is the same as before, and glob characters in the input are no longer matched against files. I haven't run the action to test this.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the step now removes CR and LF from expires_in and granted_scope (printf | tr -d '\n\r') before writing them to GITHUB_OUTPUT. The values are passed in as plain variables, so sanitizing cannot hide a failing command. pipefail is set either way.

