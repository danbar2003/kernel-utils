#!/bin/bash
set -e

ARCH="${1:-x86_64}"
OUTPUT="initramfs.cpio.gz"
BUSYBOX_URL="https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR=$(mktemp -d)

echo "[*] Working directory: $WORKDIR"
echo "[*] Building initramfs for $ARCH..."

mkdir -p "$WORKDIR/initramfs"/{bin,sbin,usr/bin,usr/sbin,etc,dev,proc,sys,tmp,root}
mkdir -p "$WORKDIR/initramfs/lib64" 2>/dev/null || true

echo "[*] Downloading busybox binary..."
if command -v busybox &>/dev/null; then
    cp "$(command -v busybox)" "$WORKDIR/initramfs/bin/busybox"
elif [ "$ARCH" = "x86_64" ]; then
    if curl -fsSL "$BUSYBOX_URL" -o "$WORKDIR/initramfs/bin/busybox"; then
        :
    else
        echo "[!] Download failed, trying apt..."
        apt-get install -y busybox-static 2>/dev/null || true
        cp "$(command -v busybox)" "$WORKDIR/initramfs/bin/busybox" 2>/dev/null || true
    fi
fi

if [ ! -f "$WORKDIR/initramfs/bin/busybox" ]; then
    echo "[!] Warning: busybox binary not found, creating minimal shell wrapper"
    cat > "$WORKDIR/initramfs/bin/sh" << 'SHELL'
#!/bin/sh
echo "Busybox not available - minimal initramfs"
exec /bin/sh
SHELL
    chmod +x "$WORKDIR/initramfs/bin/sh"
else
    chmod +x "$WORKDIR/initramfs/bin/busybox"
    echo "[*] Symlinking busybox applets..."
    
    for applet in sh ash cat chmod cp dd echo grep gzip hostname init ln ls mkdir mdev mknod mount ps pwd rm sed sh sleep switch_root sysctl tar umount uname yes free df top kill killall sleep date touch which id env cut awk sed tr head tail sort uniq wc strings printf test true false ip route nslookup wget curl ping su login chroot; do
        [ -L "$WORKDIR/initramfs/bin/$applet" ] || ln -sf busybox "$WORKDIR/initramfs/bin/$applet" 2>/dev/null || true
    done
    
    echo "[*] Creating passwd file..."
    mkdir -p "$WORKDIR/initramfs/etc"
    echo "root:x:0:0:root:/root:/bin/sh" > "$WORKDIR/initramfs/etc/passwd"
    echo "user:x:1000:1000:user:/home:/bin/sh" >> "$WORKDIR/initramfs/etc/passwd"
fi

for dir in /bin /sbin /usr/bin /usr/sbin; do
    [ -L "$WORKDIR/initramfs$dir" ] || ln -sf bin "$WORKDIR/initramfs$dir" 2>/dev/null || true
done

echo "[*] Creating device nodes..."
mknod -m 666 "$WORKDIR/initramfs/dev/null" c 1 3 2>/dev/null || true
mknod -m 622 "$WORKDIR/initramfs/dev/console" c 5 1 2>/dev/null || true
mknod -m 666 "$WORKDIR/initramfs/dev/tty" c 5 0 2>/dev/null || true
mknod -m 666 "$WORKDIR/initramfs/dev/tty0" c 4 0 2>/dev/null || true
mknod -m 666 "$WORKDIR/initramfs/dev/zero" c 1 5 2>/dev/null || true
mknod -m 666 "$WORKDIR/initramfs/dev/urandom" c 1 9 2>/dev/null || true

echo "[*] Copying files from current directory..."
mkdir -p "$WORKDIR/initramfs/exploit"
for f in "$SCRIPT_DIR"/*; do
    [ -f "$f" ] || continue
    basename="$(basename "$f")"
    [ "$basename" = "$(basename "$0")" ] && continue
    [ "$basename" = "$OUTPUT" ] && continue
    [[ "$basename" =~ \.gz$ ]] && continue
    cp "$f" "$WORKDIR/initramfs/exploit/"
    echo "    Added: $basename"
done

echo "[*] Creating init script..."
cat > "$WORKDIR/initramfs/init" << 'INIT'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp

echo "localhost" > /etc/hostname

ip link set eth0 up
ip addr add 10.0.2.15/24 dev eth0
ip route add default via 10.0.2.2

echo "=== Initramfs ready ==="
echo "IP: 10.0.2.15/24"
echo "Gateway: 10.0.2.2"
echo "Mount: /dev/sda1 on /mnt"
echo ""
echo "Available commands: su, login, sh"
echo "Run 'su - user' to login as user 1000"
echo ""

if [ -n "$USER_UID" ]; then
    su - "#$USER_UID"
else
    exec /bin/sh
fi
INIT

chmod +x "$WORKDIR/initramfs/init"

echo "[*] Creating cpio archive..."
cd "$WORKDIR/initramfs"
find . -print0 | cpio --null -o -H newc 2>/dev/null | gzip -9 > "$WORKDIR/$OUTPUT"

cp "$WORKDIR/$OUTPUT" "$SCRIPT_DIR/"

SIZE=$(du -h "$SCRIPT_DIR/$OUTPUT" | cut -f1)
echo "[✓] Created $OUTPUT ($SIZE)"
echo ""
echo "Usage with QEMU:"
echo "  qemu-system-x86_64 -kernel /path/to/vmlinuz -initrd $OUTPUT -nographic"
echo ""
echo "Inside VM:"
echo "  wget http://10.0.2.2:8000/<file> -O /tmp/<file>"