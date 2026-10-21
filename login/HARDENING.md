<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. `requested_resources` comes straight from the `resource` input (INPUTS_RESOURCE, via `printf | xargs`). It is expanded without quotes in `for res in ${requested_resources}; do`. Because it isn't quoted, the shell splits it on whitespace and also expands glob characters from the input value against files in the working directory. Fix: split it safely, e.g. `read -r -a resources <<< "$requested_resources"`, then loop with `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes values that are not literals to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the server named by the `exchange-url` input, read with `jq -r`, which can return text containing newlines. A hostile or spoofed exchange server could therefore inject extra step outputs.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list was looped over unquoted, which also expanded glob characters. It is now read into an array with `read -r -d '' -a` (only when it is non-empty, and with `|| true`), then looped over quoted, with a guard for an empty array under `set -u`. It still splits on whitespace as before, but glob characters are no longer expanded. github-env-injection: the expires_in and granted_scope values from the exchange server's response now have newlines and carriage returns removed with `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the merged lines in step 'login' of action.yml. Restored the line '# 3. Mask the token and export it for later steps.', followed by echo ::add-mask:: for the token and printf 'CARABINER_CREDENTIALS=%s\n' to GITHUB_ENV (the variable name comes from the README). The safe_expires_in and safe_granted_scope assignments, which strip newlines with tr -d, now run as their own lines. Removed the raw writes of expires-in and scope to GITHUB_OUTPUT. The notice message now uses the sanitized expires-in value too.

