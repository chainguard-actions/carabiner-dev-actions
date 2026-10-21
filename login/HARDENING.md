<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the 'login' step, `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` write values taken from the token-exchange server's JSON response (`jq -r '.expires_in'` / `jq -r '.scope'`). The caller picks that server through `inputs.exchange-url` (INPUTS_EXCHANGE_URL), so these values count as untrusted. `jq -r` can return strings that contain newlines, which would let a hostile server add extra step outputs. Only the token written to GITHUB_ENV is checked against the JWT regex. These two values get no `printf '%s' ... | tr -d '\n\r'` cleanup before the write.

Locations:

- `action.yml:150`
- `action.yml:151`

### script-injection (severity: high)

Sub-rule (b): an unquoted shell variable holds input-derived data. `for res in ${requested_resources}; do` expands `requested_resources`, which comes from `inputs.resource` (INPUTS_RESOURCE), without quotes. The shell therefore applies glob expansion as well as word splitting, so a value like `*` or `/etc/*` expands to file paths. Those paths are then sent to the exchange server as resource parameters. A safer pattern is `read -ra resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`, or running `set -f` first.

Locations:

- `action.yml:82`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Resource list is now read into a bash array with `read -r -d '' -a` (behind an emptiness guard and `|| true`) and looped as a quoted array. Values still split on whitespace as upstream did, but glob characters no longer expand. The array expansion is written `${arr[@]+...}` so it works under `set -u` on bash 3.2. The expires_in and granted scope values are cleaned with `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the broken output and env section of action.yml. 1) Put the '# 3. Mask' comment and the safe_expires_in assignment back on separate lines. 2) Restored 'echo ::add-mask::${token}' and a valid printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> $GITHUB_ENV (the name comes from the README). 3) Removed the unsanitized echo writes of expires-in and scope, so only the printf writes of the newline-stripped values remain. 4) The notice line now uses safe_expires_in.

