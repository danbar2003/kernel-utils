#!/bin/sh
# krun [bzImage] [initramfs]
# Boots a kernel under QEMU with hardened CTF settings:
#   SMEP, SMAP, KPTI, nokaslr, gdbstub on :1234,
#   guest:8000 forwarded to host:8080.
#
# Defaults if args omitted:
#   bzImage:   arch/x86/boot/bzImage  -> ./bzImage  -> /work/bzImage
#   initramfs: ./initramfs.cpio.gz    -> /work/initramfs.cpio.gz
set -e

BZ="${1:-}"
if [ -z "$BZ" ]; then
  for c in arch/x86/boot/bzImage ./bzImage /work/bzImage; do
    [ -f "$c" ] && BZ="$c" && break
  done
fi
[ -z "$BZ" ] && { echo "krun: no bzImage found (try: krun /path/to/bzImage)" >&2; exit 1; }

INITRD="${2:-}"
if [ -z "$INITRD" ]; then
  for c in ./initramfs.cpio.gz /work/initramfs.cpio.gz "$KU_DATA/initramfs.cpio.gz" /opt/kernel-utils/initramfs.cpio.gz; do
    [ -f "$c" ] && INITRD="$c" && break
  done
fi
[ -z "$INITRD" ] && { echo "krun: no initramfs.cpio.gz found" >&2; exit 1; }

NIC="${KU_NIC:-e1000}"
case "$NIC" in
  virtio) NIC=virtio-net-pci ;;
  e1000|virtio-net-pci) ;;
  *) echo "krun: unknown KU_NIC='$NIC' (use e1000 or virtio)" >&2; exit 1 ;;
esac

case "${KASLR:-0}" in
  0|"") KASLR_ARG=nokaslr ;;
  1)    KASLR_ARG=kaslr ;;
  *) echo "krun: unknown KASLR='$KASLR' (use 0 or 1)" >&2; exit 1 ;;
esac

echo "krun: bzImage=$BZ  initrd=$INITRD  nic=$NIC  kaslr=${KASLR:-0}  (Ctrl-A X to quit, gdb on :1234)"

exec qemu-system-x86_64 \
    -m 1G -smp 4 \
    -cpu kvm64,+smep,+smap \
    -kernel "$BZ" \
    -initrd "$INITRD" \
    -snapshot \
    -nographic \
    -serial mon:stdio \
    -monitor /dev/null \
    -netdev user,id=n0,hostfwd=tcp::8080-:8000 \
    -device "$NIC,netdev=n0" \
    -machine pc \
    -append "console=ttyS0,115200 $KASLR_ARG kpti=1 quiet panic=1 earlyprintk=serial" \
    -s
