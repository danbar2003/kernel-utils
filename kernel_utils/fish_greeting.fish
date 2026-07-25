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
    echo "    sh \$KU_CONFIGS/disable_random_defconfig_stuff   # sed/echo into .config"
    echo "    sh \$KU_CONFIGS/debugging_stuff                   # appends debug configs"
    echo "    make olddefconfig"
    echo
    set_color yellow; echo "  build:"; set_color normal
    echo "    make -j(nproc) bzImage"
    echo
    set_color yellow; echo "  compile an x86_64 exploit (cc/gcc here are the arm64 host tools):"; set_color normal
    echo "    x86_64-linux-gnu-gcc -static exploit.c -o exploit"
    echo
    set_color yellow; echo "  kernelXDK is prebuilt -- link with a bare -lkernelXDK (no -I/-L):"; set_color normal
    echo "    x86_64-linux-gnu-g++ -static -std=gnu++17 *.c *.cpp -lkernelXDK -o exploit"
    echo "    gen_kxdb vmlinux               # build target_db.kxdb from your vmlinux"
    echo "    gen_kxdb vmlinux out.kxdb      # custom output path"
    echo
    set_color yellow; echo "  run under QEMU (from kernel tree, or anywhere with bzImage):"; set_color normal
    echo "    krun                        # auto-finds bzImage + initramfs.cpio.gz"
    echo "    krun /path/to/bzImage       # explicit"
    echo "    (Ctrl-A X to quit, gdb on host :1234, exploit on :8080)"
    echo
    set_color brblack; echo "  (run 'help_msg' to see this again)"; set_color normal
end
