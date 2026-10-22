<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the 'login' step, `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write values parsed with `jq -r` from the token-exchange response. The server is picked by the untrusted input `inputs.exchange-url`. Nothing removes newlines first (`printf '%s' ... | tr -d '\n\r'`). A hostile or compromised exchange server can put newlines in `.scope` or `.expires_in` and add extra step outputs. Unlike the GITHUB_ENV write of the token, these values are not checked against a regex.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data. In the 'login' step, `for res in ${requested_resources}; do` expands `requested_resources` without quotes. That variable comes from `INPUTS_RESOURCE` (`inputs.resource`). The shell splits the value on whitespace and expands glob characters in it. A safer approach is to split it explicitly, e.g. `read -ra resources <<< "$requested_resources"`, then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both fixes are in action.yml, in the 'login' step. I haven't run the action to test them.

1. **Resource list (script-injection):** the loop no longer expands `requested_resources` unquoted. The value is now split into an array with `read -r -d '' -a ... || true`, skipped when the value is empty. The loop then goes over the array using the same `${arr[@]+"${arr[@]}"}` form the step already uses for `scope_args`. That form keeps working under `set -u` when the array is empty. The value is still split on whitespace as before, but glob characters are no longer expanded.

2. **Step outputs (github-env-injection):** newlines and carriage returns are now stripped from `expires_in` and `granted_scope` (`printf '%s' | tr -d '\n\r'`) right before they are written to `$GITHUB_OUTPUT`. The values captured from `jq` are unchanged. That means the scope-narrowing warning still compares the raw value, and the final notice still prints the raw `expires_in`.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt step 3 of the login script in action.yml: the token is masked with ::add-mask:: and written with printf 'CARABINER_CREDENTIALS=%s\n' to GITHUB_ENV (it is already checked against a single-line JWT regex). safe_expires_in and safe_granted_scope are each set on their own line with tr -d '\n\r'. The two old writes that skipped sanitizing were removed, and the notice message now uses safe_expires_in.

