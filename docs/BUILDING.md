# Building and flashing a recovery for Galaxian

This document assumes:

- an **Android 16** recovery workspace for the recovery you want to build
  (TWRP, OrangeFox R12, or AERA R1.0);
- a stock Nothing OS 4.1 Galaxian dump with `boot.img`, `vendor_boot.img`,
  `dtbo.img` and `vendor_dlkm.img` (the local reference dump is
  `~/A001T/stock`);
- a Linux host with roughly 250 GB free for the source tree and output. A full
  Android 16 sync is much larger than the recovery output.

The tree itself is recovery-only and shares no makefiles with
`~/device_nothing_Galaxian`. Keep the LineageOS tree out of the recovery
workspace; two `device/nothing/Galaxian/BoardConfig.mk` files cannot coexist.

All recoveries use the same product and lunch target:

```
twrp_Galaxian-bp2a-eng
```

The recovery is selected by the vendor tree and by `vendorsetup.sh`. Build the
tree in one workspace at a time.

## 1. Sync the workspace

### TWRP

Public TWRP branches currently stop at `android-14.1`. There is no upstream
Android 16 TWRP branch to build this tree against yet, so treat the TWRP path
as ready-but-pending. When a 16.0 branch appears, sync it as usual; the tree
expects the standard `vendor/twrp/config/common.mk` interface. For a working
build today, use OrangeFox R12 or AERA R1.0.

### OrangeFox R12

OrangeFox's `sync.git` is a tool checkout, not a manifest. Use its Android 16
entry point, which initialises `https://gitlab.com/OrangeFox/Manifest.git`
branch `fox_16.0`:

```bash
mkdir -p ~/OrangeFox_sync && cd ~/OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 16.0 --path ~/fox_16.0
```

Or initialise the manifest directly:

```bash
mkdir -p ~/fox_16.0 && cd ~/fox_16.0
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j"$(nproc)" --no-clone-bundle --no-tags
```

The manifest already contains `vendor/recovery` and `device/xiaomi/mondrian`;
do not reuse a patched 12.1/14.1 checkout.

### AERA R1.0

```bash
mkdir -p ~/aera-16.0 && cd ~/aera-16.0
repo init --depth=1 -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
repo sync -c -j"$(nproc)" --no-clone-bundle --no-tags
```

AERA's vendor build system carries its own patch flow and installer assets.

## 2. Add this tree

```bash
cd "$ANDROID_BUILD_TOP"
ln -s ~/device_nothing_Galaxian_recovery device/nothing/Galaxian
```

A copy works too; the scripts resolve their own location.

## 3. Apply the selected recovery's source patches

```bash
# Inspect what is available
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --list

# OrangeFox R12: verify, then apply
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery orangefox --check
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery orangefox

# TWRP: no device-side patch series
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery twrp

# AERA: use AERA's own manifest/patch flow
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery aera
```

The OrangeFox series lives in `patches/orangefox`. The script can also read a
different directory with `--patches <dir>` or `GALAXIAN_RECOVERY_PATCHES`.

## 4. Extract the local prebuilts

```bash
device/nothing/Galaxian/scripts/extract-prebuilts.sh ~/A001T/stock
```

This produces `prebuilt/` (git-ignored):

| Path | Source | Purpose |
| --- | --- | --- |
| `Image.lz4` | stock `boot.img` kernel | intermediate boot image only |
| `dtbo.img` | stock `dtbo.img` | intermediate build |
| `dtbs/mt6878.dtb` | FDT inside stock `vendor_boot.img` DTB table | intermediate build |
| `vendor_boot/*.ko` + `modules.load*` | stock platform ramdisk | module list and recovery fragment |
| `vendor/{ft3683g,bootinfo,touchpanel_event_notify}.ko` | stock `vendor_dlkm.img` | touch bring-up |

Requirements:

- `magiskboot` (`MAGISKBOOT=/path/to/magiskboot` if not in `PATH`)
- `fsck.erofs` from `erofs-utils`
- `python3`, `cpio`, `lz4`

On Omarchy/Arch: `sudo pacman -S erofs-utils lz4 android-tools`, then provide
`magiskboot` from a Magisk APK or a Magisk build tree.

The script fails closed if a required module or file is missing. Set `TMPDIR`
to a directory on a large filesystem if `/tmp` is a small tmpfs.

## 5. Build

```bash
cd "$ANDROID_BUILD_TOP"
device/nothing/Galaxian/scripts/build-recovery.sh --recovery twrp
device/nothing/Galaxian/scripts/build-recovery.sh --recovery orangefox
device/nothing/Galaxian/scripts/build-recovery.sh --recovery aera
```

The script runs `lunch twrp_Galaxian-bp2a-eng` and then:

| Recovery | Default target | Output used here |
| --- | --- | --- |
| TWRP | `vendorbootimage` | recovery fragment |
| OrangeFox R12 | `vendorbootimage` | recovery fragment |
| AERA R1.0 | `recoveryimage` | AERA image plus recovery fragment |

Override with `--target <make-target>` if your source revision needs it. The
fragment path printed by the script is normally:

```
out/target/product/Galaxian/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4
```

Only this fragment is used. The generated `vendor_boot` from the Android build
is a throwaway image; the final image is produced in the next step so the stock
platform ramdisk, DTB and bootconfig stay byte-for-byte identical.

## 6. Package into vendor_boot

```bash
device/nothing/Galaxian/scripts/package-vendor-boot.sh \
    --stock ~/A001T/stock \
    --label TWRP \
    --ramdisk out/target/product/Galaxian/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4
```

Use `--label OrangeFox-R12` or `--label AERA-R1.0` for the other builds.

The script:

1. unpacks the stock `vendor_boot.img`;
2. replaces only the `recovery` vendor-ramdisk fragment;
3. repacks with `magiskboot` (platform ramdisk, DTB and header fields kept);
4. erases the old AVB footer and writes a new `SHA256` hash footer with
   `--algorithm NONE`, the stock salt and the stock vendor_boot fingerprint;
5. verifies the image and the 64 MiB partition size;
6. writes a matching `-OFFICIAL-RESTORE-vendor_boot.img` next to the result.

Expected stock values for the reference dump:

```
sha256   c51086947a9408bd4ec504e9e0dd73801f7bfda4fef755c9f320046583f3aa22
salt     436553f64170cf5a945830f2f5ccc51a5da98735609153e5d9710ae10979689a
profile  alps/Galaxian_mgvi_64_64only_ww_armv82/mgvi_64_64only_ww_armv82:14/UP1A.231005.007/2610291756:user/release-keys
```

Pass `--expected-sha256 c5108694...` to refuse a mismatched dump.

## 7. Flash

Back up the current vendor_boot first, and verify the active slot:

```bash
fastboot getvar current-slot
fastboot flash vendor_boot_<slot> out/Galaxian-NOS41-2610291756-TWRP-vendor_boot.img
fastboot reboot recovery
```

`vendor_boot` carries recovery, the DTB and the early module set. It does not
replace the kernel (`boot`), so a bad recovery image still leaves Android
bootable. Do **not** flash `boot.img`, `init_boot.img` or `dtbo.img` from this
tree.

## 8. Restore

```bash
fastboot flash vendor_boot_<slot> out/Galaxian-NOS41-2610291756-TWRP-OFFICIAL-RESTORE-vendor_boot.img
```

The restore image is the untouched stock `vendor_boot.img` produced by the
packaging step.

## 9. First-boot validation checklist

- UI appears with the correct orientation, resolution and colours.
- Touch works (`fts_ts` should be the selected input device; `hbtp_vm` is
  blacklisted).
- Time and battery percentage match Android.
- `/metadata` and encrypted `/data` mount after entering the lock screen
  credential; internal storage is readable and writable.
- A non-destructive ADB sideload cycle completes.
- MTP read/write/delete works.
- Reboot to Android, then `fastboot reboot recovery` again.
- Only after all of the above: Format Data (destructive) and verify a clean
  f2fs format with a working `/data/media/0` MTP export.

Collect logs before changing anything:

```bash
adb shell dmesg > dmesg.txt
adb shell cat /tmp/recovery.log > recovery.log
adb shell cat /tmp/twrp_trustonic_setup.log > trustonic.log
```

## 10. Recovery-specific notes

### TWRP

No device-side patch series. The tree uses the standard `TW_*` variables and
the common `twrp_Galaxian` product.

### OrangeFox R12

Apply `patches/orangefox` once per workspace. The series carries the R12 UI
port, the Trustonic readiness handshake, Format Data device-mapper teardown
and the VABC-safe snapshot handling.

### AERA R1.0

AERA's vendor tree supplies its own patch flow and installer. The device tree
provides `AERA_*` configuration in `aera_Galaxian.mk` and `BoardConfig.mk`.
AERA's build script detects `vendor_boot` recovery from
`BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT` and
`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT`.

The AERA values most likely to need adjustment after the first boot are the
status-bar height, the brightness path/scale, and the module list. See
`docs/PORTING-NOTES.md`.
