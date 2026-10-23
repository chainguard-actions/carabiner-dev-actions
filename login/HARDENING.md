<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`) without first running `printf '%s' ... | tr -d '\n\r'`. Both values come from the JSON response of the server at inputs.exchange-url (via INPUTS_EXCHANGE_URL), and `jq -r` keeps any newlines in the strings, so a hostile or spoofed exchange server can inject extra output lines. Only the token is checked against the JWT regex; these two values are not. Fix: strip CR/LF first, e.g. `safe=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, then write `$safe`.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from inputs.resource (INPUTS_RESOURCE). Because it is unquoted, the shell also expands glob characters (`*`, `?`, `[`) in the input against the filesystem, not just splitting it into words. Fix: split it safely with `read -r -a resources <<< "$requested_resources"` (with globbing disabled via `set -f` if needed), then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

action.yml: (1) expires_in and granted_scope now have CR/LF removed with printf '%s' | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. (2) The loop over the unquoted ${requested_resources} is gone. The value is now split into an array with read -r -d '' -a (guarded by a non-empty check, with '|| true'). This splits on whitespace the same way as before but skips glob expansion. The array is expanded with the ${arr[@]+...} form, so set -u does not fail on older bash when the array is empty.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

action.yml: the loop `for res in ${requested_resources}` (an unquoted expansion) now goes through an array instead. The code reads the value into `res_list` with `read -r -d '' -a ... || true`, guarded by a non-empty check, and loops over `${res_list[@]+"${res_list[@]}"}`, a form that is safe under set -u. It still splits on whitespace like before, but glob characters are no longer expanded against the filesystem.

