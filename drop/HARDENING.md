<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/d41fe10fe88deaf493ce026007da73738b9f570c

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/d41fe10fe88deaf493ce026007da73738b9f570c** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Validate install-dir' step writes a value derived from the untrusted input `inputs.install-dir` (via env var INPUTS_INSTALL_DIR) to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization. The case-based character validation excludes newlines, but the check requires explicit sanitization before every write to a special environment file when the source is workflow-controllable. Offending line: `echo "path=$dir" >> "$GITHUB_OUTPUT"`

Locations:

- `install/action.yml:73`

### github-env-injection (severity: high)

The 'Add the install directory to the PATH' step (Linux/macOS) writes `${INSTALL_DIR}/bin` to $GITHUB_PATH where INSTALL_DIR is sourced from `steps.install-dir.outputs.path` (a steps.*.outputs.* value, which is workflow-controllable) without the required `printf '%s' ... | tr -d '\n\r'` sanitization. Offending line: `echo "${INSTALL_DIR}/bin" >> $GITHUB_PATH`

Locations:

- `install/action.yml:100`

### github-env-injection (severity: high)

The 'Add the install directory to the PATH' step (Windows/pwsh) writes a value derived from `inputs.install-dir` (via env var INPUTS_INSTALL_DIR) to $env:GITHUB_PATH without the required sanitization. Offending line: `echo "$dir/bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append`

Locations:

- `install/action.yml:110`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in hardened/action/install/action.yml:
1. 'Validate install-dir' step (line 73): Added `safe_dir=$(printf '%s' "$dir" | tr -d '\n\r')` and write `$safe_dir` to $GITHUB_OUTPUT instead of raw `$dir`.
2. 'Add the install directory to the PATH' (Linux/macOS, line 100): Expanded to multi-line run block with `safe_dir=$(printf '%s' "${INSTALL_DIR}/bin" | tr -d '\n\r')` before writing to $GITHUB_PATH.
3. 'Add the install directory to the PATH' (Windows/pwsh, line 110): Added PowerShell sanitization `$safe = ("$dir/bin" -replace "`r","" -replace "`n","")` and used `Add-Content` to write the sanitized value to $env:GITHUB_PATH.

