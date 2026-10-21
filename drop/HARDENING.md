<!-- markdownlint-disable -->

# Hardening Report: carabiner-dev--actions--drop/v1.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **carabiner-dev--actions--drop/v1.2.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The Docker action's runs.image is 'docker://ghcr.io/carabiner-dev/drop'. It has no SHA256 digest and no tag, so it resolves to the mutable ':latest' tag. Whoever controls that tag can change the code that runs on users' runners. Pin it to a digest, e.g. image: 'docker://ghcr.io/carabiner-dev/drop@sha256:<digest>'.

Locations:

- `action.yml:19`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Pinned runs.image to docker://ghcr.io/carabiner-dev/drop:latest@sha256:56b3fb14a90e92a268ddebf864bc80f84b2488cba09ea3cacbc2753cc838a56f. Kept the docker:// scheme and the tag. Left the Docker args unchanged because they are passed as an argv array and are not injectable.

