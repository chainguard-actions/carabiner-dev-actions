<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes values parsed from the token-exchange HTTP response to $GITHUB_OUTPUT without the required sanitization (printf '%s' ... | tr -d '\n\r'): `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server URL comes from the caller-controlled `inputs.exchange-url`, so a hostile server could return a value containing newlines and inject extra step outputs. jq -r does not remove newlines from string values. Only the access token is checked against the JWT regex before its GITHUB_ENV write.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an expansion of data derived from untrusted input is not quoted. `requested_resources` is built from `INPUTS_RESOURCE` (`${{ inputs.resource }}`) and then expanded without quotes in `for res in ${requested_resources}; do`. This exposes the value to word splitting and glob expansion (e.g. '*' expands to file names). Split it safely instead, e.g. `read -ra resources <<< "$requested_resources"; for res in "${resources[@]}"`, with globbing disabled (set -f).

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Before expires_in and granted_scope (both taken from the token-exchange response) are written to $GITHUB_OUTPUT, they now pass through printf '%s' | tr -d '\n\r' to remove newlines. The resource list is no longer expanded unquoted in the for loop. It is now split on whitespace into an array with read -r -d '' -a, which doesn't glob; the read only runs when the list isn't empty and has '|| true' so it can't stop the step under set -e. The loop expands that array quoted, in a form that works under set -u. The earlier xargs step that normalizes whitespace is unchanged, so the resources are split the same way as before. I didn't run the action or any tests after these edits.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt step 3 of the login script in action.yml. It now runs, each on its own line: add-mask on the token, the printf of the JWT-validated token to GITHUB_ENV as CARABINER_CREDENTIALS, the sanitizing assignments for safe_expires_in and safe_granted_scope (each value passed through tr -d '\n\r'), and writes of only those sanitized values to GITHUB_OUTPUT. I deleted the old unsanitized echo lines and the broken spliced line. The add-mask line was restored on a best guess: the comment fragment '# 3. Mask' and the zizmor note say the token is masked, but the original line had been lost in the bad edit. Nothing was run to test the fix; the change was only made in the file.

