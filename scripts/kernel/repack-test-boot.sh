#!/system/bin/sh

set -eu

WORK=${1:?usage: repack-test-boot.sh WORK_DIRECTORY [OUTPUT_NAME]}
OUTPUT=${2:-nord-k3s-test.img}
MAGISKBOOT=${MAGISKBOOT:-/data/adb/magisk/magiskboot}

case "$WORK" in
    /data/local/tmp/*) ;;
    *) echo "Work directory must be below /data/local/tmp" >&2; exit 1 ;;
esac

case "$OUTPUT" in
    */*) echo "Output must be a file name, not a path" >&2; exit 1 ;;
esac

ORIGINAL="$WORK/original"
CUSTOM="$WORK/custom"
VERIFY="$WORK/verify"

test -x "$MAGISKBOOT"
test -s "$ORIGINAL/boot.img"
test -s "$CUSTOM/Image.gz-dtb"
test -d "$VERIFY"

cd "$ORIGINAL"
"$MAGISKBOOT" unpack -n -h boot.img

test -s kernel
test -s ramdisk.cpio

cd "$CUSTOM"
"$MAGISKBOOT" split Image.gz-dtb

test -s kernel
test -s kernel_dtb

cp "$CUSTOM/kernel" "$ORIGINAL/kernel"
cp "$CUSTOM/kernel_dtb" "$ORIGINAL/kernel_dtb"

cd "$ORIGINAL"
"$MAGISKBOOT" repack -n boot.img "$OUTPUT"

test -s "$OUTPUT"

input_size=$(wc -c < boot.img)
output_size=$(wc -c < "$OUTPUT")
test "$output_size" -le "$input_size"

cp "$OUTPUT" "$VERIFY/"

cd "$VERIFY"
"$MAGISKBOOT" unpack -n "$OUTPUT"

test -s kernel
test -s kernel_dtb

expected_kernel=$(sha256sum "$CUSTOM/kernel" | awk '{print $1}')
actual_kernel=$(sha256sum kernel | awk '{print $1}')
expected_dtb=$(sha256sum "$CUSTOM/kernel_dtb" | awk '{print $1}')
actual_dtb=$(sha256sum kernel_dtb | awk '{print $1}')

test "$expected_kernel" = "$actual_kernel"
test "$expected_dtb" = "$actual_dtb"

echo "REPACK VERIFIED"
echo "input boot image bytes: $input_size"
echo "output boot image bytes: $output_size"
sha256sum "$ORIGINAL/$OUTPUT"
