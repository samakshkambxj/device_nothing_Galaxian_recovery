# Galaxian prebuilt binaries

These files are extracted from the stock Nothing OS 4.1 firmware for the
Nothing Phone (3a) Lite (`Galaxian`, model `A001T`, MT6878), build
`B4.1-261029-1756`. They let the recovery build run without asking every user
to unpack the same firmware first.

| Path | Contents |
| --- | --- |
| `Image.lz4` | LZ4-compressed arm64 kernel from stock `boot.img` |
| `dtbo.img` | stock DTBO image |
| `dtbs/mt6878.dtb` | the single FDT from the stock `vendor_boot` DTB table |
| `vendor_boot/*.ko` | platform kernel modules from the stock `vendor_boot` ramdisk |
| `vendor_boot/modules.load` | stock first-stage module list |
| `vendor_boot/modules.load.recovery` | stock recovery module list |
| `vendor/{ft3683g,bootinfo,touchpanel_event_notify}.ko` | touch modules from stock `vendor_dlkm` |

The final flashable image is still built from your own stock `vendor_boot.img`
by `scripts/package-vendor-boot.sh`. No full boot or vendor_boot image is
shipped here, and no vendor userspace, Trustonic driver, key material or other
proprietary application blob is included.

## Source and licensing

The kernel and kernel modules are Linux kernel binaries. Every module in
`vendor_boot/` and `vendor/` reports one of `GPL v2`, `GPL`,
`GPL and additional rights`, or `Dual BSD/GPL`; none is marked proprietary.

The corresponding source is published by Nothing Technology Limited:

- <https://github.com/NothingOSS/android_kernel_6.1_nothing_mt6878>
- <https://github.com/NothingOSS/android_kernel_modules_nothing_mt6878>
- <https://github.com/NothingOSS/android_kernel_device_modules_6.1_nothing_mt6878>

The Linux kernel is licensed under GPL-2.0; device tree files are generally
GPL-2.0 or BSD-licensed. See the source repositories and the files' own module
metadata for the exact terms. Nothing's kernel source is the authoritative
source for these binaries; this directory merely carries the compiled output
from the matching stock firmware.

Nothing Phone and Nothing OS are trademarks of Nothing Technology Limited.
This project is unofficial and is not affiliated with or endorsed by Nothing.

## Regenerating

With a stock dump for the same firmware:

```bash
export TMPDIR=$HOME/tmp-galaxian-build
MAGISKBOOT=/path/to/magiskboot \
EROFS_EXTRACT=/path/to/fsck.erofs \
scripts/extract-prebuilts.sh /path/to/stock
```

For a different Nothing OS build, re-run the script and commit the update. Do
not mix modules from one build with a kernel or DTB from another.
