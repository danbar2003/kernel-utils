FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# BUILD_LIBXDK_FROM_SOURCE: if "true", build libxdk from main branch instead of
# downloading v0.1 binary. Builds include newer APIs (leak_kaslr_base,
# SetKernelPageCount, GetKernelPageCount). Set via: docker build --build-arg BUILD_LIBXDK_FROM_SOURCE=false
ARG BUILD_LIBXDK_FROM_SOURCE=true

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

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip binutils \
 && pip3 install --break-system-packages pydantic==2.10.4 pyelftools ROPgadget \
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
# Two paths: (1) download v0.1 binary (default, fast, limited API), or
# (2) build from main branch source (slower, full API including leak_kaslr_base).
# Toggle with: docker build --build-arg BUILD_LIBXDK_FROM_SOURCE=true
#
# Artifacts land on the paths that x86_64-linux-gnu-g++ already searches by default:
#   headers -> /usr/include/xdk/...
#   archive -> /usr/lib/x86_64-linux-gnu/libkernelXDK.a
RUN mkdir -p /opt/kernelxdk/db && \
    if [ "$BUILD_LIBXDK_FROM_SOURCE" = "true" ]; then \
      git clone --depth 1 https://github.com/google/kernel-research.git /tmp/kernel-research && \
      cmake -S /tmp/kernel-research/libxdk -B /tmp/xdk-build \
            -DCMAKE_TOOLCHAIN_FILE=/opt/kernel-utils/x86_64-cross.cmake && \
      cmake --build /tmp/xdk-build --target kernelXDK -j"$(nproc)" && \
      cp -a /tmp/kernel-research/libxdk/include/xdk /usr/include/xdk && \
      install -D /tmp/kernel-research/libxdk/lib/libkernelXDK.a \
                  /usr/lib/x86_64-linux-gnu/libkernelXDK.a && \
      cp -a /tmp/kernel-research/kxdb_tool /opt/kernelxdk/kxdb_tool && \
      cp -a /tmp/kernel-research/rop_generator /opt/kernelxdk/rop_generator && \
      rm -rf /tmp/kernel-research /tmp/xdk-build; \
    else \
      mkdir -p /tmp/libxdk && \
      wget -qO - https://github.com/google/kernel-research/releases/download/libxdk%2Fv0.1/libxdk-v0.1.tar.gz \
           | tar -xz -C /tmp/libxdk && \
      cp -a /tmp/libxdk/include/xdk /usr/include/xdk && \
      install -D /tmp/libxdk/lib/libkernelXDK.a \
                  /usr/lib/x86_64-linux-gnu/libkernelXDK.a && \
      rm -rf /tmp/libxdk && \
      git clone --depth 1 https://github.com/google/kernel-research.git /tmp/kernel-research && \
      cp -a /tmp/kernel-research/kxdb_tool /opt/kernelxdk/kxdb_tool && \
      cp -a /tmp/kernel-research/rop_generator /opt/kernelxdk/rop_generator && \
      rm -rf /tmp/kernel-research; \
    fi

ENV KU_XDK=/opt/kernelxdk

RUN chsh -s /usr/bin/fish root

RUN mkdir -p /root/.config/fish/functions
COPY fish_greeting.fish /root/.config/fish/functions/fish_greeting.fish
COPY help_msg.fish      /root/.config/fish/functions/help_msg.fish

COPY krun.sh /usr/local/bin/krun
COPY gen_kxdb /usr/local/bin/gen_kxdb
RUN chmod +x /usr/local/bin/krun /usr/local/bin/gen_kxdb

COPY disable_random_defconfig_stuff /opt/kernel-utils/disable_random_defconfig_stuff
COPY debugging_stuff                /opt/kernel-utils/debugging_stuff
COPY initramfs.cpio.gz              /opt/kernel-utils/initramfs.cpio.gz
ENV KU_CONFIGS=/opt/kernel-utils

WORKDIR /work
CMD ["/usr/bin/fish", "-l"]
