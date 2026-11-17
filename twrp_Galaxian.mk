# Common Android 16 recovery product for the Nothing Phone (3a) Lite.
#
# The product is intentionally named twrp_Galaxian because TWRP, OrangeFox R12
# and AERA R1.0 all consume the TWRP product interface. The active recovery is
# selected by the vendor source tree and by vendorsetup.sh, not by a different
# lunch target.
#
# This is a recovery-only product. It intentionally does not inherit the
# LineageOS device tree so that the ROM tree keeps its own BoardConfig.mk.

# Base Android 16 recovery userspace.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Virtual A/B with the recovery ramdisk in vendor_boot.
#
# Stock Nothing OS 4.1 on Galaxian enables userspace snapshots and snapshot
# compression (ro.virtual_ab.compression.enabled=true), so use the VABC product
# definition instead of the older launch_with_vendor_ramdisk profile.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/vabc_features.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4
PRODUCT_VENDOR_PROPERTIES += ro.virtual_ab.compression.threads=true

# Device and recovery vendor configuration.
$(call inherit-product, device/nothing/Galaxian/device.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := Galaxian
PRODUCT_NAME := twrp_Galaxian
PRODUCT_BRAND := Nothing
PRODUCT_MODEL := A001T
PRODUCT_MANUFACTURER := Nothing
PRODUCT_RELEASE_NAME := Nothing Phone (3a) Lite
