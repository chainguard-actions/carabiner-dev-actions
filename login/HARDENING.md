<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): an unquoted expansion of data that comes from a workflow input. `requested_resources` is built from INPUTS_RESOURCE (inputs.resource) and expanded without quotes in `for res in ${requested_resources}; do`. The shell splits the value on whitespace, which is intended, but it also expands glob characters (*, ?, [) against the runner's filesystem. Fix: split the value safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop with `for res in "${resources[@]}"`. Alternatively, turn globbing off with `set -f` before the loop.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

`expires_in` and `granted_scope` are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` cleanup: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the token server at INPUTS_EXCHANGE_URL, and that URL is set by the caller through inputs.exchange-url. A hostile or compromised server can put newlines in the `scope` or `expires_in` fields and add or overwrite step outputs. The token written to GITHUB_ENV is checked against a single-line JWT regex, but these two values are not checked. Fix: clean each value right before writing it, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for expires_in.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list is now split into a bash array with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true`, and the loop expands `${resources[@]+"${resources[@]}"}`. It still splits on whitespace, but glob characters are no longer matched against files on the runner. The empty-array form works under set -u on bash 3.2. github-env-injection: newlines are stripped from expires_in and granted_scope with printf | tr -d '\n\r' right before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Replaced `for res in ${requested_resources}` with a whitespace split via `read -r -a resources <<< "$requested_resources"` (guarded for empty input) and iterate `${resources[@]+"${resources[@]}"}` (set -u safe on bash 3.2). Same whitespace splitting as upstream, without glob expansion.

