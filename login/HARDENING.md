<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`) without first running them through `printf '%s' ... | tr -d '\n\r'`. Both values come from `jq -r` output of the token-exchange HTTP response, and the server URL is set by the `inputs.exchange-url` input. A string field containing embedded newlines could therefore inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is protected by a single-line JWT regex check, but these two output writes have no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b) violated: an unquoted shell expansion of input-derived data in step 'login'. The line is `for res in ${requested_resources}; do`. `requested_resources` comes from `INPUTS_RESOURCE` (`${{ inputs.resource }}`) and is expanded without quotes, so the shell applies word splitting and pathname (glob) expansion to the workflow-supplied value. It should be split safely instead, e.g. `read -ra resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`, or the loop should run with globbing disabled (`set -f`).

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Strip CR/LF from expires_in and granted_scope (via printf '%s' | tr -d '\n\r') before writing them to GITHUB_OUTPUT. Replaced the unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true` and a loop over "${resources[@]}". This splits on whitespace exactly as before but without glob expansion. The loop only runs when the value is non-empty, so set -u is never triggered by an empty array.

