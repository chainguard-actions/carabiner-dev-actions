<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data. The `requested_resources` variable comes from `INPUTS_RESOURCE` (${{ inputs.resource }}), and the loop expands it without quotes: `for res in ${requested_resources}; do`. The word splitting is deliberate, but glob characters in the input (`*`, `?`, `[...]`) will be expanded against the runner's working directory. That lets the caller turn the input into filenames or extra arguments for curl. Fix: split safely, e.g. `read -r -a resources <<< "$requested_resources"` with globbing turned off (`set -f`), then loop over `"${resources[@]}"`.

Locations:

- `action.yml:82`

### github-env-injection (severity: high)

The 'login' step writes values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization. The lines are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response (jq -r .expires_in / .scope) of a server at a URL the caller sets through inputs.exchange-url. They are not literals built inside the script, and jq -r can output embedded newlines. A hostile or compromised exchange server could therefore inject extra step outputs. (The GITHUB_ENV write of the token is fine, because it is checked against a single-line JWT regex first.) Fix: sanitize each value with `printf '%s' "$v" | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:146`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Both findings are fixed in action.yml. I haven't run the action to test the changes.

1. **script-injection:** the resource loop used to loop over the unquoted `${requested_resources}`, so a `*`, `?` or `[...]` in the input could be expanded into filenames from the working directory. The list is now split into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, which splits on whitespace like before but never expands globs. The loop then goes over `"${resources[@]}"`, written in a form that still works with an empty list under `set -u`. The split only runs when the input is non-empty. The `|| true` is needed because `read -d ''` returns 1 at the end of input, which `set -e` would otherwise treat as a failure.

2. **github-env-injection:** `expires_in` and `granted_scope` come from the exchange server's JSON reply. Each one now has newlines and carriage returns stripped with `printf '%s' ... | tr -d '\n\r'` before it is written to `$GITHUB_OUTPUT`. The command that reads each value is still a separate line from the cleanup, so a failure there still stops the step. The token write to `$GITHUB_ENV` was already checked against a single-line token pattern, so I left it alone.

