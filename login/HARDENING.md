<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b) in the 'Carabiner Login' step. The variable requested_resources comes from inputs.resource (via INPUTS_RESOURCE, normalized with xargs), and it is expanded without double quotes: `for res in ${requested_resources}; do`. Leaving it unquoted means the shell splits the value into words and also expands any glob characters (*, ?, [...]) in the caller-supplied input. Fix: split it into an array without globbing, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

In the 'Carabiner Login' step, expires_in and granted_scope are pulled with jq from the token exchange response and written to $GITHUB_OUTPUT with no newline sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server URL comes from the caller-controlled input exchange-url, and jq -r can emit embedded newlines, so these values can inject extra outputs. The access token written to GITHUB_ENV is checked against a single-line JWT regex first, but these two values are not. Fix: before each write, run the value through `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` and write $safe instead.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Both findings are fixed in action.yml. I haven't run the action or the analysis again after the changes.

1. **script-injection:** The resource list was looped over unquoted (`for res in ${requested_resources}`), so a `*` or `?` in the input could expand to file names. The value is now split into an array with `read -r -a resources <<< "$requested_resources" || true`, and the loop runs over `"${resources[@]}"`. It still splits on whitespace as before, but no longer globs. The split only runs when the value is non-empty, because the script uses `set -u`, which can fail on an empty array in older bash.

2. **github-env-injection:** Newlines and carriage returns are now stripped from `expires_in` and `granted_scope` with `tr -d '\n\r'` before they are written to GITHUB_OUTPUT. Since both come from the exchange server's response, a server could otherwise slip extra output lines in. The access token check (it must be a single-line JWT before going to GITHUB_ENV) is unchanged.

