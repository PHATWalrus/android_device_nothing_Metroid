#!/system/bin/sh

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
    /system/bin/resetprop "$name" "$value" || exit 1
done

setprop crypto.metroid.keymint_props_ready 1
