<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In the 'login' step, `granted_scope` and `expires_in` are written to $GITHUB_OUTPUT with `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the token exchange server, and that server's URL is the workflow-controlled `inputs.exchange-url` (INPUTS_EXCHANGE_URL). `jq -r` output can contain embedded newlines, so a hostile or spoofed exchange response could inject extra output lines. Neither value goes through `printf '%s' ... | tr -d '\n\r'` before the write. (The CARABINER_CREDENTIALS write to $GITHUB_ENV on line 136 is first checked against a strict single-line JWT regex, but the required sanitization pipeline is still missing there too.)

Locations:

- `action.yml:137`
- `action.yml:138`
- `action.yml:136`

### script-injection (severity: high)

Sub-rule (b), unquoted shell expansion of untrusted data: `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (INPUTS_RESOURCE, passed through xargs) and is expanded without quotes. The shell therefore applies word splitting and pathname/glob expansion to a value the workflow controls. A safer approach is to split explicitly with `read -ra arr <<< "$requested_resources"` and iterate over "${arr[@]}", or to turn off globbing with `set -f` before the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Sanitized token, expires_in and granted_scope with printf | tr -d '\n\r' before writing to GITHUB_ENV/GITHUB_OUTPUT. Replaced unquoted `for res in ${requested_resources}` with a guarded `read -r -d '' -a` whitespace split (no globbing) and quoted array iteration, set -u safe. Not run or tested.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt the broken end of the login step in action.yml. The ::warning:: echo now closes properly and reports the requested and granted scopes. The `if` has its `fi`. The token, expires_in and granted_scope are cleaned with tr -d '\n\r' into safe_* variables, and those are now the only values written to GITHUB_ENV and GITHUB_OUTPUT. I deleted the leftover unsanitized writes and added `::add-mask::` for the token before it is written. The original wording of the warning was lost in the broken edit, so I wrote a replacement message. The step's comment says the token is masked, and the mask line is harmless if upstream already masked it somewhere else.

