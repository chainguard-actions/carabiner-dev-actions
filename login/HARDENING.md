<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--login/v1.2.9

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--login/v1.2.9** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansion of untrusted data. The variable `requested_resources` is derived from `inputs.resource` (via the `INPUTS_RESOURCE` env var, which holds `${{ inputs.resource }}`). It is then expanded unquoted in `for res in ${requested_resources}; do`, allowing shell glob expansion and metacharacter interpretation of attacker-controlled input. An attacker supplying a crafted `resource` input value could cause unexpected shell behavior. The value should be handled in a way that prevents glob expansion (e.g., using `read -ra` with a here-string, or quoting with IFS-controlled splitting).

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted shell variable expansion of `requested_resources` (derived from `inputs.resource` via `INPUTS_RESOURCE` env var) at line 76 of action.yml. Replaced `for res in ${requested_resources}; do` (which allowed glob expansion and metacharacter interpretation) with a safe xargs-based array tokenization pattern using NUL-delimited `read -r -d ''` in a while loop. The fix: (1) guards with `if [ -n "${INPUTS_RESOURCE}" ]` to prevent xargs from emitting an empty token on empty input, (2) uses `printf '%s' "${INPUTS_RESOURCE}" | xargs printf '%s\0'` for quote-aware tokenization, and (3) reads each NUL-delimited token safely into the `resource_args` array without glob expansion. Also removed the now-unnecessary intermediate `requested_resources` variable.

