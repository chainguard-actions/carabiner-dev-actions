<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes values to $GITHUB_OUTPUT without first running `printf '%s' ... | tr -d '\n\r'` on them: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values are parsed with `jq -r` from the token-exchange response. The server URL is the caller-controlled input `exchange-url`, so these values are not literals computed inside the script. A JSON string with embedded newlines would inject extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is guarded by a single-line JWT regex, but these two output writes have no guard.

Locations:

- `action.yml:137`
- `action.yml:138`

### script-injection (severity: high)

Rule (b), unquoted expansion of untrusted data. In step 'login', the line `for res in ${requested_resources}; do` expands `requested_resources` without quotes. That variable comes from `inputs.resource` (via INPUTS_RESOURCE | xargs). Leaving it unquoted means the shell applies glob/pathname expansion to values chosen by the caller. A safer form is `read -ra arr <<< "$requested_resources"` followed by iterating over `"${arr[@]}"`, or running `set -f` before the loop.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Both findings are fixed in action.yml, in the 'login' step. I didn't run the action after the edits.

- github-env-injection: before `expires_in` and `granted_scope` are written to $GITHUB_OUTPUT, each now goes through `printf '%s' ... | tr -d '\n\r'`. A response from the exchange server can no longer add extra output lines.
- script-injection: the resource loop no longer expands `requested_resources` unquoted. The list is read into an array with `read -r -d '' -a ... || true`, guarded so an empty value adds no arguments. The loop then goes over `${resource_list[@]+"${resource_list[@]}"}`, which keeps `set -u` happy on older bash when the array is empty. It still splits on whitespace as before, but there's no more glob expansion of values the caller passes in.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the 'login' step now removes CR and LF from three values before writing them out: the token, expires_in and granted_scope (each through printf '%s' | tr -d '\n\r'). The token goes to GITHUB_ENV, the other two to GITHUB_OUTPUT. The token was already checked against a single-line JWT pattern; that check is unchanged. Each tr runs in its own assignment, so with pipefail a failure still stops the step. Nothing else in the step was changed, and no tests were run.

