<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` without cleaning the values first. Both come from `jq -r` on the JSON response of the server at `inputs.exchange-url`, which the caller controls. A hostile or compromised server could return a value with newlines (e.g. "scope": "x\nexpires-in=...") and inject extra step outputs. Only the token written to GITHUB_ENV is checked against the JWT regex. Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` right before writing it.

Locations:

- `action.yml:147`
- `action.yml:148`

### script-injection (severity: high)

Rule (b), unquoted shell variable expansion: `for res in ${requested_resources}; do` expands `requested_resources`, which comes from `inputs.resource` (via INPUTS_RESOURCE and xargs), without quotes. The shell splits the value into words and also expands glob patterns, so a caller-supplied value like `*` or `/etc/*` becomes file paths that get sent as resource parameters. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"` (or turn globbing off with `set -f`).

Locations:

- `action.yml:88`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed both findings in action.yml; nothing was run to test the changes.

1. script-injection: the unquoted `for res in ${requested_resources}` loop was letting glob patterns like `*` turn into file paths. The value is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, inside a check that it isn't empty. The loop then goes over `${resources[@]+"${resources[@]}"}`. This form is safe under `set -u` with bash 3.2. It still splits on whitespace and newlines the way upstream did, but no longer expands glob patterns.

2. github-env-injection: `expires_in` and `granted_scope` are run through `printf '%s' ... | tr -d '\n\r'` before being written to GITHUB_OUTPUT. I also changed the `::notice::` line to use the cleaned `expires_in`, since it prints that value as a workflow command too.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the line `for res in ${requested_resources}` is replaced. The value is now split on whitespace into an array with `read -r -d '' -a ... || true`, guarded by an emptiness check, and the loop expands the array quoted, written so it works under set -u. Splitting still happens on whitespace as before, but glob characters are no longer expanded.

