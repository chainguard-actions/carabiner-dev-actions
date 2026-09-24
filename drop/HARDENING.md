<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/d41fe10fe88deaf493ce026007da73738b9f570c

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/d41fe10fe88deaf493ce026007da73738b9f570c** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Validate install-dir' step writes a value derived from `inputs.install-dir` (via the `$INPUTS_INSTALL_DIR` env var) to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). The character-set validation (`case "$INPUTS_INSTALL_DIR" in ''|*[!A-Za-z0-9._/$~-]*)`) does restrict the allowed characters, but the mandatory sanitization pipeline is absent before `echo "path=$dir" >> "$GITHUB_OUTPUT"`.

Locations:

- `install/action.yml:79`

### github-env-injection (severity: high)

The 'Add the install directory to the PATH' step (Linux/macOS) writes `${INSTALL_DIR}/bin` to `$GITHUB_PATH` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). `INSTALL_DIR` is sourced from `steps.install-dir.outputs.path`, which is itself derived from the user-controlled `inputs.install-dir`. The `# zizmor: ignore` comment acknowledges the issue but does not replace the missing sanitization.

Locations:

- `install/action.yml:92`

### github-env-injection (severity: high)

The 'Add the install directory to the PATH' step (Windows/pwsh) writes a value derived from `inputs.install-dir` (via `$env:INPUTS_INSTALL_DIR`) to `$env:GITHUB_PATH` using `Out-File -Append` without the required sanitization. The `# zizmor: ignore` comment acknowledges the issue but does not replace the missing sanitization.

Locations:

- `install/action.yml:98`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in hardened/action/install/action.yml:
1. Line 79 ('Validate install-dir' step): Added `safe_dir=$(printf '%s' "$dir" | tr -d '\n\r')` and used `$safe_dir` when writing to $GITHUB_OUTPUT.
2. Line 92 (Linux/macOS PATH step): Replaced single-line echo with a multi-line block that sanitizes `${INSTALL_DIR}/bin` via `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_PATH.
3. Line 98 (Windows/pwsh PATH step): Added PowerShell sanitization using `-replace` to strip newlines/carriage returns from the path value before writing to $GITHUB_PATH via Out-File.

