<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes values from the token server's response to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step that removes newlines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the response from `${INPUTS_EXCHANGE_URL}`, which is the caller-controlled `inputs.exchange-url`. A hostile or compromised server can return a JSON string containing newlines. That lets it add extra step outputs. Only the access token is checked against a single-line regex; these two values are not.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): a value from a workflow-controlled input is expanded without double quotes. `for res in ${requested_resources}; do`: requested_resources comes from INPUTS_RESOURCE (inputs.resource). Because it is unquoted, the shell performs word splitting and glob expansion on the input's contents. Read the value with `read -ra` into an array and iterate over the quoted array elements instead.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before expires_in and granted_scope are written to $GITHUB_OUTPUT, each is now passed through printf '%s' | tr -d '\n\r'. A hostile token server can no longer use newlines in those values to add extra step outputs. script-injection: the resource list is now read into an array with `read -r -d '' -a`, guarded by an emptiness check and `|| true`, and the loop runs over the quoted array elements. The input is still split on whitespace as before, but glob expansion no longer happens. The array is expanded as ${arr[@]+...} so an empty list still works under `set -u` on the bash 3.2 that macOS runners ship. The existing xargs step that cleans up whitespace is unchanged.

