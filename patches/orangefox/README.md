# OrangeFox R12 patch series

These patches add device behaviour that the current public OrangeFox `fox_16.0`
tree does not have. They are applied to the OrangeFox source workspace, not to
this repository.

```bash
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery orangefox --check
device/nothing/Galaxian/scripts/apply-recovery-patches.sh --recovery orangefox
```

## Applied series

| Patch | Repository | Purpose |
| --- | --- | --- |
| `orangefox16-r12-v16-format-data-wipe.patch` | `bootable/recovery` | do not unmap every super partition before `HandleImminentDataWipe()`; a busy vendor mapping otherwise stops Format Data before `mkfs` |
| `orangefox16-r12-v17-data-format-mapping.patch` | `bootable/recovery` | stop `keystore2` and `twrp.trustonic.setup`, then destroy the metadata-encryption mapping before formatting userdata |
| `orangefox16-r12-nothingos41-v8-sigpipe.patch` | `bootable/recovery` | keep `SIGPIPE` ignored across minadbd so recovery is not killed after an ADB sideload |
| `android16-health-vintf-v15.patch` | `hardware/interfaces` | attach the health VINTF fragment to the example health binary instead of its defaults |
| `android16-keystore-kmsg-v15.patch` | `system/security` | copy `keystore2` panics to `/dev/kmsg` for early-decryption diagnostics |

The last two are optional: they are skipped if the AOSP source revision no
longer matches, and neither is required to boot.

All five apply cleanly to the public `fox_16.0` branch as of November 2026 and
to Android 16 AOSP release branches.

## Legacy series (`legacy/`)

`legacy/` holds patches that were written against
`github.com/OrangeFox16/android_bootable_recovery` at commit `bb7a65285217`
and `github.com/OrangeFox16/android_vendor_recovery` at `f243e0b7bb86`
(April 2026). That fork already carried earlier device work, and the public
`fox_16.0` tree has since moved. None of these apply to current sources:

| Patch | Why it is not applied |
| --- | --- |
| `orangefox16-r12-vendor.patch` | the R12 vendor layer is already in `vendor/recovery` |
| `orangefox16-r12-ui-port.patch.xz.part-*` | the R12 UI and SVG engine are already in `bootable/recovery` |
| `orangefox16-r12-v15-runtime.patch` | needs the fork's earlier Trustonic runtime changes as context |
| `orangefox16-r12-v18-v28-and-nothingos41-v5.patch` | cumulative fork delta; overlaps v15-v17 and cannot be replayed on the public tree |

`legacy/` is kept for reference. Do not apply it to a current workspace.

The device-side changes that only exist there, and that a future rebase should
port, are: forced timezone (`OF_FORCE_TIMEZONE`), the Trustonic readiness
handshake and keystore DB sync, disabling auto-reflash in `vendor_boot` mode,
vendor_boot-aware repacking, and the sideload child cleanup.

## UI patch reassembly (legacy only)

The split archive is reassembled in lexical order:

```bash
cd patches/orangefox/legacy
cat orangefox16-r12-ui-port.patch.xz.part-*.chunk-* > /tmp/orangefox16-r12-ui-port.patch.xz
xz -dc /tmp/orangefox16-r12-ui-port.patch.xz > /tmp/orangefox16-r12-ui-port.patch
```
