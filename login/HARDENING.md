<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), unquoted shell expansion of untrusted data. On line 74, requested_resources is built from INPUTS_RESOURCE (${{ inputs.resource }}). On line 76 it is expanded without quotes: `for res in ${requested_resources}; do`. The word splitting is deliberate, but the shell also expands glob characters (*, ?, [) in the input-supplied value against the runner's filesystem. Fix: run `read -r -a res_list <<< "$requested_resources"`, then loop with `for res in "${res_list[@]}"`. Alternatively, turn off globbing with `set -f` before the loop.

Locations:

- `action.yml:76`

### github-env-injection (severity: high)

The login step writes values it did not create itself to $GITHUB_OUTPUT without first stripping newlines with printf '%s' ... | tr -d '\n\r'. The writes are `echo "expires-in=${expires_in}" >> "${GITHUB_OUTPUT}"` on line 137 and `echo "scope=${granted_scope}" >> "${GITHUB_OUTPUT}"` on line 138. Both values come from the JSON response of the token exchange server, read with `jq -r` on lines 125 and 129. That server's URL is set by the workflow through inputs.exchange-url. A response value that contains newlines could add extra outputs. The CARABINER_CREDENTIALS write to GITHUB_ENV on line 136 is safe because a single-line JWT regex checks it first. Fix: strip newlines from expires_in and granted_scope (e.g. safe=$(printf '%s' "$granted_scope" | tr -d '\n\r')) before writing them.

Locations:

- `action.yml:137`
- `action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

script-injection: the resource input is no longer looped over unquoted. It is now split into an array with `read -r -d '' -a`, guarded by `[ -n ]` and followed by `|| true`, and the loop uses `${res_list[@]+"${res_list[@]}"}`. It still splits on whitespace like before, but `*`, `?` and `[` in the input are no longer matched against files on the runner. The form also works with `set -u` and older bash, including when the input is empty.
github-env-injection: expires_in and granted_scope now have newlines and carriage returns removed with `printf '%s' | tr -d '\n\r'` before they are written to GITHUB_OUTPUT. I didn't change the CARABINER_CREDENTIALS write to GITHUB_ENV, because a single-line JWT check already guards it. I haven't run the changed action; both edits are in action.yml.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Rebuilt the broken end of the login step's script, where the previous edit had mangled the comment and left a fragment and duplicate lines behind. Restored the '# 3. Mask the token...' comment, the '::add-mask::' line for the token, and the CARABINER_CREDENTIALS export to GITHUB_ENV (the variable name comes from the README). The token also has newlines stripped, on top of the existing JWT regex check. expires-in and scope go through printf | tr -d '\n\r' before being written to GITHUB_OUTPUT. Removed the stray 'IALS=...' fragment and the duplicate unsanitized echo lines.

