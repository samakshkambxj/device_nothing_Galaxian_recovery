# Inputs intentionally excluded from this repository

This tree contains source configuration only. It does not redistribute any
firmware, kernel binary, kernel module, signing key or proprietary userspace
component.

Everything below is produced locally by `scripts/extract-prebuilts.sh` from a
stock Nothing OS 4.1 Galaxian dump and is ignored by git via `.gitignore`.

## Generated prebuilts (`prebuilt/`)

| Path | Source | Why it is excluded |
| --- | --- | --- |
| `prebuilt/Image.lz4` | kernel inside stock `boot.img` | Nothing/MediaTek kernel binary; only used while producing a throwaway intermediate boot image |
| `prebuilt/dtbo.img` | stock `dtbo.img` | device-specific DTBO image |
| `prebuilt/dtbs/mt6878.dtb` | FDT extracted from the stock `vendor_boot.img` DTB table | device-specific device tree |
| `prebuilt/vendor_boot/*.ko` | platform ramdisk inside stock `vendor_boot.img` | 216 proprietary/GPL kernel modules |
| `prebuilt/vendor_boot/modules.load` | same platform ramdisk | module list tied to the exact ROM build |
| `prebuilt/vendor_boot/modules.load.recovery` | same platform ramdisk | recovery module subset tied to the exact ROM build |
| `prebuilt/vendor_boot/modules.dep`, `modules.alias`, `modules.softdep` | same platform ramdisk | dependency metadata tied to the exact module set |
| `prebuilt/vendor/ft3683g.ko` | `vendor_dlkm.img` | FocalTech touchscreen driver |
| `prebuilt/vendor/bootinfo.ko` | `vendor_dlkm.img` | vendor module required by the touch driver |
| `prebuilt/vendor/touchpanel_event_notify.ko` | `vendor_dlkm.img` | vendor module required by the touch driver |

The stock platform ramdisk also supplies first-stage init, `snapuserd` and
other ROM userspace files. Those are never copied into this repository; the
packaging script preserves them inside the device's own `vendor_boot.img`.

## Build and packaging output

| Path | Reason |
| --- | --- |
| `out/` | packaged images, checksums and the generated restore image |
| `*.img` in the repository root | never produced here; outputs go to `out/` |

## Not included by design

- **Signing keys.** The stock `vendor_boot` uses an AVB hash footer with
  `--algorithm NONE`, so packaging needs the stock salt and fingerprint, not a
  private key. `BoardConfig.mk` references
  `external/avb/test/data/testkey_rsa2048.pem` only for the intermediate build
  image; that file comes from the Android source tree and is not copied here.
- **Stock firmware images.** `boot.img`, `vendor_boot.img`, `dtbo.img`,
  `vendor_dlkm.img` and the other partitions from `~/A001T/stock` stay local.
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

## Regenerating the local inputs

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

## Licensing notes

- The Linux kernel and its modules are distributed by Nothing Technology
  Limited under the GNU General Public License. Kernel source references are
  available through <https://github.com/NothingOSS>. Extracted binaries remain
  subject to that license and to the OEM's distribution terms.
- The stock Android userspace, Trustonic components and firmware images are
  proprietary and are not licensed for redistribution by this project.
- The source files in this repository are provided under the Apache License
  2.0 unless a file states otherwise. See `CREDITS.md` for upstream projects.

If you republish a packaged image, keep the OEM notices intact and do not
upload the extracted prebuilts. Share the extraction instructions instead.
