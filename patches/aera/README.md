# AERA Recovery patch set

AERA Recovery R1.0 ships its own Android 16 manifest, vendor build system and
patch flow. The device tree provides the public `AERA_*` configuration in
`aera_Galaxian.mk` and `BoardConfig.mk`, but it does not carry a private copy
of AERA's source patches.

Build AERA from an AERA R1.0 workspace:

```bash
source build/envsetup.sh
lunch twrp_Galaxian-bp2a-eng
mka adbd recoveryimage
```

The AERA vendor scripts detect `vendor_boot` recovery from
`BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT` and
`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT`, both of which are set in
`BoardConfig.mk`.

If AERA's upstream documentation asks for a device-specific patch, place it in
this directory and extend `scripts/apply-recovery-patches.sh` so the change is
explicit and reproducible.
