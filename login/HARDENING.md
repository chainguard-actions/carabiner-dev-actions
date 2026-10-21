<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'login' writes values taken from the token-exchange server's response straight to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server is chosen by the workflow-controlled input `exchange-url` (INPUTS_EXCHANGE_URL). `jq -r` decodes JSON strings, so a server that returns embedded newlines in `.scope` or `.expires_in` can inject extra step outputs. The CARABINER_CREDENTIALS write to $GITHUB_ENV is guarded by a single-line JWT regex check, but the two output writes have no guard at all.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b): unquoted shell expansion of input-derived data. `for res in ${requested_resources}; do` expands `requested_resources`, which comes from INPUTS_RESOURCE (`inputs.resource`), without double quotes. The shell will glob-expand wildcard characters in the input (e.g. `*`) against the runner's filesystem. Splitting on whitespace is intended here, so split into an array with `read -ra` (or turn globbing off with `set -f`) instead of relying on an unquoted expansion.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

The expires-in and scope values from the exchange server now have CR/LF removed with printf '%s' | tr -d '\n\r' before they go to $GITHUB_OUTPUT. The resource input is no longer looped over as an unquoted ${requested_resources}. It is now split into an array with 'read -r -d "" -a ... || true', which only runs when the value isn't empty. It still splits on whitespace the way the old loop did, but wildcards like * are no longer expanded against the runner's files. Nothing was tested or run.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the broken block at the end of the login step in action.yml. The `if` around the scope-narrowing warning is now closed with `fi`. Expires-in, the granted scope and the token each go through `printf '%s' | tr -d '\n\r'` before being written. Each write is back on its own line: the token to GITHUB_ENV, the other two to GITHUB_OUTPUT. I deleted the old unsanitized echo lines. I also added `echo "::add-mask::${token}"` before the token is written. The step's own comment says the value is masked, but nothing in the step masked it. Nothing was run to test the change.

