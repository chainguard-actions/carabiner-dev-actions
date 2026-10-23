<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violated: an expansion of workflow-controlled data is unquoted. `requested_resources` comes from INPUTS_RESOURCE (${{ inputs.resource }}) via xargs and is expanded without quotes in `for res in ${requested_resources}; do`. Word-splitting appears to be intended, but the shell also performs glob/pathname expansion on the value, so input containing glob characters (e.g. `*`) is expanded against the filesystem. Safer: split with `read -r -a resources <<< "$requested_resources"` and loop over "${resources[@]}", or turn globbing off with `set -f`.

Locations:

- `action.yml:82`

### github-env-injection (severity: high)

The login step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`) without first applying `printf '%s' ... | tr -d '\n\r'`. Both values are taken with `jq -r` from the response of a server whose URL is the untrusted input `inputs.exchange-url`. A hostile or misconfigured server could return strings containing newlines and inject extra step outputs. (The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against an anchored single-line JWT regex first, so it is not flagged.)

Locations:

- `action.yml:141`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the xargs-normalized resource list is now split into an array with `read -r -d '' -a` (behind an empty-value guard and `|| true`), and the loop runs over the quoted array using a set -u-safe expansion. It still splits on whitespace as before, but glob characters are no longer expanded against the filesystem. github-env-injection: expires_in and granted_scope have \n and \r stripped with printf | tr before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the broken section 3 of the login step. Restored the token masking (::add-mask::) and the CARABINER_CREDENTIALS write to GITHUB_ENV, using the variable name from README.md. The token was already checked as a single-line JWT. safe_expires_in is now assigned on its own line. Removed the unsanitized expires-in/scope writes. Only the sanitized values (tr -d '\n\r') go to GITHUB_OUTPUT now.

