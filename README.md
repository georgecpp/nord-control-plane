# Nord Control Plane

Infrastructure, documentation and automation for converting a OnePlus
Nord AC2003 into a reproducible ARM64 home-server and Kubernetes node.

## Target platform

- Device: OnePlus Nord AC2003
- Codename: `avicii`
- Operating system: LineageOS 21 / Android 14
- Architecture: ARM64
- Linux userspace: Debian or Alpine chroot
- Container runtime: containerd
- Orchestrator: single-node K3s

## Responsibilities

This repository owns:

- device-state identification and recovery;
- Android and LineageOS installation procedures;
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