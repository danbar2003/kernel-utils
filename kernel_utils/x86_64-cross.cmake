# CMake toolchain file: cross-compile to x86_64 on an arm64 build host.
#
# The kernel-utils container runs natively on arm64 but targets an x86_64
# guest kernel. Raw `make`/kbuild are pointed at the cross toolchain via the
# ARCH/CROSS_COMPILE env vars; this file is the cmake equivalent. It is wired
# in as the default via ENV CMAKE_TOOLCHAIN_FILE, so a bare `cmake -B build`
# (e.g. libxdk's build.sh) produces x86_64 objects instead of native arm64.
#
# It only affects cmake invocations -- it does NOT alias gcc/cc, so the kernel
# host tools (objtool, fixdep, extract-cert) still build with native gcc.
#
# To opt out for a one-off native build: `CMAKE_TOOLCHAIN_FILE= cmake ...`.

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER   x86_64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER x86_64-linux-gnu-g++)

# Debian multiarch: the x86_64 headers/libs live alongside the native ones
# (/usr/include, /usr/lib/x86_64-linux-gnu), and the cross gcc already knows
# those paths. Find target libraries/headers there, but keep host programs
# (cmake, make, pkg-config) resolving from the native root.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
