# kernel-utils — context for future Claude sessions

## What this is

Small toolkit for hacking on Linux kernels (CTF / exploit-dev style) from
a Mac host. The goal is "fun, low-friction kernel compile + boot loop".

Owner is on Apple Silicon macOS. Builds happen inside a Docker container;
QEMU runs on the host.

## How it works today

- **`Dockerfile`** — native arm64 Debian bookworm with kernel build deps,
  fish shell, and an x86_64 cross-toolchain (`gcc-x86-64-linux-gnu`).
  `ARCH=x86_64` and `CROSS_COMPILE=x86_64-linux-gnu-` are baked in as env
  vars, so plain `make bzImage` cross-compiles automatically. We chose
  native arm64 + cross-toolchain over `--platform=linux/amd64` emulation
  for speed.
- **`kdev`** — host launcher. `./kdev` builds the image (cached) and
  drops the user into a fish prompt at `/work` with `$PWD` bind-mounted.
  Optional arg: `./kdev /some/dir` mounts that instead.
- **`fish_greeting.fish`** — colored cheat sheet shown on container
  entry. Reprintable inside the container by typing `help_msg`.
- **`help_msg.fish`** — defines the `help_msg` fish function.
- **`run.sh`** — host-side QEMU launcher with hardened CTF settings
  (SMEP/SMAP/KPTI, kvm64+mitigations, gdbstub on :1234, exploit delivery
  on :8000 via guest-host port forward). Expects `bzImage` and
  `initramfs.cpio.gz` next to it.
- **`initramfs-builder.sh`** — builds a minimal busybox initramfs
  (`initramfs.cpio.gz`). Includes login support and any local files
  under `/exploit`.
- **`disable_random_defconfig_stuff`** — config fragment that strips
  irrelevant subsystems (DRM, wifi, BT, sound, netfilter) and enables
  VirtIO. Append to `.config` then `make olddefconfig`.
- **`debugging_stuff`** — config fragment for debug symbols, KGDB,
  KALLSYMS, frame pointers, SysRq.

Typical flow:

```sh
./kdev                                 # enter container
# inside:
git clone --depth 1 -b v6.17 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
cd linux
make defconfig
cat ../disable_random_defconfig_stuff >> .config
cat ../debugging_stuff               >> .config
make olddefconfig
make -j(nproc) bzImage
# back on Mac host:
cp linux/arch/x86/boot/bzImage .
./run.sh
```

## Decisions / dead ends (don't relitigate)

- **Tried `tinyclub/linux-lab` + `cloud-lab`. Rejected.** GNU sed/coreutils
  assumptions broke immediately on Mac; would have kept breaking on
  /var/lock, Docker bridge networking, etc. Death by a thousand cuts.
- **Considered Homebrew tap. Rejected.** Owner prefers
  `git clone && ./install.sh` (fzf/oh-my-zsh style) over brew tap.
- **amd64 emulation rejected** in favor of native arm64 + cross-toolchain.

## Next planned work (parked)

Make kernel-utils self-installing so `kdev` works from any directory
without needing to be in the repo. Detailed design lives in
`~/.claude/plans/in-this-dir-there-stateless-finch.md` ("Self-installing
kernel-utils" section).

Summary:
1. Move `kdev` into `bin/kdev`, add portable symlink resolution so it
   can find the Dockerfile via the symlink target.
2. Add `install.sh` that symlinks `bin/kdev` into `$HOME/.local/bin`
   (override via `--prefix=` or `PREFIX=`).
3. Add `uninstall.sh`.
4. Drop build artifacts (`bzImage`, `initramfs.cpio.gz`) from the repo
   via `.gitignore`.
5. Update `README.md` with install instructions.

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
