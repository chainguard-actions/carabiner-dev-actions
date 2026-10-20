<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.6** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: unquoted expansion of data that comes from an input. On line 76, the step runs `for res in ${requested_resources}; do`. The variable is built from INPUTS_RESOURCE, which is set from ${{ inputs.resource }}, and the only processing is `printf '%s' ... | xargs`. Because the expansion is unquoted, the shell splits it into words and expands glob patterns, so characters like * or ? in the input can turn into local file names. The splitting is deliberate, so simply adding quotes would break the loop. Split the value safely instead, for example `read -r -a resources <<< "$requested_resources"; for res in "${resources[@]}"; do`, or run `set -f` around the loop to turn off globbing.

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

In action.yml, the loop over resources no longer uses the unquoted `for res in ${requested_resources}`. The value is now read into an array with `read -r -d '' -a resources <<< "$requested_resources" || true` and the loop runs over the quoted array elements. It still splits on whitespace like before, but no longer expands glob characters into file names. An empty-value guard was added, and the array expansion is written to work under set -u on bash 3.2. The input is still cleaned with xargs first, as upstream did.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, expires_in and granted_scope are now passed through tr -d '\n\r' before being written to $GITHUB_OUTPUT. The inputs are plain variables, so the pipelines can't hide a failing command. Nothing else changed.

