#!/usr/bin/env bash
#
# Populate prebuilt/ from a Galaxian stock firmware dump.
#
# Required inputs in <stock-dir>:
#   boot.img, vendor_boot.img, dtbo.img, vendor_dlkm.img
#
# Tools:
#   MAGISKBOOT     magiskboot binary (default: magiskboot from PATH)
#   EROFS_EXTRACT  fsck.erofs binary (default: fsck.erofs from PATH)
#
# On Arch/Omarchy: sudo pacman -S erofs-utils android-tools
#
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree_dir=$(cd -- "$script_dir/.." && pwd)
stock_dir=${1:-}
magiskboot=${MAGISKBOOT:-magiskboot}
erofs_extract=${EROFS_EXTRACT:-fsck.erofs}

if [[ -z "$stock_dir" ]]; then
    echo "usage: $0 <stock-dump-dir>" >&2
    echo "example: $0 ~/A001T/stock" >&2
    exit 1
fi
stock_dir=$(cd -- "$stock_dir" && pwd)

for tool in "$magiskboot" "$erofs_extract" python3 cpio; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "missing tool: $tool" >&2
        [[ "$tool" == "$erofs_extract" ]] && echo "install erofs-utils (fsck.erofs)" >&2
        [[ "$tool" == "$magiskboot" ]] && echo "set MAGISKBOOT=/path/to/magiskboot" >&2
        exit 1
    fi
done

for image in boot.img vendor_boot.img dtbo.img vendor_dlkm.img; do
    [[ -f "$stock_dir/$image" ]] || { echo "missing input: $stock_dir/$image" >&2; exit 1; }
done

prebuilt="$tree_dir/prebuilt"
work=$(mktemp -d "${TMPDIR:-/tmp}/galaxian-prebuilts.XXXXXX")
trap 'rm -rf "$work"' EXIT

echo "==> unpacking boot.img (kernel stays lz4-compressed)"
mkdir -p "$work/boot"
(
    cd "$work/boot"
    "$magiskboot" unpack -n "$stock_dir/boot.img" >/dev/null
)
[[ -f "$work/boot/kernel" ]] || { echo "boot.img did not contain a kernel" >&2; exit 1; }

echo "==> unpacking vendor_boot.img (platform ramdisk + DTB)"
mkdir -p "$work/vendor_boot"
(
    cd "$work/vendor_boot"
    rc=0
    "$magiskboot" unpack "$stock_dir/vendor_boot.img" >/dev/null || rc=$?
    # magiskboot returns 3 for vendor_boot images.
    [[ $rc -eq 0 || $rc -eq 3 ]] || { echo "could not unpack vendor_boot (status $rc)" >&2; exit 1; }
)
[[ -f "$work/vendor_boot/vendor_ramdisk/ramdisk.cpio" ]] || { echo "vendor_boot has no platform ramdisk" >&2; exit 1; }

echo "==> extracting platform ramdisk"
mkdir -p "$work/platform"
(
    cd "$work/platform"
    cpio -idm --no-absolute-filenames < "$work/vendor_boot/vendor_ramdisk/ramdisk.cpio" >/dev/null 2>&1
)
[[ -d "$work/platform/lib/modules" ]] || { echo "platform ramdisk has no lib/modules" >&2; exit 1; }

echo "==> extracting vendor_dlkm modules"
mkdir -p "$work/vendor_dlkm"
"$erofs_extract" --extract="$work/vendor_dlkm" "$stock_dir/vendor_dlkm.img" >/dev/null

modules_root="$work/vendor_dlkm/lib/modules"
[[ -d "$modules_root" ]] || { echo "could not find lib/modules in vendor_dlkm" >&2; exit 1; }

echo "==> installing prebuilts into $prebuilt"
# Keep prebuilt/README.md: it is tracked and documents the source and licence.
rm -rf "$prebuilt/vendor_boot" "$prebuilt/vendor" "$prebuilt/dtbs" \
       "$prebuilt/Image.lz4" "$prebuilt/dtbo.img"
mkdir -p "$prebuilt/vendor_boot" "$prebuilt/vendor" "$prebuilt/dtbs"

# Kernel image used only while building the throwaway boot image. The final
# vendor_boot packaging step never touches the kernel.
cp "$work/boot/kernel" "$prebuilt/Image.lz4"

# DTBO is reused verbatim by the build system.
cp "$stock_dir/dtbo.img" "$prebuilt/dtbo.img"

# The stock vendor_boot DTB is a MediaTek table (magic 0xd7b7ab1e) that wraps a
# single FDT. Extract the FDT for the build system; the packaging step keeps
# the original table byte-for-byte.
python3 - "$work/vendor_boot/dtb" "$prebuilt/dtbs/mt6878.dtb" <<'PY'
import struct
import sys

src, dst = sys.argv[1], sys.argv[2]
data = open(src, "rb").read()
fdt_magic = b"\xd0\x0d\xfe\xed"
offset = data.find(fdt_magic)
if offset < 0:
    raise SystemExit("no FDT found in vendor_boot dtb")
size = struct.unpack(">I", data[offset + 4:offset + 8])[0]
if offset + size > len(data):
    raise SystemExit("FDT size exceeds dtb payload")
open(dst, "wb").write(data[offset:offset + size])
print("FDT offset=%d size=%d" % (offset, size))
PY

# Full platform module set. Both modules.load and modules.load.recovery are
# copied because the recovery fragment loads a different subset.
find "$work/platform/lib/modules" -maxdepth 1 -type f \
    \( -name '*.ko' -o -name 'modules.load' -o -name 'modules.load.recovery' \
       -o -name 'modules.dep' -o -name 'modules.alias' -o -name 'modules.softdep' \) \
    -exec cp {} "$prebuilt/vendor_boot/" \;

# Touch drivers live in vendor_dlkm on Galaxian. ft3683g imports symbols from
# bootinfo and touchpanel_event_notify; bootinfo imports charger symbols.
for module in ft3683g.ko bootinfo.ko touchpanel_event_notify.ko; do
    if [[ ! -f "$modules_root/$module" ]]; then
        echo "missing vendor_dlkm module: $module" >&2
        exit 1
    fi
    cp "$modules_root/$module" "$prebuilt/vendor/"
done

required=(
    "$prebuilt/Image.lz4"
    "$prebuilt/dtbo.img"
    "$prebuilt/dtbs/mt6878.dtb"
    "$prebuilt/vendor_boot/modules.load"
    "$prebuilt/vendor_boot/modules.load.recovery"
    "$prebuilt/vendor/ft3683g.ko"
    "$prebuilt/vendor/bootinfo.ko"
    "$prebuilt/vendor/touchpanel_event_notify.ko"
)
for file in "${required[@]}"; do
    [[ -s "$file" ]] || { echo "prebuilt validation failed: $file" >&2; exit 1; }
done

printf 'platform modules: %s\n' "$(find "$prebuilt/vendor_boot" -name '*.ko' | wc -l)"
printf 'vendor touch modules: %s\n' "$(find "$prebuilt/vendor" -name '*.ko' | wc -l)"
printf 'prebuilt size: %s\n' "$(du -sh "$prebuilt" | cut -f1)"
echo "done: $prebuilt"
