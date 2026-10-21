<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` without first running printf '%s' ... | tr -d '\n\r'. Both values come from the JSON response of the server at inputs.exchange-url, which the caller controls. `jq -r` can return strings with newlines, so a hostile or misconfigured exchange server could add extra output lines. Unlike CARABINER_CREDENTIALS, which is checked against a JWT regex, these two values are written without any newline stripping.

Locations:

- `action.yml:163`
- `action.yml:164`

### script-injection (severity: high)

Rule (b): the value from `requested_resources="$(printf '%s' "${INPUTS_RESOURCE}" | xargs)"` (from inputs.resource) is expanded without quotes in `for res in ${requested_resources}; do`. The shell therefore applies glob expansion to the input as well as splitting it into words. To split safely, use `read -ra resources <<< "$requested_resources"` and loop over "${resources[@]}", or turn globbing off with `set -f`.

Locations:

- `action.yml:88`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both fixes are in action.yml. 1) Before writing to GITHUB_OUTPUT, expires_in and granted_scope now go through printf '%s' | tr -d '\n\r'. A value with a newline can no longer add extra output lines. 2) The requested resources are now read into an array with `read -r -d '' -a` (guarded for an empty value, with || true) and looped as "${resources[@]}". This splits on whitespace the same way the old unquoted loop did, but without glob expansion. Nothing was run or tested. Neither change was exercised against a real or fake exchange server.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml login step, expires_in and granted_scope are passed through printf '%s' | tr -d '\n\r' into safe_* variables before being written to GITHUB_OUTPUT. Other behavior unchanged.

