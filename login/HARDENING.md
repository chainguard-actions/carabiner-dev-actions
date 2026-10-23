<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data. `for res in ${requested_resources}; do` expands `requested_resources` without quotes. That variable comes from INPUTS_RESOURCE (${{ inputs.resource }}), so the shell splits the value on whitespace and also expands glob characters (*, ?, [) in it before passing it on. Read the value into an array with `read -ra resources <<< "$requested_resources"`, or turn off globbing with `set -f` first, so the loop only splits on whitespace as intended.

Locations:

- `action.yml:82`

### github-env-injection (severity: high)

`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write values from the token server's JSON response (via jq -r) without the required `printf '%s' ... | tr -d '\n\r'` step. The server is the one named by the caller-controlled `exchange-url` input, so a hostile or misbehaving server can return a scope or expires_in containing newlines and add extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is already safe because the token is checked against a single-line JWT pattern first. Fix: `granted_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, and do the same for `expires_in`, before writing them.

Locations:

- `action.yml:135`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource input was looped over unquoted, which also expanded glob characters. It is now read into an array with `read -r -d '' -a ... || true`, so it is split on whitespace only, as upstream intended. The `[ -n ]` guard means an empty input adds no resource arguments, which also avoids an unset-array error under `set -u` with bash 3.2. github-env-injection: expires_in and granted_scope now go through `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. The scope warning and the closing notice still show the original values. Nothing was run to test these edits.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the token, expires_in and granted_scope values now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_ENV and GITHUB_OUTPUT. These are plain variables with no command substitution nested inside, so errexit still works as before. Nothing else was changed.

