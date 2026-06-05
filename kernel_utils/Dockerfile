FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture amd64 \
 && apt-get update && apt-get upgrade -y

RUN apt-get install -y --no-install-recommends \
      build-essential bc bison flex \
      libssl-dev libelf-dev libncurses-dev \
      cpio kmod rsync xz-utils \
      gcc make git ca-certificates \
      curl wget vim less file \
      fish

RUN apt-get install -y --no-install-recommends \
      gcc-x86-64-linux-gnu g++-x86-64-linux-gnu binutils-x86-64-linux-gnu \
      qemu-system-x86

RUN apt-get install -y --no-install-recommends \
      libc6-dev:amd64 libstdc++-12-dev:amd64 \
      libkeyutils-dev libkeyutils-dev:amd64 \
 && rm -rf /var/lib/apt/lists/*

ENV ARCH=x86_64
ENV CROSS_COMPILE=x86_64-linux-gnu-
RUN mkdir -p /usr/local/x86-cross/bin \
 && for tool in gcc g++ ld ar strip objdump objcopy nm ranlib readelf; do \
      ln -s /usr/bin/x86_64-linux-gnu-$tool /usr/local/x86-cross/bin/$tool; \
    done \
 && ln -s /usr/bin/x86_64-linux-gnu-gcc /usr/local/x86-cross/bin/cc \
 && ln -s /usr/bin/x86_64-linux-gnu-g++ /usr/local/x86-cross/bin/c++
ENV PATH=/usr/local/x86-cross/bin:$PATH
ENV LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
ENV CPATH=/usr/include/x86_64-linux-gnu

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
