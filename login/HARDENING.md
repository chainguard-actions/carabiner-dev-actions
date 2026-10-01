<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.3** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The run: step writes values derived from an external HTTP response (the token exchange server) to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

1. `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"` — Although `token` is validated against a JWT regex before the write, the canonical `tr -d '\n\r'` sanitization is not applied. The regex guard is domain-specific and does not satisfy the required sanitization pattern.

2. `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` — `expires_in` is parsed from the server JSON response via `jq` with no sanitization; a hostile exchange server could embed newlines to inject additional output variables.

3. `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` — `granted_scope` is similarly parsed from the server JSON response via `jq` with no sanitization; a hostile server could inject additional output variables via embedded newlines.

All three writes should be preceded by: `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` before writing to the special environment files.

Locations:

- `action.yml:131`
- `action.yml:132`
- `action.yml:133`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in hardened/action/action.yml (lines 131-133). Before writing to $GITHUB_ENV and $GITHUB_OUTPUT, each value is now sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` to strip embedded newlines and carriage returns: (1) `safe_token` sanitizes the JWT token before writing CARABINER_CREDENTIALS to $GITHUB_ENV; (2) `safe_expires_in` sanitizes the expires_in value before writing to $GITHUB_OUTPUT; (3) `safe_granted_scope` sanitizes the granted_scope value before writing to $GITHUB_OUTPUT. The original `${expires_in:-unknown}` reference in the notice message is preserved as-is since it's not written to a special environment file.

