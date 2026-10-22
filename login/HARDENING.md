<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the token exchange server, and the caller picks that server through the `exchange-url` input. They are written without the `printf '%s' ... | tr -d '\n\r'` sanitization step. A hostile or compromised exchange server could put newlines in `.scope` or `.expires_in` and add extra step outputs. The access token itself is checked against a single-line JWT regex, but these two values are not. Fix: sanitize each one before writing it, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`.

Locations:

- `action.yml:149`
- `action.yml:150`

### script-injection (severity: high)

Rule (b): an unquoted shell expansion of workflow-controlled data. The line `for res in ${requested_resources}; do` expands `requested_resources`, which comes from `inputs.resource` (via INPUTS_RESOURCE), without quotes. The shell splits it into words and also expands glob characters such as `*`, `?` and `[`, so a crafted input value can turn into unexpected arguments. Fix: split the value safely with `read -r -a resources <<< "$requested_resources"`, run `set -f` first, and loop over `"${resources[@]}"`.

Locations:

- `action.yml:81`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Before writing expires-in and scope to GITHUB_OUTPUT, newlines are now stripped from both values with printf | tr -d '\n\r'. The unquoted loop `for res in ${requested_resources}` is gone. requested_resources is now split into a bash array with a guarded `read -r -d '' -a ... || true`. That still splits on whitespace like before, but no longer expands glob characters. The loop then runs over the quoted array, written so it stays safe under set -u when the array is empty. Behaviour is otherwise unchanged. The edits were not run or tested.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the expires_in and granted_scope values from the server's JSON response now have newlines and carriage returns stripped (printf '%s' ... | tr -d '\n\r') right before they are written to $GITHUB_OUTPUT. The original variables are unchanged, so the scope-narrowing warning and the notice behave as upstream. The CARABINER_CREDENTIALS write was already safe because the token is checked against a single-line JWT pattern.

