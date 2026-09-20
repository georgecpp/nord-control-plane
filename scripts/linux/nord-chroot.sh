#!/system/bin/sh

set -eu

BUSYBOX=${BUSYBOX:-/data/adb/magisk/busybox}
ROOTFS=${NORD_ROOTFS:-/data/adb/nord-k3s/rootfs}

test "$(id -u)" = 0
test -x "$BUSYBOX"
test -x "$ROOTFS/bin/sh"
test -x "$ROOTFS/usr/bin/env"

if [ "${1:-}" != "--inside-mount-namespace" ]; then
    exec "$BUSYBOX" unshare -m \
        "$0" --inside-mount-namespace "$@"
fi

shift

"$BUSYBOX" mount --make-rprivate /

"$BUSYBOX" mount --rbind /dev "$ROOTFS/dev"
"$BUSYBOX" mount --make-rslave "$ROOTFS/dev"

"$BUSYBOX" mount -t proc proc "$ROOTFS/proc"

"$BUSYBOX" mount --rbind /sys "$ROOTFS/sys"
"$BUSYBOX" mount --make-rslave "$ROOTFS/sys"

"$BUSYBOX" mount -t tmpfs \
    -o mode=0755,nosuid,nodev tmpfs "$ROOTFS/run"

if [ "$#" -eq 0 ]; then
    set -- /bin/bash -l
fi

exec "$BUSYBOX" chroot "$ROOTFS" \
    /usr/bin/env -i \
    HOME=/root \
    USER=root \
    LOGNAME=root \
    HOSTNAME=nord \
    TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$@"
