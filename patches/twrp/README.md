# TWRP patch set

No device-side source patches are required for TWRP. Build the tree against
the upstream Android 16 TWRP manifest when that branch is published; public
TWRP branches currently stop at `android-14.1`, so use OrangeFox R12 or AERA
R1.0 for a build today. The lunch target stays `twrp_Galaxian-bp2a-eng`.

The tree uses the standard TWRP variables (`TW_*`, `TARGET_RECOVERY_*`,
`BOARD_*`) and an A/B `vendor_boot` layout. If a future TWRP revision changes a
variable name or the `vendor_boot` fragment path, fix the device tree rather
than patching TWRP locally.

Keep this directory in place so `apply-recovery-patches.sh --recovery twrp`
has an explicit, empty patch set to report.
