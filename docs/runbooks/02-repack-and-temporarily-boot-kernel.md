# Repack and temporarily boot the avicii kernel

## Objective

Create a boot image that preserves the installed CherishOS/Magisk ramdisk,
replaces only the kernel and appended device trees, and boots it without writing
any partition.

## Safety requirements

- bootloader unlocked
- phone battery at least 50 percent and connected to stable power
- current active slot recorded
- checksummed backup of the active slot's boot partition available
- verified kernel artifact produced by the preceding runbook

Never flash `Image.gz-dtb` or `dtbo-raw.img`. Never use `fastboot flash` during
this runbook.

## Set paths

Replace the example values with the current run and active-slot backup:

```bash
run_id=<successful-workflow-run-id>
artifact_dir="artifacts/kernel-build-$run_id"
boot_backup=<absolute-path-to-active-slot-boot-backup>
expected_boot_sha256=<recorded-backup-sha256>
phone_work="/data/local/tmp/nord-k3s-$run_id"
local_test_dir="artifacts/test-boot-$run_id"
test_boot="$local_test_dir/nord-k3s-test.img"
```

Verify the inputs:

```bash
test -s "$artifact_dir/Image.gz-dtb"
test -s "$boot_backup"

actual_boot_sha256=$(
  shasum -a 256 "$boot_backup" |
  awk '{print $1}'
)

test "$actual_boot_sha256" = "$expected_boot_sha256"
```

## Prepare the phone workspace

Use a new work directory for every attempt:

```bash
adb shell "test ! -e $phone_work"
adb shell "mkdir -p \
  $phone_work/original \
  $phone_work/custom \
  $phone_work/verify"

adb push "$boot_backup" "$phone_work/original/boot.img"
adb push "$artifact_dir/Image.gz-dtb" "$phone_work/custom/Image.gz-dtb"
adb push scripts/kernel/repack-test-boot.sh \
  /data/local/tmp/repack-test-boot.sh
adb shell chmod 0755 /data/local/tmp/repack-test-boot.sh
```

## Repack and verify

```bash
adb shell \
  "su -c 'sh /data/local/tmp/repack-test-boot.sh \
  $phone_work nord-k3s-test.img'"
```

Do not continue unless the script prints `REPACK VERIFIED`.

```bash
mkdir -p "$local_test_dir"
adb pull "$phone_work/original/nord-k3s-test.img" "$test_boot"
test -s "$test_boot"
shasum -a 256 "$test_boot"
```

Record the resulting checksum before booting it.

## Temporary boot

```bash
adb shell dumpsys battery | grep -E 'level:|status:|temperature:'
adb shell getprop ro.boot.slot_suffix
adb reboot bootloader

fastboot devices
fastboot getvar is-userspace 2>&1
fastboot getvar current-slot 2>&1
fastboot getvar unlocked 2>&1
fastboot boot "$test_boot"
```

Expected bootloader state is `is-userspace: no`, the previously recorded active
slot and `unlocked: yes`.

If `fastboot boot` fails, run `fastboot reboot`, record the error and stop. Do
not substitute a flash command.

## Wait for Android

```bash
for attempt in $(seq 1 60); do
  state=$(adb get-state 2>/dev/null || true)

  if [ "$state" = device ]; then
    break
  fi

  sleep 5
done

adb devices -l
adb shell getprop sys.boot_completed
adb shell uname -a
```

If Android does not boot within five minutes, force the phone off using Power
and Volume Up for approximately ten seconds, then boot normally. A temporary
boot leaves the installed boot partition unchanged.

## Exit criterion

Android completed startup and `uname -a` contains the expected project local
version. Continue with
[`03-validate-temporary-kernel.md`](03-validate-temporary-kernel.md) without
rebooting.
