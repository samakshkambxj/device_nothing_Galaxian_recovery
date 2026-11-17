#!/usr/bin/env bash
#
# Apply the source patches for one recovery target.
#
# The device tree is shared by TWRP, OrangeFox R12 and AERA R1.0. TWRP and
# AERA use their own upstream source sets and need no device-side patch here.
# OrangeFox R12 needs the series in patches/orangefox.
#
# Usage:
#   ./scripts/apply-recovery-patches.sh [--recovery twrp|orangefox|aera|auto]
#                                       [--patches <dir>] [--check] [--list]
#
# Environment:
#   GALAXIAN_RECOVERY           default recovery when --recovery is not given
#   GALAXIAN_RECOVERY_PATCHES   override the patch-set directory
#   ANDROID_BUILD_TOP           workspace root (required for OrangeFox)
#
# With --recovery auto the script detects AERA from AERA_PRODUCT_PREFIX,
# OrangeFox from FOX_BUILD_DEVICE, and otherwise assumes TWRP.
#
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree_dir=$(cd -- "$script_dir/.." && pwd)
recovery=${GALAXIAN_RECOVERY:-auto}
explicit_patches=${GALAXIAN_RECOVERY_PATCHES:-}
check_only=0
list_only=0

usage() {
    sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --recovery) recovery=${2:?}; shift 2 ;;
        --patches) explicit_patches=${2:?}; shift 2 ;;
        --check) check_only=1; shift ;;
        --list) list_only=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

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

if [[ "$recovery" == auto ]]; then
    recovery=$(detect_recovery)
fi

case "$recovery" in
    twrp|orangefox|aera) ;;
    *)
        echo "unknown recovery: $recovery (expected twrp, orangefox, aera or auto)" >&2
        exit 1
        ;;
esac

if [[ "$list_only" -eq 1 ]]; then
    echo "twrp       no device-side patch series (upstream TWRP sources)"
    echo "orangefox  patches/orangefox (R12 format-data, data mapping, sideload)"
    echo "aera       no device-side patch series (AERA vendor patch flow)"
    exit 0
fi

if [[ -n "$explicit_patches" ]]; then
    patches_dir=$explicit_patches
else
    patches_dir="$tree_dir/patches/$recovery"
fi

if [[ "$recovery" != orangefox ]]; then
    echo "recovery: $recovery"
    echo "no device-side source patches are required for $recovery."
    if [[ "$recovery" == aera ]]; then
        echo "use the AERA R1.0 manifest and its own patch flow, then build twrp_Galaxian."
    fi
    exit 0
fi

build_top=${ANDROID_BUILD_TOP:-}
[[ -n "$build_top" ]] || { echo "ANDROID_BUILD_TOP is not set" >&2; exit 1; }
[[ -d "$patches_dir" ]] || { echo "patch directory not found: $patches_dir" >&2; exit 1; }

apply() {
    local repo=$1 patch=$2 required=${3:-required}
    local target="$build_top/$repo"
    if [[ ! -d "$target" ]]; then
        if [[ "$required" == optional ]]; then
            echo "skip (missing repo): $repo"
            return 0
        fi
        echo "missing repo: $target" >&2
        exit 1
    fi
    if ! git -C "$target" apply --check "$patch" 2>/dev/null; then
        if git -C "$target" apply --reverse --check "$patch" 2>/dev/null; then
            echo "already applied: $(basename "$patch") -> $repo"
            return 0
        fi
        echo "does not apply cleanly: $(basename "$patch") -> $repo" >&2
        [[ "$required" == optional ]] && return 0
        exit 1
    fi
    echo "check ok: $(basename "$patch") -> $repo"
    if [[ "$check_only" -eq 0 ]]; then
        git -C "$target" apply "$patch"
    fi
}

echo "recovery: orangefox"
apply bootable/recovery "$patches_dir/orangefox16-r12-v16-format-data-wipe.patch"
apply bootable/recovery "$patches_dir/orangefox16-r12-v17-data-format-mapping.patch"
apply bootable/recovery "$patches_dir/orangefox16-r12-nothingos41-v8-sigpipe.patch"
apply hardware/interfaces "$patches_dir/android16-health-vintf-v15.patch" optional
apply system/security "$patches_dir/android16-keystore-kmsg-v15.patch" optional

echo
if [[ -d "$patches_dir/legacy" ]]; then
    echo "not applied: patches/orangefox/legacy (vendor, UI, runtime and v18 series)"
    echo "Those were written against the OrangeFox16 fork snapshot, not the current"
    echo "fox_16.0 tree. See patches/orangefox/README.md before using them."
    echo
fi
if [[ "$check_only" -eq 1 ]]; then
    echo "all required patches apply cleanly (nothing was changed)"
else
    echo "OrangeFox patch series applied"
fi
