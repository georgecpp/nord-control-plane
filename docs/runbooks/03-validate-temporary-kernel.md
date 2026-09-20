# Validate the temporarily booted kernel

## Objective

Verify Android compatibility and exercise the kernel capabilities needed by the
planned Linux userspace, containerd and rootful K3s installation.

## Android compatibility

```bash
adb shell getprop sys.boot_completed
adb shell uname -a
adb shell getprop ro.boot.slot_suffix
adb shell su -c id
adb shell su -c getenforce
adb shell cmd wifi status | head -20
adb shell ping -c 3 1.1.1.1
adb shell dumpsys battery | grep -E 'level:|status:|health:|temperature:'
```

Required results:

- Android reports boot completed;
- the expected custom local version appears in `uname -a`;
- Magisk returns UID 0;
- SELinux remains enforcing;
- Wi-Fi and external connectivity work;
- charging and temperature remain normal.

Do not commit SSIDs, BSSIDs, MAC addresses, IP addresses or device serials.

## Kernel runtime validation

```bash
adb push "$artifact_dir/requested-k3s.config" \
  /data/local/tmp/requested-k3s.config
adb push scripts/kernel/validate-runtime.sh \
  /data/local/tmp/validate-runtime.sh
adb shell chmod 0755 /data/local/tmp/validate-runtime.sh

adb shell \
  "su -c 'sh /data/local/tmp/validate-runtime.sh \
  /data/local/tmp/requested-k3s.config'" |
  tee reports/kernel/builds/<version>/runtime-validation.txt
```

The script verifies the requested configuration, PID/IPC/mount/network
namespaces, PIDs-controller availability, devices cgroup and OverlayFS. It
creates only temporary test mounts and removes them on exit.

## Moby audit

Use the same pinned Moby `check-config.sh` revision used for the original
kernel audit:

```bash
adb shell \
  "su -c 'NO_COLOR=1 sh \
  /data/local/tmp/moby-check-config.sh /proc/config.gz'" |
  tee reports/kernel/builds/<version>/moby-check-config-temporary-boot.txt
```

On Android, the checker will still report runtime differences:

- a hybrid cgroup-v1/cgroup-v2 layout;
- forwarding sysctls disabled;
- optional filesystems and security systems not selected by this project.

Those results must not be misreported as compile failures. Runtime cgroup
presentation and networking sysctls belong to the Linux-userspace provisioning
stage.

## Record the result

Commit only sanitized evidence:

- build manifest and checksums;
- final kernel configuration and config delta;
- runtime-validation output;
- Moby audit output;
- a short temporary-boot summary;
- updated `inventory/device.md` status.

Do not commit raw boot images, partition backups, network identifiers, device
serials or raw ADB dumps.

## Exit criterion

All compatibility and runtime tests pass, failures are documented, and the
installed boot partition remains unchanged. Permanent installation requires a
separate reviewed runbook and is intentionally outside this runbook.
