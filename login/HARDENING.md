<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b) violated: an expansion of untrusted data isn't quoted. `requested_resources` comes from the env var INPUTS_RESOURCE (set from `${{ inputs.resource }}`) and is expanded without quotes in `for res in ${requested_resources}; do`. The shell will word-split it and also glob-expand it, so characters like * ? [ in the input turn into file names. Fix: split the input safely, e.g. `read -r -a resources <<< "$requested_resources"` and then loop over `for res in "${resources[@]}"`. Or turn off globbing with `set -f` before the loop.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

Two values are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both are taken with `jq -r` from the response of a server whose URL comes from `inputs.exchange-url` (env INPUTS_EXCHANGE_URL), so they derive from untrusted input. If the response contains a newline, it can inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because the value is checked against a strict single-line JWT regex first. Fix: run each value through `safe=$(printf '%s' "$v" | tr -d '\n\r')` before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the loop no longer uses the unquoted ${requested_resources}. The value is now split into an array with `read -r -d '' -a` (with a non-empty guard and `|| true`), and the loop runs over the quoted array as `${resources[@]+"${resources[@]}"}`, a form that stays safe under `set -u` on bash 3.2. Like upstream's unquoted loop, it still splits on whitespace, but wildcard characters such as * ? [ are no longer turned into file names. github-env-injection: expires_in and granted_scope now pass through `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. Nothing was run or tested.

