<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes values parsed from the token-exchange server's response to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on a response from `${INPUTS_EXCHANGE_URL}`, which the calling workflow controls through inputs.exchange-url. A hostile or compromised server could put newlines in these values and inject extra outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, so it is safe.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of input-derived data in step 'login'. The line is `for res in ${requested_resources}; do`. requested_resources comes from INPUTS_RESOURCE (inputs.resource). The word-splitting is intended, but because the expansion is unquoted, glob characters in the input are also expanded. A safer form is `read -ra arr <<< "$requested_resources"` followed by `for res in "${arr[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed both findings in action.yml. I haven't run the action or any tests after the change.

1. github-env-injection: before `expires_in` and `granted_scope` go to $GITHUB_OUTPUT, the step now passes each one through `printf '%s' ... | tr -d '\n\r'`. A malicious exchange server can no longer add extra outputs by putting newlines in its response.

2. script-injection: the `for res in ${requested_resources}` loop expanded the input unquoted, so glob characters in it could match files. It now splits the value into an array with `read -r -d '' -a ... || true` and loops over the quoted array, so glob characters are passed through as literal text. It still splits on whitespace, as before. I used this instead of the `read -ra` the finding suggested because `read -ra` only reads the first line, and `-d ''` reads every line. The `|| true` is needed because `read -d ''` returns 1 at the end of input, which would otherwise stop the step under `set -e`. The loop only runs when the value is non-empty, so an empty `resource` input still sends no resource parameter and the server uses its default.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before being written to $GITHUB_OUTPUT. Nothing else changed. The CARABINER_CREDENTIALS write was already safe because the JWT regex checks it first.

