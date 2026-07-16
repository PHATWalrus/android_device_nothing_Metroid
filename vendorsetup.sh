# OrangeFox build vars for Nothing Phone (3) — Metroid

FDEVICE="Metroid"

fox_get_target_device() {
local chkdev=$(echo "$BASH_SOURCE" | grep -w $FDEVICE)
   if [ -n "$chkdev" ]; then 
      FOX_BUILD_DEVICE="$FDEVICE"
   else
      chkdev=$(set | grep BASH_ARGV | grep -w $FDEVICE)
      [ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
   fi
}

if [ -z "$1" -a -z "$FOX_BUILD_DEVICE" ]; then
   fox_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
    #

    # Target Architecture
    export TARGET_ARCH="arm64"

    # About Us
    export FOX_MAINTAINER_PATCH_VERSION="1"
    export OF_MAINTAINER="@phattylol"
    export FOX_BUILD_TYPE="Unofficial"
    export FOX_CUSTOM_OUT_NAME="orangefox-Metroid"


    # Build Environment Stuff
    export FOX_BUILD_DEVICE="Metroid"
    export ALLOW_MISSING_DEPENDENCIES=true
    export TARGET_DEVICE_ALT="Metroid,metroid"
    export FOX_TARGET_DEVICES="Metroid,metroid"
    export TW_DEFAULT_LANGUAGE="en"
    export LC_ALL="C"

    # Use Magisk Boot for Patching
    export OF_USE_MAGISKBOOT=1
    export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1

    # We Have A/B Partitions
    export FOX_AB_DEVICE=1
    export FOX_VIRTUAL_AB_DEVICE=1
    export OF_AB_DEVICE_WITH_RECOVERY_PARTITION=1

    # Screen Specifications
    export OF_STATUS_INDENT_LEFT=48
    export OF_STATUS_INDENT_RIGHT=48
    export OF_DEFAULT_KEYMASTER_VERSION=4.1
    export OF_ALLOW_DISABLE_NAVBAR=0
    # Display — 1260x2800, no physical select button
    export OF_SCREEN_H=2800
    export OF_STATUS_H=180
    export OF_STATUS_INDENT_LEFT=48
    export OF_STATUS_INDENT_RIGHT=48
    export OF_HIDE_NOTCH=1
    export OF_CLOCK_POS=1

    # Device Stuff
    export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
    export OF_FBE_METADATA_MOUNT_IGNORE=1
    export OF_PATCH_AVB20=1
    export FOX_USE_NANO_EDITOR=1
    export FOX_ENABLE_APP_MANAGER=0
    export FOX_DELETE_AROMAFM=1
    export OF_DONT_PATCH_ON_FRESH_INSTALLATION=1
    export OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR=1
    export OF_NO_ADDITIONAL_MIUI_PROPS_CHECK=1
    export OF_RUN_POST_FORMAT_PROCESS=1
    export OF_USE_LEGACY_BATTERY_SERVICES=1
    export FOX_USE_UPDATED_MAGISKBOOT=1
    export OF_IGNORE_LOGICAL_MOUNT_ERRORS=1
    export OF_DISABLE_OTA_MENU=1
    export OF_DISABLE_MIUI_OTA_BY_DEFAULT=1
    export OF_DYNAMIC_FULL_SIZE=7516192768

    # Quick Backup List
    export FOX_R11=1
    export OF_QUICK_BACKUP_LIST="/boot;/dtbo;/data;/system_image;/vendor_image;"

    # Add Some Extras
    export FOX_ENABLE_SUKISU_SUPPORT=1
    export FOX_ENABLE_KERNELSU_NEXT_SUPPORT=1
    export FOX_ENABLE_KERNELSU_SUPPORT=1
    export FOX_ALLOW_EARLY_SETTINGS_LOAD=1
    export FOX_USE_ZIP_BINARY=1
    export FOX_USE_TAR_BINARY=1
    export FOX_ASH_IS_BASH=1
    export FOX_REPLACE_BUSYBOX_PS=1
    export FOX_USE_BASH_SHELL=1
    export OF_USE_LZ4_COMPRESSION=1
    export OF_DONT_KEEP_LOG_HISTORY=0
    export OF_NO_SPLASH_CHANGE=0
    export FOX_INSTALLER_DISABLE_AUTOREBOOT=1
    export OF_USE_GREEN_LED=0
    export FOX_RESET_SETTINGS=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_ENABLE_APP_MANAGER=1
    export FOX_REPLACE_TOOLBOX_GETPROP=1
    export OF_OPTIONS_LIST_NUM=8
    export FOX_ALLOW_EARLY_SETTINGS_LOAD=1
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=$(pwd)/out/.ccache
    mkdir -p "$CCACHE_DIR"
    ccache -M 100G -F 0
fi

