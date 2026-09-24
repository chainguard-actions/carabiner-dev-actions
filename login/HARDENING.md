<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/d41fe10fe88deaf493ce026007da73738b9f570c

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/d41fe10fe88deaf493ce026007da73738b9f570c** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The `run:` block in the composite action step writes values derived from external server responses to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). Specifically:
1. `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"` — `token` is validated against a JWT regex but not sanitized with `tr -d '\n\r'` before the write.
2. `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` — `expires_in` is derived from a server response via `jq` with no sanitization.
3. `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` — `granted_scope` is derived from a server response via `jq` with no sanitization.
A malicious token exchange server could return values containing newlines to inject additional environment variables or outputs.

Locations:

- `action.yml:139`
- `action.yml:140`
- `action.yml:141`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed three github-env-injection vulnerabilities in action.yml (lines 139-141). Added sanitization using `printf '%s' ... | tr -d '\n\r'` for all three values derived from external server responses before writing them to $GITHUB_ENV and $GITHUB_OUTPUT:
1. `safe_token` - sanitized version of `token` (already JWT-validated but now also stripped of newlines) written to GITHUB_ENV
2. `safe_expires_in` - sanitized version of `expires_in` (from jq/server response) written to GITHUB_OUTPUT
3. `safe_granted_scope` - sanitized version of `granted_scope` (from jq/server response) written to GITHUB_OUTPUT
The original `expires_in` variable is still used in the notice message (safe, not written to env/output files).

