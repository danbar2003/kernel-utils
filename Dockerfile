FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential bc bison flex \
      libssl-dev libelf-dev libncurses-dev \
      cpio kmod rsync xz-utils \
      gcc make git ca-certificates \
      curl wget vim less file \
      fish \
      gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu \
 && rm -rf /var/lib/apt/lists/*

ENV ARCH=x86_64
ENV CROSS_COMPILE=x86_64-linux-gnu-

RUN chsh -s /usr/bin/fish root

RUN mkdir -p /root/.config/fish/functions
COPY fish_greeting.fish /root/.config/fish/functions/fish_greeting.fish
COPY help_msg.fish      /root/.config/fish/functions/help_msg.fish

WORKDIR /work
CMD ["/usr/bin/fish", "-l"]
