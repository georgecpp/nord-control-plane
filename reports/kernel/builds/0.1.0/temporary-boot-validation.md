# Kernel 0.1.0 temporary-boot validation

- Date: 2026-09-20
- Device: OnePlus Nord AC2003 (`avicii`)
- Active slot: A
- Build workflow run: `35522034398`
- Control-plane commit: `48fe06fc821dc51c5c9e2f9494114803600f11bc`
- Test boot image SHA-256: `880d29ae3b9b4cfd1d62f666b1b412faa5544003e3584da13cfb4146cd7348e5`
- Boot method: temporary `fastboot boot`
- Persistent partitions modified: none

## Passed checks

- Android 14 completed startup.
- ADB reconnected and `sys.boot_completed` returned `1`.
- Kernel release was `4.19.318-NordK3s-v0.1.0`.
- Active slot remained A.
- Magisk returned a root shell in the `u:r:magisk:s0` context.
- SELinux remained enforcing.
- Wi-Fi associated successfully and external ICMP connectivity worked.
- All requested kernel configuration options were present.
- KernelSU remained disabled.
- PID, IPC, mount and network namespace creation succeeded.
- The PIDs controller was available through the existing cgroup-v2 hierarchy.
- A devices cgroup was mounted and exercised successfully.
- OverlayFS was mounted, read and written successfully.
- The complete versioned runtime validator passed.

## Runtime work still required

Android exposes a hybrid cgroup layout. CPU, cpuset, memory and block I/O are
mounted using cgroup v1. The PIDs controller is available in the existing
cgroup-v2 hierarchy. The first runtime-validation pass stopped when it tried
to mount that controller again as cgroup v1. The versioned validator at
`scripts/kernel/validate-runtime.sh` detects this layout and continues with the
devices-cgroup and OverlayFS tests; its captured output is the source of truth
for those results.

IPv4 and IPv6 forwarding remain disabled. Runtime provisioning must construct
the cgroup view used by the Linux userspace and enable the required networking
sysctls before containerd and K3s are installed.

The Moby audit records missing optional features such as user namespaces,
AppArmor, nftables, Btrfs and ZFS. These are not required for the selected
rootful K3s design using SELinux, iptables and OverlayFS.

## Installation status

The custom kernel has not been installed persistently. The device continues to
boot the original CherishOS kernel after a normal reboot.
