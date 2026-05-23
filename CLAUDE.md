# kernel-utils — context for future Claude sessions

## What this is

Small toolkit for hacking on Linux kernels (CTF / exploit-dev style) from
a Mac host. The goal is "fun, low-friction kernel compile + boot loop".

Owner is on Apple Silicon macOS. Builds happen inside a Docker container;
QEMU runs on the host.

## How it works today

Installed as a Python package (`pyproject.toml`, hatchling). All scripts
and assets live under `src/kernel_utils/data/`; thin Python entry points
in `src/kernel_utils/cli.py` `os.execvp` into them via `sh`.

`pipx install .` (or `pip install -e .`) puts four commands on `$PATH`:

- **`kdev [path]`** — host launcher. Builds the image (cached) and drops
  the user into a fish prompt at `/work` with `$PWD` (or `path`)
  bind-mounted. Backed by `data/kdev.sh` + `data/Dockerfile`.
- **`krun [bzImage] [initramfs]`** — QEMU launcher with hardened CTF
  settings (SMEP/SMAP/KPTI, gdbstub on :1234, guest:8000 → host:8080).
  Auto-discovers artifacts in `arch/x86/boot/`, `./`, `/work/`,
  `$KU_DATA/`, `/opt/kernel-utils/`. Also baked into the container image
  as `/usr/local/bin/krun`. NIC model selectable via `KU_NIC` env var:
  `e1000` (default, works with most defconfigs) or `virtio` (requires
  `CONFIG_VIRTIO_NET=y` + `CONFIG_VIRTIO_PCI=y` in the guest kernel).
  KASLR selectable via `KASLR` env var: `0` (default, appends `nokaslr`
  to cmdline) or `1` (enables KASLR).
- **`kbuild-initramfs`** — builds `initramfs.cpio.gz` in cwd. Copies
  files from cwd into `/exploit` inside the image.

Other bundled assets:

- **`Dockerfile`** — native arm64 Debian bookworm with kernel build
  deps, fish shell, and an x86_64 cross-toolchain
  (`gcc-x86-64-linux-gnu`). `ARCH=x86_64` and
  `CROSS_COMPILE=x86_64-linux-gnu-` are baked in. Native arm64 +
  cross-toolchain was chosen over `--platform=linux/amd64` emulation for
  speed.
- **`fish_greeting.fish` / `help_msg.fish`** — colored cheat sheet on
  container entry; reprintable via `help_msg`.
- **`disable_random_defconfig_stuff`** — shell script (sed+echo) that
  strips irrelevant subsystems (DRM, wifi, BT, sound, netfilter) and
  enables VirtIO. Run with `sh $KU_CONFIGS/disable_random_defconfig_stuff`
  from inside the kernel tree, then `make olddefconfig`. NOT a kconfig
  fragment — do not `cat >> .config`.
- **`debugging_stuff`** — shell script appending debug-symbol/KGDB/
  KALLSYMS/frame-pointer/SysRq configs to `./.config`. Same usage:
  `sh $KU_CONFIGS/debugging_stuff`.

Typical flow:

```sh
kdev                                   # enter container (mounts $PWD at /work)
# inside:
git clone --depth 1 -b v6.17 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
cd linux
make defconfig
make -j(nproc) bzImage
krun                                   # boots arch/x86/boot/bzImage
```

## Decisions / dead ends (don't relitigate)

- **Tried `tinyclub/linux-lab` + `cloud-lab`. Rejected.** GNU sed/coreutils
  assumptions broke immediately on Mac; would have kept breaking on
  /var/lock, Docker bridge networking, etc. Death by a thousand cuts.
- **Considered Homebrew tap. Rejected.** Owner prefers
  `git clone && ./install.sh` (fzf/oh-my-zsh style) over brew tap.
- **amd64 emulation rejected** in favor of native arm64 + cross-toolchain.

## Next planned work (parked)

Drop build artifacts (`bzImage`, `initramfs.cpio.gz`) from the repo via
`.gitignore`.

## House rules for working here

- **Owner prefers terse responses.** Don't summarize what was just done
  unless asked; the diff speaks for itself.
- **Don't run risky/destructive commands without asking.** `rm -rf`,
  `hdiutil` create/detach, anything that mutates files outside the repo
  needs explicit confirmation, even in auto mode.
- **Don't yak-shave.** If the user asks for X, do X — don't also refactor
  Y, add Z helper, or invent abstractions for hypothetical future
  requirements.
- **Mac portability matters.** This repo is Mac-first. BSD vs GNU tool
  differences (sed, readlink, date, stat) bite — write portable shell or
  call out the assumption.
- **Architecture: Apple Silicon → arm64 container → x86_64 cross-build.**
  If you ever switch back to amd64 emulation, that's a regression.

## Repo location & git

- Working tree: `/Users/daniel/git/kernel-utils`
- Remote: `git@github.com:danbar2003/kernel-utils.git`
- Branch: `master`
