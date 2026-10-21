<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): the shell expands a variable built from untrusted input without quotes. The line `for res in ${requested_resources}; do` uses requested_resources, which comes from INPUTS_RESOURCE (${{ inputs.resource }}). The shell splits the value on whitespace on purpose here, but it also expands glob characters in it (*, ?, [..]). That lets a caller-supplied value expand to filenames on the runner. Fix: split into an array with globbing off, e.g. `read -r -a resources <<< "$requested_resources"`, then loop over "${resources[@]}".

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step. The lines are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the token-exchange server's JSON response, read with `jq -r`. That server's URL is the caller-controlled input exchange-url. `jq -r` can return strings that contain newlines, so a hostile or compromised server could add extra outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV is not flagged: it is checked against a single-line JWT regex first. Fix: sanitize each value, e.g. `safe_scope=$(printf '%s' "$granted_scope" | tr -d '\n\r')`, before writing it.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

I fixed both findings in action.yml. Nothing has been run or tested.

1. script-injection: the `resource` input is no longer split by an unquoted `for res in ${requested_resources}`, which also expanded `*`, `?` and `[..]` into runner filenames. The value is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true`, which splits on whitespace without globbing. The loop then runs over `${resources[@]+"${resources[@]}"}`. That expansion form keeps an empty `resource` input from failing under `set -u` on older bash versions such as macOS's bash 3.2. The `read` only runs when the value isn't empty, and `|| true` is there because `read -d ''` returns 1 when it reaches the end of input. Each resource is still sent as its own `resource=` parameter, as before.

2. github-env-injection: `expires_in` and `granted_scope` come from the exchange server's JSON response. Each now goes through `printf '%s' ... | tr -d '\n\r'` before it is written to $GITHUB_OUTPUT, so a server can't add extra outputs by putting line breaks in either field. The unsanitized values are still used in the scope-narrowing warning and the final login notice, and those only go to the job log. I left the CARABINER_CREDENTIALS write to $GITHUB_ENV alone, because the existing single-line JWT check already covers it.

