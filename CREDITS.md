# Credits and upstream sources

This recovery tree is a from-scratch port for the Nothing Phone (3a) Lite
(`Galaxian`). It builds against public Android 16 recovery sources and the
device's own stock firmware. Thank you to everyone whose work made it possible.

## Recovery and platform work

| Project / person | Contribution |
| --- | --- |
| [AERA Recovery Project](https://github.com/AERA-Recovery) | AERA R1.0 backend, vendor tree, installer assets and the public `AERA_*` device configuration namespace |
| [OrangeFox Recovery Project](https://orangefox.download/) | OrangeFox R12 backend, vendor tree, UI and build system |
| [Team Win Recovery Project](https://twrp.me/) | TWRP recovery foundation, partition handling and encryption infrastructure |
| [OrangeFox16/android_bootable_recovery](https://github.com/OrangeFox16/android_bootable_recovery) | Android 16 recovery backend base (`bb7a65285217`) |
| [OrangeFox16/android_vendor_recovery](https://github.com/OrangeFox16/android_vendor_recovery) | `fox_16.0-R12` vendor base (`f243e0b7bb86`) |
| [killindodo/OFR_TB373FU_A16](https://github.com/killindodo/OFR_TB373FU_A16) | Android 16 MediaTek OrangeFox reference (`c8630e58e145`) |

## Device sources and firmware

| Project / person | Contribution |
| --- | --- |
| [Nothing Technology Limited / NothingOSS](https://github.com/NothingOSS) | Galaxian kernel sources and GPL kernel/module materials |
| [Nothing Archive / spike0en](https://github.com/spike0en/nothing_archive) | Stock Nothing OS 4.1 `B4.1-261029-1756` firmware archive and partition images |
| [Nothing Phone (3a) Lite LineageOS device tree](https://github.com/Andreyka445/local_manifest) | Hardware reference for the platform, display, partitions and stock properties |

The stock firmware remains the property of Nothing Technology Limited. See
`docs/EXCLUDED-INPUTS.md` for what is deliberately not redistributed.

## Build and packaging tools

| Project | Contribution |
| --- | --- |
| [Android Open Source Project](https://source.android.com/) | Android 16 build system, `vendor_boot`, VABC, AIDL HALs |
| [AOSP `external/avb`](https://android.googlesource.com/platform/external/avb) | `avbtool`, used to erase and recreate the stock hash footer |
| [Magisk](https://github.com/topjohnwu/Magisk) | `magiskboot`, used to unpack and repack the stock `vendor_boot` |
| [erofs-utils](https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git/) | `fsck.erofs`, used to extract the stock EROFS `vendor_dlkm` |
| [Linux kernel community](https://www.kernel.org/) | Kernel, module loader and filesystem infrastructure |

## Patch series

Most of this repository is device configuration. The only vendored source
patches are the OrangeFox R12 series under `patches/orangefox`, which target
`bootable/recovery`, `hardware/interfaces` and `system/security` in an
OrangeFox workspace. They are applied by
`scripts/apply-recovery-patches.sh --recovery orangefox` and remain the work of
their respective authors. Patches kept in `patches/orangefox/legacy` are
reference-only and are not applied.

TWRP builds from the upstream TWRP sources without device-side patches. AERA
builds from the AERA manifest and uses AERA's own patch flow.

## State of this port

This tree is not affiliated with or endorsed by Nothing Technology Limited,
AERA, OrangeFox or Team Win. It is an unofficial community port. Nothing in
this repository should be read as transferring ownership of their work.
