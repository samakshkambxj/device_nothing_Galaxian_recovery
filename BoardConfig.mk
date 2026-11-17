#
# Common recovery device configuration for the Nothing Phone (3a) Lite.
#
# Target: stock Nothing OS 4.1 for Galaxian / A001T (MT6878), build
# B4.1-261029-1756. The same board configuration is used to build TWRP,
# OrangeFox R12 and AERA R1.0 from their respective Android 16 source trees.
# It is recovery-only and intentionally shares no makefiles with the LineageOS
# device tree.
#

DEVICE_PATH := device/nothing/Galaxian
KERNEL_PATH := $(DEVICE_PATH)/prebuilt

# The minimal TWRP manifest intentionally omits non-recovery components.
ALLOW_MISSING_DEPENDENCIES := true

# A/B and dynamic partitions
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76
TARGET_CPU_VARIANT_RUNTIME := cortex-a76
IGNORE_PREFER32_ON_DEVICE := true

# APEX
OVERRIDE_TARGET_FLATTEN_APEX := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := Galaxian
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_HEIGHT := 2392
TARGET_SCREEN_WIDTH := 1084
TARGET_SCREEN_DENSITY := 420

# Kernel and vendor_boot. Values match the stock Galaxian build.
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/Image.lz4
TARGET_FORCE_PREBUILT_KERNEL := true
BOARD_KERNEL_IMAGE_NAME := Image.lz4

BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_KERNEL_TAGS_OFFSET := 0x07c88000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_DTB_OFFSET := 0x07c88000
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true

BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_KERNEL_CMDLINE += log_buf_len=1M
BOARD_KERNEL_CMDLINE += sysctl.kernel.sched_pelt_multiplier=4
BOARD_KERNEL_CMDLINE += androidboot.console=0
BOARD_KERNEL_CMDLINE += kasan=off
BOARD_KERNEL_CMDLINE += rcupdate.rcu_expedited=1 rcu_nocbs=all rcutree.enable_rcu_lazy

BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# A single FDT is embedded in the stock MT6878 DTB table. It is extracted by
# scripts/extract-prebuilts.sh into prebuilt/dtbs/mt6878.dtb. The final image
# produced by scripts/package-vendor-boot.sh always reuses the untouched stock
# DTB table, so this copy only has to satisfy the build system.
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtbs
TARGET_PREBUILT_DTB := $(KERNEL_PATH)/dtbs/mt6878.dtb
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img

# Stock vendor_boot module set. scripts/extract-prebuilts.sh fills
# prebuilt/vendor_boot/ from the platform ramdisk of the target vendor_boot.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_boot/modules.load))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(sort $(addprefix $(KERNEL_PATH)/vendor_boot/, $(notdir $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD))))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_boot/modules.load.recovery))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES := $(sort $(addprefix $(KERNEL_PATH)/vendor_boot/, $(notdir $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD))))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES += $(filter-out $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES),$(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES))

# Partitions
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608

BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := nothing_dynamic_partitions
BOARD_NOTHING_DYNAMIC_PARTITIONS_PARTITION_LIST := odm odm_dlkm product system system_dlkm system_ext vendor vendor_dlkm
BOARD_NOTHING_DYNAMIC_PARTITIONS_SIZE := 9659482112

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_USES_METADATA_PARTITION := true
BOARD_ROOT_EXTRA_FOLDERS += metadata

# Platform
BOARD_HAS_MTK_HARDWARE := true
BOARD_USES_MTK_HARDWARE := true
TARGET_BOARD_PLATFORM := mt6878

# Recovery lives in the header-v4 recovery fragment of vendor_boot.
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/recovery.fstab
# The recovery fstab already contains the stock Nothing OS 4.1 metadata-FBE
# flags. Re-parsing a mounted vendor copy makes recovery block at
# "Using additional fstab for decryption" and then restart.
TW_SKIP_ADDITIONAL_FSTAB := true
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_USERIMAGES_USE_F2FS := true

# Build the native Android 16 KeyMint, GateKeeper, Keystore2 and metadata-FBE
# stack. The recovery ramdisk starts the ROM-matched Trustonic services in the
# background before this path unwraps the metadata key.
TW_INCLUDE_CRYPTO := true
TW_USE_FSCRYPT_POLICY := 2

# Stock Galaxian declares the AIDL boot-control HAL. Make both
# update_engine_sideload and OrangeFox's slot selector use that interface.
OF_USE_AIDL_BOOT_CONTROL := 1

# Recreate the correct user-0 media path after Format Data and rebuild the MTP
# export around it.
OF_BIND_MOUNT_SDCARD_ON_FORMAT := 1

# Security levels from the stock Nothing OS 4.1 build.
PLATFORM_SECURITY_PATCH := 2026-04-05
VENDOR_SECURITY_PATCH := 2026-04-05
PLATFORM_VERSION := 16.0.0

# Verified Boot. Stock Galaxian vendor_boot uses an AVB hash footer with
# algorithm NONE and the MediaTek test key material is not involved. The build
# below only has to produce a valid intermediate image; the final image is
# signed by scripts/package-vendor-boot.sh using the exact stock salt and
# fingerprint.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_ROLLBACK_INDEX := 0
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
BOARD_AVB_VENDOR_BOOT_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VENDOR_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := 0
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 6

# OrangeFox/TWRP UI and recovery tools
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := false
# The RTC already carries the correct Unix epoch on this MediaTek device. Use
# the owner's timezone so the displayed clock matches Android. Adjust with
# OF_DEFAULT_TIMEZONE/OF_FORCE_TIMEZONE if the device is used elsewhere.
OF_DEFAULT_TIMEZONE := IST-5:30
OF_FORCE_TIMEZONE := IST-5:30
# OrangeFox's Android 16 tree keys these features with TWRP_INCLUDE_LOGCAT and
# TARGET_USES_LOGD; the older aliases silently omit logd from the recovery
# ramdisk and hide Keystore2 decryption diagnostics.
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_PYTHON := false
TW_USE_TOOLBOX := true
# Recovery links against Magisk's resetprop library when repack tools are
# enabled; explicitly retain it in the recovery ramdisk.
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libresetprop.so
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 1023
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_FRAMERATE := 60
TW_DEVICE_VERSION := Nothing Phone (3a) Lite
TW_CUSTOM_BATTERY_PATH := /sys/class/power_supply/battery
TW_USE_LEGACY_BATTERY_SERVICES := true
# hbtp_vm is a MediaTek virtual input device. Blacklist it so TWRP binds the
# FT3683G touchscreen ("fts_ts") instead.
TW_INPUT_BLACKLIST := hbtp_vm
TW_Y_OFFSET := 95
TW_H_OFFSET := -95
TW_NO_SCREEN_BLANK := true

# Load the exact recovery subset from the preserved vendor_boot platform
# ramdisk. The FT3683G touchscreen lives in vendor_dlkm, not vendor_boot, so
# request the ROM-matched driver, the touch notification helpers and bootinfo's
# charger dependencies explicitly.
#
# ft3683g.ko imports symbols from bootinfo.ko and touchpanel_event_notify.ko.
# bootinfo.ko imports one symbol from each of the four charger providers, which
# are present in the stock platform ramdisk but are not part of
# modules.load.recovery. Load the providers first, then bootinfo, then the
# touch notification helper, then the driver.
GALAXIAN_RECOVERY_PROVIDER_MODULES := \
    sc8541_charger.ko \
    upm6720_charger.ko \
    nu2115_charger.ko \
    sgm41606S_charger.ko
GALAXIAN_RECOVERY_TOUCH_MODULES := \
    bootinfo.ko \
    touchpanel_event_notify.ko \
    ft3683g.ko
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_VENDOR_BOOT_MODULES := true
# Keep the driver list on one line: recovery turns it into its modules list.
# Do not sort the provider prefix: bootinfo imports one symbol from each of
# these four modules.
GALAXIAN_RECOVERY_SORTED_MODULES := $(filter-out $(GALAXIAN_RECOVERY_PROVIDER_MODULES),$(sort $(notdir $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)) $(GALAXIAN_RECOVERY_TOUCH_MODULES)))
TW_LOAD_VENDOR_MODULES := $(GALAXIAN_RECOVERY_PROVIDER_MODULES) $(GALAXIAN_RECOVERY_SORTED_MODULES)

# The three vendor_dlkm touch modules must also be packed into the recovery
# fragment so they exist under /lib/modules after the fragments are merged.
GALAXIAN_VENDOR_TOUCH_MODULES := $(addprefix $(KERNEL_PATH)/vendor/,$(GALAXIAN_RECOVERY_TOUCH_MODULES))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES += $(GALAXIAN_VENDOR_TOUCH_MODULES)

# AERA Recovery R1.0 public configuration. AERA's aera_config.mk translates
# these into the TW_*/OF_* names consumed by the inherited recovery backend.
# The settings are harmless in TWRP and OrangeFox workspaces.
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2
AERA_SKIP_ADDITIONAL_FSTAB := true
AERA_USE_AIDL_BOOT_CONTROL := 1
AERA_USE_DMCTL := 1
AERA_INCLUDE_FASTBOOTD := true
AERA_INCLUDE_LOGCAT := true
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_USE_TOOLBOX := true
AERA_INCLUDE_ZSTD := true
AERA_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
AERA_LOAD_VENDOR_BOOT_MODULES := true
AERA_LOAD_PREBUILT_MODULES_AT_FIRST := true
AERA_LOAD_VENDOR_MODULES := $(TW_LOAD_VENDOR_MODULES)
AERA_INPUT_BLACKLIST := "hbtp_vm"
AERA_THEME := portrait_hdpi
AERA_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
AERA_MAX_BRIGHTNESS := 2047
AERA_DEFAULT_BRIGHTNESS := 1023
AERA_FRAMERATE := 60
AERA_NO_SCREEN_BLANK := true
AERA_DEVICE_VERSION := Nothing_Phone_3a_Lite
AERA_ENABLE_FS_COMPRESSION := true
AERA_USE_LZ4_COMPRESSION := 1
AERA_EXCLUDE_APEX := true
