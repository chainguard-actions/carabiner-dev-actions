<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/v1.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/v1.3.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Three steps in install/action.yml write values derived from the caller-controlled `inputs.install-dir` input to `$GITHUB_OUTPUT` and `$GITHUB_PATH` without the required `printf '%s' ... | tr -d '\n\r'` newline-stripping sanitization.

1. The 'Validate install-dir' step writes `echo "path=$dir" >> "$GITHUB_OUTPUT"` where `$dir` is derived from `$INPUTS_INSTALL_DIR` (which holds `${{ inputs.install-dir }}`). A character-allowlist `case` check is applied, but the sanitization pipeline (`printf '%s' "$dir" | tr -d '\n\r'`) is not used before the write.

2. The Linux/macOS 'Add the install directory to the PATH' step writes `echo "${INSTALL_DIR}/bin" >> $GITHUB_PATH` where `$INSTALL_DIR` is set from `steps.install-dir.outputs.path` (itself derived from the untrusted input). No sanitization is applied.

3. The Windows 'Add the install directory to the PATH' step writes `echo "$dir/bin" | Out-File -FilePath $env:GITHUB_PATH` where `$dir` is derived from `$env:INPUTS_INSTALL_DIR` (which holds `${{ inputs.install-dir }}`). No sanitization is applied.

Locations:

- `install/action.yml:93`
- `install/action.yml:131`
- `install/action.yml:138`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in hardened/action/install/action.yml:
1. 'Validate install-dir' step (bash): Added `safe_dir=$(printf '%s' "$dir" | tr -d '\n\r')` and write `safe_dir` to $GITHUB_OUTPUT instead of raw `$dir`.
2. Linux/macOS 'Add the install directory to the PATH' step (bash): Converted to multi-line script that sanitizes $INSTALL_DIR with `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_PATH.
3. Windows 'Add the install directory to the PATH' step (pwsh): Added `$safe_dir = ($dir -replace '[\r\n]', '')` and writes `$safe_dir` to $GITHUB_PATH instead of raw `$dir`.

