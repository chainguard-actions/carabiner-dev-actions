<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. The variable `requested_resources` comes from the `inputs.resource` input (INPUTS_RESOURCE run through xargs). It is expanded without quotes in `for res in ${requested_resources}; do`. `set -f` is never set, so the shell splits the value on whitespace and also expands glob characters in it (`*`, `?`, `[...]`) against the filesystem. To fix this, split safely with `read -ra resources <<< "$requested_resources"` and loop over `"${resources[@]}"`, or turn off globbing (`set -f`) around the loop.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`). Both values come from the JSON response of the token exchange server, and that server is the one named by the caller-supplied `inputs.exchange-url`. So they are not literals computed in the script. A hostile or compromised server can put a newline in `.scope` or `.expires_in`; `jq -r` outputs it as a real line break, which adds extra output entries. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, but these two GITHUB_OUTPUT writes have no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

I fixed both findings in action.yml. Nothing was run or tested.

**script-injection:** The resource list was split by an unquoted `for res in ${requested_resources}`, which also expanded glob characters like `*` against the filesystem. It now splits into a `resources` array with `read -r -d '' -a resources <<< "$requested_resources" || true`, only when the value isn't empty, and loops over the quoted array. `${resources[@]+"${resources[@]}"}` keeps an empty list from failing under `set -u` on the older bash on macOS runners. It still splits on whitespace like before, but no longer globs.

**github-env-injection:** `expires_in` and `granted_scope` come back from the exchange server. Both now go through `printf '%s' ... | tr -d '\n\r'` before being written to `$GITHUB_OUTPUT`, so a newline in the server's reply can't add extra output entries.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. Each value is cleaned in its own variable, using plain variables only with no command substitution inside another command. Nothing else in the action changed.

