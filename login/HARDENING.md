<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes values to $GITHUB_OUTPUT without the required printf '%s' ... | tr -d '\n\r' step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the response of the token exchange server. That server's address comes from the caller-controlled input `inputs.exchange-url` (via INPUTS_EXCHANGE_URL). jq -r prints JSON string escapes like \n as real newlines, so a hostile or compromised server could add extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is guarded by an anchored single-line JWT regex, but expires_in and granted_scope have no such guard. Fix: run each value through printf '%s' "$v" | tr -d '\n\r' just before writing it.

Locations:

- `action.yml:138`
- `action.yml:139`

### script-injection (severity: high)

Sub-rule (b): an unquoted expansion of input-derived data. `for res in ${requested_resources}; do` expands requested_resources, which comes from INPUTS_RESOURCE (inputs.resource), without quotes. The word splitting is intended, but the shell also expands glob characters in the value. Fix: split safely with `read -ra resources <<< "$requested_resources"` and loop over "${resources[@]}" (or turn off globbing with set -f).

Locations:

- `action.yml:77`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Two fixes in action.yml, not run or tested. (1) expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. (2) The unquoted 'for res in ${requested_resources}' loop is replaced with a guarded 'read -r -d "" -a resources' split (with '|| true') and a loop over the quoted array (written in a form that's safe under set -u). It still splits on whitespace like before, but no longer expands globs.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the login step now removes \n and \r from expires_in and granted_scope (printf '%s' | tr -d '\n\r') before writing them to GITHUB_OUTPUT. The sanitizing commands run on variables that were already captured, so error handling is the same as before. The CARABINER_CREDENTIALS write to GITHUB_ENV is unchanged because it is already checked against a JWT regex.

