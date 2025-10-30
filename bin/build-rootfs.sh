#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${HOME}/.codex-sandbox"
ROOTFS_FILE="${ROOTFS_DIR}/rootfs.ext4"
ROOTFS_SIZE_MB=64
BUSYBOX_VERSION="1.36.1"

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================
# Check dependencies
# ============================================================
for cmd in curl tar dd mkfs.ext4 mke2fs chroot; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}❌ Missing required tool: $cmd${NC}"
        exit 1
    fi
done

mkdir -p "$ROOTFS_DIR"

# ============================================================
# Download busybox if needed
# ============================================================
BUSYBOX_TAR="$ROOTFS_DIR/busybox.tar.bz2"
BUSYBOX_DIR="$ROOTFS_DIR/busybox-root"

if [ ! -d "$BUSYBOX_DIR" ]; then
    echo -e "${YELLOW}⬇️  Downloading BusyBox ${BUSYBOX_VERSION}...${NC}"
    curl -L -o "$BUSYBOX_TAR" "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
    mkdir -p "$BUSYBOX_DIR"
    tar -xf "$BUSYBOX_TAR" -C "$BUSYBOX_DIR" --strip-components=1
fi

# ============================================================
# Create minimal rootfs structure
# ============================================================
echo -e "${YELLOW}📦 Creating minimal root filesystem...${NC}"
BUILD_DIR="$ROOTFS_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,home,tmp}

# Build busybox static binary
pushd "$BUSYBOX_DIR" >/dev/null
make defconfig >/dev/null
# Enable static linking
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make -j"$(nproc)" >/dev/null
make install CONFIG_PREFIX="$BUILD_DIR" >/dev/null
popd >/dev/null

# Create essential device nodes
sudo mknod -m 666 "$BUILD_DIR/dev/null" c 1 3
sudo mknod -m 666 "$BUILD_DIR/dev/zero" c 1 5
sudo mknod -m 666 "$BUILD_DIR/dev/tty" c 5 0
sudo mknod -m 600 "$BUILD_DIR/dev/console" c 5 1

# Basic init
cat <<'EOF' > "$BUILD_DIR/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo "🔥 Minimal BusyBox rootfs ready!"
exec /bin/sh
EOF
chmod +x "$BUILD_DIR/init"

# ============================================================
# Create ext4 image
# ============================================================
echo -e "${YELLOW}🧰 Creating ext4 image...${NC}"
dd if=/dev/zero of="$ROOTFS_FILE" bs=1M count=$ROOTFS_SIZE_MB status=none
mkfs.ext4 -F "$ROOTFS_FILE" >/dev/null

# Mount and copy rootfs
TMPMNT="$(mktemp -d)"
sudo mount -o loop "$ROOTFS_FILE" "$TMPMNT"
sudo cp -a "$BUILD_DIR"/. "$TMPMNT"/
sudo umount "$TMPMNT"
rmdir "$TMPMNT"

echo -e "${GREEN}✅ Rootfs image created at:${NC} $ROOTFS_FILE"
echo -e "${GREEN}ℹ️  You can now run:${NC} ./codex-sandbox.sh --no-login"
