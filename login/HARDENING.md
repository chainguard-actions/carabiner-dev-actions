<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The login step in action.yml writes `expires_in` and `granted_scope` to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step: `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"`. Both values come from `jq -r` on the JSON response of the exchange server. The caller chooses that server through the `exchange-url` input, so these values are untrusted. A JSON string with embedded newlines can add extra output keys. The CARABINER_CREDENTIALS write to $GITHUB_ENV on line 136 is checked against a single-line JWT regex first, so in practice it is safe. It still does not use the required tr -d sanitization, though, and should get it too.

Locations:

- `action.yml:137`
- `action.yml:138`
- `action.yml:136`

### script-injection (severity: high)

Rule (b), unquoted shell expansion of untrusted data, in the login step of action.yml: `for res in ${requested_resources}; do`. `requested_resources` comes from the `resource` input (env INPUTS_RESOURCE) and is expanded without quotes. The shell then word-splits it and expands glob characters such as `*`, `?` and `[`, so the value can turn into file names from the workspace. Split it safely instead, for example `read -ra resources <<< "$requested_resources"; for res in "${resources[@]}"`, or turn off globbing with `set -f`.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Resources are now split on whitespace into a bash array with `read -r -d '' -a` behind an emptiness guard, so the shell no longer globs them. The array is then expanded quoted, using the set -u-safe ${arr[@]+...} form. The upstream xargs normalization is unchanged. Before CARABINER_CREDENTIALS is written to GITHUB_ENV and expires-in and scope are written to GITHUB_OUTPUT, each value has newlines removed with printf '%s' | tr -d '\n\r'.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the 'login' step now passes expires_in and granted_scope through printf '%s' | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. The inputs are both plain variables, so no command substitution is nested inside another and errexit behavior is unchanged.

