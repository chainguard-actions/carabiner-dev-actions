<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the 'login' step, `expires_in` and `granted_scope` are written straight to $GITHUB_OUTPUT with no `printf '%s' ... | tr -d '\n\r'` cleanup: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are parsed with jq -r from the JSON returned by the token exchange server, and the calling workflow picks that server through inputs.exchange-url. A hostile response can put embedded newlines in these strings and inject extra or overriding step outputs. The access token gets a single-line regex check before it is written to GITHUB_ENV, but these two values get no check at all. Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b) is violated: input-derived data is expanded without quotes. In `for res in ${requested_resources}; do`, `requested_resources` comes from inputs.resource (via the INPUTS_RESOURCE env var) and is expanded unquoted. Word splitting is intended here, but the unquoted expansion also triggers pathname globbing on attacker-controlled input such as `*` or `?`, so filenames from the workspace can end up as resource parameters. Fix: split safely into an array with `read -ra resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml. Nothing was run to test the changes.

- **github-env-injection:** `expires_in` and `granted_scope` are now passed through `printf '%s' ... | tr -d '\n\r'` before they are written to $GITHUB_OUTPUT. A hostile token-exchange response can no longer add or override step outputs with embedded newlines.
- **script-injection:** the resource list is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, guarded by a check for an empty value. The loop runs over `${resources[@]+"${resources[@]}"}`. This still splits on whitespace as upstream did, but stops values like `*` or `?` from expanding to workspace filenames. The `${arr[@]+...}` form keeps an empty list working under `set -u` on bash older than 4.4 (macOS runners ship 3.2). The `|| true` stops `set -e` from failing the step when `read` reaches the end of input.

