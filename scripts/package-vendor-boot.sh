#!/usr/bin/env bash
#
# Repack a freshly built recovery fragment into a Galaxian vendor_boot image
# and restore the stock AVB hash footer.
#
# This works for any recovery that produces the standard vendor_boot recovery
# fragment (TWRP, OrangeFox R12, AERA R1.0). The stock platform ramdisk, DTB,
# bootconfig and header fields are preserved byte-for-byte; only the "recovery"
# vendor-ramdisk fragment is replaced. This is required because the recovery
# fragment shares vendor_boot with the ROM's first-stage mount data and early
# kernel modules.
#
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree_dir=$(cd -- "$script_dir/.." && pwd)
magiskboot=${MAGISKBOOT:-magiskboot}
avbtool=${AVBTOOL:-avbtool}

stock_dir=
ramdisk=
out_dir="$tree_dir/out"
image_name=
label=Recovery
expected_sha=
partition_size=67108864

usage() {
    cat <<EOF
usage: $0 --stock <dir> --ramdisk <recovery.cpio.lz4> [options]

  --stock <dir>          directory containing boot.img, vendor_boot.img,
                         dtbo.img and vendor_dlkm.img (for reference)
  --ramdisk <file>       recovery fragment produced by the recovery build
                         (.../obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4)
  --out-dir <dir>        output directory (default: $out_dir)
  --name <file.img>      output file name
  --label <text>         recovery label in the default file name
                         (default: Recovery; e.g. TWRP, OrangeFox-R12, AERA-R1.0)
  --expected-sha256 <s>  refuse to package if the stock vendor_boot differs
  --partition-size <n>   vendor_boot partition size (default: $partition_size)

environment:
  MAGISKBOOT   path to magiskboot (default: magiskboot)
  AVBTOOL      path to avbtool   (default: avbtool)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stock) stock_dir=${2:?}; shift 2 ;;
        --ramdisk) ramdisk=${2:?}; shift 2 ;;
        --out-dir) out_dir=${2:?}; shift 2 ;;
        --name) image_name=${2:?}; shift 2 ;;
        --label) label=${2:?}; shift 2 ;;
        --expected-sha256) expected_sha=${2:?}; shift 2 ;;
        --partition-size) partition_size=${2:?}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
    esac
done

[[ -n "$stock_dir" ]] || { usage; exit 1; }
[[ -n "$ramdisk" ]] || { usage; exit 1; }
stock_dir=$(cd -- "$stock_dir" && pwd)
[[ -f "$ramdisk" ]] || { echo "missing recovery ramdisk: $ramdisk" >&2; exit 1; }

for tool in "$magiskboot" "$avbtool" sha256sum python3; do
    command -v "$tool" >/dev/null 2>&1 || { echo "missing tool: $tool" >&2; exit 1; }
done

stock_image="$stock_dir/vendor_boot.img"
[[ -f "$stock_image" ]] || { echo "missing stock vendor_boot: $stock_image" >&2; exit 1; }

if [[ -n "$expected_sha" ]]; then
    actual_sha=$(sha256sum "$stock_image" | awk '{print $1}')
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        echo "stock vendor_boot hash mismatch" >&2
        echo "expected: $expected_sha" >&2
        echo "actual:   $actual_sha" >&2
        exit 1
    fi
fi

info=$(avbtool info_image --image "$stock_image")
salt=$(printf '%s\n' "$info" | sed -n 's/^ *Salt: *//p' | head -n1)
fingerprint=$(printf '%s\n' "$info" | sed -n "s/^ *Prop: com.android.build.vendor_boot.fingerprint -> '\(.*\)'/\1/p" | head -n1)
[[ -n "$salt" ]] || { echo "could not read AVB salt from stock vendor_boot" >&2; exit 1; }
[[ -n "$fingerprint" ]] || { echo "could not read vendor_boot fingerprint" >&2; exit 1; }

incremental=${fingerprint##*/}
[[ "$incremental" =~ ^[0-9]+$ ]] || incremental=unknown
if [[ -z "$image_name" ]]; then
    image_name="Galaxian-NOS41-${incremental}-${label}-vendor_boot.img"
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/galaxian-vendorboot.XXXXXX")
trap 'rm -rf "$work"' EXIT

echo "==> unpacking stock vendor_boot"
mkdir -p "$work/unpack"
(
    cd "$work/unpack"
    rc=0
    "$magiskboot" unpack "$stock_image" >/dev/null || rc=$?
    [[ $rc -eq 0 || $rc -eq 3 ]] || { echo "could not unpack vendor_boot (status $rc)" >&2; exit 1; }
)
[[ -f "$work/unpack/vendor_ramdisk/ramdisk.cpio" ]] || { echo "stock vendor_boot has no platform ramdisk" >&2; exit 1; }
[[ -f "$work/unpack/vendor_ramdisk/recovery.cpio" ]] || { echo "stock vendor_boot has no recovery fragment" >&2; exit 1; }

platform_size=$(stat -c %s "$work/unpack/vendor_ramdisk/ramdisk.cpio")
echo "    platform ramdisk (raw): $platform_size bytes"

echo "==> installing OrangeFox recovery fragment"
# Accept either lz4-compressed (normal build output) or raw cpio.
magic=$(od -An -tx1 -N4 "$ramdisk" | tr -d ' \n')
if [[ "$magic" == "04224d18" || "$magic" == "02214c18" ]]; then
    "$magiskboot" decompress "$ramdisk" "$work/unpack/vendor_ramdisk/recovery.cpio"
else
    cp "$ramdisk" "$work/unpack/vendor_ramdisk/recovery.cpio"
fi
recovery_size=$(stat -c %s "$work/unpack/vendor_ramdisk/recovery.cpio")
echo "    recovery ramdisk (raw): $recovery_size bytes"

echo "==> repacking (platform ramdisk, DTB and bootconfig preserved)"
(
    cd "$work/unpack"
    "$magiskboot" repack "$stock_image" "$work/unsigned.img" >/dev/null
)

echo "==> restoring AVB hash footer (algorithm NONE, stock salt)"
avbtool erase_footer --image "$work/unsigned.img"
avbtool add_hash_footer \
    --image "$work/unsigned.img" \
    --partition_size "$partition_size" \
    --partition_name vendor_boot \
    --algorithm NONE \
    --salt "$salt" \
    --prop "com.android.build.vendor_boot.fingerprint:$fingerprint"
avbtool verify_image --image "$work/unsigned.img"

actual_size=$(stat -c %s "$work/unsigned.img")
if [[ "$actual_size" -ne "$partition_size" ]]; then
    echo "packaged image is $actual_size bytes, expected $partition_size" >&2
    exit 1
fi

mkdir -p "$out_dir"
cp "$work/unsigned.img" "$out_dir/$image_name"
restore_name="${image_name%-vendor_boot.img}-OFFICIAL-RESTORE-vendor_boot.img"
cp "$stock_image" "$out_dir/$restore_name"

sha256sum "$out_dir/$image_name" "$out_dir/$restore_name" | tee "$out_dir/SHA256SUMS"
echo "packaged: $out_dir/$image_name"
