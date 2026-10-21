<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes two values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the token-exchange server's JSON response through `jq -r`. The server is whatever `inputs.exchange-url` points to, so the caller controls it. A response holding a newline would let it inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, but these two outputs get no check at all.

Locations:

- `action.yml:135`
- `action.yml:136`

### script-injection (severity: high)

Sub-rule (b) is violated: an input-derived shell variable is expanded without quotes. `requested_resources` comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`) and is expanded bare in `for res in ${requested_resources}; do`. Without quotes, the shell applies glob/pathname expansion to the input, so a value like `*` or `/etc/*` turns into file names from the runner's disk. Splitting into words should be done safely instead, e.g. `read -r -a resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`, or by running `set -f` before the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run to test the changes.

- **github-env-injection:** the `expires-in` and `scope` values come from the exchange server's response. Each now goes through `printf '%s' ... | tr -d '\n\r'` before it is written to `$GITHUB_OUTPUT`. A response containing a newline can no longer add extra step outputs.
- **script-injection:** the resource input used to be split by an unquoted `for res in ${requested_resources}`, which let the shell turn values like `*` into file names. It is now split on whitespace into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, and only when the value is non-empty. The loop runs over the quoted array with `${resources[@]+"${resources[@]}"}`, a form that also works with `set -u` on bash 3.2. The splitting is the same as before, minus the glob expansion.

