# Install and enter the Debian ARM64 rootfs

## Objective

Extract the verified Debian rootfs into persistent Android data storage and run
commands inside it with the kernel interfaces required by package management
and later container operation.

## Location

The rootfs lives at:

```text
/data/adb/nord-k3s/rootfs
```

This location is persistent, root-only and outside the Git repository. Rootfs
archives and extracted files must never be committed.

## Integrity and extraction

Verify the GitHub Actions artifact locally, compare its SHA-256 after transfer
to the phone, and extract into a new staging directory. Rename the staging
directory to `rootfs` only after its shell, dpkg database and OS metadata have
been verified.

## Chroot launcher

`scripts/linux/nord-chroot.sh` must run through Magisk root. For every command
it creates a private mount namespace and mounts:

- Android `/dev` recursively at the rootfs `/dev`;
- a new proc filesystem at `/proc`;
- Android `/sys`, including its cgroup mounts, recursively at `/sys`;
- a temporary `/run` filesystem.

The private namespace is destroyed automatically when the chroot command exits,
so these test mounts do not remain in Android's global mount namespace.

Install the launcher on the phone:

```bash
adb push scripts/linux/nord-chroot.sh \
  /data/local/tmp/nord-chroot.sh
adb shell chmod 0755 /data/local/tmp/nord-chroot.sh
```

Run one command:

```bash
adb shell \
  "su -c 'sh /data/local/tmp/nord-chroot.sh /usr/bin/uname -a'"
```

Open an interactive shell:

```bash
adb shell -t \
  "su -c 'sh /data/local/tmp/nord-chroot.sh'"
```

## Package networking test

```bash
adb shell \
  "su -c 'sh /data/local/tmp/nord-chroot.sh /usr/bin/apt-get update'"
```

Do not install K3s at this stage. The rootfs mount layout, Debian networking and
package manager must first be validated and recorded.

## Exit criterion

Debian sees the expected kernel and ARM64 architecture, `/proc`, `/dev`, `/sys`,
`/sys/fs/cgroup` and `/run` are mounted inside the private namespace, DNS works,
and `apt-get update` completes successfully.
