#!/system/bin/sh

LOG=/persist/metroid-fbe.log
SRC=/system/lib64_a16
DST=/persist/decrypt_libs

note() {
    echo "[METROID-FBE] $*" >> "$LOG"
    log -t METROID-FBE "$*"
}

set_firmware_props() {
    for pair in \
        ro.build.version.sdk=36 \
        ro.build.version.release=16 \
        ro.build.version.release_or_codename=16 \
        ro.product.first_api_level=35 \
        ro.board.first_api_level=202404 \
        ro.board.api_level=202404 \
        ro.vendor.api_level=202404 \
        ro.build.version.security_patch=2026-06-01 \
        ro.vendor.build.security_patch=2026-04-05 \
        ro.vendor.boot_security_patch=2025-09-05; do
        name="${pair%%=*}"
        value="${pair#*=}"
        /system/bin/resetprop "$name" "$value" || return 1
    done
}

: > "$LOG"
setprop metroid.vendor.ready 0
setprop crypto.metroid.active 0
setprop crypto.metroid.error ""
setprop crypto.metroid.keymint_ready 0
setprop crypto.metroid.keymint_timeout 0
setprop crypto.metroid.keymint_props_ready 0
if ! set_firmware_props; then
    note "firmware property setup failed"
    setprop crypto.metroid.error firmware_props
    exit 1
fi
mkdir -p "$DST"
for name in libbinder.so libbinder_ndk.so libapexsupport.so libvndksupport.so; do
    file="$SRC/$name"
    [ -e "$file" ] || continue
    cp -f "$file" "$DST/"
done
chmod 0644 "$DST"/*.so 2>/dev/null

mkdir -p /mnt/vendor
mkdir -p /mnt/vendor/persist
if ! grep -q ' /mnt/vendor/persist ' /proc/mounts; then
    mount -o bind /persist /mnt/vendor/persist
fi
mkdir -p /persist/haptic
chown system:system /persist/haptic
chmod 0771 /persist/haptic
chmod 0666 /dev/aw86927_haptic 2>/dev/null
chown system:system /dev/aw86927_haptic 2>/dev/null
chmod 0600 /dev/0:0:0:49476 2>/dev/null
chown system:system /dev/0:0:0:49476 2>/dev/null
chmod 0666 /proc/haptic/* 2>/dev/null
chown system:system /proc/haptic/* 2>/dev/null
chmod 0666 /sys/class/leds/vibrator_nt/* 2>/dev/null
chown system:system /sys/class/leds/vibrator_nt/* 2>/dev/null

for file in \
    "$DST/libbinder.so" \
    "$DST/libbinder_ndk.so" \
    "$DST/libapexsupport.so" \
    "$DST/libvndksupport.so" \
    /vendor/bin/qseecomd \
    /vendor/bin/hw/vendor.qti.hardware.qseecom@1.0-service \
    /vendor/bin/hw/android.hardware.security.keymint-service-qti \
    /vendor/bin/hw/android.hardware.gatekeeper-service-qti; do
    if [ ! -e "$file" ]; then
        note "missing $file"
        setprop crypto.metroid.error missing_file
        exit 1
    fi
done

setprop vendor.gatekeeper.is_security_level_spu 0
setprop crypto.metroid.error ""
setprop metroid.vendor.ready 1
note "vendor ready slot=$(getprop ro.boot.slot_suffix) sku=$(getprop ro.boot.product.vendor.sku) sdk=$(getprop ro.build.version.sdk) spl=$(getprop ro.vendor.build.security_patch)"
