<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization step (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`). Both values are read with `jq -r` from the response of the server at `inputs.exchange-url`, which the caller controls. A hostile or compromised exchange server can put newlines in `.scope` or `.expires_in` and inject extra step outputs. The token write to GITHUB_ENV is safe because a single-line JWT regex check guards it, but these two writes have no such guard. Fix: `safe=$(printf '%s' "$granted_scope" | tr -d '\n\r')` before writing, and do the same for expires_in.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b) is violated: an expansion of input-derived data is not quoted. `for res in ${requested_resources}; do` expands `requested_resources` (taken from `inputs.resource` via INPUTS_RESOURCE) without double quotes. The shell therefore applies word splitting and pathname/glob expansion to the input value, so glob characters in the input could expand to file names on the runner. Fix: split safely with `read -ra resources <<< "$requested_resources"`, then `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized expires_in and granted_scope with printf '%s' | tr -d '\n\r' before writing to GITHUB_OUTPUT. Replaced the unquoted `for res in ${requested_resources}` with a whitespace split (`read -r -d '' -a`, guarded by an emptiness check, with `|| true`) and iteration over the quoted array using the ${arr[@]+...} form, which is safe under set -u. This keeps upstream's whitespace splitting and removes glob expansion.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Replaced `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources` whitespace split (|| true for set -e) and a loop over the quoted array, which works with an empty array under set -u. The value is still split on whitespace as before, but glob characters are no longer expanded.

