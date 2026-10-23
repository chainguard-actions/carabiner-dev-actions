<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the composite step 'login' in action.yml, `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` (line 137) and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` (line 138) write values taken from the token-exchange server's JSON (`jq -r '.expires_in'` / `jq -r '.scope'`). The server address comes from the workflow-controlled input `inputs.exchange-url` (INPUTS_EXCHANGE_URL), so whoever controls that input controls the response. `jq -r` turns an embedded \n in a JSON string into a real newline, which would let extra output lines be injected. Neither value goes through the required `printf '%s' ... | tr -d '\n\r'` before the write. The CARABINER_CREDENTIALS write on line 136 is already checked against a strict single-line JWT regex, but it would also be more robust with the standard sanitization pipeline.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do` (line 76). `requested_resources` comes from `inputs.resource` (INPUTS_RESOURCE) after normalization with xargs, and it is expanded without quotes. Word splitting is intended here, but glob characters in the input (for example `*` or `?`) will still be expanded against the filesystem, because `set -f` is not enabled. Read the values into an array safely instead, e.g. `read -r -a resources <<< "$requested_resources"`, and loop over `"${resources[@]}"`, or turn off globbing with `set -f` around the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: the token, expires_in and granted_scope values now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_ENV and GITHUB_OUTPUT, and the writes now use printf. Each value is captured in its own assignment, not wrapped inside another command substitution. script-injection: the resource list was looped over unquoted, so glob characters like * or ? could match files. It is now read into an array with read -r -d '' -a, which splits on whitespace the same way the old loop did, using an empty-input guard and '|| true'. The loop then expands the array quoted, written ${resources[@]+"${resources[@]}"} so it doesn't fail under set -u when the list is empty. Each resource is still passed as its own --data-urlencode argument, as before. Nothing was run to test the changes.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the expires_in and granted_scope values from the exchange server response now go through printf '%s' | tr -d '\n\r' before being written to $GITHUB_OUTPUT. The variables are already set, so stripping them cannot hide a failing command.

