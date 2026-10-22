<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` without sanitizing them first. Both values come from the JSON response of the token exchange server. That server's URL is the workflow-controlled input `inputs.exchange-url`, passed in as INPUTS_EXCHANGE_URL. `jq -r` can return strings with embedded newlines, so a hostile or spoofed exchange response could inject extra step outputs. Fix: run `printf '%s' "$VAR" | tr -d '\n\r'` on each value before writing it. The CARABINER_CREDENTIALS write to GITHUB_ENV is guarded by a strict single-line JWT regex, but the required tr -d sanitization is not applied there either.

Locations:

- `action.yml:137`
- `action.yml:138`
- `action.yml:136`

### script-injection (severity: high)

Sub-rule (b) is violated in step 'login': the line `for res in ${requested_resources}; do` expands a variable without quotes. requested_resources comes from `inputs.resource` (INPUTS_RESOURCE), so the shell applies word splitting and glob expansion to workflow-controlled data. For example, `*` would expand to filenames in the working directory. Fix: split the value safely, e.g. `read -r -a resources <<< "$requested_resources"` (optionally with `set -f`), then loop over "${resources[@]}".

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run or tested; I checked the changes by re-reading the file.

- **github-env-injection:** The step now strips newlines and carriage returns (`printf '%s' | tr -d '\n\r'`) from `token`, `expires_in` and `granted_scope` before they are written. The token goes to `GITHUB_ENV` as `CARABINER_CREDENTIALS`; the other two go to `GITHUB_OUTPUT`. The original single-line JWT check on the token is unchanged.
- **script-injection:** The unquoted `for res in ${requested_resources}` loop is gone. The value is now split into an array with `read -r -d '' -a resources <<< "${requested_resources}" || true` and looped over as `"${resources[@]}"`. It still splits on whitespace as before, but it can no longer expand file-name patterns like `*`. The loop only runs when `requested_resources` is non-empty, which avoids an unbound-variable error from `set -u` on an empty array in older bash.

