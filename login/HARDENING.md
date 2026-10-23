<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step in action.yml writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step. Lines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON returned by the server at `inputs.exchange-url`, which the caller controls, and are read with `jq -r`. `jq -r` turns an escaped \n inside a JSON string into a real newline, so a hostile or compromised server could add extra output lines. The access token itself is checked against a single-line JWT regex, but these two values are not checked at all.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted shell expansion of untrusted data, in the 'login' step: `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE and xargs). Because it is unquoted, the shell splits the value on whitespace and also expands glob characters in it. Fix: split it into an array without glob expansion, e.g. `read -r -a res_list <<< "$requested_resources"`, then loop with `for res in "${res_list[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before expires_in and granted_scope are written to $GITHUB_OUTPUT, the step now removes newlines and carriage returns from both with printf '%s' | tr -d '\n\r'. Both values come from the exchange server's response, so they are untrusted. script-injection: the loop no longer uses the unquoted ${requested_resources}, which split on whitespace and also expanded glob characters. The value is now read into an array with read -r -d '' -a (guarded so an empty value adds nothing, with || true because read -d '' returns 1 at the end of input), and the loop runs over ${res_list[@]+"${res_list[@]}"}. That form keeps set -u from failing on an empty array in older bash. The value is still split on whitespace as before, but glob characters are no longer expanded. Nothing was run to test these changes.

