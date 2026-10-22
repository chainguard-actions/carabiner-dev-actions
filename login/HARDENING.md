<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' (action.yml line 37) writes values to $GITHUB_OUTPUT without sanitising them first. The lines are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` (line 137) and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` (line 138). Both values come from `jq -r` run on the HTTP response body. That response is fetched from `${INPUTS_EXCHANGE_URL}`, which the caller sets through inputs.exchange-url. A hostile or misconfigured exchange server could return a JSON string with embedded newlines, such as `"scope": "x\nother=..."`, and inject extra step outputs. Neither value goes through `printf '%s' ... | tr -d '\n\r'` before the write. The CARABINER_CREDENTIALS write to $GITHUB_ENV is protected by the strict single-line JWT regex check. Fix: `safe_exp=$(printf '%s' "$expires_in" | tr -d '\n\r')` and `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')` before writing.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of workflow-controlled data. Offending line: `for res in ${requested_resources}; do` (line 76). `requested_resources` comes from INPUTS_RESOURCE (inputs.resource), passed through xargs. Because the expansion is unquoted, it is subject to word splitting and pathname (glob) expansion, so a value like `*` expands to filenames in the working directory. Fix: split safely without an unquoted expansion, e.g. `read -r -a resources <<< "$requested_resources"` with `set -f`, then `for res in "${resources[@]}"; do`. No ${{ }} expressions appear inside the run: script, so sub-rule (a) passes.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both edits are in action.yml.

1. github-env-injection: newlines are now stripped from expires_in and granted_scope with `printf '%s' | tr -d '\n\r'` before they are written to $GITHUB_OUTPUT. A malicious exchange server can no longer add extra step outputs by putting newlines in its response.

2. script-injection: removed the unquoted `for res in ${requested_resources}`. The resource list is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`. This only runs when the list is non-empty, and the loop goes over the quoted array.

The split is the same as upstream's: on whitespace, newlines included. The one difference is that values are no longer glob-expanded, so a `*` can't turn into file names. The `${arr[@]+...}` form keeps empty arrays from tripping `set -u` on older bash versions.

I haven't run the action or any tests to confirm these changes.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, requested_resources is now split into an array with `read -r -a`, behind a guard that skips it when the value is empty. This keeps upstream's whitespace splitting (xargs has already put the value on one line) and stops glob expansion. The array is expanded quoted, using the ${arr[@]+...} form so it is safe under set -u.

