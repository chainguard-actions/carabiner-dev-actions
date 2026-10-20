<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an input-derived value is expanded without quotes. `requested_resources` comes from INPUTS_RESOURCE (${{ inputs.resource }}) and is used unquoted in `for res in ${requested_resources}; do`. The word splitting is deliberate, but the unquoted expansion also lets glob characters (*, ?, [) in a caller-supplied value match files in the working directory. Fix: split safely with `read -ra resources <<< "$requested_resources"` and loop over "${resources[@]}", or turn globbing off with `set -f` first.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

`expires_in` and `granted_scope` are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on the exchange server's response. The server is whatever `inputs.exchange-url` points to, so the caller controls it. A JSON string containing \n will produce real newlines, which can inject extra outputs. Only the access token gets a single-line regex check before it is written. Fix: sanitize each value right before writing it, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: `requested_resources` used to be expanded unquoted in the `for` loop, so a `*`, `?` or `[` in the input could match files in the working directory. It is now split into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`. That runs only when the value is non-empty, and the loop goes over the array with quotes. It still splits on whitespace as upstream did, but no longer globs. The array expansion is guarded so an empty array doesn't trip `set -u` on older bash.
github-env-injection: `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. Each is assigned to a variable on its own first, so a failure isn't hidden by wrapping one command inside another.

