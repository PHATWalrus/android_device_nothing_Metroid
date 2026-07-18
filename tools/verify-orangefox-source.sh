#!/usr/bin/env bash
set -euo pipefail

device_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${ANDROID_BUILD_TOP:-}" ]]; then
    top="$ANDROID_BUILD_TOP"
else
    top="$(cd "$device_dir/../../.." && pwd)"
fi

failed=0

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1" >&2
    failed=1
}

check_file() {
    local path="$1"
    local label="$2"

    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label is missing: ${path#$top/}"
    fi
}

recovery="$top/bootable/recovery"
if [[ -f "$recovery/orangefox.mk" || -f "$recovery/orangefox_defaults.go" ]]; then
    pass "OrangeFox recovery build hooks"
else
    fail "bootable/recovery is a plain TWRP checkout (missing orangefox.mk/orangefox_defaults.go)"
fi

check_file "$top/vendor/recovery/OrangeFox_A14.sh" "OrangeFox vendor source"
check_file "$top/external/se_omapi/Android.bp" "OrangeFox se_omapi source"

for file in \
    "$recovery/Android.mk" \
    "$recovery/prebuilt/Android.mk" \
    "$recovery/prebuilt/Android.bp" \
    "$recovery/etc/Android.mk"; do
    [[ -f "$file" ]] || fail "required recovery build file is missing: ${file#$top/}"
done

if [[ -f "$recovery/Android.mk" && \
      -f "$recovery/prebuilt/Android.mk" && \
      -f "$recovery/prebuilt/Android.bp" && \
      -f "$recovery/etc/Android.mk" ]] && \
    grep -q "TW_INCLUDE_OMAPI" "$recovery/Android.mk" && \
    grep -q "se_omapi" "$recovery/Android.mk" && \
    grep -q "TW_INCLUDE_OMAPI" "$recovery/prebuilt/Android.mk" && \
    grep -q "se_omapi" "$recovery/prebuilt/Android.mk" && \
    grep -q "external/se_omapi" "$recovery/prebuilt/Android.bp" && \
    grep -q "LOCAL_MODULE := se_omapi.rc" "$recovery/etc/Android.mk" && \
    grep -q "LOCAL_MODULE := se_omapi.xml" "$recovery/etc/Android.mk"; then
    pass "native OMAPI packaging"
else
    fail "native OMAPI packaging is absent or partial"
fi

if grep -qF 'private/android_filesystem_config.h' "$recovery/partitionmanager.cpp"; then
    pass "partition manager Android filesystem IDs"
else
    fail "partitionmanager.cpp uses AID_MEDIA_RW without its defining header"
fi

if grep -qF 'does not require a pre-wipe super unmap' "$recovery/partitionmanager.cpp" && \
   grep -qF 'update_state == android::snapshot::UpdateState::Merging' "$recovery/partitionmanager.cpp" && \
   grep -qE '^[[:space:]]*export[[:space:]]+OF_USE_DMCTL="?1"?' "$device_dir/vendorsetup.sh" && \
   grep -qE '^[[:space:]]*export[[:space:]]+OF_UNBIND_SDCARD_F2FS="?1"?' "$device_dir/vendorsetup.sh" && \
   grep -qF 'TWRP_REQUIRED_MODULES += dmctl' "$recovery/orangefox.mk"; then
    pass "snapshot-aware format-data mapper cleanup"
else
    fail "format-data mapper cleanup is incomplete"
fi

if grep -qE '^[[:space:]]*BOARD_USES_QCOM_FBE_DECRYPTION[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk"; then
    fail "legacy Qualcomm FBE helper is enabled; it uses the unsupported install_keyring init builtin"
else
    pass "legacy Qualcomm FBE helper disabled"
fi

if grep -R -q --include='*.rc' '^[[:space:]]*install_keyring\>' "$device_dir/recovery/root"; then
    fail "device recovery init contains the unsupported install_keyring builtin"
else
    pass "recovery init builtins"
fi

if grep -qF 'wait /dev/block/platform/soc/1d84000.ufshc' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'symlink /dev/block/platform/soc/1d84000.ufshc /dev/block/bootdevice' "$device_dir/recovery/root/init.recovery.qcom.rc"; then
    pass "recovery UFS bootdevice path"
else
    fail "recovery UFS bootdevice path is missing or property-dependent"
fi

if grep -qE '^[[:space:]]*METROID_ENABLE_FBE[[:space:]]*\?=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_INCLUDE_CRYPTO[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_INCLUDE_CRYPTO_FBE[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_INCLUDE_FBE_METADATA_DECRYPT[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk"; then
    pass "guarded Android 16 FBE profile"
else
    fail "guarded Android 16 FBE profile is incomplete"
fi

if grep -qF 'PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.recovery.metroid.fbe=1' "$device_dir/device.mk" && \
   grep -qF 'ro.boot.product.vendor.sku=tuna' "$device_dir/device.mk" && \
   ! grep -qF 'TW_DEFAULT_PROPS' "$device_dir/BoardConfig.mk"; then
    pass "recovery FBE and tuna default properties"
else
    fail "recovery FBE controls are not packaged into prop.default"
fi

if ! grep -qF 'mount_logical' "$device_dir/recovery/root/system/bin/metroid-crypto-init.sh" && \
   grep -qF 'ro.build.version.release=16' "$device_dir/recovery/root/system/bin/metroid-keymint-prepare.sh" && \
   grep -qF 'ro.vendor.build.security_patch=2026-04-05' "$device_dir/recovery/root/system/bin/metroid-keymint-prepare.sh"; then
    pass "non-blocking KeyMint property preparation"
else
    fail "KeyMint preparation is blocking or does not match the stock firmware"
fi

if grep -qF 'import /init.recovery.metroid.crypto.rc' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'property:crypto.metroid.keymint_ready=1' "$device_dir/recovery/root/init.recovery.metroid.crypto.rc" && \
   grep -qF 'KeyMint did not register; keystore2 remains stopped' "$device_dir/recovery/root/system/bin/metroid-fbe-monitor.sh" && \
   [[ -f "$device_dir/recovery/root/system/etc/init/keystore2.rc" ]] && \
   ! grep -qE '^[[:space:]]*(on late-init|start keystore2|service keystore2)' "$device_dir/recovery/root/system/etc/init/keystore2.rc"; then
    pass "KeyMint registration gate"
else
    fail "keystore2 is not protected by the KeyMint registration gate"
fi

if grep -qF 'TW_RECOVERY_ADDITIONAL_RELINK_BINARY_FILES += $(TARGET_OUT_EXECUTABLES)/service' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*service([[:space:]]|$)' "$device_dir/device.mk"; then
    pass "recovery service-manager client"
else
    fail "the KeyMint monitor requires /system/bin/service in the recovery ramdisk"
fi

if grep -qF '[METROID-FBE] timed out waiting for keystore2' "$top/system/vold/Keystore.cpp" && \
   grep -qF 'keystore2_full_wait_done' "$top/system/vold/Keystore.cpp" && \
   grep -qF 'exchange(true) ? 1 : 50' "$top/system/vold/Keystore.cpp" && \
   ! grep -qF 'AServiceManager_waitForService(keystore2_service_name)' "$top/system/vold/Keystore.cpp"; then
    pass "bounded vold keystore2 wait"
else
    fail "system/vold still has an unbounded keystore2 wait"
fi

if grep -R -qE --include='*.mk' --include='*.prop' --include='*.rc' '(^|[[:space:]])keymaster_ver=' "$device_dir"; then
    fail "legacy keymaster_ver override is present"
else
    pass "AIDL KeyMint selection"
fi

if grep -qE '^[[:space:]]*TW_EXCLUDE_DEFAULT_USB_INIT[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_EXCLUDE_MTP[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qF 'start of_usbdbg' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'setprop sys.usb.config adb' "$device_dir/recovery/root/of_usbdbg.sh"; then
    pass "stock configfs plain-ADB bring-up"
else
    fail "stable plain-ADB bring-up is incomplete"
fi

usb_controller_triggers="$(grep -R -h --include='*.rc' '^on property:ro.boot.usbcontroller=\*' "$device_dir/recovery/root" | wc -l)"
if [[ "$usb_controller_triggers" -eq 1 ]]; then
    pass "single USB controller trigger"
else
    fail "expected one USB controller trigger, found $usb_controller_triggers"
fi

check_file "$device_dir/recovery/root/system/bin/metroid-bootlog.sh" "persistent recovery boot logger"
check_file "$device_dir/recovery/root/system/bin/metroid-crypto-init.sh" "vendor namespace preparation"
check_file "$device_dir/recovery/root/system/bin/metroid-fbe-monitor.sh" "FBE registration monitor"
check_file "$device_dir/recovery/root/system/bin/metroid-keymint-prepare.sh" "KeyMint property preparation"
check_file "$device_dir/recovery/root/system/bin/metroid-haptics-init.sh" "haptics preparation"
check_file "$device_dir/recovery/root/system/etc/task_profiles.json" "recovery task profiles"

for library in libbinder.so libbinder_ndk.so libapexsupport.so libvndksupport.so; do
    check_file "$device_dir/recovery/root/system/lib64_a16/$library" "stock Android 16 $library"
done

if grep -qF 'LD_LIBRARY_PATH /system/lib64_a16:/system/lib64' "$device_dir/recovery/root/system/etc/init/servicemanager.rc" && \
   grep -qF 'libvintf.so:$(TARGET_COPY_OUT_RECOVERY)/root/system/lib64_a16/libvintf.so' "$device_dir/proprietary-blobs.mk" && \
   grep -qF 'libperfetto_c.so:$(TARGET_COPY_OUT_RECOVERY)/root/system/lib64_a16/libperfetto_c.so' "$device_dir/proprietary-blobs.mk"; then
    pass "mixed Android 16 servicemanager runtime"
else
    fail "servicemanager is missing its tested mixed runtime"
fi

if grep -qF '/dev/0:0:0:49476   0600  system  system' "$device_dir/recovery/root/vendor/etc/ueventd.rc" && \
   grep -qF 'librpmb.so:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib64/librpmb.so' "$device_dir/proprietary-blobs.mk" && \
   grep -qF 'libops.so:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib64/libops.so' "$device_dir/proprietary-blobs.mk"; then
    pass "QSEE RPMB listener closure"
else
    fail "QSEE RPMB listener or device ownership is incomplete"
fi

manifest="$device_dir/recovery/root/vendor/etc/vintf/manifest.xml"
if grep -qF '<fqname>IKeyMintDevice/default</fqname>' "$manifest" && \
   grep -qF '<fqname>IVibrator/default</fqname>' "$manifest" && \
   ! grep -qE 'strongbox|android.hardware.weaver|android.hardware.secure_element' "$manifest"; then
    pass "IND/tuna recovery VINTF manifest"
else
    fail "recovery VINTF does not match the stock IND/tuna services"
fi

if grep -qE '^[[:space:]]*TW_FRAMERATE[[:space:]]*:=[[:space:]]*120' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_USE_LEGACY_BATTERY_SERVICES[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_CUSTOM_CPU_TEMP_PATH[[:space:]]*:=[[:space:]]*"/tmp/metroid_cpu_temp"' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*TW_CUSTOM_POWER_BUTTON[[:space:]]*:=[[:space:]]*116' "$device_dir/BoardConfig.mk" && \
   grep -qF 'aw9380x_0_ch11' "$device_dir/BoardConfig.mk" && \
   grep -qF 'echo 8-0012 > "$aw_driver/unbind"' "$device_dir/recovery/root/system/bin/metroid-platform-init.sh" && \
   ! grep -qE '^[[:space:]]*start[[:space:]]+metroid-bootlog' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   ! grep -qF 'scaling_max_freq' "$device_dir/recovery/root/init.recovery.qcom.rc"; then
    pass "120 Hz display and quiet recovery input path"
else
    fail "display/input latency safeguards are incomplete"
fi

if grep -qF 'kMaxInputPollSleepUs = 1000' "$recovery/gui/gui.cpp" && \
   grep -qF 'usleep(sleep_us)' "$recovery/gui/gui.cpp"; then
    pass "bounded GUI input polling"
else
    fail "OrangeFox GUI input polling still busy-spins"
fi

platform_init="$device_dir/recovery/root/system/bin/metroid-platform-init.sh"
if grep -qF 'write /proc/sys/kernel/firmware_config/force_sysfs_fallback 1' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'start metroid-platform-prepare' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'service metroid-platform-prepare' "$device_dir/recovery/root/init.recovery.qcom.rc" && \
   grep -qF 'cpu-0-0-0' "$platform_init" && \
   grep -qF 'ln -sf "$cpu_temp" /tmp/metroid_cpu_temp' "$platform_init" && \
   grep -qF 'set_cpu_policy /sys/devices/system/cpu/cpufreq/policy0 1516800' "$platform_init" && \
   grep -qF 'set_cpu_policy /sys/devices/system/cpu/cpufreq/policy7 2400000' "$platform_init" && \
   grep -qF 'setprop metroid.cpu.capped 1' "$platform_init" && \
   grep -qF 'mount -t vfat -o ro "$modem" /tmp/metroid-firmware' "$platform_init" && \
   grep -qF 'mount -o bind /tmp/metroid-firmware/image /vendor/firmware' "$platform_init" && \
   grep -qF '3000000.remoteproc-adsp' "$platform_init" && \
   grep -qF '/sys/class/power_supply/battery/capacity' "$platform_init"; then
    pass "ADSP-backed battery and sensor bring-up"
else
    fail "battery and sensor bring-up is incomplete"
fi

if grep -qE '^[[:space:]]*FOX_USE_DATA_RECOVERY_FOR_SETTINGS[[:space:]]*:=[[:space:]]*1' "$device_dir/BoardConfig.mk" && \
   grep -qE '^[[:space:]]*export[[:space:]]+FOX_USE_DATA_RECOVERY_FOR_SETTINGS="?1"?' "$device_dir/vendorsetup.sh" && \
   ! grep -qE '^[[:space:]]*FOX_SETTINGS_ROOT_DIRECTORY[[:space:]]*:=' "$device_dir/BoardConfig.mk" && \
   ! grep -qE '^[[:space:]]*export[[:space:]]+FOX_(SETTINGS_ROOT_DIRECTORY|ALLOW_EARLY_SETTINGS_LOAD)' "$device_dir/vendorsetup.sh"; then
    pass "OrangeFox settings on /data/recovery"
else
    fail "OrangeFox settings are not configured for post-decryption /data/recovery load"
fi

if grep -qF 'AServiceManager_checkService(kVibratorInstance.c_str())' "$recovery/minuitwrp/events.cpp" && \
   ! grep -qF 'AServiceManager_getService(kVibratorInstance.c_str())' "$recovery/minuitwrp/events.cpp"; then
    pass "non-blocking AIDL haptics lookup"
else
    fail "AIDL haptics still blocks input while waiting for a vibrator service"
fi

if grep -qE '^[[:space:]]*TW_SUPPORT_INPUT_AIDL_HAPTICS[[:space:]]*:=[[:space:]]*true' "$device_dir/BoardConfig.mk" && \
   grep -qF '/dev/aw86927_haptic 0666 system system' "$device_dir/recovery/root/vendor/etc/ueventd.rc" && \
   grep -qF 'root/vendor/etc/aac_richtap.config' "$device_dir/proprietary-blobs.mk" && \
   grep -qF 'ENV_RICHTAP_CONFIG_PATH /vendor/etc/aac_richtap.config' "$device_dir/recovery/root/init.recovery.metroid.crypto.rc" && \
   grep -qF 'service vendor.qti.vibrator' "$device_dir/recovery/root/init.recovery.metroid.crypto.rc"; then
    pass "AIDL vibrator service"
else
    fail "AIDL haptics are incomplete"
fi

module_count="$(find "$device_dir/recovery/root/vendor/lib/modules" -maxdepth 1 -type f -name '*.ko' | wc -l)"
if [[ "$module_count" -ge 300 ]] && \
   [[ -f "$device_dir/recovery/root/vendor/lib/modules/modules.load.recovery" ]] && \
   grep -qF 'dwc3-msm.ko' "$device_dir/recovery/root/vendor/lib/modules/modules.load.recovery" && \
   grep -qF 'focaltech_tp.ko' "$device_dir/recovery/root/vendor/lib/modules/modules.load.recovery"; then
    pass "stock recovery module payload ($module_count modules)"
else
    fail "stock recovery module payload is incomplete ($module_count modules)"
fi

if grep -qF '/dev/block/mapper/vendor ' "$device_dir/recovery.fstab" && \
   grep -qF 'mounttodecrypt' "$device_dir/recovery.fstab"; then
    pass "working unsuffixed logical-partition mapping"
else
    fail "recovery fstab does not match the working logical-partition mapping"
fi

if command -v git >/dev/null 2>&1 && [[ -d "$recovery/.git" || -f "$recovery/.git" ]]; then
    remote="$(git -C "$recovery" remote get-url origin 2>/dev/null || true)"
    if [[ "$remote" == *"OrangeFox"* || "$remote" == *"orangefox"* ]]; then
        pass "OrangeFox recovery remote: $remote"
    else
        fail "bootable/recovery remote is not OrangeFox: ${remote:-unknown}"
    fi
fi

if (( failed )); then
    echo "Fix the failed fox_14.1 checks before building Metroid." >&2
    exit 1
fi

echo "OrangeFox fox_14.1 source verification passed."
