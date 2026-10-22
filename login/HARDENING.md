<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): `for res in ${requested_resources}; do` expands input-derived data without quotes. `requested_resources` comes from `inputs.resource` through INPUTS_RESOURCE, so the shell splits it on whitespace and expands glob characters in it (`set -f` is not set). Turn off globbing with `set -f`, or read the values into an array with `read -ra` and iterate over the quoted array (`"${arr[@]}"`).

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write values parsed with `jq -r` from the token-exchange response. The server's URL is set by the untrusted input `inputs.exchange-url`, so whoever controls that server can return strings containing newlines and inject extra step outputs. Neither value goes through `printf '%s' ... | tr -d '\n\r'` before the write. (The GITHUB_ENV write on line 136 is checked against a single-line JWT regex first.)

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the unquoted `for res in ${requested_resources}` loop now reads the values into an array (guarded with -n; uses `read -r -d '' -a ... || true` so that set -e passes and bash 3.2 works) and loops over the quoted array, so a value can no longer expand as a glob. Splitting still happens on whitespace, as before. github-env-injection: expires_in and granted_scope go through `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. Nothing was run to test these changes.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the unquoted `for res in ${requested_resources}` loop is replaced. The value is now split into an array with `read -r -a` (guarded for an empty value) and the loop runs over the quoted array. `read -a` doesn't expand globs, so `set -f` isn't needed. Splitting still happens on whitespace, as before. The `${arr[@]+...}` form is used so an empty array doesn't trip `set -u`.

