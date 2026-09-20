# Build and verify the avicii K3s kernel

## Objective

Build the pinned kernel recipe in GitHub Actions and verify the resulting audit
artifact. This runbook does not modify the phone.

## Prerequisites

- GitHub CLI authenticated for this repository
- clean `main` branch pushed to GitHub
- `configs/kernel/build.env`, `configs/kernel/k3s.config` and every file named
  by `patches/kernel/series` committed

## Build

```bash
gh workflow run build-avicii-k3s-kernel.yml

run_id=$(
  gh run list \
    --workflow build-avicii-k3s-kernel.yml \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId'
)

gh run watch "$run_id" --exit-status
```

## Download and verify

```bash
artifact_dir="artifacts/kernel-build-$run_id"
mkdir -p "$artifact_dir"

gh run download "$run_id" \
  --name avicii-k3s-kernel \
  --dir "$artifact_dir"

(
  cd "$artifact_dir"
  shasum -a 256 -c SHA256SUMS
)

cat "$artifact_dir/BUILD-MANIFEST.txt"
cat "$artifact_dir/PATCHES.sha256"
```

Every checksum must report `OK`. Verify that `control_plane_commit` identifies
the commit intended for testing and that `kernel_commit` and
`clang_archive_sha256` match `configs/kernel/build.env`.

## Artifact meaning

- `Image.gz-dtb`: kernel and appended device trees; not directly flashable
- `dtbo-raw.img`: raw build output; not approved for flashing
- `kernel.config`: final resolved kernel configuration
- `requested-k3s.config`: configuration requested by this repository
- `base-to-final.diffconfig`: resolved changes from the source base config
- `BUILD-MANIFEST.txt`: pinned inputs and output hashes
- `SHA256SUMS`: integrity record for the complete artifact

## Exit criterion

The workflow succeeded, every checksum passed and the manifest identifies the
expected repository commit. Continue with
[`02-repack-and-temporarily-boot-kernel.md`](02-repack-and-temporarily-boot-kernel.md).
