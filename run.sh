#!/bin/bash
exec qemu-system-x86_64 \
    -m 1G \
    -smp 4 \
    -cpu kvm64,+smep,+smap \
    -kernel ./linux-6.12.54/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -snapshot \
    -nographic \
    -serial mon:stdio \
    -monitor /dev/null \
    -net nic,model=rtl8139 \
    -net user,hostfwd=tcp::8080-:8000 \
    -machine pc \
    -append "console=ttyS0,115200 kaslr kpti=1 quiet panic=1 earlyprintk=serial" \
    -s
