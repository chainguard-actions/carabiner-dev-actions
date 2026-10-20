<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b) is violated: a value controlled by the calling workflow is expanded without quotes. In `for res in ${requested_resources}; do`, requested_resources comes straight from INPUTS_RESOURCE (${{ inputs.resource }}) via `printf '%s' "${INPUTS_RESOURCE}" | xargs`. Because the expansion is unquoted, the shell splits it into words and expands glob characters (*, ?, [...]) against the filesystem. A safer pattern is `read -ra resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`, with globbing turned off (set -f).

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes `expires_in` and `granted_scope` to GITHUB_OUTPUT without the required sanitization (`printf '%s' ... | tr -d '\n\r'`): `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the token-exchange server's response, and the server is chosen by `inputs.exchange-url`. They are not literals computed in the script, and jq -r can return strings with newlines, which could inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because a single-line JWT regex validates it first.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list is no longer expanded unquoted. The value that xargs already tidied up is split on whitespace into a bash array with `read -r -d '' -a` (guarded for an empty value, `|| true` for errexit). The loop then runs over "${resources[@]}", using the ${arr[@]+...} form so it is safe under set -u. This splits on whitespace exactly as before but never globs. github-env-injection: expires_in and granted_scope now pass through `printf '%s' | tr -d '\n\r'` before being written to GITHUB_OUTPUT. The warning and notice messages still use the original values.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt step 3 of the login step in action.yml. The '# 3. Mask' comment is back on its own line. The token is masked again with '::add-mask::' and written to GITHUB_ENV as CARABINER_CREDENTIALS using printf. That is the variable name the README documents. The token was already checked against a single-line JWT regex earlier in the step. The safe_expires_in and safe_granted_scope assignments run again (tr -d '\n\r'), and only these sanitized values go to GITHUB_OUTPUT. The unsanitized expires-in and scope writes and the corrupted fragment are gone.

