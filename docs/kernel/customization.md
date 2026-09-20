# Kernel customization record

This document identifies every input and intentional change in the Nord K3s
kernel. The build has no undocumented source revision, compiler revision or
configuration overlay.

## Sources of truth

| Path | Purpose |
|---|---|
| `configs/kernel/build.env` | Pins the kernel repository and commit, compiler archive and checksum, build version, local version and base defconfigs |
| `configs/kernel/k3s.config` | Records the deliberately requested kernel configuration delta |
| `patches/kernel/series` | Defines the source patches and their application order |
| `patches/kernel/*.patch` | Records each source-code change as a reviewable patch |
| `.github/workflows/build-avicii-k3s-kernel.yml` | Applies the pinned recipe, verifies it, compiles it and packages evidence |

The large `configs/kernel/cherishos-14-psm-4.19.275.config` file is an audit of
the original running kernel. It is evidence, not an input to the custom build.

## Intentional changes in version 0.1.0

The base kernel is the `avicii_defconfig` plus `debugfs.config` configuration
from the pinned source commit. The project fragment adds the capabilities
needed by the planned rootful containerd and K3s environment, including:

- PID and IPC namespaces;
- device and PIDs cgroups;
- POSIX message queues and seccomp filtering;
- OverlayFS;
- bridge netfilter and iptables dependencies;
- IPv6 NAT support;
- VXLAN, MACVLAN and IPVLAN networking;
- IPVS support used by Kubernetes networking modes.

`CONFIG_KSU` is explicitly disabled because root is provided by Magisk. The
patch listed in `patches/kernel/series` removes an unguarded duplicate KernelSU
hook which otherwise breaks compilation when KernelSU is disabled. It does not
add an undocumented feature.

## Build evidence

Every successful workflow artifact contains:

- `BUILD-MANIFEST.txt`, which resolves all pinned inputs and output hashes;
- `SOURCE_COMMIT`, which records the checked-out source revision;
- `requested-k3s.config`, which is the requested project fragment;
- `kernel.config`, which is the final resolved configuration;
- `base-to-final.diffconfig`, which shows the effective configuration delta;
- `PATCH_SERIES` and `PATCHES.sha256`, which identify the applied source edits;
- `SHA256SUMS`, which covers every published artifact file.

The manifest's `control_plane_commit` connects an artifact to the exact state
of this repository that produced it.

## Changing the kernel recipe

1. Change only the appropriate source of truth above.
2. Increase `KERNEL_BUILD_VERSION` and update `KERNEL_LOCALVERSION` in
   `configs/kernel/build.env` for a new testable build.
3. Put each new source edit in a named patch and append it to
   `patches/kernel/series` in application order.
4. Run the GitHub Actions build and verify its artifact using the build
   runbook.
5. Review `base-to-final.diffconfig`, `PATCHES.sha256` and
   `BUILD-MANIFEST.txt` before testing the image.
6. Follow the temporary-boot and runtime-validation runbooks. Do not treat a
   successful compile as device validation.

Never edit generated artifact files to change the recipe. Make the change in
Git, produce a new versioned build and preserve the resulting manifest.
