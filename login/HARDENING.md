<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT (`echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`). Neither value is passed through `printf '%s' ... | tr -d '\n\r'` first. Both come from the JSON response of the server at `inputs.exchange-url`, which the caller controls. `jq -r` can output newlines, so a hostile or compromised server could inject extra output entries. Only the CARABINER_CREDENTIALS write to GITHUB_ENV is checked against a single-line JWT regex.

Locations:

- `action.yml:149`
- `action.yml:150`

### script-injection (severity: high)

Sub-rule (b): an unquoted expansion of input-derived data in step 'login': `for res in ${requested_resources}; do`. `requested_resources` comes from `inputs.resource` (via INPUTS_RESOURCE | xargs) and is expanded without quotes. The shell therefore applies word splitting and glob expansion to the value. To split safely, use `read -ra arr <<< "$requested_resources"` and loop over `"${arr[@]}"`.

Locations:

- `action.yml:82`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

github-env-injection: before `expires_in` and `granted_scope` are written to $GITHUB_OUTPUT, each now goes through `printf '%s' | tr -d '\n\r'` and is stored in a separate safe_* variable. The ::notice:: message still shows the original expires_in value. script-injection: the unquoted `for res in ${requested_resources}` loop now builds an array with `read -r -d '' -a` (guarded for an empty value, with `|| true`) and loops over the quoted array. The `${arr[@]+...}` form is used so it works under `set -u` with the older bash 3.2 on macOS runners. Splitting still happens on whitespace, as before, but values are no longer glob-expanded. I edited the file only and haven't run the action or re-run the analysis to confirm.

