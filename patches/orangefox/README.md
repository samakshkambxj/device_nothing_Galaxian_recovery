# OrangeFox R12 patch series

These patches add the Android 16 / MT6878 behaviour that the OrangeFox build
relies on. They are applied to the OrangeFox R12 source workspace, not to this
repository. The device tree itself needs no other local projects.

Apply them from the root of the named repository:

1. `orangefox16-r12-vendor.patch` → `vendor/recovery`
2. Reassemble and apply `orangefox16-r12-ui-port.patch` → `bootable/recovery`
3. `orangefox16-r12-v15-runtime.patch` → `bootable/recovery`
4. `orangefox16-r12-v16-format-data-wipe.patch` → `bootable/recovery`
5. `orangefox16-r12-v17-data-format-mapping.patch` → `bootable/recovery`
6. `android16-health-vintf-v15.patch` → `hardware/interfaces`
7. `android16-keystore-kmsg-v15.patch` → `system/security`
8. `orangefox16-r12-v18-v28-and-nothingos41-v5.patch` → `bootable/recovery`
9. `orangefox16-r12-nothingos41-v8-sigpipe.patch` → `bootable/recovery`

`scripts/apply-recovery-patches.sh` applies them in that order and can be run
with `--check` to verify the workspace without changing it.

## UI patch reassembly

The R12 UI patch is stored as a split xz archive so that individual Git
objects stay small. Reassemble it in lexical order:

```bash
cd patches/orangefox
cat orangefox16-r12-ui-port.patch.xz.part-*.chunk-* > /tmp/orangefox16-r12-ui-port.patch.xz
xz -dc /tmp/orangefox16-r12-ui-port.patch.xz > /tmp/orangefox16-r12-ui-port.patch
```

The apply script performs this step automatically when the unpacked patch is
not present.

## Pinned sources

The patches apply to the pinned OrangeFox R12 Android 16 revisions listed in
the top-level `CREDITS.md`. If a source checkout has moved, run `--check` and
resolve context drift before building.
