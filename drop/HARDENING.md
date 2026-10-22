<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/v1.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/v1.2.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The Docker image in action.yml is not pinned to a SHA digest: `image: 'docker://ghcr.io/carabiner-dev/drop'`. It has no tag, so it resolves to the mutable `latest` tag. Pin it to a digest instead (e.g. ghcr.io/carabiner-dev/drop@sha256:<digest> # <tag>).

Locations:

- `action.yml:19`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Pinned runs.image in action.yml to docker://ghcr.io/carabiner-dev/drop:latest@sha256:56b3fb14a90e92a268ddebf864bc80f84b2488cba09ea3cacbc2753cc838a56f. The docker:// scheme and the tag stay inline. I left the Docker args alone: the runner passes them as an argv array with no shell, so they can't be injected into.

