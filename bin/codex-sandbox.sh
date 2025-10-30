#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# CONFIG
# ============================================================
FIRECRACKER_BIN="$(command -v firecracker || true)"
VIRTIOFSD_BIN=""
VIRTIOFSD_PID=""
FC_PID=""
SNAPSHOT_DIR="${HOME}/.codex-sandbox"
CONTEXT_DIR="${SNAPSHOT_DIR}/context"
VM_KERNEL="${SNAPSHOT_DIR}/vmlinux.bin"
VM_ROOTFS="${SNAPSHOT_DIR}/rootfs.ext4"
WORKDIR="$(pwd)"
SOCK_WORK="/tmp/codex-sock-$$.sock"
API_SOCKET="/tmp/fc-$$.socket"
VSOCK_SOCKET="/tmp/vsock-$$.sock"
AUTO_INSTALL=false
INIT_MODE=false
NO_LOGIN=false
BUSYBOX_VERSION="1.36.1"
ROOTFS_SIZE_MB=64

# ============================================================
# Colors
# ============================================================
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
NC='\033[0m'

# ============================================================
# Help
# ============================================================
show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --init              Recreate VM base image (kernel+rootfs)
  --auto-install      Auto-install missing dependencies
  --no-login          Don't attach to serial console
  --help              Show this help message

Behavior:
  • Mounts current directory into /work inside VM
  • Keeps context in ~/.codex-sandbox/context
  • Builds BusyBox rootfs locally
  • Cleans up VM on exit
EOF
}

# ============================================================
# Dependencies
# ============================================================
check_dep() {
    local dep="$1"
    local pkg="$2"
    if ! command -v "$dep" &>/dev/null; then
        echo "❌ Missing dependency: '${dep}'"
        echo "   👉 Suggested Arch package: ${pkg}"
        MISSING_DEPS=1
        if $AUTO_INSTALL; then
            yay -S --noconfirm "$pkg"
        fi
    fi
}

check_dep_virtiofsd() {
    if command -v virtiofsd &>/dev/null; then
        VIRTIOFSD_BIN="$(command -v virtiofsd)"
    elif [ -x /usr/lib/virtiofsd ]; then
        VIRTIOFSD_BIN="/usr/lib/virtiofsd"
    elif [ -x /usr/lib/qemu/virtiofsd ]; then
        VIRTIOFSD_BIN="/usr/lib/qemu/virtiofsd"
    else
        echo "❌ Missing dependency: 'virtiofsd' (qemu-base)"
        MISSING_DEPS=1
        if $AUTO_INSTALL; then
            yay -S --noconfirm qemu-base
        fi
    fi
}

# ============================================================
# Context
# ============================================================
ensure_context() {
    if [ ! -d "$CONTEXT_DIR" ]; then
        echo -e "${YEL}🗂  A context directory was not found at:${NC} $CONTEXT_DIR"
        read -rp "Would you like to create it? (y/N) " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            mkdir -p "$CONTEXT_DIR"
            echo -e "${GRN}✅ Context directory created.${NC}"
        else
            echo -e "${RED}🚨 Cannot run without context directory.${NC}"
            exit 1
        fi
    fi
}

# ============================================================
# Kernel download
# ============================================================
fetch_kernel() {
    if [ ! -f "$VM_KERNEL" ] || $INIT_MODE; then
        echo -e "${YEL}⬇️  Downloading Firecracker kernel image...${NC}"
        curl -L -o "$VM_KERNEL" \
            "https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin"
        file "$VM_KERNEL" | grep -q "ELF" || {
            echo -e "${RED}❌ Invalid kernel downloaded${NC}"
            rm -f "$VM_KERNEL"
            exit 1
        }
    fi
}

# ============================================================
# Build BusyBox rootfs
# ============================================================
build_rootfs() {
    local BUILD_DIR="${SNAPSHOT_DIR}/build"
    local BUSYBOX_DIR="${SNAPSHOT_DIR}/busybox-src"
    local BUSYBOX_TAR="${SNAPSHOT_DIR}/busybox.tar.bz2"

    if [ -f "$VM_ROOTFS" ] && ! $INIT_MODE; then
        return
    fi

    echo -e "${YEL}🧰 Building BusyBox rootfs...${NC}"
    mkdir -p "$SNAPSHOT_DIR"

    # Download BusyBox
    if [ ! -d "$BUSYBOX_DIR" ]; then
        echo -e "${YEL}⬇️  Downloading BusyBox ${BUSYBOX_VERSION}...${NC}"
        curl -L -o "$BUSYBOX_TAR" \
            "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
        mkdir -p "$BUSYBOX_DIR"
        tar -xf "$BUSYBOX_TAR" -C "$BUSYBOX_DIR" --strip-components=1
    fi

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,home,tmp}

    pushd "$BUSYBOX_DIR" >/dev/null
    make defconfig >/dev/null

    # Enable static linking
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

    # Force-disable tc and related stuff
    for sym in \
        TC \
        FEATURE_TC_INGRESS \
        FEATURE_TC_SCHEDULER \
        FEATURE_TC_ACTIONS \
        FEATURE_TC_BPF \
        FEATURE_TC_PEDIT \
        FEATURE_TC_POLICE \
        FEATURE_TC_MIRRED \
    ; do
        scripts/config -d "$sym" 2>/dev/null || sed -i "/^CONFIG_${sym}=.*/d" .config
        echo "CONFIG_${sym}=n" >> .config
    done

    make olddefconfig >/dev/null
    make -j"$(nproc)" >/dev/null
    make install CONFIG_PREFIX="$BUILD_DIR" >/dev/null
    popd >/dev/null

    sudo mknod -m 666 "$BUILD_DIR/dev/null" c 1 3 || true
    sudo mknod -m 666 "$BUILD_DIR/dev/zero" c 1 5 || true
    sudo mknod -m 666 "$BUILD_DIR/dev/tty" c 5 0 || true
    sudo mknod -m 600 "$BUILD_DIR/dev/console" c 5 1 || true

    cat <<'EOF' > "$BUILD_DIR/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo "🔥 Minimal BusyBox rootfs ready!"
exec /bin/sh
EOF
    chmod +x "$BUILD_DIR/init"

    dd if=/dev/zero of="$VM_ROOTFS" bs=1M count=$ROOTFS_SIZE_MB status=none
    mkfs.ext4 -F "$VM_ROOTFS" >/dev/null
    TMPMNT=$(mktemp -d)
    sudo mount -o loop "$VM_ROOTFS" "$TMPMNT"
    sudo cp -a "$BUILD_DIR"/. "$TMPMNT"/
    sudo umount "$TMPMNT"
    rmdir "$TMPMNT"

    echo -e "${GRN}✅ Rootfs built: $VM_ROOTFS${NC}"
}

# ============================================================
# Cleanup
# ============================================================
cleanup() {
    if [ -n "${VIRTIOFSD_PID}" ]; then
        kill "$VIRTIOFSD_PID" 2>/dev/null || true
    fi
    if [ -n "${FC_PID}" ]; then
        kill "$FC_PID" 2>/dev/null || true
    fi
    rm -f "$SOCK_WORK" "$API_SOCKET" "$VSOCK_SOCKET"
}
trap cleanup EXIT

# ============================================================
# Parse args
# ============================================================
MISSING_DEPS=0
for arg in "$@"; do
    case "$arg" in
        --auto-install) AUTO_INSTALL=true ;;
        --init) INIT_MODE=true ;;
        --no-login) NO_LOGIN=true ;;
        --help) show_help; exit 0 ;;
    esac
done

# ============================================================
# Check deps
# ============================================================
check_dep firecracker firecracker
check_dep curl curl
check_dep socat openbsd-netcat
check_dep_virtiofsd

if [ $MISSING_DEPS -ne 0 ]; then
    echo -e "\n🚨 Some dependencies are missing. Install with yay or use --auto-install."
    exit 1
fi

# ============================================================
# Init
# ============================================================
fetch_kernel
build_rootfs
ensure_context

# ============================================================
# Start virtiofsd
# ============================================================
"$VIRTIOFSD_BIN" --socket-path="$SOCK_WORK" --shared-dir="$WORKDIR" --cache=never &
VIRTIOFSD_PID=$!
sleep 0.5

# ============================================================
# Start Firecracker
# ============================================================
firecracker --api-sock "$API_SOCKET" --no-seccomp &
FC_PID=$!
sleep 0.5

curl -s -X PUT --unix-socket "$API_SOCKET" -H 'Content-Type: application/json' \
    -d '{"vcpu_count":1,"mem_size_mib":512,"smt":false}' http://localhost/machine-config

curl -s -X PUT --unix-socket "$API_SOCKET" -H 'Content-Type: application/json' \
    -d "{\"kernel_image_path\":\"$VM_KERNEL\",\"boot_args\":\"console=ttyS0 reboot=k panic=1 pci=off\"}" \
    http://localhost/boot-source

curl -s -X PUT --unix-socket "$API_SOCKET" -H 'Content-Type: application/json' \
    -d "{\"drive_id\":\"rootfs\",\"path_on_host\":\"$VM_ROOTFS\",\"is_root_device\":true,\"is_read_only\":false}" \
    http://localhost/drives/rootfs

curl -s -X PUT --unix-socket "$API_SOCKET" -H 'Content-Type: application/json' \
    -d "{\"guest_cid\":3,\"uds_path\":\"$VSOCK_SOCKET\"}" \
    http://localhost/vsock

curl -s -X PUT --unix-socket "$API_SOCKET" -H 'Content-Type: application/json' \
    -d '{"action_type":"InstanceStart"}' \
    http://localhost/actions

echo -e "${GRN}✅ VM started.${NC}"
echo -e "💻 Mounted: ${YEL}${WORKDIR}${NC} → /work"
echo -e "🧠 Context: ${YEL}${CONTEXT_DIR}${NC}"
echo -e "🧼 VM destroyed on exit"

if ! $NO_LOGIN; then
    socat -,raw,echo=0 UNIX-CONNECT:"$VSOCK_SOCKET"
fi
