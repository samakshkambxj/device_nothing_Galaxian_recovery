# Inputs shipped and excluded

This tree carries the compiled kernel, DTB, DTBO and kernel modules needed to
build the recovery fragment. It does not carry full firmware images, vendor
userspace or key material.

## Shipped prebuilt binaries (`prebuilt/`)

These come from the stock Nothing OS 4.1 Galaxian firmware,
`B4.1-261029-1756`. See `prebuilt/README.md` for the source and licensing
notice.

| Path | Source | Why it is shipped |
| --- | --- | --- |
| `prebuilt/Image.lz4` | kernel inside stock `boot.img` | the build needs a kernel image; the final image keeps the stock boot layout |
| `prebuilt/dtbo.img` | stock `dtbo.img` | satisfies the build system; the final vendor_boot keeps the stock DTB table |
| `prebuilt/dtbs/mt6878.dtb` | FDT extracted from stock `vendor_boot.img` | build-time DTB input |
| `prebuilt/vendor_boot/*.ko` | platform ramdisk inside stock `vendor_boot.img` | 216 GPL kernel modules used by the recovery fragment |
| `prebuilt/vendor_boot/modules.load` | same platform ramdisk | stock first-stage module list |
| `prebuilt/vendor_boot/modules.load.recovery` | same platform ramdisk | stock recovery module subset |
| `prebuilt/vendor_boot/modules.{dep,alias,softdep}` | same platform ramdisk | module dependency metadata |
| `prebuilt/vendor/ft3683g.ko` | `vendor_dlkm.img` | FocalTech FT3683G touchscreen driver |
| `prebuilt/vendor/bootinfo.ko` | `vendor_dlkm.img` | dependency of the touch driver |
| `prebuilt/vendor/touchpanel_event_notify.ko` | `vendor_dlkm.img` | dependency of the touch driver |

Total size: about 55 MB.

The final flashable image is still assembled from the device's own stock
`vendor_boot.img` by `scripts/package-vendor-boot.sh`. The stock platform
ramdisk, first-stage init, `snapuserd`, bootconfig and DTB table stay inside
that image; they are not copied into this repository.

## Build and packaging output

| Path | Reason |
| --- | --- |
| `out/` | packaged images, checksums and the generated restore image |
| `*.img` in the repository root | never produced here; outputs go to `out/` |

Both are ignored by git.

## Not included by design

- **Signing keys.** The stock `vendor_boot` uses an AVB hash footer with
  `--algorithm NONE`, so packaging needs the stock salt and fingerprint, not a
  private key. `BoardConfig.mk` references
  `external/avb/test/data/testkey_rsa2048.pem` only for the intermediate build
  image; that file comes from the Android source tree and is not copied here.
- **Full stock firmware images.** `boot.img`, `vendor_boot.img`,
  `vendor_dlkm.img` and the other partition images stay local. Only the pieces
  listed above are shipped.
- **Trustonic userspace.** `mcDriverDaemon`, the KeyMint 3 service, the
  Gatekeeper service, `mcRegistry/*.drbin` and `*.tlbin` are proprietary
  Nothing/Trustonic components. This tree only starts the copies already
  present in the device's stock vendor partition at runtime.
- **MediaTek confidential sources.** Unlike some MTK recovery trees, this
  tree does not contain MediaTek boot-control implementation files, headers or
  other material covered by a confidentiality notice. It uses the stock AIDL
  boot-control HAL instead.
- **OrangeFox UI patch payload.** The R12 source patches are vendored under
  `patches/orangefox` as text patches. They are not firmware and contain no
  device blobs. `scripts/apply-recovery-patches.sh` applies them only to an
  OrangeFox workspace; TWRP and AERA do not use them.

## Licensing

- The kernel and every shipped module report `GPL v2`, `GPL`,
  `GPL and additional rights`, or `Dual BSD/GPL`. No module is marked
  proprietary.
- Nothing Technology Limited publishes the matching source for MT6878:
  - <https://github.com/NothingOSS/android_kernel_6.1_nothing_mt6878>
  - <https://github.com/NothingOSS/android_kernel_modules_nothing_mt6878>
  - <https://github.com/NothingOSS/android_kernel_device_modules_6.1_nothing_mt6878>
- The Linux kernel is GPL-2.0. Device tree files are generally GPL-2.0 or
  BSD-licensed. The files' own metadata and the published source are
  authoritative.
- The recovery source configuration in this repository is Apache-2.0 unless a
  file states otherwise. See `CREDITS.md` for upstream projects.
- Nothing Phone and Nothing OS are trademarks of Nothing Technology Limited.
  This project is unofficial and is not affiliated with or endorsed by Nothing.

## Regenerating

Use a dump of the **same** firmware release. Mixing kernel, DTB or modules from
another build can break touch, storage or Trustonic bring-up.

```bash
MAGISKBOOT=/path/to/magiskboot \
EROFS_EXTRACT=/path/to/fsck.erofs \
./scripts/extract-prebuilts.sh ~/A001T/stock
```

The script validates that every required file exists and is non-empty, and
fails closed if the dump does not match the expected layout. It prints the
platform module count, the vendor touch module count and the total prebuilt
size.
