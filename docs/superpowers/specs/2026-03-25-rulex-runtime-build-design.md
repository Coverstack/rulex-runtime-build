# rulex-runtime-build: Docker Build Image with GitHub Actions

**Date:** 2026-03-25
**Status:** Approved

## Purpose

Build and maintain Docker images for building Python wheels for the rulex-runtime project. The images are based on `manylinux_2_28` and include LLVM 18, Rust (stable), and maturin. Images are published to GitHub Container Registry (GHCR).

## Dockerfile

Copy `Dockerfile` verbatim from `rulex-runtime`. The file is suitable as-is:

- **Base image:** `quay.io/pypa/manylinux_2_28_{PLATFORM}` (AlmaLinux 8, glibc 2.28+)
- **LLVM 18.1.8:** Downloaded as pre-built binaries from the LLVM GitHub releases. x86_64 uses the Ubuntu 18.04 build (glibc-compatible with manylinux_2_28). aarch64 uses the generic Linux build.
- **Rust:** Installed via rustup, pinned to `stable` toolchain (intentionally floating to pick up updates via scheduled builds).
- **maturin:** Installed via cp313 pip, symlinked to `/usr/local/bin/maturin`.
- **`ARG PLATFORM`:** Controls which manylinux base image is selected (`x86_64` or `aarch64`). Passed explicitly at build time.

## Tag Naming

Tags follow the `{variant}-{arch}` scheme to support future libc variants:

| Image | Tag |
|---|---|
| `ghcr.io/coverstack/rulex-runtime-build` | `manylinux-amd64` |
| `ghcr.io/coverstack/rulex-runtime-build` | `manylinux-arm64` |
| (future) | `musl-amd64` |
| (future) | `musl-arm64` |

## GitHub Actions Workflows

Two separate workflow files — one per architecture — using **native GitHub-hosted runners** (no QEMU).

### Triggers (both workflows)

- `push` to `main` with path filter: `Dockerfile`
- `schedule`: weekly, Sunday at 00:00 UTC (to pick up Rust stable updates)
- `workflow_dispatch`: manual trigger

### Workflow: `build-manylinux-amd64.yml`

- **Runner:** `ubuntu-24.04`
- **Build arg:** `PLATFORM=x86_64`
- **Pushes to:** `ghcr.io/coverstack/rulex-runtime-build:manylinux-amd64`

### Workflow: `build-manylinux-arm64.yml`

- **Runner:** `ubuntu-24.04-arm`
- **Build arg:** `PLATFORM=aarch64`
- **Pushes to:** `ghcr.io/coverstack/rulex-runtime-build:manylinux-arm64`

### Steps (each workflow)

1. Checkout repo
2. Log in to GHCR using `GITHUB_TOKEN` (via `docker/login-action`)
3. Set up Docker Buildx (via `docker/setup-buildx-action`)
4. Build and push (via `docker/build-push-action`) with the appropriate `PLATFORM` build arg

### Permissions

Each workflow requires:
- `contents: read`
- `packages: write`

## Future Extensions

- Add `musl-amd64` / `musl-arm64` workflows using `alpine`-based or `musllinux` base images.
- No multi-arch manifest merge needed — consumers pull the explicit `{variant}-{arch}` tag.
