# Common recovery tree for the Nothing Phone (3a) Lite

Recovery-only device tree for the **Nothing Phone (3a) Lite** (`Galaxian`,
model `A001T`, MediaTek Dimensity 7300 Pro / MT6878), targeting **stock
Nothing OS 4.1** (`B4.1-261029-1756`).

The tree builds a standard Android 16 `vendor_boot` recovery fragment from one
shared product. It is intended for:

- **TWRP** on the Android 16 TWRP manifest;
- **OrangeFox R12** on the `fox_16.0-R12` manifest;
- **AERA Recovery R1.0** on the `aera-16.0` manifest.

All three use the same `twrp_Galaxian-bp2a-eng` lunch target. The recovery is
selected by the vendor source tree and by `vendorsetup.sh`, not by a separate
product.

> **Status:** source complete, not yet built or flashed on hardware. See
> [docs/BUILDING.md](docs/BUILDING.md) for the first-build checklist and
> [docs/PORTING-NOTES.md](docs/PORTING-NOTES.md) for the assumptions that need
> to be validated on a real device.

## Layout

```
BoardConfig.mk                 common recovery board configuration
device.mk                      common recovery userspace packages and libraries
twrp_Galaxian.mk               common product (TWRP product interface)
aera_Galaxian.mk               AERA R1.0 public configuration
AndroidProducts.mk             lunch choices
vendorsetup.sh                 TWRP/OrangeFox/AERA environment selection
system.prop                    recovery-only properties

recovery/root/
  recovery.fstab               A/B, erofs, metadata-FBE fstab
  init.recovery.mt6878.rc      USB controller and early adbd
  servicemanager.recovery.rc
  snapuserd.rc                 Virtual A/B snapshot userspace daemon
  system/etc/twrp.flags        friendly partition names and backup flags
  system/etc/init/twrp_mtp.rc  ConfigFS/FunctionFS MTP gadget
  system/etc/init/twrp_trustonic.rc
  system/bin/twrp_trustonic_setup.sh
  system/etc/vintf/manifest.xml           framework manifest
  vendor/etc/vintf/manifest.xml           recovery device manifest
  vendor/manifest.xml                     legacy libvintf fallback

patches/
  twrp/                        no device-side patches
  orangefox/                   R12 runtime/UI/FBE/VABC/Trustonic series
  aera/                        AERA's own patch flow

scripts/
  extract-prebuilts.sh         stock images -> prebuilt/
  build-recovery.sh            build a selected recovery
  package-vendor-boot.sh       recovery fragment -> signed vendor_boot
  apply-recovery-patches.sh    apply the selected recovery's patch set

docs/BUILDING.md               workspace, build, package, flash, restore
docs/PORTING-NOTES.md          hardware facts and open validation items
docs/EXCLUDED-INPUTS.md        what is intentionally not committed
```

## Quick start

```bash
# 1. Put this tree in the recovery workspace you want to build
ln -s "$PWD" "$ANDROID_BUILD_TOP/device/nothing/Galaxian"

# 2. Apply the selected recovery's source patches (OrangeFox only; TWRP and
#    AERA report that their vendor trees already provide the source set)
./scripts/apply-recovery-patches.sh --recovery orangefox

# 3. Extract stock kernel/DTB/modules from the device's own dump
./scripts/extract-prebuilts.sh ~/A001T/stock

# 4. Build
./scripts/build-recovery.sh --recovery orangefox

# 5. Repack into the stock vendor_boot and sign it
./scripts/package-vendor-boot.sh \
    --stock ~/A001T/stock \
    --label OrangeFox-R12 \
    --ramdisk "$ANDROID_BUILD_TOP/out/target/product/Galaxian/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"
```

For TWRP use `--recovery twrp`; for AERA use `--recovery aera`. See
[docs/BUILDING.md](docs/BUILDING.md) for the per-recovery build matrix.

`prebuilt/` and `out/` are ignored by git; the firmware blobs stay local to
your machine.

## Device specifications

Basic | Spec
-----:|:-----
CPU | 4x Cortex-A78 @ 2.50 GHz + 4x Cortex-A55 @ 2.00 GHz
Chipset | MediaTek Dimensity 7300 Pro (MT6878)
GPU | Mali-G615 MP2
Memory | 8 GB
Storage | 128 / 256 GB
Display | 1084 x 2392, 6.77", 60/120 Hz, 420 dpi
Shipped Android | 15
Battery | 5000 mAh
Touch | FocalTech FT3683G (`ft3683g.ko`, vendor_dlkm)
TEE / KeyMint | Trustonic (`mcDriverDaemon`, KeyMint 3, Gatekeeper 1)
