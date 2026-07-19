#!/usr/bin/env bash
# OrangeFox environment.

FDEVICE="Metroid"

fox_get_target_device() {
    local script_path="${BASH_SOURCE[0],,}"

    if [[ "$script_path" == *"/device/nothing/metroid/"* ]]; then
        export FOX_BUILD_DEVICE="$FDEVICE"
    fi
}

if [[ -z "${FOX_BUILD_DEVICE:-}" ]]; then
    fox_get_target_device
fi

requested_device="${1:-}"
if [[ "${requested_device,,}" == "${FDEVICE,,}" || "${FOX_BUILD_DEVICE,,}" == "${FDEVICE,,}" ]]; then
    export FOX_BUILD_DEVICE="$FDEVICE"
    export TARGET_ARCH="arm64"
    export LC_ALL="C"

    export FOX_BUILD_TYPE="Unofficial"
    export FOX_MAINTAINER_PATCH_VERSION="1"

    # Device aliases.
    export TARGET_DEVICE_ALT="metroid,A024"
    export FOX_TARGET_DEVICES="Metroid,metroid,A024"

    export TW_DEFAULT_LANGUAGE="en"
    export LC_ALL="C"
    export ALLOW_MISSING_DEPENDENCIES=true
    export USE_CCACHE="1"
    export CC_WRAPPER="/usr/bin/ccache"
    export CCACHE_DIR="/mnt/ccache"
    export FOX_AB_DEVICE="1"
    export OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR=1
    export FOX_VIRTUAL_AB_DEVICE="1"
    export FOX_VANILLA_BUILD="1"
    export OF_DYNAMIC_FULL_SIZE="9663676416"
    export OF_UNBIND_SDCARD_F2FS="1"
    export OF_USE_DMCTL="1"
    export OF_USE_MAGISKBOOT=1
    export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1
    export FOX_DELETE_AROMAFM=1
    export FOX_USE_DATA_RECOVERY_FOR_SETTINGS="1"
    export FOX_USE_TAR_BINARY="1"
    export FOX_USE_SED_BINARY="1"
    export FOX_USE_LZ4_BINARY="1"
    export FOX_USE_ZSTD_BINARY="1"
    export FOX_USE_DATE_BINARY="1"


    export FOX_ENABLE_KERNELSU_SUPPORT="1"
    export FOX_ENABLE_KERNELSU_NEXT_SUPPORT="1"
    export FOX_ENABLE_SUKISU_SUPPORT="1"

    echo "OrangeFox build environment: $FOX_BUILD_DEVICE (fox_14.1, Virtual A/B)"
fi
