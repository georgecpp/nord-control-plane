# Install and verify the tested avicii kernel

## Objective

Install only a boot image that has already passed the temporary-boot runbook,
then prove that the installed image and all required behavior survive a normal
reboot.

## Preconditions

- the temporary-boot and runtime-validation runbooks passed;
- the active slot is known;
- the tested boot-image SHA-256 is recorded;
- a checksummed backup of the active boot partition is available off-device;
- bootloader fastboot is accessible and unlocked;
- USB power and data are stable.

Do not flash the raw `Image.gz-dtb` or `dtbo-raw.img` artifacts. Do not modify
the inactive slot.

## Verify inputs

Set paths and expected hashes for the approved build:

```bash
test_boot=<path-to-tested-repacked-boot-image>
boot_backup=<path-to-active-slot-boot-backup>
expected_test_sha256=<recorded-tested-image-sha256>
expected_backup_sha256=<recorded-backup-sha256>
```

```bash
test -s "$test_boot"
test -s "$boot_backup"

test "$(shasum -a 256 "$test_boot" | awk '{print $1}')" = \
  "$expected_test_sha256"

test "$(shasum -a 256 "$boot_backup" | awk '{print $1}')" = \
  "$expected_backup_sha256"

adb shell getprop ro.boot.slot_suffix
adb shell getprop sys.boot_completed
```

Stop if either checksum differs or Android is not completely booted.

## Enter bootloader fastboot

```bash
adb reboot bootloader
sleep 5

fastboot devices
fastboot getvar is-userspace 2>&1
fastboot getvar current-slot 2>&1
fastboot getvar unlocked 2>&1
```

Require bootloader fastboot (`is-userspace: no`), the previously recorded slot
and `unlocked: yes`.

## Install

Replace `a` below only if the verified active slot is different:

```bash
fastboot flash boot_a "$test_boot"
fastboot reboot
```

Wait for `sys.boot_completed=1`; ADB availability alone does not prove Android
has completed startup.

## Verify installed bytes

For slot A:

```bash
installed_boot_sha=$(
  adb exec-out su -c \
    'dd if=/dev/block/by-name/boot_a bs=1048576 2>/dev/null' |
  shasum -a 256 |
  awk '{print $1}'
)

test "$installed_boot_sha" = "$expected_test_sha256"
```

## Verify behavior and persistence

Verify Android completion, expected kernel release, active slot, Magisk,
enforcing SELinux, networking and the versioned runtime validator. Then perform
one additional normal reboot and repeat those checks.

Record the persistent validation separately from the temporary-boot output.

## Rollback

If the installed kernel does not boot, return to bootloader fastboot and write
the checksummed original image back to the same slot:

```bash
fastboot flash boot_a "$boot_backup"
fastboot reboot
```

Do not switch to the untested inactive slot as a substitute for restoring the
known slot backup.

## Exit criterion

The partition checksum matches the tested image, Android completes two boots,
and the compatibility and kernel-runtime tests pass after persistent install.
