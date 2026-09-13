# ADR 0001: Retain CherishOS and build a container-capable kernel

- Status: Accepted
- Date: 2026-09-14

## Context

The OnePlus Nord AC2003 currently boots CherishOS 14 with working Android
hardware support, Magisk 29 root and SELinux enforcing. Replacing the complete
ROM would add recovery risk and is not required for the server workload.

The running PSM 4.19.275 kernel was audited using its exported configuration
and Moby's container configuration checker. Essential container features were
missing, including PID and IPC namespaces, device and PIDs cgroups, POSIX
message queues, bridge netfilter and parts of the planned container network.
These are compile-time capabilities and cannot be added by a chroot, Magisk
module or runtime sysctl.

## Decision

Retain CherishOS 14 as the Android hardware-support layer and Magisk as the
root mechanism. Build a replacement kernel from a pinned avicii Android 14
source commit using a pinned Android Clang archive.

Record the customization as:

- named build inputs in `configs/kernel/build.env`;
- requested configuration changes in `configs/kernel/k3s.config`;
- ordered source changes in `patches/kernel/series`;
- generated configuration, input hashes and output hashes in each CI artifact.

KernelSU is disabled to avoid introducing a second root implementation. The
source patch in `patches/kernel/` only fixes the source so it compiles correctly
with KernelSU disabled.

## Safety boundary

A successful CI build proves compilation only. It does not prove that the
kernel is compatible with this phone or this CherishOS build.

The raw kernel and DTBO outputs are not directly flashable. A test boot image
must preserve the backed-up CherishOS/Magisk ramdisk and must first be booted
temporarily with `fastboot boot`. Permanent installation is allowed only after
Android startup, ADB, Wi-Fi, charging, Magisk root, SELinux and required
container kernel features have been verified.

## Consequences

- CherishOS remains the installed operating system.
- The kernel customization is reviewable and reproducible from Git.
- Android-specific runtime cgroup mounts and networking setup are still needed.
- A future ROM replacement requires a separate ADR.
