<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes two values taken from the token-exchange server's JSON reply straight into $GITHUB_OUTPUT: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server is the one named by the workflow-controlled input `inputs.exchange-url`. `jq -r` turns an escaped newline inside a JSON string into a real newline, so a hostile or compromised exchange server could add extra outputs. The required `printf '%s' ... | tr -d '\n\r'` step is not applied before these writes. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked first against a single-line JWT regex, but the two GITHUB_OUTPUT values are not checked at all.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data. The 'login' step has `for res in ${requested_resources}; do`, where `requested_resources` comes from the input `inputs.resource` (via INPUTS_RESOURCE and xargs). The word splitting is intentional, but the unquoted expansion also lets the shell expand glob characters (`*`, `?`, `[...]`) in the input. The fix is to split safely, for example `read -r -a resources <<< "$requested_resources"`, then loop over the quoted array `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: expires_in and granted_scope are run through printf '%s' | tr -d '\n\r' before being written to GITHUB_OUTPUT. script-injection: the xargs-normalized resource list is now split into an array with read -r -d '' -a, inside an emptiness guard and with '|| true' (read returns 1 at end of input, which set -e would otherwise treat as a failure). The loop then iterates over ${resources[@]+"${resources[@]}"}, which avoids the set -u failure on empty arrays in older bash. Splitting stays whitespace-based as upstream had it, but there is no more globbing.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the resource list is now split with read -r -a into an array, guarded so it only runs on a non-empty value, and the loop goes over the quoted array elements. Splitting on whitespace works as before (xargs has already joined the value into one line), but glob characters are no longer expanded. The ${arr[@]+...} form keeps empty arrays safe under set -u on older bash.

