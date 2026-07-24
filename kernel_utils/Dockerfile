FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture amd64 \
 && apt-get update && apt-get upgrade -y

# Each install RUN refreshes the apt index itself. Debian point releases rotate
# .deb versions off the mirror, so a cached `apt-get update` layer paired with a
# later-rebuilt `apt-get install` layer fetches stale versions and 404s.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential bc bison flex \
      libssl-dev libelf-dev libncurses-dev \
      cpio kmod rsync xz-utils \
      gcc make cmake pkg-config git ca-certificates \
      curl wget vim less file \
      fish

RUN apt-get update && apt-get install -y --no-install-recommends \
      gcc-x86-64-linux-gnu g++-x86-64-linux-gnu binutils-x86-64-linux-gnu \
      qemu-system-x86

RUN apt-get update && apt-get install -y --no-install-recommends \
      libc6-dev:amd64 libstdc++-12-dev:amd64 \
      libkeyutils-dev libkeyutils-dev:amd64 \
 && rm -rf /var/lib/apt/lists/*

# The kernel build needs TWO toolchains:
#   - host tools (objtool, fixdep, extract-cert ...) run on the arm64 build
#     host, so HOSTCC must stay the native gcc.
#   - target code is x86_64, selected via CROSS_COMPILE -> x86_64-linux-gnu-gcc.
# Do NOT alias `gcc`/`cc` or CPATH/LIBRARY_PATH to the x86_64 cross toolchain:
# that hijacks HOSTCC and breaks the host tools (no x86_64 openssl/libelf
# headers are installed). To build an x86_64 userspace exploit, call the
# cross compiler explicitly: `x86_64-linux-gnu-gcc -static exploit.c -o exploit`.
ENV ARCH=x86_64
ENV CROSS_COMPILE=x86_64-linux-gnu-

# cmake does NOT target x86_64 on its own -- left alone it picks the native
# arm64 g++ and produces arm64 objects. Point every cmake build at the cross
# toolchain by default so bare `cmake -B build` (e.g. libxdk's build.sh) emits
# x86_64. This is scoped to cmake only, so it does not hijack HOSTCC above.
# Opt out for a one-off native build with `CMAKE_TOOLCHAIN_FILE= cmake ...`.
COPY x86_64-cross.cmake /opt/kernel-utils/x86_64-cross.cmake
ENV CMAKE_TOOLCHAIN_FILE=/opt/kernel-utils/x86_64-cross.cmake

# --- kernelXDK (Google kernel-research libxdk) ---
# Pre-build libxdk so kernel exploits link with a bare `-lkernelXDK` (no -I/-L,
# nothing to clone or ./build.sh at runtime). It is CROSS-compiled to x86_64 via
# the cmake toolchain file above -- a bare `cmake -B build` emits x86_64 objects,
# so the archive matches the guest kernel, not the arm64 host. Only the library
# target is built (the test binary is skipped). Artifacts land on the paths that
# x86_64-linux-gnu-g++ already searches by default:
#   headers -> /usr/include/xdk/...
#   archive -> /usr/lib/x86_64-linux-gnu/libkernelXDK.a
# The kernelctf target DB is cached under $KU_XDK/db (cmake's configure step
# downloads it; we stash a copy, falling back to curl, non-fatal when offline).
RUN git clone --depth 1 https://github.com/google/kernel-research.git /tmp/kernel-research \
 && cmake -S /tmp/kernel-research/libxdk -B /tmp/xdk-build \
 && cmake --build /tmp/xdk-build --target kernelXDK -j"$(nproc)" \
 && cp -a /tmp/kernel-research/libxdk/include/xdk /usr/include/xdk \
 && install -D /tmp/kernel-research/libxdk/lib/libkernelXDK.a \
              /usr/lib/x86_64-linux-gnu/libkernelXDK.a \
 && mkdir -p /opt/kernelxdk/db \
 && { cp /tmp/kernel-research/libxdk/test/artifacts/kernelctf.kxdb /opt/kernelxdk/db/kernelctf.kxdb 2>/dev/null \
      || curl -fsSL -o /opt/kernelxdk/db/kernelctf.kxdb https://storage.googleapis.com/kernelxdk/db/kernelctf.kxdb \
      || echo "WARN: kernelctf.kxdb not cached (offline build)"; } \
 && rm -rf /tmp/kernel-research /tmp/xdk-build
ENV KU_XDK=/opt/kernelxdk

RUN chsh -s /usr/bin/fish root

RUN mkdir -p /root/.config/fish/functions
COPY fish_greeting.fish /root/.config/fish/functions/fish_greeting.fish
COPY help_msg.fish      /root/.config/fish/functions/help_msg.fish

COPY krun.sh /usr/local/bin/krun
RUN chmod +x /usr/local/bin/krun

COPY disable_random_defconfig_stuff /opt/kernel-utils/disable_random_defconfig_stuff
COPY debugging_stuff                /opt/kernel-utils/debugging_stuff
COPY initramfs.cpio.gz              /opt/kernel-utils/initramfs.cpio.gz
ENV KU_CONFIGS=/opt/kernel-utils

WORKDIR /work
CMD ["/usr/bin/fish", "-l"]
