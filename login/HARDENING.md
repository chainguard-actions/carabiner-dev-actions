<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'login' step writes values parsed from the token-exchange HTTP response straight to $GITHUB_OUTPUT, with no printf '%s' ... | tr -d '\n\r' step first: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. The response comes from a server whose URL is set by inputs.exchange-url, and these values are not literals computed in the script. A response containing newlines can inject extra step outputs. The CARABINER_CREDENTIALS write to $GITHUB_ENV is not flagged because the value is first checked against a strict one-line JWT regex.

Locations:

- `action.yml:138`
- `action.yml:139`

### script-injection (severity: high)

Sub-rule (b): an env var holding input data is expanded without quotes. The 'login' step does `requested_resources="$(printf '%s' "${INPUTS_RESOURCE}" | xargs)"` and then `for res in ${requested_resources}; do`. Because ${requested_resources} comes from inputs.resource and is unquoted, the shell word-splits and glob-expands it, so glob characters in the input can expand to file names in the working directory. Fix: split safely with `read -ra arr <<< "$requested_resources"` and loop over "${arr[@]}".

Locations:

- `action.yml:77`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Removed newlines (tr -d '\n\r') from expires_in and granted_scope before they are written to $GITHUB_OUTPUT. The resource list was looped over unquoted, which also let the shell glob-expand it. It is now split on whitespace into an array with read -r -d '' -a (|| true, guarded by a non-empty check) and expanded with a set -u-safe idiom. It still splits on whitespace as before, but no longer expands globs.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope now have newlines and carriage returns removed with tr -d '\n\r' before they are written to GITHUB_OUTPUT. The variables are plain strings, so the tr pipeline cannot hide a command failure. The CARABINER_CREDENTIALS write was left as it was because the value is already checked as a single-line JWT.

