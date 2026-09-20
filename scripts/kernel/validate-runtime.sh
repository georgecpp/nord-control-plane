#!/system/bin/sh

set -eu

REQUESTED_CONFIG=${1:-/data/local/tmp/requested-k3s.config}
EXPECTED_LOCALVERSION=${EXPECTED_LOCALVERSION:-NordK3s-v0.1.0}
BUSYBOX=${BUSYBOX:-/data/adb/magisk/busybox}
TEST_ROOT=/data/local/tmp/nord-k3s-runtime-test-$$
PIDS_MOUNTED=0
DEVICES_MOUNTED=0
OVERLAY_MOUNTED=0

cleanup() {
    if [ "$OVERLAY_MOUNTED" -eq 1 ]; then
        "$BUSYBOX" umount "$TEST_ROOT/overlay/merged" || true
    fi

    if [ "$DEVICES_MOUNTED" -eq 1 ]; then
        rmdir "$TEST_ROOT/cgroup/devices/probe" 2>/dev/null || true
        "$BUSYBOX" umount "$TEST_ROOT/cgroup/devices" || true
    fi

    if [ "$PIDS_MOUNTED" -eq 1 ]; then
        rmdir "$TEST_ROOT/cgroup/pids/probe" 2>/dev/null || true
        "$BUSYBOX" umount "$TEST_ROOT/cgroup/pids" || true
    fi

    rm -f "$TEST_ROOT.config"
    rm -rf "$TEST_ROOT"
}

trap cleanup EXIT INT TERM

test -x "$BUSYBOX"
test -r /proc/config.gz
test -r "$REQUESTED_CONFIG"

echo "Kernel: $(uname -r)"
case "$(uname -r)" in
    *"$EXPECTED_LOCALVERSION"*) ;;
    *) echo "Unexpected kernel release" >&2; exit 1 ;;
esac

zcat /proc/config.gz > "$TEST_ROOT.config"

while IFS= read -r requested; do
    case "$requested" in
        CONFIG_*=*)
            grep -Fqx "$requested" "$TEST_ROOT.config" || {
                echo "Missing requested option: $requested" >&2
                exit 1
            }
            ;;
        '# CONFIG_KSU is not set')
            grep -Fqx "$requested" "$TEST_ROOT.config" || {
                echo "KernelSU is not disabled" >&2
                exit 1
            }
            ;;
    esac
done < "$REQUESTED_CONFIG"

rm -f "$TEST_ROOT.config"
echo "PASS: requested kernel configuration"

"$BUSYBOX" unshare -pf "$BUSYBOX" sh -c 'test "$$" -eq 1'
echo "PASS: PID namespace"

"$BUSYBOX" unshare -if "$BUSYBOX" sh -c 'exit 0'
echo "PASS: IPC namespace"

"$BUSYBOX" unshare -mf "$BUSYBOX" sh -c 'exit 0'
echo "PASS: mount namespace"

"$BUSYBOX" unshare -nf "$BUSYBOX" sh -c 'exit 0'
echo "PASS: network namespace"

mkdir -p \
    "$TEST_ROOT/cgroup/pids" \
    "$TEST_ROOT/cgroup/devices" \
    "$TEST_ROOT/overlay/lower" \
    "$TEST_ROOT/overlay/upper" \
    "$TEST_ROOT/overlay/work" \
    "$TEST_ROOT/overlay/merged"

if grep -qw pids /sys/fs/cgroup/cgroup.controllers 2>/dev/null; then
    echo "PASS: PIDs controller available in cgroup v2"
else
    "$BUSYBOX" mount -t cgroup -o pids pids "$TEST_ROOT/cgroup/pids"
    PIDS_MOUNTED=1
    test -f "$TEST_ROOT/cgroup/pids/pids.max"
    mkdir "$TEST_ROOT/cgroup/pids/probe"
    echo 64 > "$TEST_ROOT/cgroup/pids/probe/pids.max"
    test "$(cat "$TEST_ROOT/cgroup/pids/probe/pids.max")" = 64
    rmdir "$TEST_ROOT/cgroup/pids/probe"
    echo "PASS: PIDs cgroup v1"
fi

"$BUSYBOX" mount -t cgroup -o devices devices "$TEST_ROOT/cgroup/devices"
DEVICES_MOUNTED=1
test -f "$TEST_ROOT/cgroup/devices/devices.allow"
mkdir "$TEST_ROOT/cgroup/devices/probe"
test -f "$TEST_ROOT/cgroup/devices/probe/devices.allow"
rmdir "$TEST_ROOT/cgroup/devices/probe"
echo "PASS: devices cgroup"

printf '%s\n' base > "$TEST_ROOT/overlay/lower/base.txt"
"$BUSYBOX" mount -t overlay overlay \
    -o "lowerdir=$TEST_ROOT/overlay/lower,upperdir=$TEST_ROOT/overlay/upper,workdir=$TEST_ROOT/overlay/work" \
    "$TEST_ROOT/overlay/merged"
OVERLAY_MOUNTED=1
test "$(cat "$TEST_ROOT/overlay/merged/base.txt")" = base
printf '%s\n' written > "$TEST_ROOT/overlay/merged/written.txt"
test "$(cat "$TEST_ROOT/overlay/upper/written.txt")" = written
echo "PASS: OverlayFS"

echo "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo "IPv6 forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
echo "PASS: kernel runtime validation"
