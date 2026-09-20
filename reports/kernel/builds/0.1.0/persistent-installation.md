# Kernel 0.1.0 persistent installation

- Date: 2026-09-20
- Device: OnePlus Nord AC2003 (`avicii`)
- Installed slot: A
- Kernel: `4.19.318-NordK3s-v0.1.0`
- Installation method: bootloader fastboot, `boot_a` only
- Installed boot-image SHA-256: `880d29ae3b9b4cfd1d62f666b1b412faa5544003e3584da13cfb4146cd7348e5`
- Inactive slot modified: no
- Raw kernel or DTBO artifact flashed: no

## Verification

- The post-install `boot_a` checksum matched the temporarily tested image.
- Android completed startup after installation.
- The kernel survived an additional normal reboot.
- Active slot remained A.
- Magisk root remained available in the `u:r:magisk:s0` context.
- SELinux remained enforcing.
- External network connectivity worked.
- Requested kernel configuration validation passed.
- PID, IPC, mount and network namespace tests passed.
- The existing cgroup-v2 PIDs controller was detected.
- Devices-cgroup and OverlayFS runtime tests passed.

IPv4 and IPv6 forwarding remained disabled. These are intentional runtime
provisioning tasks for the Linux userspace and K3s networking stage, not kernel
build failures.

## Rollback

The checksummed original `boot_a` image remains stored outside the repository.
Rollback consists of restoring that image to `boot_a` from bootloader fastboot.
