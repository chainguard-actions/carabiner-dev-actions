<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step writes values taken from the token-exchange server's JSON response to $GITHUB_OUTPUT without the printf '%s' ... | tr -d '\n\r' cleanup: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server URL comes from inputs.exchange-url, so the calling workflow controls these values. jq -r can return strings with newlines, which would let a hostile response add extra step outputs. (The CARABINER_CREDENTIALS write to GITHUB_ENV is fine because it is checked against a single-line JWT regex first.)

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an unquoted expansion of untrusted data. `for res in ${requested_resources}; do` expands a value derived from INPUTS_RESOURCE (inputs.resource) without quotes, so the shell applies word splitting and filename globbing to it. A fix that keeps the per-URI loop is to split into an array with `read -ra resources <<< "$requested_resources"` and loop over "${resources[@]}".

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

I fixed both findings in action.yml. I haven't run the action to test the changes.

- **script-injection:** The loop no longer expands `${requested_resources}` without quotes. The value is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, and the loop runs over that array. This keeps upstream's whitespace splitting but no longer matches filenames against the resource URIs. A non-empty check before the read, plus the `${resources[@]+"${resources[@]}"}` form in the loop, keeps an empty input from tripping `set -u` on older bash.
- **github-env-injection:** Newlines and carriage returns are now stripped from `expires_in` and `granted_scope` with `printf '%s' ... | tr -d '\n\r'` before they are written to `$GITHUB_OUTPUT`. A hostile exchange-server response therefore can't add extra step outputs.

The write to `GITHUB_ENV` was not flagged and is unchanged: the token is already checked against a single-line JWT pattern before it is written.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the unquoted loop `for res in ${requested_resources}` is replaced. When the value is non-empty, it is split on whitespace into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`. The loop then expands `${resources[@]+"${resources[@]}"}`, which is safe under set -u even on bash 3.2 when the array is empty. Splitting still happens on whitespace, as upstream did, but glob characters in the input are no longer matched against the runner's files.

