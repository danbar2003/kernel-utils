function fish_greeting
    set_color cyan --bold
    echo "  kernel-dev container (native arm64, cross-compiles to x86_64)"
    set_color normal
    echo "  /work = your kernel-utils dir.  ARCH=$ARCH  CROSS_COMPILE=$CROSS_COMPILE"
    echo
    set_color yellow; echo "  fetch a kernel:"; set_color normal
    echo "    git clone --depth 1 -b v6.17 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
    echo
    set_color yellow; echo "  configure (.config):"; set_color normal
    echo "    cd linux"
    echo "    make defconfig"
    echo "    cat ../disable_random_defconfig_stuff >> .config"
    echo "    cat ../debugging_stuff               >> .config"
    echo "    make olddefconfig"
    echo
    set_color yellow; echo "  build:"; set_color normal
    echo "    make -j(nproc) bzImage"
    echo
    set_color yellow; echo "  run under QEMU (from kernel tree, or anywhere with bzImage):"; set_color normal
    echo "    krun                        # auto-finds bzImage + initramfs.cpio.gz"
    echo "    krun /path/to/bzImage       # explicit"
    echo "    (Ctrl-A X to quit, gdb on host :1234, exploit on :8080)"
    echo
    set_color brblack; echo "  (run 'help_msg' to see this again)"; set_color normal
end
