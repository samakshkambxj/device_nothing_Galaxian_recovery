DEVICE_PATH := device/nothing/Galaxian

# The physical device reports first_api_level 34. Keep the real launch API
# while compiling the recovery userspace from the Android 16 source base.
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 34

# Virtual A/B recovery and fastbootd support.
AB_OTA_UPDATER := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    fastbootd \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# Stock Galaxian declares the AIDL boot-control HAL. Use the same default
# service as the ROM so update_engine_sideload can activate the inactive slot
# and OrangeFox's slot selector reports the correct slot.
PRODUCT_PACKAGES += \
    android.hardware.boot-service.default_recovery

# Stock Nothing OS 4.1 exposes AIDL Health version 2. The example recovery
# service satisfies that interface and reports battery state to the UI.
PRODUCT_PACKAGES += \
    android.hardware.health-service.example_recovery

# Libraries used by the display and Android FBE/metadata decrypt paths.
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.graphics.common@1.0 \
    libion \
    libkeymaster4 \
    libkeymaster41 \
    libpuresoftkeymasterdevice \
    libsysutils \
    libxml2

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.graphics.common@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libkeymaster4.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libkeymaster41.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libpuresoftkeymasterdevice.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libsysutils.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so

# Recovery properties.
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true \
    persist.sys.fuse.passthrough.enable=true

# AERA Recovery public configuration. Unknown AERA_* variables are ignored by
# TWRP and OrangeFox, so this can stay in the common product.
$(call inherit-product, $(DEVICE_PATH)/aera_Galaxian.mk)

PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)
