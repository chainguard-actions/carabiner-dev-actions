<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step writes values to $GITHUB_OUTPUT without first running `printf '%s' ... | tr -d '\n\r'` on them: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the token-exchange server's JSON response via `jq -r`. That server is picked by the caller through `inputs.exchange-url`, so the values are workflow-controlled. A JSON string containing newlines could inject extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is regex-checked as a single-line JWT first, but expires_in and granted_scope get no check at all.

Locations:

- `action.yml:157`
- `action.yml:158`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE and xargs) and is expanded without double quotes. The shell therefore applies word splitting and glob expansion to a value the workflow controls. A safer form is to read the value into an array with `read -ra` and loop over the quoted array, which still splits on spaces but does not expand globs.

Locations:

- `action.yml:86`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Two fixes in action.yml. (1) expires_in and granted_scope now go through `printf '%s' ... | tr -d '\n\r'` before they are written to $GITHUB_OUTPUT. (2) The unquoted `for res in ${requested_resources}` loop is replaced. When the value is not empty, `read -r -d '' -a resource_list <<< ... || true` reads it into an array, and the loop goes over the quoted array. It still splits on whitespace as before, but no longer expands globs. The emptiness check also avoids an unbound-variable error on an empty array under `set -u` in older bash.

