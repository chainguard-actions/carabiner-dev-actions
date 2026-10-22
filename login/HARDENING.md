<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), unquoted shell variable expansion of untrusted data. In the login step, `requested_resources` comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`) and is expanded without quotes in `for res in ${requested_resources}; do`. Leaving it unquoted means glob characters in the input (`*`, `?`, `[`) get expanded against the filesystem along with the intended word splitting. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"` then `for res in "${resources[@]}"`, or turn globbing off with `set -f`.

Locations:

- `action.yml:82`

### github-env-injection (severity: high)

The login step writes values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the response of a server whose URL is set by the workflow (`inputs.exchange-url`). A JSON string with embedded newlines can therefore add extra output lines. Only the CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex; these two outputs get no such check. Fix: sanitize each value first, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and the same for expires_in.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed both findings in action.yml. Nothing was run or tested.

**script-injection:** The resource list was expanded unquoted, so `*`, `?` and `[` in the input could match filenames. It is now split into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, and each element is passed quoted. The `|| true` keeps `set -e` from stopping the step, because `read -d ''` returns 1 when it reaches the end of input. An empty input is skipped. The loop also works with `set -u` on bash 3.2 (the macOS version). Splitting is still on whitespace, as before.

**github-env-injection:** `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to `$GITHUB_OUTPUT`.

