# Recovery patch sets

This device tree is shared by several recoveries. Each recovery uses the same
`twrp_Galaxian` product and the same `vendor_boot` recovery fragment, but it
may need a different set of source patches.

| Recovery | Patch set | Applied by |
| --- | --- | --- |
| TWRP | `patches/twrp` | Nothing to apply; use upstream TWRP sources |
| OrangeFox R12 | `patches/orangefox` | `scripts/apply-recovery-patches.sh --recovery orangefox` |
| AERA Recovery R1.0 | `patches/aera` | AERA's own manifest and patch flow |

The device tree deliberately does not modify any recovery source during a
normal build. Apply a patch set once to the workspace that you are building.

`scripts/apply-recovery-patches.sh` selects the set with `--recovery` or with
`GALAXIAN_RECOVERY`. With `auto` it detects AERA from `AERA_PRODUCT_PREFIX`,
OrangeFox from `FOX_BUILD_DEVICE`, and otherwise assumes TWRP.
