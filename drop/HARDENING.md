<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/v1.1.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/v1.1.6** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The Docker action's `runs.image` references `docker://ghcr.io/carabiner-dev/drop` without a SHA digest. This resolves to a mutable tag (effectively `latest`), meaning the image pulled at runtime can change without notice, creating a supply-chain attack vector. It must be pinned to an immutable SHA digest, e.g. `image: ghcr.io/carabiner-dev/drop@sha256:<64-hex-char-digest>`.

Locations:

- `action.yml:19`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Pinned the Docker image reference in action.yml from the mutable `docker://ghcr.io/carabiner-dev/drop` to `docker://ghcr.io/carabiner-dev/drop:latest@sha256:56b3fb14a90e92a268ddebf864bc80f84b2488cba09ea3cacbc2753cc838a56f`. The docker:// scheme is preserved as required for Docker container actions, and the tag is kept inline before the digest per the pinning guidelines.

