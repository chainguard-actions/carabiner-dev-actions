<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), an unquoted expansion of untrusted data. `requested_resources` comes from inputs.resource (env INPUTS_RESOURCE, normalized with xargs) and is expanded without quotes in `for res in ${requested_resources}; do`. The shell therefore splits the value on whitespace and also expands glob characters (*, ?, [...]) from the caller's input against the filesystem. Fix: split into an array without globbing, e.g. `read -r -a resources <<< "$requested_resources"` and then `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are taken with `jq -r` from the HTTP response of the token exchange server, and that server's address is the caller-controlled input `exchange-url`. They are not literals computed in the script, and nothing removes newlines before the write. A response with newlines in .scope or .expires_in could inject extra step outputs. Add the required sanitization first, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')` and `safe_expires=$(printf '%s' "$expires_in" | tr -d '\n\r')`, and write those values instead.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Resources are now split on whitespace into an array with `read -r -d '' -a` (behind an empty check, with `|| true`), so they are no longer glob-expanded. Upstream split them on whitespace too, so the result is the same. expires_in and granted_scope have \n and \r removed with tr before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the resource list is now split into an array with `read -r -a` (guarded for an empty value) and the loop runs over the quoted array elements, so glob characters are never expanded. Uses the ${arr[@]+...} form for set -u safety on older bash. Splitting still happens on whitespace, as upstream did (the value was already whitespace-collapsed by xargs).

