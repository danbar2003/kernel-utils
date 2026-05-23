#!/bin/bash
exec qemu-system-x86_64 \
    -m 1G \
    -smp 4 \
    -cpu kvm64,+smep,+smap \
    -kernel ./bzImage \
    -initrd initramfs.cpio.gz \
    -snapshot \
    -nographic \
    -serial mon:stdio \
    -monitor /dev/null \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8080-:8000 \
    -machine pc \
    -append "console=ttyS0,115200 nokaslr kpti=1 quiet panic=1 earlyprintk=serial" \
    -s
