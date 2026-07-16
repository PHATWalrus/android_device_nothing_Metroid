# Inherit from common AOSP product config - must be at the top
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# OrangeFox / TWRP common
$(call inherit-product, vendor/twrp/config/common.mk)

# Product identification
PRODUCT_DEVICE       := Metroid
PRODUCT_NAME         := twrp_Metroid
PRODUCT_BRAND        := Nothing
PRODUCT_MODEL        := Nothing Phone (3)
PRODUCT_MANUFACTURER := Nothing

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# A/B postinstall
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true
