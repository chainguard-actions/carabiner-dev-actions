<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values to $GITHUB_OUTPUT that were not computed in the script. They come from the token-exchange server's JSON response, and the server address is set by inputs.exchange-url. The writes are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r`, which keeps any newlines inside the strings, so a hostile response could add extra outputs. Neither value goes through `printf '%s' ... | tr -d '\n\r'` before the write. The CARABINER_CREDENTIALS write to $GITHUB_ENV is regex-validated as a single-line JWT, so it is not the problem here.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b): an env var holding input data is expanded without quotes. The offending line is `for res in ${requested_resources}; do`. requested_resources comes from INPUTS_RESOURCE (inputs.resource) and is expanded unquoted, so the shell can split it on whitespace and expand glob characters (*, ?, [) against the filesystem. A safer approach is to read it into an array with `read -ra` (after `set -f`) and loop over the quoted array elements.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before expires_in and granted_scope are written to $GITHUB_OUTPUT, they now go through printf '%s' | tr -d '\n\r' to remove newlines. script-injection: the unquoted loop `for res in ${requested_resources}` was replaced. The list is now read into an array with `read -r -d '' -a ... || true`, which still splits on whitespace like the old loop but no longer expands glob characters. The read only runs when the list isn't empty, and the loop goes over the quoted array elements (written to work under set -u).

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the loop `for res in ${requested_resources}` was replaced. The value is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, guarded by `[ -n ... ]`. The loop then runs over the quoted array, using the `${arr[@]+...}` form so an empty array doesn't trip `set -u`. The value is still split on whitespace as before (xargs had already normalized it), but glob characters are no longer expanded against the runner's files.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the token is now cleaned right before it is written to GITHUB_ENV: safe_token="$(printf '%s' "${token}" | tr -d '\n\r')", and safe_token is what gets written. The existing check that the token is a valid compact JWT is still in place, so this doesn't change behavior. A valid token never contains newlines. Nothing else was changed.

