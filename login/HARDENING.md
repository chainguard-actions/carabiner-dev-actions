<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without first running them through `printf '%s' ... | tr -d '\n\r'`. Lines: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the token-exchange response, and the exchange server is set by `inputs.exchange-url`. A hostile or misconfigured server can return a value containing newlines and inject extra output entries. The access token written to $GITHUB_ENV is safe because a single-line JWT regex checks it first, but these two outputs have no such check.

Locations:

- `action.yml:141`
- `action.yml:142`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. In the 'login' step, `for res in ${requested_resources}; do` expands `requested_resources` without quotes. The value comes from `inputs.resource` via the env var INPUTS_RESOURCE. Because it is unquoted, the shell splits it on spaces and also expands glob characters in the input. Split the string safely instead, for example `read -ra resources <<< "$requested_resources"` followed by iterating over `"${resources[@]}"`.

Locations:

- `action.yml:75`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

I fixed both findings in action.yml, in the 'login' step. I haven't run the action to test these changes.

1. **github-env-injection:** `expires_in` and `granted_scope` now have newlines and carriage returns stripped (`printf '%s' ... | tr -d '\n\r'`) before they are written to $GITHUB_OUTPUT. A hostile exchange server can no longer add extra output entries.

2. **script-injection:** the unquoted `for res in ${requested_resources}` loop is gone. The resource list is now split on whitespace into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`. That runs only when the value is non-empty, and the loop goes over `${resources[@]+"${resources[@]}"}`. Glob characters in the input stay literal text. Splitting on whitespace is how upstream split this input, so each resource still becomes its own `resource=` parameter. The `${arr[@]+...}` form is there because the step uses `set -u`, and an empty array would otherwise stop the step on older bash such as the 3.2 on macOS runners.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the loop `for res in ${requested_resources}` used to expand the string unquoted. It now splits the string into an array with `read -r -d '' -a resources <<< "$requested_resources" || true` (only when the string isn't empty), then loops over the quoted array. Words are still split on whitespace as before, but `*` and `?` in the resource input no longer match files in the workspace. The `${resources[@]+...}` form keeps an empty list working under `set -u`, including on bash 3.2. I didn't add `set -f` because nothing expands unquoted any more. Not tested here; I only edited the file.

