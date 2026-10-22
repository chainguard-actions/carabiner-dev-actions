<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values taken from the token-exchange server's JSON response to $GITHUB_OUTPUT without the required sanitization (`printf '%s' ... | tr -d '\n\r'`). The server URL comes from inputs.exchange-url. The lines are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the response body. jq -r can output strings that contain newlines, so a hostile or compromised exchange endpoint can add extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, but these two output writes have no such check. Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:138`
- `action.yml:139`

### script-injection (severity: high)

Rule (b), unquoted shell expansion of untrusted data. In the 'login' step, `for res in ${requested_resources}; do` expands requested_resources without quotes. That variable comes from INPUTS_RESOURCE (inputs.resource). Word splitting is intended here, but the unquoted expansion also expands glob characters (*, ?, [) in the input against the filesystem. Fix: split safely, e.g. `read -r -a resources <<< "$requested_resources"` then `for res in "${resources[@]}"`, or run `set -f` before the loop.

Locations:

- `action.yml:77`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Before writing expires-in and scope to GITHUB_OUTPUT, each value is now passed through printf '%s' | tr -d '\n\r' to strip newlines. The unquoted loop `for res in ${requested_resources}` is replaced: the resources are first read into an array with `read -r -d '' -a` behind an empty-input guard and `|| true`, and the loop runs over that array quoted. The list still splits on whitespace as before, but glob characters are no longer expanded. The `${arr[@]+...}` form is kept so it works under set -u with older bash.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, newlines and carriage returns are now stripped from expires_in and granted_scope (printf '%s' | tr -d '\n\r') before they are written to GITHUB_OUTPUT. The inputs are plain variables, so tr cannot fail and errexit behaviour is unchanged.

