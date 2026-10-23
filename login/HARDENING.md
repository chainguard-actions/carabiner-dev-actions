<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes two values from the token server's response to $GITHUB_OUTPUT without cleaning them first: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on a response from a server the caller picks with the `exchange-url` input. `jq -r` turns escaped newlines in a JSON string into real newlines, so a hostile or spoofed exchange server could add extra output lines and inject outputs. The access token itself is safe because a single-line JWT regex checks it before it is written to GITHUB_ENV. These two values get no such check. Fix: apply `printf '%s' "$VAR" | tr -d '\n\r'` to each value right before writing it.

Locations:

- `action.yml:138`
- `action.yml:139`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from the `resource` input (INPUTS_RESOURCE via `xargs`) and is expanded without quotes. The shell therefore splits it on whitespace and also expands glob characters in it. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Strip CR/LF from expires_in and granted_scope (both come from the exchange server's response) before writing them to GITHUB_OUTPUT. Replace the unquoted `for res in ${requested_resources}` loop: the value is now split on whitespace into an array with `read -r -d '' -a ... || true`, guarded so an empty value adds nothing, and the loop runs over the quoted array. The split is the same as upstream's, but glob characters in the input no longer expand. `set -u` is safe on bash 3.2 (the macOS default) because the array is expanded with the ${arr[@]+...} form. These changes have not been run or tested.

