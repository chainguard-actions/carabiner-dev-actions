<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step writes values from the server response to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the reply from the server at the workflow-controlled input `exchange-url`. That server's reply is untrusted, and a JSON string can contain newlines, so a crafted reply could add extra step outputs. Fix: run each value through `printf '%s' "$v" | tr -d '\n\r'` before writing it. The CARABINER_CREDENTIALS write to GITHUB_ENV is already checked against a single-line JWT regex.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (through INPUTS_RESOURCE and xargs) and is expanded without quotes, so the shell applies glob expansion to the input value as well as splitting it on spaces. Fix: split it safely without globbing, e.g. `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do`, or use `set -f` around the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both fixes are in action.yml. I haven't run the action to test them.

- **github-env-injection:** `expires_in` and `granted_scope` now go through `printf '%s' ... | tr -d '\n\r'` before they are written to `$GITHUB_OUTPUT`. A crafted reply from the exchange server can no longer add extra step outputs.
- **script-injection:** `requested_resources` is now read into an array with `read -r -d '' -a resources ... || true`, with a guard for an empty value. The loop then goes over `${resources[@]+"${resources[@]}"}`. The input is still split on whitespace as before, but glob characters stay as literal text. The `${arr[@]+...}` form avoids the unbound-variable error that `set -u` gives for an empty array on older bash (such as the 3.2 on macOS runners).

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Repaired the broken step 3 in action.yml. Put back the token mask (`::add-mask::${token}`) and the `printf 'CARABINER_CREDENTIALS=%s\n'` write to GITHUB_ENV. The name matches the README, but the comment text was rewritten because the original was lost. Moved the safe_expires_in assignment back onto its own line and deleted the cut-off fragment and the unsanitized expires-in/scope writes. The notice message now uses the sanitized safe_expires_in. Not run or tested.

