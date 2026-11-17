#!/usr/bin/env bash
#
# Build a recovery for the Nothing Phone (3a) Lite inside an Android 16
# workspace. The same device tree and the same product serve TWRP, OrangeFox
# R12 and AERA R1.0; the selected recovery only changes the vendor source tree
# and post-build packaging.
#
# Usage:
#   ANDROID_BUILD_TOP=~/aosp16 ./scripts/build-recovery.sh [options]
#
# Options:
#   --recovery <twrp|orangefox|aera|auto>   default: auto
#   --variant <eng|userdebug|user>          default: eng
#   --target <make-target>                  default: vendorbootimage
#                                           (adbd vendorbootimage for AERA)
#   --jobs <n>                              passed to mka
#   --list                                  list recovery targets
#
# With --recovery auto the script detects AERA from AERA_PRODUCT_PREFIX,
# OrangeFox from FOX_BUILD_DEVICE, and otherwise assumes TWRP.
#
# The tree must be linked or copied to device/nothing/Galaxian first:
#   ln -s "$PWD" "$ANDROID_BUILD_TOP/device/nothing/Galaxian"
#
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree_dir=$(cd -- "$script_dir/.." && pwd)
recovery=${GALAXIAN_RECOVERY:-auto}
variant=eng
target=
jobs=

detect_recovery() {
    if [[ -n "${GALAXIAN_RECOVERY:-}" && "${GALAXIAN_RECOVERY}" != auto ]]; then
        echo "$GALAXIAN_RECOVERY"
    elif [[ -n "${AERA_PRODUCT_PREFIX:-}" ]]; then
        echo aera
    elif [[ -n "${FOX_BUILD_DEVICE:-}" ]]; then
        echo orangefox
    else
        echo twrp
    fi
}

usage() {
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --recovery) recovery=${2:?}; shift 2 ;;
        --variant) variant=${2:?}; shift 2 ;;
        --target) target=${2:?}; shift 2 ;;
        --jobs) jobs=${2:?}; shift 2 ;;
        --list)
            echo "twrp       Android 16 TWRP sources"
            echo "orangefox  OrangeFox R12 (fox_16.0-R12)"
            echo "aera       AERA Recovery R1.0"
            exit 0
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ "$recovery" == auto ]]; then
    recovery=$(detect_recovery)
fi

case "$recovery" in
    twrp|orangefox|aera) ;;
    *) echo "unknown recovery: $recovery" >&2; exit 1 ;;
esac

case "$variant" in
    eng|userdebug|user) ;;
    *) echo "unknown variant: $variant" >&2; exit 1 ;;
esac

if [[ -z "$target" ]]; then
    if [[ "$recovery" == aera ]]; then
        target="adbd vendorbootimage"
    else
        target=vendorbootimage
    fi
fi

build_top=${ANDROID_BUILD_TOP:-}
if [[ -z "$build_top" ]]; then
    echo "ANDROID_BUILD_TOP is not set. Source build/envsetup.sh or set it explicitly." >&2
    exit 1
fi

if [[ ! -d "$build_top" ]]; then
    echo "workspace not found: $build_top" >&2
    exit 1
fi

cd "$build_top"
# shellcheck disable=SC1091
source build/envsetup.sh

lunch "twrp_Galaxian-bp2a-$variant"

mka_args=()
[[ -n "$jobs" ]] && mka_args+=("-j$jobs")
read -r -a targets <<< "$target"
mka "${mka_args[@]}" "${targets[@]}"

product_out="$build_top/out/target/product/Galaxian"
fragment=
for candidate in \
    "$product_out/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4" \
    "$product_out/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio" \
    "$product_out/obj/PACKAGING/recovery_ramdisk_intermediates/recovery.cpio.lz4"; do
    if [[ -f "$candidate" ]]; then
        fragment=$candidate
        break
    fi
done
if [[ -z "$fragment" ]]; then
    fragment=$(find "$product_out" -type f \( -name recovery.cpio.lz4 -o -name recovery.cpio \) 2>/dev/null | head -n 1 || true)
fi

echo
echo "recovery: $recovery"
echo "target:   $target"
if [[ -n "$fragment" ]]; then
    echo "fragment: $fragment"
    echo "package it with:"
    echo "  $tree_dir/scripts/package-vendor-boot.sh \\"
    echo "      --stock <stock-dump> --ramdisk $fragment --label $recovery"
else
    echo "warning: no recovery.cpio fragment found under $product_out" >&2
    echo "If the target completed, try 'mka vendorbootimage' and rerun this check," >&2
    echo "or inspect $product_out/obj/PACKAGING for the produced file." >&2
fi
