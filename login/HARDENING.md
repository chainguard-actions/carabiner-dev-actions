<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): an unquoted shell variable holds data from an input. `requested_resources` comes from inputs.resource (via INPUTS_RESOURCE and xargs) and is expanded unquoted in `for res in ${requested_resources}; do`. Because of this, glob characters in the input (*, ?, [..]) get expanded against the filesystem, and the value is split on whitespace without any control. A safer approach is to split explicitly, e.g. `read -r -a resources <<< "$requested_resources"`, run with globbing turned off (set -f), and then loop over `"${resources[@]}"`.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes to GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from the JSON response of the server named by inputs.exchange-url, so they are not literals computed inside the script. `jq -r` keeps any newlines embedded in a string, so a hostile or compromised exchange server could inject extra output lines. The CARABINER_CREDENTIALS write to GITHUB_ENV is checked first against a single-line JWT regex, but the two GITHUB_OUTPUT writes have no such check.

Locations:

- `action.yml:136`
- `action.yml:137`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

I changed action.yml in two places and haven't tested either change. (1) The `resource` input is now split on whitespace into a `resources` array with `read -r -d '' -a ... || true`. The split only runs when the value isn't empty, and the loop goes over `${resources[@]+"${resources[@]}"}`. This drops the unquoted `${requested_resources}`, so wildcard characters like `*` or `?` in the input are no longer matched against filenames. The `+` form keeps an empty array from failing under `set -u` on older bash. (2) The `expires_in` and `granted_scope` values from the exchange server now go through `printf '%s' | tr -d '\n\r'` before being written to GITHUB_OUTPUT, and the writes use printf. Each value is captured first and then cleaned in a separate step, so a failing command still stops the script.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, the unquoted `for res in ${requested_resources}` loop has been replaced. The value is now read into an array with `read -r -d '' -a resources <<< ...` (guarded by an empty check and `|| true` for set -e), and the loop iterates over the quoted array using a nounset-safe form. This keeps upstream's whitespace splitting but no longer expands glob characters.

