<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without running them through `printf '%s' ... | tr -d '\n\r'` first: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both come from `jq -r` on the token-exchange response. The calling workflow picks the server through `inputs.exchange-url`, so these values are not literals computed in the script, and `jq -r` keeps embedded newlines. A hostile or compromised server can therefore inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because a single-line JWT regex checks it first. These two values get no such check.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b) is violated: input-derived data is expanded without quotes. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE | xargs) and is expanded unquoted in `for res in ${requested_resources}; do`. Word splitting is intended here, but the unquoted expansion also applies glob expansion to attacker-controlled data. For example, a resource value of `*` would expand to file names in the working directory. Use a quoted array split instead, e.g. `read -r -a res_list <<< "$requested_resources"; for res in "${res_list[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

1) github-env-injection: before expires_in and granted_scope are written to GITHUB_OUTPUT, both now go through printf '%s' | tr -d '\n\r' to strip newlines. 2) script-injection: the unquoted `for res in ${requested_resources}` loop is replaced. The resource list is now read into an array with `read -r -d '' -a ... || true`, guarded so an empty input is skipped. The array is expanded with a set -u-safe ${arr[@]+"${arr[@]}"} pattern. It still splits on whitespace like before, but no longer expands globs.

