# OrangeFox build vars for Nothing Phone (3) — Metroid
export OF_MAINTAINER="Wise"
export FOX_BUILD_TYPE="Unofficial"

# A/B + virtual A/B + dynamic partitions
export FOX_AB_DEVICE=1
export FOX_VIRTUAL_AB_DEVICE=1

# Display — 1260x2800, no physical select button
export OF_SCREEN_H=2800
export OF_STATUS_H=180
export OF_STATUS_INDENT_LEFT=48
export OF_STATUS_INDENT_RIGHT=48
export OF_HIDE_NOTCH=1
export OF_CLOCK_POS=1

# UX
export OF_USE_LOCKSCREEN_BUTTON=0
export OF_ALLOW_DISABLE_NAVBAR=0
export OF_DISABLE_MIUI_OTA_BY_DEFAULT=1
export OF_USE_GREEN_LED=0
export FOX_DELETE_AROMAFM=1
export FOX_ENABLE_APP_MANAGER=1

# Build scope
export FOX_TARGET_DEVICES="Metroid"
export FOX_CUSTOM_OUT_NAME="orangefox-Metroid"
