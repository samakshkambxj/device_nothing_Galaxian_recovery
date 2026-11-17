#!/bin/bash
#
# Common build environment for TWRP, OrangeFox R12 and AERA R1.0.
#
# The same twrp_Galaxian product is used by all three recoveries. Only the
# vendor source tree and its environment variables differ. Set GALAXIAN_RECOVERY
# explicitly when more than one recovery vendor tree is present.

build_top=${ANDROID_BUILD_TOP:-}

if [ -n "${GALAXIAN_RECOVERY:-}" ] && [ "${GALAXIAN_RECOVERY}" != "auto" ]; then
    recovery=${GALAXIAN_RECOVERY}
elif [ -n "$build_top" ] && [ -f "$build_top/vendor/recovery/AERA_A16.sh" ]; then
    recovery=aera
elif [ -n "$build_top" ] && [ -f "$build_top/vendor/recovery/config/common.mk" ]; then
    recovery=orangefox
else
    recovery=twrp
fi

export GALAXIAN_RECOVERY="$recovery"
export TARGET_DEVICE_ALT="Galaxian,A001T,galaxian"

case "$recovery" in
orangefox)
    # OrangeFox 16 build identity and vendor_boot layout.
    export FOX_BUILD_DEVICE="Galaxian"
    export FOX_TARGET_DEVICES="Galaxian,A001T,galaxian"
    export FOX_AB_DEVICE=1
    export FOX_VIRTUAL_AB_DEVICE=1
    export FOX_VENDOR_BOOT_RECOVERY=1
    export FOX_BUILD_TYPE="Unofficial"
    export OF_MAINTAINER="samakshkambxj"

    # Nothing Phone (3a) Lite display geometry: 1084 x 2392, 420 dpi.
    export OF_SCREEN_H=2392
    export OF_STATUS_H=95
    export OF_STATUS_INDENT_LEFT=48
    export OF_STATUS_INDENT_RIGHT=48
    export OF_CLOCK_POS=1
    export OF_ALLOW_DISABLE_NAVBAR=0
    export OF_HIDE_NOTCH=1

    # Non-Xiaomi Android 16 recovery behaviour.
    export OF_TWRP_COMPATIBILITY_MODE=1
    export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
    export OF_NO_MIUI_PATCH_WARNING=1
    export OF_NO_ADDITIONAL_MIUI_PROPS_CHECK=1
    export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
    export OF_DISABLE_OTA_MENU=1

    # Keep AVB and encryption policy unchanged. The ROM's hardware
    # KeyMint/Gatekeeper stack only unlocks existing FBE data. Advanced
    # Security would hide ADB and MTP until decryption succeeds.
    export OF_ADVANCED_SECURITY=0
    export OF_DONT_PATCH_ENCRYPTED_DEVICE=1
    export OF_KEEP_DM_VERITY=1
    export OF_KEEP_FORCED_ENCRYPTION=1
    export OF_FBE_METADATA_MOUNT_IGNORE=0
    export OF_FIX_DECRYPTION_ON_DATA_MEDIA=1

    # vendor_boot is a strict 64 MiB partition and the stock platform ramdisk
    # already occupies about 34 MiB.
    export FOX_DRASTIC_SIZE_REDUCTION=1
    export FOX_REMOVE_BASH=1
    export FOX_EXCLUDE_NANO_EDITOR=1
    export FOX_ENABLE_APP_MANAGER=0
    export OF_FLASHLIGHT_ENABLE=0
    export OF_USE_GREEN_LED=0
    export FOX_DISABLE_UPDATEZIP=1
    export OF_NO_REFLASH_CURRENT_ORANGEFOX=1
    ;;

aera)
    # AERA Recovery R1.0 public configuration namespace.
    export AERA_PRODUCT_PREFIX=AERA
    export AERA_BUILD_STATUS=Unofficial
    export AERA_BUILD_TYPE=Beta
    export AERA_AB_DEVICE=1
    export AERA_VIRTUAL_AB_DEVICE=1
    export AERA_VENDOR_BOOT_RECOVERY=1
    export AERA_TARGET_DEVICES="Galaxian,A001T,galaxian"
    export AERA_BUILD_DEVICE="Galaxian"
    export AERA_MAINTAINER="samakshkambxj"

    # Keep the recovery fragment small enough for the 64 MiB vendor_boot.
    export AERA_DRASTIC_SIZE_REDUCTION=1
    export AERA_DELETE_AROMAFM=1
    export AERA_DELETE_MAGISK_ADDON=1
    export AERA_ENABLE_ROOT_MANAGER=0
    export AERA_INCLUDE_OMAPI=0
    export AERA_ENABLE_WLAN=0

    # Tools used by the AERA installer and by recovery-side image handling.
    export AERA_USE_UPDATED_MAGISKBOOT=1
    export AERA_USE_FSCK_EROFS_BINARY=1
    export AERA_USE_TAR_BINARY=1
    export AERA_USE_SED_BINARY=1
    export AERA_USE_LZ4_BINARY=1
    export AERA_USE_ZSTD_BINARY=1
    export AERA_USE_DATE_BINARY=1
    export AERA_USE_GREP_BINARY=1
    export AERA_USE_BUSYBOX_BINARY=1
    export AERA_USE_XZ_UTILS=1
    # AERA_USE_DMCTL is set in BoardConfig.mk. AERA rejects using the legacy
    # dmsetup interface at the same time, so do not export AERA_USE_DMSETUP.

    export AERA_SETTINGS_ROOT_DIRECTORY=/data/recovery
    export AERA_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard
    ;;

twrp)
    # TWRP reads the common TW_* variables from BoardConfig.mk. No vendor
    # environment is required.
    ;;
esac
