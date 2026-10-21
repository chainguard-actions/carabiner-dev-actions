<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The step 'login' writes two values to $GITHUB_OUTPUT without the required sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the token-exchange server, and the caller chooses that server through inputs.exchange-url. `jq -r` can return strings that contain newlines, so a hostile or compromised server could add extra output lines. Before each write, pass the value through `printf '%s' "$VAR" | tr -d '\n\r'`. The CARABINER_CREDENTIALS write to $GITHUB_ENV is already limited by a single-line JWT regex check, but the two output writes have no such check.

Locations:

- `action.yml:154`
- `action.yml:155`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of untrusted data: `for res in ${requested_resources}; do`. requested_resources comes from INPUTS_RESOURCE, which is set from inputs.resource. Because the expansion is unquoted, the shell splits the value into words and also expands glob characters such as `*` and `?` against the working directory. That lets a caller-supplied value change what gets sent as resource parameters. Split the value safely instead, for example `read -r -a resources <<< "$requested_resources"`, run `set -f` first, then use `for res in "${resources[@]}"`.

Locations:

- `action.yml:80`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed both findings in action.yml.
- github-env-injection: before `expires_in` and `granted_scope` are written to $GITHUB_OUTPUT, each now goes through `printf '%s' | tr -d '\n\r'` to remove newlines. These values come from the exchange server's JSON response.
- script-injection: the unquoted `for res in ${requested_resources}` loop is gone. The resource list is now split into a bash array with `read -r -d '' -a ... || true`, and the loop runs over the quoted array. The read only happens when the list is non-empty, and the `${arr[@]+...}` form avoids an unset-variable error under `set -u` when the array is empty. Splitting is still on whitespace, as before, but `*` and `?` are no longer matched against files in the working directory.

Nothing was run to test the changes.

