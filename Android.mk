LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),Metroid)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
