<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes two values from the token-exchange response straight to $GITHUB_OUTPUT without the printf '%s' ... | tr -d '\n\r' sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the body returned by `${INPUTS_EXCHANGE_URL}`, and that URL is the caller-controlled input `inputs.exchange-url`. A hostile or compromised server could return a scope or expires_in containing newlines and inject extra step outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is safe because it is checked against a JWT regex first; these two output writes are not checked at all.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data, in step 'login': `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE | xargs), and it is expanded without quotes, so the shell splits it on whitespace and expands glob characters in the caller-supplied value. Split it safely instead, e.g. `read -r -a resources <<< "$requested_resources"` and then `for res in "${resources[@]}"`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed both findings in action.yml. I haven't run the action to check the changes.

1. **github-env-injection:** `expires_in` and `granted_scope` now go through `printf '%s' | tr -d '\n\r'` before they are written to `$GITHUB_OUTPUT`. A response from the exchange server can no longer add extra step outputs. Both values come from `jq -r` on fields that should hold a single line, so stripping newlines shouldn't change normal output.

2. **script-injection:** The resource list used to be expanded unquoted in a `for` loop. It is now split into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, wrapped in a non-empty check, and the loop runs over the quoted array. The array expansion form also works with `set -u` on older bash versions. The `| xargs` normalization from upstream is unchanged, so the resources are split the same way as before, except that glob characters are no longer expanded.

