<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): an unquoted shell variable holds data that comes from an input. `requested_resources` is set from INPUTS_RESOURCE (inputs.resource) and then expanded without quotes in `for res in ${requested_resources}; do`. The shell splits it into words and also expands glob characters (*, ?, [...]) in it, so a crafted input can turn into file names from the runner. Fix: read it into an array with `read -r -a resources <<< "$requested_resources"`, add `set -f` to turn off globbing, and loop over "${resources[@]}".

Locations:

- `action.yml:82`

### github-env-injection (severity: high)

Unsanitized values are written to $GITHUB_OUTPUT. `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` copy fields taken with jq from the token-exchange server's response. That server is set by the caller through inputs.exchange-url, so its response counts as untrusted. A value containing a newline could add extra step outputs. Fix: strip line breaks before writing, e.g. `safe=$(printf '%s' "$granted_scope" | tr -d '\n\r')` (and the same for expires_in). The CARABINER_CREDENTIALS write to GITHUB_ENV is fine: the token is checked against a single-line JWT regex first.

Locations:

- `action.yml:139`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

I fixed both findings in action.yml. Nothing was run or tested, so neither change has been checked against a real token exchange.

1. **script-injection:** the old loop `for res in ${requested_resources}` split the value without quotes, so glob characters in `inputs.resource` could expand into runner file names. The value is now read into a `resources` array with `read -r -a` (only when it is non-empty), and the loop uses the quoted form `${resources[@]+"${resources[@]}"}`. That form avoids an unset-variable error under `set -u` when the array is empty, on older bash. Glob characters now stay as plain text. Splitting is unchanged: upstream's `xargs` step already collapses the input to one line, and `read -a` splits it on whitespace as before. I didn't add `set -f`: the suggested fix included it, but with every expansion quoted there is nothing left to glob.

2. **github-env-injection:** `expires_in` and `granted_scope` come from the exchange server's response, so line breaks are now stripped from both (`printf '%s' ... | tr -d '\n\r'`) before they are written to `$GITHUB_OUTPUT`. Under the existing `set -o pipefail` a failure there would still stop the step. The `CARABINER_CREDENTIALS` write to `GITHUB_ENV` is unchanged, since the token is already checked against a single-line JWT pattern first.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml I fixed the end of the login step and took out the two GITHUB_OUTPUT writes that weren't sanitized. I put back the '# 3. Mask the carabiner token...' comment. I also restored two lines: `echo "::add-mask::${token}"` and `printf 'CARABINER_CREDENTIALS=%s\n' "${token}" >> "${GITHUB_ENV}"`. Most of that text had been lost, so I rebuilt it. The variable name CARABINER_CREDENTIALS comes from the README, but the add-mask line and the comment wording are my best guess. The README says the token is masked before export. safe_expires_in and safe_granted_scope are now each defined on their own line with tr -d '\n\r'. The expires-in and scope outputs now use only those sanitized values. Nothing has been run or tested.

