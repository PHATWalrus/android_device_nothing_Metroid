#!/usr/bin/env bash
set -euo pipefail

device_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${ANDROID_BUILD_TOP:-}" ]]; then
    top="$ANDROID_BUILD_TOP"
else
    top="$(cd "$device_dir/../../.." && pwd)"
fi

apply_patch_once() {
    local project="$1"
    local patch="$2"

    if git -C "$project" apply --reverse --check "$patch" >/dev/null 2>&1; then
        echo "already applied: ${patch#$device_dir/}"
        return 0
    fi

    git -C "$project" apply --check "$patch"
    git -C "$project" apply "$patch"
    echo "applied: ${patch#$device_dir/}"
}

require_project() {
    local project="$1"
    [[ -d "$project/.git" || -f "$project/.git" ]] || {
        echo "missing source project: $project" >&2
        exit 1
    }
}

require_project "$top/system/vold"
require_project "$top/bootable/recovery"

has_native_omapi_packaging() {
    local recovery="$1"

    [[ -f "$top/external/se_omapi/Android.bp" ]] && \
        grep -q "TW_INCLUDE_OMAPI" "$recovery/Android.mk" && \
        grep -q "se_omapi" "$recovery/Android.mk" && \
        grep -q "TW_INCLUDE_OMAPI" "$recovery/prebuilt/Android.mk" && \
        grep -q "se_omapi" "$recovery/prebuilt/Android.mk" && \
        grep -q "external/se_omapi" "$recovery/prebuilt/Android.bp" && \
        grep -q "LOCAL_MODULE := se_omapi.rc" "$recovery/etc/Android.mk" && \
        grep -q "LOCAL_MODULE := se_omapi.xml" "$recovery/etc/Android.mk"
}

board_flag_is_true() {
    local flag="$1"
    grep -qE "^[[:space:]]*${flag}[[:space:]]*:=[[:space:]]*true([[:space:]]*(#.*)?)?$" \
        "$device_dir/BoardConfig.mk"
}

# TeamWin 14 fallback patches.
if grep -q "AidlIGatekeeper" "$top/system/vold/Decrypt.cpp"; then
    echo "provided by source: AIDL Gatekeeper"
else
    apply_patch_once "$top/system/vold" \
        "$device_dir/patches/system_vold/0001-vold-support-AIDL-GateKeeper-1-2.patch"
fi

if grep -q "mAidlDevice" "$top/system/vold/Weaver1.cpp"; then
    echo "provided by source: AIDL Weaver"
else
    apply_patch_once "$top/system/vold" \
        "$device_dir/patches/system_vold/0002-vold-Add-support-for-AIDL-weaver-service-1-2.patch"
fi

keystore_wait_patch="$device_dir/patches/system_vold/0003-vold-bound-keystore2-service-wait.patch"
if grep -qF '[METROID-FBE] timed out waiting for keystore2' "$top/system/vold/Keystore.cpp"; then
    echo "provided by source: bounded keystore2 wait"
else
    apply_patch_once "$top/system/vold" "$keystore_wait_patch"
fi

single_wait_patch="$device_dir/patches/system_vold/0004-vold-avoid-repeated-keystore2-wait.patch"
if grep -qF 'keystore2_full_wait_done' "$top/system/vold/Keystore.cpp"; then
    echo "provided by source: single full keystore2 wait"
else
    apply_patch_once "$top/system/vold" "$single_wait_patch"
fi

filesystem_ids_patch="$device_dir/patches/bootable_recovery/0002-recovery-include-android-filesystem-config.patch"
if grep -q "private/android_filesystem_config.h" "$top/bootable/recovery/partitionmanager.cpp"; then
    echo "provided by source: partition manager Android filesystem IDs"
else
    apply_patch_once "$top/bootable/recovery" "$filesystem_ids_patch"
fi

pending_merge_patch="$device_dir/patches/bootable_recovery/0005-recovery-only-unmap-super-for-pending-merge.patch"
if grep -qF 'does not require a pre-wipe super unmap' "$top/bootable/recovery/partitionmanager.cpp"; then
    echo "provided by source: snapshot-aware data format"
else
    apply_patch_once "$top/bootable/recovery" "$pending_merge_patch"
fi

haptics_lookup_patch="$device_dir/patches/bootable_recovery/0003-recovery-use-nonblocking-vibrator-lookup.patch"
if ! board_flag_is_true TW_SUPPORT_INPUT_AIDL_HAPTICS; then
    echo "provided by device tree: binder haptics disabled"
elif grep -qF 'AServiceManager_checkService(kVibratorInstance.c_str())' "$top/bootable/recovery/minuitwrp/events.cpp"; then
    echo "provided by source: non-blocking vibrator lookup"
else
    apply_patch_once "$top/bootable/recovery" "$haptics_lookup_patch"
fi

gui_poll_patch="$device_dir/patches/bootable_recovery/0004-recovery-sleep-between-gui-input-polls.patch"
if grep -qF 'kMaxInputPollSleepUs = 1000' "$top/bootable/recovery/gui/gui.cpp"; then
    echo "provided by source: bounded GUI input polling"
else
    apply_patch_once "$top/bootable/recovery" "$gui_poll_patch"
fi

usb_transition_patch="$device_dir/patches/bootable_recovery/0006-recovery-wait-for-usb-gadget-teardown.patch"
if sed -n '/int GUIAction::enablefastboot/,/^}/p' "$top/bootable/recovery/gui/action.cpp" | grep -qF 'sleep(1);'; then
    echo "provided by source: serialized USB gadget transition"
else
    apply_patch_once "$top/bootable/recovery" "$usb_transition_patch"
fi

# OMAPI is source-native on fox_14.1; do not patch its build files.
if ! board_flag_is_true TW_INCLUDE_OMAPI; then
    echo "provided by device tree: OMAPI disabled"
elif has_native_omapi_packaging "$top/bootable/recovery"; then
    echo "provided by source: native OMAPI packaging"
else
    echo "Native OMAPI packaging is absent or partial; source patching is disabled for this feature." >&2
    echo "Re-sync bootable/recovery, vendor/recovery, and external/se_omapi with the official OrangeFox fox_14.1 sync, then rerun this helper." >&2
    exit 1
fi
