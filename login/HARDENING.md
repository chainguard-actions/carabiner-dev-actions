<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data. In the 'login' step, `for res in ${requested_resources}; do` expands `requested_resources` without quotes. That variable comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`), so the shell applies word splitting and glob/pathname expansion to a value the caller controls. Split the value safely instead, for example `read -r -a resources <<< "$requested_resources"` (with `set -f` if needed), then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

In the 'login' step, `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write values taken with `jq -r` from the token-exchange response body. The caller picks the server through `inputs.exchange-url`, so these values are not literals computed in the script. They can contain newlines, and nothing applies `printf '%s' ... | tr -d '\n\r'` before the write, so a hostile response could inject extra output lines. Sanitize each value before writing it, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`. The CARABINER_CREDENTIALS write to GITHUB_ENV is first checked against a single-line JWT regex.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list is now split into an array with `read -r -d '' -a` (with `|| true` and a check for an empty value first), and the loop runs over the quoted array. The split is still on whitespace, as before, but glob expansion no longer happens. The array is expanded with the `${arr[@]+...}` form so `set -u` doesn't fail on older bash when the list is empty. github-env-injection: before `expires_in` and `granted_scope` are written to GITHUB_OUTPUT, newlines and carriage returns are removed with `printf '%s' | tr -d '\n\r'`. Nothing was run or tested after these edits.

