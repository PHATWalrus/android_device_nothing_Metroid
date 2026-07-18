DEVICE_PATH := device/nothing/Metroid

$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_RELEASE_NAME := Metroid
PRODUCT_DEVICE := Metroid
PRODUCT_NAME := twrp_Metroid
PRODUCT_BRAND := Nothing
PRODUCT_MODEL := A024
PRODUCT_MANUFACTURER := Nothing

TARGET_OTA_ASSERT_DEVICE := Metroid,metroid,A024
