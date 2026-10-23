<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes two values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are read with `jq -r` from the response of the server at `inputs.exchange-url`, which the caller controls. `jq -r` turns an escaped \n in a JSON string into a real newline, so a hostile server can add extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is already checked against an anchored single-line JWT regex. Fix: run `printf '%s' "$expires_in" | tr -d '\n\r'` and `printf '%s' "$granted_scope" | tr -d '\n\r'` before writing.

Locations:

- `action.yml:148`
- `action.yml:149`

### script-injection (severity: high)

Rule (b) broken in step 'login' of action.yml: `for res in ${requested_resources}; do`. The variable `requested_resources` comes from INPUTS_RESOURCE (`inputs.resource`) and is expanded without quotes. The shell splits it on whitespace, which is intended, but it also expands glob characters (`*`, `?`, `[`) against the filesystem. Fix: split it safely with `read -ra resources <<< "$requested_resources"`, then loop with `for res in "${resources[@]}"`.

Locations:

- `action.yml:82`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: expires_in and granted_scope are now passed through printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. script-injection: requested_resources (already reduced to one line by xargs) is now split on whitespace into an array with read -r -d '' -a, which does not expand globs. This replaces the unquoted for-loop. The read is skipped when the value is empty, and the line ends in '|| true' so it does not fail the step. The array is expanded with ${arr[@]+...}, which keeps 'set -u' from failing on an empty array in older bash.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope now have \n and \r removed with printf '%s' | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. The original variables are captured on their own line, so jq errors are handled exactly as before.

