<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: the shell variable `${requested_resources}` — derived from `inputs.resource` (via the `INPUTS_RESOURCE` env var, which is set to `${{ inputs.resource }}`) — is expanded **unquoted** in a `for` loop: `for res in ${requested_resources}; do`. An attacker-controlled value for `inputs.resource` can contain shell glob characters (`*`, `?`, `[...]`) that the shell will expand before the loop iterates, potentially matching files on the runner filesystem and causing unexpected behaviour. The value should be double-quoted or the loop should use a safer splitting mechanism (e.g. `read -ra` from a here-string).

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted variable expansion in the `for res in ${requested_resources}; do` loop at action.yml line 76. Replaced it with a safe xargs-based NUL-delimited tokenization pattern: `if [ -n "${requested_resources}" ]; then while IFS= read -r -d '' res; do resource_args+=(--data-urlencode "resource=${res}"); done < <(printf '%s' "${requested_resources}" | xargs printf '%s\0'); fi`. This prevents glob expansion and word-splitting of attacker-controlled `inputs.resource` values while correctly handling space-separated URI lists with quoted substrings.

