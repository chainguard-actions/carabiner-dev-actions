<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step writes values to $GITHUB_OUTPUT without the required printf '%s' ... | tr -d '\n\r' sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are read by jq -r from the token-exchange response. The server is reached at inputs.exchange-url, so the caller controls which server answers. A JSON string with an embedded newline in .expires_in or .scope can inject extra output lines. (The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because the token is first checked against a single-line JWT regex.)

Locations:

- `action.yml:159`
- `action.yml:160`

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do` expands requested_resources without quotes. That variable comes from INPUTS_RESOURCE (inputs.resource), so the shell splits the value on whitespace and also expands glob characters in it. Fix: split the value safely, e.g. `read -r -a resources <<< "$requested_resources"` with `set -f`, then loop over "${resources[@]}".

Locations:

- `action.yml:82`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run to test the changes.

- **github-env-injection:** `expires_in` and `granted_scope` come from the exchange server's response. Newlines and carriage returns are now stripped with `printf '%s' ... | tr -d '\n\r'` before either value is written to $GITHUB_OUTPUT. A hostile server can no longer add extra output lines.
- **script-injection:** The unquoted `for res in ${requested_resources}` loop is gone. The value is split into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, only when it is non-empty, and the loop walks `${resources[@]+"${resources[@]}"}`. That form still works under `set -u` on macOS's older bash (3.2). It splits on whitespace as before but no longer expands glob characters. Upstream's `xargs` cleanup step is left as it was, so each resource URI is still sent as its own `resource=` parameter.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Repaired step 3 of the login script in action.yml. The comment line '# 3. Mask the token and export it for later steps.' is restored, and the safe_* assignments are back on their own lines. The token is now passed through tr -d '\n\r', masked, and written as CARABINER_CREDENTIALS to GITHUB_ENV (the variable name comes from the README). The unsanitized expires-in and scope writes to GITHUB_OUTPUT are removed, so only the sanitized versions remain. The notice message also uses the sanitized expires-in value now.

