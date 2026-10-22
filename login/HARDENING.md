<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data. The value of `requested_resources` comes from inputs.resource (through INPUTS_RESOURCE and xargs). It is expanded without quotes in `for res in ${requested_resources}; do`. The shell therefore splits it into words and also expands glob characters (*, ?, [ ]) in it, so an input value can turn into file names from the runner's disk. Fix: split it safely with `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`, after turning off globbing with `set -f` if needed.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

Step 'login' writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` cleanup step. Lines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are read with `jq -r` from the JSON reply of the exchange server. The server address comes from inputs.exchange-url, so the caller controls it. `jq -r` keeps embedded newlines, so a hostile reply could add extra lines and create fake step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is fine because the token is first checked against a single-line JWT pattern. Fix: clean each value right before the write, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for expires_in.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Replaced unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources` whitespace split (no globbing) and iterate over the quoted array (set -u safe). Sanitized expires_in and granted_scope with `printf '%s' | tr -d '\n\r'` right before writing to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the broken 'login' step in action.yml. The line `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"` is back, so the token is written to GITHUB_ENV again. The token was already checked against a single-line JWT pattern, and I added `::add-mask::` before the write so it is hidden in logs. I uncommented the safe_expires_in assignment, which `set -u` needs. I removed the stray spliced text that left a quote unclosed, and the two unsanitized `expires-in` / `scope` writes. Both outputs are now written only from values that had newlines stripped with `tr -d '\n\r'`. The closing notice message uses the cleaned expires-in value too. I haven't run the action or the script to test these changes.

