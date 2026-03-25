# rulex-runtime-build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish multi-arch manylinux Docker build images (LLVM 18 + Rust + maturin) to GHCR via two native-runner GitHub Actions workflows.

**Architecture:** Two independent workflow files — one per architecture — each building and pushing a platform-tagged image to GHCR using a native GitHub-hosted runner. No QEMU. No manifest merge. Tags follow `{variant}-{arch}` scheme for future extensibility (e.g., `musl-amd64`).

**Tech Stack:** Docker, GitHub Actions, `docker/login-action`, `docker/setup-buildx-action`, `docker/build-push-action`, GHCR (`ghcr.io`)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Dockerfile` | manylinux_2_28 + LLVM 18 + Rust + maturin build image |
| Create | `.github/workflows/build-manylinux-amd64.yml` | Build and push `manylinux-amd64` on native x86_64 runner |
| Create | `.github/workflows/build-manylinux-arm64.yml` | Build and push `manylinux-arm64` on native arm64 runner |

---

### Task 1: Add the Dockerfile

**Files:**
- Create: `Dockerfile`

- [ ] **Step 1: Copy the Dockerfile from rulex-runtime**

```bash
cp ../rulex-runtime/Dockerfile ./Dockerfile
```

- [ ] **Step 2: Verify the file contents look correct**

```bash
cat Dockerfile
```

Expected: File starts with `ARG PLATFORM=x86_64`, ends with `WORKDIR /io`. No changes needed.

- [ ] **Step 3: Validate Dockerfile syntax locally**

```bash
docker build --no-cache --build-arg PLATFORM=x86_64 -t rulex-runtime-build:test . 2>&1 | tail -5
```

Expected: Build succeeds (this will take several minutes on first run due to LLVM download and Rust install). If you don't want to wait, at minimum check syntax:

```bash
docker buildx build --no-cache --build-arg PLATFORM=x86_64 --check . 2>&1
```

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "feat: add manylinux_2_28 + LLVM 18 + Rust + maturin Dockerfile"
```

---

### Task 2: Create the amd64 workflow

**Files:**
- Create: `.github/workflows/build-manylinux-amd64.yml`

- [ ] **Step 1: Create the workflow file**

```bash
mkdir -p .github/workflows
```

Create `.github/workflows/build-manylinux-amd64.yml` with this content:

```yaml
name: Build manylinux-amd64

on:
  push:
    branches: [main]
    paths:
      - Dockerfile
  schedule:
    - cron: '0 0 * * 0'  # Weekly, Sunday 00:00 UTC
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          build-args: |
            PLATFORM=x86_64
          tags: ghcr.io/${{ github.repository_owner }}/rulex-runtime-build:manylinux-amd64
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-manylinux-amd64.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build-manylinux-amd64.yml
git commit -m "feat: add GitHub Actions workflow to build manylinux-amd64 image"
```

---

### Task 3: Create the arm64 workflow

**Files:**
- Create: `.github/workflows/build-manylinux-arm64.yml`

- [ ] **Step 1: Create the workflow file**

Create `.github/workflows/build-manylinux-arm64.yml` with this content:

```yaml
name: Build manylinux-arm64

on:
  push:
    branches: [main]
    paths:
      - Dockerfile
  schedule:
    - cron: '0 0 * * 0'  # Weekly, Sunday 00:00 UTC
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-24.04-arm
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          build-args: |
            PLATFORM=aarch64
          tags: ghcr.io/${{ github.repository_owner }}/rulex-runtime-build:manylinux-arm64
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-manylinux-arm64.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build-manylinux-arm64.yml
git commit -m "feat: add GitHub Actions workflow to build manylinux-arm64 image"
```

---

### Task 4: Push and verify

- [ ] **Step 1: Push to GitHub**

```bash
git push origin main
```

- [ ] **Step 2: Trigger both workflows manually**

Navigate to the repo on GitHub → Actions → "Build manylinux-amd64" → Run workflow.
Repeat for "Build manylinux-arm64".

- [ ] **Step 3: Verify images are published**

After both workflows succeed, check GHCR:

```
https://github.com/orgs/coverstack/packages/container/package/rulex-runtime-build
```

Both `manylinux-amd64` and `manylinux-arm64` tags should be visible.

- [ ] **Step 4: Smoke-test the published image (optional)**

```bash
docker run --rm ghcr.io/coverstack/rulex-runtime-build:manylinux-amd64 \
  sh -c "clang --version && rustc --version && maturin --version"
```

Expected output similar to:
```
clang version 18.1.8
rustc 1.xx.x (...)
maturin 1.x.x (...)
```

---

## Notes

- **GHA cache:** Both workflows use GitHub Actions cache (`type=gha`) for Docker layer caching. This significantly speeds up rebuilds when only Rust/maturin change.
- **`github.repository_owner`:** The image is tagged under the org/user who owns the repo. For the `coverstack` org this resolves to `ghcr.io/coverstack/rulex-runtime-build`.
- **Future musl images:** Add a new `build-musl-amd64.yml` / `build-musl-arm64.yml` following the same pattern, swapping the base image and `PLATFORM` build arg.
- **`ubuntu-24.04-arm`:** This is GitHub's hosted ARM64 runner. Confirm it is enabled for your plan/org at `https://github.com/organizations/coverstack/settings/actions/runners`.
