<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. requested_resources comes from inputs.resource (INPUTS_RESOURCE piped through xargs) and is expanded without quotes. The shell therefore splits it into words and applies glob expansion to a value the caller controls. Fix: split it explicitly instead, e.g. `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"`, and add `set -f` to turn off globbing.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

Two values from the exchange server's JSON response are written to $GITHUB_OUTPUT without the `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The server URL comes from the caller-controlled input inputs.exchange-url, so the response counts as untrusted. Because `jq -r` can return values containing newlines, a hostile response could inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because it is checked against a single-line JWT regex first.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource list is now split with `read -r -d '' -a resources` into a bash array. It only runs when the value is non-empty, and `|| true` keeps it from failing the step. The loop then goes over the quoted array, so there is no globbing and the list is still split on whitespace as before. The array is expanded with the `${arr[@]+...}` form so `set -u` doesn't fail on an empty list. github-env-injection: expires_in and granted_scope now go through `printf '%s' | tr -d '\n\r'` before being written to GITHUB_OUTPUT. Untested; changes only checked by reading the file.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, newlines and carriage returns are now stripped from expires_in and granted_scope (printf '%s' | tr -d '\n\r') before they are written to GITHUB_OUTPUT. Nothing else changed.

