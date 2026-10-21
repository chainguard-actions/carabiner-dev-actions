<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the 'login' step, two values go into $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on the token-exchange response. The server that sends that response is picked by the caller through `inputs.exchange-url` (INPUTS_EXCHANGE_URL), and `jq -r` can print text that contains newlines. A hostile or compromised exchange server could therefore add extra step outputs. The CARABINER_CREDENTIALS write to $GITHUB_ENV is checked first against a strict single-line JWT regex, which in practice keeps out newlines. The two output writes have no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. The 'login' step has `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (INPUTS_RESOURCE, cleaned up with xargs) and is expanded without quotes, so the shell splits it into words and expands glob characters in the caller's value. The splitting looks deliberate. It should be done safely, for example `read -r -a resources <<< "$requested_resources"` followed by a loop over `"${resources[@]}"`, or by running `set -f` first.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before `expires_in` and `granted_scope` are written to $GITHUB_OUTPUT, each now goes through `printf '%s' | tr -d '\n\r'` to remove newlines. script-injection: the unquoted `for res in ${requested_resources}` loop no longer expands the value directly. The value is now split into an array with `read -r -d '' -a ... || true`, only when it is non-empty, and the loop runs over `${resources[@]+"${resources[@]}"}`. This still splits on whitespace as before but no longer expands glob characters, and it is safe under `set -u`. I haven't run the action or any tests after the change.

