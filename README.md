# Nord Control Plane

Infrastructure, documentation and automation for converting a OnePlus
Nord AC2003 into a reproducible ARM64 home-server and Kubernetes node.

## Target platform

- Device: OnePlus Nord AC2003
- Codename: `avicii`
- Operating system: CherishOS 14 / Android 14
- Architecture: ARM64
- Linux userspace: Debian or Alpine chroot
- Container runtime: containerd
- Orchestrator: single-node K3s

## Responsibilities

This repository owns:

- device-state identification and recovery;
- CherishOS baseline, recovery and upgrade procedures;
- bootloader, recovery and partition documentation;
- root configuration;
- kernel capability auditing;
- container-compatible kernel configuration and builds;
- Linux chroot provisioning;
- K3s installation and lifecycle management;
- host networking and remote administration;
- monitoring, backups and disaster recovery;
- reproducible rebuilding of the node.

## Non-goals

This repository does not contain:

- application source code;
- Kubernetes application manifests;
- credentials, tokens or private keys;
- exact home-network details;
- proprietary firmware or ROM images;
- personal location coordinates.

Kubernetes workload definitions belong in
[`homelab-gitops`](https://github.com/georgecpp/homelab-gitops).

## Planned structure

```text
.
├── configs/
│   ├── android/
│   ├── kernel/
│   └── k3s/
├── docs/
│   ├── decisions/
│   └── runbooks/
├── inventory/
├── scripts/
│   ├── android/
│   ├── kernel/
│   └── linux/
├── checksums/
└── README.md

<!-- bootstrap-status:start -->

## Bootstrap status

Last updated: 2026-09-13

The project has reached the first reproducible kernel-build milestone. No
custom image has been booted or flashed to the phone yet.

### Current platform decision

Retain the working CherishOS 14 installation as the Android hardware-support
layer and replace only its kernel with a reproducibly built, container-capable
kernel. Replacing the Android ROM is outside the current bootstrap plan.

### Verified device baseline

- Device: OnePlus Nord AC2003 (`avicii`), ARM64
- Current operating system: CherishOS based on Android 14
- Active slot: A
- Current kernel: PSM Kernel 4.19.275
- Root: Magisk 29.0
- SELinux: enforcing
- Bootloader: unlocked
- Recovery, bootloader fastboot, fastbootd and recovery ADB: accessible

### Recovery preparation

The following partitions were copied from both slots where applicable and
checksummed before kernel work began:

- `boot_a` and `boot_b`
- `recovery_a` and `recovery_b`
- `dtbo_a` and `dtbo_b`
- `vbmeta_a` and `vbmeta_b`
- `persist`
- `modemst1` and `modemst2`
- `fsg` and `fsc`

Partition images are stored outside the repository. The `artifacts/`
directory and Android image formats are excluded by `.gitignore`.

### Stock-kernel audit

The running CherishOS kernel configuration is recorded at:

```text
configs/kernel/cherishos-14-psm-4.19.275.config
```

Its container compatibility report is recorded at:

```text
reports/kernel/moby-check-config.txt
```

The audit established that the installed kernel cannot host containerd or
K3s reliably because essential features are absent, including PID and IPC
namespaces, device and PIDs cgroups, bridge netfilter and required container
networking functionality.

### Reproducible custom-kernel build

GitHub Actions now builds a custom Android 14 kernel using:

- source: `OnePlus-Nord-OSS-Development/android_kernel_oneplus_avicii`;
- source commit: `c43a2a9e1c9e67c814910286f3e6b77c80a8050d`;
- Android Clang: `clang-r530567`;
- base configuration: `avicii_defconfig` plus `debugfs.config`;
- project configuration fragment: `configs/kernel/k3s.config`.

The project configuration enables the namespaces, cgroups, seccomp,
OverlayFS, bridge filtering, netfilter, VXLAN and optional IPVS functionality
required for the planned rootful K3s environment.

KernelSU is disabled so the existing Magisk-based root path can be retained.
A small, versioned source patch removes an unguarded duplicate KernelSU hook
that otherwise prevents the upstream kernel from compiling with KernelSU
disabled.

The CI workflow now:

1. fetches the pinned kernel source;
2. applies the local source patch;
3. downloads, validates and caches the Android Clang toolchain;
4. merges and verifies every requested kernel option;
5. compiles the kernel and DTBO successfully;
6. publishes checksummed, non-flashable audit artifacts.

The complete build recipe is version controlled:

- `configs/kernel/build.env` pins the kernel source, source commit, compiler,
  compiler checksum, build version and local version;
- `configs/kernel/k3s.config` records every deliberately requested K3s option;
- `patches/kernel/series` records the ordered source-patch set;
- `patches/kernel/*.patch` records every source-code change;
- each successful artifact contains the resolved configuration, configuration
  delta, patch checksums, input manifest and output checksums.

### Current safety boundary

Build success does not establish device compatibility. The generated
`Image.gz-dtb` and `dtbo-raw.img` files must not be flashed directly.

The next stage is to:

1. download and verify the CI artifact checksums;
2. review the generated `kernel.config`;
3. repack the backed-up active-slot boot image with the new kernel;
4. test it temporarily using `fastboot boot`;
5. verify Android startup, ADB, Wi-Fi, charging, Magisk root and the required
   kernel features;
6. install persistently only after the temporary boot passes.

Linux userspace, containerd and K3s installation remain pending until that
kernel validation is complete.

<!-- bootstrap-status:end -->
