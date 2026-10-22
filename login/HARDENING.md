<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data. `requested_resources` comes from the workflow-controlled input `inputs.resource` (through INPUTS_RESOURCE and xargs). It is expanded without quotes: `for res in ${requested_resources}; do`. The splitting on spaces is intended, but the unquoted expansion also lets the shell expand glob characters in the input. A safer form is `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do` (consider `set -f` too).

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without running them through `printf '%s' ... | tr -d '\n\r'` first: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the reply of a server at the input-controlled URL `inputs.exchange-url`, and the granted scope may echo the input `inputs.scope`. jq -r can print embedded newlines, which would inject extra output entries. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex first, so it is not affected.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the loop no longer expands the resource list unquoted (`for res in ${requested_resources}`), so glob characters in the input can't expand to file names. The list is now read into an array with `read -r -d '' -a` behind a non-empty check, and the loop uses the quoted array. It still splits on whitespace as before. The `${arr[@]+...}` form keeps empty arrays safe under `set -u` and works on bash 3.2.
github-env-injection: `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. The CARABINER_CREDENTIALS write was already checked against a JWT regex, so I left it alone.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope are now passed through printf '%s' | tr -d '\n\r' (stored as safe_expires_in and safe_scope) before being written to $GITHUB_OUTPUT. The CARABINER_CREDENTIALS write to GITHUB_ENV is unchanged because a JWT regex already checks it.

