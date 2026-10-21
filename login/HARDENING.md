<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'login' in action.yml writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the token-exchange response. The server that sends that response is chosen by the caller through `inputs.exchange-url`, and `jq -r` can output strings that contain newlines. A malicious or compromised server could therefore inject extra outputs. The CARABINER_CREDENTIALS write to $GITHUB_ENV on line 136 is checked first against an anchored single-line JWT regex, so in practice it cannot inject anything. It still does not use the sanitization step this check requires.

Locations:

- `action.yml:137`
- `action.yml:138`
- `action.yml:136`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of workflow-controlled data. Step 'login' in action.yml runs `for res in ${requested_resources}; do`. `requested_resources` comes from `INPUTS_RESOURCE` (`inputs.resource`) and is expanded without quotes, so the shell applies word splitting and glob/pathname expansion to caller-supplied text. Splitting the space-separated URIs on purpose is fine, but it should be done safely, for example `read -r -a resources <<< "$requested_resources"` followed by `for res in "${resources[@]}"`, or by turning globbing off with `set -f`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection: the token, expires_in and granted_scope now go through printf '%s' | tr -d '\n\r' before they are written to GITHUB_ENV or GITHUB_OUTPUT. The existing JWT regex check stays in place. Fixed script-injection: the unquoted `for res in ${requested_resources}` loop is replaced. The resource URIs are now split into an array with `read -r -d '' -a ... || true` and the loop uses the quoted array (written with the set -u-safe ${arr[@]+...} form). This splits on whitespace exactly as before, but no longer expands globs. Nothing was run or tested.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

In action.yml, `for res in ${requested_resources}` let glob characters in the input match files on the runner. I replaced it with a guarded `read -r -d '' -a resources <<< "$requested_resources" || true` and a loop over the quoted array, using the `${arr[@]+...}` form so it doesn't error under `set -u`. The value is still split on whitespace as before, but nothing is glob-expanded now. The xargs normalization is unchanged. I haven't run the changed step.

