# Porting notes and hardware validation

This is a from-scratch recovery port for the Nothing Phone (3a) Lite, written
against public Android 16 recovery sources and the device's stock firmware.
The same device tree produces TWRP, OrangeFox R12 and AERA R1.0 recovery
fragments. Nothing here has been built or flashed on a physical Galaxian yet;
the source is complete and internally consistent, and the items below are the
assumptions that need hardware proof.

## Reference firmware

| Item | Value |
| --- | --- |
| Device | Nothing Phone (3a) Lite (`Galaxian`, model `A001T`) |
| SoC | MediaTek Dimensity 7300 Pro (`MT6878`) |
| Target ROM | Stock Nothing OS 4.1 |
| Build | `B4.1-261029-1756` (`Galaxian_B4.1-261029-1756`) |
| Local dump | `~/A001T/stock` |
| `vendor_boot.img` SHA-256 | `c51086947a9408bd4ec504e9e0dd73801f7bfda4fef755c9f320046583f3aa22` |
| AVB salt | `436553f64170cf5a945830f2f5ccc51a5da98735609153e5d9710ae10979689a` |
| AVB footer algorithm | `NONE` (hash footer) |
| Vendor-boot fingerprint | `alps/Galaxian_mgvi_64_64only_ww_armv82/mgvi_64_64only_ww_armv82:14/UP1A.231005.007/2610291756:user/release-keys` |

The fingerprint's trailing component (`2610291756`) is parsed by
`scripts/package-vendor-boot.sh` to build the output file name.

## Why a separate tree

`~/device_nothing_Galaxian` is a LineageOS device tree with its own
`BoardConfig.mk` for a full Android build. A recovery workspace needs
`device/nothing/Galaxian` to contain a recovery board configuration. Linking
or copying both into one workspace would put two `BoardConfig.mk` files at the
same path. This repository is therefore standalone and recovery-only. Keep the
LineageOS tree out of the recovery workspace.

## One product, three recoveries

TWRP, OrangeFox R12 and AERA R1.0 all consume the TWRP product interface, so a
single product is enough:

```
PRODUCT_NAME := twrp_Galaxian
lunch        twrp_Galaxian-bp2a-eng
```

What changes is the vendor source tree and its environment:

| Recovery | Vendor source | Device-side patches | BoardConfig namespace |
| --- | --- | --- | --- |
| TWRP | Android 16 TWRP | none | `TW_*`, `TARGET_RECOVERY_*`, `BOARD_*` |
| OrangeFox R12 | `vendor/recovery` `fox_16.0-R12` | `patches/orangefox` | `TW_*` plus `OF_*` |
| AERA R1.0 | `vendor/recovery` `aera-16.0` | AERA's own patch flow | `TW_*` plus `AERA_*` |

`vendorsetup.sh` detects the active vendor tree. It exports `FOX_*`/`OF_*` for
OrangeFox and `AERA_*` for AERA; TWRP needs no vendor environment. Set
`GALAXIAN_RECOVERY` explicitly when a workspace contains more than one vendor
recovery tree.

## Image layout

Galaxian uses the Android 13+ `vendor_boot` layout (header version 4):

```
vendor_boot.img
  kernel        (empty in stock Galaxian)
  ramdisk       (platform ramdisk: first-stage init, modules, snapuserd)
  recovery      (vendor-ramdisk fragment, replaced by this build)
  dtb           (MediaTek DTB table wrapping one FDT)
  bootconfig    (stock bootconfig)
  AVB hash footer
```

`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT` and
`BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT` make the build produce only the
recovery fragment. That fragment is then merged into the untouched stock image
with `magiskboot`, which preserves the platform ramdisk, DTB table, bootconfig
and header fields byte-for-byte. Re-signing uses `avbtool add_hash_footer` with
the exact stock salt, fingerprint and `--algorithm NONE`.

Do not flash the `vendorbootimage` produced directly by the Android build. It
is a throwaway artifact with a different platform ramdisk and a test AVB key.

## Module loading

The stock platform ramdisk contains 216 modules. `modules.load` and
`modules.load.recovery` each list 204 entries. Recovery loads the recovery
list, but three groups need special handling:

1. `ft3683g.ko` (the FocalTech FT3683G touchscreen) lives in `vendor_dlkm`,
   not in the stock platform ramdisk. It is packed into the recovery fragment
   from `prebuilt/vendor/`.
2. `ft3683g.ko` depends on `bootinfo.ko` and `touchpanel_event_notify.ko`,
   which are also vendor_dlkm modules. Both are packed alongside it.
3. `bootinfo.ko` imports one symbol from each of `sc8541_charger.ko`,
   `upm6720_charger.ko`, `nu2115_charger.ko` and `sgm41606S_charger.ko`.
   Those four are present in the stock platform ramdisk but are **not** in
   `modules.load.recovery`, so they are listed explicitly and loaded first.

The resulting order is:

```
sc8541_charger, upm6720_charger, nu2115_charger, sgm41606S_charger,
<sorted modules.load.recovery entries>,
bootinfo, touchpanel_event_notify, ft3683g
```

`TW_INPUT_BLACKLIST := hbtp_vm` prevents the selected recovery from binding the
MediaTek virtual input device instead of the real touchscreen (`fts_ts`).

## Encryption and Trustonic

Stock Galaxian uses metadata FBE and the Trustonic TEE stack:

- metadata encryption keys live under `/metadata/vold/metadata_encryption`;
- KeyMint is AIDL version 3, Gatekeeper is AIDL version 1;
- `/vendor/app/mcRegistry` ships 10 `.drbin` drivers;
- the vendor partition is EROFS and is a dynamic logical partition.

Recovery enables encrypted-storage support with fscrypt policy 2 and starts the
ROM-matched Trustonic services from `system/bin/twrp_trustonic_setup.sh`
before the metadata key is unwrapped. The script:

- waits for the logical `vendor` device, then mounts it read-only at
  `/mnt/vendor_real`;
- bind-mounts `/vendor/bin` and `/vendor/app` from that stable mount;
- mounts `/persist` read-write and prepares `mcRegistry`;
- enumerates the `.drbin` files at runtime instead of hard-coding names;
- starts `mcDriverDaemon`, the KeyMint 3 service and the Gatekeeper service
  directly, and waits for them to stay alive;
- sets `recovery.trustonic.ready=1`, which the OrangeFox patch series uses as
  the handshake before decrypting.

`TW_SKIP_ADDITIONAL_FSTAB := true` is deliberate. The recovery fstab already
carries the stock metadata-FBE flags; letting recovery re-parse a mounted
vendor fstab causes it to stop at "Using additional fstab for decryption" and
restart.

## Virtual A/B

Stock Nothing OS 4.1 enables userspace snapshots and snapshot compression
(`ro.virtual_ab.compression.enabled=true`). The product therefore inherits
`virtual_ab_ota/vabc_features.mk`, sets
`PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4`, and includes `snapuserd.rc`.
The OrangeFox patch series contains the VABC safety changes that keep Format
Data and snapshot teardown consistent. AERA ships its own equivalent handling.

## Display and UI

| Setting | Value | Source |
| --- | --- | --- |
| Panel | 1084 x 2392, 420 dpi | stock display configuration |
| Pixel format | `BGRA_8888` | stock `ro.minui.pixel_format` |
| `OF_SCREEN_H` / `AERA_SCREEN_H` | 2392 | panel height |
| `OF_STATUS_H` / `AERA_STATUS_H` | 95 | initial geometry, needs visual check |
| `TW_Y_OFFSET` / `TW_H_OFFSET` | 95 / -95 | initial geometry, needs visual check |
| `TW_MAX_BRIGHTNESS` / `AERA_MAX_BRIGHTNESS` | 2047 | MT6878 backlight scale |
| Brightness path | `/sys/class/leds/lcd-backlight/brightness` | stock init |
| Time zone | `IST-5:30` | maintainer locale; change with the matching setting |

## Recovery-specific configuration

### TWRP

Uses only the common `TW_*` and `BOARD_*` variables. No vendor-specific
environment or patch set is required.

### OrangeFox R12

Adds `OF_*` environment values in `vendorsetup.sh` and `OF_*` board settings.
The `patches/orangefox` series must be applied to `vendor/recovery`,
`bootable/recovery`, `hardware/interfaces` and `system/security`.

### AERA R1.0

`aera_Galaxian.mk` and `BoardConfig.mk` provide the public `AERA_*` namespace.
AERA's `aera_config.mk` translates those values into the inherited backend
names. Core settings such as crypto, fastbootd, logcat, repack tools, module
loading and brightness are in `BoardConfig.mk`; UI and partition behaviour are
in `aera_Galaxian.mk`.

`AERA_LOAD_VENDOR_MODULES` is set to the same ordered list as
`TW_LOAD_VENDOR_MODULES`, so AERA loads the charger providers before
`bootinfo.ko` and the touch modules.

## Open items that need hardware validation

Treat this list as the acceptance test for the first build.

1. **Build variables.** Confirm that the selected recovery revision accepts
   `BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD`,
   `BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES` and
   `TW_LOAD_VENDOR_BOOT_MODULES` with the expected semantics. If a variable
   was renamed upstream, adjust `BoardConfig.mk`; do not remove the explicit
   charger-provider ordering.
2. **UI geometry.** Check orientation, status-bar height, clock position and
   navbar offset in each recovery. `OF_STATUS_H=95`, `AERA_STATUS_H=95` and the
   95 px offsets are initial values and are the most likely cosmetic mismatch
   on a 2392 px panel.
3. **Touch.** Verify that `ft3683g.ko` loads (no unknown-symbol errors), that
   `fts_ts` is the selected input device, and that `hbtp_vm` is ignored.
   `init.touch.rc` in stock references `focaltech_tp.ko`, which is absent from
   stock `vendor_dlkm`; it is probably built into the kernel, but this must be
   confirmed. If touch does not work, inspect `dmesg` for the module load
   order.
4. **Health HAL.** The stock manifest advertises AIDL Health version 2. The
   build packages `android.hardware.health-service.example_recovery`; confirm
   it registers at version 2 and that battery percentage and charging state
   appear in the UI.
5. **Metadata FBE.** Enter the lock-screen credential and confirm that
   `/metadata` and `/data` mount, internal storage is readable/writable, and
   `/tmp/twrp_trustonic_setup.log` ends with a successful
   `mobicore=... keymint=... gatekeeper=...` line.
6. **MTP.** The tree uses product IDs `0x4EE2` (MTP+ADB) and `0x4EE1` (MTP)
   for the recovery gadget. Stock Galaxian documents `18D1:D001` for ADB and
   `18D1:4EE0` for fastboot. If MTP does not enumerate, inspect `dmesg`,
   `/config/usb_gadget/g1`, and `sys.usb.state`, then adjust the MTP product
   IDs.
7. **VABC and Format Data.** Test a non-destructive sideload first, then
   Format Data. Confirm that `snapuserd` starts, that the formatted data
   partition is f2fs with the stock options, and that `/data/media/0` is
   recreated and exported over MTP.
8. **Partition sizes.** `BOARD_BOOTIMAGE_PARTITION_SIZE`,
   `BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE` and the super partition sizes were
   taken from the stock dump. Cross-check with
   `fastboot getvar partition-size:vendor_boot` and
   `fastboot getvar partition-size:super` before trusting a flash.
9. **AVB verification.** `scripts/package-vendor-boot.sh` runs
   `avbtool verify_image`. Confirm the bootloader accepts the image with the
   bootloader unlocked. The footer uses `--algorithm NONE`, matching stock, so
   no signing key is required.
10. **AERA specifics.** Confirm the AERA build detects `vendor_boot` recovery
    from the two `BOARD_*` flags, that its `recoveryimage` target produces a
    usable fragment, and that the AERA status bar, brightness and module list
    match the panel. AERA's installer packaging is separate from
    `package-vendor-boot.sh`.
11. **Brightness.** Verify `TW_MAX_BRIGHTNESS=2047` and
    `AERA_MAX_BRIGHTNESS=2047` match the panel's backlight scale; a wrong value
    produces a dim or saturated UI.
12. **Patch series.** The OrangeFox patches are pinned to specific R12
    revisions. Run `scripts/apply-recovery-patches.sh --recovery orangefox
    --check` against the synced workspace and resolve any context drift before
    building.

## Known limitations

- The tree has not been compiled against a synced Android 16 recovery
  workspace. Only syntax, extraction and configuration checks have been run
  locally.
- This machine has about 59 GB free; a full Android 16 source tree needs much
  more. Build on a roomier disk or machine.
- Prebuilts are not committed. Run `scripts/extract-prebuilts.sh` against the
  matching stock dump before building.
- The stock firmware is proprietary. Do not redistribute the extracted
  modules, kernel, DTB or images.
