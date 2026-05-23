# kernel-utils

Toolkit for hacking on Linux kernels (CTF / exploit-dev) from a Mac host.

## Install

```sh
pipx install .          # or: pip install -e .
```

Installs three entry points on `$PATH`:

- `kdev [path]` — build + enter the kernel-build Docker container. Mounts
  `$PWD` (or `path`) at `/work`.
- `krun [bzImage] [initramfs]` — boot a kernel under QEMU with hardened
  CTF settings (SMEP/SMAP/KPTI, gdbstub on :1234, guest:8000 →
  host:8080). Auto-discovers `arch/x86/boot/bzImage`, `./bzImage`,
  `./initramfs.cpio.gz` in cwd.
- `kbuild-initramfs` — builds `initramfs.cpio.gz` in cwd; copies files
  from cwd into `/exploit` inside the image.

### Environment variables

- `KU_NIC` — NIC model used by `krun`. `e1000` (default) or `virtio`
  (alias for `virtio-net-pci`). Pick `virtio` only if your kernel has
  `CONFIG_VIRTIO_NET=y` and `CONFIG_VIRTIO_PCI=y`; otherwise `eth0`
  won't appear in the guest.
- `KASLR` — `0` (default) appends `nokaslr` to the kernel cmdline,
  matching the CTF-friendly default. `1` enables KASLR.

  ```sh
  KU_NIC=virtio KASLR=1 krun
  ```

## Typical flow

```sh
mkdir ~/kernel-work && cd ~/kernel-work
kdev                                   # enter container, $PWD mounted at /work
# inside:
git clone --depth 1 -b v6.17 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
cd linux
make defconfig
make -j(nproc) bzImage
krun                                   # boots arch/x86/boot/bzImage
```

## Within the qemu

```
rm exploit; wget http://10.0.2.2:8000/exploit && chmod +x ./exploit
```
