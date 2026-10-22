<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values from the token-exchange response straight to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server is chosen by inputs.exchange-url (INPUTS_EXCHANGE_URL), so a caller-controlled URL or a hostile response can put newlines in `.scope` or `.expires_in` and inject extra step outputs. Only the access token is validated, with a single-line JWT regex, before it goes to GITHUB_ENV. Fix: run both values through tr -d '\n\r' before writing them.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. requested_resources comes from inputs.resource (INPUTS_RESOURCE) and is expanded without quotes. That is a word-splitting and glob-expansion risk. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. script-injection: the unquoted 'for res in ${requested_resources}' loop is replaced. The input is now split into an array with "read -r -d '' -a ... || true". That only runs when the value is not empty, and the loop uses the quoted array with a guard that is safe under set -u. It still splits on whitespace as upstream did, but no longer expands globs.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the broken block in action.yml's login step. The '# 3.' comment is back on its own line. Restored `echo "::add-mask::${token}"` and the `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"` line, which had been corrupted. The variable name comes from the README. The token already passes the single-line JWT regex check before this line. Moved the safe_expires_in assignment onto its own line. Deleted the unsanitized writes of expires_in and granted_scope to GITHUB_OUTPUT, so only the copies with newlines stripped (tr -d) are written. The notice message now uses safe_expires_in.

