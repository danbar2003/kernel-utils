import os
import sys

from . import DATA_DIR


def _exec(script_name: str) -> None:
    path = DATA_DIR / script_name
    os.environ.setdefault("KU_DATA", str(DATA_DIR))
    os.execvp("sh", ["sh", str(path), *sys.argv[1:]])


def kdev() -> None:
    _exec("kdev.sh")


def krun() -> None:
    _exec("krun.sh")


def kbuild_initramfs() -> None:
    _exec("initramfs-builder.sh")
