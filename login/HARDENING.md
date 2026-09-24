<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/d41fe10fe88deaf493ce026007da73738b9f570c

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/d41fe10fe88deaf493ce026007da73738b9f570c** was hardened automatically. 1 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: The shell variable `${requested_resources}` — derived from `inputs.resource` via the `INPUTS_RESOURCE` env var — is expanded **unquoted** in a `for` loop: `for res in ${requested_resources}; do`. Because the value is not double-quoted, the shell performs word-splitting AND glob expansion on it, and any shell metacharacters (`;`, `|`, `&`, `$(...)`, backticks, etc.) embedded in the input are interpreted by the shell before the loop iterates. An attacker-controlled `inputs.resource` value could inject arbitrary shell commands. The fix is to either quote the expansion (`"${requested_resources}"`) or use a safer splitting mechanism such as `read -ra` with a controlled delimiter.

Locations:

- `action.yml:64`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted `${requested_resources}` expansion in the `for` loop at line 64 of action.yml. Replaced the unsafe `for res in ${requested_resources}; do` pattern with a safe xargs-based NUL-delimited tokenization: `printf '%s' "${INPUTS_RESOURCE}" | xargs printf '%s\0'` piped into a `while IFS= read -r -d '' res` loop. This uses xargs's quote-aware tokenization to split the space-separated resource URIs without allowing shell metacharacters (`;`, `|`, `&&`, `$(...)`, etc.) to be interpreted. The intermediate `requested_resources` variable was eliminated entirely, and an `if [ -n "${INPUTS_RESOURCE}" ]` guard prevents xargs from emitting an empty token when the input is empty.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed two writes to $GITHUB_OUTPUT in the `login` step that used unsanitized values derived from a remote server's JSON response. Added sanitization for both `expires_in` and `granted_scope` values using `printf '%s' "${value}" | tr -d '\n\r'` before writing them to GITHUB_OUTPUT. This prevents a hostile or compromised exchange server from injecting additional key=value pairs by returning multi-line values in those JSON fields.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Added the required sanitization step before writing the token to $GITHUB_ENV. The line `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"` was updated to first sanitize the token: `safe_token=$(printf '%s' "${token}" | tr -d '\n\r')` followed by `printf 'CARABINER_CREDENTIALS=%s\n' "${safe_token}" >> "${GITHUB_ENV}"`. This matches the same pattern already used for `safe_expires` and `safe_scope` written to $GITHUB_OUTPUT, and satisfies the prescribed sanitization requirement even though the JWT regex check provides defense-in-depth.

