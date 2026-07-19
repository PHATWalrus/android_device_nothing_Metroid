DEVICE_PATH := device/nothing/Metroid

$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product-if-exists, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, $(DEVICE_PATH)/fox_Metroid.mk)
$(call inherit-product, $(DEVICE_PATH)/proprietary-blobs.mk)

PRODUCT_USE_DYNAMIC_PARTITIONS := true
ENABLE_VIRTUAL_AB := true

METROID_ENABLE_FBE ?= true
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.boot.product.vendor.sku=tuna \
    sys.usb.configfs=1 \
    sys.usb.controller=a600000.dwc3 \
    ro.recovery.usb.vid=18D1 \
    ro.recovery.usb.adb.pid=D001 \
    ro.recovery.usb.fastboot.pid=4EE0

ifeq ($(METROID_ENABLE_FBE),true)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.recovery.metroid.fbe=1
else
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.recovery.metroid.fbe=0
endif

# ap2a source compatibility.
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 34

PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl-qti.recovery \
    android.hardware.fastboot@1.1-impl-mock \
    bootctrl.sun.recovery \
    fastbootd \
    service

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/recovery.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/recovery.fstab \
    $(DEVICE_PATH)/twrp.flags:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/twrp.flags \
    $(DEVICE_PATH)/recovery/root/init.recovery.qcom.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.qcom.rc \
    $(DEVICE_PATH)/recovery/root/vendor/etc/ueventd.rc:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/ueventd.rc \
    $(DEVICE_PATH)/recovery/root/vendor/firmware/focaltech_ts_fw_boe.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/focaltech_ts_fw_boe.bin \
    $(DEVICE_PATH)/recovery/root/vendor/lib/modules/panel_event_notifier.ko:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/panel_event_notifier.ko \
    $(DEVICE_PATH)/recovery/root/vendor/lib/modules/touchpanel_event_notify.ko:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/touchpanel_event_notify.ko \
    $(DEVICE_PATH)/recovery/root/vendor/lib/modules/qts.ko:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/qts.ko \
    $(DEVICE_PATH)/recovery/root/vendor/lib/modules/focaltech_tp.ko:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/focaltech_tp.ko
