<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an unquoted shell expansion of data that comes from a workflow input. `for res in ${requested_resources}; do` expands requested_resources, which is built from INPUTS_RESOURCE (inputs.resource), without double quotes. The shell therefore applies word splitting and glob expansion to a value the calling workflow controls. Fix: split the value safely and keep each piece quoted, e.g. `read -ra resources <<< "$requested_resources"; for res in "${resources[@]}"; do ...` (run `set -f` first if globbing is a concern).

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

Two values are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on the token exchange response. The server's URL is set by inputs.exchange-url, so the values trace back to an untrusted input, and a hostile server could put newlines in them to inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is already checked against a single-line JWT pattern, but these two writes have no equivalent check. Fix: sanitize each value before writing, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for expires_in.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the unquoted `for res in ${requested_resources}` now reads the value into a bash array with `read -r -d '' -a`. That still splits on whitespace like upstream, but globbing is gone. A guard handles an empty value. The loop uses the `${arr[@]+...}` form so `set -u` doesn't trip on an empty array. github-env-injection: expires_in and granted_scope are passed through `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT.

